---
title: Use Query Builder for Aggregations
impact: MEDIUM
tags: query, aggregations, sql
---

## Use Query Builder for Aggregations

The SQL-like query builder (`db.select`) is better for aggregations, GROUP BY, and complex queries.

**Correct (query builder for aggregations):**

```typescript
import { count, sum, avg } from 'drizzle-orm';

// COUNT with GROUP BY
const postCounts = await db
  .select({
    organizationId: posts.organizationId,
    postCount: count(posts.id),
  })
  .from(posts)
  .where(eq(posts.status, 'ACTIVE'))
  .groupBy(posts.organizationId);

// SUM and AVG
const stats = await db
  .select({
    organizationId: orders.organizationId,
    totalRevenue: sum(orders.amount),
    averageOrder: avg(orders.amount),
  })
  .from(orders)
  .where(gte(orders.createdAt, startOfMonth))
  .groupBy(orders.organizationId);

// Multiple aggregations
const userStats = await db
  .select({
    userId: users.id,
    orderCount: count(orders.id),
    totalSpent: sum(orders.amount),
    lastOrder: max(orders.createdAt),
  })
  .from(users)
  .leftJoin(orders, eq(users.id, orders.userId))
  .groupBy(users.id);
```

**Available aggregation functions:**

```typescript
import {
  count,    // COUNT(column)
  countDistinct, // COUNT(DISTINCT column)
  sum,      // SUM(column)
  avg,      // AVG(column)
  min,      // MIN(column)
  max,      // MAX(column)
} from 'drizzle-orm';
```

**Why it matters:**
- Relational queries don't support aggregations
- Query builder provides full SQL flexibility
- Type-safe aggregation results
- Can combine with JOINs and subqueries

Reference: [Drizzle Aggregations](https://orm.drizzle.team/docs/select#aggregations)
