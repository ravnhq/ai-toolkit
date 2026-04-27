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
### Flow 3 — Create Order
**Result:** FAIL
**Notes:** Something went wrong with the order
```

- Error: Bug report lacks reproduction steps, severity, expected/actual behavior, and was not filed in the issue tracker.
- Cause: Agent reported a vague failure without following the structured bug reporting format.

## Correct

```
### Flow 3 — Create Order
**Result:** FAIL
**Severity:** HIGH
**Steps to reproduce:**
1. Navigate to /orders/new
2. Fill form with valid data
3. Click "Submit"
**Expected:** Order created, redirect to /orders/{id}
**Actual:** 500 error, stuck on form page
**Screenshot:** .qa/screenshots/flow-3-fail.png

Filed: LIN-456 [QA-HappyPath] Order creation returns 500 on valid input
```

- Full reproduction details, severity, expected vs actual, and issue tracker ticket filed.
- Another engineer can reproduce the bug from this report alone.

## Provider-Specific Filing

**Linear** (`issue_tracker.detected: linear`):
```
mcp__linear__save_issue:
  title: "[QA-AgentName] <short description>"
  teamId: <from .qa/config.yml>
  labelNames: <from .qa/config.yml>
  priority: BLOCKER=1, HIGH=2, MEDIUM=3, LOW=4
```

**GitHub** (`issue_tracker.detected: github`):
```
mcp__github__create_issue:
  title: "[QA-AgentName] <short description>"
  repo: <from .qa/config.yml>
  labels: <from .qa/config.yml>
```

**None** (`issue_tracker.detected: none`):
Skip filing. Include ALL details in output — the orchestrator collects them into the QA summary report.

## BLOCKER — Signal Early Termination

If a bug is BLOCKER severity and prevents further flows from running (e.g., login broken, app unreachable, crash on every page), stop testing and emit this signal before your final output so the orchestrator can surface it separately:

```
STOPPED_EARLY: true
BLOCKER: <short description> — <N> flows skipped
```

Do not continue testing remaining flows when a BLOCKER makes results unreliable.

## Why it matters

Vague bug reports waste engineer time on reproduction. Unfiled bugs get forgotten. Structured reports with full reproduction details, severity, and issue tracker integration ensure bugs are triaged and fixed systematically.
