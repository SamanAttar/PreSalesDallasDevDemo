public class AccountTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        setPriorityScore((List<Account>) Trigger.new, null);
    }

    public override void beforeUpdate() {
        autoSetCustomerTier(
            (List<Account>) Trigger.new,
            (Map<Id, Account>) Trigger.oldMap
        );
        setPriorityScore(
            (List<Account>) Trigger.new,
            (Map<Id, Account>) Trigger.oldMap
        );
    }

    // Rule 5: Auto-set Customer Tier based on pipeline value
    @TestVisible
    private void autoSetCustomerTier(List<Account> newAccounts, Map<Id, Account> oldMap) {
        for (Account acct : newAccounts) {
            Account oldAcct = oldMap.get(acct.Id);

            if (acct.Total_Open_Pipeline__c == oldAcct.Total_Open_Pipeline__c) {
                continue;
            }

            Decimal pipeline = acct.Total_Open_Pipeline__c != null
                ? acct.Total_Open_Pipeline__c : 0;

            if (pipeline >= 500000) {
                acct.Customer_Tier__c = 'Tier 1 - Strategic';
            } else if (pipeline >= 100000) {
                acct.Customer_Tier__c = 'Tier 2 - Major';
            } else {
                acct.Customer_Tier__c = 'Tier 3 - Standard';
            }
        }
    }

    // Priority Score: the override wins when set, otherwise calculate from pipeline.
    // Stored by Apex rather than a formula so the field can be history-tracked.
    // oldMap is null on insert, where every record is scored.
    @TestVisible
    private void setPriorityScore(List<Account> newAccounts, Map<Id, Account> oldMap) {
        for (Account acct : newAccounts) {
            if (oldMap != null && !priorityInputsChanged(acct, oldMap.get(acct.Id))) {
                continue;
            }

            acct.Account_Priority_Score__c = acct.Account_Priority_Score_Override__c != null
                ? acct.Account_Priority_Score_Override__c
                : calculatePriorityScore(acct);
        }
    }

    private Boolean priorityInputsChanged(Account acct, Account oldAcct) {
        return acct.Account_Priority_Score_Override__c != oldAcct.Account_Priority_Score_Override__c
            || acct.Total_Open_Pipeline__c != oldAcct.Total_Open_Pipeline__c
            || acct.Active_Opportunities__c != oldAcct.Active_Opportunities__c;
    }

    @TestVisible
    private Integer calculatePriorityScore(Account acct) {
        Decimal pipeline = acct.Total_Open_Pipeline__c != null
            ? acct.Total_Open_Pipeline__c : 0;
        Decimal activeOpps = acct.Active_Opportunities__c != null
            ? acct.Active_Opportunities__c : 0;

        Decimal score = (pipeline / 10000).setScale(0, System.RoundingMode.HALF_UP)
            + (activeOpps * 5);

        return Math.min(100, score.intValue());
    }
}
