---
name: Salesforce Org Details
description: Instance URL, org type, auth pattern, and key testing observations for the default SF CLI org
type: project
---

Instance URL: https://brave-goat-mkb88c-dev-ed.trailblaze.my.salesforce.com (Lightning: trailblaze.lightning.force.com)
Org type: Developer Edition
Alias: PreSalesDemo
Username: saman.attar@brave-goat-mkb88c.com

**Auth pattern:** frontdoor.jsp with sid token works reliably using `domcontentloaded` wait strategy. Do NOT use `networkidle` — Salesforce Lightning keeps persistent connections and it times out.

**Lightning load pattern:** After frontdoor.jsp redirect, wait for `.auraLoadingBox` hidden, then `.slds-spinner_container` hidden, then `records-record-layout-item` or `.slds-form` attached. Add a 3-5 second buffer after.

**Shadow DOM note:** Standard `querySelectorAll` on field labels returns empty due to Lightning Web Components shadow DOM. Use `page.evaluate(() => document.body.innerText)` for full text extraction — this IS accessible and reliable for field presence checks.

**Why:** Discovered during Potato__c/Potato_Date__c field validation test on 2026-03-25.
**How to apply:** Always use body.innerText for field label presence checks in Salesforce Lightning UI tests.
