@IsTest
private class AccountTriggerHandler_FT {

    @TestSetup
    static void setup() {
        Account testAcct = new Account(Name = 'Tier Func Test Account');
        insert testAcct;
    }

    static Account getTestAccount() {
        return [SELECT Id, Customer_Tier__c, Total_Open_Pipeline__c FROM Account WHERE Name = 'Tier Func Test Account' LIMIT 1];
    }

    @IsTest
    static void testTierSetThroughTrigger() {
        Account acct = getTestAccount();
        acct.Total_Open_Pipeline__c = 600000;
        update acct;
        acct = getTestAccount();
        System.assertEquals('Tier 1 - Strategic', acct.Customer_Tier__c);
    }

    @IsTest
    static void testTierDowngradeThroughTrigger() {
        Account acct = getTestAccount();
        acct.Total_Open_Pipeline__c = 600000;
        update acct;

        acct = getTestAccount();
        acct.Total_Open_Pipeline__c = 50000;
        update acct;

        acct = getTestAccount();
        System.assertEquals('Tier 3 - Standard', acct.Customer_Tier__c);
    }

    @IsTest
    static void testTierUnchangedWhenPipelineUnchanged() {
        Account acct = getTestAccount();
        acct.Total_Open_Pipeline__c = 600000;
        update acct;

        acct = getTestAccount();
        acct.Name = 'Renamed Account';
        update acct;

        acct = [SELECT Customer_Tier__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals('Tier 1 - Strategic', acct.Customer_Tier__c);
    }

    static Account getPriorityAccount(Id acctId) {
        return [
            SELECT Id, Account_Priority_Score__c, Account_Priority_Score_Override__c,
                Total_Open_Pipeline__c, Active_Opportunities__c
            FROM Account
            WHERE Id = :acctId
        ];
    }

    @IsTest
    static void testPriorityScoreSetOnInsert() {
        Account acct = new Account(Name = 'Priority Insert', Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3);

        Test.startTest();
        insert acct;
        Test.stopTest();

        Assert.areEqual(40, getPriorityAccount(acct.Id).Account_Priority_Score__c, 'Score should be calculated on insert');
    }

    @IsTest
    static void testPriorityScoreRecalculatedWhenPipelineChanges() {
        Account acct = new Account(Name = 'Priority Pipeline', Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3);
        insert acct;

        Test.startTest();
        acct.Total_Open_Pipeline__c = 500000;
        update acct;
        Test.stopTest();

        Assert.areEqual(65, getPriorityAccount(acct.Id).Account_Priority_Score__c, 'Score should follow the new pipeline');
    }

    @IsTest
    static void testPriorityScoreOverrideSticksThroughPipelineChanges() {
        Account acct = new Account(Name = 'Priority Override', Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3);
        insert acct;

        Test.startTest();
        acct.Account_Priority_Score_Override__c = 90;
        update acct;
        acct.Total_Open_Pipeline__c = 10000;
        update acct;
        Test.stopTest();

        Assert.areEqual(90, getPriorityAccount(acct.Id).Account_Priority_Score__c, 'Override should hold while it is set');
    }

    @IsTest
    static void testPriorityScoreRecalculatedWhenOverrideCleared() {
        Account acct = new Account(Name = 'Priority Clear', Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3,
            Account_Priority_Score_Override__c = 90);
        insert acct;
        Assert.areEqual(90, getPriorityAccount(acct.Id).Account_Priority_Score__c, 'Override should apply on insert');

        Test.startTest();
        acct.Account_Priority_Score_Override__c = null;
        update acct;
        Test.stopTest();

        Assert.areEqual(40, getPriorityAccount(acct.Id).Account_Priority_Score__c, 'Clearing the override should recalculate');
    }

    @IsTest
    static void testPriorityScoreBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Priority Bulk ' + i, Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3));
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Account> inserted = [SELECT Account_Priority_Score__c FROM Account WHERE Name LIKE 'Priority Bulk %'];
        Assert.areEqual(200, inserted.size(), 'All 200 accounts should have been inserted');
        for (Account acct : inserted) {
            Assert.areEqual(40, acct.Account_Priority_Score__c, 'Every bulk-inserted account should be scored');
        }
    }
}
