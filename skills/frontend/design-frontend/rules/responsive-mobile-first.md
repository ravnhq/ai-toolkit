---
title: Design Mobile-First
impact: HIGH
tags: responsive, mobile, breakpoints
---

## Design Mobile-First

Write base styles for mobile, then add breakpoint variants for larger screens.

**Incorrect (desktop-first):**

```tsx
// Bad - defaults to desktop, overrides for mobile
<div className="flex-row flex-col sm:flex-row" />  // Confusing
<div className="w-1/2 w-full sm:w-1/2" />           // Redundant
<p className="text-lg text-sm md:text-lg" />        // Backwards
```

**Correct (mobile-first):**

```tsx
// Good - base is mobile, breakpoints add complexity
<div className="flex flex-col md:flex-row" />
<div className="w-full md:w-1/2 lg:w-1/3" />
<p className="text-sm md:text-base" />

// Good - common responsive pattern
<div className="
  grid
  grid-cols-1
  sm:grid-cols-2
  lg:grid-cols-3
  xl:grid-cols-4
  gap-4
">
```

**Tailwind breakpoints:**

| Prefix | Min Width | Use |
|--------|-----------|-----|
| (none) | 0px | Mobile (default) |
| `sm:` | 640px | Large phones |
| `md:` | 768px | Tablets |
| `lg:` | 1024px | Laptops |
| `xl:` | 1280px | Desktops |
| `2xl:` | 1536px | Large screens |

**Common patterns:**

```tsx
// Stack → row
<div className="flex flex-col gap-4 md:flex-row" />

// Full → partial width
<div className="w-full md:w-1/2 lg:w-1/3" />

// Hide on mobile
<nav className="hidden md:flex" />

// Show on mobile only
<button className="md:hidden">Menu</button>
```

**Why it matters:**
- More users on mobile than desktop
- Mobile constraints force simpler design
- Progressive enhancement is more maintainable
- Avoids redundant overrides

Reference: [Tailwind Responsive Design](https://tailwindcss.com/docs/responsive-design)
