---
title: Define Output Schemas
impact: MEDIUM
tags: api, validation, contracts
---

## Define Output Schemas

Always define output schemas for API endpoints. This provides runtime validation, documentation, and type safety.

**Incorrect (no output schema):**

```typescript
// Bad - returns whatever the database gives
export const getUser = protectedProcedure
  .input(z.object({ id: z.string() }))
  .query(async ({ input }) => {
    // Might accidentally include password_hash, internal IDs, etc.
    return db.findUser(input.id);
  });
```

**Correct (explicit output schema):**

```typescript
// Define what the client receives
const userOutput = z.object({
  id: z.string(),
  email: z.string(),
  name: z.string(),
  createdAt: z.date(),
  // Explicitly excludes: password_hash, internal_notes, etc.
});

export const getUser = protectedProcedure
  .input(z.object({ id: z.string() }))
  .output(userOutput)
  .query(async ({ input }) => {
    const user = await db.findUser(input.id);
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      createdAt: user.createdAt,
    };
  });
```

**Benefits:**

1. **Runtime validation**: Catches accidental exposure of sensitive fields
2. **TypeScript types**: Clients get typed responses
3. **Documentation**: Schema defines the API contract
4. **Refactoring safety**: Schema mismatch fails fast

**Why it matters:**
- Prevents accidentally exposing sensitive data
- API changes that break clients are caught at compile/runtime
- Clients can rely on the response shape
- Self-documenting API for frontend developers
