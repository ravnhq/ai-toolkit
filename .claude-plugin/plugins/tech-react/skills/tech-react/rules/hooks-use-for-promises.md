---
title: Use use() Hook for Consuming Promises in React 19
impact: HIGH
tags: hooks, promises, suspense, async, react-19
---

## Use use() Hook for Consuming Promises in React 19

The new `use()` hook (React 19) consumes promises and suspends rendering until they resolve. Use it instead of useEffect + useState for async data. Always wrap with Suspense boundaries.

**Incorrect (useEffect pattern — outdated in React 19):**

```tsx
// Bad - useEffect chain for data fetching
function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setLoading(true);
    fetchUser(userId)
      .then(setUser)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [userId]);

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  return <div>{user?.name}</div>;
}
```

**Correct (use() hook with Suspense and ErrorBoundary):**

```tsx
// Good - use() hook for promise consumption
function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  return <div>{user.name}</div>;
}

function UserSection({ userId }: { userId: string }) {
  return (
    <ErrorBoundary fallback={<div>Error loading user</div>}>
      <Suspense fallback={<div>Loading...</div>}>
        <UserProfile userPromise={fetchUser(userId)} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

**use() with multiple promises:**

```tsx
// Pass multiple promises as object
function PostWithComments({ postPromise, commentsPromise }: {
  postPromise: Promise<Post>;
  commentsPromise: Promise<Comment[]>;
}) {
  const post = use(postPromise);
  const comments = use(commentsPromise);

  return (
    <div>
      <h1>{post.title}</h1>
      <ul>
        {comments.map(c => <li key={c.id}>{c.text}</li>)}
      </ul>
    </div>
  );
}

function PostSection({ postId }: { postId: string }) {
  return (
    <Suspense fallback={<div>Loading post...</div>}>
      <PostWithComments
        postPromise={fetchPost(postId)}
        commentsPromise={fetchComments(postId)}
      />
    </Suspense>
  );
}
```

**Server Component passing promises to Client Component:**

```tsx
// Server Component - fetch data, pass promise
async function NotesPage() {
  // Fetch critical data on server
  const notes = await db.notes.getAll();

  // Pass less-critical data as promise to client
  const commentsPromise = db.comments.getAll();

  return (
    <div>
      <NotesList notes={notes} />
      <Suspense fallback={<div>Loading comments...</div>}>
        <CommentsList commentsPromise={commentsPromise} />
      </Suspense>
    </div>
  );
}

// Client Component - consume promise with use()
"use client";

function CommentsList({ commentsPromise }: {
  commentsPromise: Promise<Comment[]>;
}) {
  const comments = use(commentsPromise);
  return <ul>{comments.map(c => <li key={c.id}>{c.text}</li>)}</ul>;
}
```

**use() with error handling via ErrorBoundary:**

```tsx
import { use, Suspense } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

function DataDisplay({ dataPromise }: { dataPromise: Promise<Data> }) {
  const data = use(dataPromise);
  return <div>{data.value}</div>;
}

function Section({ dataPromise }: { dataPromise: Promise<Data> }) {
  return (
    <ErrorBoundary
      fallback={<div>⚠️ Failed to load data. Try again.</div>}
      onError={(error) => console.error('Data fetch error:', error)}
    >
      <Suspense fallback={<div>Loading data...</div>}>
        <DataDisplay dataPromise={dataPromise} />
      </Suspense>
    </ErrorBoundary>
  );
}
```

**Conditional use() based on component logic:**

```tsx
// Use is called during render, so it can't be conditional
// But you can structure components conditionally
function UserOrNull({ userIdOrNull }: { userIdOrNull: string | null }) {
  if (!userIdOrNull) {
    return <div>No user selected</div>;
  }

  // Now we can safely use() because userIdOrNull is definitely a string
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <UserDetails userPromise={fetchUser(userIdOrNull)} />
    </Suspense>
  );
}

function UserDetails({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise);
  return <div>{user.name}</div>;
}
```

**Pattern: Server Component initiates promise, Client consumes:**

```tsx
// Server Component
async function Dashboard() {
  const userId = getCurrentUserId(); // Server-only

  // Start fetching before rendering client component
  const statsPromise = fetchUserStats(userId); // Not awaited

  return (
    <div>
      <header>Dashboard</header>
      <Suspense fallback={<div>Loading stats...</div>}>
        <StatsPanel statsPromise={statsPromise} />
      </Suspense>
    </div>
  );
}

// Client Component
"use client";

function StatsPanel({ statsPromise }: { statsPromise: Promise<Stats> }) {
  const stats = use(statsPromise);
  return (
    <div>
      <p>Views: {stats.views}</p>
      <p>Clicks: {stats.clicks}</p>
    </div>
  );
}
```

**Why it matters:**
- `use()` eliminates verbose useEffect + useState + loading state patterns
- Server Components can start fetching before passing to Client Components
- Suspense boundaries handle loading UI declaratively
- Error boundaries handle promise rejections naturally
- Separates data fetching (Server) from interaction (Client)
- Reduces code complexity for async data by 50%+
- React 19's foundation for building faster, cleaner UIs

Reference: [use() Hook](https://react.dev/reference/react/use)
Reference: [Suspense for Data Fetching](https://react.dev/reference/react/Suspense)
Reference: [Server Components](https://react.dev/reference/rsc/server-components)
