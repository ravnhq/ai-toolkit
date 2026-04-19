---
title: Separate Data and Schema Migrations
impact: MEDIUM
tags: migration, data, organization
---

## Separate Data and Schema Migrations

Keep schema migrations separate from data backfills. Run them as independent operations.

**Incorrect (combined in one migration):**

```sql
-- 0001_add_user_tier.sql
ALTER TABLE users ADD COLUMN tier VARCHAR(20);

-- Backfill in same migration - risky
UPDATE users SET tier = 'free' WHERE subscription_id IS NULL;
UPDATE users SET tier = 'pro' WHERE subscription_id IS NOT NULL;

ALTER TABLE users ALTER COLUMN tier SET NOT NULL;
```

**Correct (separated):**

```sql
-- 0001_add_user_tier.sql (schema only)
ALTER TABLE users ADD COLUMN tier VARCHAR(20);
```

```typescript
// scripts/backfill-user-tiers.ts (data migration)
// Run separately, with batching and progress tracking
async function backfillUserTiers() {
  let updated = 0;
  while (true) {
    const result = await db.execute(`
      UPDATE users SET tier = CASE
        WHEN subscription_id IS NULL THEN 'free'
        ELSE 'pro'
      END
      WHERE tier IS NULL
      LIMIT 1000
    `);
    if (result.rowCount === 0) break;
    updated += result.rowCount;
    console.log(`Updated ${updated} users`);
  }
}
```

```sql
-- 0002_make_user_tier_required.sql (after backfill verified)
ALTER TABLE users ALTER COLUMN tier SET NOT NULL;
```

**Why it matters:**
- Schema migrations should be fast and safe to retry
- Data migrations may be slow and need progress tracking
- Failed data backfills shouldn't block schema deployments
- Data migration logic is easier to test in application code

Reference: [Data Migration Best Practices](https://benchling.engineering/move-fast-and-migrate-things-how-we-automated-migrations-in-postgres-d60c5c9e1bc8)
