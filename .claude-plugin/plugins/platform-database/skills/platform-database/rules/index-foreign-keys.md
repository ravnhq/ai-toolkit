---
title: Always Index Foreign Keys
impact: HIGH
tags: index, foreign-key, performance
---

## Always Index Foreign Keys

Every foreign key column should have an index. This is not automatic in most databases.

**Incorrect (missing index on foreign key):**

```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  -- No index on user_id!
  created_at TIMESTAMP NOT NULL
);

-- This query is slow without index:
SELECT * FROM orders WHERE user_id = 'user_123';

-- JOINs are also slow:
SELECT u.*, o.* FROM users u
JOIN orders o ON o.user_id = u.id;
```

**Correct (indexed foreign key):**

```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
```

**Why it matters:**
- JOINs on foreign keys are extremely common
- Without index, every JOIN requires full table scan of child table
- Parent record deletion checks (for RESTRICT/CASCADE) require scanning child table
- PostgreSQL and MySQL don't auto-create indexes on foreign keys (unlike some other databases)

Reference: [Foreign Key Indexes](https://use-the-index-luke.com/sql/join/fk-index-foreign-key-parent-table)
