---
title: Index Columns Used in WHERE, ORDER BY, JOIN
impact: HIGH
tags: index, performance, optimization
---

## Index Columns Used in WHERE, ORDER BY, JOIN

Create indexes for columns frequently used in filtering, sorting, and joining.

**Common patterns that need indexes:**

```sql
-- WHERE clause filtering
SELECT * FROM orders WHERE status = 'pending';
-- Index: CREATE INDEX idx_orders_status ON orders(status);

-- ORDER BY sorting
SELECT * FROM products ORDER BY created_at DESC LIMIT 20;
-- Index: CREATE INDEX idx_products_created_at ON products(created_at DESC);

-- JOIN conditions (foreign keys)
SELECT * FROM orders o JOIN users u ON u.id = o.user_id;
-- Index: CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Composite for multiple conditions
SELECT * FROM posts
WHERE organization_id = 'org_1' AND status = 'active'
ORDER BY start_date;
-- Index: CREATE INDEX idx_posts_org_status_date
--        ON posts(organization_id, status, start_date);
```

**Composite index column order:**

```sql
-- Put equality conditions first, range/sort last
-- Good: org_id (=), status (=), date (ORDER BY)
CREATE INDEX idx ON posts(organization_id, status, start_date);

-- The index can be used for:
-- WHERE organization_id = ?
-- WHERE organization_id = ? AND status = ?
-- WHERE organization_id = ? AND status = ? ORDER BY start_date

-- But NOT efficiently for:
-- WHERE status = ? (first column not used)
-- WHERE start_date > ? (first columns not used)
```

**Why it matters:** Without appropriate indexes, queries must scan entire tables. A properly indexed query on millions of rows can return in milliseconds; without the index, the same query takes seconds or minutes.

Reference: [Index Design](https://use-the-index-luke.com/sql/table-of-contents)
