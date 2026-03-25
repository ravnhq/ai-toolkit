---
title: Ensure Adequate Touch Targets
impact: MEDIUM
tags: responsive, touch, accessibility
---

## Ensure Adequate Touch Targets

Interactive elements need minimum 44x44px touch targets for mobile users.

**Incorrect (too small):**

```tsx
// Bad - tiny touch target
<button className="p-1">
  <Icon className="h-4 w-4" />
</button>

// Bad - links too close together
<div className="flex gap-1">
  <a href="/a">Link A</a>
  <a href="/b">Link B</a>
</div>
```

**Correct (adequate touch targets):**

```tsx
// Good - 44px minimum (p-2.5 + icon = ~40-48px)
<button className="p-2.5">
  <Icon className="h-5 w-5" />
</button>

// Good - shadcn icon button
<Button variant="ghost" size="icon">  {/* h-10 w-10 = 40px */}
  <Settings className="h-5 w-5" />
</Button>

// Good - adequate spacing between targets
<div className="flex gap-4">
  <a href="/a" className="p-2">Link A</a>
  <a href="/b" className="p-2">Link B</a>
</div>

// Good - list items with padding
<ul>
  {items.map(item => (
    <li key={item.id}>
      <button className="w-full py-3 px-4 text-left">
        {item.name}
      </button>
    </li>
  ))}
</ul>
```

**Size reference:**

| Size | Tailwind | Use |
|------|----------|-----|
| 36px | `h-9` | Minimum touch (not recommended) |
| 40px | `h-10` | Default buttons |
| 44px | `h-11` | Comfortable touch target |
| 48px | `h-12` | Large buttons, mobile nav |

**Why it matters:**
- 44px is WCAG 2.5.5 minimum recommendation
- Fat finger syndrome is real
- Touch has no hover state precision
- Frustrating UX when targets are too small

Reference: [WCAG 2.5.5 Target Size](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)
