public class OpportunityTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        List<Opportunity> newOpps = (List<Opportunity>) Trigger.new;
        categorizeDealSize(newOpps);
        setVPApprovalFlag(newOpps);
    }

    public override void beforeUpdate() {
        List<Opportunity> newOpps = (List<Opportunity>) Trigger.new;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        categorizeDealSize(newOpps);
        setVPApprovalFlag(newOpps);
        flagRiskyOpportunities(newOpps, oldMap);
    }

    public override void afterInsert() {
        rollUpAccountPipeline();
    }

    public override void afterUpdate() {
        rollUpAccountPipeline();
    }

    public override void afterDelete() {
        rollUpAccountPipeline();
    }

    public override void afterUndelete() {
        rollUpAccountPipeline();
    }

    // Rule 1: Auto-categorize deal size based on Amount
    @TestVisible
    private void categorizeDealSize(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            if (opp.Amount == null) {
                opp.Deal_Size_Category__c = null;
            } else if (opp.Amount < 10000) {
                opp.Deal_Size_Category__c = 'Small';
            } else if (opp.Amount < 50000) {
                opp.Deal_Size_Category__c = 'Medium';
            } else if (opp.Amount < 250000) {
                opp.Deal_Size_Category__c = 'Large';
            } else {
                opp.Deal_Size_Category__c = 'Enterprise';
            }
        }
    }

    // Rule 2: Flag deals requiring VP approval
    @TestVisible
    private void setVPApprovalFlag(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            Decimal amount = opp.Amount != null ? opp.Amount : 0;
            Decimal discount = opp.Discount_Percent__c != null ? opp.Discount_Percent__c : 0;
            opp.Requires_VP_Approval__c = (amount >= 100000 || discount > 20);
        }
    }

    // Rule 3: Flag risky opportunities
    @TestVisible
    private void flagRiskyOpportunities(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        Set<String> closedStages = new Set<String>{ 'Closed Won', 'Closed Lost' };

        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean isOpen = !closedStages.contains(opp.StageName);

            if (!isOpen) {
                opp.Risk_Flag__c = false;
                continue;
            }

            Boolean isPastDue = opp.CloseDate != null && opp.CloseDate < Date.today();
            Boolean pushedOut = opp.CloseDate != null
                && oldOpp.CloseDate != null
                && opp.CloseDate > oldOpp.CloseDate.addDays(30);

            opp.Risk_Flag__c = isPastDue || pushedOut;
        }
    }

    // Rule 4: Roll up pipeline metrics to parent Account
    private void rollUpAccountPipeline() {
        Set<Id> accountIds = new Set<Id>();

        if (Trigger.new != null) {
            for (SObject so : Trigger.new) {
                Opportunity opp = (Opportunity) so;
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
        }
        if (Trigger.old != null) {
            for (SObject so : Trigger.old) {
                Opportunity opp = (Opportunity) so;
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            }
        }

        rollUpAccountPipeline(accountIds);
    }

    @TestVisible
    private void rollUpAccountPipeline(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        OpportunitySelector selector = OpportunitySelector.getInstance();

        // Aggregate open pipeline
        Map<Id, Decimal> pipelineByAccount = new Map<Id, Decimal>();
        Map<Id, Integer> countByAccount = new Map<Id, Integer>();

        for (OpportunitySelector.PipelineAggregate pa : selector.getOpenPipelineByAccountIds(accountIds)) {
            pipelineByAccount.put(pa.accountId, pa.totalAmount);
            countByAccount.put(pa.accountId, pa.oppCount);
        }

        // Aggregate last won close date
        Map<Id, Date> lastWonByAccount = new Map<Id, Date>();

        for (OpportunitySelector.LastWonAggregate lwa : selector.getLastWonDateByAccountIds(accountIds)) {
            lastWonByAccount.put(lwa.accountId, lwa.lastWonDate);
        }

        // Build Account updates
        List<Account> accountsToUpdate = new List<Account>();
        for (Id acctId : accountIds) {
            accountsToUpdate.add(new Account(
                Id = acctId,
                Total_Open_Pipeline__c = pipelineByAccount.containsKey(acctId)
                    ? pipelineByAccount.get(acctId) : 0,
                Active_Opportunities__c = countByAccount.containsKey(acctId)
                    ? countByAccount.get(acctId) : 0,
                Last_Opportunity_Close_Date__c = lastWonByAccount.get(acctId)
            ));
        }

        update accountsToUpdate;
    }
}
