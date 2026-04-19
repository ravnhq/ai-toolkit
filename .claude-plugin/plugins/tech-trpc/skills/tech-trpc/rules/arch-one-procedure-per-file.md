---
title: One Procedure Per File
impact: CRITICAL
tags: architecture, organization, procedures
---

## One Procedure Per File

Each tRPC procedure lives in its own file with a clear name matching the operation.

**Incorrect (multiple procedures in one file):**

```typescript
// features/invitations/procedures.ts
export const createInvitation = protectedProcedure
  .input(...)
  .mutation(...);

export const listInvitations = protectedProcedure
  .input(...)
  .query(...);

export const revokeInvitation = protectedProcedure
  .input(...)
  .mutation(...);

// 500 lines later...
```

**Correct (one per file):**

```typescript
// features/invitations/create/create.procedure.ts
import { adminProcedure } from '@/shared/procedures';
import { createInvitationInput, createInvitationOutput } from './create.schema';
import { insertInvitation, findExisting } from './create.repository';

export const createInvitation = adminProcedure
  .input(createInvitationInput)
  .output(createInvitationOutput)
  .mutation(async ({ ctx, input }) => {
    const existing = await findExisting(ctx.db, input.email, ctx.organizationId);
    if (existing) {
      throw new InvitationExistsError(input.email);
    }
    return insertInvitation(ctx.db, { ...input, organizationId: ctx.organizationId });
  });
```

**Why it matters:** One procedure per file keeps files focused and small. It's easy to find the code for any operation. Tests are co-located with the code they test.
