---
title: List all preconditions explicitly — never assume setup state
impact: HIGH
tags:
  - test-case
  - preconditions
  - setup
  - standards
---

## Rule

Every test case must list all required setup state in a `preconditions` field. Never assume the tester knows what state the system should be in before the test begins.

## Incorrect

```json
{
  "title": "User can add item to cart",
  "preconditions": "User is logged in",
  "steps": ["Navigate to a product page", "Add item to cart", "Verify cart count updates"]
}
```

- Error: "User is logged in" omits required setup: the product must have available inventory, the cart must start empty, and the user must have the correct role.
- Cause: Preconditions written from memory of the happy path rather than a complete state enumeration.

## Correct

```json
{
  "title": "User can add item to cart",
  "preconditions": [
    "User is authenticated with role: customer",
    "Cart is empty (0 items)",
    "Target product has quantity_in_stock > 0",
    "Test environment is on /products"
  ],
  "steps": ["Navigate to the target product detail page", "Select quantity 1", "Submit add-to-cart action", "Observe cart state"]
}
```

- All four setup conditions are listed explicitly.
- A tester or automated runner can prepare the system state exactly before executing the test.

## Why it matters

Missing preconditions cause intermittent failures that are difficult to diagnose — the test may pass when run first in a session and fail when run after another test that modified the cart. Explicit preconditions enable reliable, repeatable execution in any order.
