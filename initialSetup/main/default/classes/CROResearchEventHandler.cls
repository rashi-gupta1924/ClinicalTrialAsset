/**
* @File Name : CROResearchEventHandler.cls
* @Description : Handler Class for CROResearchEventTrigger
* @Author : Pradeep Sharma
* @Last Modified By : Aakash Malik
* @Last Modified On : August 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 1, 2025 | Pradeep Sharma  | Initial Version
* 2.0 | August 18, 2025 | Aakash Malik        | Bulkified version
**/
public class CROResearchEventHandler {
   
    public static void afterInsert(List<CRO_Research_Event__e> croResearchEvents) {
        if (croResearchEvents.isEmpty()) return;

        Set<Id> researchStudyIds = new Set<Id>();
        for (CRO_Research_Event__e evt : croResearchEvents) {
            if (evt.CRO_Research_Study_ID__c != null) {
                researchStudyIds.add(evt.CRO_Research_Study_ID__c);
            }
        }

        if (researchStudyIds.isEmpty()) return;

        Map<Id, CRO_Research_Study__c> researchStudyMap = new Map<Id, CRO_Research_Study__c>([SELECT Id, Name, CRO_Account__c, Research_Study__c FROM CRO_Research_Study__c WHERE Id IN :researchStudyIds]);

        List<HealthcareFacility> facilities = [SELECT Id, Count_of_Enrolled_Patients__c FROM HealthcareFacility WHERE Count_of_Enrolled_Patients__c > 0 ];
        System.debug('Facilities count: ' + facilities.size());

        List<Enrolled_Site__c> enrolledSites = new List<Enrolled_Site__c>();

        for (Id researchStudyId : researchStudyMap.keySet()) {
            for (HealthcareFacility facility : facilities) {
                enrolledSites.add(new Enrolled_Site__c(
                    Healthcare_Facility__c = facility.Id,
                    CRO_Research_Study__c = researchStudyId,
                    Status__c = 'Invited for Survey'
                ));
            }
        }

        System.debug('Enrolled Sites to insert: ' + enrolledSites.size());

        if (!enrolledSites.isEmpty()) {
            insert enrolledSites;
        }

        for (Id researchStudyId : researchStudyIds) {
            Database.executeBatch(new SiteEligiblityPromptCallBatch(researchStudyId), 1);
        }
    }  
}