public class CandidateScoringHandler {

    public static void assignCandidateStatus(Id enrolledSiteId) {
        List<Enrolled_Site_Research_Candidate__c> candidates = [
            SELECT Id, Eligibility_Score__c, Status__c,Enrolled_Site__r.CRO_Research_Study__r.Enrolled_Candidate_Count__c 
            FROM Enrolled_Site_Research_Candidate__c 
            WHERE Enrolled_Site__c = :enrolledSiteId 
            AND Status__c = 'Shortlisted'
            AND Eligibility_Score__c != null
            AND RecordType.DeveloperName = 'Enrolled'
            ORDER BY Eligibility_Score__c DESC
        ];

        Integer enrolledCount = 0;
        for (Enrolled_Site_Research_Candidate__c cand : candidates) {
            Integer candidateCount = Integer.valueOf(cand.Enrolled_Site__r.CRO_Research_Study__r.Enrolled_Candidate_Count__c);
            if (cand.Eligibility_Score__c > 90) {
                cand.Status__c = 'Invite Sent for Enrollment';
                enrolledCount++;
            } else if (cand.Eligibility_Score__c > 70) {
                cand.Status__c = 'On Hold';
            } else {
                cand.Status__c = 'Rejected After Shortlisted';
            }
        }
        update candidates;
    }
}