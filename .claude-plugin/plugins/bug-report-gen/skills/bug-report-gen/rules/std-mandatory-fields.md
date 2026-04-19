---
title: All mandatory fields must be populated
impact: HIGH
tags:
  - bug-report
  - completeness
  - standards
---

## Rule

Every bug report must include all six mandatory fields: `severity`, `priority`, `environment`, `affected_component`, `reporter`, and `status`. A report missing any of these fields is incomplete and cannot be triaged.

## Incorrect

```json
{
  "title": "[Login] Authentication fails for SSO users",
  "description": "SSO users cannot log in after the latest deploy.",
  "actual": "SSO login returns a 401 error.",
  "expected": "SSO users are authenticated and redirected to the dashboard."
}
```

- Error: Missing `severity`, `priority`, `environment`, `affected_component`, `reporter`, and `status`.
- Cause: Reporter provided the description without completing the structured fields.

## Correct

```json
{
  "title": "[Auth] SSO login returns 401 after deploy v2.4.1",
  "severity": "Critical",
  "priority": "P1",
  "environment": "Staging",
  "affected_component": "Authentication / SSO",
  "reporter": "qa-engineer@ravn.co",
  "status": "New",
  "actual": "SSO login returns a 401 Unauthorized error.",
  "expected": "SSO users are authenticated and redirected to /dashboard."
}
```

- All six mandatory fields are populated with valid values.
- The report can be triaged, assigned, and tracked without follow-up questions.

## Why it matters

Incomplete reports block triage. Without `severity` and `priority`, engineers cannot determine urgency. Without `environment`, they cannot reproduce. Without `affected_component`, routing to the right team is guesswork.
