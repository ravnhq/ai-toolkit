---
name: design-frontend
description: 'Visual design system patterns for web UIs. Tailwind CSS v4 design tokens
  and CSS variables, responsive design with container queries, dark mode, layout patterns,
  and spacing scales. Use when implementing visual designs, working with Tailwind
  CSS, or building responsive layouts.

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
metadata:
  category: frontend
  tags:
  - design
  - css
  - tailwind
  - responsive
  - layout
  - tokens
  - dark-mode
  - container-queries
  status: ready
  version: 6
---

# Visual Design Systems for Web UIs

Design system patterns for consistent, accessible, responsive interfaces. Tailwind CSS v4 changes the game with CSS variables for runtime theming. Core patterns: design tokens (colors, spacing, typography), responsive breakpoints and container queries, dark mode with proper contrast, component composition, and spacing scales.

Key challenges: hardcoded values instead of tokens (unmaintainable), responsive design without mobile-first thinking, dark mode implemented post-hoc (inaccessible), container queries for component-level responsiveness (not just viewport-based).

## Workflow

When implementing visual designs:

1. **Define tokens** — Colors, spacing, typography, shadows as CSS variables in `@theme`
2. **Choose container** — Wrap component in `@container` for container queries
3. **Build mobile-first** — Start with mobile layout, add breakpoints upward
4. **Test dark mode** — Use `dark:` variants; ensure contrast ratios
5. **Validate touch targets** — Min 44x44px for interactive elements
6. **Measure performance** — CSS-in-JS libraries impact paint time; Tailwind is zero-runtime

## Rules

Patterns are organized by concern:

- **Layout** — Max-width containers, consistent spacing, visual hierarchy
- **Responsive Design** — Mobile-first approach, breakpoints, container queries
- **Design Tokens** — Color scales, spacing scales, typography families
- **Dark Mode** — Proper contrast, color pairs, CSS variables for theming
- **Components** — Touch targets, affordances, accessibility

See `rules/` for implementation patterns and examples.

## Examples

### Positive Trigger

User: "Set up a Tailwind design token system with dark mode support for our component library."

Expected behavior: Use `design-frontend` guidance, apply token patterns with CSS variables and color pairs.

### Non-Trigger

User: "Write a Node.js REST API for user authentication."

Expected behavior: Do not prioritize `design-frontend`; choose a more relevant skill or proceed without it.

- Error: Hardcoding color values in classes; theme changes require refactoring
- Cause: Not using design tokens; colors scattered across codebase
- Solution: Use `@theme` to define colors as CSS variables; reference with `var(--color-*)`

- Error: Dark mode looks washed out; low contrast on dark backgrounds
- Cause: Color pairs not designed together; assumed inversion works
- Solution: Test dark variants; use color scales with proper contrast ratios

## Troubleshooting

- Error: Container queries not working; elements not responding to container size
- Cause: Parent not marked with `@container` class
- Solution: Add `@container` to parent; use `@sm:`, `@md:`, `@lg:` variants on children

- Error: Dark mode styles not applying; dark: variants ignored
- Cause: Dark mode not configured; use `darkMode: "class"` or `"media"` in config
- Solution: Configure dark mode in `tailwind.config.js` or CSS `@custom-variant`

- Error: Touch targets too small; users struggle to tap buttons
- Cause: Over-optimizing for desktop; assuming mouse precision on mobile
- Solution: Use `h-11` / `w-11` (44px) minimum for touch targets
