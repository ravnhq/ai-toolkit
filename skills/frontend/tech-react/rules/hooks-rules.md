---
title: Follow the Rules of Hooks
impact: CRITICAL
tags: hooks, correctness, fundamentals
---

## Follow the Rules of Hooks

Hooks must be called at the top level, not inside conditions, loops, or nested functions.

**Incorrect (conditional hook calls):**

```tsx
// Bad - hook inside condition
function UserProfile({ userId }: { userId: string | null }) {
  if (!userId) {
    return <div>No user selected</div>;
  }

  // ERROR: Hook called conditionally!
  const { data } = useQuery({ queryKey: ['user', userId], ... });

  return <div>{data?.name}</div>;
}

// Bad - hook inside loop
function UserList({ userIds }: { userIds: string[] }) {
  return userIds.map(id => {
    // ERROR: Hook inside map callback!
    const { data } = useQuery({ queryKey: ['user', id], ... });
    return <div key={id}>{data?.name}</div>;
  });
}
```

**Correct (hooks at top level):**

```tsx
// Good - early return AFTER hooks
function UserProfile({ userId }: { userId: string | null }) {
  const { data } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId!),
    enabled: !!userId, // Query only runs when userId is truthy
  });

  if (!userId) {
    return <div>No user selected</div>;
  }

  return <div>{data?.name}</div>;
}

// Good - separate component for each item
function UserList({ userIds }: { userIds: string[] }) {
  return userIds.map(id => (
    <UserCard key={id} userId={id} />
  ));
}

function UserCard({ userId }: { userId: string }) {
  const { data } = useQuery({ queryKey: ['user', userId], ... });
  return <div>{data?.name}</div>;
}
```

**The Rules:**

1. Only call hooks at the top level
2. Only call hooks from React functions (components or custom hooks)

**Why it matters:**
- React relies on call order to track hook state
- Conditional hooks break React's internal tracking
- Results in cryptic bugs and stale state

Reference: [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
