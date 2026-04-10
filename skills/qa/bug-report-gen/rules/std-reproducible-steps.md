---
title: Reproduction steps must be atomic, sequential, and unambiguous
impact: CRITICAL
tags:
  - bug-report
  - reproducibility
  - standards
---

## Rule

Every bug report must include reproduction steps that are **atomic** (one action per step), **sequential** (in the exact order needed), and **unambiguous** (a stranger with zero project context can follow them and reproduce the failure).

## Incorrect

```
Steps:
1. Log in and set up a cart
2. Do the checkout thing
3. Bug appears
```

- Error: Steps are vague, skipped, and non-reproducible. "Set up a cart" and "checkout thing" are not actionable.
- Cause: Reporter assumed shared context with the reader.

## Correct

```
Steps to reproduce:
1. Navigate to https://app.example.com/login
2. Enter valid credentials for a standard user account (role: customer)
3. Navigate to /products and add any item with quantity > 0 to the cart
4. Navigate to /cart and proceed to /checkout
5. Fill in all required payment fields with valid test card 4111-1111-1111-1111
6. Click "Place Order"
7. Observe the response
```

- Each step is a single, unambiguous action.
- A new team member or automation script can follow these steps without additional context.

## Why it matters

Non-reproducible bugs cannot be fixed. Vague steps force engineers to waste time investigating what the reporter saw instead of the defect itself. Atomic, sequential steps are also directly reusable in automated regression test cases.
