import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createAndLinkGap from '@salesforce/apex/ProductGapQuickActionController.createAndLinkGap';
import searchExistingGaps from '@salesforce/apex/ProductGapQuickActionController.searchExistingGaps';
import linkExistingGap from '@salesforce/apex/ProductGapQuickActionController.linkExistingGap';

const MODE_CREATE = 'create';
const MODE_LINK = 'link';

export default class ProductGapQuickAction extends LightningElement {
    @api recordId; // Opportunity Id — passed automatically by quick action

    @track selectedMode = MODE_CREATE;
    @track gapName = '';
    @track gapDescription = '';
    @track gapCategory = '';
    @track gapStatus = 'New';
    @track searchTerm = '';
    @track searchResults = [];
    @track selectedGapId = null;
    @track selectedGapName = '';
    @track errorMessage = '';
    @track isSaving = false;

    get isCreateMode() {
        return this.selectedMode === MODE_CREATE;
    }

    get modeOptions() {
        return [
            { label: 'Create New Gap', value: MODE_CREATE },
            { label: 'Link Existing Gap', value: MODE_LINK }
        ];
    }

    get categoryOptions() {
        return [
            { label: 'Integrations', value: 'Integrations' },
            { label: 'Reporting', value: 'Reporting' },
            { label: 'Security', value: 'Security' }
        ];
    }

    get statusOptions() {
        return [
            { label: 'New', value: 'New' },
            { label: 'Under Review', value: 'Under Review' },
            { label: 'Roadmap', value: 'Roadmap' },
            { label: 'Closed', value: 'Closed' }
        ];
    }

    handleModeChange(event) {
        this.selectedMode = event.detail.value;
        this.errorMessage = '';
    }

    handleNameChange(event) {
        this.gapName = event.detail.value;
    }

    handleDescriptionChange(event) {
        this.gapDescription = event.detail.value;
    }

    handleCategoryChange(event) {
        this.gapCategory = event.detail.value;
    }

    handleStatusChange(event) {
        this.gapStatus = event.detail.value;
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        if (this.searchTerm.length >= 2) {
            this.runSearch();
        } else {
            this.searchResults = [];
        }
    }

    runSearch() {
        searchExistingGaps({ searchTerm: this.searchTerm })
            .then(results => {
                this.searchResults = results;
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : error.message;
            });
    }

    handleSelectGap(event) {
        this.selectedGapId = event.currentTarget.dataset.id;
        this.selectedGapName = event.currentTarget.dataset.name;
        this.searchResults = [];
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave() {
        this.errorMessage = '';
        this.isSaving = true;

        if (this.selectedMode === MODE_CREATE) {
            if (!this.gapName || !this.gapCategory || !this.gapStatus) {
                this.errorMessage = 'Please fill in all required fields.';
                this.isSaving = false;
                return;
            }
            createAndLinkGap({
                opportunityId: this.recordId,
                name: this.gapName,
                description: this.gapDescription,
                category: this.gapCategory,
                status: this.gapStatus
            })
                .then(() => {
                    this.dispatchToast('success', 'Product gap created and linked.');
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch(error => {
                    this.errorMessage = error.body ? error.body.message : error.message;
                    this.isSaving = false;
                });
        } else {
            if (!this.selectedGapId) {
                this.errorMessage = 'Please select a product gap to link.';
                this.isSaving = false;
                return;
            }
            linkExistingGap({
                opportunityId: this.recordId,
                productGapId: this.selectedGapId
            })
                .then(() => {
                    this.dispatchToast('success', 'Product gap linked successfully.');
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch(error => {
                    this.errorMessage = error.body ? error.body.message : error.message;
                    this.isSaving = false;
                });
        }
    }

    dispatchToast(variant, message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Success', message, variant }));
    }
}
