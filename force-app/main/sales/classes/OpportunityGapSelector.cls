public virtual class OpportunityGapSelector {

    @TestVisible
    private static OpportunityGapSelector mockInstance;

    public static OpportunityGapSelector getInstance() {
        return mockInstance != null ? mockInstance : new OpportunityGapSelector();
    }

    public virtual List<OpportunityGap__c> getGapsByOpportunityIds(Set<Id> oppIds) {
        return [
            SELECT Id, Amount__c, Opportunity__c, ProductGap__c
            FROM OpportunityGap__c
            WHERE Opportunity__c IN :oppIds
        ];
    }
}
