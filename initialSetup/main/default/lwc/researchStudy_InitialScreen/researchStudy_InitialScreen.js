import { LightningElement, track } from 'lwc';
import getResearchStudies from '@salesforce/apex/ResearchStudyInitialScreenController.getResearchStudies';
import getCROsByStudy from '@salesforce/apex/ResearchStudyInitialScreenController.getCROsByStudy';
import getResearchStudyDetails from '@salesforce/apex/ClinicalTrialWrapperController.getResearchStudyDetails';

export default class ResearchStudy_InitialScreen extends LightningElement {
    @track studyOptions = [];
    @track croList = [];
    @track errorMessage = '';
    @track isLoading = false;


    selectedStudy = '';
    selectedCROs = [];

    @track rsWrapperList = [];
    @track showHierarchy = false;

    get isSubmitDisabled() {
        return !(this.selectedStudy && this.selectedCROs.length > 0);
    }

    get isRefreshDisabled() {
        return !(this.showHierarchy);
    }

    connectedCallback() {
        this.loadResearchStudies();
    }

    async loadResearchStudies() {
        try {
            const studies = await getResearchStudies();
            this.studyOptions = studies.map(s => ({
                label: s.Name,
                value: s.Id
            }));
        } catch (error) {
            console.error('Error loading studies', error);
        }
    }

    async handleStudyChange(event) {
        this.selectedStudy = event.detail.value;
        this.selectedCROs = [];
        this.errorMessage = '';

        try {
            const cros = await getCROsByStudy({ studyId: this.selectedStudy });
            if (!cros || cros.length === 0) {
                this.croList = [];
                this.errorMessage = 'The selected research study has no ongoing processes at this time.';
                return;
            }
            this.croList = cros.map(cro => ({
                label: cro.Name,
                value: cro.Id,
                isSelected: false
            }));
        } catch (error) {
            console.error('Error loading CROs', error);
            this.croList = [];
            this.errorMessage = 'Error retrieving CROs for the selected study.';
        }
    }

    handleCROSelection(event) {
        const { value, checked } = event.target;
        if (checked) {
            this.selectedCROs = [...this.selectedCROs, value];
        } else {
            this.selectedCROs = this.selectedCROs.filter(id => id !== value);
        }
        this.croList = this.croList.map(cro => ({
            ...cro,
            isSelected: cro.value === value ? checked : cro.isSelected
        }));
    }

    async handleSubmit() {
        this.isLoading = true;
        try {
            const data = await getResearchStudyDetails({ 
                researchStudyId: this.selectedStudy,
                selectedCROs: this.selectedCROs
            });
            
            console.log('Wrapper Data:', data);
            console.log('Wrapper Data JSON:', JSON.stringify(data, null, 2));

            this.rsWrapperList = data;
            this.showHierarchy = true;
            this.isLoading = false;
        } catch (error) {
            console.error('Error fetching research study details', error);
        }
    }
}