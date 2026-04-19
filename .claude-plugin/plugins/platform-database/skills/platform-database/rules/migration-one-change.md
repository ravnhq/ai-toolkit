---
title: One Logical Change Per Migration
impact: HIGH
tags: migration, safety, organization
---

## One Logical Change Per Migration

Each migration should represent a single, coherent schema change. Don't bundle unrelated changes.

**Incorrect (multiple unrelated changes):**

```
0001_add_invitations_and_update_users_and_fix_indexes.sql
```

```sql
-- Too many things happening
CREATE TABLE invitations (...);
ALTER TABLE users ADD COLUMN avatar_url TEXT;
CREATE INDEX idx_orders_created_at ON orders(created_at);
ALTER TABLE products DROP COLUMN legacy_field;
```

**Correct (single logical change):**

```
0001_add_invitations_table.sql
0002_add_user_avatar_column.sql
0003_add_orders_created_at_index.sql
0004_drop_products_legacy_field.sql
```

**Why it matters:**
- **Debugging**: If migration 0001 fails, you know exactly what went wrong
- **Rollback**: Smaller changes are easier to manually reverse if needed
- **Review**: Code reviewers can understand each change in isolation
- **Reordering**: Unrelated migrations can be safely reordered if needed

Reference: [Migration Best Practices](https://blog.pragmaticengineer.com/typical-rdbms-implementation-patterns/)
