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

**Why:** Understanding these patterns avoids inconsistent metadata that would cause deployment failures or diff noise.
**How to apply:** Match these conventions exactly when creating new fields, layouts, or profile entries in this org.
