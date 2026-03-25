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
}
