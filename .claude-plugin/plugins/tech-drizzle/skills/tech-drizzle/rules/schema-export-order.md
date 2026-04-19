---
title: Export Tables in Dependency Order
impact: MEDIUM
tags: schema, imports, circular
---

## Export Tables in Dependency Order

In your schema index, export tables before their dependents, and relations last.

**Incorrect (random order causes issues):**

```typescript
// schema/index.ts - wrong order
export * from './relations';        // Uses tables not yet exported!
export * from './invitations';      // Depends on users, organizations
export * from './users';
export * from './organizations';
```

**Correct (dependency order):**

```typescript
// schema/index.ts
// 1. Base tables (no dependencies)
export * from './users';

// 2. Tables that depend on base tables
export * from './organizations';    // Has ownerId -> users

// 3. Junction/dependent tables
export * from './user-organizations'; // Depends on users, organizations
export * from './invitations';        // Depends on users, organizations

// 4. Relations LAST (uses all tables)
export * from './relations';
```

**General ordering:**

1. Tables with no foreign keys
2. Tables with foreign keys (after their references)
3. Junction tables
4. Relations (always last)

**Why it matters:**
- Prevents "X is not defined" errors
- Drizzle needs tables defined before relations
- Consistent ordering across the codebase
- Easier to understand dependencies

Reference: [Drizzle Relations](https://orm.drizzle.team/docs/relations)
