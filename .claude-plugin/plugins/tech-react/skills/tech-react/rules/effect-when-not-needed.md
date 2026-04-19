---
title: You Might Not Need useEffect
impact: HIGH
tags: effect, performance, correctness
---

## You Might Not Need useEffect

useEffect is for synchronizing with external systems. Most of the time, you don't need it.

**Don't use useEffect for:**

**1. Transforming data for rendering:**

```tsx
// Bad
const [fullName, setFullName] = useState('');
useEffect(() => {
  setFullName(firstName + ' ' + lastName);
}, [firstName, lastName]);

// Good - calculate during render
const fullName = firstName + ' ' + lastName;
```

**2. Handling user events:**

```tsx
// Bad
useEffect(() => {
  if (submitted) {
    postData(formData);
  }
}, [submitted]);

// Good - use event handler
function handleSubmit() {
  postData(formData);
}
```

**3. Resetting state when props change:**

```tsx
// Bad
useEffect(() => {
  setComment('');
}, [userId]);

// Good - use key to force remount
<CommentForm userId={userId} key={userId} />
```

**4. Chains of effects updating state:**

```tsx
// Bad - effect chain
useEffect(() => { setA(b + 1); }, [b]);
useEffect(() => { setC(a + 1); }, [a]);

// Good - update together
function handleBChange(newB) {
  setB(newB);
  setA(newB + 1);
  setC(newB + 2);
}
```

**Do use useEffect for:**

- Fetching data (though TanStack Query is preferred)
- Setting up subscriptions to external stores
- Syncing with non-React widgets (maps, video players)
- Sending analytics on page view

**Why it matters:**
- Effects run after render, causing extra re-renders
- Effect chains are hard to trace and debug
- Most effects can be replaced with simpler patterns

Reference: [You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
