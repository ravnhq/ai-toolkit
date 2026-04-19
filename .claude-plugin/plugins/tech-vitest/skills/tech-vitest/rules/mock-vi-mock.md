---
title: Use vi.mock() for Module Mocking
impact: HIGH
tags: mocking, modules, imports
---

## Use vi.mock() for Module Mocking

Use `vi.mock()` to replace entire modules with mock implementations.

**Basic module mock:**

```typescript
import { vi, test, expect } from 'vitest';
import { sendEmail } from './email-service';
import { createUser } from './user-service';

// Mock the entire module
vi.mock('./email-service', () => ({
  sendEmail: vi.fn().mockResolvedValue({ id: 'email_123' }),
}));

test('creates user and sends welcome email', async () => {
  await createUser({ email: 'test@test.com' });

  expect(sendEmail).toHaveBeenCalledWith(
    expect.objectContaining({ to: 'test@test.com' })
  );
});
```

**Auto-mocking with vi.mock():**

```typescript
// Auto-mock all exports
vi.mock('./email-service');

// All exports become vi.fn()
import { sendEmail, sendSms } from './email-service';
// sendEmail and sendSms are now mock functions
```

**Partial mock (keep some real implementations):**

```typescript
vi.mock('./utils', async () => {
  const actual = await vi.importActual('./utils');
  return {
    ...actual,
    // Only mock this one function
    fetchData: vi.fn().mockResolvedValue({ data: [] }),
  };
});
```

**Important: vi.mock is hoisted:**

```typescript
// vi.mock is hoisted to top of file
// This runs BEFORE imports!
vi.mock('./db');

import { db } from './db'; // Already mocked
```

**Reset between tests:**

```typescript
import { sendEmail } from './email-service';

beforeEach(() => {
  vi.mocked(sendEmail).mockClear();
});
```

**Why it matters:**
- Isolate tests from external dependencies
- Control module behavior for different scenarios
- Mock network requests, file system, etc.
- Speed up tests by avoiding real implementations

Reference: [Vitest Mocking Modules](https://vitest.dev/guide/mocking.html#modules)
