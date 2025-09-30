trigger CROResearchEventTrigger on CRO_Research_Event__e (after insert) {  
    if(trigger.isAfter && trigger.isInsert){
        CROResearchEventHandler.afterInsert(trigger.new);
    }
}