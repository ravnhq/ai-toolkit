---
title: Use vi.spyOn() to Spy on Methods
impact: MEDIUM
tags: mocking, spies, methods
---

## Use vi.spyOn() to Spy on Methods

Use `vi.spyOn()` to watch method calls while optionally keeping the real implementation.

**Spy on object method:**

```typescript
import { vi, test, expect } from 'vitest';

const calculator = {
  add: (a: number, b: number) => a + b,
  multiply: (a: number, b: number) => a * b,
};

test('tracks method calls', () => {
  const spy = vi.spyOn(calculator, 'add');

  const result = calculator.add(2, 3);

  expect(result).toBe(5);  // Real implementation runs
  expect(spy).toHaveBeenCalledWith(2, 3);
  expect(spy).toHaveBeenCalledTimes(1);
});
```

**Spy and mock return value:**

```typescript
test('can override return value', () => {
  const spy = vi.spyOn(calculator, 'add').mockReturnValue(100);

  const result = calculator.add(2, 3);

  expect(result).toBe(100);  // Mocked value
  expect(spy).toHaveBeenCalledWith(2, 3);
});
```

**Spy on console methods:**

```typescript
test('logs error message', () => {
  const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

  processInvalidData();

  expect(consoleSpy).toHaveBeenCalledWith('Invalid data');

  consoleSpy.mockRestore();  // Clean up
});
```

**Spy vs vi.fn():**

| Use Case | Tool |
|----------|------|
| Mock standalone function | `vi.fn()` |
| Watch object method | `vi.spyOn()` |
| Replace module export | `vi.mock()` |
| Keep real behavior + track | `vi.spyOn()` (no mock impl) |

**Why it matters:**
- Track calls without changing behavior
- Verify logging, analytics, side effects
- Easier cleanup with mockRestore()
- Works with existing objects and classes

Reference: [Vitest spyOn](https://vitest.dev/api/vi.html#vi-spyon)
