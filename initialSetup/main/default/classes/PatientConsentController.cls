public with sharing class PatientConsentController {
    @AuraEnabled
    public static void updateEnrollmentStatus(Id recordId, String newStatus) {
        if(recordId == null || String.isBlank(newStatus)) {
            throw new AuraHandledException('Record Id or Status is missing');
        }

        Patient_Consent_Invite__c pci = [
            SELECT Id, Name, Status__c 
            FROM Patient_Consent_Invite__c 
            WHERE Id = :recordId
            LIMIT 1
        ];

        pci.Status__c = newStatus;
        update pci;
    }
    
}