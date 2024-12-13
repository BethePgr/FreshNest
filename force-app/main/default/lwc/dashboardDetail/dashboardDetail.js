import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDashboardId from '@salesforce/apex/DashboardController.getDashboardId'; // Apex 메서드 임포트

export default class DashboardDetail extends NavigationMixin(LightningElement) {
    dashboardId;

    // 대시보드 ID를 Apex에서 가져옴
    @wire(getDashboardId, { dashboardName: '영업 매니저 대시보드_Detail' }) // 대시보드 이름 전달
    wiredDashboard({ error, data }) {
        if (data) {
            this.dashboardId = data;
        } else if (error) {
            console.error('Error retrieving dashboard ID:', error);
        }
    }

    handleClick() {
        if (this.dashboardId) {
            // 대시보드 ID가 있으면 대시보드로 네비게이션
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.dashboardId,
                    objectApiName: 'Dashboard',
                    actionName: 'view'
                }
            });
        } else {
            console.error('Dashboard ID not found');
        }
    }
}