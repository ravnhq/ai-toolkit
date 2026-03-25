---
title: Create Indexes Concurrently on Large Tables
impact: MEDIUM
tags: index, migration, locking
---

## Create Indexes Concurrently on Large Tables

Standard index creation locks the table. Use CONCURRENTLY for zero-downtime index creation.

**Incorrect (locks table during creation):**

```sql
-- Blocks all writes to orders table until complete
-- On large tables, this can take minutes!
CREATE INDEX idx_orders_created_at ON orders(created_at);
```

**Correct (concurrent, non-blocking):**

```sql
-- PostgreSQL: Allows reads and writes during creation
CREATE INDEX CONCURRENTLY idx_orders_created_at ON orders(created_at);
```

**Caveats with CONCURRENTLY:**

```sql
-- Cannot run inside a transaction
BEGIN; -- This won't work
CREATE INDEX CONCURRENTLY idx_name ON table(column);
COMMIT;

-- Takes longer than regular index creation
-- Index may be marked INVALID if creation fails
-- Check for invalid indexes:
SELECT indexrelid::regclass, indisvalid
FROM pg_index WHERE NOT indisvalid;

-- Retry if invalid:
DROP INDEX CONCURRENTLY idx_name;
CREATE INDEX CONCURRENTLY idx_name ON table(column);
```

**Why it matters:** Production tables often have millions of rows and continuous traffic. A regular CREATE INDEX can lock the table for minutes, causing user-facing errors. CONCURRENTLY builds the index without blocking writes.

Reference: [PostgreSQL CREATE INDEX CONCURRENTLY](https://www.postgresql.org/docs/current/sql-createindex.html#SQL-CREATEINDEX-CONCURRENTLY)
