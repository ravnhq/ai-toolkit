---
title: Handle Loading, Error, and Empty States
impact: MEDIUM
tags: data, ux, error-handling
---

## Handle Loading, Error, and Empty States

Every data fetch has three states beyond success: loading, error, and empty. Handle all of them.

**Incorrect (only handles success):**

```typescript
// Bad - crashes or shows nothing for other states
function UserList() {
  const { data: users } = useQuery(['users'], fetchUsers);

  return (
    <ul>
      {users.map(user => <li key={user.id}>{user.name}</li>)}
    </ul>
  );
  // What if loading? Error? Empty array?
}
```

**Correct (all states handled):**

```typescript
function UserList() {
  const { data: users, isLoading, error } = useQuery(['users'], fetchUsers);

  // Loading state
  if (isLoading) {
    return <UserListSkeleton />;
  }

  // Error state
  if (error) {
    return (
      <ErrorState
        message="Failed to load users"
        retry={() => refetch()}
      />
    );
  }

  // Empty state
  if (!users || users.length === 0) {
    return (
      <EmptyState
        icon={<Users />}
        title="No users yet"
        description="Users will appear here once they sign up."
        action={<Button>Invite Users</Button>}
      />
    );
  }

  // Success state
  return (
    <ul>
      {users.map(user => <li key={user.id}>{user.name}</li>)}
    </ul>
  );
}
```

**State checklist:**

| State | Show |
|-------|------|
| Loading | Skeleton, spinner, or placeholder |
| Error | Error message + retry action |
| Empty | Helpful message + next action |
| Success | The actual content |

**Why it matters:**
- Loading: Users know something is happening
- Error: Users can retry instead of staring at blank screen
- Empty: Users know it's not broken, just empty
- Good UX builds trust in your application
