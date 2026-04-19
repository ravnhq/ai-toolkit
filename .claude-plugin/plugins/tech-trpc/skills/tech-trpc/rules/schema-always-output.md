---
title: Always Define Output Schemas
impact: HIGH
tags: schemas, validation, types, api-contract
---

## Always Define Output Schemas

Always define `.output()` schemas for procedures. This provides runtime validation, automatic TypeScript types for clients, and documentation of the API contract.

**Incorrect (no output schema):**

```typescript
export const listInvitations = adminProcedure
  .input(listInvitationsInput)
  // No .output() - client has to guess the shape
  .query(async ({ ctx, input }) => {
    const invitations = await findInvitations(ctx.db, ctx.organizationId);
    return invitations; // What shape is this? 🤷
  });
```

**Correct (explicit output):**

```typescript
export const listInvitations = adminProcedure
  .input(listInvitationsInput)
  .output(listInvitationsOutput) // Always include
  .query(async ({ ctx, input }) => {
    const invitations = await findInvitations(ctx.db, ctx.organizationId);
    return invitations;
  });

// In schema file:
export const listInvitationsOutput = z.array(z.object({
  id: z.string(),
  email: z.string(),
  role: z.enum(['MEMBER', 'AGENT', 'ADMIN']),
  status: z.enum(['PENDING', 'ACCEPTED', 'REVOKED']),
  createdAt: z.date(),
  invitedBy: z.object({
    id: z.string(),
    name: z.string(),
  }),
}));
```

**Why it matters:**

- **Runtime validation**: Catches accidental data leakage (e.g., password hashes)
- **Type safety**: Clients get accurate types without manual definitions
- **Documentation**: The schema IS the API contract
- **Refactoring safety**: Schema changes break at compile time, not production
