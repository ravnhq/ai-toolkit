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

**Dependency array: when effect runs**

```tsx
// Runs on every render (bad - usually wrong)
useEffect(() => {
  subscribeToUpdates();
  // Cleanup runs, resubscribes on every render
});

// Runs once on mount and unmount
useEffect(() => {
  subscribeToUpdates();
  return () => unsubscribe();
}, []); // Empty array = once only

// Runs when dependencies change
useEffect(() => {
  subscribeToUpdates(userId);
  return () => unsubscribe();
}, [userId]); // Resubscribe when userId changes
```

**Common cleanup mistakes:**

```tsx
// BAD: cleanup doesn't execute because dependencies are missing
useEffect(() => {
  const timer = setTimeout(() => console.log(message), 1000);
  // If message changes, old timer is never cleared!
  // Two timers now run
}, []); // message not in deps

// GOOD: include all dependencies
useEffect(() => {
  const timer = setTimeout(() => console.log(message), 1000);
  return () => clearTimeout(timer);
}, [message]); // timer is cleared before new effect runs
```

**React 19: prefer use() + Suspense over useEffect for data:**

Instead of useEffect with loading states, pass promises to components and read them with `use()`:

```tsx
// Old: useEffect in component
function PostList({ userId }: { userId: string }) {
  const [posts, setPosts] = useState([]);

  useEffect(() => {
    fetchPosts(userId).then(setPosts);
  }, [userId]);

  return posts.length ? <ul>{posts.map(...)}</ul> : <div>Loading...</div>;
}

// React 19: pass promise, read with use()
function PostList({ postsPromise }: { postsPromise: Promise<Post[]> }) {
  const posts = use(postsPromise);
  return <ul>{posts.map(...)}</ul>;
}

function PostSection({ userId }: { userId: string }) {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <PostList postsPromise={fetchPosts(userId)} />
    </Suspense>
  );
}
```

**Why it matters:**
- Memory leaks crash the application over time
- Multiple listeners cause duplicate actions
- Stale closures update wrong state
- Missing cleanup causes bugs that only appear on re-render
- Missing dependencies silently cause stale data
- React 19's `use()` eliminates many useEffect patterns entirely

Reference: [Synchronizing with Effects](https://react.dev/learn/synchronizing-with-effects)
Reference: [use() Hook](https://react.dev/reference/react/use)
