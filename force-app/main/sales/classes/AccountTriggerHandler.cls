public class AccountTriggerHandler extends TriggerHandler {

    public override void beforeUpdate() {
        autoSetCustomerTier(
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
}
