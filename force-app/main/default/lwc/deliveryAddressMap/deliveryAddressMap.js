import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { loadScript } from 'lightning/platformResourceLoader';

// Address 필드 가져오기
import ADDRESS_FIELD from '@salesforce/schema/Delivery__c.Address__c'; // Address 데이터 타입 필드

// Google Maps API Key (Static Resource나 직접 입력)
const GOOGLE_MAPS_API_KEY = 'YOUR_GOOGLE_MAPS_API_KEY';
const FIELDS = [ADDRESS_FIELD];

export default class DeliveryAddressMap extends LightningElement {
    @api recordId; // 레코드 ID
    @track mapMarkers = [];
    isGoogleMapsInitialized = false;

    // 레코드 데이터 가져오기 (주소 정보 포함)
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            // 레코드에서 Address 필드의 값을 가져옴
            const addressData = data.fields.Address__c.value;
            if (addressData) {
                // Address 필드에서 세부 주소를 추출하여 하나의 문자열로 만듦
                const { country, city, street, postalCode } = addressData;
                const fullAddress = `${street}, ${city}, ${postalCode}, ${country}`;
                this.geocodeAddress(fullAddress);  // 주소를 바탕으로 지도에 마커 표시
            }
        } else if (error) {
            console.error('Error fetching Delivery__c record:', error);
        }
    }

    // Google Maps API에서 주소의 좌표를 찾아 지도에 마커 표시
    geocodeAddress(address) {
        console.log('Geocode status:', status);

        if (!this.isGoogleMapsInitialized) {
            this.loadGoogleMapsAPI().then(() => {
                this.geocodeAddress(address);  // API 로드 후 다시 시도
            });
            return;
        }

        const geocoder = new google.maps.Geocoder();
        geocoder.geocode({ address: address }, (results, status) => {
            if (status === 'OK') {
                const location = results[0].geometry.location;
                this.mapMarkers = [{
                    location: {
                        Latitude: location.lat(),
                        Longitude: location.lng()
                    },
                    title: results[0].formatted_address,
                    description: 'Delivery Location'
                }];
            } else {
                console.error('Geocode was not successful for the following reason:', status);
            }
        });
    }

    // Google Maps API 로드
    loadGoogleMapsAPI() {
        console.log('Geocode status:', status);
        return loadScript(this, `https://maps.googleapis.com/maps/api/js?key=AIzaSyDeu-42tVy-_teSWSKG-CNu-jI_q9Kpkrs&libraries=places`)
            .then(() => {
                this.isGoogleMapsInitialized = true;
            })
            .catch(error => {
                console.error('Error loading Google Maps API:', error);
            });
    }
}