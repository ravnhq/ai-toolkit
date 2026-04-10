---
title: Always state both actual and expected behavior
impact: CRITICAL
tags:
  - bug-report
  - clarity
  - standards
---

## Rule

Every bug report must include an **actual** field (what the system did) and an **expected** field (what the spec or common sense requires). Both must be present, specific, and clearly differentiated.

## Incorrect

```json
{
  "actual": "The order didn't work",
  "expected": "It should work"
}
```

- Error: "Didn't work" and "should work" are not specific. The reader cannot determine what failure occurred or what the correct behavior should be.
- Cause: Reporter described the emotional experience of the failure rather than the technical outcome.

## Correct

```json
{
  "actual": "After clicking 'Place Order', the page returns HTTP 500 and no order record is created in the database.",
  "expected": "The system creates an order record, returns HTTP 200 with the order ID, and sends a confirmation email to the user."
}
```

- `actual` describes the exact failure: the HTTP status code and the missing database record.
- `expected` describes the complete correct behavior with measurable outcomes.

## Why it matters

Without a clear expected behavior, engineers cannot determine if their fix is correct. Without a clear actual behavior, they cannot reproduce or diagnose the failure. Both fields are required for a bug report to be actionable.
