---
title: Expected results must be specific and verifiable
impact: CRITICAL
tags:
  - test-case
  - expected-results
  - standards
---

## Rule

Expected results must be **specific and verifiable** — a tester can determine pass/fail without interpretation. Vague statements like "the system works correctly" or "the page loads" are not acceptable.

## Incorrect

```json
{
  "expected_result": "The checkout process works correctly and the order is placed."
}
```

- Error: "Works correctly" is not measurable. The tester cannot determine a pass/fail condition.
- Cause: Expected result written from the tester's intent rather than the system's observable output.

## Correct

```json
{
  "expected_result": "The system returns HTTP 200, creates an order record with status 'pending', and sends a confirmation email to the user's registered address within 30 seconds."
}
```

- Measurable outcomes: HTTP status code, database record creation, email delivery, timing.
- Any tester can independently determine pass or fail without interpretation.

## Why it matters

Vague expected results make test execution subjective — two testers may reach different verdicts on the same behavior. Specific, verifiable expected results enable consistent execution, unambiguous automation assertions, and defensible pass/fail determinations in client-facing reports.
