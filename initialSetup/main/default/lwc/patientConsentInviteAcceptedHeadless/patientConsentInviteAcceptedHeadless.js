import { LightningElement, api } from 'lwc';
import updateStatus from '@salesforce/apex/PatientConsentInviteController.updateStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';

export default class PatientConsentInviteAcceptedHeadless extends LightningElement {
    @api recordId;

    @api
    async invoke() {
        if (!this.recordId) {
            this.showToast('Error', 'No recordId found!', 'error');
            return;
        }

        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to update the status to Enrollment Accepted? Once updated, you cannot modify it.',
            variant: 'headerless', 
            label: 'Confirm Status Update' 
        });

        if (!confirmed) {
            // User clicked No — just close the popup
            this.dispatchEvent(new CloseActionScreenEvent());
            return;
        }

        const statusValue = 'Enrollment Accepted';
        console.log('🚀 Headless action invoked for recordId:', this.recordId);

        updateStatus({ recordId: this.recordId, statusValue })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.showToast('Success', `Status updated to ${statusValue}`, 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.error('❌ Error updating status:', error);
                this.showToast('Error', error.body?.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}