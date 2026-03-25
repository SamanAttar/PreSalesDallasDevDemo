public virtual class OpportunitySelector {

    @TestVisible
    private static OpportunitySelector mockInstance;

    public static OpportunitySelector getInstance() {
        return mockInstance != null ? mockInstance : new OpportunitySelector();
    }

    public virtual List<PipelineAggregate> getOpenPipelineByAccountIds(Set<Id> accountIds) {
        List<PipelineAggregate> results = new List<PipelineAggregate>();
        for (AggregateResult ar : [
            SELECT AccountId, SUM(Amount) totalAmt, COUNT(Id) oppCount
            FROM Opportunity
            WHERE AccountId IN :accountIds
                AND StageName NOT IN ('Closed Won', 'Closed Lost')
            GROUP BY AccountId
        ]) {
            results.add(new PipelineAggregate(
                (Id) ar.get('AccountId'),
                (Decimal) ar.get('totalAmt'),
                (Integer) ar.get('oppCount')
            ));
        }
        return results;
    }

    public virtual List<LastWonAggregate> getLastWonDateByAccountIds(Set<Id> accountIds) {
        List<LastWonAggregate> results = new List<LastWonAggregate>();
        for (AggregateResult ar : [
            SELECT AccountId, MAX(CloseDate) lastWon
            FROM Opportunity
            WHERE AccountId IN :accountIds
                AND StageName NOT IN ('Closed Won', 'Closed Lost')
            GROUP BY AccountId
        ]) {
            results.add(new LastWonAggregate(
                (Id) ar.get('AccountId'),
                (Date) ar.get('lastWon')
            ));
        }
        return results;
    }

    public class PipelineAggregate {
        public Id accountId;
        public Decimal totalAmount;
        public Integer oppCount;

        public PipelineAggregate(Id accountId, Decimal totalAmount, Integer oppCount) {
            this.accountId = accountId;
            this.totalAmount = totalAmount;
            this.oppCount = oppCount;
        }
    }

    public class LastWonAggregate {
        public Id accountId;
        public Date lastWonDate;

        public LastWonAggregate(Id accountId, Date lastWonDate) {
            this.accountId = accountId;
            this.lastWonDate = lastWonDate;
        }
    }
}
