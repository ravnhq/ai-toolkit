---
title: Generate a structured QA report with verdict
impact: HIGH
tags:
  - qa
  - orchestration
  - reporting
  - verdict
---

## Rule

Every QA run must produce a report saved to `.qa/reports/YYYY-MM-DD-HHmmss-qa-report.md` with sections: Summary, Agent Results, Bugs Found table, Bug Details (if no issue tracker), Fixes Applied (if bug-fixer ran), and Verdict (PASS or FAIL).

## Incorrect

```
QA done. Found 2 bugs. See the agent outputs above.
```

- Error: No persistent report file, no structured summary, no verdict.
- Cause: Agent delivered results inline without saving a report artifact.

## Correct

```markdown
# QA Report — 2026-04-07 — PR #42: add payment processing

## Summary
- **Scope:** PR #42
- **Agents run:** qa-happy-path, qa-chaos-monkey
- **Result:** FAIL (2 bugs found)

## Agent Results
### qa-happy-path
[full structured output]

### qa-chaos-monkey
[full structured output]

## Bugs Found
| # | Agent | Severity | Description | Issue | Status |
|---|-------|----------|-------------|-------|--------|
| 1 | chaos-monkey | BLOCKER | POST /api/orders 500 on zero qty | LIN-456 | Fixed |
| 2 | happy-path | HIGH | Checkout redirect fails | LIN-457 | Open |

## Fixes Applied
### Fix: POST /api/orders 500 on zero quantity
**Root cause:** Missing quantity validation
**Files changed:** OrderService.java
**Risk:** LOW

## Verdict
**FAIL** — 1 unresolved bug remains (LIN-457)
```

- Saved to `.qa/reports/2026-04-07-143022-qa-report.md`
- Structured with all required sections and a clear verdict.

## Why it matters

Reports are the audit trail of QA runs. Without a saved file, results are lost when the conversation ends. The bugs table and verdict enable CI gates and team review. The structured format makes reports machine-parseable for automation.
