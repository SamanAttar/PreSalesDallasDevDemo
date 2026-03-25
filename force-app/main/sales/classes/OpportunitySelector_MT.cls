@IsTest
public class OpportunitySelector_MT extends OpportunitySelector {

    private List<PipelineAggregate> pipelineResults = new List<PipelineAggregate>();
    private List<LastWonAggregate> lastWonResults = new List<LastWonAggregate>();

    public void setPipelineResults(List<PipelineAggregate> results) {
        this.pipelineResults = results;
    }

    public void setLastWonResults(List<LastWonAggregate> results) {
        this.lastWonResults = results;
    }

    public override List<PipelineAggregate> getOpenPipelineByAccountIds(Set<Id> accountIds) {
        return pipelineResults;
    }

    public override List<LastWonAggregate> getLastWonDateByAccountIds(Set<Id> accountIds) {
        return lastWonResults;
    }
}
