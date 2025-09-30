public class SiteEligiblityPromptCallBatch implements Database.Batchable<SObject>, Database.Stateful {

    private CRO_Research_Study__c croResearchStudyRecord;
    private Id croResearchId;
    private Research_Study__c researchStudy;

    // Constructor accepts the Id of the Research Study
    public SiteEligiblityPromptCallBatch(Id cRStudyId) {
        this.croResearchId = cRStudyId;
        this.croResearchStudyRecord = [SELECT ID, CRO_Account__c FROM CRO_Research_Study__c WHERE Id=:croResearchId];
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
		//this.croResearchStudyRecord.Status__C = In PRogress;
         return Database.getQueryLocator([SELECT Id, Name, Healthcare_Facility__c,CRO_Research_Study__c,CRO_Research_Study__r.Research_Study__c FROM Enrolled_Site__c WHERE CRO_Research_Study__c = :croResearchId AND Status__c='Invited for Survey']);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject sObj : scope) {
            Enrolled_Site__c enrolledSite = (Enrolled_Site__c)sObj;
            //call headless 
            SiteAgentHeadlessController.checkSiteEligibility(enrolledSite,new Research_Study__c(Id = enrolledSite.CRO_Research_Study__r.Research_Study__c),croResearchStudyRecord);
        }
    }

    public void finish(Database.BatchableContext bc) {
       
        //this.croResearchStudyRecord.Status__C = Compeleted;
        System.debug('Site Eligilibility Batch finished');
    }
}