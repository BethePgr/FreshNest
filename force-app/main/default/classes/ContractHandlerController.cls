public with sharing class ContractHandlerController {
    public static void enablePartnerAndCustomerUser(List<Id> contractIds) {
        // Get Contracts and their related Accounts
        List<Contract> contracts = [SELECT Id, AccountId, (SELECT Id, ContactId, Role, IsPrimary FROM ContractContactRoles) 
                                    FROM Contract 
                                    WHERE Id IN :contractIds];
        
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Id> primaryContactMap = new Map<Id, Id>();
        
        for (Contract con : contracts) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
                
                // Find the primary contact
                for (ContractContactRole role : con.ContractContactRoles) {
                    if (role.IsPrimary) {
                        primaryContactMap.put(con.AccountId, role.ContactId);
                        System.debug('안녕 con은' + con);
                        System.debug('안녕 accountId = ' + con.AccountId);
                    }
                }
            }
        }

        // Enable Accounts as Partners if not already enabled
        List<Account> accountsToEnable = [SELECT Id, IsPartner FROM Account WHERE Id IN :accountIds];
        System.debug('accountstoenable  = ' + accountsToEnable);
        List<Account> accountsToUpdate = new List<Account>();

        for (Account acc : accountsToEnable) {
            if (!acc.IsPartner) {
                acc.IsPartner = true;
                accountsToUpdate.add(acc);
                System.debug('update 추가 = ' + acc);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
        System.debug('accountstoupdate까지는 완료 이제부터는 contacts');
        System.debug('primaryContactMap.key() = ' + primaryContactMap.keySet());
        System.debug('primaryContactMap.values() = ' + primaryContactMap.values());
        // Enable Contacts as Customer Users
        List<Contact> contactsToEnable = [SELECT Id, AccountId, Email, FirstName, LastName FROM Contact WHERE Id IN :primaryContactMap.values()];
        //System.debug('contactsToEnable = ' + contactsToEnable.get(0));
        List<User> usersToCreate = new List<User>();

        for (Contact con : contactsToEnable) {
            System.debug('for문 시작');
            system.debug('con.accountId = ' + con.accountId);
            if (primaryContactMap.containsKey(con.AccountId)) {
                System.debug('일단 contact for문 돌리는 중 con = ' + con);
                if (con.AccountId != null) {
                    System.debug('일단 이녀석의 accountId는 null이 아님');
                    List<User> existingUser = [SELECT Id FROM User WHERE ContactId = :con.Id LIMIT 1];
                    System.debug('ㅎㅇ');
                    if (existingUser.isEmpty()) {
                        System.debug('비어잇음');
                        User newUser = new User(
                            Username = 'twin' + con.Email,
                            Email = con.Email,
                            LastName = con.LastName,
                            FirstName = con.FirstName,
                            ContactId = con.Id,
                            Alias = con.LastName + ' ' +con.FirstName,
                            TimeZoneSidKey = 'Asia/Seoul',
                            LocaleSidKey = 'ko_KR',
                            EmailEncodingKey = 'UTF-8',
                            ProfileId = [SELECT Id FROM Profile WHERE Name = 'custom custom cpl User' LIMIT 1].Id,
                            LanguageLocaleKey = 'ko'
                        );
                        usersToCreate.add(newUser);
                    }
                }
            }
        }

        if (!usersToCreate.isEmpty()) {
            insert usersToCreate;
            System.debug('사용자 생성 완료: ' + usersToCreate);

            //새로 생성된 사용자의 이메일 전송 및 비밀번호 재설정 로직 추가
            List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

            for (User newUser : usersToCreate) {
                // 비밀번호 재설정 URL 생성
                
                String resetUrl = 'https://democom-e0-dev-ed.develop.my.site.com/s/login/ForgotPassword';
                
                // 이메일 생성
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{newUser.Email});
                email.setSubject('Welcome to our community, FreshNest!');
                email.setPlainTextBody(
                    '안녕하세요, ' + newUser.Alias + '님!\n\n' +
                    '당신의 username은 ' + newUser.Username + '입니다.' + 
                    '저희 회사에 가입해주셔서 감사합니다. 아래의 링크를 통해 비밀번호를 설정하실 수 있습니다:\n' +
                    resetUrl + '\n\n' +
                    '감사합니다!'
                );

                emailMessages.add(email);
            }

            // 이메일 전송
            if (!emailMessages.isEmpty()) {
                Messaging.sendEmail(emailMessages);
                System.debug('이메일 전송 완료');
            }
        }
    }
}