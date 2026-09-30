@IsTest
private class AccountTriggerHandler_UT {

    static Id fakeAccountId() {
        return Account.SObjectType.getDescribe().getKeyPrefix() + '000000000001';
    }

    @IsTest
    static void testTierStrategic() {
        Id fakeId = fakeAccountId();
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 0);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 600000);

        AccountTriggerHandler handler = new AccountTriggerHandler();
        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );

        System.assertEquals('Tier 1 - Strategic', newAcct.Customer_Tier__c);
    }

    @IsTest
    static void testTierMajor() {
        Id fakeId = fakeAccountId();
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 0);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 200000);

        AccountTriggerHandler handler = new AccountTriggerHandler();
        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );

        System.assertEquals('Tier 2 - Major', newAcct.Customer_Tier__c);
    }

    @IsTest
    static void testTierStandard() {
        Id fakeId = fakeAccountId();
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 0);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 50000);

        AccountTriggerHandler handler = new AccountTriggerHandler();
        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );

        System.assertEquals('Tier 3 - Standard', newAcct.Customer_Tier__c);
    }

    @IsTest
    static void testTierEdgeCaseBoundaries() {
        Id fakeId = fakeAccountId();
        AccountTriggerHandler handler = new AccountTriggerHandler();

        // Exactly 500K → Tier 1
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 0);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 500000);
        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );
        System.assertEquals('Tier 1 - Strategic', newAcct.Customer_Tier__c);

        // Exactly 100K → Tier 2
        oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 500000);
        newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 100000);
        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );
        System.assertEquals('Tier 2 - Major', newAcct.Customer_Tier__c);

        // Just under 100K → Tier 3
        oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 100000);
        newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 99999.99);
        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );
        System.assertEquals('Tier 3 - Standard', newAcct.Customer_Tier__c);
    }

    @IsTest
    static void testTierNotChangedWhenPipelineUnchanged() {
        Id fakeId = fakeAccountId();
        AccountTriggerHandler handler = new AccountTriggerHandler();

        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 600000, Customer_Tier__c = 'Tier 1 - Strategic');
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 600000, Customer_Tier__c = 'Tier 1 - Strategic');

        handler.autoSetCustomerTier(
            new List<Account>{ newAcct },
            new Map<Id, Account>{ fakeId => oldAcct }
        );

        // Tier should remain unchanged since pipeline didn't change
        System.assertEquals('Tier 1 - Strategic', newAcct.Customer_Tier__c);
    }

    @IsTest
    static void testPriorityScoreCalculation() {
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account acct = new Account(Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3);

        Test.startTest();
        Integer score = handler.calculatePriorityScore(acct);
        Test.stopTest();

        Assert.areEqual(40, score, '250K pipeline and 3 active opps should score 25 + 15');
    }

    @IsTest
    static void testPriorityScoreRoundsHalfUp() {
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account acct = new Account(Total_Open_Pipeline__c = 15000, Active_Opportunities__c = 0);

        Test.startTest();
        Integer score = handler.calculatePriorityScore(acct);
        Test.stopTest();

        Assert.areEqual(2, score, '15K pipeline is 1.5 points, which should round up to 2');
    }

    @IsTest
    static void testPriorityScoreCappedAt100() {
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account acct = new Account(Total_Open_Pipeline__c = 1200000, Active_Opportunities__c = 2);

        Test.startTest();
        Integer score = handler.calculatePriorityScore(acct);
        Test.stopTest();

        Assert.areEqual(100, score, '120 + 10 should be capped at 100');
    }

    @IsTest
    static void testPriorityScoreBlankInputsAreZero() {
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account acct = new Account(Total_Open_Pipeline__c = null, Active_Opportunities__c = null);

        Test.startTest();
        Integer score = handler.calculatePriorityScore(acct);
        Test.stopTest();

        Assert.areEqual(0, score, 'Blank pipeline and active opps should be treated as 0');
    }

    @IsTest
    static void testPriorityScoreSetOnInsert() {
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account acct = new Account(Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3);

        Test.startTest();
        handler.setPriorityScore(new List<Account>{ acct }, null);
        Test.stopTest();

        Assert.areEqual(40, acct.Account_Priority_Score__c, 'Insert (null oldMap) should always score the record');
    }

    @IsTest
    static void testPriorityScoreOverrideWins() {
        Id fakeId = fakeAccountId();
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3,
            Account_Priority_Score_Override__c = 90);

        Test.startTest();
        handler.setPriorityScore(new List<Account>{ newAcct }, new Map<Id, Account>{ fakeId => oldAcct });
        Test.stopTest();

        Assert.areEqual(90, newAcct.Account_Priority_Score__c, 'Override should replace the calculated score');
    }

    @IsTest
    static void testPriorityScoreOverrideOfZeroIsHonored() {
        Id fakeId = fakeAccountId();
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 1200000, Active_Opportunities__c = 2);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 1200000, Active_Opportunities__c = 2,
            Account_Priority_Score_Override__c = 0);

        Test.startTest();
        handler.setPriorityScore(new List<Account>{ newAcct }, new Map<Id, Account>{ fakeId => oldAcct });
        Test.stopTest();

        Assert.areEqual(0, newAcct.Account_Priority_Score__c, 'An override of 0 is a real value, not blank');
    }

    @IsTest
    static void testPriorityScoreRecalculatedWhenOverrideCleared() {
        Id fakeId = fakeAccountId();
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account oldAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3,
            Account_Priority_Score_Override__c = 90, Account_Priority_Score__c = 90);
        Account newAcct = new Account(Id = fakeId, Total_Open_Pipeline__c = 250000, Active_Opportunities__c = 3,
            Account_Priority_Score_Override__c = null, Account_Priority_Score__c = 90);

        Test.startTest();
        handler.setPriorityScore(new List<Account>{ newAcct }, new Map<Id, Account>{ fakeId => oldAcct });
        Test.stopTest();

        Assert.areEqual(40, newAcct.Account_Priority_Score__c, 'Clearing the override should fall back to the calculation');
    }

    @IsTest
    static void testPriorityScoreUntouchedWhenInputsUnchanged() {
        Id fakeId = fakeAccountId();
        AccountTriggerHandler handler = new AccountTriggerHandler();
        Account oldAcct = new Account(Id = fakeId, Name = 'Old Name', Total_Open_Pipeline__c = 250000,
            Active_Opportunities__c = 3, Account_Priority_Score__c = 55);
        Account newAcct = new Account(Id = fakeId, Name = 'New Name', Total_Open_Pipeline__c = 250000,
            Active_Opportunities__c = 3, Account_Priority_Score__c = 55);

        Test.startTest();
        handler.setPriorityScore(new List<Account>{ newAcct }, new Map<Id, Account>{ fakeId => oldAcct });
        Test.stopTest();

        Assert.areEqual(55, newAcct.Account_Priority_Score__c, 'Score should not be recalculated when no input changed');
    }
}
