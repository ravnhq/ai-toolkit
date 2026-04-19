---
title: Review Generated Migration SQL
impact: HIGH
tags: migration, safety, review
---

## Review Generated Migration SQL

Always review the SQL that migration tools generate. Auto-generated migrations can produce unexpected results.

**Common issues to watch for:**

```sql
-- Tool might generate DROP + ADD instead of RENAME
ALTER TABLE users DROP COLUMN full_name;
ALTER TABLE users ADD COLUMN display_name VARCHAR(255);
-- Lost all data! Should be:
ALTER TABLE users RENAME COLUMN full_name TO display_name;

-- Tool might add NOT NULL without default on large table
ALTER TABLE orders ADD COLUMN priority INTEGER NOT NULL;
-- Fails on existing rows! Should be:
ALTER TABLE orders ADD COLUMN priority INTEGER NOT NULL DEFAULT 0;

-- Tool might not use CONCURRENTLY for large table indexes
CREATE INDEX idx_orders_user ON orders(user_id);
-- Locks table! Should be:
CREATE INDEX CONCURRENTLY idx_orders_user ON orders(user_id);
```

**Review checklist:**

1. Run the migration tool's generate command
2. Read the generated SQL file
3. Check for data-destructive operations (DROP, TRUNCATE)
4. Verify constraint additions handle existing data
5. Consider table lock implications on large tables

**Why it matters:** Migration tools infer changes from schema diffs. They can't know your intent - whether a rename is a rename vs. a drop-and-add. A few minutes of review prevents data loss in production.
