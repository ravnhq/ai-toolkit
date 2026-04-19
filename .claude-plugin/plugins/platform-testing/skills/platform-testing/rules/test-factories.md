---
title: Use Test Data Factories
impact: HIGH
tags: test-data, factories, isolation
---

## Use Test Data Factories

Create factory functions that produce complete entities with sensible defaults and unique identifiers. This reduces setup boilerplate and prevents cross-test contamination from shared or hardcoded data.

**Define factory functions with defaults and overrides:**

```typescript
// test/factories.ts
import { nanoid } from "nanoid";

export function createUser(overrides?: Partial<User>): User {
  return {
    id: crypto.randomUUID(),
    email: `test-${nanoid(6)}@example.com`,
    name: "Test User",
    role: "MEMBER",
    createdAt: new Date(),
    ...overrides,
  };
}

export function createOrganization(overrides?: Partial<Organization>): Organization {
  return {
    id: crypto.randomUUID(),
    name: `Test Org ${nanoid(6)}`,
    slug: `test-org-${nanoid(6)}`,
    createdAt: new Date(),
    ...overrides,
  };
}
```

**Compose factories for related entities:**

```typescript
export function createInvitation(overrides?: Partial<Invitation>): Invitation {
  return {
    id: crypto.randomUUID(),
    organizationId: overrides?.organizationId ?? crypto.randomUUID(),
    email: `invite-${nanoid(6)}@example.com`,
    role: "MEMBER",
    status: "PENDING",
    createdAt: new Date(),
    ...overrides,
  };
}

// Usage - compose related data
const org = createOrganization();
const admin = createUser({ role: "ADMIN" });
const invite = createInvitation({ organizationId: org.id });
```

**Bad -- hardcoded inline test data with shared IDs:**

```typescript
it("creates an invitation", async () => {
  const user = {
    id: "user-1",
    email: "test@example.com",
    name: "Test",
    role: "ADMIN",
    createdAt: new Date("2024-01-01"),
  };

  // Another test also uses "user-1" -- collision risk
  const result = await inviteUser(user, "new@example.com");
  expect(result.status).toBe("PENDING");
});
```

**Good -- factory with defaults and partial overrides:**

```typescript
it("creates an invitation", async () => {
  const admin = createUser({ role: "ADMIN" });

  const result = await inviteUser(admin, "new@example.com");
  expect(result.status).toBe("PENDING");
});

it("rejects invitation from non-admin", async () => {
  const member = createUser({ role: "MEMBER" });

  await expect(inviteUser(member, "new@example.com")).rejects.toThrow(
    "UNAUTHORIZED",
  );
});
```

**Why it matters:**
- Each test gets isolated data with unique IDs -- no cross-test contamination
- Only override the fields relevant to the test, making intent clear
- Tests can run in parallel without ID collisions
- Adding a new required field to an entity only requires updating one factory, not every test

Reference: [Test Data Isolation](https://kentcdodds.com/blog/test-isolation-with-react)
