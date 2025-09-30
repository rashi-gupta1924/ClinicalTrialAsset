import { LightningElement, api, track } from 'lwc';
import getResearchStudyDetails from '@salesforce/apex/ClinicalTrialWrapperController.getResearchStudyDetails';

export default class ClinicalTrialHierarchy extends LightningElement {
  _rsWrapperList = [];

  // derived + selection state
  @track rs;
  @track croList = [];
  @track selectedCRO = {};
  @track selectedHCF = {};
  @track selectedPCP = {};
  @track selectedPatient = {};
  @track showDetails = false;

  // Properties to hold the vertical offsets for positioning the columns
  @track hcfColumnTopOffset = 0;
  @track pcpColumnTopOffset = 0;
  @track patientColumnTopOffset = 0;

  @api 
  get rsWrapperList() {
      return this._rsWrapperList;
  }
  
  set rsWrapperList(data) {
      if (data && data.length > 0) {
          this._rsWrapperList = JSON.parse(JSON.stringify(data));
          this.initFromWrapper();
      }
  }

  connectedCallback() {
    this.initFromWrapper();
  }

  renderedCallback() {
    if (!this.rs && this._rsWrapperList && this._rsWrapperList.length) {
      this.initFromWrapper();
    }
  }

  initFromWrapper() {
    if (!Array.isArray(this._rsWrapperList) || this._rsWrapperList.length === 0) return;
    this.rs = this._rsWrapperList[0];
    console.log('this.rs : ',JSON.stringify(this.rs));
    this.croList = this.rs.croWrapperList || [];

    // Reset selections and offsets
    this.selectedCRO = {};
    this.selectedHCF = {};
    this.selectedPCP = {};
    this.selectedPatient = {};
    this.hcfColumnTopOffset = 0;
    this.pcpColumnTopOffset = 0;
    this.patientColumnTopOffset = 0;

    if (this.croList.length === 1) {
        this.selectedCRO = this.croList[0];
    }
  }

  // --- Event Handlers ---
  onCROClick(evt) {
    const id = evt.currentTarget.dataset.id;
    const next = (this.croList || []).find(c => c.croId === id) || {};
    this.selectedCRO = next;
    this.selectedHCF = {};
    this.selectedPCP = {};
    this.hcfColumnTopOffset = evt.currentTarget.offsetTop;
    this.pcpColumnTopOffset = 0;
    this.patientColumnTopOffset = 0;
  }

  onHCFClick(evt) {
    const id = evt.currentTarget.dataset.id;
    const list = this.selectedCRO?.hfWrapperList || [];
    const next = list.find(h => h.hfId === id) || {};
    this.selectedHCF = next;
    this.selectedPCP = {};
    this.pcpColumnTopOffset = evt.currentTarget.offsetTop;
    this.patientColumnTopOffset = 0;
  }

  onPCPClick(evt) {
    const id = evt.currentTarget.dataset.id;
    const list = this.selectedHCF?.pcpWrapperList || [];
    const next = list.find(p => p.id === id) || {};
    this.selectedPCP = next;
    this.patientColumnTopOffset = evt.currentTarget.offsetTop;
  }

handlePatientCardClick(event) {
  console.log('Index -->' +   event.currentTarget.dataset.index);
  const idx = Number(event.currentTarget.dataset.index);
  const list = this.selectedPCP?.elCandidateWrapperList || [];
  console.log(list);
  this.selectedPatient = JSON.parse(JSON.stringify(list[idx] || {}));
  console.log(this.selectedPatient);
  this.showDetails = true;
}

handlePatientCardKeyDown(event) {
  // Open on Enter/Space for accessibility
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault();
    this.handlePatientCardClick(event); 
  }
}


handleCloseDetails() {
    this.showDetails = false;
    this.selectedPatient = null;
  }

  // --- GETTERS FOR DYNAMIC STYLES ---
  get hcfContainerStyle() {
    return `padding-top: ${this.hcfColumnTopOffset}px;`;
  }

  get pcpContainerStyle() {
    return `padding-top: ${this.pcpColumnTopOffset}px;`;
  }

  get patientContainerStyle() {
    return `padding-top: ${this.patientColumnTopOffset}px;`;
  }

  get decoratedHFs() {
    return (this.selectedCRO?.hfWrapperList || []).map(hf => {
      return {
        ...hf,
        dynamicClass: `flow-box txt-16 ${hf.cssClass}` + 
                      (hf.status === 'Identified' ? ' slds-is-clickable' : '')
      };
    });
  }

}