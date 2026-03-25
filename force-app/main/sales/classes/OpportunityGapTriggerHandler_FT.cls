@IsTest
private class OpportunityGapTriggerHandler_FT {

    @TestSetup
    static void setup() {
        Account acct = new Account(Name = 'Gap FT Account');
        insert acct;

        Opportunity opp1 = new Opportunity(
            AccountId = acct.Id,
            Name = 'Gap FT Opp 1',
            StageName = 'Prospecting',
            Amount = 50000,
            CloseDate = Date.today().addDays(30)
        );
        Opportunity opp2 = new Opportunity(
            AccountId = acct.Id,
            Name = 'Gap FT Opp 2',
            StageName = 'Prospecting',
            Amount = 75000,
            CloseDate = Date.today().addDays(30)
        );
        insert new List<Opportunity>{ opp1, opp2 };
    }

    static Opportunity getOpp(String name) {
        return [SELECT Id, Amount FROM Opportunity WHERE Name = :name LIMIT 1];
    }

    static ProductGap__c createProductGap(String gapName) {
        return new ProductGap__c(
            Name = gapName,
            Status__c = 'New',
            Category__c = 'Reporting'
        );
    }

    @IsTest
    static void testInsertCopiesAmount() {
        Opportunity opp1 = getOpp('Gap FT Opp 1');

        ProductGap__c pg = createProductGap('FT Gap Insert');
        insert pg;

        Test.startTest();
        OpportunityGap__c oppGap = new OpportunityGap__c(
            ProductGap__c = pg.Id,
            Opportunity__c = opp1.Id
        );
        insert oppGap;
        Test.stopTest();

        oppGap = [SELECT Amount__c FROM OpportunityGap__c WHERE Id = :oppGap.Id];
        Assert.areEqual(50000, oppGap.Amount__c, 'Amount__c should be copied from the linked Opportunity on insert');
    }

    @IsTest
    static void testReparentResyncAmount() {
        Opportunity opp1 = getOpp('Gap FT Opp 1');
        Opportunity opp2 = getOpp('Gap FT Opp 2');

        ProductGap__c pg = createProductGap('FT Gap Reparent');
        insert pg;

        OpportunityGap__c oppGap = new OpportunityGap__c(
            ProductGap__c = pg.Id,
            Opportunity__c = opp1.Id
        );
        insert oppGap;

        oppGap = [SELECT Amount__c FROM OpportunityGap__c WHERE Id = :oppGap.Id];
        Assert.areEqual(50000, oppGap.Amount__c, 'Amount__c should initially match opp1 Amount');

        Test.startTest();
        oppGap.Opportunity__c = opp2.Id;
        update oppGap;
        Test.stopTest();

        oppGap = [SELECT Amount__c FROM OpportunityGap__c WHERE Id = :oppGap.Id];
        Assert.areEqual(75000, oppGap.Amount__c, 'Amount__c should re-sync to opp2 Amount after reparent');
    }

    @IsTest
    static void testBulkInsert() {
        Opportunity opp1 = getOpp('Gap FT Opp 1');

        ProductGap__c pg = createProductGap('FT Gap Bulk');
        insert pg;

        List<OpportunityGap__c> gaps = new List<OpportunityGap__c>();
        for (Integer i = 0; i < 200; i++) {
            gaps.add(new OpportunityGap__c(
                ProductGap__c = pg.Id,
                Opportunity__c = opp1.Id
            ));
        }

        Test.startTest();
        insert gaps;
        Test.stopTest();

        List<OpportunityGap__c> inserted = [
            SELECT Amount__c FROM OpportunityGap__c
            WHERE ProductGap__c = :pg.Id
        ];
        Assert.areEqual(200, inserted.size(), 'All 200 gap records should be inserted');
        for (OpportunityGap__c gap : inserted) {
            Assert.areEqual(50000, gap.Amount__c, 'Every gap Amount__c should equal opp1 Amount of 50000');
        }
    }
}
