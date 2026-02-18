---
title: Distinguish Authentication from Authorization
impact: HIGH
tags: security, auth, design
---

## Distinguish Authentication from Authorization

Authentication verifies identity; authorization verifies permissions. Both are required but they're different concerns.

**The distinction:**

- **Authentication**: Who are you? (session, JWT, API key)
- **Authorization**: What can you do? (roles, permissions, ownership)

**Incorrect (confusing auth concepts):**

```typescript
// Bad - only checks authentication, not authorization
export const deleteUser = protectedProcedure
  .input(z.object({ userId: z.string() }))
  .mutation(async ({ ctx, input }) => {
    // User is logged in, but can they delete THIS user?
    await db.deleteUser(input.userId); // Dangerous!
  });
```

**Correct (separate auth and authz):**

```typescript
export const deleteUser = protectedProcedure // Authentication
  .input(z.object({ userId: z.string() }))
  .mutation(async ({ ctx, input }) => {
    // Authorization: Can this user delete that user?
    const isOwnAccount = ctx.session.userId === input.userId;
    const isAdmin = ctx.session.role === 'ADMIN';

    if (!isOwnAccount && !isAdmin) {
      throw new ForbiddenError('Cannot delete other users');
    }

    await db.deleteUser(input.userId);
  });

// Or use role-based procedure
export const deleteAnyUser = adminProcedure // Auth + Admin role
  .input(z.object({ userId: z.string() }))
  .mutation(async ({ input }) => {
    await db.deleteUser(input.userId);
  });
```

**Authorization patterns:**

- **Role-based (RBAC)**: user, admin, moderator
- **Resource-based**: owner of this record
- **Attribute-based (ABAC)**: org membership + role + resource state

**Why it matters:**
- Authentication alone doesn't protect resources
- "Logged in user can access everything" is a common vulnerability
- Clear separation makes security audits easier
- Different resources need different permission models
