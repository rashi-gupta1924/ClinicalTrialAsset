public class PatientEligibilityPromptCallBatch implements Database.Batchable<SObject>,Database.Stateful {
    
    private Id enrolledSiteId;
    private Enrolled_Site__c enrolledSiteRecord;
    private Boolean isPreliminaryCheck = false;
    
    public PatientEligibilityPromptCallBatch(Id enrolledSiteId, Boolean isPreliminaryCheck) {
        this.isPreliminaryCheck = isPreliminaryCheck;
        this.enrolledSiteId = enrolledSiteId;
        this.enrolledSiteRecord = [SELECT Id,Healthcare_Facility__c,Status__c,CRO_Research_Study__r.Research_Study__c,CRO_Research_Study__r.CRO_Account__c,
                                    CRO_Research_Study__c FROM Enrolled_Site__c WHERE Id=:enrolledSiteId];
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(this.isPreliminaryCheck){
            return Database.getQueryLocator([
                SELECT Id, Patient__c, Enrolled_Site__c, 
                Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c,
                Enrolled_Site__r.Healthcare_Facility__c,
                Enrolled_Site__r.CRO_Research_Study__r.CRO_Account__c,
                Enrolled_Site__r.CRO_Research_Study__c, Enrolled_Site__r.Status__c
                FROM Enrolled_Site_Research_Candidate__c
                WHERE Enrolled_Site__c = :enrolledSiteId AND Status__c = 'Initial Check'
                AND RecordType.DeveloperName = 'Pre_Enrolled']);
        }else{
            return Database.getQueryLocator([
                SELECT Id, Patient__c, Enrolled_Site__c,
                Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c,
                Enrolled_Site__r.Healthcare_Facility__c,
                Enrolled_Site__r.CRO_Research_Study__r.CRO_Account__c,
                Enrolled_Site__r.CRO_Research_Study__c, Enrolled_Site__r.Status__c
                FROM Enrolled_Site_Research_Candidate__c 
                WHERE Enrolled_Site__c = :enrolledSiteId AND Status__c = 'Initial Check Cleared'
                AND RecordType.DeveloperName = 'Pre_Enrolled']);
        }
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Enrolled_Site_Research_Candidate__c> enrolledCandidateProcessed = new List<Enrolled_Site_Research_Candidate__c>();
        for (SObject recObj : scope) {
            if(this.isPreliminaryCheck){
                Enrolled_Site_Research_Candidate__c enrolledSiteCandidate = (Enrolled_Site_Research_Candidate__c) recObj;
                PatientAgentHeadlessController.checkPatientSiteEligibility(enrolledSiteCandidate,new Account(Id= enrolledSiteCandidate.Patient__c));
            }else{
                Enrolled_Site_Research_Candidate__c enrolledSiteCandidate = (Enrolled_Site_Research_Candidate__c) recObj;
                PatientAgentHeadlessController.checkPatientPCPEligibility(enrolledSiteCandidate,new Account(Id=enrolledSiteCandidate.Patient__c));
            }
        }
    } 

    public void finish(Database.BatchableContext bc) {
        if(this.isPreliminaryCheck){
            Id pcpAgentTaskRecordTypeId = SObjectType.Task.getRecordTypeInfosByDeveloperName().get('PCP_Agent_Task').getRecordTypeId();
            Task task = new Task(
                recordTypeId            = pcpAgentTaskRecordTypeId,
                Subject                 = 'Identify Shortlisted Patients',
                WhatId                  = this.enrolledSiteRecord.Id,
                Status                  = 'Open',
                Description             = 'Shortlist patients for mentioned research study.',
                Research_Study__c       = this.enrolledSiteRecord.CRO_Research_Study__r.Research_Study__c,
                Enrolled_Site__c        = this.enrolledSiteRecord.Id,
                Healthcare_Facility__c  = this.enrolledSiteRecord.Healthcare_Facility__c,
                CRO_Account__c          = this.enrolledSiteRecord.CRO_Research_Study__r.CRO_Account__c,
                CRO_Research_Study__c   = this.enrolledSiteRecord.CRO_Research_Study__c
            );
            insert task;
            
            //close the site agent task
            List<Task> siteAgentTaskList = new List<Task>();
            for(Task tsk : [SELECT Id, Status FROM Task WHERE WhatId = :enrolledSiteId AND RecordType.DeveloperName='Site_Agent_Task' AND Status='Open']){
                tsk.Status = 'Completed';
                siteAgentTaskList.add(tsk);
            }
            if(siteAgentTaskList.size()>0){
                update siteAgentTaskList;
            }
        } else {
            //create a task - CRO_Agent_Task
            Id croAgentTaskRecordTypeId = SObjectType.Task.getRecordTypeInfosByDeveloperName().get('CRO_Agent_Task').getRecordTypeId();
            Task task = new Task(
                recordTypeId            = croAgentTaskRecordTypeId,
                Subject                 = 'Identify Enrolled Patients',
                WhatId                  = this.enrolledSiteRecord.Id,
                Status                  = 'Open',
                Description             = 'Calculate eligiblity score for shortlisted patients.',
                Research_Study__c       = this.enrolledSiteRecord.CRO_Research_Study__r.Research_Study__c,
                Healthcare_Facility__c  = this.enrolledSiteRecord.Healthcare_Facility__c,
                Enrolled_Site__c        = this.enrolledSiteRecord.Id,
                CRO_Account__c          = this.enrolledSiteRecord.CRO_Research_Study__r.CRO_Account__c,
                CRO_Research_Study__c   = this.enrolledSiteRecord.CRO_Research_Study__c
            );
            insert task;

            List<Task> siteAgentTaskList = new List<Task>();
            for(Task tsk : [SELECT Id, Status FROM Task WHERE WhatId = :enrolledSiteId AND RecordType.DeveloperName='PCP_Agent_Task' AND Status='Open']){
                tsk.Status = 'Completed';
                siteAgentTaskList.add(tsk);
            }
            if(siteAgentTaskList.size()>0){
                update siteAgentTaskList;
            }
        }
    }
}