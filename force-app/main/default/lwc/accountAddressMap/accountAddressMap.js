import { LightningElement, api, wire } from 'lwc';
import getAddressInfo from '@salesforce/apex/AccountBillingController.getAddressInfo';

export default class AccountAddressMap extends LightningElement {
    @api recordId;
    mapMarkers = [];
    zoomLevel = 18; // 이 값을 조정하여 확대/축소 수준 설정 (값이 낮을수록 더 멀리서 보여줍니다)

    @wire(getAddressInfo, { accountId: '$recordId' })
    loadCustomAddress({ error, data }) {
        console.log('Wire service result:', { error, data });

        if (data) {
            // 필요한 필드 데이터를 추출
            const street = data.Address_c__Street__s || '';
            const city = data.Address_c__City__s || '';
            const postalCode = data.Address_c__PostalCode__s || '';

            // 디버깅을 위한 콘솔 로그
            console.log('Street:', street);
            console.log('City:', city);
            console.log('PostalCode:', postalCode);

            // 유효한 주소 정보를 사용해 주소 문자열 구성
            let address = [street, city, postalCode].filter(Boolean).join(', ');

            console.log('Constructed Address:', address);

            // 유효한 주소가 있는 경우 지도 마커 설정
            if (address) {
                this.mapMarkers = [
                    {
                        location: {
                            Street: street,
                            City: city,
                            PostalCode: postalCode
                        },
                        title: 'Custom Address',
                        description: `Address: ${address}`,
                        icon: 'standard:account'
                    }
                ];
                console.log('Map Markers:', this.mapMarkers);
            } else {
                // 유효한 주소가 없는 경우 마커를 비웁니다.
                this.mapMarkers = [];
                console.warn('No valid address found to set map marker.');
            }
        } else if (error) {
            console.error('Error loading address information:', error);
            this.mapMarkers = [];
        }
    }
}