---
title: High and Critical severity reports require evidence
impact: HIGH
tags:
  - bug-report
  - evidence
  - severity
  - standards
---

## Rule

Bug reports with `severity: High` or `severity: Critical` must include at least one attachment reference: a screenshot, video recording, log snippet, or HAR file. Reports at these severity levels without evidence are incomplete.

## Incorrect

```json
{
  "title": "[Payments] Checkout fails for all users",
  "severity": "Critical",
  "priority": "P1",
  "attachments": []
}
```

- Error: A Critical severity report with no evidence attachments.
- Cause: Reporter filed the report without capturing supporting artifacts.

## Correct

```json
{
  "title": "[Payments] Checkout fails for all users",
  "severity": "Critical",
  "priority": "P1",
  "attachments": [
    {
      "type": "log",
      "description": "Server error log showing 500 response from /api/orders",
      "reference": "logs/checkout-error-2024-01-15.txt"
    },
    {
      "type": "screenshot",
      "description": "Browser console showing failed network request",
      "reference": "screenshots/checkout-500-error.png"
    }
  ]
}
```

- Two evidence artifacts are referenced with type, description, and file location.
- Engineers can immediately inspect the failure without needing to reproduce it first.

## Why it matters

High and Critical bugs often block releases. Without evidence, engineers may dispute the defect, spend time reproducing it, or deprioritize it. Evidence shortens the debug cycle and prevents "cannot reproduce" closures for legitimate critical failures.
