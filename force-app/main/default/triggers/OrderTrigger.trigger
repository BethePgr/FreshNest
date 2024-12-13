trigger OrderTrigger on Order (after insert, after update) {
    
    // 리스트 선언: 생성할 배송과 알림을 보낼 오더
    List<Delivery__c> deliveriesToCreate = new List<Delivery__c>();
    List<Order> ordersToNotify = new List<Order>();
    
    // Profile ID를 가져오기 위한 Map 생성
    Map<String, Id> profileIdMap = new Map<String, Id>();
    for (Profile prof : [SELECT Id, Name FROM Profile WHERE Name IN ('Customer Community Plus Login User', 'Sales')]) {
        profileIdMap.put(prof.Name, prof.Id);
    }

    // Order가 생성되었을 때를 처리하기 위한 로직
    if (Trigger.isInsert) {
        for (Order ord : Trigger.new) {
            // Order 소유자의 프로필 확인
            User ownerUser = [SELECT ProfileId FROM User WHERE Id = :ord.OwnerId];
            if (ownerUser.ProfileId == profileIdMap.get('Customer Community Plus Login User')) {
                ordersToNotify.add(ord);
            }
        }
    }

    // Order 상태가 '배송 요청'으로 변경될 때를 처리하기 위한 로직
    if (Trigger.isUpdate) {
        for (Order order : Trigger.new) {
            Order oldOrder = Trigger.oldMap.get(order.Id);

            // 주문 상태가 "배송 요청"으로 변경된 경우에만 처리
            if (order.Status == '배송 요청' && oldOrder.Status != '배송 요청') {
                Delivery__c newDelivery = new Delivery__c();
                newDelivery.Order__c = order.Id;
                newDelivery.Status__c = '배송 접수'; // 원하는 배송 상태로 설정
                newDelivery.Created_Date__c = DateTime.now(); // 현재 날짜 및 시간으로 설정
                deliveriesToCreate.add(newDelivery);
            }
        }
    }

    // 배송 레코드 생성
    if (!deliveriesToCreate.isEmpty()) {
        try {
            insert deliveriesToCreate;
            System.debug('Deliveries Created Successfully');
        } catch (DmlException e) {
            System.debug('Error creating Delivery records: ' + e.getMessage());
        }
    }
    
    // 알림 전송: 주문이 생성되었을 때 또는 배송 요청 상태로 변경되었을 때
    if (!ordersToNotify.isEmpty() || !deliveriesToCreate.isEmpty()) {
        try {
            // "Sales" 프로필을 가진 유저 조회
            Profile salesProfile = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
            System.debug('Sales Profile ID: ' + salesProfile.Id);
            
            List<User> salesUsers = [SELECT Id, Email FROM User WHERE ProfileId = :salesProfile.Id];
            System.debug('Sales Users: ' + salesUsers);
            
            // 이메일 알림 리스트 준비
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            // 각 세일즈 유저에게 이메일 알림을 보냅니다.
            for (User user : salesUsers) {
                // 이메일 알림 설정
                if (user.Email != null) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { user.Email });
                    email.setSubject('새 주문 알림');
                    email.setPlainTextBody('Customer Community Plus Login User 프로필을 가진 사용자가 새 주문을 생성하거나 배송요청 상태로 변경했습니다.');
                    emails.add(email);
                } else {
                    System.debug('User does not have an email: ' + user.Id);
                }
            }
            
            // 이메일 알림 전송
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
                System.debug('Emails sent successfully');
            } else {
                System.debug('No emails to send');
            }

            // Salesforce Notification 알림 생성
            CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='New_Order_Notification'];
            
            // 각 사용자에게 Salesforce Notification 전송
            for (User user : salesUsers) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('새 주문 또는 배송 요청 알림');
                notification.setBody('Customer Community Plus Login User 프로필을 가진 사용자가 새 주문을 생성하거나 배송요청 상태로 변경했습니다.');
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(!ordersToNotify.isEmpty() ? ordersToNotify[0].Id : deliveriesToCreate[0].Id);
                notification.setSenderId(user.Id);
                
                try {
                    // 각 사용자에게 개별적으로 Notification 전송
                    notification.send(new Set<String> {user.Id});
                } catch (Exception e) {
                    System.debug('Problem sending notification: ' + e.getMessage());
                }
            }
            System.debug('Notifications sent successfully');
        } catch (Exception e) {
            System.debug('Error sending notifications: ' + e.getMessage());
        }
    }
}