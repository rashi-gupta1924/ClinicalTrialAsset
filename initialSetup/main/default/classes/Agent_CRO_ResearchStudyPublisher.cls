public without sharing class Agent_CRO_ResearchStudyPublisher {

    public class CRORequest {
        @InvocableVariable(required=true)
        public String researchStudyName;

        @InvocableVariable(required=true)
        public String croName;
    }

    public class CROResponse {
        @InvocableVariable public String responseJson;
    }

    @InvocableMethod(label='Publish CRO Research Events' description='Publishes Platform Event for given CRO and Research Study')
    public static List<CROResponse> publishResearchEvent(List<CRORequest> requests) {
        List<CROResponse> responses = new List<CROResponse>();

        for (CRORequest req : requests) {
            Map<String, Object> result = new Map<String, Object>();
            CROResponse resp = new CROResponse();

            try {
                Research_Study__c study = [SELECT Id, Name FROM Research_Study__c WHERE Name = :req.researchStudyName LIMIT 1];

                Account croAcc = [SELECT Id, Name FROM Account WHERE Name = :req.croName LIMIT 1];

                CRO_Research_Study__c croStudy;
                List<CRO_Research_Study__c> existing = [SELECT Id FROM CRO_Research_Study__c WHERE Research_Study__c = :study.Id AND CRO_Account__c = :croAcc.Id LIMIT 1];

                if (!existing.isEmpty()) {
                    croStudy = existing[0];
                } else {
                    croStudy = new CRO_Research_Study__c(Research_Study__c = study.Id, CRO_Account__c = croAcc.Id);
                    insert croStudy;
                }

                CRO_Research_Event__e evt = new CRO_Research_Event__e(CRO_Research_Study_ID__c = croStudy.Id);

                List<Database.SaveResult> results = EventBus.publish(new List<CRO_Research_Event__e>{ evt });

                if (!results.isEmpty() && results[0].isSuccess()) {
                    result.put('message', 'The eligibility check for ' + req.researchStudyName + ' with CRO ' + req.croName + ' has started. Eligible sites will be available soon.');
                    result.put('researchStudyId', study.Id);
                    result.put('researchStudyName', req.researchStudyName);
                } else {
                    result.put('message', 'Failed to publish event');
                    if (!results.isEmpty()) {
                        result.put('error', results[0].getErrors()[0].getMessage());
                    }
                }

            } catch (Exception e) {
                result.put('message', 'Error processing request for: ' + req.researchStudyName + ' with CRO ' + req.croName);
                result.put('error', e.getMessage());
            }

            resp.responseJson = JSON.serialize(result);
            responses.add(resp);
        }

        return responses;
    }
}