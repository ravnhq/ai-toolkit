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

**Error factory pattern for consistent creation:**

```typescript
// errors/factory.ts
import { TRPCError } from '@trpc/server';

export const errors = {
  notFound: (resource: string, id?: string) =>
    new TRPCError({
      code: 'NOT_FOUND',
      message: id ? `${resource} '${id}' not found` : `${resource} not found`,
    }),

  invalidInput: (field: string, reason: string) =>
    new TRPCError({
      code: 'BAD_REQUEST',
      message: `Invalid ${field}: ${reason}`,
    }),

  unauthorized: (reason = 'Authentication required') =>
    new TRPCError({
      code: 'UNAUTHORIZED',
      message: reason,
    }),

  forbidden: (resource: string) =>
    new TRPCError({
      code: 'FORBIDDEN',
      message: `You do not have access to ${resource}`,
    }),

  conflict: (resource: string) =>
    new TRPCError({
      code: 'CONFLICT',
      message: `${resource} already exists`,
    }),
};

// Usage in procedures:
if (!user) throw errors.notFound('User', userId);
if (email && existingUser?.email === email) throw errors.conflict('Email');
if (!hasAccess) throw errors.forbidden('this resource');
```

**Why it matters:**
- Domain-specific errors are self-documenting and provide clear feedback to clients
- Proper HTTP codes help with caching, retries, and debugging
- Error factories reduce boilerplate and ensure consistency across the codebase
- Type-safe error handling on client with `TRPCClientError` type guards
- Errors are part of the API contract; clients depend on specific error codes for retry logic

Reference: [tRPC Error Handling](https://trpc.io/docs/server/error-handling)
