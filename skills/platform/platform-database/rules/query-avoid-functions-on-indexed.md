---
title: Avoid Functions on Indexed Columns
impact: HIGH
tags: query, performance, index
---

## Avoid Functions on Indexed Columns

Applying functions to columns in WHERE clauses prevents index usage.

**Incorrect (function prevents index):**

```sql
-- Index on email column is NOT used
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- Index on created_at is NOT used
SELECT * FROM orders WHERE YEAR(created_at) = 2024;
```

**Correct (index-friendly):**

```sql
-- Store normalized (lowercase) data, query directly
SELECT * FROM users WHERE email = 'user@example.com';

-- Use range comparison instead of function
SELECT * FROM orders
WHERE created_at >= '2024-01-01'
  AND created_at < '2025-01-01';
```

**Why it matters:** When you apply a function to a column, the database must evaluate that function for every row before comparing - this is a full table scan. By keeping the column "naked" in the WHERE clause, the index can be used for fast lookups.

Reference: [Sargable Predicates](https://use-the-index-luke.com/sql/where-clause/functions)
