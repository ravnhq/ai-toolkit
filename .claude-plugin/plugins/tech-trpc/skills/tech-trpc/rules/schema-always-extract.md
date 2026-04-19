---
title: Always Extract Schemas
impact: HIGH
tags: schemas, validation, types
---

## Always Extract Schemas

All Zod schemas live in `*.schema.ts` files, even simple ones. This enables reuse and keeps procedures focused on logic.

**Incorrect (inline schemas):**

```typescript
// features/invitations/create/create.procedure.ts
export const createInvitation = adminProcedure
  .input(z.object({
    email: z.string().email(),
    role: z.enum(['MEMBER', 'AGENT', 'ADMIN']).default('MEMBER'),
  }))
  .output(z.object({
    id: z.string(),
    email: z.string(),
    role: z.string(),
    expiresAt: z.date(),
  }))
  .mutation(async ({ ctx, input }) => {
    // ...
  });
```

**Correct (extracted schemas):**

```typescript
// features/invitations/create/create.schema.ts
import { z } from 'zod';

export const createInvitationInput = z.object({
  email: z.string().email(),
  role: z.enum(['MEMBER', 'AGENT', 'ADMIN']).default('MEMBER'),
});

export const createInvitationOutput = z.object({
  id: z.string(),
  email: z.string(),
  role: z.string(),
  expiresAt: z.date(),
});

export type CreateInvitationInput = z.infer<typeof createInvitationInput>;
export type CreateInvitationOutput = z.infer<typeof createInvitationOutput>;

// features/invitations/create/create.procedure.ts
import { createInvitationInput, createInvitationOutput } from './create.schema';

export const createInvitation = adminProcedure
  .input(createInvitationInput)
  .output(createInvitationOutput)
  .mutation(async ({ ctx, input }) => {
    // Procedure is focused on logic, not schema definitions
  });
```

**Why it matters:** Extracted schemas can be reused (e.g., for form validation on the client). Procedures stay focused on business logic. Types are easily exported for use elsewhere.
