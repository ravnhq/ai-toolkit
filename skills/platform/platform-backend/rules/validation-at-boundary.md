---
title: Validate Inputs at the API Boundary
impact: HIGH
tags: validation, security, reliability
---

## Validate Inputs at the API Boundary

All external input must be validated before use. Never trust data from clients, webhooks, or external APIs.

**Incorrect (trusting input):**

```typescript
// Bad - using input directly without validation
app.post('/users', async (req, res) => {
  const user = await db.createUser({
    email: req.body.email,      // Could be anything!
    role: req.body.role,        // User could set "admin"!
    age: req.body.age,          // String? Number? Array?
  });
  res.json(user);
});
```

**Correct (validate at boundary):**

```typescript
// Define schema with strict types and constraints
const createUserSchema = z.object({
  email: z.string().email().max(255),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150).optional(),
  // Role is NOT in input - set by server based on auth
});

// Validate before use
app.post('/users', async (req, res) => {
  const input = createUserSchema.parse(req.body);
  // input is now typed and validated

  const user = await db.createUser({
    ...input,
    role: 'USER', // Set by server, not client
  });
  res.json(user);
});
```

**What to validate:**

- Type correctness (string vs number vs array)
- Format (email, URL, UUID)
- Length/size limits
- Enum values (status must be 'active' | 'inactive')
- Numeric ranges (age > 0, quantity < 10000)
- Required vs optional fields

**Why it matters:**
- Prevents SQL injection and XSS
- Catches bugs early with clear error messages
- Documents expected input format
- Protects against malformed requests crashing your app
