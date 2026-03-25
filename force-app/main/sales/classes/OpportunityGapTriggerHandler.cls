public class OpportunityGapTriggerHandler extends TriggerHandler {

    public override void afterInsert() {
        copyAmountsOnInsert((List<OpportunityGap__c>) Trigger.new);
    }

    public override void afterUpdate() {
        resyncAmountsOnReparent(
            (List<OpportunityGap__c>) Trigger.new,
            (Map<Id, OpportunityGap__c>) Trigger.oldMap
        );
    }

    // Copies the related Opportunity's Amount to each newly inserted OpportunityGap__c.
    // Bulkified: one SOQL to fetch all needed Opportunities, then one DML to update gaps.
    @TestVisible
    private void copyAmountsOnInsert(List<OpportunityGap__c> newGaps) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityGap__c gap : newGaps) {
            if (gap.Opportunity__c != null) {
                oppIds.add(gap.Opportunity__c);
            }
        }
        if (oppIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Amount FROM Opportunity WHERE Id IN :oppIds]
        );

        List<OpportunityGap__c> gapsToUpdate = new List<OpportunityGap__c>();
        for (OpportunityGap__c gap : newGaps) {
            if (gap.Opportunity__c != null && oppMap.containsKey(gap.Opportunity__c)) {
                gapsToUpdate.add(new OpportunityGap__c(
                    Id = gap.Id,
                    Amount__c = oppMap.get(gap.Opportunity__c).Amount
                ));
            }
        }

        if (!gapsToUpdate.isEmpty()) {
            update gapsToUpdate;
        }
    }

    // Re-syncs Amount__c on OpportunityGap__c records whose Opportunity__c lookup changed.
    // Only processes records where the parent Opportunity actually changed.
    // Bulkified: one SOQL to fetch all newly referenced Opportunities, then one DML.
    @TestVisible
    private void resyncAmountsOnReparent(List<OpportunityGap__c> newGaps, Map<Id, OpportunityGap__c> oldMap) {
        Set<Id> changedOppIds = new Set<Id>();
        List<OpportunityGap__c> changedGaps = new List<OpportunityGap__c>();

        for (OpportunityGap__c gap : newGaps) {
            OpportunityGap__c oldGap = oldMap.get(gap.Id);
            if (gap.Opportunity__c != oldGap.Opportunity__c && gap.Opportunity__c != null) {
                changedOppIds.add(gap.Opportunity__c);
                changedGaps.add(gap);
            }
        }
        if (changedOppIds.isEmpty()) {
            return;
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Amount FROM Opportunity WHERE Id IN :changedOppIds]
        );

        List<OpportunityGap__c> gapsToUpdate = new List<OpportunityGap__c>();
        for (OpportunityGap__c gap : changedGaps) {
            if (oppMap.containsKey(gap.Opportunity__c)) {
                gapsToUpdate.add(new OpportunityGap__c(
                    Id = gap.Id,
                    Amount__c = oppMap.get(gap.Opportunity__c).Amount
                ));
            }
        }

        if (!gapsToUpdate.isEmpty()) {
            update gapsToUpdate;
        }
    }
}
