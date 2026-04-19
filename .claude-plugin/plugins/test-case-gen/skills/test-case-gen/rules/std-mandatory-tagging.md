---
title: Every test case must include all mandatory tags
impact: HIGH
tags:
  - test-case
  - tagging
  - metadata
  - standards
---

## Rule

Every test case must include four mandatory tags: `risk_level`, `priority`, `type`, and `automation_candidate`. A test case missing any of these cannot be properly filtered, prioritized, or planned for automation.

## Incorrect

```json
{
  "id": "TC-042",
  "title": "User can reset password via email link",
  "steps": ["..."],
  "expected_result": "Password is reset and user can log in with new credentials."
}
```

- Error: Missing `risk_level`, `priority`, `type`, and `automation_candidate`.
- Cause: Test case created without completing the metadata fields.

## Correct

```json
{
  "id": "TC-042",
  "title": "User can reset password via email link",
  "risk_level": "High",
  "priority": "P2",
  "type": "Functional",
  "automation_candidate": true,
  "steps": ["..."],
  "expected_result": "Password is reset and user can log in with new credentials."
}
```

- All four mandatory tags are present with valid values.
- The test case can be filtered by risk, prioritized for execution, categorized by type, and earmarked for automation.

## Why it matters

Missing tags break suite management: risk-based execution ordering fails without `risk_level`, automation planning cannot work without `automation_candidate`, and reporting by test type requires `type`. Consistent tagging is the foundation of a queryable, manageable test suite.
