public with sharing class PreferenceScoreEventTriggerHandler {   
    public static void afterInsert(List<Preference_Score_Event__e> prefScoreEvent){
        for(Preference_Score_Event__e evt: prefScoreEvent){
            Database.executeBatch(new PatientPreferenceScorePromptCallBatch(evt.Enrolled_Site_Id__c), 1);
        }      
    }           
}