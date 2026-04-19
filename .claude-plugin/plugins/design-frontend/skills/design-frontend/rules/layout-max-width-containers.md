---
title: Constrain Content Width
impact: MEDIUM
tags: layout, containers, width
---

## Constrain Content Width

Use `max-w-*` to prevent content from spanning too wide on large screens.

**Incorrect (unconstrained width):**

```tsx
// Bad - content spans entire viewport on 4K monitors
<main className="p-4">
  <article>
    {/* Text line lengths become unreadable */}
  </article>
</main>
```

**Correct (constrained width):**

```tsx
// Good - page container
<main className="max-w-7xl mx-auto px-4 md:px-6">
  <Content />
</main>

// Good - narrow content (forms, articles)
<article className="max-w-prose mx-auto">
  {/* ~65 characters per line - optimal reading */}
</article>

// Good - form container
<form className="max-w-md mx-auto">
  {/* ~448px - comfortable form width */}
</form>

// Good - dashboard with sidebar
<div className="flex">
  <aside className="w-64 shrink-0">Sidebar</aside>
  <main className="flex-1 max-w-5xl">Content</main>
</div>
```

**Max width reference:**

| Class | Width | Use |
|-------|-------|-----|
| `max-w-md` | 448px | Forms, modals |
| `max-w-lg` | 512px | Wider forms |
| `max-w-2xl` | 672px | Content columns |
| `max-w-prose` | 65ch | Article text |
| `max-w-5xl` | 1024px | Main content |
| `max-w-7xl` | 1280px | Page container |

**Why it matters:**
- Lines over 75 characters are hard to read
- Wasted space looks unfinished
- Consistent alignment across pages
- Better responsive behavior

Reference: [Tailwind Max Width](https://tailwindcss.com/docs/max-width)
