public with sharing class DashboardController {
    @AuraEnabled(cacheable=true)
    public static String getDashboardId(String dashboardName) {
        // 대시보드 이름을 기준으로 ID를 검색
        Dashboard d = [SELECT Id FROM Dashboard WHERE Title = :dashboardName LIMIT 1];
        return d.Id;
    }
}