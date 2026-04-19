---
title: Always Filter by Tenant in Multi-Tenant Apps
impact: CRITICAL
tags: security, multi-tenant, authorization
---

## Always Filter by Tenant in Multi-Tenant Apps

In multi-tenant applications, every query for tenant data MUST include the tenant filter (e.g., organizationId).

**Incorrect (missing tenant filter):**

```typescript
// DANGEROUS - returns ALL posts across ALL organizations!
export const listPosts = protectedProcedure
  .query(async ({ ctx }) => {
    return db.query.posts.findMany(); // No org filter!
  });
```

**Correct (always filter by tenant):**

```typescript
// Good - scoped to current organization
export const listPosts = organizationProcedure
  .query(async ({ ctx }) => {
    return db.query.posts.findMany({
      where: (e, { eq }) => eq(e.organizationId, ctx.organizationId),
    });
  });
```

**Common patterns:**

```typescript
// Repository functions should require tenant ID
export async function findPosts(db: Database, organizationId: string) {
  return db.query.posts.findMany({
    where: (e, { eq }) => eq(e.organizationId, organizationId),
  });
}

// Middleware provides tenant context
const organizationProcedure = protectedProcedure.use(async ({ ctx, next }) => {
  const orgId = ctx.headers.get('X-Organization-Id');
  if (!orgId) throw new BadRequestError('Organization required');
  // Verify user is member of this organization
  const membership = await verifyMembership(ctx.userId, orgId);
  if (!membership) throw new ForbiddenError();
  return next({ ctx: { ...ctx, organizationId: orgId } });
});
```

**Why it matters:** Missing tenant filters expose data across organizations. This is one of the most severe security vulnerabilities in multi-tenant systems - it can leak confidential business data to competitors or unauthorized users.

Reference: [Multi-Tenancy Security](https://cheatsheetseries.owasp.org/cheatsheets/Multi-Tenancy_Security_Cheat_Sheet.html)
