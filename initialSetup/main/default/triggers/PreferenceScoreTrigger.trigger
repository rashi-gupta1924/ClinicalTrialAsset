trigger PreferenceScoreTrigger on Preference_Score_Event__e (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        PreferenceScoreEventTriggerHandler.afterInsert(trigger.new);
    }
}