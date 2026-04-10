---
title: Use EXPLAIN ANALYZE for Slow Queries
impact: MEDIUM
tags: query, debugging, performance
---

## Use EXPLAIN ANALYZE for Slow Queries

Before optimizing, understand what the database is actually doing with EXPLAIN ANALYZE.

**Debug with EXPLAIN ANALYZE:**

```sql
EXPLAIN ANALYZE
SELECT u.*, COUNT(o.id) as order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active'
GROUP BY u.id;
```

**What to look for in the output:**

- **Seq Scan** on large tables - consider adding an index
- **Nested Loop** with high row estimates - may need better join strategy
- **Sort** without index - consider index on ORDER BY columns
- **Hash Join** with large memory - may need more work_mem or query restructure

**Actual vs Estimated rows:**

```
->  Index Scan (cost=0.29..8.31 rows=1)
    Actual rows=1000  <- Huge difference indicates stale statistics
```

**Why it matters:** Guessing at query performance is unreliable. EXPLAIN ANALYZE shows actual execution plans and timing, revealing bottlenecks like missing indexes, poor join strategies, or incorrect cardinality estimates.

Reference: [PostgreSQL EXPLAIN](https://www.postgresql.org/docs/current/using-explain.html)
