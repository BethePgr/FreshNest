// ProductsTableByFamily.js

import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import saveOrder from '@salesforce/apex/OrderController.saveOrder';
import getAccountId from '@salesforce/apex/UserController.getAccountId';

export default class ProductsTableByFamily extends LightningElement {
    productsByFamily = {};
    expandedFamily = '';
    cartItems = [];
    accountId;

    // 컴포넌트가 DOM에 추가될 때 accountId 가져오기
    connectedCallback() {
        getAccountId()
            .then((result) => {
                this.accountId = result;
                //console.log('Fetched Account ID:', this.accountId);
            })
            .catch((error) => {
                console.log('no accountId logic');
                //console.error('Error fetching account ID:', error);
                this.accountId = null; 
            });
    }

    @wire(getProducts)
    wiredProducts({ error, data }) {
        if (data) {
            this.productsByFamily = data.reduce((acc, product) => {
                const family = product.family || 'Other';
                if (!acc[family]) {
                    acc[family] = [];
                }
                acc[family].push({
                    name: product.name,
                    price: product.price !== 0 ? product.price : 'No Price Available',
                    stockAmount: product.stockAmount,
                    quantity: 1
                });
                return acc;
            }, {});
        } else if (error) {
            console.error('Error loading products:', error);
        }
    }

    handleUpdateQuantity(event) {
        const productName = event.target.dataset.name;
        const newQuantity = parseInt(this.template.querySelector(`[data-cart-quantity="${productName}"]`).value, 10);

        const itemIndex = this.cartItems.findIndex(item => item.name === productName);
        if (itemIndex > -1 && newQuantity > 0) {
            // 수량 업데이트
            this.cartItems[itemIndex].quantity = newQuantity;
            // 총 가격 업데이트
            this.cartItems[itemIndex].totalPrice = newQuantity * this.cartItems[itemIndex].price;
            this.cartItems[itemIndex].formattedTotalPrice = this.formatPrice(this.cartItems[itemIndex].totalPrice); // 총 금액 포맷

            // 상태를 다시 설정하여 변경 사항을 반영
            this.cartItems = [...this.cartItems];
        } else {
            // 수량이 잘못된 경우 사용자에게 오류 표시
            const evt = new ShowToastEvent({
                title: 'Error',
                message: '수량은 1보다 커야 합니다.',
                variant: 'error'
            });
            this.dispatchEvent(evt);
        }
    }

    handleRemoveFromCart(event) {
        const productName = event.target.dataset.name;

        // 카트에서 항목 제거
        const updatedCartItems = this.cartItems.filter(item => item.name !== productName);

        // 변경 사항 반영
        this.cartItems = [...updatedCartItems];

        // 사용자에게 항목 제거 성공을 알림
        const evt = new ShowToastEvent({
            title: 'Item Removed',
            message: `${productName}이(가) 장바구니에서 제거되었습니다.`,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    toggleFamily(event) {
        const selectedFamily = event.currentTarget.dataset.family;
        this.expandedFamily = this.expandedFamily === selectedFamily ? '' : selectedFamily;
    }

    handleAddToCart(event) {
        const productName = event.target.dataset.name;
        const productPrice = parseFloat(event.target.dataset.price);
        const quantityInput = this.template.querySelector(`[data-quantity="${productName}"]`).value;
        const quantity = parseInt(quantityInput, 10);

        const existingItemIndex = this.cartItems.findIndex(item => item.name === productName);

        if (existingItemIndex > -1) {
            this.cartItems[existingItemIndex].quantity += quantity;
            this.cartItems[existingItemIndex].totalPrice += productPrice * quantity;
            this.cartItems[existingItemIndex].formattedPrice = this.formatPrice(this.cartItems[existingItemIndex].totalPrice); // 총 금액을 포맷

        } else {
            this.cartItems.push({
                name: productName,
                price: productPrice,
                formattedPrice: this.formatPrice(productPrice),
                quantity: quantity,
                totalPrice: productPrice * quantity,
                formattedTotalPrice: this.formatPrice(productPrice * quantity) // 가격을 포맷하여 저장

            });
        }

        this.cartItems = [...this.cartItems]; // 변경 사항 감지
    }
    handlePlaceOrder() {
        // 올바른 형태의 객체 생성
        const orderDetails = {
            accountId: this.accountId,
            cartItems: this.cartItems.map(item => ({
                productName: item.name,
                unitPrice: item.price,
                amount: item.quantity,
                totalPrice: item.totalPrice
            })),
            totalCartPrice: this.totalCartPrice
        };

        // 디버그 로그로 확인하기
        console.log('saveOrder 호출:', JSON.stringify(orderDetails));
        orderDetails.cartItems.forEach(item => {
            if (item.unitPrice <= 0) {
                console.error('Invalid unit price detected:', item);
            }
            if (item.quantity <= 0) {
                console.error('Invalid quantity detected:', item);
            }
        });
        // Apex 메서드 호출
        saveOrder({ orderDetails: JSON.stringify(orderDetails) })
            .then(() => {
                // 성공 시 처리
                this.cartItems = [];
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: '주문이 완료되었습니다.',
                    variant: 'success'
                });
                this.dispatchEvent(evt);
                console.log('Order has been placed successfully.');
            })
            .catch((error) => {
                // 에러 시 처리
                let errorMessage = '주문을 저장하는 중 오류가 발생했습니다.';
                if (error.body && error.body.message) {
                    errorMessage += ' 상세: ' + error.body.message;
                }

                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                });
                this.dispatchEvent(evt);

                console.error('Error placing order:', JSON.stringify(error)); // 에러 상세 출력
            });
    }

    formatPrice(price) {
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(price);
    }

    get totalCartPriceTwo() {
        return this.formatPrice(this.cartItems.reduce((acc, item) => acc + item.totalPrice, 0));
    }

    get totalCartPrice() {
        return this.cartItems.reduce((acc, item) => acc + item.totalPrice, 0);
    }

    get familyList() {
        return Object.keys(this.productsByFamily).map(family => ({
            name: family,
            isExpanded: this.expandedFamily === family
        }));
    }

    get expandedProducts() {
        return (this.productsByFamily[this.expandedFamily] || []).map(product => {
            return {
                ...product,
                formattedPrice: this.formatPrice(product.price) 
            };
        });
    }

    get hasCartItems() {
        return this.cartItems.length > 0;
    }

    // 가격 포맷 함수
    formatPrice(price) {
        return new Intl.NumberFormat('ko-KR', {
            style: 'currency',
            currency: 'KRW',
            minimumFractionDigits: 0
        }).format(price);
    }
}