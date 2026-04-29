---
title: Read the code before writing any changes
impact: CRITICAL
tags:
  - qa
  - bug-fix
  - workflow
  - understanding
---

## Rule

Before editing any file, read the entire relevant code section to understand the existing patterns, error handling, and logic flow. Never edit a file you have not read first. Trace the bug's logic path from entry point to failure point before writing a fix.

## Incorrect

```
# Bug report says: "POST /api/orders returns 500 when quantity is 0"
# Agent immediately writes a fix without reading:
Edit: OrderController.java line 23
  Add: if (request.getQuantity() <= 0) throw new BadRequestException("...");
# But the validation actually belongs in OrderService.validate(), not the controller
```

- Error: Applied the fix in the wrong layer because the agent did not read the codebase to understand where validation lives.
- Cause: Jumped to writing a fix without understanding the existing code structure.

## Correct

```
# Bug report says: "POST /api/orders returns 500 when quantity is 0"
# Agent reads first:
1. Read OrderController.java → delegates to orderService.createOrder()
2. Read OrderService.java → calls validate() then save()
3. Read validate() → checks productId not null, but NO quantity check
4. Root cause: missing quantity validation in OrderService.validate()
5. Fix: add quantity > 0 check in validate() method (line 67)
```

- Agent traced the full request path before writing anything.
- Fix is in the correct layer (service validation, not controller).

## Why it matters

Fixes applied without understanding the codebase end up in the wrong layer, duplicate existing logic, or conflict with patterns the team has established. Reading first ensures the fix is consistent with the architecture and addresses the actual root cause, not just the symptom.
