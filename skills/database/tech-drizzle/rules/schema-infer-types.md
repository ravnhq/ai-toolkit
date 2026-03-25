---
title: Export Inferred Types
impact: MEDIUM
tags: schema, types, typescript
---

## Export Inferred Types

Export `$inferSelect` and `$inferInsert` types for each table. Use them consistently across the codebase.

**Incorrect (manual type definitions):**

```typescript
// Bad - manual types that can drift from schema
interface User {
  id: string;
  email: string;
  name: string;
  // Missing createdAt, updatedAt - oops!
}

// Bad - using 'any' or loose types
function createUser(data: any) { ... }
```

**Correct (inferred types):**

```typescript
// schema/users.ts
export const users = pgTable('users', {
  id: text('id').primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: varchar('name', { length: 100 }),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});

// Inferred types - always match schema
export type User = typeof users.$inferSelect;      // For reads
export type NewUser = typeof users.$inferInsert;   // For inserts

// Usage
async function createUser(data: NewUser): Promise<User> {
  const [user] = await db.insert(users).values(data).returning();
  return user;
}

async function getUser(id: string): Promise<User | undefined> {
  return db.query.users.findFirst({
    where: (u, { eq }) => eq(u.id, id),
  });
}
```

**Type differences:**

| Type | Use | Differences |
|------|-----|-------------|
| `$inferSelect` | Query results | All columns |
| `$inferInsert` | Insert data | Optionals have `?`, defaults excluded |

**Why it matters:**
- Types are always in sync with schema
- No manual type maintenance
- TypeScript catches schema/code mismatches
- Better autocomplete and error messages

Reference: [Drizzle Type Inference](https://orm.drizzle.team/docs/goodies#type-api)
