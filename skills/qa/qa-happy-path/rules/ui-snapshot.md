---
title: Take a snapshot after every user action
impact: HIGH
tags:
  - qa
  - playwright
  - verification
  - ui
---

## Rule

After every meaningful user action (click, form fill, navigation, submit), take a Playwright snapshot to verify the UI state changed as expected. Screenshots provide evidence for both passing and failing tests.

## Incorrect

```
1. Click "Add to Cart" button
2. Click "Checkout" button
3. Fill payment form
4. Click "Pay"
5. Assert order confirmation page appears
# No snapshots taken between steps — if step 3 fails, there's no evidence of state at step 2
```

- Error: No intermediate snapshots between actions — failure evidence is missing.
- Cause: Agent optimized for speed over verification, skipping snapshot steps.

## Correct

```
1. Click "Add to Cart" button
   → Snapshot: cart badge shows "1 item" ✓
2. Click "Checkout" button
   → Snapshot: checkout page loaded with cart summary ✓
3. Fill payment form
   → Snapshot: form fields populated correctly ✓
4. Click "Pay"
   → Snapshot: order confirmation page with order ID ✓
```

- Every action is followed by a snapshot that verifies the expected state.
- If step 4 fails, snapshots from steps 1-3 show the exact state leading to the failure.

## Why it matters

Without snapshots, bug reports lack visual evidence and reproduction context. Engineers cannot see what state the application was in before the failure. Snapshots also catch subtle UI regressions (layout shifts, missing elements) that assertion-only tests miss.
