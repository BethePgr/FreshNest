import { LightningElement, wire } from 'lwc';
import getInventoriesWithProductDetails from '@salesforce/apex/InventoryController.getInventoriesWithProductDetails';

export default class InventoryTable extends LightningElement {
    inventoriesByCategory = {};
    expandedCategory = '';

    @wire(getInventoriesWithProductDetails)
    wiredInventories({ error, data }) {
        if (data) {
            this.inventoriesByCategory = data.reduce((acc, inventory) => {
                const category = inventory.productCategory || 'Other';
                if (!acc[category]) {
                    acc[category] = [];
                }
                acc[category].push({
                    name: inventory.productName,
                    price: inventory.price,
                    stock: inventory.amount,
                    id: inventory.id
                });
                return acc;
            }, {});
        } else if (error) {
            console.error('Error loading inventories:', error);
        }
    }

    toggleCategory(event) {
        const selectedCategory = event.currentTarget.dataset.category;
        this.expandedCategory = this.expandedCategory === selectedCategory ? '' : selectedCategory;
    }

    get categoryList() {
        return Object.keys(this.inventoriesByCategory).map(category => ({
            name: category,
            isExpanded: this.expandedCategory === category
        }));
    }

    getExpandedInventories(category) {
        return this.inventoriesByCategory[category] || [];
    }
}