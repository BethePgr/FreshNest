public with sharing class InventoryController {
    @AuraEnabled(cacheable=true)
    public static List<InventoryWrapper> getInventoriesWithProductDetails() {
        // Inventory__c 정보를 먼저 쿼리하여 제품 정보를 가져옴
        List<Inventory__c> inventories = [
            SELECT Id, Amount__c, Product__r.Name, Product__r.Family, Product__r.Id
            FROM Inventory__c
        ];

        // 가격 정보를 가져오기 위해 필요한 Product Id 목록 생성
        Set<Id> productIds = new Set<Id>();
        for (Inventory__c inv : inventories) {
            if (inv.Product__r != null) {
                productIds.add(inv.Product__r.Id);
            }
        }

        // Product2의 가격 정보를 가져옴
        Map<Id, Decimal> productPriceMap = new Map<Id, Decimal>();
        if (!productIds.isEmpty()) {
            for (PricebookEntry pbe : [
                SELECT Product2Id, UnitPrice 
                FROM PricebookEntry 
                WHERE Pricebook2.IsStandard = true AND IsActive = true AND Product2Id IN :productIds
            ]) {
                productPriceMap.put(pbe.Product2Id, pbe.UnitPrice);
            }
        }

        // Inventory 정보를 InventoryWrapper로 Wrapping
        List<InventoryWrapper> inventoryList = new List<InventoryWrapper>();
        for (Inventory__c inv : inventories) {
            Decimal price = productPriceMap.containsKey(inv.Product__r.Id) ? productPriceMap.get(inv.Product__r.Id) : 0;

            // InventoryWrapper 클래스에 추가
            inventoryList.add(new InventoryWrapper(
                inv.Id,
                inv.Amount__c != null ? inv.Amount__c : 0,
                inv.Product__r != null ? inv.Product__r.Name : 'No Product',
                inv.Product__r != null ? inv.Product__r.Family : 'No Family',
                price
            ));
        }

        return inventoryList;
    }

    // Inventory 정보 및 관련된 Product 정보를 Wrapping
    public class InventoryWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String productName;
        @AuraEnabled public String family;
        @AuraEnabled public Decimal price;

        // 생성자 정의: 매개변수의 순서와 타입에 주의
        public InventoryWrapper(String id, Decimal amount, String productName, String family, Decimal price) {
            this.id = id;
            this.amount = amount;
            this.productName = productName;
            this.family = family;
            this.price = price;
        }
    }
}