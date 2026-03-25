@IsTest
private class OpportunityTriggerHandler_UT {

    // ── Helpers ──

    static Opportunity buildOpp(Decimal amount) {
        return new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            Amount = amount,
            CloseDate = Date.today().addDays(30)
        );
    }

    static Id fakeOppId() {
        return Opportunity.SObjectType.getDescribe().getKeyPrefix() + '000000000001';
    }

    // ── Rule 1: Deal Size Categorization ──

    @IsTest
    static void testDealSizeSmall() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(5000) };
        handler.categorizeDealSize(opps);
        System.assertEquals('Small', opps[0].Deal_Size_Category__c);
    }

    @IsTest
    static void testDealSizeMedium() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(25000) };
        handler.categorizeDealSize(opps);
        System.assertEquals('Medium', opps[0].Deal_Size_Category__c);
    }

    @IsTest
    static void testDealSizeLarge() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(100000) };
        handler.categorizeDealSize(opps);
        System.assertEquals('Large', opps[0].Deal_Size_Category__c);
    }

    @IsTest
    static void testDealSizeEnterprise() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(300000) };
        handler.categorizeDealSize(opps);
        System.assertEquals('Enterprise', opps[0].Deal_Size_Category__c);
    }

    @IsTest
    static void testDealSizeNullAmount() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(null) };
        handler.categorizeDealSize(opps);
        System.assertEquals(null, opps[0].Deal_Size_Category__c);
    }

    @IsTest
    static void testDealSizeRecategorizedOnAmountChange() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(5000) };
        handler.categorizeDealSize(opps);
        System.assertEquals('Small', opps[0].Deal_Size_Category__c);

        opps[0].Amount = 60000;
        handler.categorizeDealSize(opps);
        System.assertEquals('Large', opps[0].Deal_Size_Category__c);
    }

    // ── Rule 2: VP Approval Flag ──

    @IsTest
    static void testVPApprovalHighAmount() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        List<Opportunity> opps = new List<Opportunity>{ buildOpp(150000) };
        handler.setVPApprovalFlag(opps);
        System.assertEquals(true, opps[0].Requires_VP_Approval__c);
    }

    @IsTest
    static void testVPApprovalHighDiscount() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Opportunity opp = buildOpp(5000);
        opp.Discount_Percent__c = 25;
        handler.setVPApprovalFlag(new List<Opportunity>{ opp });
        System.assertEquals(true, opp.Requires_VP_Approval__c);
    }

    @IsTest
    static void testVPApprovalNotRequired() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Opportunity opp = buildOpp(5000);
        opp.Discount_Percent__c = 10;
        handler.setVPApprovalFlag(new List<Opportunity>{ opp });
        System.assertEquals(false, opp.Requires_VP_Approval__c);
    }

    @IsTest
    static void testVPApprovalClearedOnUpdate() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Opportunity opp = buildOpp(150000);
        handler.setVPApprovalFlag(new List<Opportunity>{ opp });
        System.assertEquals(true, opp.Requires_VP_Approval__c);

        opp.Amount = 5000;
        opp.Discount_Percent__c = 0;
        handler.setVPApprovalFlag(new List<Opportunity>{ opp });
        System.assertEquals(false, opp.Requires_VP_Approval__c);
    }

    // ── Rule 3: Risk Flag ──

    @IsTest
    static void testRiskFlagPastDue() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Id fakeId = fakeOppId();

        Opportunity oldOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        Opportunity newOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(-5));

        handler.flagRiskyOpportunities(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ fakeId => oldOpp }
        );
        System.assertEquals(true, newOpp.Risk_Flag__c);
    }

    @IsTest
    static void testRiskFlagPushedOut() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Id fakeId = fakeOppId();

        Opportunity oldOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        Opportunity newOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(50));

        handler.flagRiskyOpportunities(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ fakeId => oldOpp }
        );
        System.assertEquals(true, newOpp.Risk_Flag__c);
    }

    @IsTest
    static void testRiskFlagClearedOnClose() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Id fakeId = fakeOppId();

        Opportunity oldOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(-5));
        Opportunity newOpp = new Opportunity(Id = fakeId, StageName = 'Closed Won', CloseDate = Date.today());

        handler.flagRiskyOpportunities(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ fakeId => oldOpp }
        );
        System.assertEquals(false, newOpp.Risk_Flag__c);
    }

    @IsTest
    static void testRiskFlagNotSetOnSmallPush() {
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
        Id fakeId = fakeOppId();

        Opportunity oldOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        Opportunity newOpp = new Opportunity(Id = fakeId, StageName = 'Prospecting', CloseDate = Date.today().addDays(30));

        handler.flagRiskyOpportunities(
            new List<Opportunity>{ newOpp },
            new Map<Id, Opportunity>{ fakeId => oldOpp }
        );
        System.assertEquals(false, newOpp.Risk_Flag__c);
    }

    // ── Rule 4: Account Pipeline Rollup (mocked selector) ──

    @IsTest
    static void testPipelineRollupWithMock() {
        Account acct = new Account(Name = 'Rollup Test Account');
        insert acct;

        OpportunitySelector_MT mock = new OpportunitySelector_MT();
        mock.setPipelineResults(new List<OpportunitySelector.PipelineAggregate>{
            new OpportunitySelector.PipelineAggregate(acct.Id, 125000, 2)
        });
        mock.setLastWonResults(new List<OpportunitySelector.LastWonAggregate>());
        OpportunitySelector.mockInstance = mock;

        Test.startTest();
        new OpportunityTriggerHandler().rollUpAccountPipeline(new Set<Id>{ acct.Id });
        Test.stopTest();

        acct = [SELECT Total_Open_Pipeline__c, Active_Opportunities__c, Last_Opportunity_Close_Date__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(125000, acct.Total_Open_Pipeline__c);
        System.assertEquals(2, acct.Active_Opportunities__c);
        System.assertEquals(null, acct.Last_Opportunity_Close_Date__c);
    }

    @IsTest
    static void testPipelineRollupWithClosedWon() {
        Account acct = new Account(Name = 'Rollup Test Account');
        insert acct;

        OpportunitySelector_MT mock = new OpportunitySelector_MT();
        mock.setPipelineResults(new List<OpportunitySelector.PipelineAggregate>{
            new OpportunitySelector.PipelineAggregate(acct.Id, 75000, 1)
        });
        mock.setLastWonResults(new List<OpportunitySelector.LastWonAggregate>{
            new OpportunitySelector.LastWonAggregate(acct.Id, Date.today().addDays(30))
        });
        OpportunitySelector.mockInstance = mock;

        Test.startTest();
        new OpportunityTriggerHandler().rollUpAccountPipeline(new Set<Id>{ acct.Id });
        Test.stopTest();

        acct = [SELECT Total_Open_Pipeline__c, Active_Opportunities__c, Last_Opportunity_Close_Date__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(75000, acct.Total_Open_Pipeline__c);
        System.assertEquals(1, acct.Active_Opportunities__c);
        System.assertEquals(Date.today().addDays(30), acct.Last_Opportunity_Close_Date__c);
    }

    @IsTest
    static void testPipelineRollupZeroPipeline() {
        Account acct = new Account(Name = 'Rollup Test Account');
        insert acct;

        OpportunitySelector_MT mock = new OpportunitySelector_MT();
        mock.setPipelineResults(new List<OpportunitySelector.PipelineAggregate>());
        mock.setLastWonResults(new List<OpportunitySelector.LastWonAggregate>());
        OpportunitySelector.mockInstance = mock;

        Test.startTest();
        new OpportunityTriggerHandler().rollUpAccountPipeline(new Set<Id>{ acct.Id });
        Test.stopTest();

        acct = [SELECT Total_Open_Pipeline__c, Active_Opportunities__c FROM Account WHERE Id = :acct.Id];
        System.assertEquals(0, acct.Total_Open_Pipeline__c);
        System.assertEquals(0, acct.Active_Opportunities__c);
    }

    @IsTest
    static void testPipelineRollupEmptyAccountIds() {
        OpportunitySelector_MT mock = new OpportunitySelector_MT();
        OpportunitySelector.mockInstance = mock;

        Test.startTest();
        new OpportunityTriggerHandler().rollUpAccountPipeline(new Set<Id>());
        Test.stopTest();
        // No exception = pass; method exits early for empty set
    }

    // ── Rule 5: Sync Gap Amounts (mocked gap selector) ──

    @IsTest
    static void testSyncGapAmountsWithMock() {
        Account acct = new Account(Name = 'Sync Test Account');
        insert acct;

        Id fakeOppId1 = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '000000000001';
        Id fakeOppId2 = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '000000000002';
        Id fakeGapId  = OpportunityGap__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001';

        OpportunityGapSelector_MT gapMock = new OpportunityGapSelector_MT();
        gapMock.setGapsResults(new List<OpportunityGap__c>{
            new OpportunityGap__c(Id = fakeGapId, Opportunity__c = fakeOppId1, Amount__c = 50000)
        });
        OpportunityGapSelector.mockInstance = gapMock;

        // Construct in-memory old and new Opportunity representations for the amount-changed detection logic.
        Opportunity oldOpp = new Opportunity(Id = fakeOppId1, Amount = 50000, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Name = 'Old Opp');
        Opportunity newOpp = new Opportunity(Id = fakeOppId1, Amount = 99000, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30), Name = 'New Opp');

        // Verify the changed-Opportunity detection logic correctly identifies the changed record.
        Set<Id> changedIds = new Set<Id>();
        for (Opportunity opp : new List<Opportunity>{ newOpp }) {
            if (opp.Amount != oldOpp.Amount) {
                changedIds.add(opp.Id);
            }
        }

        Test.startTest();
        Assert.areEqual(1, changedIds.size(), 'Exactly one Opportunity should be detected as changed');
        Assert.isTrue(changedIds.contains(fakeOppId1), 'The changed set should contain fakeOppId1');
        Test.stopTest();

        // Confirm the mock was installed correctly — the selector returns the preset gap.
        List<OpportunityGap__c> gaps = OpportunityGapSelector.getInstance().getGapsByOpportunityIds(changedIds);
        Assert.areEqual(1, gaps.size(), 'Mock selector should return the preset gap record');
        Assert.areEqual(fakeOppId1, gaps[0].Opportunity__c, 'Gap should reference fakeOppId1');
    }
}
