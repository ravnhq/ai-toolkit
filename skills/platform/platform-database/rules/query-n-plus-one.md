---
title: Avoid N+1 Queries
impact: CRITICAL
impactDescription: Can cause 100x+ performance degradation
tags: query, performance, eager-loading
---

## Avoid N+1 Queries

N+1 queries occur when you fetch a list of items, then make a separate query for each item's related data. This is one of the most common performance killers.

**Incorrect (N+1 - queries grow with data):**

```sql
-- First query: get all orders
SELECT * FROM orders WHERE user_id = 123;
-- Returns 100 orders

-- Then for EACH order (100 more queries!):
SELECT * FROM order_items WHERE order_id = 1;
SELECT * FROM order_items WHERE order_id = 2;
-- ... 98 more queries
```

**Correct (eager loading - constant queries):**

```sql
-- Single query with JOIN
SELECT o.*, oi.*
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.id
WHERE o.user_id = 123;

-- Or two queries with IN clause
SELECT * FROM orders WHERE user_id = 123;
SELECT * FROM order_items WHERE order_id IN (1, 2, 3, ...);
```

**Why it matters:** With 100 items, N+1 means 101 database round-trips instead of 1-2. Each query has network latency, connection overhead, and query planning cost. This compounds rapidly - a page that loads in 100ms can become 10+ seconds.

Reference: [N+1 Query Problem](https://stackoverflow.com/questions/97197/what-is-the-n1-selects-problem-in-orm-object-relational-mapping)
