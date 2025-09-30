import { LightningElement, api, track } from 'lwc';

// Columns for the final Patient datatable
const PATIENT_COLUMNS = [
    { label: 'Name', fieldName: 'patientName', type: 'text', sortable: true },
    { label: 'Age', fieldName: 'patientAge', type: 'number', sortable: true },
    { label: 'Status', fieldName: 'statusEnrolled', type: 'text', sortable: true },
    { label: 'Enrollment Date', fieldName: 'enrollmentDate', type: 'date-local', sortable: true, typeAttributes:{ month: "short", day: "2-digit", year: "numeric"} },
];

export default class GuidedHierarchyViewer extends LightningElement {
    
    _researchData = [];
    patientColumns = PATIENT_COLUMNS;

    // --- STATE MANAGEMENT ---
    @track researchStudy;
    @track currentStep = 'CRO'; // Initial step
    @track selectedCro;
    @track selectedHcf;
    @track selectedPcp;
    @track breadcrumbs = [];

    // --- DATA INPUT ---
    @api 
    get researchData() {
        return this._researchData;
    }
    
    set researchData(data) {
        if (data && data.length > 0) {
            // Deep copy to make data mutable and prevent side effects
            // this._researchData = JSON.parse(JSON.stringify(data));
            // this.researchStudy = this._researchData[0];
            // this._reset();

            let tempData = JSON.parse(JSON.stringify(data));

            tempData.forEach(rsWrapper => {
                if (rsWrapper.croWrapperList) {
                    rsWrapper.croWrapperList.forEach(croWrapper => {
                        if (croWrapper.hfWrapperList) {
                            croWrapper.hfWrapperList = croWrapper.hfWrapperList.filter(
                                hcf => hcf.status === 'Identified'
                            );
                        }
                    });
                }
            });

            console.log('Filtered tempData : ', JSON.stringify(tempData, null, 2));


            this._researchData = tempData;
            this.researchStudy = this._researchData[0];
            this._reset();

        }
    }

    // --- GETTERS FOR CONDITIONAL RENDERING ---
    get isCroStep() { return this.currentStep === 'CRO'; }
    get isHcfStep() { return this.currentStep === 'HCF'; }
    get isPcpStep() { return this.currentStep === 'PCP'; }
    get isPatientStep() { return this.currentStep === 'PATIENT'; }

    // --- GETTER FOR PATIENT DATA (adds dummy data for table) ---
    get patientData() {
        if (!this.selectedPcp) return [];
        return this.selectedPcp.elCandidateWrapperList;
    }

    // --- EVENT HANDLERS ---
    handleCroSelect(event) {
        const croId = event.currentTarget.dataset.id;
        this.selectedCro = this.researchStudy.croWrapperList.find(c => c.croId === croId);
        this.currentStep = 'HCF';
        console.log('OUTPUT : handleCroSelect');
        this._buildBreadcrumbs();
    }

    handleHcfSelect(event) {
        const hcfId = event.currentTarget.dataset.id;
        this.selectedHcf = this.selectedCro.hfWrapperList.find(h => h.hfId === hcfId);
        this.currentStep = 'PCP';
        console.log('OUTPUT : handleHcfSelect');
        this._buildBreadcrumbs();
    }

    handlePcpSelect(event) {
        const pcpId = event.currentTarget.dataset.id;
        this.selectedPcp = this.selectedHcf.pcpWrapperList.find(p => p.id === pcpId);
        this.currentStep = 'PATIENT';
        console.log('OUTPUT : handlePcpSelect');
        this._buildBreadcrumbs();
    }

    handleBreadcrumbNavigate(event) {
        const stepName = event.currentTarget.dataset.name;

        switch (stepName) {
            case 'ROOT':
                this._reset();
                break;
            case 'CRO':
                this.selectedHcf = null;
                this.selectedPcp = null;
                this.currentStep = 'HCF';
                break;
            case 'HCF':
                this.selectedPcp = null;
                this.currentStep = 'PCP';
                break;
            default:
                break;
        }
        this._buildBreadcrumbs();
    }


    // --- PRIVATE HELPER METHODS ---
    _reset() {
        this.currentStep = 'CRO';
        this.selectedCro = null;
        this.selectedHcf = null;
        this.selectedPcp = null;
        this._buildBreadcrumbs();
    }

    _buildBreadcrumbs() {
        console.log('OUTPUT : _buildBreadcrumbs', JSON.stringify(this.breadcrumbs));
        const crumbs = [{ label: this.researchStudy.name, name: 'ROOT' }];
        console.log(JSON.stringify(this.breadcrumbs));
        console.log(JSON.stringify(this.breadcrumbs));
        console.log(JSON.stringify(this.breadcrumbs));
        if (this.selectedCro) {
            crumbs.push({ label: this.selectedCro.croName, name: 'CRO' });
        }
        if (this.selectedHcf) {
            crumbs.push({ label: this.selectedHcf.hfName, name: 'HCF' });
        }
        if (this.selectedPcp) {
            // The last item in the breadcrumb is not a link, just text.
            crumbs.push({ label: this.selectedPcp.name, name: 'PCP' });
        }

        this.breadcrumbs = crumbs;
        console.log('OUTPUT : _buildBreadcrumbsv2', JSON.stringify(this.breadcrumbs));
    }
}