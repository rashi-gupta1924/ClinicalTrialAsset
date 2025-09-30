import { LightningElement, api, track, wire } from 'lwc';
import fetchTranscripts from '@salesforce/apex/LlmResponseFromTranscriptController.getTranscripts';
import invokeCustomerResponsePrompt from '@salesforce/apex/LlmResponseFromTranscriptController.invokeCustomerResponsePrompt';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Import LMS utilities
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import ConversationAgentSendChannel from '@salesforce/messageChannel/lightning__conversationAgentSend';
import ConversationEndUserMessageChannel from '@salesforce/messageChannel/lightning__conversationEndUserMessage';

export default class LlmResponseFromTranscript extends LightningElement {
    @track isAutomatic = false;
    @track isLoading = false;
    @track transcripts = [];
    @track LLM_Response = '';
    @track error;
    selectedTranscripts = [];
    @api recordId;
    isAllSelected = false; 
    subscription = null;

    // Wire MessageContext for LMS
    @wire(MessageContext)
    messageContext;

    handleToggle(event) {
        this.isAutomatic = event.target.checked;
        console.log('Automatic mode:', this.isAutomatic);
    }

    connectedCallback() {
        this.handleRefresh();
        this.subscribeToMessageChannels();
    }

    disconnectedCallback() {
        this.unsubscribeFromMessageChannels();
    }

    subscribeToMessageChannels() {
        if (!this.subscription) {
            // Subscribe to both agent send and customer message events
            this.subscription = subscribe(
                this.messageContext,
                ConversationAgentSendChannel,
                (message) => this.handleMessageEventAgent(message),
                { scope: APPLICATION_SCOPE }
            );

            this.subscription = subscribe(
                this.messageContext,
                ConversationEndUserMessageChannel,
                (message) => this.handleMessageEventUser(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeFromMessageChannels() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleMessageEventAgent(message){
        this.handleMessageEvent(message,'Agent');
    }

    handleMessageEventUser(message){
        this.handleMessageEvent(message,'EndUser');
    }

    handleMessageEvent(message,role) {
        console.log('New message received:', JSON.stringify(message) , '---------------',role);

        this.transcripts = [
            ...this.transcripts,
            {
                index: this.transcripts.length + 1,
                transcriptText: role + ' : ' + message.content,
                prefix: role + ' : ',
                suffix: message.content
            }
        ];
    }

    handleRefresh() {
        console.log('Refresh button clicked::> ', this.recordId);

        fetchTranscripts({ sessionId: this.recordId })
            .then(result => {
                console.log('Result Successfully:', result);

                this.transcripts = result.map((transcript, index) => {
                    const splitIndex = transcript.indexOf(':');
                    transcript = transcript.replace("&#39;", "'"); // Handle special characters
                    return {
                        index: index + 1,
                        transcriptText: transcript,
                        prefix: splitIndex !== -1 ? transcript.substring(0, splitIndex + 1) : '',
                        suffix: splitIndex !== -1 ? transcript.substring(splitIndex + 2) : transcript
                    };
                });
                this.error = undefined;
            })
            .catch(error => {
                console.error('Error:', error);
                this.error = error.body?.message || error.message || 'Unknown error';
                this.transcripts = [];
            });
    }

    handleCheckboxChange(event) {
        const transcriptText = event.target.dataset.text;
        if (event.target.checked) {
            this.selectedTranscripts.push(transcriptText);
        } else {
            this.selectedTranscripts.pop(transcriptText);
        }
    }

    handleGetLLMResponse() {
        if (this.selectedTranscripts.length === 0) {
            this.showToast('Error', 'Please select at least one transcript.', 'error');
            return;
        }
        this.isLoading = true;
        const selectedConversation = [...this.selectedTranscripts].join('\n');

        invokeCustomerResponsePrompt({ selectedConversation })
            .then(response => {
                this.handleDeselectAll();
                console.log('LLM Response:', response);
                this.LLM_Response = response;
                this.copyToClipboard(response);
                this.isLoading = false;
                this.showToast('Success', 'Response copied to clipboard!', 'success');
            })
            .catch(error => {
                console.error('Error fetching LLM response:', error);
                this.showToast('Error', 'Failed to get LLM response.', 'error');
            });
    }

    handleCopy(){
        this.copyToClipboard(this.LLM_Response);
    }

    copyToClipboard(text) {
        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text)
                .then(() => {
                    console.log('Text copied successfully using Clipboard API');
                })
                .catch(err => {
                    console.error('Clipboard API failed, using fallback method', err);
                });
        } else {
            console.error('unable to copy');
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleSelectAll() {
        if (this.isAllSelected) {
            this.handleDeselectAll();
        } else {
            const inputs = this.template.querySelectorAll('lightning-input');
            inputs.forEach(input => {
                if (input.type === 'checkbox') {
                    input.checked = true;
                    const text = input.dataset.text;
                    if (text !== '') {
                        this.selectedTranscripts.push(text);
                    }
                }
            });
            this.isAllSelected = !this.isAllSelected;
        }

        console.log('Selected Transcripts:', JSON.stringify(this.selectedTranscripts));
    }

    get selectAllLabel() {
        return this.isAllSelected ? 'Deselect All' : 'Select All';
    }

    handleDeselectAll() {
        const inputs = this.template.querySelectorAll('lightning-input');

        inputs.forEach(input => {
            if (input.type === 'checkbox') {
                input.checked = false;
            }
        });
        this.selectedTranscripts = [];
        console.log('All transcripts deselected');
        this.isAllSelected = !this.isAllSelected;

    }
}