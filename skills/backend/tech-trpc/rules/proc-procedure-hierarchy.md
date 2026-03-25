---
title: Use the Procedure Hierarchy
impact: HIGH
tags: procedures, authorization, security
---

## Use the Procedure Hierarchy

Use the established procedure chain for authorization. Choose the most restrictive procedure that fits the use case.

**Procedure hierarchy:**

```
publicProcedure          # No auth required
    ↓
protectedProcedure       # Requires authenticated session
    ↓
organizationProcedure    # Requires org membership (X-Organization-Id header)
    ↓
adminProcedure           # Requires ADMIN, OWNER, or MASTER_CHIEF role
```

**Incorrect (wrong authorization level):**

```typescript
// Using public for something that needs auth
export const getUserProfile = publicProcedure
  .query(async ({ ctx }) => {
    return ctx.session.user; // 💥 ctx.session is undefined!
  });

// Using protected when org scoping is needed
export const listMembers = protectedProcedure
  .query(async ({ ctx }) => {
    // Which organization? No organizationId in context!
    return db.members.findMany();
  });
```

**Correct (appropriate authorization):**

```typescript
// Public - truly needs no auth
export const getPublicStats = publicProcedure
  .query(async () => {
    return { userCount: await countUsers() };
  });

// Protected - needs auth, not org-specific
export const getUserProfile = protectedProcedure
  .query(async ({ ctx }) => {
    return ctx.session.user;
  });

// Organization - needs org membership
export const listMembers = organizationProcedure
  .query(async ({ ctx }) => {
    return findMembersByOrg(ctx.db, ctx.organizationId);
  });

// Admin - needs admin role
export const deleteOrganization = adminProcedure
  .mutation(async ({ ctx, input }) => {
    return deleteOrg(ctx.db, ctx.organizationId);
  });
```

**Why it matters:** Using the wrong procedure level either exposes data that should be protected or blocks legitimate access. The hierarchy ensures consistent authorization.
