---
title: Use Procedure Hierarchy for Authorization
impact: CRITICAL
tags: security, authorization, middleware
---

## Use Procedure Hierarchy for Authorization

Establish a clear hierarchy of authorization levels. Each endpoint should use the most restrictive level that fits its use case.

**Typical procedure hierarchy:**

```
publicProcedure          → No auth required
    ↓
protectedProcedure       → Requires authenticated session
    ↓
resourceProcedure        → Requires resource/org membership
    ↓
adminProcedure           → Requires admin role
```

**Incorrect (bypass auth checks):**

```typescript
// Bad - direct data access without auth
app.get('/users/:id', async (req, res) => {
  const user = await db.findUser(req.params.id);
  res.json(user);
});
```

**Correct (use procedure hierarchy):**

```typescript
// Good - uses appropriate auth level
export const getUser = protectedProcedure
  .input(z.object({ id: z.string() }))
  .query(async ({ ctx, input }) => {
    // ctx.session is guaranteed to exist
    if (input.id !== ctx.session.userId && !ctx.isAdmin) {
      throw new ForbiddenError();
    }
    return db.findUser(input.id);
  });
```

**Why it matters:**
- Centralized auth logic prevents accidental bypasses
- Code review can verify correct procedure is used
- New endpoints automatically get appropriate auth
- Consistent authorization patterns across the codebase

Reference: [Defense in Depth](https://owasp.org/www-community/Defense_in_depth)
