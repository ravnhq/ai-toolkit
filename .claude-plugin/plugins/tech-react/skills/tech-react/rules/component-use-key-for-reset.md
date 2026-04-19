---
title: Use Key to Reset Component State
impact: MEDIUM
tags: component, state, key
---

## Use Key to Reset Component State

When you need to reset a component's internal state based on a prop change, use the `key` prop instead of useEffect.

**Incorrect (effect to reset state):**

```tsx
// Bad - effect to reset form when user changes
function ProfileForm({ userId }: { userId: string }) {
  const [formData, setFormData] = useState({ name: '', email: '' });

  useEffect(() => {
    // Reset form when userId changes
    setFormData({ name: '', email: '' });
  }, [userId]);

  return <form>...</form>;
}
```

**Correct (key forces remount):**

```tsx
// Good - key causes React to remount the component
function ProfilePage({ userId }: { userId: string }) {
  return <ProfileForm userId={userId} key={userId} />;
}

function ProfileForm({ userId }: { userId: string }) {
  // Fresh state on each userId - no effect needed!
  const [formData, setFormData] = useState({ name: '', email: '' });

  return <form>...</form>;
}
```

**How it works:**

When the `key` changes, React:
1. Unmounts the old component instance
2. Mounts a new instance with fresh state

**When to use this pattern:**

- Form that resets for different entities
- Editor for different documents
- Any component that should "start fresh" for different data

**Why it matters:**
- Simpler than effect-based reset
- No risk of stale state during the effect cycle
- Clearer intent - "new key = new component"

Reference: [Resetting state with a key](https://react.dev/learn/you-might-not-need-an-effect#resetting-all-state-when-a-prop-changes)
