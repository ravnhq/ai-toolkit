---
title: Never hardcode visual values
impact: CRITICAL
tags:
  - design-tokens
  - consistency
  - maintainability
---

# Never Hardcode Visual Values

All colors, spacing, typography, radii, and elevation values MUST come from the project's design token system. Never use raw CSS values.

## Incorrect

```scss
// Raw hex colors and pixel values
.card {
  background-color: #ffffff;
  padding: 16px;
  border-radius: 8px;
  color: #333333;
  font-size: 14px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}
```

**Why this is wrong:** Raw values drift from the design system, break when themes change, and create inconsistencies across components.

## Correct

**SCSS variables:**
```scss
@import 'path/to/your/tokens';

.card {
  background-color: $color-surface-primary;
  padding: $spacing-md;
  border-radius: $radius-md;
  color: $color-text-default-primary;
  font-size: $typography-text-sm-size;
  box-shadow: $elevation-md;
}
```

**CSS custom properties:**
```css
.card {
  background-color: var(--color-surface-primary);
  padding: var(--spacing-md);
  border-radius: var(--radius-md);
  color: var(--color-text-primary);
  font-size: var(--font-size-sm);
  box-shadow: var(--elevation-md);
}
```

**Tailwind utility classes:**
```tsx
<div className="bg-surface-primary p-4 rounded-md text-primary text-sm shadow-md">
  {/* content */}
</div>
```

**Why this is correct:** Token references stay synchronized with the design system. When tokens change (e.g., a rebrand or dark mode), every component updates automatically.

## Why It Matters

- **Theme support:** Tokens enable light/dark mode and brand theming without code changes
- **Design consistency:** A single source of truth prevents visual drift between components
- **Maintainability:** Updating a token value propagates everywhere; updating 47 hardcoded `#333333` values does not
- **Design-dev alignment:** Designers and developers reference the same token names
