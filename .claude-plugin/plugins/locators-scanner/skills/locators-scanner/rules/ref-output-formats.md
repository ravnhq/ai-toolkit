---
title: Output format rules — confidence levels, naming, and summary fields
impact: HIGH
tags:
  - locators
  - output
  - confidence
  - naming
  - json
---

## Confidence Levels

Assign a confidence level to every locator in the JSON map:

| Level | Criteria |
|---|---|
| **high** | Locator uses a dedicated test attribute (`data-testid`, `data-cy`) or a stable accessibility attribute (`role` + accessible name, `aria-label`, label association via `getByLabel`) |
| **medium** | Locator uses `id`, `name`, `placeholder`, or visible text |
| **low** | Locator uses CSS class, tag position, or structural selectors |

## Output File Naming

| File | Pattern | Example |
|---|---|---|
| POM code file | `{PageName}Page.{ts\|js}` | `LoginPage.ts` |
| JSON locator map | `{pageName}-locators.json` | `login-locators.json` |

Save both files to `/mnt/user-data/outputs/`.

## Required Summary Fields

After delivering outputs, provide a brief summary containing:

- **Total elements found** — count of all extracted elements
- **Category breakdown** — count per category (interactive, form, content, structural)
- **Confidence distribution** — count of high / medium / low locators
- **Warnings** — e.g., "12 elements lack test attributes — consider asking developers to add `data-testid`"
