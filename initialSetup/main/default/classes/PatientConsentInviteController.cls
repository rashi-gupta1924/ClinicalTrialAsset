public with sharing class PatientConsentInviteController {
    @AuraEnabled
    public static void updateStatus(Id recordId, String statusValue) {
        if (String.isBlank(recordId) || String.isBlank(statusValue)) {
            throw new AuraHandledException('Record Id or Status value missing');
        }

        Patient_Consent_Invite__c pci = [
            SELECT Id, Status__c 
            FROM Patient_Consent_Invite__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        pci.Status__c = statusValue;
        update pci;
    }
}