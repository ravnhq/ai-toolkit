---
title: Define Color Pairs for Dark Mode with Proper Contrast
impact: HIGH
tags: dark-mode, colors, accessibility, contrast
---

## Define Color Pairs for Dark Mode with Proper Contrast

Use `@theme` to define color tokens as CSS variables and design color pairs for light AND dark modes simultaneously. Never invert colors post-hoc; design color pairs together to maintain WCAG contrast ratios in both modes.

**Problem: dark mode implemented as color inversion**

```html
<!-- BAD — assumed inversion will work -->
<div class="bg-white dark:bg-black">
  <p class="text-gray-900 dark:text-white">Text</p>
  <p class="text-gray-500 dark:text-gray-400">Subtext</p>
  <!-- Problem: gray-500 text on black background is hard to read -->
  <!-- Subtext color insufficient contrast in dark mode -->
</div>
```

**Solution: design color pairs that maintain contrast in both modes**

```css
/* app.css - Define color pairs as tokens */
@import "tailwindcss";

@theme {
  /* Primary colors: light/dark pair */
  --color-primary-light: #3b82f6;    /* Blue 500 */
  --color-primary-dark: #60a5fa;     /* Blue 400, lighter for dark bg */

  /* Surface colors: light/dark pair */
  --color-surface-light: #ffffff;
  --color-surface-dark: #1f2937;     /* Gray 800 */

  /* Text colors: designed for readability in both modes */
  --color-text-primary-light: #111827;   /* Gray 900 */
  --color-text-primary-dark: #f9fafb;    /* Gray 50 */

  --color-text-secondary-light: #4b5563; /* Gray 700, not 500 */
  --color-text-secondary-dark: #d1d5db;  /* Gray 300, not gray 400 */

  /* Semantic colors with light/dark variants */
  --color-success-light: #10b981;
  --color-success-dark: #34d399;

  --color-error-light: #ef4444;
  --color-error-dark: #f87171;
}
```

```html
<!-- GOOD — color pairs designed for contrast in both modes -->
<div class="bg-[var(--color-surface-light)] dark:bg-[var(--color-surface-dark)]">
  <h2 class="text-[var(--color-text-primary-light)] dark:text-[var(--color-text-primary-dark)] font-bold">
    Heading
  </h2>
  <p class="text-[var(--color-text-secondary-light)] dark:text-[var(--color-text-secondary-dark)]">
    Secondary text with proper contrast in both modes
  </p>
</div>
```

**Using semantic utility shorthand:**

```css
/* tailwind.config.js or @theme in CSS */
@theme {
  --color-bg: light #ffffff, dark #1f2937;
  --color-text: light #111827, dark #f9fafb;
  --color-text-muted: light #6b7280, dark #d1d5db;
}
```

```html
<div class="bg-[var(--color-bg)]">
  <h1 class="text-[var(--color-text)]">Title</h1>
  <p class="text-[var(--color-text-muted)]">Muted text with contrast</p>
</div>
```

**Color palette with light and dark variants:**

```css
@theme {
  /* All colors defined as light/dark pairs */
  --color-neutral-50: light #f9fafb, dark #111827;
  --color-neutral-100: light #f3f4f6, dark #1f2937;
  --color-neutral-200: light #e5e7eb, dark #374151;
  --color-neutral-300: light #d1d5db, dark #4b5563;
  --color-neutral-400: light #9ca3af, dark #9ca3af; /* Same in both */
  --color-neutral-500: light #6b7280, dark #d1d5db;
  --color-neutral-600: light #4b5563, dark #e5e7eb;
  --color-neutral-700: light #374151, dark #f3f4f6;
  --color-neutral-800: light #1f2937, dark #f9fafb;
  --color-neutral-900: light #111827, dark #ffffff;

  /* Interactive colors */
  --color-interactive: light #3b82f6, dark #60a5fa;
  --color-interactive-hover: light #2563eb, dark #93c5fd;
}
```

**Testing contrast in both modes:**

```html
<!-- Test setup: verify 4.5:1 minimum contrast in both modes -->
<div class="bg-[var(--color-bg)]">
  <!-- Primary text: must meet WCAG AA (4.5:1) -->
  <p class="text-[var(--color-text)]">Primary text</p>

  <!-- Secondary text: larger text allows lower contrast (3:1) -->
  <p class="text-lg text-[var(--color-text-muted)]">Secondary text</p>

  <!-- Interactive elements: minimum 3:1 for non-text -->
  <button class="bg-[var(--color-interactive)] text-white">
    Button text 4.5:1
  </button>
</div>
```

**Common dark mode pitfalls to avoid:**

```html
<!-- ❌ BAD: Simple inversion -->
<p class="text-gray-500 dark:text-gray-400">
  <!-- gray-500 on black is ~3:1 contrast (too low) -->
  <!-- gray-400 on black is ~2:1 contrast (fails WCAG) -->
</p>

<!-- ✅ GOOD: Designed color pair -->
<p class="text-gray-600 dark:text-gray-300">
  <!-- gray-600 on white: ~5:1 (passes) -->
  <!-- gray-300 on black: ~5:1 (passes) -->
</p>
```

**Why it matters:**
- Color pairs ensure readability in both light and dark modes
- Post-hoc dark mode inversion fails accessibility requirements
- CSS variables enable runtime theme switching without recompile
- Semantic color names improve maintainability ("primary-text" vs "gray-700")
- Proper contrast supports low-vision users and reduces eye strain
- Design tokens centralize color decisions; consistent theming across app
- v4 CSS variables enable theme switching on individual components

Reference: [Tailwind Dark Mode](https://tailwindcss.com/docs/dark-mode)
Reference: [WCAG Contrast Requirements](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum)
