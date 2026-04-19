---
title: Components Should Do One Thing
impact: HIGH
tags: component, design, maintainability
---

## Components Should Do One Thing

Each component should have a single responsibility. Split large components into focused pieces.

**Incorrect (component does too much):**

```typescript
// Bad - fetching, form handling, display, and actions in one component
function UserPage() {
  const [user, setUser] = useState(null);
  const [formData, setFormData] = useState({});
  const [isEditing, setIsEditing] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => { fetchUser(); }, []);

  async function fetchUser() { /* ... */ }
  async function saveUser() { /* ... */ }
  function handleChange() { /* ... */ }

  if (!user) return <Loading />;

  return (
    <div>
      <header>{/* navigation, breadcrumbs */}</header>
      <aside>{/* user stats, actions */}</aside>
      <main>
        {isEditing ? (
          <form>{/* 20 form fields */}</form>
        ) : (
          <div>{/* user display */}</div>
        )}
      </main>
      {/* modal, toast, etc */}
    </div>
  );
}
```

**Correct (split by responsibility):**

```typescript
// Good - orchestration component
function UserPage() {
  const { data: user, isLoading } = useUser();

  if (isLoading) return <PageLoader />;
  if (!user) return <NotFound />;

  return (
    <PageLayout>
      <UserHeader user={user} />
      <UserContent user={user} />
    </PageLayout>
  );
}

// Display component
function UserHeader({ user }) {
  return (
    <header>
      <Avatar user={user} />
      <h1>{user.name}</h1>
    </header>
  );
}

// Form component
function UserEditForm({ user, onSave }) {
  const form = useForm({ defaultValues: user });
  // Form logic isolated here
}
```

**Signs a component is too big:**

- Multiple useState calls (5+)
- Multiple useEffect calls
- Hard to name (does X and Y and Z)
- Over 200 lines

**Why it matters:**
- Small components are easier to test
- Bugs are isolated to specific components
- Easier to reuse pieces
- Faster to understand when debugging
