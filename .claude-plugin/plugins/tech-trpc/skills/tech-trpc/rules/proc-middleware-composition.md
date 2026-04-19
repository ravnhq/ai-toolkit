---
title: Chain Middlewares with unstable_pipe() for Context Composition
impact: HIGH
tags: middleware, composition, context, authentication
---

## Chain Middlewares with unstable_pipe() for Context Composition

Use `unstable_pipe()` to chain multiple middlewares and extend context in a type-safe manner. This pattern allows sequential middleware execution where each layer can access and extend the context from previous layers.

**Problem: middleware context not accessible in procedures**

```typescript
// BAD — middleware defined independently; context not merged
const authMiddleware = t.middleware((opts) => {
  return opts.next({
    ctx: { user: { id: '123' } },
  });
});

const logMiddleware = t.middleware((opts) => {
  return opts.next({
    ctx: { requestId: crypto.randomUUID() },
  });
});

const procedure = t.procedure.use(authMiddleware).use(logMiddleware);

procedure.query(({ ctx }) => {
  // ctx.user is undefined; context from authMiddleware lost
  return { userId: ctx.user?.id };
});
```

**Solution: chain middlewares with unstable_pipe() to preserve and extend context**

```typescript
// GOOD — middlewares piped; context preserved and extended
const authMiddleware = t.middleware((opts) => {
  return opts.next({
    ctx: { user: { id: '123', role: 'admin' } },
  });
});

const logMiddleware = authMiddleware.unstable_pipe((opts) => {
  // Access context from authMiddleware
  const { user } = opts.ctx;
  console.log(`Request from user ${user.id}`);

  return opts.next({
    ctx: {
      requestId: crypto.randomUUID(),
      startTime: Date.now(),
    },
  });
});

const protectedProcedure = t.procedure.use(logMiddleware);

protectedProcedure.query(({ ctx }) => {
  // ✅ Both user AND requestId available
  return {
    userId: ctx.user.id,
    requestId: ctx.requestId,
  };
});
```

**Real-world example: auth → authorization → logging chain**

```typescript
import { initTRPC, TRPCError } from '@trpc/server';
import { z } from 'zod';

const t = initTRPC.createContextFront(Context);

// Layer 1: Extract and validate user from bearer token
const authMiddleware = t.middleware(async (opts) => {
  const authHeader = opts.ctx.headers?.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    throw new TRPCError({ code: 'UNAUTHORIZED' });
  }

  const token = authHeader.slice(7);
  const user = await verifyJWT(token);

  return opts.next({
    ctx: { user },
  });
});

// Layer 2: Check authorization; only allow certain roles
const adminMiddleware = authMiddleware.unstable_pipe((opts) => {
  const { user } = opts.ctx;

  if (user.role !== 'admin') {
    throw new TRPCError({
      code: 'FORBIDDEN',
      message: 'Admin access required',
    });
  }

  return opts.next({
    ctx: { admin: true },
  });
});

// Layer 3: Add request tracking and timing
const tracedMiddleware = adminMiddleware.unstable_pipe((opts) => {
  const requestId = crypto.randomUUID();
  const startTime = Date.now();

  return opts.next({
    ctx: { requestId, startTime },
  });
});

// Use the fully-chained middleware
const adminProcedure = t.procedure.use(tracedMiddleware);

export const adminRouter = t.router({
  deleteUser: adminProcedure
    .input(z.object({ userId: z.string() }))
    .mutation(async ({ ctx, input }) => {
      // All context available: user, admin flag, requestId, startTime
      console.log(`[${ctx.requestId}] Admin ${ctx.user.id} deleting ${input.userId}`);

      await db.user.delete(input.userId);

      const duration = Date.now() - ctx.startTime;
      console.log(`[${ctx.requestId}] Completed in ${duration}ms`);

      return { success: true };
    }),
});
```

**Building reusable middleware stacks:**

```typescript
// Layer 1: Basic auth
const authenticated = t.middleware(async (opts) => {
  const token = opts.ctx.headers?.authorization?.slice(7);
  if (!token) throw new TRPCError({ code: 'UNAUTHORIZED' });

  const user = await verifyToken(token);
  return opts.next({ ctx: { user } });
});

// Layer 2: Admin-only
const adminOnly = authenticated.unstable_pipe((opts) => {
  if (opts.ctx.user.role !== 'admin') {
    throw new TRPCError({ code: 'FORBIDDEN' });
  }
  return opts.next({ ctx: {} }); // No new context needed
});

// Layer 3: Rate limiting
const rateLimited = authenticated.unstable_pipe((opts) => {
  const key = `rate:${opts.ctx.user.id}`;
  const count = cache.increment(key);
  if (count > 100) throw new TRPCError({ code: 'TOO_MANY_REQUESTS' });

  return opts.next({
    ctx: { remaining: 100 - count },
  });
});

// Create different procedures with different middleware stacks
const publicProcedure = t.procedure;
const authProcedure = t.procedure.use(authenticated);
const adminProcedure = t.procedure.use(adminOnly);
const rateLimitedProcedure = t.procedure.use(rateLimited);
```

**Why it matters:**
- Middlewares execute in order; each layer can access and extend context from previous layers
- Type-safe context composition; TypeScript ensures context is properly extended
- `unstable_pipe()` enforces that context types properly overlap, preventing bugs
- Allows building reusable middleware chains (auth → admin, auth → rate-limit, etc.)
- Each middleware layer has clear responsibility; separation of concerns
- Timing, logging, and instrumentation can wrap the full request lifecycle

Reference: [tRPC Middleware Documentation](https://trpc.io/docs/server/middlewares)
