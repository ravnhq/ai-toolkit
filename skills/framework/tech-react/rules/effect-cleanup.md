---
title: Clean Up Effects That Set Up Subscriptions
impact: HIGH
tags: effect, memory-leak, cleanup
---

## Clean Up Effects That Set Up Subscriptions

Effects that subscribe to external systems must clean up to prevent memory leaks.

**Incorrect (no cleanup):**

```tsx
// Bad - memory leak!
useEffect(() => {
  const handler = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      onClose();
    }
  };
  window.addEventListener('keydown', handler);
  // Never cleaned up - handler accumulates on every render!
}, [onClose]);

// Bad - subscription without cleanup
useEffect(() => {
  const subscription = dataSource.subscribe(setData);
  // Subscription never canceled!
}, []);
```

**Correct (with cleanup):**

```tsx
// Good - cleanup function
useEffect(() => {
  const handler = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      onClose();
    }
  };
  window.addEventListener('keydown', handler);

  // Cleanup runs before next effect and on unmount
  return () => {
    window.removeEventListener('keydown', handler);
  };
}, [onClose]);

// Good - cancel subscription
useEffect(() => {
  const subscription = dataSource.subscribe(setData);

  return () => {
    subscription.unsubscribe();
  };
}, []);

// Good - abort fetch on cleanup
useEffect(() => {
  const controller = new AbortController();

  fetch(url, { signal: controller.signal })
    .then(res => res.json())
    .then(setData)
    .catch(err => {
      if (err.name !== 'AbortError') throw err;
    });

  return () => controller.abort();
}, [url]);
```

**Things that need cleanup:**

- Event listeners
- Subscriptions (WebSocket, observables)
- Timers (setTimeout, setInterval)
- Fetch requests (AbortController)

**Why it matters:**
- Memory leaks crash the application over time
- Multiple listeners cause duplicate actions
- Stale closures update wrong state

Reference: [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)
