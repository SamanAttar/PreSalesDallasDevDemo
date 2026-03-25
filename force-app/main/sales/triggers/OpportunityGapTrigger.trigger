trigger OpportunityGapTrigger on OpportunityGap__c (after insert, after update) {
    new OpportunityGapTriggerHandler().run();
}
