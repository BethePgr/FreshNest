import { LightningElement } from 'lwc';
import bronzeBenefit from '@salesforce/resourceUrl/BronzeBenefit';
import silverBenefit from '@salesforce/resourceUrl/SilverBenefit';
import goldBenefit from '@salesforce/resourceUrl/GoldBenefit';

export default class BenefitsDisplay extends LightningElement {
    bronzeImage = bronzeBenefit;
    silverImage = silverBenefit;
    goldImage = goldBenefit;

    benefits = [
        {
            range: '1억 ~ 2억',
            image: this.bronzeImage,
            discount: '5% 할인'
        },
        {
            range: '2억 ~ 3억',
            image: this.silverImage,
            discount: '10% 할인'
        },
        {
            range: '3억 이상',
            image: this.goldImage,
            discount: '15% 할인'
        }
    ];
}