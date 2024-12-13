public with sharing class OrderController {

    @AuraEnabled
    public static void saveOrder(String orderDetails) {
        System.debug('DEBUG: saveOrder called with orderDetails: ' + orderDetails);

        // 주문 전 재고 확인
        if (!validateStockAvailability(orderDetails)) {
            throw new AuraHandledException('재고가 충분하지 않습니다.');
        }

        try {
            // 기존의 saveOrder 로직을 실행합니다.
            OrderWrapper orderDetailsWrapper = (OrderWrapper) JSON.deserialize(orderDetails, OrderWrapper.class);

            // Account 조회
            List<Account> accountList = [SELECT Id, Name FROM Account WHERE Id = :orderDetailsWrapper.accountId LIMIT 1];
            if (accountList.isEmpty()) {
                throw new AuraHandledException('No Account found for Id: ' + orderDetailsWrapper.accountId);
            }

            Account account = accountList[0];

            // Account에 연관된 'Activated' 상태의 Contract를 찾기 (가장 최근 Start Date)
            List<Contract> activeContracts = [SELECT Id, Pricebook2Id FROM Contract WHERE AccountId = :account.Id AND Status = 'Activated' ORDER BY StartDate DESC LIMIT 1];
            Id pricebookId;
            if (!activeContracts.isEmpty() && activeContracts[0].Pricebook2Id != null) {
                pricebookId = activeContracts[0].Pricebook2Id;
            } else {
                // 만약 활성화된 Contract가 없거나, Pricebook2Id가 없다면 Standard Pricebook 사용
                Pricebook2 pricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
                if (pricebook == null) {
                    throw new AuraHandledException('No Standard Pricebook found.');
                } else {
                    pricebookId = pricebook.Id;
                }
            }

            // 주문(Order) 생성
            Order newOrder = new Order(
                Status = '승인 완료',
                EffectiveDate = Date.today(),
                AccountId = account.Id,
                Name = account.Name + ' - ' + String.valueOf(Date.today().year()) + '-' + String.valueOf(Date.today().month()) + '-' + String.valueOf(Date.today().day()),
                Pricebook2Id = pricebookId,
                ContractId = (activeContracts.isEmpty()) ? null : activeContracts[0].Id
            );
            insert newOrder;

            if (newOrder.Id == null) {
                throw new AuraHandledException('Failed to insert new Order. ID is null.');
            }

            // 장바구니 항목(OrderItem) 생성
            List<OrderItem> orderProducts = new List<OrderItem>();
            List<CartItemWrapper> cartItemWrapperList = orderDetailsWrapper.cartItems;
            for (CartItemWrapper cartItem : cartItemWrapperList) {

                // Product2 및 PricebookEntry 조회
                List<Product2> productList = [SELECT Id FROM Product2 WHERE Name = :cartItem.productName LIMIT 1];
                if (productList.isEmpty()) {
                    throw new AuraHandledException('No Product found with the name: ' + cartItem.productName);
                }

                Product2 product = productList[0];

                // PricebookEntry 조회
                List<PricebookEntry> pricebookEntries = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :product.Id AND Pricebook2Id = :pricebookId LIMIT 1];
                if (pricebookEntries.isEmpty()) {
                    throw new AuraHandledException('No PricebookEntry found for Product: ' + product.Name);
                }
                PricebookEntry pricebookEntry = pricebookEntries[0];

                // OrderItem 생성
                OrderItem orderItem = new OrderItem(
                    OrderId = newOrder.Id,
                    Product2Id = product.Id,
                    UnitPrice = pricebookEntry.UnitPrice,
                    ListPrice = pricebookEntry.UnitPrice,
                    Quantity = cartItem.amount,
                    PricebookEntryId = pricebookEntry.Id
                );

                orderProducts.add(orderItem);
            }

            // 모든 OrderItem 삽입
            insert orderProducts;

            // 주문 후 재고 감소 처리
            reduceInventory(orderDetailsWrapper.cartItems);

        } catch (Exception e) {
            throw new AuraHandledException('주문을 저장하는 중 오류가 발생했습니다. 상세: ' + e.getMessage());
        }
    }

    // 추가된 메서드: 재고 검증
    @AuraEnabled
    public static Boolean validateStockAvailability(String orderDetails) {
        OrderWrapper orderDetailsWrapper = (OrderWrapper) JSON.deserialize(orderDetails, OrderWrapper.class);
        List<CartItemWrapper> cartItems = orderDetailsWrapper.cartItems;

        for (CartItemWrapper cartItem : cartItems) {
            Product2 product = [SELECT Id, (SELECT Amount__c FROM Inventories__r LIMIT 1) FROM Product2 WHERE Name = :cartItem.productName LIMIT 1];
            if (product.Inventories__r.isEmpty() || product.Inventories__r[0].Amount__c < cartItem.amount) {
                return false; // 재고가 충분하지 않으면 false 반환
            }
        }
        return true; // 모든 제품의 재고가 충분한 경우
    }

    // 추가된 메서드: 재고 감소
    @AuraEnabled
    public static void reduceInventory(List<CartItemWrapper> cartItems) {
        List<Inventory__c> inventoriesToUpdate = new List<Inventory__c>();

        for (CartItemWrapper cartItem : cartItems) {
            Product2 product = [SELECT Id, (SELECT Id, Amount__c FROM Inventories__r LIMIT 1) FROM Product2 WHERE Name = :cartItem.productName LIMIT 1];
            if (!product.Inventories__r.isEmpty()) {
                Inventory__c inventory = product.Inventories__r[0];
                inventory.Amount__c -= cartItem.amount;
                inventoriesToUpdate.add(inventory);
            }
        }

        if (!inventoriesToUpdate.isEmpty()) {
            update inventoriesToUpdate; // 재고 업데이트
        }
    }

    public class OrderWrapper {
        @AuraEnabled public Decimal totalCartPrice;
        @AuraEnabled public String accountId;
        @AuraEnabled public List<CartItemWrapper> cartItems;
    }

    public class CartItemWrapper {
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public String productName;
    }
}