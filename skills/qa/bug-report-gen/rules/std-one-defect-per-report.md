---
title: One defect per report
impact: HIGH
tags:
  - bug-report
  - structure
  - standards
---

## Rule

Each bug report documents exactly **one observable failure**. Compound defects — where a single report describes multiple distinct failures — must be split into separate reports.

## Incorrect

```json
{
  "title": "[Checkout] Multiple issues with order submission",
  "description": "The cart total is wrong AND the confirmation email is not sent AND the order history page crashes."
}
```

- Error: Three separate failures documented in a single report.
- Cause: Reporter captured everything they found in one sitting and filed it together.

## Correct

```json
{ "title": "[Cart] Order total recalculates after payment confirmation" }
{ "title": "[Notifications] Confirmation email not sent after successful order" }
{ "title": "[Order History] Page crashes when navigating to submitted orders" }
```

- Each report isolates one failure, making it independently assignable, reproducible, and closable.

## Why it matters

Compound defect reports cannot be closed until every issue is fixed, blocking metrics and triage. Splitting defects enables parallel assignment to different team members, accurate severity/priority per issue, and clean status tracking.
