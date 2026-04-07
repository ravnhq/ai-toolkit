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

**React 19 Compiler changes the game:**

React 19 introduces an experimental compiler that automatically memoizes components and values. With the compiler enabled, you may not need manual memoization at all:

```tsx
// With React 19 Compiler, this is automatically optimized
// No need to add useMemo/useCallback manually
function UserList({ users }: { users: User[] }) {
  const activeUsers = users.filter(u => u.active); // Auto-memoized
  const handleClick = (id: string) => selectUser(id); // Auto-stable

  return (
    <div>
      {activeUsers.map(user => (
        <UserCard key={user.id} user={user} onClick={handleClick} />
      ))}
    </div>
  );
}

// The compiler understands dependencies and prevents unnecessary re-renders
// Even simpler: just write clean code, let the compiler optimize it
```

**Compiler vs manual memoization:**

| Pattern | Without Compiler | With Compiler (React 19+) |
|---------|------------------|---------------------------|
| Simple calculation | Fast, no overhead | Same speed, zero code |
| Callback stability | Use useCallback | Auto-stable, zero code |
| Child memoization | Use React.memo + useCallback | Auto-memoized, zero code |
| Code clarity | Memoization adds noise | Clean, readable code |

**Strategy: wait for measured problems:**

1. Write clean, simple code without memoization
2. Use React DevTools Profiler to measure actual bottlenecks
3. If memoization is needed (rare with Compiler), add it then
4. Verify improvement with before/after measurements

**Why it matters:**
- Memoization has memory and comparison overhead
- Can make performance worse in simple cases
- Obscures code with unnecessary complexity
- False sense of optimization without measurement
- React 19 Compiler eliminates need for most manual memoization

Reference: [useMemo](https://react.dev/reference/react/useMemo#should-you-add-usememo-everywhere)
Reference: [React 19 Compiler](https://react.dev/blog/2024/12/19/react-19)
