---
title: Field definitions — risk, priority, type, automation, platform
impact: HIGH
tags:
  - schema
  - fields
  - reference
---

## Rule

Every test case must use the exact allowed values for classification fields. No synonyms, no custom values.

## Field Definitions

**Risk Level** — `High`: blocks core flow, data loss, or payment/auth (any test touching payments, authentication, or authorization MUST be `High`) · `Medium`: degrades UX, workaround exists · `Low`: minor cosmetic or edge case

**Priority** — `P1`: smoke suite, run before any release · `P2`: regression suite, before sprint sign-off · `P3`: full regression cycles · `P4`: run when time permits

**Type** — ONLY these values are valid: `Smoke` · `Functional` · `Regression` · `Integration` · `E2E` · `API` · `UI` · `Security` · `Performance` · `Exploratory`. Never use unlisted values like "Edge Case", "Negative", or "Boundary".

**Automation Candidate** — `true` if stable, deterministic, and valuable to automate; `false` for exploratory or context-dependent tests

**Platform** — controls vocabulary and element naming; see `std-platform-terminology.md`.

## Incorrect

```json
{
  "risk_level": "Critical",
  "priority": "Must-have",
  "type": "Edge Case",
  "automation_candidate": "maybe"
}
```

- Error: All four fields use values outside the allowed set.
- Cause: Writer used informal labels instead of the standard vocabulary.

## Correct

```json
{
  "risk_level": "High",
  "priority": "P1",
  "type": "Functional",
  "automation_candidate": true
}
```

- Every field uses an exact allowed value from the definitions above.

## Why it matters

Non-standard field values break test management tool filters, dashboards, and automation pipelines. Consistent classification enables reliable priority sorting, risk reporting, and suite selection across teams.
