---
title: Test deduplication and idempotency
impact: HIGH
tags:
  - qa
  - edge-case
  - deduplication
  - idempotency
---

## Rule

For operations that should be idempotent or deduplicated (webhook handlers, payment processing, form submissions with unique IDs), test: same request twice with same ID, same ID with different body, and rapid duplicate submissions. Verify only one record is created.

## Incorrect

```
# Only sends the request once
1. POST /api/webhooks/stripe with event_id="evt_123" → 200 ✓
# Never tested what happens if Stripe retries the same event
```

- Error: Never tested duplicate handling — only verified the first request works.
- Cause: Agent assumed idempotency without verifying it.

## Correct

```
# Tests deduplication behavior
1. POST /api/webhooks/stripe with event_id="evt_123" → 200 ✓
2. POST /api/webhooks/stripe with event_id="evt_123" (same payload) → 200 ✓
3. GET /api/orders → only 1 order created ✓ (dedup works)
4. POST /api/webhooks/stripe with event_id="evt_123" (different amount) → 200 ✓
5. GET /api/orders → still only 1 order ✓ (dedup by ID, not content)
```

- Sends the same event twice and verifies only one record is created.
- Tests that dedup is by ID, not by payload content — a common implementation mistake.

## Why it matters

Webhooks retry on timeout. Users double-click submit buttons. Network errors cause automatic retries. Without deduplication, these create duplicate records — duplicate charges, duplicate orders, duplicate notifications. Financial systems require idempotency.
