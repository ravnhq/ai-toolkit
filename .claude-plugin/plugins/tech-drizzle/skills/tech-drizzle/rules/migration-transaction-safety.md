---
title: Use Transactions for Multi-Operation Consistency
impact: HIGH
tags: transaction, consistency, data-integrity, atomicity
---

## Use Transactions for Multi-Operation Consistency

Wrap multi-operation writes in `db.transaction()` to ensure atomicity. All operations commit together or all rollback together, preventing partial updates and maintaining referential integrity. Use nested transactions with savepoints for fine-grained control.

**Problem: partial updates without transaction**

```typescript
// BAD — operations not atomic; one can fail, leaving data inconsistent
async function transferFunds(fromUserId: string, toUserId: string, amount: number) {
  // Debit first account
  await db
    .update(accounts)
    .set({ balance: sql`${accounts.balance} - ${amount}` })
    .where(eq(accounts.userId, fromUserId));

  // If this fails, first account is debited but second is not credited
  // Transfer is incomplete and data is corrupted
  await db
    .update(accounts)
    .set({ balance: sql`${accounts.balance} + ${amount}` })
    .where(eq(accounts.userId, toUserId));
}
```

**Solution: wrap in transaction for atomicity**

```typescript
// GOOD — both operations succeed or both rollback
async function transferFunds(fromUserId: string, toUserId: string, amount: number) {
  const result = await db.transaction(async (tx) => {
    // Debit first account
    await tx
      .update(accounts)
      .set({ balance: sql`${accounts.balance} - ${amount}` })
      .where(eq(accounts.userId, fromUserId));

    // If this fails, entire transaction rolls back
    await tx
      .update(accounts)
      .set({ balance: sql`${accounts.balance} + ${amount}` })
      .where(eq(accounts.userId, toUserId));

    // Log transaction
    return { success: true, timestamp: new Date() };
  });

  return result; // Both updates committed atomically
}
```

**Handling errors in transactions:**

```typescript
async function refundOrder(orderId: string) {
  try {
    await db.transaction(async (tx) => {
      // Find order and validate
      const [order] = await tx
        .select()
        .from(orders)
        .where(eq(orders.id, orderId));

      if (!order) {
        throw new Error('Order not found');
      }

      if (order.status !== 'completed') {
        throw new Error('Only completed orders can be refunded');
      }

      // Refund payment
      const refund = await paymentProvider.refund(order.paymentId, order.total);
      if (!refund.success) {
        throw new Error('Payment refund failed');
      }

      // Update order status
      await tx
        .update(orders)
        .set({ status: 'refunded', refundedAt: new Date() })
        .where(eq(orders.id, orderId));

      // Delete order items (cleanup)
      await tx
        .delete(orderItems)
        .where(eq(orderItems.orderId, orderId));
    });
  } catch (error) {
    // Transaction automatically rolled back
    console.error('Refund failed:', error.message);
    throw error;
  }
}
```

**Nested transactions with savepoints:**

```typescript
async function updateUserWithAudit(userId: string, updates: object) {
  const result = await db.transaction(async (tx) => {
    // Update user
    const [updatedUser] = await tx
      .update(users)
      .set(updates)
      .where(eq(users.id, userId))
      .returning();

    try {
      // Nested transaction: attempt to create audit log
      await tx.transaction(async (tx2) => {
        await tx2.insert(auditLogs).values({
          userId,
          action: 'update',
          changes: JSON.stringify(updates),
          timestamp: new Date(),
        });
      });
    } catch (auditError) {
      // Audit log failed but user update is still committed
      // Outer transaction continues
      console.warn('Audit log failed:', auditError);
      // Could choose to rollback outer transaction here instead
    }

    return updatedUser;
  });

  return result;
}
```

**Transaction with relational queries:**

```typescript
async function createOrderWithItems(
  customerId: string,
  items: Array<{ productId: string; quantity: number }>
) {
  return await db.transaction(async (tx) => {
    // Create order
    const [order] = await tx
      .insert(orders)
      .values({
        customerId,
        status: 'pending',
        createdAt: new Date(),
      })
      .returning();

    // Insert all order items
    const orderItems = await tx
      .insert(items)
      .values(
        items.map(item => ({
          orderId: order.id,
          productId: item.productId,
          quantity: item.quantity,
        }))
      )
      .returning();

    // Fetch complete order with items using relational query
    const completeOrder = await tx.query.orders.findFirst({
      where: eq(orders.id, order.id),
      with: {
        items: true,
        customer: true,
      },
    });

    return completeOrder;
  });
}
```

**Transaction rollback on validation:**

```typescript
async function promoteUser(userId: string) {
  try {
    const [user] = await db.transaction(async (tx) => {
      // Fetch user
      const [user] = await tx
        .select()
        .from(users)
        .where(eq(users.id, userId));

      if (!user) {
        throw new Error('User not found');
      }

      // Check eligibility (cannot promote suspended users)
      if (user.suspended) {
        throw new Error('Cannot promote suspended user');
      }

      // Update role
      const [promoted] = await tx
        .update(users)
        .set({ role: 'admin', promotedAt: new Date() })
        .where(eq(users.id, userId))
        .returning();

      return [promoted];
    });

    return user;
  } catch (error) {
    // Entire transaction rolled back; no partial updates
    console.error('Promotion failed:', error.message);
    throw error;
  }
}
```

**Why it matters:**
- Atomicity ensures multi-operation consistency; either all succeed or all fail
- Prevents data corruption from partial writes
- Savepoints allow fine-grained rollback of nested operations
- Essential for financial transactions, inventory updates, order processing
- Database handles concurrent access within transactions safely
- Errors automatically trigger rollback; no manual cleanup needed
- Transaction isolation levels prevent dirty reads and race conditions

Reference: [Drizzle Transactions](https://orm.drizzle.team/docs/transactions)
