public class PatientAgentHeadlessController {
    
    public static void invokePDFPrompt(ContentDocument doc){
        //invoke prompt
    }
    public static void checkPatientSiteEligibility(Enrolled_Site_Research_Candidate__c enrolledSiteResearchCandidate, Account patient){
        
        Research_Study__c researchStudy = new Research_Study__c(Id = enrolledSiteResearchCandidate.Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c);      
        ConnectApi.WrappedValue inputResearchStudy = new ConnectApi.WrappedValue();
        inputResearchStudy.value = new Map<String, String> {'Id' => researchStudy.Id};
            
        ConnectApi.WrappedValue inputPatient = new ConnectApi.WrappedValue();
        inputPatient.value = new Map<String, String> {'Id' => patient.Id};
            
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{};
        inputParams.put('Input:Patient_Account',inputPatient);
        inputParams.put('Input:Research_Study',inputResearchStudy);
        
        String result = PromptUtility.invokePrompt('Patient_Eligibility', inputParams);
        result = result.replace('\u00A0', ' '); 
        
        //write log run logic here 
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        // Cast values if you need them as String
        String response = (String) resultMap.get('Response');
        String status = (String) resultMap.get('Status');
        
        Enrolled_Site_Research_Candidate__c enrolledSiteCandidate = new Enrolled_Site_Research_Candidate__c(Id=enrolledSiteResearchCandidate.Id,Status__c = status,Site_Agent_Prompt_Response__c = response);
        update enrolledSiteCandidate;
        Patient_Eligibility_Run_Log__c log = new Patient_Eligibility_Run_Log__c(Prompt_Response__c = response,Agent__c = 'Site Agent', Enrolled_Site_Research_Candidate__c = enrolledSiteCandidate.Id);
        insert log;
        System.debug(log);
        System.debug(enrolledSiteCandidate);
        
    } 
    
    public static void checkPatientPCPEligibility(Enrolled_Site_Research_Candidate__c enrolledSiteCandidate,Account patient){
        System.debug('Rashi');
        Research_Study__c researchStudy = new Research_Study__c(Id = enrolledSiteCandidate.Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c);
        ConnectApi.WrappedValue inputPatient = new ConnectApi.WrappedValue();
        inputPatient.value = new Map<String, String> {'Id' => patient.Id};
            
        ConnectApi.WrappedValue inputResearchStudy = new ConnectApi.WrappedValue();
        inputResearchStudy.value = new Map<String, String> {'Id' => researchStudy.Id};
            
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{};
        inputParams.put('Input:Patient',inputPatient);
        inputParams.put('Input:Research_Study',inputResearchStudy);
        System.debug('Rashi');
        String result = PromptUtility.invokePrompt('Patient_Shortlisting', inputParams);
        result = result.replace('\u00A0', ' ');
        System.debug('Rashi');
        //write log run logic here 
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        // Cast values if you need them as String
        String response = (String) resultMap.get('Response');
        String status = (String) resultMap.get('Status');
        
        enrolledSiteCandidate = new Enrolled_Site_Research_Candidate__c(Id = enrolledSiteCandidate.Id,Status__c = status,PCP_Agent_Prompt_Response__c = response);
        update enrolledSiteCandidate;
        Patient_Eligibility_Run_Log__c log = new Patient_Eligibility_Run_Log__c(Prompt_Response__c = response,Agent__c = 'PCP Agent', Enrolled_Site_Research_Candidate__c = enrolledSiteCandidate.Id);
        insert log;      
    }
    
    public static void patientPreferenceScorePromptInvoke(Enrolled_Site_Research_Candidate__c enrolledSiteCandidate){
        
        //Research_Study__c researchStudy = new Research_Study__c(Id = enrolledSiteCandidate.Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c);
        ConnectApi.WrappedValue inputPatient = new ConnectApi.WrappedValue();
        inputPatient.value = new Map<String, String> {'Id' => enrolledSiteCandidate.Patient__c};
            
        ConnectApi.WrappedValue inputResearchStudy = new ConnectApi.WrappedValue();
        //inputResearchStudy.value = new Map<String, String> {'Id' => researchStudy.Id};
        inputResearchStudy.value = new Map<String, String> {'Id' => enrolledSiteCandidate.Enrolled_Site__r.CRO_Research_Study__r.Research_Study__c};
            
        ConnectApi.WrappedValue inputEnrolledCandidate = new ConnectApi.WrappedValue();
        inputEnrolledCandidate.value = new Map<String, String> {'Id' => enrolledSiteCandidate.Id};
            
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>{};
        inputParams.put('Input:Patient_Account',inputPatient);
        inputParams.put('Input:ResearchStudy',inputResearchStudy);
        inputParams.put('Input:EnrolledCandidate',inputEnrolledCandidate);
        
        String result = PromptUtility.invokePrompt('Patient_Preference_Score', inputParams);
        System.debug('**Result***'+result);
        result = result.replace('\u00A0', ' ');
        
        //write log run logic here 
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
        // Cast values if you need them as String
        String response = (String) resultMap.get('Response');
        Integer score = (Integer) resultMap.get('Score');
        System.debug(score);
        enrolledSiteCandidate = new Enrolled_Site_Research_Candidate__c(Id = enrolledSiteCandidate.Id,Eligibility_Score__c=score,CRO_Agent_Prompt_Response__c=response);
        update enrolledSiteCandidate;	
    }
}