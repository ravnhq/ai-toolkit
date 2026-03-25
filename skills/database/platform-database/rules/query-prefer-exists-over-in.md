---
title: Prefer EXISTS Over IN for Subqueries
impact: MEDIUM
tags: query, performance, subquery
---

## Prefer EXISTS Over IN for Subqueries

EXISTS can exit early when a match is found; IN must evaluate the entire subquery first.

**Incorrect (IN - evaluates entire subquery):**

```sql
-- Must build complete list of user IDs first
SELECT * FROM users
WHERE id IN (
  SELECT user_id FROM orders
  WHERE total > 1000
);
```

**Correct (EXISTS - exits early):**

```sql
-- Stops at first match per user
SELECT * FROM users u
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.user_id = u.id
    AND o.total > 1000
);
```

**Why it matters:** With EXISTS, the database can stop searching as soon as it finds one matching row. IN requires materializing the entire subquery result set into memory first. For large subquery results, EXISTS can be significantly faster.

**Note:** Modern query optimizers may rewrite IN to EXISTS automatically, but writing EXISTS explicitly ensures optimal behavior across databases.

Reference: [EXISTS vs IN](https://use-the-index-luke.com/sql/partial-results/fetch-next-page)
