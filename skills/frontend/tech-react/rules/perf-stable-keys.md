---
title: Use Stable, Unique Keys for Lists
impact: HIGH
tags: performance, keys, lists
---

## Use Stable, Unique Keys for Lists

List items need stable, unique keys. Never use array index as key unless the list is static.

**Incorrect (index as key):**

```tsx
// Bad - index as key
{items.map((item, index) => (
  <ListItem key={index} item={item} />
))}

// Problems when items reorder:
// 1. React can't track which item moved
// 2. Component state gets attached to wrong item
// 3. Animations break
// 4. Input focus is lost
```

**Correct (stable unique key):**

```tsx
// Good - unique ID as key
{items.map(item => (
  <ListItem key={item.id} item={item} />
))}

// Good - composite key when no single ID
{posts.map(post => (
  <PostRow key={`${post.date}-${post.userId}`} post={post} />
))}
```

**When index key is acceptable:**

- Static lists that never reorder
- Lists without stateful children
- Lists that never get items added/removed in the middle

**Signs of key problems:**

- Input loses focus after typing
- Component state appears on wrong item after sort
- Animations play on wrong items
- Form values jump between rows

**Why it matters:**
- Keys tell React which items changed
- Wrong keys cause incorrect DOM updates
- Performance degrades with bad reconciliation
- User-visible bugs from state mismatches

Reference: [Rendering Lists](https://react.dev/learn/rendering-lists#keeping-list-items-in-order-with-key)
