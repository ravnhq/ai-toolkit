---
title: Use Real Database for Integration Tests
impact: MEDIUM
tags: mocking, database, integration
---

## Use Real Database for Integration Tests

Test against a real database, not mocks or in-memory fakes. Schema differences cause false positives.

**Incorrect (mocked/fake database):**

```typescript
// Bad - in-memory fake doesn't match production behavior
const mockDb = {
  users: new Map(),
  findUser: (id) => mockDb.users.get(id),
  createUser: (data) => {
    mockDb.users.set(data.id, data);
    return data;
  },
};

// This passes but real DB might fail on:
// - Unique constraints
// - Foreign key violations
// - Type coercion differences
// - Transaction behavior
```

**Correct (real test database):**

```typescript
// Good - real PostgreSQL database
// docker-compose.test.yml
// services:
//   test-db:
//     image: postgres:16

// test/setup.ts
const testDbUrl = process.env.TEST_DATABASE_URL;
export const testDb = drizzle(postgres(testDbUrl));

// Tests use real database
test('enforces unique email constraint', async () => {
  await testDb.insert(users).values({
    id: 'user-1',
    email: 'test@test.com',
  });

  // Real database will throw constraint violation
  await expect(
    testDb.insert(users).values({
      id: 'user-2',
      email: 'test@test.com', // duplicate
    })
  ).rejects.toThrow(/unique/i);
});
```

**Test database setup:**

```yaml
# docker-compose.test.yml
services:
  test-db:
    image: postgres:16
    environment:
      POSTGRES_DB: app_test
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
    ports:
      - "5433:5432"
    # Disable durability for speed (never in prod!)
    command: postgres -c fsync=off -c full_page_writes=off
```

**Why it matters:**
- SQLite behaves differently than PostgreSQL
- Constraint violations only surface with real DB
- Transaction semantics differ
- Data type handling varies between databases
