import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import updateStatus from '@salesforce/apex/PatientConsentInviteController.updateStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';

// Keep existing FIELDS intact
const FIELDS = ['Patient_Consent_Invite__c.Id', 'Patient_Consent_Invite__c.Status__c'];

export default class PatientConsentInviteRejected extends LightningElement {
    @api recordId;
    statusValue = 'Enrollment Rejected';
    isModalOpen = true;
    @track currentStatus; // show current status in UI

    wiredRecordResult;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;
        if (data) {
            this.currentStatus = data.fields.Status__c.value;
            console.log('✅ Wired record received:', data);
        } else if (error) {
            console.error('❌ Wired record error:', error);
        }
    }

    handleYesClick() {
        if (!this.recordId) {
            this.showToast('Error', 'No recordId found!', 'error');
            return;
        }

        updateStatus({ recordId: this.recordId, statusValue: this.statusValue })
            .then(() => {
                this.showToast('Success', `Status updated to ${this.statusValue}`, 'success');
                return refreshApex(this.wiredRecordResult); // 🔄 refresh UI
            })
            .then(() => {
                this.isModalOpen = false; // close popup
            })
            .catch(error => {
                this.showToast('Error', error.body?.message, 'error');
                this.isModalOpen = false;
            });
    }

    handleNoClick() {
        this.isModalOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}