---
title: Always Review Generated Migration SQL
impact: HIGH
tags: migration, review, safety
---

## Always Review Generated Migration SQL

Drizzle-kit infers migrations from schema diffs. Always review the generated SQL before committing.

**After generating:**

```bash
# Generate migration
pnpm db:generate
# Output: Created migration: 0003_add_user_avatar.sql

# Review the SQL!
cat packages/db/drizzle/0003_add_user_avatar.sql
```

**Common issues to catch:**

```sql
-- Issue 1: DROP + ADD instead of RENAME
-- Drizzle saw column name change, but generated:
ALTER TABLE "users" DROP COLUMN "full_name";
ALTER TABLE "users" ADD COLUMN "display_name" varchar(255);
-- Data loss! Manually change to:
ALTER TABLE "users" RENAME COLUMN "full_name" TO "display_name";

-- Issue 2: NOT NULL without default on existing table
ALTER TABLE "users" ADD COLUMN "tier" varchar(20) NOT NULL;
-- Fails if table has rows! Change to:
ALTER TABLE "users" ADD COLUMN "tier" varchar(20) NOT NULL DEFAULT 'free';

-- Issue 3: Regular index on large table (locks!)
CREATE INDEX "idx_orders_created" ON "orders" ("created_at");
-- Change to concurrent:
CREATE INDEX CONCURRENTLY "idx_orders_created" ON "orders" ("created_at");
-- Note: CONCURRENTLY can't be in a transaction
```

**Review checklist:**

- [ ] No DROP COLUMN that should be RENAME
- [ ] NOT NULL columns have DEFAULT or are nullable
- [ ] Large table indexes use CONCURRENTLY
- [ ] No unintended data-destructive operations
- [ ] Changes match your intent

**Why it matters:**
- Schema diff algorithms aren't perfect
- Data loss from misinterpreted renames
- Production outages from table locks
- A few minutes of review prevents hours of recovery

Reference: [Drizzle Migrations](https://orm.drizzle.team/kit-docs/overview)
