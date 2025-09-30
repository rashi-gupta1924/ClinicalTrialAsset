import { LightningElement, api, track } from 'lwc';
export default class TestClinicalTrialHierarchy extends LightningElement{
    // The @api decorator makes this property public, so the parent component can provide the data.
    _researchData = [];

    @track researchStudy;

    @api 
    get researchData() {
        return this._researchData;
    }
    
    set researchData(data) {
        if (data && data.length > 0) {
            this._researchData = JSON.parse(JSON.stringify(data)); // Deep copy to make it mutable
            // this.researchStudy = this._researchData[0]; 
            let study = this._researchData[0];
            study.croWrapperList = study.croWrapperList.map(cro => {
                return {
                    ...cro,
                    hfWrapperList: cro.hfWrapperList
                        ? cro.hfWrapperList.filter(hcf => hcf.status === 'Identified')
                        : []
                };
            });

            this.researchStudy = study
        } else {
            this.researchStudy = undefined;
        }
    }
}