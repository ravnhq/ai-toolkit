---
title: Use Fake Timers for Time-Dependent Code
impact: MEDIUM
tags: mocking, timers, time
---

## Use Fake Timers for Time-Dependent Code

Use `vi.useFakeTimers()` to control time in tests involving setTimeout, setInterval, or dates.

**Basic fake timers:**

```typescript
import { vi, test, expect, beforeEach, afterEach } from 'vitest';

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

test('debounces function calls', () => {
  const callback = vi.fn();
  const debounced = debounce(callback, 100);

  debounced();
  debounced();
  debounced();

  expect(callback).not.toHaveBeenCalled();

  vi.advanceTimersByTime(100);

  expect(callback).toHaveBeenCalledTimes(1);
});
```

**Control current date:**

```typescript
test('invitation expires after 7 days', async () => {
  vi.setSystemTime(new Date('2024-01-01'));

  const invitation = await createInvitation({ email: 'test@test.com' });

  expect(invitation.expiresAt).toEqual(new Date('2024-01-08'));
});

test('rejects expired invitation', async () => {
  vi.setSystemTime(new Date('2024-01-01'));
  const invitation = await createInvitation({ email: 'test@test.com' });

  // Advance time past expiration
  vi.setSystemTime(new Date('2024-01-10'));

  await expect(acceptInvitation(invitation.token)).rejects.toThrow('expired');
});
```

**Advance timers:**

```typescript
// Advance by specific time
vi.advanceTimersByTime(1000);  // 1 second

// Run all pending timers
vi.runAllTimers();

// Run only currently pending timers (not newly scheduled)
vi.runOnlyPendingTimers();

// Advance to next timer
vi.advanceTimersToNextTimer();
```

**Clean up fake timers in afterEach:**

```typescript
import { beforeEach, afterEach, test, expect, vi } from 'vitest';

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();  // Critical — reset between tests
});

test('first test with faked time', () => {
  vi.setSystemTime(new Date('2024-01-01'));
  // ...
});

test('second test gets real time again', () => {
  // Time is no longer faked
  expect(new Date()).toBeAfter(new Date('2024-01-01'));
});
```

**Fake timers with modern async/await:**

```typescript
test('async function respects fake timers', async () => {
  vi.useFakeTimers();
  const callback = vi.fn();

  const delayedCall = new Promise(resolve => {
    setTimeout(() => {
      callback();
      resolve(true);
    }, 1000);
  });

  // Advance timers to trigger the setTimeout
  vi.advanceTimersByTime(1000);
  await delayedCall;

  expect(callback).toHaveBeenCalled();
  vi.useRealTimers();
});
```

**Edge case: Promise microtasks before fake timers take effect:**

```typescript
test('microtasks execute before timers advance', async () => {
  vi.useFakeTimers();
  const order: string[] = [];

  Promise.resolve().then(() => order.push('microtask'));
  setTimeout(() => order.push('timer'), 0);

  // Microtasks run first, before advancing timers
  await vi.runAllTimersAsync();

  expect(order).toEqual(['microtask', 'timer']);
  vi.useRealTimers();
});
```

**Why it matters:**
- Tests run instantly instead of waiting for real time
- Deterministic time in tests eliminates race conditions
- Test edge cases like expiration reliably
- Prevent flaky tests from timing issues
- Must reset with `vi.useRealTimers()` to prevent contamination between tests
- Microtasks (Promises) execute before timers advance; order matters for async code

Reference: [Vitest Fake Timers](https://vitest.dev/api/vi.html#vi-usefaketimers)
