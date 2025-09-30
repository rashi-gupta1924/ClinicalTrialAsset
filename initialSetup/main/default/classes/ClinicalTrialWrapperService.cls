/**
* @File Name : ClinicalTrialWrapperController.cls
* @Description : 
* @Author : Nitin Karan;
* @Last Modified On : August 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 | Nitn Karan  | Initial Version
**/

public with sharing class ClinicalTrialWrapperService {

    public List<RSWrapper> rsWrapperList;

    public class RSWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String cssClass;
        @AuraEnabled public List<CROWrapper> croWrapperList;
        @AuraEnabled public Research_Study__c resStudy;
    }

    public class CROWrapper {
        @AuraEnabled public Id croId;
        @AuraEnabled public String croName;
        @AuraEnabled public String status;
        @AuraEnabled public Id researchStudyId;
        @AuraEnabled public String cssClass;
        @AuraEnabled public List<HFWrapper> hfWrapperList;
        @AuraEnabled public Boolean hasChildren;
        @AuraEnabled public Boolean isExpanded;
    }

    public class HFWrapper {
        @AuraEnabled public Id hfId;
        @AuraEnabled public String hfName;
        @AuraEnabled public String status;
        @AuraEnabled public List<PCPWrapper> pcpWrapperList;
        @AuraEnabled public String cssClass;
        @AuraEnabled public Boolean isIdentified;
        @AuraEnabled public Boolean hasChildren;
        @AuraEnabled public Boolean isExpanded;
    }

    public class PCPWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public String speciality;
        @AuraEnabled public String cssClass;
        @AuraEnabled public List<ELCandidateWrapper> elCandidateWrapperList;
        @AuraEnabled public Id researchStudyId;
        @AuraEnabled public Id healthcareFacilityId;
        @AuraEnabled public Boolean hasChildren;
        @AuraEnabled public Boolean isExpanded;
    }

    public class ELCandidateWrapper {
        @AuraEnabled public String name;
        @AuraEnabled public String patientName;
        @AuraEnabled public Decimal patientAge;
        @AuraEnabled public Decimal patientBMI;
        @AuraEnabled public String patientBP;
        @AuraEnabled public String patientEcgStatus;
        @AuraEnabled public String patientHepaticFunction;
        @AuraEnabled public Decimal patientWeight;
        @AuraEnabled public String statusEnrolled;
        @AuraEnabled public String sugarStatus;
        @AuraEnabled public String pcpLLMResponse;
        @AuraEnabled public Decimal score;
        @AuraEnabled public Id idEnrolled;
        @AuraEnabled public Id idPreEnrolled;

        @AuraEnabled public String statusPreEnrolled;
        @AuraEnabled public String siteLLMResponse;
        @AuraEnabled public String statusSelected;
        @AuraEnabled public String croLLMResponse;

        @AuraEnabled public Id researchStudyId;
        @AuraEnabled public Id pcpId;
        @AuraEnabled public String cssClass;
    }
}