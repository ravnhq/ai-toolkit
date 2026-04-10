---
title: Use Prepared Statements with Placeholders for Hot Paths
impact: HIGH
tags: performance, optimization, prepared-statements, placeholders
---

## Use Prepared Statements with Placeholders for Hot Paths

Use `.prepare()` with `sql.placeholder()` to pre-compile queries and execute them multiple times with different parameters. Prepared statements provide significant performance improvement for queries that run frequently in loops or hot paths.

**Problem: query recompiled on every execution**

```typescript
// BAD — query compiled every execution
async function getUsersByRole(role: string, count: number) {
  const results = [];
  for (let i = 0; i < count; i++) {
    // Query parsed and compiled every iteration
    const users = await db
      .select()
      .from(users)
      .where(eq(users.role, role))
      .limit(10);
    results.push(...users);
  }
  return results;
}

// ❌ 1000 iterations = 1000 compilations
```

**Solution: prepare once, execute many times**

```typescript
import { sql } from 'drizzle-orm';

// GOOD — prepare once, execute many times
const roleQuery = db
  .select()
  .from(users)
  .where(eq(users.role, sql.placeholder('role')))
  .limit(10)
  .prepare();

async function getUsersByRole(role: string, count: number) {
  const results = [];
  for (let i = 0; i < count; i++) {
    // Same precompiled query, only parameters change
    const users = await roleQuery.execute({ role });
    results.push(...users);
  }
  return results;
}

// ✅ 1000 iterations = 1 compilation
```

**Prepared statements with multiple placeholders:**

```typescript
import { sql } from 'drizzle-orm';
import { eq, gte, lte } from 'drizzle-orm';

const invoiceQuery = db
  .select({
    id: invoices.id,
    amount: invoices.amount,
    customer: customers.name,
  })
  .from(invoices)
  .innerJoin(customers, eq(invoices.customerId, customers.id))
  .where(
    sql`${invoices.createdAt} >= ${sql.placeholder('startDate')}
      and ${invoices.createdAt} <= ${sql.placeholder('endDate')}
      and ${invoices.status} = ${sql.placeholder('status')}`
  )
  .prepare();

// Execute with different date ranges and statuses
const q1 = await invoiceQuery.execute({
  startDate: new Date('2024-01-01'),
  endDate: new Date('2024-01-31'),
  status: 'paid',
});

const q2 = await invoiceQuery.execute({
  startDate: new Date('2024-02-01'),
  endDate: new Date('2024-02-28'),
  status: 'pending',
});
```

**Relational queries with prepared statements:**

```typescript
import { sql, placeholder } from 'drizzle-orm';

const userWithPostsQuery = db.query.users
  .findMany({
    where: (users, { eq }) => eq(users.id, placeholder('userId')),
    with: {
      posts: {
        where: (posts, { gte }) =>
          gte(posts.createdAt, placeholder('since')),
        limit: placeholder('limit'),
      },
    },
  })
  .prepare();

// Execute for different users and date ranges
const user1Posts = await userWithPostsQuery.execute({
  userId: 1,
  since: new Date('2024-01-01'),
  limit: 10,
});

const user2Posts = await userWithPostsQuery.execute({
  userId: 2,
  since: new Date('2024-02-01'),
  limit: 5,
});
```

**Batch insert with prepared statement:**

```typescript
const insertUserQuery = db
  .insert(users)
  .values({
    email: sql.placeholder('email'),
    name: sql.placeholder('name'),
    role: sql.placeholder('role'),
  })
  .returning()
  .prepare();

// Batch insert from array
const newUsers = await Promise.all(
  userDataArray.map(user =>
    insertUserQuery.execute({
      email: user.email,
      name: user.name,
      role: user.role,
    })
  )
);
```

**Prepared statement with named query (PostgreSQL specific):**

```typescript
const getActiveUsersQuery = db
  .select()
  .from(users)
  .where(eq(users.active, true))
  .prepare('get_active_users'); // Named for server-side caching

// Execute multiple times with server caching
const batch1 = await getActiveUsersQuery.execute();
const batch2 = await getActiveUsersQuery.execute();
```

**Why it matters:**
- Query compilation is expensive; prepared statements pre-compile once
- Reusing prepared statements reduces CPU and memory overhead
- Significant performance improvement for queries executed many times
- Placeholders prevent SQL injection by separating logic from data
- Server can cache compiled query plans across connection pool
- Essential for batch operations and tight loops
- TypeScript types fully preserved with placeholders

Reference: [Drizzle Prepared Statements](https://orm.drizzle.team/docs/performance-queries)
