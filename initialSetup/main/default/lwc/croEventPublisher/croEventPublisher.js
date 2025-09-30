import { LightningElement, api } from 'lwc';
//import firePlatformEvents from '@salesforce/apex/CROResearchStudyEventPublisher.firePlatformEvents';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CroEventPublisher extends LightningElement {
    // @api recordId;

    // connectedCallback() {
    //     // if (!this.recordId) {
    //     //     this.showToast('Error', 'Record ID not found', 'error');
    //     //     this.dispatchEvent(new CloseActionScreenEvent());
    //     //     return;
    //     // }

    //    setTimeout(() => {
    //         this.createEventRecord();
    //     }, 100);
    // }

    // createEventRecord(){
    //     firePlatformEvents({ croResearchStudyIds: [this.recordId] })
    //         .then(() => {
    //             this.showToast('Success', 'Platform Event published successfully!', 'success');
    //             this.dispatchEvent(new CloseActionScreenEvent());
    //             console.log('Successfully published event.');
    //         })
    //         .catch(error => {
    //             const message = error?.body?.message || 'Unknown error occurred';
    //             this.showToast('Error publishing event', message, 'error');
    //             this.dispatchEvent(new CloseActionScreenEvent());
    //         });
    // }
    // showToast(title, message, variant) {
    //     this.dispatchEvent(
    //         new ShowToastEvent({
    //             title: title,
    //             message: message,
    //             variant: variant
    //         })
    //     );
    // }
}