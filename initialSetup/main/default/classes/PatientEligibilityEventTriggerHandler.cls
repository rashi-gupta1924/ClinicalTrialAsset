public class PatientEligibilityEventTriggerHandler {
    public static void afterInsert(List<Patient_Eligibility_Event__e> patientEligibilityEvents) { 
        System.debug('Events received: ' + patientEligibilityEvents.size());
        // 1️⃣ Track all events
        Set<Id> siteAgentEnrolledSiteIds = new Set<Id>();
        Set<Id> pcpAgentEnrolledSiteIds = new Set<Id>();

        List<Patient_Eligibility_Event_Tracker__c> eventTrackerList = new List<Patient_Eligibility_Event_Tracker__c>();
        for (Patient_Eligibility_Event__e evt : patientEligibilityEvents) {
            eventTrackerList.add(new Patient_Eligibility_Event_Tracker__c(
                Enrolled_Site_ID__c = evt.Enrolled_Site_Id__c,
                Eligibility_Check_Stage__c = evt.Eligibility_Check_Stage__c
            ));
            if (evt.Enrolled_Site_Id__c != null && evt.Eligibility_Check_Stage__c == 'Site Agent') {
                siteAgentEnrolledSiteIds.add(evt.Enrolled_Site_Id__c);
            } else if(evt.Enrolled_Site_Id__c != null && evt.Eligibility_Check_Stage__c == 'PCP Agent') {
                pcpAgentEnrolledSiteIds.add(evt.Enrolled_Site_Id__c);
            }
        }

        if(!eventTrackerList.isEmpty()) {
            insert eventTrackerList;
        }

        if(!pcpAgentEnrolledSiteIds.isEmpty()) {
            for(Id eachSiteId : pcpAgentEnrolledSiteIds){
                Database.executeBatch(new PatientEligibilityPromptCallBatch(eachSiteId, false),1);
            }
        }
        
        if(!siteAgentEnrolledSiteIds.isEmpty()) {
            Map<Id, Id> enrolledSiteFacilityMap = new Map<Id, Id>();
            for(Enrolled_Site__c eachEnrolledSite : [SELECT Id, Healthcare_Facility__c FROM Enrolled_Site__c WHERE Id IN :siteAgentEnrolledSiteIds]) {
                enrolledSiteFacilityMap.put(eachEnrolledSite.Id, eachEnrolledSite.Healthcare_Facility__c);
            }
            
            Map<Id, List<Patient_Site__c>> healthSitePatientMap = new Map<Id, List<Patient_Site__c>>();
            for(Patient_Site__c eachPatientSite : [SELECT Id,Patient__c,Patient__r.PersonEmail,Healthcare_Facility__c,PCP__c FROM Patient_Site__c WHERE Healthcare_Facility__c = :enrolledSiteFacilityMap.values()
                                                    AND Healthcare_Facility__r.Count_of_Enrolled_Patients__c > 0]) {
                if(!healthSitePatientMap.containsKey(eachPatientSite.Healthcare_Facility__c)) {
                    healthSitePatientMap.put(eachPatientSite.Healthcare_Facility__c, new List<Patient_Site__c>());
                }
                healthSitePatientMap.get(eachPatientSite.Healthcare_Facility__c).add(eachPatientSite);
            }

            // 4️⃣ Get the Pre-Enrolled Record Type Id once
            Id preEnrolledRecordTypeId = SObjectType.Enrolled_Site_Research_Candidate__c
                .getRecordTypeInfosByDeveloperName()
                .get('Pre_Enrolled')
                .getRecordTypeId();
            List<Enrolled_Site_Research_Candidate__c> enrolledSiteCandidateList = new List<Enrolled_Site_Research_Candidate__c>();
            for(Id enrolledSiteKey : enrolledSiteFacilityMap.keySet()) {
                Id healthcareFacilityId = enrolledSiteFacilityMap.get(enrolledSiteKey);
                for(Patient_Site__c patientSite : healthSitePatientMap.get(healthcareFacilityId)) {
                    enrolledSiteCandidateList.add(new Enrolled_Site_Research_Candidate__c(
                        Patient__c = patientSite.Patient__c,
                        Patient_Email__c = patientSite.Patient__r.PersonEmail,
                        Enrolled_Site__c = enrolledSiteKey,
                        RecordTypeId = preEnrolledRecordTypeId,
                        Status__c = 'Initial Check',
                        PCP__c   = patientSite.PCP__c
                    ));
                }
            }

            // 6️⃣ Insert all candidates in one go
            if (!enrolledSiteCandidateList.isEmpty()) {
                insert enrolledSiteCandidateList;
                System.debug('Inserted Candidates: ' + enrolledSiteCandidateList.size());
            }
            
            for(Id eachSiteId : siteAgentEnrolledSiteIds){
                Database.executeBatch(new PatientEligibilityPromptCallBatch(eachSiteId, true),1);
            }
        }
    }
}