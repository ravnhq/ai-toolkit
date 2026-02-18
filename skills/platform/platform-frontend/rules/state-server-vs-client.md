---
title: Separate Server State from Client State
impact: HIGH
tags: state, data-fetching, architecture
---

## Separate Server State from Client State

Server state (data from APIs) and client state (UI preferences) have different characteristics. Use different tools for each.

**Incorrect (mixing state types):**

```typescript
// Bad - server data in client store
const useStore = create((set) => ({
  // Client state - OK
  theme: 'dark',
  sidebarOpen: true,

  // Server state - WRONG place
  users: [],
  isLoading: false,
  fetchUsers: async () => {
    set({ isLoading: true });
    const users = await api.getUsers();
    set({ users, isLoading: false });
  },
}));
```

**Correct (separated by type):**

```typescript
// Server state - use query library
// Handles caching, refetching, stale data, loading, errors
const { data: users, isLoading, error } = useQuery({
  queryKey: ['users'],
  queryFn: () => api.getUsers(),
});

// Client state - use local/global store
const useUIStore = create((set) => ({
  theme: 'dark',
  sidebarOpen: true,
  setTheme: (theme) => set({ theme }),
}));
```

**Characteristics of each:**

| Server State | Client State |
|--------------|--------------|
| Persisted elsewhere | Only in browser |
| Async, can be stale | Synchronous |
| Shared across users | User-specific |
| Needs caching strategy | Rarely cached |
| Can fail (network) | Always available |

**Why it matters:**
- Query libraries handle caching, deduplication, refetching automatically
- Client stores don't handle loading/error states well for async data
- Mixing concerns makes code harder to reason about
- Different invalidation and refresh strategies
