trigger PatientEligibilityEventTrigger on Patient_Eligibility_Event__e (after insert) {
	if(trigger.isAfter && trigger.isInsert){
        PatientEligibilityEventTriggerHandler.afterInsert(trigger.new);
    }
}