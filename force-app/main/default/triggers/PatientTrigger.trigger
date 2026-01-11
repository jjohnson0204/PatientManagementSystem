trigger PatientTrigger on Patient__c (before insert, before update, 
                                      after insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            PatientTriggerHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            PatientTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PatientTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            PatientTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}