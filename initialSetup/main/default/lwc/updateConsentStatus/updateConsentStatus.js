import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateEnrollmentStatus from '@salesforce/apex/PatientConsentController.updateEnrollmentStatus';

export default class UpdateEnrollmentStatus extends LightningElement {
    @api recordId;   // Passed automatically when used as record action
    @api statusValue; // This will come from Action Button config

    connectedCallback() {
        this.updateStatus();
    }

    updateStatus() {
        updateEnrollmentStatus({ recordId: this.recordId, newStatus: this.statusValue })
            .then(() => {
                this.showToast('Success', `Enrollment updated to: ${this.statusValue}`, 'success');
                this.closeAction();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.closeAction();
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeAction() {
        const closeEvent = new CustomEvent('close');
        this.dispatchEvent(closeEvent);
    }
}