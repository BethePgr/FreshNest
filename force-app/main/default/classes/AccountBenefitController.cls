public with sharing class AccountBenefitController {
    @AuraEnabled(cacheable=true)
    public static ContractWrapper getLatestActivatedContract() {
        Id accountId = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.AccountId;

        if (accountId == null) {
            throw new AuraHandledException('사용자의 AccountId를 찾을 수 없습니다.');
        }

        // 최신의 활성화된 계약을 조회하여 Pricebook 정보를 가져옴
        Contract latestActivatedContract = [
            SELECT Pricebook2.Name
            FROM Contract
            WHERE AccountId = :accountId

            ORDER BY StartDate DESC
            LIMIT 1
        ];

        if (latestActivatedContract == null || latestActivatedContract.Pricebook2 == null) {
            System.debug('활성화된 계약이 없거나 Pricebook이 설정되어 있지 않습니다.');
            throw new AuraHandledException('활성화된 계약이 없습니다.');
        }

        System.debug('Pricebook Name: ' + latestActivatedContract.Pricebook2.Name); // 디버그: Pricebook 이름 출력
        return new ContractWrapper(latestActivatedContract.Pricebook2.Name);
    }

    // ContractWrapper 클래스 정의
    public class ContractWrapper {
        @AuraEnabled public String PricebookName;

        public ContractWrapper(String pricebookName) {
            this.PricebookName = pricebookName;

        }
    }
}