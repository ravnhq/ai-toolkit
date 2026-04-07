---
title: Use Container Queries for Component-Level Responsiveness
impact: HIGH
tags: responsive, container-queries, components, layout
---

## Use Container Queries for Component-Level Responsiveness

Use `@container` on parent elements and container query variants (`@sm:`, `@md:`, `@lg:`) on children to build components that respond to their container size, not viewport size. This enables truly reusable components that adapt to any layout context.

**Problem: viewport-based responsive design breaks component reusability**

```html
<!-- BAD — card layout depends on viewport, not available space -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
  <article class="flex md:flex-row lg:flex-col">
    <img class="w-full md:w-48 lg:w-full" src="..." />
    <div class="hidden md:block text-sm"><!-- Only shown on md+ --></div>
  </article>
</div>

<!-- Problem: if we move card to a sidebar, md: breakpoint is meaningless -->
<!-- The card needs full width in a narrow sidebar, not md behavior -->
```

**Solution: container queries respond to component container, not viewport**

```html
<!-- GOOD — card responds to its own container size -->
<div class="@container">
  <article class="flex @md:flex-row @lg:flex-col">
    <img class="w-full @md:w-48 @lg:w-full" src="..." />
    <!-- Shows text at container md+, regardless of viewport -->
    <div class="hidden @md:block text-sm">Visible in wide containers</div>
  </article>
</div>

<!-- Same card works in sidebar, grid, or full width -->
<!-- Layout adapts to ACTUAL available space, not viewport size -->
```

**Real-world example: reusable card component**

```html
<!-- Product card that works in any container -->
<div class="@container rounded-lg border p-4">
  <div class="flex flex-col @sm:flex-row gap-4">
    <img class="h-24 w-24 @sm:h-32 @sm:w-32 object-cover rounded" src="..." />

    <div class="flex flex-col justify-between flex-1">
      <h3 class="font-bold text-base @sm:text-lg">Product Name</h3>
      <p class="text-sm @sm:text-base text-gray-600">Description hidden on small containers</p>

      <div class="flex gap-2 mt-4">
        <button class="flex-1 @sm:flex-none px-4 py-2 bg-blue-600">Add</button>
      </div>
    </div>
  </div>
</div>

<!-- Use in different layouts: all responsive to container -->
<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
  <!-- Card will be flexible in each column -->
</div>

<aside class="w-64">
  <!-- Card will adapt to 256px width -->
</aside>
```

**Container queries with nested layouts:**

```html
<!-- Parent container establishes query context -->
<section class="@container space-y-6">
  <!-- Grid adapts at container size, not viewport -->
  <div class="grid grid-cols-1 @sm:grid-cols-2 @md:grid-cols-3 @lg:grid-cols-4 gap-4">
    <!-- Each item responsive within grid -->
    <div class="@container rounded-lg border p-3">
      <h4 class="font-bold text-sm @sm:text-base">Item</h4>
      <p class="text-xs @sm:text-sm text-gray-600">Description</p>
    </div>
  </div>
</section>
```

**Container query with aspect ratio changes:**

```html
<!-- Media container that changes aspect ratio based on space -->
<div class="@container">
  <img
    class="w-full aspect-square @sm:aspect-video @lg:aspect-auto"
    src="..."
    alt="Hero"
  />
</div>

<!-- In sidebar: square image (small container) -->
<!-- In main area: video aspect (medium container) -->
<!-- In full viewport: original aspect (large container) -->
```

**Comparison: viewport vs container queries**

| Pattern | Viewport | Container |
|---------|----------|-----------|
| Breakpoint trigger | Screen size | Parent container width |
| Component reusability | Limited (depends on position) | Excellent (responds to actual space) |
| Usage | Page-level layouts | Reusable components |
| Variants | `md:`, `lg:`, `xl:` | `@sm:`, `@md:`, `@lg:`, `@xl:` |
| Markup | Applied directly | Applied inside `@container` parent |

**Browser support and fallback:**

```html
<!-- Modern container queries (Chrome 105+, Firefox 110+, Safari 16+) -->
<div class="@container">
  <div class="hidden @sm:block">Shown in small containers</div>
</div>

<!-- Fallback for older browsers: use viewport media queries -->
<div class="hidden md:block">Fallback shown on md+ viewport</div>
```

**Why it matters:**
- Components respond to actual available space, not viewport position
- Enables true component reusability across different layouts
- Particularly powerful for third-party components and design systems
- Removes media query coupling from component CSS
- Containers can be nested; each establishes query context
- Mobile-first container queries (`@sm` is the smallest, applies upward)
- Far more flexible than trying to make components work at all breakpoints

Reference: [Tailwind Container Queries](https://tailwindcss.com/docs/container-queries)
