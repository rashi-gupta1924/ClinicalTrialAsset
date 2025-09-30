import { LightningElement, api } from 'lwc';

export default class PatientTable extends LightningElement {
    @api patients;
}