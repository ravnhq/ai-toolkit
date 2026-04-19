---
title: Avoid Type Assertions
impact: HIGH
tags: typescript, type-safety, casting
---

## Avoid Type Assertions

Type assertions (`as`) tell TypeScript "trust me" - but you might be wrong. Prefer proper typing or runtime validation.

**Incorrect:**

```typescript
// Assuming API returns what you expect
const user = (await fetchUser()) as User;
user.email.toLowerCase(); // Crashes if email is null

// Forcing incompatible types
const config = rawConfig as AppConfig;
```

**Correct:**

```typescript
// Runtime validation with Zod
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string(),
});

const user = UserSchema.parse(await fetchUser());
// Now TypeScript AND runtime guarantee the shape

// Or use type guards
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'email' in data &&
    typeof data.email === 'string'
  );
}
```

**When assertions are acceptable:**

- Test code where you control the mock data
- After a type guard in the same scope
- DOM element types after null checks

**Why it matters:** Assertions hide type mismatches that become runtime errors. Runtime validation ensures data matches expectations at system boundaries.
