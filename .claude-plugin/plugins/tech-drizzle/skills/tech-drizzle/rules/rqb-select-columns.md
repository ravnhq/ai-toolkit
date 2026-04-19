---
title: Select Specific Columns in Relational Queries
impact: MEDIUM
tags: query, performance, security
---

## Select Specific Columns in Relational Queries

Use the `columns` option to fetch only needed fields. Avoid returning entire rows.

**Incorrect (over-fetching):**

```typescript
// Bad - fetches all columns
const users = await db.query.users.findMany();
// Returns: id, email, name, passwordHash, resetToken, ...

// Bad - no column restriction on relations
const orders = await db.query.orders.findMany({
  with: {
    customer: true, // All customer columns
    items: true,    // All item columns
  },
});
```

**Correct (explicit columns):**

```typescript
// Good - only needed columns
const users = await db.query.users.findMany({
  columns: {
    id: true,
    email: true,
    name: true,
    // passwordHash: false (implicit)
  },
});

// Good - columns on relations too
const orders = await db.query.orders.findMany({
  columns: {
    id: true,
    total: true,
    status: true,
  },
  with: {
    customer: {
      columns: {
        id: true,
        name: true,
      },
    },
    items: {
      columns: {
        id: true,
        productName: true,
        quantity: true,
      },
    },
  },
});
```

**Why it matters:**
- Reduces bandwidth and memory usage
- Prevents accidentally exposing sensitive fields
- Clearer about what data is actually used
- Better performance on wide tables

Reference: [Drizzle columns selection](https://orm.drizzle.team/docs/rqb#select-filters)
