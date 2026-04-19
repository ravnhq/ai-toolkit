---
title: Establish Clear Server/Client Component Boundaries
impact: HIGH
tags: server-components, use-client, data-fetching, architecture
---

## Establish Clear Server/Client Component Boundaries

Server Components fetch data on the server and pass results to Client Components. Client Components handle interaction. Mark client-only code with `"use client"` and keep Server Components at the top of the tree.

**Incorrect (mixing Server and Client concerns):**

```tsx
// BAD: Server Component trying to use hooks
async function ProfilePage() {
  // Can't use hooks or event handlers in Server Components
  const [expanded, setExpanded] = useState(false); // ERROR
  const [user, setUser] = useState(null); // ERROR

  const user = await db.user.get(id);

  return (
    <div>
      <button onClick={() => setExpanded(!expanded)}> {/* ERROR: onClick in Server */}
        Toggle Details
      </button>
      {expanded && <div>{user.bio}</div>}
    </div>
  );
}
```

**Correct (Server fetches, Client interacts):**

```tsx
// Server Component - fetch data, compose layout
async function ProfilePage({ userId }: { userId: string }) {
  const user = await db.user.get(userId);
  const posts = await db.posts.byUser(userId);

  return (
    <div>
      <header>
        <h1>{user.name}</h1>
        <p>{user.bio}</p>
      </header>

      {/* Pass data to Client Component for interaction */}
      <ProfileActions userId={userId} postCount={posts.length} />

      {/* Server Component can handle rendering lists */}
      <ul>
        {posts.map(post => (
          <li key={post.id}>{post.title}</li>
        ))}
      </ul>
    </div>
  );
}

// Client Component - handles interaction only
"use client";

function ProfileActions({ userId, postCount }: {
  userId: string;
  postCount: number;
}) {
  const [liked, setLiked] = useState(false);

  return (
    <div>
      <button onClick={() => setLiked(!liked)}>
        {liked ? 'Liked' : 'Like'} ({postCount})
      </button>
    </div>
  );
}
```

**Pattern: Server fetches, Client renders interactive children:**

```tsx
// Server Component
async function Dashboard() {
  const notifications = await db.notifications.recent();
  const userData = await db.user.current();

  return (
    <div className="dashboard">
      <NavigationBar user={userData} />

      {/* Pass promise for progressive rendering */}
      <Suspense fallback={<div>Loading stats...</div>}>
        <NotificationCenter notificationsPromise={Promise.resolve(notifications)} />
      </Suspense>
    </div>
  );
}

// Client Component - handles notifications UI
"use client";

function NotificationCenter({ notificationsPromise }: {
  notificationsPromise: Promise<Notification[]>;
}) {
  const [expanded, setExpanded] = useState(false);
  const notifications = use(notificationsPromise);

  return (
    <div>
      <button onClick={() => setExpanded(!expanded)}>
        Notifications ({notifications.length})
      </button>
      {expanded && (
        <ul>
          {notifications.map(n => (
            <li key={n.id} onClick={() => markRead(n.id)}>
              {n.message}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

**Mistake: passing promises through many layers:**

```tsx
// BAD: Promise threading through many components
async function Page() {
  const dataPromise = fetchData();
  return <Layout><Content><Display dataPromise={dataPromise} /></Display></Content></Layout>;
}

// GOOD: Fetch at the boundary, pass resolved data
async function Page() {
  const data = await fetchData();
  return <Layout><Content><Display data={data} /></Display></Content></Layout>;
}

// Or: use Suspense for granular loading
async function Page() {
  const dataPromise = fetchData();
  return (
    <Layout>
      <Content>
        <Suspense fallback={<div>Loading...</div>}>
          <Display dataPromise={dataPromise} />
        </Suspense>
      </Content>
    </Layout>
  );
}
```

**Decision tree: Server vs Client Component:**

```
Is the component doing any of these?
├─ Fetching data from DB/API? → Server Component
├─ Using hooks (useState, useEffect)? → Client Component
├─ Using browser APIs (localStorage, canvas)? → Client Component
├─ Using event handlers (onClick, onChange)? → Client Component
├─ Rendering static content? → Server Component (better for SEO)
├─ Passing props to Client Components? → Server Component
└─ Using a framework that requires Client (forms, charts)? → Client Component
```

**Common pitfall: Server Component tree must be at root:**

```tsx
// BAD: Can't wrap Server Component with Client
"use client";

function ClientWrapper() {
  // This entire subtree is now Client-side
  return <ServerComponent />; // Won't work - Server code can't run here
}

// GOOD: Server Component at top level
async function App() {
  return (
    <ServerComponent /> {/* Runs on server */}
  );
}

// Client boundary somewhere inside
function ServerComponent() {
  const user = await db.user.current();

  return (
    <div>
      <ClientInteractiveArea user={user} /> {/* Client Component inside Server */}
    </div>
  );
}

"use client";

function ClientInteractiveArea({ user }: { user: User }) {
  const [expanded, setExpanded] = useState(false);
  // Hooks work here
}
```

**Pattern: Progressive data loading with Suspense:**

```tsx
// Server Component starts multiple fetches at boundary
async function ProductPage({ id }: { id: string }) {
  // Critical: load immediately
  const product = await db.products.get(id);

  // Non-critical: load in background
  const reviewsPromise = db.reviews.byProduct(id);
  const relatedPromise = db.products.related(id);

  return (
    <div>
      <ProductHeader product={product} />

      {/* Stream reviews separately */}
      <Suspense fallback={<div>Loading reviews...</div>}>
        <ReviewSection reviewsPromise={reviewsPromise} />
      </Suspense>

      {/* Stream related products separately */}
      <Suspense fallback={<div>Loading related...</div>}>
        <RelatedProducts relatedPromise={relatedPromise} />
      </Suspense>
    </div>
  );
}

// Client Component consumes promise
"use client";

function ReviewSection({ reviewsPromise }: { reviewsPromise: Promise<Review[]> }) {
  const reviews = use(reviewsPromise);
  const [sortBy, setSortBy] = useState<'recent' | 'helpful'>('recent');

  const sorted = sortBy === 'recent'
    ? reviews.sort((a, b) => b.date - a.date)
    : reviews.sort((a, b) => b.helpfulCount - a.helpfulCount);

  return (
    <div>
      <select value={sortBy} onChange={e => setSortBy(e.target.value as 'recent' | 'helpful')}>
        <option value="recent">Recent</option>
        <option value="helpful">Most Helpful</option>
      </select>
      <ul>{sorted.map(r => <li key={r.id}>{r.text}</li>)}</ul>
    </div>
  );
}
```

**Why it matters:**
- Server Components eliminate data fetching round-trips from client
- Reduces JavaScript sent to browser (less bundle size)
- Database queries run on server, never exposed to client
- Clearer architecture: data layer on server, UI layer on client
- "use client" boundaries are explicit - easier to understand code flow
- Suspense at boundaries enables streaming and progressive rendering
- Server Components enable better SEO (rendered on server before sending HTML)

Reference: [Server Components](https://react.dev/reference/rsc/server-components)
Reference: [use() Hook](https://react.dev/reference/react/use)
Reference: [Suspense for Data Fetching](https://react.dev/reference/react/Suspense)
