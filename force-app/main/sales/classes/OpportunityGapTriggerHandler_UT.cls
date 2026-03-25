@IsTest
private class OpportunityGapTriggerHandler_UT {

    // ── Helpers ──

    static Id fakeOppId(Integer suffix) {
        return (Id)(Opportunity.SObjectType.getDescribe().getKeyPrefix()
            + String.valueOf(suffix).leftPad(12, '0'));
    }

    static Id fakeGapId(Integer suffix) {
        return (Id)(OpportunityGap__c.SObjectType.getDescribe().getKeyPrefix()
            + String.valueOf(suffix).leftPad(12, '0'));
    }

    // ── copyAmountsOnInsert ──

    @IsTest
    static void testCopyAmountsOnInsertBulk() {
        // Need real Opportunities so the handler can query their Amount via SOQL.
        Account acct = new Account(Name = 'UT Gap Account');
        insert acct;

        Opportunity opp1 = new Opportunity(
            AccountId = acct.Id,
            Name = 'UT Opp 1',
            StageName = 'Prospecting',
            Amount = 30000,
            CloseDate = Date.today().addDays(30)
        );
        Opportunity opp2 = new Opportunity(
            AccountId = acct.Id,
            Name = 'UT Opp 2',
            StageName = 'Prospecting',
            Amount = 80000,
            CloseDate = Date.today().addDays(30)
        );
        insert new List<Opportunity>{ opp1, opp2 };

        ProductGap__c pg = new ProductGap__c(
            Name = 'UT Gap',
            Status__c = 'New',
            Category__c = 'Reporting'
        );
        insert pg;

        // Insert two gaps linked to different opportunities and call the @TestVisible method directly.
        OpportunityGap__c gap1 = new OpportunityGap__c(
            ProductGap__c = pg.Id,
            Opportunity__c = opp1.Id
        );
        OpportunityGap__c gap2 = new OpportunityGap__c(
            ProductGap__c = pg.Id,
            Opportunity__c = opp2.Id
        );
        insert new List<OpportunityGap__c>{ gap1, gap2 };

        // Re-blank amounts so we can test the method in isolation without trigger side effects.
        update new List<OpportunityGap__c>{
            new OpportunityGap__c(Id = gap1.Id, Amount__c = null),
            new OpportunityGap__c(Id = gap2.Id, Amount__c = null)
        };

        gap1 = new OpportunityGap__c(Id = gap1.Id, Opportunity__c = opp1.Id);
        gap2 = new OpportunityGap__c(Id = gap2.Id, Opportunity__c = opp2.Id);

        OpportunityGapTriggerHandler handler = new OpportunityGapTriggerHandler();

        Test.startTest();
        handler.copyAmountsOnInsert(new List<OpportunityGap__c>{ gap1, gap2 });
        Test.stopTest();

        List<OpportunityGap__c> results = [
            SELECT Id, Amount__c, Opportunity__c FROM OpportunityGap__c
            WHERE Id IN (:gap1.Id, :gap2.Id)
        ];
        Map<Id, OpportunityGap__c> resultMap = new Map<Id, OpportunityGap__c>();
        for (OpportunityGap__c g : results) {
            resultMap.put(g.Id, g);
        }

        Assert.areEqual(30000, resultMap.get(gap1.Id).Amount__c,
            'gap1 Amount__c should be copied from opp1 (30000)');
        Assert.areEqual(80000, resultMap.get(gap2.Id).Amount__c,
            'gap2 Amount__c should be copied from opp2 (80000)');
    }

    // ── resyncAmountsOnReparent ──

    @IsTest
    static void testResyncOnReparent() {
        // Verify that only records where Opportunity__c changed are processed.
        Account acct = new Account(Name = 'UT Reparent Account');
        insert acct;

        Opportunity opp1 = new Opportunity(
            AccountId = acct.Id,
            Name = 'UT Reparent Opp 1',
            StageName = 'Prospecting',
            Amount = 20000,
            CloseDate = Date.today().addDays(30)
        );
        Opportunity opp2 = new Opportunity(
            AccountId = acct.Id,
            Name = 'UT Reparent Opp 2',
            StageName = 'Prospecting',
            Amount = 60000,
            CloseDate = Date.today().addDays(30)
        );
        insert new List<Opportunity>{ opp1, opp2 };

        ProductGap__c pg = new ProductGap__c(
            Name = 'UT Reparent Gap',
            Status__c = 'New',
            Category__c = 'Reporting'
        );
        insert pg;

        OpportunityGap__c gapChanged = new OpportunityGap__c(
            ProductGap__c = pg.Id,
            Opportunity__c = opp1.Id
        );
        OpportunityGap__c gapUnchanged = new OpportunityGap__c(
            ProductGap__c = pg.Id,
            Opportunity__c = opp1.Id
        );
        insert new List<OpportunityGap__c>{ gapChanged, gapUnchanged };

        // Clear amounts to isolate the method under test.
        update new List<OpportunityGap__c>{
            new OpportunityGap__c(Id = gapChanged.Id, Amount__c = null),
            new OpportunityGap__c(Id = gapUnchanged.Id, Amount__c = null)
        };

        // Simulate: gapChanged is reparented to opp2; gapUnchanged stays on opp1.
        OpportunityGap__c newGapChanged  = new OpportunityGap__c(Id = gapChanged.Id,   Opportunity__c = opp2.Id);
        OpportunityGap__c newGapUnchanged = new OpportunityGap__c(Id = gapUnchanged.Id, Opportunity__c = opp1.Id);

        Map<Id, OpportunityGap__c> oldMap = new Map<Id, OpportunityGap__c>{
            gapChanged.Id   => new OpportunityGap__c(Id = gapChanged.Id,   Opportunity__c = opp1.Id),
            gapUnchanged.Id => new OpportunityGap__c(Id = gapUnchanged.Id, Opportunity__c = opp1.Id)
        };

        OpportunityGapTriggerHandler handler = new OpportunityGapTriggerHandler();

        Test.startTest();
        handler.resyncAmountsOnReparent(
            new List<OpportunityGap__c>{ newGapChanged, newGapUnchanged },
            oldMap
        );
        Test.stopTest();

        List<OpportunityGap__c> results = [
            SELECT Id, Amount__c FROM OpportunityGap__c
            WHERE Id IN (:gapChanged.Id, :gapUnchanged.Id)
        ];
        Map<Id, OpportunityGap__c> resultMap = new Map<Id, OpportunityGap__c>();
        for (OpportunityGap__c g : results) {
            resultMap.put(g.Id, g);
        }

        Assert.areEqual(60000, resultMap.get(gapChanged.Id).Amount__c,
            'gapChanged should have Amount__c from the new opp2 (60000) after reparent');
        Assert.isNull(resultMap.get(gapUnchanged.Id).Amount__c,
            'gapUnchanged Opportunity__c did not change, so Amount__c should remain null');
    }
}
