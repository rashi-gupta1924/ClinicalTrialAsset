public class SiteAgentHeadlessController {
    
    public static String checkSiteEligibility(Enrolled_Site__c site, Research_Study__c researchStudy, CRO_Research_Study__c croRS){
        System.debug('User--->'+UserInfo.getUserId());
        HealthcareFacility facility =  new HealthcareFacility(Id = site.Healthcare_Facility__c);
        
        ConnectApi.WrappedValue inputResearchStudy = new ConnectApi.WrappedValue();
        inputResearchStudy.value = new Map<String, String> {'Id' => researchStudy.ID};
            
        ConnectApi.WrappedValue inputFacility = new ConnectApi.WrappedValue();
        inputFacility.value = new Map<String, String> {'Id' => facility.Id};  
            
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{};
        inputParams.put('Input:Research_Study',inputResearchStudy);
        inputParams.put('Input:Health_Care_Facility',inputFacility);
        
        system.debug('inputParams: '+inputParams);
        String result = PromptUtility.invokePrompt('Site_Eligiblility', inputParams);
        result = result.replace('\u00A0', ' ');
        System.debug('**Result***'+result);
        //write log run logic here 
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        // Cast values if you need them as String
        String response = (String) resultMap.get('Response');
        String status = (String) resultMap.get('Status');
        Enrolled_Site__c enrolledSite = new Enrolled_Site__c(Id=site.Id,CRO_Agent_LLM_Response__c = response,Status__c = status);
        update enrolledSite;
        //task - enrolledsite.status == Identified then task status completed
        //task trigger - task.status == completed ---> flow trigger --> site agent --> publish event 
        DrugSiteEligibilityRunLog__c log = new DrugSiteEligibilityRunLog__c(CRO_Agent_LLM_Repsonse__c = response, Enrolled_Site__c = enrolledSite.Id);
        insert log;
        
        Id siteAgentTaskRecordTypeId = SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Site_Agent_Task').getRecordTypeId();
        if(enrolledSite.Status__c == 'Identified' ) {
            Task task = new Task(
                recordTypeId = siteAgentTaskRecordTypeId,
                Subject = 'Identify Potential Patients',
                WhatId = enrolledSite.Id,
                Status = 'Open',
                Description = 'Identify potential patients for mentioned research study.',
                Research_Study__c = researchStudy.Id,
                Healthcare_Facility__c = facility.Id,
                CRO_Account__c = croRS.CRO_Account__c,
                CRO_Research_Study__c = croRS.Id,
                Enrolled_Site__c = enrolledSite.Id
            );
            
            insert task;
            System.debug(task.id);
        }
        
        return result;
    } 
}