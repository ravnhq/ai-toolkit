---
title: Add Columns Safely
impact: HIGH
tags: migration, safety, columns
---

## Add Columns Safely

Add new columns as nullable or with defaults to avoid table rewrites and locks on large tables.

**Incorrect (risky on large tables):**

```sql
-- NOT NULL without default requires checking every row
ALTER TABLE orders ADD COLUMN priority INTEGER NOT NULL;
-- Error: column "priority" contains null values

-- Or worse - table rewrite and lock on millions of rows
```

**Correct (safe approaches):**

```sql
-- Option 1: Nullable column (safe, instant)
ALTER TABLE orders ADD COLUMN priority INTEGER;

-- Option 2: Default value (safe, instant in modern PostgreSQL)
ALTER TABLE orders ADD COLUMN priority INTEGER NOT NULL DEFAULT 0;

-- Option 3: Two-step for custom defaults
-- Step 1: Add nullable
ALTER TABLE orders ADD COLUMN priority INTEGER;
-- Step 2: Backfill in batches (separate migration or script)
UPDATE orders SET priority = calculate_priority(order_type)
WHERE priority IS NULL LIMIT 10000;
-- Step 3: Add NOT NULL constraint (after backfill complete)
ALTER TABLE orders ALTER COLUMN priority SET NOT NULL;
```

**Why it matters:** On large tables, adding NOT NULL columns without defaults can lock the table for minutes or hours. Adding nullable columns or columns with defaults is typically instant (metadata-only change in modern databases).

Reference: [Safe Schema Changes](https://postgres.ai/blog/20210923-zero-downtime-postgres-schema-migrations-lock-timeout-and-retries)
