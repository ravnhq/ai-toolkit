---
title: Use Hooks for Setup and Teardown
impact: MEDIUM
tags: hooks, lifecycle, setup
---

## Use Hooks for Setup and Teardown

Use `beforeEach`, `afterEach`, `beforeAll`, and `afterAll` for test setup and cleanup.

**Available hooks:**

```typescript
import { beforeAll, afterAll, beforeEach, afterEach } from 'vitest';

// Run once before all tests in this file
beforeAll(async () => {
  await setupTestDatabase();
});

// Run once after all tests in this file
afterAll(async () => {
  await teardownTestDatabase();
});

// Run before each test
beforeEach(() => {
  vi.clearAllMocks();
});

// Run after each test
afterEach(() => {
  cleanup();
});
```

**Scoped hooks with describe:**

```typescript
describe('user service', () => {
  let testUser: User;

  beforeEach(async () => {
    testUser = await createTestUser();
  });

  afterEach(async () => {
    await deleteTestUser(testUser.id);
  });

  test('updates user name', async () => {
    await updateUser(testUser.id, { name: 'New Name' });
    // ...
  });
});
```

**Prefer beforeEach over beforeAll for data:**

```typescript
// Bad - shared state between tests
let testOrg: Organization;
beforeAll(async () => {
  testOrg = await createTestOrg();  // Same org for all tests
});

// Good - fresh data per test
beforeEach(async () => {
  testOrg = await createTestOrg();  // New org each test
});
```

**When to use each:**

| Hook | Use For |
|------|---------|
| `beforeAll` | Expensive one-time setup (DB connection) |
| `afterAll` | One-time cleanup |
| `beforeEach` | Per-test data setup, mock reset |
| `afterEach` | Per-test cleanup |

**Why it matters:**
- Consistent test environment
- Avoid repeated setup code
- Proper resource cleanup
- Test isolation when done right

Reference: [Vitest Test API](https://vitest.dev/api/#beforeeach)
