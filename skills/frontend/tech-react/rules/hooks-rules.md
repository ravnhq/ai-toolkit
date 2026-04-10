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

**Enabling conditional logic without breaking hook rules:**

Use hook options like `enabled` instead of conditionally calling hooks:

```tsx
// Good - hook always called, but skips execution when disabled
function SearchResults({ query }: { query: string | null }) {
  // Always call the hook at top level
  const { data, isLoading } = useQuery({
    queryKey: ['search', query],
    queryFn: () => search(query!),
    enabled: query !== null, // Query skips when null
  });

  if (!query) {
    return <div>Enter a search term</div>;
  }

  return <div>{isLoading ? 'Loading...' : data?.results}</div>;
}
```

**Hook dependencies and stale closures:**

Always include all values from component scope that the hook uses in the dependency array:

```tsx
// Bad - missing userId in dependencies
useEffect(() => {
  const handler = () => fetchUser(userId); // stale closure!
  window.addEventListener('scroll', handler);
  return () => window.removeEventListener('scroll', handler);
}, []); // userId missing!

// Good - userId in dependencies
useEffect(() => {
  const handler = () => fetchUser(userId);
  window.addEventListener('scroll', handler);
  return () => window.removeEventListener('scroll', handler);
}, [userId]); // Properly tracked
```

**React 19: prefer use() over useEffect for promises:**

The new `use()` hook reads promise values during render and automatically suspends:

```tsx
// Old pattern (useEffect + loading state)
function Comments({ id }: { id: string }) {
  const [comments, setComments] = useState([]);
  useEffect(() => {
    fetchComments(id).then(setComments);
  }, [id]);
  return <div>{comments.map(c => <p key={c.id}>{c.text}</p>)}</div>;
}

// React 19 pattern (use + Suspense)
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);
  return <div>{comments.map(c => <p key={c.id}>{c.text}</p>)}</div>;
}

function CommentsSection({ id }: { id: string }) {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Comments commentsPromise={fetchComments(id)} />
    </Suspense>
  );
}
```

**Why it matters:**
- React relies on call order to track hook state
- Conditional hooks break React's internal tracking
- Missing dependencies cause stale closures and bugs
- Results in cryptic errors: "Rendered fewer hooks than during the previous render"
- React 19's `use()` hook simplifies async data without useEffect chains

Reference: [Rules of Hooks](https://react.dev/reference/rules/rules-of-hooks)
Reference: [use() Hook](https://react.dev/reference/react/use)
