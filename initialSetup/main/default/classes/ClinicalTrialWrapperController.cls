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

public with sharing class ClinicalTrialWrapperController {
 
    @AuraEnabled
    public static List<ClinicalTrialWrapperService.RSWrapper> getResearchStudyDetails(Id researchStudyId,List<Id> selectedCROs) {
 
        List<ClinicalTrialWrapperService.RSWrapper> rsWrapperList = new List<ClinicalTrialWrapperService.RSWrapper>();
 
        Research_Study__c rs = [SELECT Id, Name, Status__c FROM Research_Study__c WHERE Id = :researchStudyId LIMIT 1];
 
        ClinicalTrialWrapperService.RSWrapper rsWrapper = new ClinicalTrialWrapperService.RSWrapper();
        rsWrapper.id = rs.Id;
        rsWrapper.name = rs.Name;
        rsWrapper.status = rs.Status__c;
        rsWrapper.cssClass = 'RSWrapper_' + (rs.Status__c != null ? rs.Status__c.replaceAll('\\s','') : 'Unknown');
        rsWrapper.resStudy = rs;
        rsWrapper.croWrapperList = new List<ClinicalTrialWrapperService.CROWrapper>();
 
        // Fetch CRO Research Studies with Enrolled Sites
        List<CRO_Research_Study__c> croList = [
            SELECT Id, Status__c, CRO_Account__c, CRO_Account__r.Name,
                   (SELECT Id, Name,Status__c, Healthcare_Facility__c, Healthcare_Facility__r.Name 
                    FROM Enrolled_Site__r
                    WHERE CRO_Research_Study__c != null ORDER BY Status__c ) 
            FROM CRO_Research_Study__c
            WHERE Research_Study__c = :rs.Id AND CRO_Account__c IN :selectedCROs];
        //AND Status__c = 'Identified'
 
        // Preload all candidates with patient info
        List<Enrolled_Site_Research_Candidate__c> allCandidates = [
                                    SELECT Id, Name,Eligibility_Score__c, Has_Eligibility_Score__c,Patient__r.Sugar_Status__c,
                                     Status__c, Site_Agent_Prompt_Response__c,PCP_Agent_Prompt_Response__c, 
                                     CRO_Agent_Prompt_Response__c, PCP__c,Patient__c, Patient__r.Masked_Name__c ,Patient__r.Age__c,Patient__r.Weight__c,Patient__r.BMI__c,Patient__r.Blood_Pressure__c,Patient__r.ECG_Status__c ,Patient__r.Hepatic_Function__c
                                     FROM Enrolled_Site_Research_Candidate__c 
                                     WHERE Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c = :rs.Id 
                                     AND RecordType.DeveloperName IN('Pre_Enrolled','Enrolled')  AND Status__c In ('Invite Sent for Enrollment' ,'On Hold', 'Rejected After Shortlisted','Shortlisted','Initial Check','Initial Check Cleared','Initial Check Failed','Enrollment Accepted','Enrollment Rejected','Trial Complete','Trial In-Progress','Rejected','Enrolled') ORDER BY RecordType.DeveloperName ASC, Has_Eligibility_Score__c DESC, Eligibility_Score__c DESC]; //Site_Agent_LLM_Response__c,PCP_Agent_LLM_Response__c

                             
 
 
        // Map PCP Id -> List of candidates
        Map<Id, List<Enrolled_Site_Research_Candidate__c>> pcpToCandidateMap = new Map<Id, List<Enrolled_Site_Research_Candidate__c>>();
        for(Enrolled_Site_Research_Candidate__c cand : allCandidates){
            System.debug('age>> ' + cand.Patient__r.Weight__c);
            if(cand.PCP__c != null){
                
                if(!pcpToCandidateMap.containsKey(cand.PCP__c)){
                    pcpToCandidateMap.put(cand.PCP__c, new List<Enrolled_Site_Research_Candidate__c>());
                }
                pcpToCandidateMap.get(cand.PCP__c).add(cand);
            }
        }
 
        for(CRO_Research_Study__c cro : croList) {
            ClinicalTrialWrapperService.CROWrapper croWrapper = new ClinicalTrialWrapperService.CROWrapper();
            croWrapper.croId = cro.CRO_Account__c;
            croWrapper.croName = cro.CRO_Account__r.Name;
            croWrapper.status = cro.Status__c;
            croWrapper.researchStudyId = rs.Id;
            croWrapper.cssClass = 'CROWrapper_' + (cro.Status__c != null ? cro.Status__c.replaceAll('\\s','') : 'Unknown');
            croWrapper.hfWrapperList = new List<ClinicalTrialWrapperService.HFWrapper>();
            croWrapper.hasChildren = cro.Enrolled_Site__r.size() > 0;
            croWrapper.isExpanded = false;
 
            Map<Id, List<Enrolled_Site__c>> hfToSitesMap = new Map<Id, List<Enrolled_Site__c>>();
            for(Enrolled_Site__c site : cro.Enrolled_Site__r) {
                if(site.Healthcare_Facility__c != null) {
                    if(!hfToSitesMap.containsKey(site.Healthcare_Facility__c)) {
                        hfToSitesMap.put(site.Healthcare_Facility__c, new List<Enrolled_Site__c>());
                    }
                    hfToSitesMap.get(site.Healthcare_Facility__c).add(site);
                }
            }
 
            for(Id hfId : hfToSitesMap.keySet()) {
                ClinicalTrialWrapperService.HFWrapper hfWrapper = new ClinicalTrialWrapperService.HFWrapper();
                hfWrapper.hfId = hfId;
                Enrolled_Site__c firstSite = hfToSitesMap.get(hfId)[0];
                hfWrapper.hfName = firstSite.Healthcare_Facility__r != null ? firstSite.Healthcare_Facility__r.Name : 'Unknown HF';
                hfWrapper.isIdentified = (firstSite.Status__c == 'Identified');
                hfWrapper.status = firstSite.Status__c;
                hfWrapper.cssClass = hfWrapper.status == 'Identified' ? 'hf-green' : 'hf-grey';
                hfWrapper.pcpWrapperList = new List<ClinicalTrialWrapperService.PCPWrapper>();
                hfWrapper.hasChildren = true;
                hfWrapper.isExpanded = false;
 
                List<Account> pcpList = [
                    SELECT Id, Name, Salutation,Medical_Specialty__c, Trial_Site__c
                    FROM Account
                    WHERE Trial_Site__c = :hfId
                ];
 
                for(Account pcp : pcpList) {
                    ClinicalTrialWrapperService.PCPWrapper pcpWrapper = new ClinicalTrialWrapperService.PCPWrapper();
                    pcpWrapper.id = pcp.Id;
                    pcpWrapper.name = 'Dr. ' + pcp.Name;
                    pcpWrapper.status = '';
                    pcpWrapper.researchStudyId = rs.Id;
                    pcpWrapper.healthcareFacilityId = hfId;
                    pcpWrapper.elCandidateWrapperList = new List<ClinicalTrialWrapperService.ELCandidateWrapper>();
                    pcpWrapper.hasChildren = pcpToCandidateMap.containsKey(pcp.Id) && pcpToCandidateMap.get(pcp.Id).size() > 0;
                    pcpWrapper.isExpanded = false;
                    pcpWrapper.cssClass = 'PCPWrapper_' + (pcpWrapper.status != null ? pcpWrapper.status.replaceAll('\\s','') : 'Unknown');
 
                    if(pcpToCandidateMap.containsKey(pcp.Id)){
                        Set<Id> patientIds = new Set<Id>();
                        for(Enrolled_Site_Research_Candidate__c cand : pcpToCandidateMap.get(pcp.Id)){
                            if(!patientIds.contains(cand.Patient__c)){
                                patientIds.add(cand.Patient__c);
                                
                                ClinicalTrialWrapperService.ELCandidateWrapper elWrapper = new ClinicalTrialWrapperService.ELCandidateWrapper();
                                elWrapper.idEnrolled = cand.Id;
                                elWrapper.name = cand.Name;
                                elWrapper.patientName = cand.Patient__r != null ? cand.Patient__r.Masked_Name__c : 'Unknown Patient';  
                                elWrapper.statusEnrolled = cand.Status__c;
                                elWrapper.patientAge = cand.Patient__r != null ? cand.Patient__r.Age__c : null ;
                                elWrapper.patientBMI = cand.Patient__r != null ? cand.Patient__r.BMI__c : null ;
                                elWrapper.patientBP = cand.Patient__r != null ? cand.Patient__r.Blood_Pressure__c : null ;
                                elWrapper.patientEcgStatus = cand.Patient__r != null ? cand.Patient__r.ECG_Status__c : null ;
                                elWrapper.patientHepaticFunction = cand.Patient__r != null ? cand.Patient__r.Hepatic_Function__c : null ;
                                elWrapper.patientWeight = cand.Patient__r != null ? cand.Patient__r.Weight__c : null ;
                                elWrapper.score = cand.Eligibility_Score__c;
                                elWrapper.siteLLMResponse = cand.Site_Agent_Prompt_Response__c;
                                elWrapper.pcpLLMResponse = cand.PCP_Agent_Prompt_Response__c;
                                elWrapper.croLLMResponse = cand.CRO_Agent_Prompt_Response__c;
                                elWrapper.researchStudyId = rs.Id;
                                elWrapper.pcpId = pcp.Id;
                                elWrapper.sugarStatus = cand.patient__r.Sugar_Status__c;
                                // elWrapper.cssClass = 'ELCandidateWrapper_' + (elWrapper.statusEnrolled != null ? elWrapper.statusEnrolled.replaceAll('\\s','') : 'Unknown');
                                String baseClass = 'flow-box txt-16';
                                switch on cand.Status__c {
                                    when 'Invite Sent for Enrollment' {
                                        elWrapper.cssClass = baseClass + ' pt-green';
                                    }
                                    when 'On Hold' {
                                        elWrapper.cssClass = baseClass + ' pt-orange';
                                    }
                                    when 'Rejected' {
                                        elWrapper.cssClass = baseClass + ' pt-red';
                                    }
                                    when 'Rejected After Shortlisted' {
                                        elWrapper.cssClass = baseClass + ' pt-mauve';
                                    }
                                    when 'Shortlisted' {
                                        elWrapper.cssClass = baseClass + ' pt-teal';
                                    }
                                    when 'Initial Check' {
                                        elWrapper.cssClass = baseClass + ' pt-blue';
                                    }
                                    when 'Initial Check Cleared' {
                                        elWrapper.cssClass = baseClass + ' pt-lime';
                                    }
                                    when 'Initial Check Failed' {
                                        elWrapper.cssClass = baseClass + ' pt-coral';
                                    }
                                    when 'Enrollment Accepted' {
                                        elWrapper.cssClass = baseClass + ' pt-accepted';
                                    }
                                    when 'Enrollment Rejected' {
                                        elWrapper.cssClass = baseClass + ' pt-amber';
                                    }
                                    when else {
                                        elWrapper.cssClass = baseClass; // fallback
                                    }
                                }
                                pcpWrapper.elCandidateWrapperList.add(elWrapper);
                            }
                        }
                        pcpWrapper.elCandidateWrapperList.sort(new ELCandidateStatusComparator());
                    }
 
                    hfWrapper.pcpWrapperList.add(pcpWrapper);
                }
 
                croWrapper.hfWrapperList.add(hfWrapper);
            }
 
            rsWrapper.croWrapperList.add(croWrapper);
        }
 
        rsWrapperList.add(rsWrapper);
        return rsWrapperList;
    }
    
    public class ELCandidateStatusComparator implements System.Comparator<ClinicalTrialWrapperService.ELCandidateWrapper> {
        Map<String, Integer> orderMap = new Map<String, Integer>{
            'Enrollment Accepted' => 1,
                'Enrollment Rejected' => 2,
                'Invite Sent for Enrollment' => 3,
                'On Hold' => 4,
                'Rejected After Shortlisted' => 5,
                'Shortlisted' => 6,
                'Rejected' => 7,
                'Initial Check Cleared' => 8,
                'Initial Check Failed' => 9,
                'Initial Check' => 10
                };
                    
                    public Integer compare(ClinicalTrialWrapperService.ELCandidateWrapper elA,
                                           ClinicalTrialWrapperService.ELCandidateWrapper elB) {
                                               Integer orderA = orderMap.containsKey(elA.statusEnrolled) ? orderMap.get(elA.statusEnrolled) : 999;
                                               Integer orderB = orderMap.containsKey(elB.statusEnrolled) ? orderMap.get(elB.statusEnrolled) : 999;
                                               
                                               if (orderA == orderB) {
                                                   // tie-breaker → higher score first
                                                   if (elA.score == elB.score) return 0;
                                                   return elA.score > elB.score ? -1 : 1;
                                               }
                                               return orderA < orderB ? -1 : 1;
                                           }
    }

}