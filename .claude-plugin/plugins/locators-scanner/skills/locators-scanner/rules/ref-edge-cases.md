---
title: Edge case handling guidance for locator extraction
impact: MEDIUM
tags:
  - locators
  - edge-cases
  - dynamic-ids
  - shadow-dom
  - iframes
---

## Edge Cases & Guidance

- **No test attributes found**: This is common. Warn the user and explain that the page would benefit from dedicated test attributes. Still produce the best available locators.
- **Dynamic IDs** (e.g., `id="react-select-123"`): Detect patterns like IDs with numbers/hashes and mark them as unreliable. Skip them in favor of other attributes.
- **Duplicate text**: If multiple buttons say "Submit", use parent context or index to disambiguate. Note this in comments.
- **Shadow DOM**: `web_fetch` won't capture Shadow DOM content. Note this limitation and suggest the user use a browser-based extraction if needed.
- **Iframes**: Note that iframe content won't be fetched by default. Mention it in the summary.
- **Very large pages**: If the page has 200+ elements, group by section/region and consider asking the user if they want to focus on a specific part of the page.
- **SVG elements**: Inline SVG content is skipped by default. Extract an SVG element only if it has `role`, `tabindex`, `onclick`, or `aria-label` (i.e., it is interactive).
