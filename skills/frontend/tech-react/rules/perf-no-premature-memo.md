---
title: Don't Add useMemo/useCallback Preemptively
impact: MEDIUM
tags: performance, memoization, optimization
---

## Don't Add useMemo/useCallback Preemptively

Memoization has overhead. Don't add useMemo, useCallback, or React.memo without measuring.

**Incorrect (premature memoization):**

```tsx
// Bad - memoizing everything "just in case"
function UserList({ users }: { users: User[] }) {
  // Unnecessary - simple filter is fast
  const activeUsers = useMemo(
    () => users.filter(u => u.active),
    [users]
  );

  // Unnecessary - no child with memo depends on this
  const handleClick = useCallback(
    (id: string) => selectUser(id),
    [selectUser]
  );

  // Unnecessary - renders same content
  const items = useMemo(
    () => activeUsers.map(u => <UserCard key={u.id} user={u} />),
    [activeUsers]
  );

  return <div>{items}</div>;
}
```

**Correct (optimize when needed):**

```tsx
// Good - simple first
function UserList({ users }: { users: User[] }) {
  const activeUsers = users.filter(u => u.active);

  function handleClick(id: string) {
    selectUser(id);
  }

  return (
    <div>
      {activeUsers.map(user => (
        <UserCard key={user.id} user={user} onClick={handleClick} />
      ))}
    </div>
  );
}

// Later, IF profiling shows performance issues:
// 1. Identify what's actually slow
// 2. Add memoization to specific bottlenecks
// 3. Verify it actually helps
```

**When memoization helps:**

- Expensive calculations (>1ms)
- Referential equality for memo'd children
- Context value stability
- Measured performance problem

**Why it matters:**
- Memoization has memory and comparison overhead
- Can make performance worse in simple cases
- Obscures code with unnecessary complexity
- False sense of optimization without measurement

Reference: [useMemo](https://react.dev/reference/react/useMemo#should-you-add-usememo-everywhere)
