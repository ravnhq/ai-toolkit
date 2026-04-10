---
title: Each test case validates exactly one observable outcome
impact: CRITICAL
tags:
  - test-case
  - structure
  - standards
---

## Rule

Every test case must have **one objective** — it validates exactly one observable outcome. Test cases that assert multiple behaviors in a single case must be split.

## Incorrect

```json
{
  "title": "Login and verify dashboard and check notification badge",
  "steps": ["Log in", "Verify dashboard loads", "Check notification count", "Verify profile menu"],
  "expected_result": "Dashboard loads, notification badge shows 3, profile menu is accessible"
}
```

- Error: The test case validates three separate behaviors: dashboard loading, notification count, and profile menu access.
- Cause: Tester combined a user journey into a single test for convenience.

## Correct

```json
{ "title": "Authenticated user is redirected to the dashboard after login", "objective": "Verify post-login navigation" }
{ "title": "Notification badge shows unread count for authenticated user", "objective": "Verify notification count display" }
{ "title": "Profile menu is accessible from the dashboard", "objective": "Verify profile menu availability" }
```

- Each test validates exactly one observable outcome.
- Failures are immediately attributable to a specific behavior without ambiguity.

## Why it matters

Multi-objective test cases make failure diagnosis slow: a single failure tells you something is broken but not which behavior. Single-objective tests pinpoint failures precisely, support independent automation, and produce cleaner pass/fail metrics.
