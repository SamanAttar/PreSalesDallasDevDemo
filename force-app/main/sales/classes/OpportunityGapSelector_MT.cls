@IsTest
public class OpportunityGapSelector_MT extends OpportunityGapSelector {

    private List<OpportunityGap__c> gapsResults = new List<OpportunityGap__c>();

    public void setGapsResults(List<OpportunityGap__c> results) {
        this.gapsResults = results;
    }

    public override List<OpportunityGap__c> getGapsByOpportunityIds(Set<Id> oppIds) {
        return gapsResults;
    }
}
