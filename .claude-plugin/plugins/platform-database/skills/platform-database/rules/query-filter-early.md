---
title: Filter Early, Aggregate Late
impact: HIGH
tags: query, performance, optimization
---

## Filter Early, Aggregate Late

Reduce the dataset with WHERE clauses before applying aggregations, sorts, or joins.

**Incorrect (aggregate then filter):**

```sql
-- Aggregates ALL posts, then filters
SELECT organization_id, COUNT(*) as post_count
FROM posts
GROUP BY organization_id
HAVING organization_id = 'org_123';
```

**Correct (filter then aggregate):**

```sql
-- Filters first, aggregates smaller dataset
SELECT organization_id, COUNT(*) as post_count
FROM posts
WHERE organization_id = 'org_123'
  AND status = 'ACTIVE'
  AND created_at > '2024-01-01'
GROUP BY organization_id;
```

**Why it matters:** Databases process data in stages. Filtering early means fewer rows to sort, join, and aggregate. A query over 1 million rows filtered to 1,000 before aggregation is ~1000x less work than aggregating everything first.

Reference: [Query Optimization Basics](https://use-the-index-luke.com/sql/where-clause)
