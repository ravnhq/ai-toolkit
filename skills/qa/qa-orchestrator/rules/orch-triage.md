---
title: Triage bugs by severity and offer fix options
impact: HIGH
tags:
  - qa
  - orchestration
  - triage
  - bug-fix
---

## Rule

After collecting QA results, partition bugs into **blocking** (BLOCKER severity that stopped an agent early) and **non-blocking** (HIGH/MEDIUM/LOW found while testing continued). Surface blocking bugs with a dedicated prompt before running standard triage. Never auto-fix without user approval. Never skip triage when bugs exist.

## Incorrect

```
# Agent lumps all bugs together and presents one generic menu
QA found 3 bugs. Spawning bug-fixer now...
[fixes applied]
Done! All bugs fixed.
```

- Error: Spawned bug-fixer without user approval, and did not distinguish blocking from non-blocking bugs.
- Cause: Agent treated all bugs the same regardless of severity or impact on test flow.

## Correct

**When a BLOCKER stopped testing early:**

```
⚠️  BLOCKING BUG — stopped qa-happy-path early
    [BLOCKER] POST /api/v1/login returns 500 — 4 flows skipped

    Fix this before QA can complete.
    1. Spawn qa-bug-fixer now (fixes blocker, then QA resumes)
    2. Abort — fix manually and re-run

────────────────────────────────────────
    Non-blocking bugs also found (2):
    [HIGH] Missing 403 on GET /api/v1/users/
    [MEDIUM] 422 not returned for short password
    Triaged after the blocker is resolved.
```

**When all bugs are non-blocking:**

```
═══════════════════════════════════════
  QA Results Summary
═══════════════════════════════════════
  qa-happy-path:    4/5 flows passed, 1 bug
  qa-chaos-monkey:  8/10 tests passed, 2 bugs

  Total: 3 bugs (0 BLOCKER, 1 HIGH, 2 MEDIUM)
═══════════════════════════════════════

Options:
  1. Spawn qa-bug-fixer for automated fixes (recommended for HIGH+)
  2. Generate QA report only — fix bugs manually
  3. Abort — discard results
```

- Blocking bugs get their own prompt — resolved before non-blocking triage.
- User always chooses the action — no assumptions.

## Why it matters

A BLOCKER that stopped testing early means the QA run is incomplete — non-blocking bugs may not represent the full picture. Surfacing blockers separately keeps the user from making triage decisions on partial data and makes the urgency unmistakably clear.
