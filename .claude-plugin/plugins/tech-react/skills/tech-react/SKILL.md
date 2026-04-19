---
name: tech-react
description: React 19 patterns for components, hooks, Server Components, and data
  fetching. Use when writing React components, managing state with hooks, implementing
  Suspense boundaries, optimizing renders with proper memoization, or building Server/Client
  component hierarchies.
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: frontend
  extends: platform-frontend
  tags:
  - react
  - hooks
  - components
  - jsx
  - server-components
  - suspense
  - use-hook
  - web
  status: ready
  version: 7
---

# Core Challenges

React patterns evolve with each major version. React 19 introduced the `use()` hook for promise handling and formalized Server Component boundaries with clearer client/server semantics. Common pitfalls include:

- **Hook ordering violations**: Conditionally calling hooks breaks React's tracking system
- **Unnecessary memoization**: useMemo/useCallback/React.memo add overhead without measurement
- **Oversized components**: Mixing Server and Client logic prevents streaming optimization
- **Missing Suspense boundaries**: Async data without Suspense blocks entire render
- **Stale closures**: Effects with incorrect dependency arrays or missing cleanup
- **Key misuse**: Index keys cause state to attach to wrong list items after reorder

React 19 improves these patterns: `use()` hook for consuming promises, Server Components for data fetching without extra requests, and `useTransition()` for non-blocking updates.

## Workflow

1. **Identify component responsibilities**: Determine if component should be Server (data-heavy) or Client (interactive)
2. **Define hooks at top level**: All hooks must execute unconditionally before any returns
3. **Use Suspense for async**: Wrap `use()` hook calls with Suspense boundaries for loading fallback
4. **Compose with keys**: Use stable, unique keys for list items; use key prop to reset component state
5. **Measure before optimizing**: Profile with React DevTools before adding memoization
6. **Clean up subscriptions**: Always return cleanup function from effects that subscribe to systems
7. **Keep components small**: Extract Client Components for interactivity, let Server Components handle data

## Rules

See [rules index](rules/_sections.md) for detailed patterns.

## Examples

### Positive Trigger

User: "Refactor this React component to reduce re-renders and clarify hook usage."

Expected behavior: Use `tech-react` guidance, follow its workflow, and return actionable output.

### Positive Trigger: Server Component Boundary

User: "I'm fetching data on the client with useEffect. How should I refactor this with Server Components?"

Expected behavior: Move data fetch to Server Component, pass promise to Client Component via `use()` hook, wrap with Suspense boundary.

### Non-Trigger

User: "Write a Bash script to package release artifacts."

Expected behavior: Do not prioritize `tech-react`; choose a more relevant skill or proceed without it.

## Troubleshooting

### Hook Call Violations ("Rendered more hooks than during the previous render")

- Error: React throws "Rendered fewer/more hooks than during the previous render"
- Cause: Hooks called inside conditions, loops, or early returns
- Solution: Move hook calls before any conditional logic; use `enabled` option in data hooks to skip execution

### Suspense Fallback Never Shows

- Error: Loading fallback doesn't appear when `use()` suspends
- Cause: Suspense boundary is not wrapping the component that calls `use()`
- Solution: Ensure `<Suspense>` is a parent of the component, not a sibling

### Server Component Can't Use State/Events

- Error: useState, onClick handlers don't work in Server Components
- Cause: Server Components render once on server; they can't respond to client interaction
- Solution: Extract interactive parts to Client Components with "use client" directive; Server Component handles data fetching and passes to Client Component

### useEffect Runs Twice or Creates Memory Leaks

- Error: Effect side effect runs multiple times; cleanup doesn't execute
- Cause: Missing dependency array or missing cleanup return function
- Solution: Include dependency array; return cleanup function for subscriptions/timers/listeners

### List Items Lose Focus or Appear in Wrong Order

- Error: Input focus jumps between rows; items appear shuffled after sort
- Cause: Using array index as key instead of stable unique identifier
- Solution: Change `key={index}` to `key={item.id}` with unique property from data

## Examples: Error Patterns

### Error 1: Conditional Hook

**Incorrect:**

```tsx
function UserProfile({ userId }: { userId: string | null }) {
  if (!userId) {
    return <div>Select a user</div>;
  }

  // Hook called conditionally - React can't track it!
  const [profile, setProfile] = useState(null);
  return <div>{profile?.name}</div>;
}
```

**Correct:**

```tsx
function UserProfile({ userId }: { userId: string | null }) {
  const [profile, setProfile] = useState(null);

  // Early return AFTER hooks
  if (!userId) {
    return <div>Select a user</div>;
  }

  return <div>{profile?.name}</div>;
}
```

### Error 2: Suspense Without use() Hook

**Incorrect:**

```tsx
function Comments({ id }: { id: string }) {
  const [comments, setComments] = useState([]);

  useEffect(() => {
    fetchComments(id).then(setComments);
  }, [id]);

  return <ul>{comments.map(c => <li key={c.id}>{c.text}</li>)}</ul>;
}
```

**Correct:**

```tsx
function Comments({ commentsPromise }: { commentsPromise: Promise<Comment[]> }) {
  const comments = use(commentsPromise);
  return <ul>{comments.map(c => <li key={c.id}>{c.text}</li>)}</ul>;
}

function CommentsSection({ id }: { id: string }) {
  return (
    <Suspense fallback={<div>Loading comments...</div>}>
      <Comments commentsPromise={fetchComments(id)} />
    </Suspense>
  );
}
```

### Error 3: Server/Client Boundary Confusion

**Incorrect:**

```tsx
// BAD: Server Component with useState
async function NotesPage() {
  const [selectedNote, setSelectedNote] = useState(null); // ERROR: Can't use state
  const notes = await db.notes.getAll();

  return (
    <div>
      {notes.map(note => (
        <button onClick={() => setSelectedNote(note)}>
          {note.title}
        </button>
      ))}
    </div>
  );
}
```

**Correct:**

```tsx
// Server Component - fetch data
async function NotesPage() {
  const notes = await db.notes.getAll();

  return (
    <div>
      <NotesList notes={notes} />
    </div>
  );
}

// Client Component - handle interaction
"use client";

function NotesList({ notes }: { notes: Note[] }) {
  const [selectedNote, setSelectedNote] = useState<Note | null>(null);

  return (
    <div>
      {notes.map(note => (
        <button
          key={note.id}
          onClick={() => setSelectedNote(note)}
        >
          {note.title}
        </button>
      ))}
    </div>
  );
}
```
