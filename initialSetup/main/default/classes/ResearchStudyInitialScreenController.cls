public with sharing class ResearchStudyInitialScreenController {

    @AuraEnabled
    public static List<Research_Study__c> getResearchStudies() {
        return [SELECT Id, Name FROM Research_Study__c ORDER BY Name];
    }

    @AuraEnabled
    public static List<Account> getCROsByStudy(Id studyId) {
        List<CRO_Research_Study__c> junctions = [SELECT CRO_Account__r.Id, CRO_Account__r.Name FROM CRO_Research_Study__c WHERE Research_Study__c = :studyId];
        //Status__c = 'In Progress' AND

        Map<Id, Account> croMap = new Map<Id, Account>();
        for (CRO_Research_Study__c j : junctions) {
            if (j.CRO_Account__r != null) {
                croMap.put(j.CRO_Account__r.Id, j.CRO_Account__r);
            }
        }
        return croMap.values();
    }
}