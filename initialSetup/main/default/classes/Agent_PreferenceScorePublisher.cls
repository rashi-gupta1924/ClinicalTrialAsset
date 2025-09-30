public with sharing class Agent_PreferenceScorePublisher {

    public class PatientPreferenceRequest {
        @InvocableVariable(required=true)
        public String enrolledSiteName;
    }

    public class PatientPreferenceResponse {
        @InvocableVariable public String responseJson;
    }

    @InvocableMethod(label='Publish Patient Score Eligibility Event' description='Publishes Platform Event for given Research Study')
    public static List<PatientPreferenceResponse> publishPatientPreferenceScoreEvent(List<PatientPreferenceRequest> requests) {
        List<PatientPreferenceResponse> responses = new List<PatientPreferenceResponse>();

        for (PatientPreferenceRequest req : requests) {
            Map<String, Object> result = new Map<String, Object>();
            PatientPreferenceResponse resp = new PatientPreferenceResponse();

            try {
                Enrolled_Site__c enrolledSite = [SELECT Id FROM Enrolled_Site__c WHERE Name = :req.enrolledSiteName LIMIT 1];
                Preference_Score_Event__e evt = new Preference_Score_Event__e(Enrolled_Site_Id__c = enrolledSite.Id);
                List<Database.SaveResult> results = EventBus.publish(new List<Preference_Score_Event__e>{ evt });
                if (!results.isEmpty() && results[0].isSuccess()) {
                    result.put('message', 'Eligibility scoring for patients of '+ req.enrolledSiteName + ' has started. Results will reflect shortly.');
                    result.put('enrolledSiteId', enrolledSite.Id);
                    result.put('enrolledSiteName', req.enrolledSiteName);
                } else {
                    result.put('message', 'Failed to publish event');
                    if (!results.isEmpty()) {
                        result.put('error', results[0].getErrors()[0].getMessage());
                    }
                }

            } catch (Exception e) {
                result.put('message', 'Error processing request for: ' + req.enrolledSiteName);
                result.put('error', e.getMessage());
            }

            resp.responseJson = JSON.serialize(result);
            responses.add(resp);
        }

        return responses;
    }
}