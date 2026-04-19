---
title: Prefer Relational Queries for Reads
impact: HIGH
tags: query, relations, eager-loading
---

## Prefer Relational Queries for Reads

Use `db.query` API for reads with relations. It's more readable and handles JOINs automatically.

**Incorrect (manual JOINs for simple relations):**

```typescript
// Bad - manual join for something relational queries handle better
const result = await db
  .select()
  .from(users)
  .leftJoin(userOrganizations, eq(users.id, userOrganizations.userId))
  .leftJoin(organizations, eq(userOrganizations.organizationId, organizations.id))
  .where(eq(users.id, userId));

// Returns flat rows, needs manual shaping
```

**Correct (relational query API):**

```typescript
// Good - relational query with eager loading
const user = await db.query.users.findFirst({
  where: (u, { eq }) => eq(u.id, userId),
  with: {
    organizations: {
      with: {
        organization: true,
      },
    },
  },
});

// Returns properly nested object:
// { id, name, organizations: [{ organization: { name } }] }
```

**When to use each:**

| Use Case | API |
|----------|-----|
| Read with relations | `db.query` (relational) |
| Aggregations (COUNT, SUM) | `db.select` (query builder) |
| Complex JOINs, CTEs | `db.select` or raw SQL |
| Simple CRUD | Either works |

**Why it matters:**
- Relational queries are more readable
- Auto-generated JOINs are optimized
- Type-safe nested results
- Less boilerplate for common patterns

Reference: [Drizzle Relational Queries](https://orm.drizzle.team/docs/rqb)
