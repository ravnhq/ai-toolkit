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

**Why it matters:**
- Tests run instantly instead of waiting
- Deterministic time in tests
- Test edge cases like expiration
- No flaky tests from timing issues

Reference: [Vitest Fake Timers](https://vitest.dev/api/vi.html#vi-usefaketimers)
