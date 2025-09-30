public without sharing class Agent_Site_PatientEligibilityPublisher {

    public class PatientEligibilityRequest {
        @InvocableVariable(required=true)
        public String enrolledSiteName;
    }

    public class PatientEligibilityResponse {
        @InvocableVariable public String responseJson;
    }

    @InvocableMethod(label='Publish Patient Eligibility Event' description='Publishes Platform Event for given Enrolled Site')
    public static List<PatientEligibilityResponse> publishPatientEligibilityEvent(List<PatientEligibilityRequest> requests) {
        List<PatientEligibilityResponse> responses = new List<PatientEligibilityResponse>();

        for (PatientEligibilityRequest req : requests) {
            Map<String, Object> result = new Map<String, Object>();
            PatientEligibilityResponse resp = new PatientEligibilityResponse();

            try {
                Enrolled_Site__c enrolledSite = [SELECT Id FROM Enrolled_Site__c WHERE Name = :req.enrolledSiteName LIMIT 1];
                Patient_Eligibility_Event__e evt = new Patient_Eligibility_Event__e(Enrolled_Site_Id__c = enrolledSite.Id, Eligibility_Check_Stage__c = 'Site Agent');
                List<Database.SaveResult> results = EventBus.publish(new List<Patient_Eligibility_Event__e>{ evt });
                System.debug(results);
                if (!results.isEmpty() && results[0].isSuccess()) {
                    result.put('message', 'Initial eligibility screening for '+ req.enrolledSiteName +' has started. Results will be available soon.');
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