public with sharing class ProductController {
    @AuraEnabled(cacheable=true)
    public static List<ProductWrapper> getProducts() {
        // 현재 사용자의 AccountId를 가져오려고 시도함
        Id accountId;
        try {
            accountId = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.AccountId;
        } catch (Exception e) {
            accountId = null; // accountId가 없을 경우 null로 설정
        }
        
        // accountId가 없는 경우 Standard Pricebook을 사용하도록 설정
        Id pricebookId;
        if (accountId != null) {
            // AccountId가 있는 경우, 해당하는 Pricebook을 사용
            Contract latestActivatedContract = [
                SELECT Pricebook2Id 
                FROM Contract 
                WHERE AccountId = :accountId 
                AND Status = 'Activated' 
                ORDER BY StartDate DESC 
                LIMIT 1
            ];
            
            // 활성화된 계약이 있을 경우 그에 해당하는 Pricebook을 사용
            if (latestActivatedContract != null && latestActivatedContract.Pricebook2Id != null) {
                pricebookId = latestActivatedContract.Pricebook2Id;
            } else {
                // 활성화된 계약이 없을 경우 Standard Pricebook을 사용
                pricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            }
        } else {
            // AccountId가 없을 경우 Standard Pricebook을 사용
            pricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
        }

        // Product2 및 관련된 PricebookEntry와 Inventory__c 정보를 서브쿼리로 쿼리
        List<Product2> products = [
            SELECT Id, Name, Family,
                (SELECT UnitPrice FROM PricebookEntries WHERE Pricebook2Id = :pricebookId AND IsActive = true LIMIT 1),
                (SELECT Amount__c FROM Inventories__r)  // Product2의 자식 관계로 Inventories__r 사용
            FROM Product2
            WHERE IsActive = true
        ];

        // Product2와 관련된 가격, Family 및 Inventory 정보를 List로 변환
        List<ProductWrapper> productList = new List<ProductWrapper>();
        for (Product2 prod : products) {
            Decimal price = 0; // 기본값 0으로 초기화
            if (prod.PricebookEntries.size() > 0) {
                price = prod.PricebookEntries[0].UnitPrice;
            }

            // 재고 수량 초기화
            Integer stockAmount = 0;
            if (prod.Inventories__r != null && prod.Inventories__r.size() > 0) {
                stockAmount = (Integer) prod.Inventories__r[0].Amount__c;  // 첫 번째 Inventory 레코드의 Amount__c 사용
            }

            // Family 필드를 추가하여 제품을 래핑
            productList.add(new ProductWrapper(prod.Name, prod.Family, price, stockAmount));
        }

        return productList;
    }

    // Product 정보와 가격, Family 및 Inventory를 Wrapping
    public class ProductWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String family; // 추가된 Family 필드
        @AuraEnabled public Decimal price;
        @AuraEnabled public Integer stockAmount; // 재고 수량 필드 추가

        public ProductWrapper(String name, String family, Decimal price, Integer stockAmount) {
            this.name = name;
            this.family = family;
            this.price = price;
            this.stockAmount = stockAmount;
        }
    }
}