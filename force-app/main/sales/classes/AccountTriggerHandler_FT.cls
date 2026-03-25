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
}
