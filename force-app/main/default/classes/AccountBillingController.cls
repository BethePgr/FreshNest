public with sharing class AccountBillingController {
    @AuraEnabled(cacheable=true)
    public static Account getAddressInfo(Id accountId) {
        try {
            Account acc = [
                SELECT Address_c__Street__s, 
                       Address_c__City__s, 
                       Address_c__PostalCode__s
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
            return acc;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching address information: ' + e.getMessage());
        }
    }
}