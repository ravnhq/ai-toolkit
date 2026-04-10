---
title: Define Strict Validation Schemas
impact: HIGH
tags: validation, types, schemas
---

## Define Strict Validation Schemas

Schemas should be as strict as possible. Don't use permissive types like `any` or unbounded strings.

**Incorrect (too permissive):**

```typescript
// Bad - accepts anything
const inputSchema = z.object({
  data: z.any(),
  options: z.record(z.unknown()),
});

// Bad - no constraints
const userSchema = z.object({
  email: z.string(),           // No format validation
  role: z.string(),            // Should be enum
  amount: z.number(),          // No min/max
  metadata: z.object({}),      // Accepts anything
});
```

**Correct (strict constraints):**

```typescript
// Good - explicit types and constraints
const userSchema = z.object({
  email: z.string().email().max(255),
  role: z.enum(['USER', 'ADMIN', 'MODERATOR']),
  amount: z.number().positive().max(1_000_000),
  metadata: z.object({
    source: z.enum(['web', 'mobile', 'api']),
    version: z.string().regex(/^\d+\.\d+\.\d+$/),
  }).optional(),
});

// Good - use discriminated unions for variants
const paymentSchema = z.discriminatedUnion('type', [
  z.object({
    type: z.literal('card'),
    cardNumber: z.string().regex(/^\d{16}$/),
    expiry: z.string().regex(/^\d{2}\/\d{2}$/),
  }),
  z.object({
    type: z.literal('bank'),
    accountNumber: z.string(),
    routingNumber: z.string(),
  }),
]);
```

**Why it matters:**
- Catches invalid data before it enters your system
- Provides TypeScript types automatically
- Self-documenting API contracts
- Prevents injection attacks and type coercion bugs
- Clear error messages for API consumers
