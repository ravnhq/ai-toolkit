---
title: Produce a structured fix report for every bug
impact: HIGH
tags:
  - qa
  - bug-fix
  - reporting
  - documentation
---

## Rule

After every fix, produce a structured fix report containing: root cause, files changed, change summary, tests to run, and risk assessment. This report is used by the orchestrator and by engineers reviewing the fix.

## Incorrect

```
Fixed the bug. Changed OrderService.java.
```

- Error: No root cause analysis, no details about what was changed, no test guidance, no risk assessment.
- Cause: Agent treated the fix as done without communicating what happened.

## Correct

```
### Fix: POST /api/orders returns 500 when quantity is 0
**Root cause:** OrderService.validate() checks productId but has no quantity validation. Quantity=0 passes validation, reaches the database layer, and triggers a constraint violation (quantity > 0 CHECK constraint).
**Files changed:** src/main/java/com/example/service/OrderService.java
**Change summary:** Added quantity > 0 check in validate() method (line 67). Throws BadRequestException with message "Quantity must be greater than 0" when quantity <= 0.
**Tests to run:** OrderServiceTest.testValidateRejectsZeroQuantity, OrderControllerIntegrationTest
**Risk:** LOW — validation-only change, no impact on existing valid orders
```

- Root cause explains WHY the bug happened, not just WHERE.
- Files changed and change summary are specific and reviewable.
- Tests to run tells the team exactly how to verify.
- Risk assessment helps prioritize review.

## Why it matters

Fix reports are the handoff between the bug fixer and the rest of the team. Without a clear root cause, the same class of bug will recur. Without test guidance, the fix might not be verified. Without risk assessment, reviewers don't know what else to check.
