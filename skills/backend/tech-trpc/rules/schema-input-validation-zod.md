---
title: Validate Input with Zod Schemas and Custom Error Formatting
impact: HIGH
tags: validation, schema, zod, error-handling
---

## Validate Input with Zod Schemas and Custom Error Formatting

Always define input schemas with Zod for runtime validation. Configure `initTRPC` with a custom `errorFormatter` to send detailed validation errors to clients instead of generic "Input validation failed" messages.

**Problem: generic validation errors without field details**

```typescript
// BAD — no custom error formatter; clients see generic message
import { initTRPC } from '@trpc/server';
import { z } from 'zod';

const t = initTRPC.create();

const userRouter = t.router({
  create: t.procedure
    .input(z.object({
      email: z.string().email('Invalid email'),
      password: z.string().min(8, 'Min 8 chars'),
      name: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      return await db.user.create(input);
    }),
});

// ❌ Client receives: { code: 'BAD_REQUEST', message: 'Input validation failed' }
// No details about which fields failed or why
```

**Solution: custom errorFormatter to flatten Zod errors in response**

```typescript
// GOOD — configure error formatter for detailed validation errors
import { initTRPC } from '@trpc/server';
import { ZodError } from 'zod';
import { z } from 'zod';

const t = initTRPC.create({
  errorFormatter({ shape, error }) {
    return {
      ...shape,
      data: {
        ...shape.data,
        zodError:
          error.code === 'BAD_REQUEST' && error.cause instanceof ZodError
            ? error.cause.flatten()
            : null,
      },
    };
  },
});

const userRouter = t.router({
  create: t.procedure
    .input(z.object({
      email: z.string().email('Invalid email'),
      password: z.string().min(8, 'Min 8 chars'),
      name: z.string().min(1),
    }))
    .mutation(async ({ input }) => {
      return await db.user.create(input);
    }),
});

// ✅ Client receives:
// {
//   code: 'BAD_REQUEST',
//   message: 'Input validation failed',
//   zodError: {
//     formErrors: [],
//     fieldErrors: {
//       email: ['Invalid email'],
//       password: ['Min 8 chars']
//     }
//   }
// }
```

**Client-side error handling with detailed feedback:**

```typescript
import { TRPCClientError } from '@trpc/client';
import type { AppRouter } from '@/server';

async function handleUserCreation(data: unknown) {
  try {
    const user = await client.user.create.mutate(data);
    return user;
  } catch (cause) {
    if (cause instanceof TRPCClientError<AppRouter>) {
      const zodError = cause.data?.zodError;

      if (zodError?.fieldErrors) {
        // Display field-specific errors
        for (const [field, errors] of Object.entries(zodError.fieldErrors)) {
          console.error(`${field}: ${errors.join(', ')}`);
        }
      }

      return null;
    }
    throw cause;
  }
}
```

**Advanced: custom error messages with context**

```typescript
import { initTRPC } from '@trpc/server';
import { ZodError } from 'zod';

const t = initTRPC.create({
  errorFormatter({ shape, error, type, path }) {
    // Log structured errors for monitoring
    if (error.code === 'BAD_REQUEST' && error.cause instanceof ZodError) {
      console.error(`Validation error in ${path}:`, error.cause.flatten());
    }

    return {
      ...shape,
      data: {
        ...shape.data,
        zodError:
          error.code === 'BAD_REQUEST' && error.cause instanceof ZodError
            ? {
                formErrors: error.cause.flatten().formErrors,
                fieldErrors: error.cause.flatten().fieldErrors,
              }
            : null,
        timestamp: new Date().toISOString(),
        traceId: error.cause?.traceId, // Pass trace IDs for debugging
      },
    };
  },
});

const invitationRouter = t.router({
  send: t.procedure
    .input(z.object({
      email: z.string().email('Email invalid'),
      expiresInDays: z.number().int().min(1).max(30),
    }))
    .mutation(async ({ input }) => {
      // Zod validates before reaching handler
      const invitation = await db.invitation.create({
        email: input.email,
        expiresAt: new Date(Date.now() + input.expiresInDays * 86400000),
      });
      return invitation;
    }),
});
```

**Composing Zod schemas for reuse:**

```typescript
import { z } from 'zod';

// Define reusable schemas
const emailSchema = z.string().email('Invalid email format').toLowerCase();
const passwordSchema = z.string().min(8, 'Min 8 chars').max(128);
const tokenSchema = z.string().uuid('Invalid token format');

const userCreateInput = z.object({
  email: emailSchema,
  password: passwordSchema,
  name: z.string().min(1).max(100),
});

const userUpdateInput = userCreateInput.omit({ password: true }).partial();

const authRouter = t.router({
  register: t.procedure
    .input(userCreateInput)
    .mutation(async ({ input }) => {
      // ✅ Reusable schema; automatic validation
      return await db.user.create(input);
    }),

  updateProfile: t.procedure
    .input(userUpdateInput)
    .mutation(async ({ input }) => {
      return await db.user.update(input);
    }),

  verifyEmail: t.procedure
    .input(z.object({ token: tokenSchema }))
    .mutation(async ({ input }) => {
      return await verifyEmailToken(input.token);
    }),
});
```

**Why it matters:**
- Runtime validation catches invalid input before it reaches business logic
- Detailed Zod error responses help clients provide specific feedback to users
- Schema reuse across procedures keeps validation consistent
- Type inference from schemas provides full client-side type safety
- Custom error formatter allows structured error logging and monitoring
- Field-level errors guide users to fix input issues immediately

Reference: [tRPC Input Validation](https://trpc.io/docs/server/error-handling)
Reference: [Zod Documentation](https://zod.dev/)
