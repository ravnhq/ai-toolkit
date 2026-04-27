---
title: Report bugs to the configured issue tracker
impact: HIGH
tags:
  - qa
  - bug-reporting
  - issue-tracker
  - linear
  - github
---

## Rule

When a bug is found, always report it inline in the test output AND file it in the configured issue tracker. Read `.qa/config.yml` to determine the provider. If no issue tracker is configured, include all bug details in the final output for the orchestrator to collect.

## Incorrect

```
### Test: SQL injection in name field
**Result:** BUG
**Notes:** Got a 500 error
```

- Error: Bug report lacks the exact input sent, the full response, severity, and was not filed in the issue tracker.
- Cause: Agent reported a vague failure without following the structured bug reporting format.

## Correct

```
### Test: SQL injection in name field
**Intent:** Test input validation against SQL injection
**Input:** POST /api/users {"name": "'; DROP TABLE users;--"}
**Response:** 500 Internal Server Error {"error": "PSQLException: ..."}
**State after:** Users table intact (checked via GET /api/users)
**Result:** BUG
**Severity:** HIGH
**Repro steps:**
1. POST /api/users with name="'; DROP TABLE users;--"
2. Observe 500 error with stack trace

Filed: LIN-789 [QA-ChaosMonkey] POST /api/users returns 500 on SQL injection input
```

- Full reproduction details with exact input, response, and severity.
- Filed in issue tracker with the `[QA-ChaosMonkey]` prefix for traceability.

## Provider-Specific Filing

**Linear** (`issue_tracker.detected: linear`):
- Title: `[QA-ChaosMonkey] <description>`
- Labels: `["Bug", "QA"]` (add `"Security"` for auth/injection bugs)
- Priority: BLOCKER=1, HIGH=2, MEDIUM=3, LOW=4

**GitHub** (`issue_tracker.detected: github`):
- Title: `[QA-ChaosMonkey] <description>`
- Labels: `["bug", "qa"]` (add `"security"` for auth bugs)

**None**: Include ALL details in output — orchestrator collects them into the QA summary.

## BLOCKER — Signal Early Termination

If a bug is BLOCKER severity and prevents further testing (e.g., auth endpoint down, DB unreachable, 500 on every request), stop testing and emit this signal before your final output so the orchestrator can surface it separately:

```
STOPPED_EARLY: true
BLOCKER: <short description> — <N> tests skipped
```

Do not continue testing other endpoints when a BLOCKER makes results unreliable.

## Why it matters

Vague bug reports waste engineer time on reproduction. Unfiled bugs get forgotten. For adversarial testing especially, the exact payload that triggered the bug IS the reproduction step — without it, the bug cannot be fixed.
