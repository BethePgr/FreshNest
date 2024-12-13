// UserController.cls
public with sharing class UserController {
    @AuraEnabled(cacheable=true)
    public static String getAccountId() {
        try {
            User currentUser = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (currentUser.Contact == null || currentUser.Contact.AccountId == null) {
                throw new AuraHandledException('No Account found for the current user.');
            }
            
            return currentUser.Contact.AccountId;
        } catch (Exception e) {
            System.debug('Error fetching AccountId: ' + e.getMessage());
            throw new AuraHandledException('Unable to fetch AccountId');
        }
    }
}