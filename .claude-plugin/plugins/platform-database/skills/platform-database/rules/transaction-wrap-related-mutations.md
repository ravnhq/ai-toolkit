---
title: Wrap Related Mutations in Transactions
impact: MEDIUM
tags: transaction, consistency, safety
---

## Wrap Related Mutations in Transactions

When multiple inserts/updates must succeed or fail together, use a transaction.

**Incorrect (partial failure leaves inconsistent state):**

```typescript
// If second operation fails, first is already committed!
await db.insert(userOrganizations).values({
  userId: session.user.id,
  organizationId: invitation.organizationId,
  role: invitation.role,
});

// This fails - user is now in org but invitation still pending
await db.update(invitations)
  .set({ status: 'ACCEPTED', acceptedAt: new Date() })
  .where(eq(invitations.id, invitationId));
```

**Correct (atomic - all or nothing):**

```typescript
await db.transaction(async (tx) => {
  // Both operations in same transaction
  await tx.insert(userOrganizations).values({
    userId: session.user.id,
    organizationId: invitation.organizationId,
    role: invitation.role,
  });

  await tx.update(invitations)
    .set({ status: 'ACCEPTED', acceptedAt: new Date() })
    .where(eq(invitations.id, invitationId));

  // If anything fails, everything rolls back
});
```

**Common transaction scenarios:**

- Creating a record with related child records
- Transferring between accounts (debit + credit)
- Accepting invitation (create membership + update invitation)
- Order completion (update order + create payment record + update inventory)

**Why it matters:** Without transactions, partial failures leave data in inconsistent states. Users might be charged but have no order, or be in an organization but invitation still shows pending. These inconsistencies are hard to debug and fix.
