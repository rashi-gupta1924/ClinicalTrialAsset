import { LightningElement, api, track } from 'lwc';
export default class showPatientDetailsModal extends LightningElement {
  _patient;
  @track detailRows = [];

  @api
  get patient() {
    return this._patient;
  }
  set patient(value) {
    this._patient = value || {};
    this.buildRowsFromWrapper();
  }

  get headerTitle() {
    const p = this._patient || {};
    const name = p.patientName || 'Patient';
    const status = p.statusEnrolled ? ` • ${p.statusEnrolled}` : '';
    return `${name}${status}`;
  }

  get hasAnyAgentNotes() {
    const p = this._patient || {};
    return !!(p.siteLLMResponse || p.pcpLLMResponse || p.croLLMResponse);
  }

  buildRowsFromWrapper() {
    const p = this._patient || {};
    const val = (x) => (x === 0 || x ? String(x) : '—');

    this.detailRows = [

      {label: 'Name',value: val(p.patientName),recordId: p.idEnrolled,recordUrl: '/' + p.idEnrolled,isName: true},
      { label: 'Age', value: val(p.patientAge) },
      { label: 'Weight (kg)', value: val(p.patientWeight) },
      { label: 'BMI', value: val(p.patientBMI) },
      { label: 'Blood Pressure', value: val(p.patientBP) },
      { label: 'ECG Status', value: val(p.patientEcgStatus) },
      { label: 'Sugar Status', value: val(p.sugarStatus) },
      { label: 'Hepatic Function', value: val(p.patientHepaticFunction) },
      { label: 'Status', value: val(p.statusEnrolled) },
      { label: 'Eligibility Score', value: val(p.score) },
      { label: 'Site Agent LLM Response', value: val(p.siteLLMResponse) },
      { label: 'PCP Agent LLM Response', value: val(p.pcpLLMResponse) },
      { label: 'CRO Agent LLM Response', value: val(p.croLLMResponse) }
    ];
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent('close'));
  }
}