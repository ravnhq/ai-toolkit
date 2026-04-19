---
title: Don't Use Mutation Callbacks
impact: HIGH
tags: tanstack-query, mutations, deprecation
---

## Don't Use Mutation Callbacks

Do NOT use `onSuccess`, `onError`, or `onSettled` callbacks in TanStack Query mutations. Handle responses at the call site.

**Incorrect (deprecated callbacks):**

```tsx
// Bad - callbacks are deprecated and will be removed in v6
const mutation = useMutation({
  mutationFn: async (data) => api.createUser(data),
  onSuccess: (data) => {
    toast.success('User created!');
    navigate(`/users/${data.id}`);
  },
  onError: (error) => {
    toast.error(error.message);
  },
  onSettled: () => {
    queryClient.invalidateQueries(['users']);
  },
});

// Called without handling result
mutation.mutate(formData);
```

**Correct (handle at call site):**

```tsx
// Good - handle everything at call site
const mutation = useMutation({
  mutationFn: async (data) => api.createUser(data),
});

async function handleSubmit(formData: FormData) {
  try {
    const user = await mutation.mutateAsync(formData);
    toast.success('User created!');
    await queryClient.invalidateQueries(['users']);
    navigate(`/users/${user.id}`);
  } catch (error) {
    toast.error(error.message);
  }
}
```

**Why call-site handling is better:**

- Explicit control flow
- Can await invalidation before navigation
- No hidden side effects in hook definition
- Easier to test and understand

**Why it matters:**
- Callbacks are deprecated in TanStack Query
- Will be removed in v6
- Call-site handling is clearer and more flexible

Reference: [TanStack Query Mutations](https://tanstack.com/query/latest/docs/framework/react/guides/mutations)
