public with sharing class ProductGapQuickActionController {

    @AuraEnabled
    public static Id createAndLinkGap(
        Id opportunityId,
        String name,
        String description,
        String category,
        String status
    ) {
        try {
            ProductGap__c gap = new ProductGap__c(
                Name = name,
                Description__c = description,
                Category__c = category,
                Status__c = status
            );
            insert gap;

            OpportunityGap__c link = new OpportunityGap__c(
                ProductGap__c = gap.Id,
                Opportunity__c = opportunityId
            );
            insert link;

            return link.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ProductGap__c> searchExistingGaps(String searchTerm) {
        String likePattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        return [
            SELECT Id, Name, Description__c, Category__c, Status__c
            FROM ProductGap__c
            WHERE Name LIKE :likePattern
               OR Description__c LIKE :likePattern
            ORDER BY Name
            LIMIT 20
        ];
    }

    @AuraEnabled
    public static Id linkExistingGap(Id opportunityId, Id productGapId) {
        try {
            OpportunityGap__c link = new OpportunityGap__c(
                ProductGap__c = productGapId,
                Opportunity__c = opportunityId
            );
            insert link;
            return link.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
