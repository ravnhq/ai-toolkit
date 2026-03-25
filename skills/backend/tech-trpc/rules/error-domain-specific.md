---
title: Domain-Specific Error Classes
impact: HIGH
tags: errors, debugging, api
---

## Domain-Specific Error Classes

Throw domain-specific errors instead of generic ones. Use tRPC error codes for HTTP semantics.

**Incorrect (generic errors):**

```typescript
export const acceptInvitation = protectedProcedure
  .mutation(async ({ ctx, input }) => {
    const invitation = await findInvitation(ctx.db, input.token);

    if (!invitation) {
      throw new Error('Not found'); // Generic, unhelpful
    }

    if (invitation.expiresAt < new Date()) {
      throw new Error('Expired'); // No HTTP semantics
    }

    // ...
  });
```

**Correct (domain-specific errors):**

```typescript
// shared/errors.ts
import { TRPCError } from '@trpc/server';

export class InvitationNotFoundError extends TRPCError {
  constructor(token: string) {
    super({
      code: 'NOT_FOUND',
      message: 'Invitation not found or already used',
    });
  }
}

export class InvitationExpiredError extends TRPCError {
  constructor() {
    super({
      code: 'BAD_REQUEST',
      message: 'This invitation has expired',
    });
  }
}

export class InvitationExistsError extends TRPCError {
  constructor(email: string) {
    super({
      code: 'CONFLICT',
      message: `A pending invitation already exists for ${email}`,
    });
  }
}

// In procedure:
if (!invitation) {
  throw new InvitationNotFoundError(input.token);
}

if (invitation.expiresAt < new Date()) {
  throw new InvitationExpiredError();
}
```

**Common tRPC error codes:**

| Code | HTTP | Use For |
|------|------|---------|
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `BAD_REQUEST` | 400 | Invalid input, expired, etc. |
| `CONFLICT` | 409 | Duplicate, already exists |
| `UNAUTHORIZED` | 401 | Not authenticated |
| `FORBIDDEN` | 403 | Authenticated but not allowed |

**Why it matters:** Domain-specific errors are self-documenting and provide clear feedback to clients. Proper HTTP codes help with caching, retries, and debugging.
