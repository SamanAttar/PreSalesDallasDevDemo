@IsTest
private class OpportunityTriggerHandler_FT {

    @TestSetup
    static void setup() {
        Account testAcct = new Account(Name = 'Functional Test Account');
        insert testAcct;
    }

    static Account getTestAccount() {
        return [
            SELECT Id, Customer_Tier__c, Total_Open_Pipeline__c,
                   Active_Opportunities__c, Last_Opportunity_Close_Date__c
            FROM Account WHERE Name = 'Functional Test Account' LIMIT 1
        ];
    }

    static Opportunity createOpp(Id accountId, String stageName, Decimal amount, Date closeDate) {
        return new Opportunity(
            AccountId = accountId,
            Name = 'Func Test Opp',
            StageName = stageName,
            Amount = amount,
            CloseDate = closeDate
        );
    }

    // ── Before-trigger rules through real DML ──

    @IsTest
    static void testDealSizeSetOnInsert() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 5000, Date.today().addDays(30));
        insert opp;
        opp = [SELECT Deal_Size_Category__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Small', opp.Deal_Size_Category__c);
    }

    @IsTest
    static void testDealSizeRecategorizedOnUpdate() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 5000, Date.today().addDays(30));
        insert opp;
        opp.Amount = 60000;
        update opp;
        opp = [SELECT Deal_Size_Category__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Large', opp.Deal_Size_Category__c);
    }

    @IsTest
    static void testVPApprovalSetOnInsert() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 150000, Date.today().addDays(30));
        insert opp;
        opp = [SELECT Requires_VP_Approval__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, opp.Requires_VP_Approval__c);
    }

    @IsTest
    static void testRiskFlagPastDue() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 10000, Date.today().addDays(30));
        insert opp;
        opp.CloseDate = Date.today().addDays(-5);
        update opp;
        opp = [SELECT Risk_Flag__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, opp.Risk_Flag__c);
    }

    // ── Pipeline rollup through real DML ──

    @IsTest
    static void testPipelineRollupOnInsert() {
        Account acct = getTestAccount();
        List<Opportunity> opps = new List<Opportunity>{
            createOpp(acct.Id, 'Prospecting', 50000, Date.today().addDays(30)),
            createOpp(acct.Id, 'Qualification', 75000, Date.today().addDays(60))
        };
        opps[1].Name = 'Func Test Opp 2';
        insert opps;
        acct = getTestAccount();
        System.assertEquals(125000, acct.Total_Open_Pipeline__c);
        System.assertEquals(2, acct.Active_Opportunities__c);
    }

    @IsTest
    static void testPipelineRollupExcludesClosedWon() {
        Account acct = getTestAccount();
        Opportunity opp1 = createOpp(acct.Id, 'Prospecting', 50000, Date.today().addDays(30));
        Opportunity opp2 = createOpp(acct.Id, 'Prospecting', 75000, Date.today().addDays(30));
        opp2.Name = 'Func Test Opp 2';
        insert new List<Opportunity>{ opp1, opp2 };
        opp1.StageName = 'Closed Won';
        update opp1;
        acct = getTestAccount();
        System.assertEquals(75000, acct.Total_Open_Pipeline__c);
        System.assertEquals(1, acct.Active_Opportunities__c);
        System.assertEquals(Date.today().addDays(30), acct.Last_Opportunity_Close_Date__c);
    }

    @IsTest
    static void testPipelineRollupOnDelete() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 50000, Date.today().addDays(30));
        insert opp;
        delete opp;
        acct = getTestAccount();
        System.assertEquals(0, acct.Total_Open_Pipeline__c);
        System.assertEquals(0, acct.Active_Opportunities__c);
    }

    @IsTest
    static void testPipelineRollupOnUndelete() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 50000, Date.today().addDays(30));
        insert opp;
        delete opp;
        undelete opp;
        acct = getTestAccount();
        System.assertEquals(50000, acct.Total_Open_Pipeline__c);
        System.assertEquals(1, acct.Active_Opportunities__c);
    }

    @IsTest
    static void testPipelineRollupBulk() {
        Account acct = getTestAccount();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Opportunity opp = createOpp(acct.Id, 'Prospecting', 1000, Date.today().addDays(30));
            opp.Name = 'Bulk Opp ' + i;
            opps.add(opp);
        }
        insert opps;
        acct = getTestAccount();
        System.assertEquals(200000, acct.Total_Open_Pipeline__c);
        System.assertEquals(200, acct.Active_Opportunities__c);
    }

    // ── Full Chain: Opp → Account Pipeline → Account Tier ──

    @IsTest
    static void testAmountChangePropagatestoGaps() {
        Account acct = getTestAccount();
        Opportunity opp = createOpp(acct.Id, 'Prospecting', 50000, Date.today().addDays(30));
        insert opp;

        ProductGap__c gap = new ProductGap__c(Name = 'FT Gap', Status__c = 'New', Category__c = 'Reporting');
        insert gap;

        OpportunityGap__c oppGap = new OpportunityGap__c(ProductGap__c = gap.Id, Opportunity__c = opp.Id);
        insert oppGap;

        // Verify initial amount was copied
        oppGap = [SELECT Amount__c FROM OpportunityGap__c WHERE Id = :oppGap.Id];
        Assert.areEqual(50000, oppGap.Amount__c, 'Amount__c should be copied from Opportunity on insert');

        // Update the opportunity amount
        opp.Amount = 99000;
        update opp;

        // Verify the gap amount was updated
        oppGap = [SELECT Amount__c FROM OpportunityGap__c WHERE Id = :oppGap.Id];
        Assert.areEqual(99000, oppGap.Amount__c, 'Amount__c should be updated when linked Opportunity Amount changes');
    }

    @IsTest
    static void testFullChainOpportunityToAccountTier() {
        Account acct = getTestAccount();

        Opportunity opp1 = createOpp(acct.Id, 'Prospecting', 300000, Date.today().addDays(30));
        Opportunity opp2 = createOpp(acct.Id, 'Qualification', 300000, Date.today().addDays(60));
        opp2.Name = 'Chain Opp 2';

        Test.startTest();
        insert new List<Opportunity>{ opp1, opp2 };
        Test.stopTest();

        acct = getTestAccount();
        System.assertEquals(600000, acct.Total_Open_Pipeline__c);
        System.assertEquals('Tier 1 - Strategic', acct.Customer_Tier__c);

        delete new List<Opportunity>{ opp1, opp2 };
        acct = getTestAccount();
        System.assertEquals(0, acct.Total_Open_Pipeline__c);
        System.assertEquals('Tier 3 - Standard', acct.Customer_Tier__c);
    }
}
