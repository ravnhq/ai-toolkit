---
title: One Table Per File
impact: MEDIUM
tags: schema, organization, maintainability
---

## One Table Per File

Define each table in its own file. Keep relations in a separate file to avoid circular imports.

**Incorrect (all tables in one file):**

```typescript
// schema.ts - too large, hard to navigate
export const users = pgTable('users', { ... });
export const organizations = pgTable('organizations', { ... });
export const userOrganizations = pgTable('user_organizations', { ... });
export const posts = pgTable('posts', { ... });
export const invitations = pgTable('invitations', { ... });
// ... 20 more tables

// Relations mixed in
export const usersRelations = relations(users, ...);
export const organizationsRelations = relations(organizations, ...);
```

**Correct (one table per file):**

```
packages/db/src/schema/
├── index.ts           # Re-exports all
├── users.ts           # users table + types
├── organizations.ts   # organizations table + types
├── user-organizations.ts
├── posts.ts
├── invitations.ts
└── relations.ts       # ALL relations in one file
```

```typescript
// schema/users.ts
export const users = pgTable('users', {
  id: text('id').primaryKey(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: varchar('name', { length: 100 }),
  createdAt: timestamp('created_at').notNull().defaultNow(),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

```typescript
// schema/relations.ts - ALL relations together
export const usersRelations = relations(users, ({ many }) => ({
  organizations: many(userOrganizations),
}));

export const organizationsRelations = relations(organizations, ({ one, many }) => ({
  owner: one(users, { fields: [organizations.ownerId], references: [users.id] }),
  members: many(userOrganizations),
}));
```

**Why it matters:**
- Easier to find and edit table definitions
- Relations in one file prevents circular imports
- Smaller files are faster to navigate
- Clear organization of schema

Reference: [Drizzle Schema Files](https://orm.drizzle.team/docs/sql-schema-declaration)
