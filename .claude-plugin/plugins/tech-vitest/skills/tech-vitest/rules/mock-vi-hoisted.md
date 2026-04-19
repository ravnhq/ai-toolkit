---
title: Hoist Mock Variables with vi.hoisted()
impact: HIGH
tags: mocking, hoisting, module-mock, scope
---

## Hoist Mock Variables with vi.hoisted()

Use `vi.hoisted()` to define variables that can be referenced inside `vi.mock()` factory functions. Because `vi.mock()` is hoisted to the top of the file, variables defined outside its scope are inaccessible. `vi.hoisted()` solves this by defining shared mock state at the module level.

**Problem: variable not accessible in vi.mock factory**

```typescript
// BAD — mockData is not accessible inside vi.mock
const mockData = { id: '123', name: 'Test User' };

vi.mock('./api', () => ({
  fetchUser: vi.fn().mockResolvedValue(mockData), // ReferenceError
}));

import { fetchUser } from './api';

test('fetches user', async () => {
  const user = await fetchUser('123');
  expect(user.name).toBe('Test User');
});
```

**Solution: wrap shared state in vi.hoisted()**

```typescript
// GOOD — mockData defined in hoisted scope
const { mockData, mockFetch } = vi.hoisted(() => {
  return {
    mockData: { id: '123', name: 'Test User' },
    mockFetch: vi.fn(),
  };
});

vi.mock('./api', () => ({
  fetchUser: mockFetch.mockResolvedValue(mockData),
}));

import { fetchUser } from './api';

test('fetches user', async () => {
  const user = await fetchUser('123');
  expect(user.name).toBe('Test User');
  expect(mockFetch).toHaveBeenCalledWith('123');
});
```

**Hoisting with conditional mock state:**

```typescript
// Define mocks that can change per test
const { mockConfig } = vi.hoisted(() => {
  return {
    mockConfig: { enabled: true, timeout: 5000 },
  };
});

vi.mock('./config', () => ({
  getConfig: vi.fn(() => mockConfig),
}));

import { getConfig } from './config';

test('returns default config', () => {
  expect(getConfig()).toEqual({ enabled: true, timeout: 5000 });
});

test('respects custom config', () => {
  mockConfig.timeout = 10000;
  expect(getConfig().timeout).toBe(10000);
});
```

**Hoisting with vi.fn() spy setup:**

```typescript
const { mockLogger, mockHandler } = vi.hoisted(() => {
  return {
    mockLogger: vi.fn(),
    mockHandler: vi.fn(),
  };
});

vi.mock('./logger', () => ({
  log: mockLogger,
}));

vi.mock('./handler', () => ({
  handle: mockHandler.mockResolvedValue({ success: true }),
}));

import { log } from './logger';
import { handle } from './handler';

test('logs on success', async () => {
  await handle({ id: '1' });
  expect(mockLogger).toHaveBeenCalledWith('Handled: {"id":"1"}');
});
```

**Why it matters:**
- Enables shared mock state between test scope and hoisted `vi.mock()` factories
- Avoids `ReferenceError` when mocks need variables from the test file
- Allows per-test mock customization (change return values, verify calls)
- Keeps mock setup declarative at the top of the file
- Works with `vi.fn()`, `mockResolvedValue()`, and other mock configuration

Reference: [Vitest vi.hoisted](https://vitest.dev/api/vi.html#vi-hoisted)
