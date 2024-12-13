trigger ContractTrigger on Contract (after update) {
    // Check if the contract status has changed to '계약 이행'
    List<Id> contractsToProcess = new List<Id>();

    for (Contract con : Trigger.new) {
        if (con.Status == 'Activated' && Trigger.oldMap.get(con.Id).Status != 'Activated') {
            System.debug('계약 시행 한 건 추가');
            contractsToProcess.add(con.Id);
        }
    }

    if (!contractsToProcess.isEmpty()) {
        ContractHandlerController.enablePartnerAndCustomerUser(contractsToProcess);
    }
}