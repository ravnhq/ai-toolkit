---
title: Use vi.fn() for Mock Functions
impact: HIGH
tags: mocking, functions, spies
---

## Use vi.fn() for Mock Functions

Use `vi.fn()` to create mock functions that track calls and can return custom values.

**Creating mock functions:**

```typescript
import { vi, expect, test } from 'vitest';

// Basic mock function
const mockFn = vi.fn();
mockFn('arg1', 'arg2');
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2');

// Mock with return value
const mockGetUser = vi.fn().mockReturnValue({ id: '1', name: 'Test' });
const user = mockGetUser();
expect(user.name).toBe('Test');

// Mock with resolved value (async)
const mockFetch = vi.fn().mockResolvedValue({ data: [] });
const result = await mockFetch();
expect(result.data).toEqual([]);

// Mock with implementation
const mockCalc = vi.fn().mockImplementation((a, b) => a + b);
expect(mockCalc(1, 2)).toBe(3);
```

**Asserting on mock calls:**

```typescript
const mockCallback = vi.fn();

// Call the mock
processItems(['a', 'b'], mockCallback);

// Assert call count
expect(mockCallback).toHaveBeenCalledTimes(2);

// Assert specific calls
expect(mockCallback).toHaveBeenNthCalledWith(1, 'a');
expect(mockCallback).toHaveBeenNthCalledWith(2, 'b');

// Assert last call
expect(mockCallback).toHaveBeenLastCalledWith('b');

// Access call arguments directly
expect(mockCallback.mock.calls[0][0]).toBe('a');
```

**Resetting mocks:**

```typescript
beforeEach(() => {
  mockFn.mockClear();      // Clear call history
  mockFn.mockReset();      // Clear history + reset return value
  mockFn.mockRestore();    // Restore original (for spies)
});
```

**Why it matters:**
- Track how functions are called
- Control return values for testing different scenarios
- Verify callback behavior
- Isolate units under test

Reference: [Vitest Mock Functions](https://vitest.dev/api/mock.html)
