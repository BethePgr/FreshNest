// OrderButton.js
import { LightningElement, api } from 'lwc';
// import getAccountId from '@salesforce/apex/UserController.getAccountId';

export default class OrderButton extends LightningElement {
    @api cartItems = [];
    @api totalCartPrice;
    @api accountId;

    // 컴포넌트가 DOM에 추가될 때 accountId 가져오기
    // connectedCallback() {
    //     getAccountId()
    //         .then((result) => {
    //             this.accountId = result;
    //             console.log('Fetched Account ID:', this.accountId);
    //         })
    //         .catch((error) => {
    //             console.error('Error fetching account ID:', error);
    //         });
    // }

    handlePlaceOrder() {
        console.log('Account ID:', this.accountId);

        const orderDetails = {
            accountId: this.accountId,
            cartItems: this.cartItems.map(cartItem => ({
                // expirationDate: cartItem.Expiration_Date__c, // 유통기한
                amount: cartItem.quantity, // 제품 수량
                unitPrice: cartItem.price, // 제품 1개 가격
                totalPrice: cartItem.totalPrice, // 제품 총 가격
                // productCategory: cartItem.Product_Category__c, // 제품 카테고리
                // productionCode: cartItem.Production_code__c, // 제품 코드
                productName: cartItem.name // 제품명 (Lookup(제품))
            })),
            totalCartPrice: this.totalCartPrice
        };

        const placeOrderEvent = new CustomEvent('placeorder', {
            detail: { orderDetails: orderDetails }
        });
        this.dispatchEvent(placeOrderEvent);
    }
}