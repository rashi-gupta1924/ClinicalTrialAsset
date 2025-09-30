import { LightningElement, api, track, wire } from 'lwc';
import updateStatus from '@salesforce/apex/PatientConsentInviteController.updateStatus';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';

// Keep minimal fields for wire
const FIELDS = ['Patient_Consent_Invite__c.Id', 'Patient_Consent_Invite__c.Status__c'];

export default class PatientConsentInviteAccept extends LightningElement {
    @api recordId;
    @track isModalOpen = true; // open immediately when action button clicked
    statusValue = 'Enrollment Accepted';
    wiredRecordResult;
    @track currentStatus;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;
        if (data) {
            this.currentStatus = data.fields.Status__c.value;
            console.log('✅ Wired record received:', data);
        } else if (error) {
            console.error('❌ Wire error:', error);
        }
    }

    handleYesClick() {
        // close popup immediately
        this.isModalOpen = false;

        // call Apex update
        updateStatus({ recordId: this.recordId, statusValue: this.statusValue })
            .then(() => {
                this.showToast('Success', `Status updated to ${this.statusValue}`, 'success');
                return refreshApex(this.wiredRecordResult); // 🔄 refresh UI
            })
            .then(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showToast('Error', error.body?.message, 'error');
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    handleNoClick() {
        // close popup & quick action
        this.isModalOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}