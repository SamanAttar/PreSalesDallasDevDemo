---
name: Org Configuration Patterns
description: Naming conventions, field metadata patterns, profile FLS structure, and layout conventions used in this Salesforce org
type: project
---

Key patterns observed in this org's Salesforce metadata:

**Field Metadata Conventions**
- All custom fields live under `force-app/main/sales/objects/<Object>/fields/`
- File naming: `Field_API_Name__c.field-meta.xml`
- Every field includes `<description>`, `<inlineHelpText>`, `<trackFeedHistory>false</trackFeedHistory>`, `<trackTrending>false</trackTrending>`
- Checkbox fields always explicitly set `<defaultValue>` and `<required>false`

**Page Layouts**
- Layouts live under `force-app/main/sales/layouts/`
- Standard naming: `<Object>-<Layout Name>.layout-meta.xml`
- Two-column sections use `<style>TwoColumnsTopToBottom</style>`
- Custom sections use `<customLabel>true</customLabel>` and have both `detailHeading` and `editHeading` set to `true`

**Profile / FLS**
- Only one profile tracked in source: `Admin` at `force-app/main/default/profiles/Admin.profile-meta.xml`
- All custom Opportunity and Account fields grant Admin full Read + Edit (`<editable>true</editable><readable>true</readable>`)
- FLS is maintained directly in the Admin profile file (no permission sets observed yet)

**Custom Objects / Fields in Use on Opportunity**
- `Deal_Size_Category__c` (Picklist, restricted, local value set)
- `Discount_Percent__c` (Number/Percent)
- `Requires_VP_Approval__c` (Checkbox)
- `Risk_Flag__c` (Checkbox or formula)

**Product Gap Feature Objects (added 2026-03-25)**
- `ProductGap__c`: sharingModel ReadWrite, text name field, reports/search enabled
  - Fields: `Description__c` (LongTextArea), `Category__c` (Picklist), `Status__c` (Picklist, default: New), `Total_Opportunity_Amount__c` (Summary SUM), `Opportunity_Count__c` (Summary COUNT)
- `OpportunityGap__c`: sharingModel ControlledByParent (master-detail child of ProductGap__c), AutoNumber name OG-{000000}
  - Fields: `ProductGap__c` (MasterDetail, relationshipName: OpportunityGaps), `Opportunity__c` (Lookup to Opportunity, relationshipName: OpportunityGaps), `Amount__c` (Currency)
- The rollup fields on ProductGap__c reference `OpportunityGap__c.ProductGap__c` as the summaryForeignKey
- The Opportunity page layout now includes a `relatedLists` entry for `OpportunityGap__r` and a `quickActionList` entry for `productGapQuickAction`

**Permission Sets**
- `Solution_Engineers`: grants Create/Read/Edit + ViewAll on ProductGap__c and OpportunityGap__c; no Delete, no ModifyAll
  - Located at `force-app/main/sales/permissionsets/Solution_Engineers.permissionset-meta.xml`

**Report Types**
- `Opportunities_with_Product_Gaps`: outer-join chain Opportunity → OpportunityGap__c (via OpportunityGaps relationship) → ProductGap__c (via ProductGap__r)
  - Located at `force-app/main/sales/reportTypes/Opportunities_with_Product_Gaps.reportType-meta.xml`

**Why:** Understanding these patterns avoids inconsistent metadata that would cause deployment failures or diff noise.
**How to apply:** Match these conventions exactly when creating new fields, layouts, or profile entries in this org.
