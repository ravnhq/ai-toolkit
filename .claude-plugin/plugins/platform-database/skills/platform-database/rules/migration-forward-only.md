---
title: Forward-Only Migrations
impact: HIGH
tags: migration, safety, deployment
---

## Forward-Only Migrations

Never modify migrations that have been applied to staging or production. Create new migrations to fix issues.

**Incorrect (modifying deployed migration):**

```sql
-- DON'T edit 0001_create_users.sql after it's deployed
-- Even if you spot a mistake!
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100)  -- Oops, should be NOT NULL
);
```

**Correct (new migration to fix):**

```sql
-- 0001_create_users.sql (unchanged, already deployed)
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100)
);

-- 0002_make_user_name_required.sql (new migration)
-- First backfill any null values
UPDATE users SET name = 'Unknown' WHERE name IS NULL;
-- Then add constraint
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
```

**Why it matters:**
- Migration state is tracked - database thinks old migration already ran
- Other developers/environments have already applied the original version
- Modifying creates drift between environments
- Deployments may fail silently or with confusing errors

Reference: [Database Migration Patterns](https://martinfowler.com/articles/evodb.html)
