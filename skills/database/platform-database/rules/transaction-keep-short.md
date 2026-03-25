---
title: Keep Transactions Short
impact: MEDIUM
tags: transaction, locking, performance
---

## Keep Transactions Short

Transactions hold locks. Long transactions block other queries and can cause deadlocks.

**Incorrect (long transaction with external calls):**

```typescript
await db.transaction(async (tx) => {
  // Holds locks on users and orders tables
  const user = await tx.query.users.findFirst({ where: ... });

  // External API call - might take seconds!
  const paymentResult = await stripe.charges.create({ ... });

  // Still holding locks...
  if (paymentResult.success) {
    await tx.update(orders).set({ status: 'paid' }).where(...);
  }

  // Send email - might queue or retry
  await sendEmail(user.email, 'Payment received');

  // Finally releases locks after all external calls
});
```

**Correct (transaction only for database work):**

```typescript
// Fetch data BEFORE transaction
const user = await db.query.users.findFirst({ where: ... });

// External call BEFORE transaction
const paymentResult = await stripe.charges.create({ ... });

if (paymentResult.success) {
  // Short transaction - just database mutations
  await db.transaction(async (tx) => {
    await tx.update(orders).set({ status: 'paid' }).where(...);
    await tx.insert(payments).values({ ... });
  });

  // Side effects AFTER transaction committed
  await sendEmail(user.email, 'Payment received');
}
```

**Why it matters:**
- Long transactions hold row/table locks, blocking other queries
- External API calls can timeout or retry, extending lock duration
- Risk of deadlocks increases with transaction duration
- Connection pool exhaustion if transactions pile up

Reference: [Transaction Best Practices](https://www.postgresql.org/docs/current/transaction-iso.html)
