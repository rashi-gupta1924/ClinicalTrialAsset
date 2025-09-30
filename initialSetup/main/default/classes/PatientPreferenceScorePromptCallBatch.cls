/**
* @File Name : PatientPreferenceScorePromptCallBatch.cls
* @Description : Used to batch the call of headless Agent using the handler class 
* @Author : Rashi Gupta;
* @Last Modified By : Rashi Gupta;
* @Last Modified On : August 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 6, 2025 | Rashi Gupta  | Initial Version
**/

public class PatientPreferenceScorePromptCallBatch implements Database.Batchable<SObject>,Database.Stateful {
	
    private Id enrolledSiteId;
    
    // Constructor accepts the Id of the Research Study
    public PatientPreferenceScorePromptCallBatch(Id enrolledSiteId) {
        this.enrolledSiteId = enrolledSiteId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query All Enrolled Research Site Candidate records to be processed
        return Database.getQueryLocator([SELECT Id,Patient__c,Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c,Status__c FROM Enrolled_Site_Research_Candidate__c 
                                        WHERE Enrolled_Site__c = :this.enrolledSiteId AND 
                                        RecordType.DeveloperName = 'Enrolled' AND Status__c = 'Shortlisted']);
    }
 
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (SObject sObj : scope) {
            Enrolled_Site_Research_Candidate__c esrc = (Enrolled_Site_Research_Candidate__c) sObj;
            PatientAgentHeadlessController.patientPreferenceScorePromptInvoke(esrc);            
        }
    }

    public void finish(Database.BatchableContext bc) {
        CandidateScoringHandler.assignCandidateStatus(this.enrolledSiteId);
         List<Task> siteAgentTaskList = new List<Task>();
        for(Task tsk : [SELECT Id, Status FROM Task WHERE WhatId = :this.enrolledSiteId AND RecordType.DeveloperName='CRO_Agent_Task' AND Status='Open']){
            tsk.Status = 'Completed';
            siteAgentTaskList.add(tsk);
        }
        if(siteAgentTaskList.size()>0){
            update siteAgentTaskList;
        }
    }
}