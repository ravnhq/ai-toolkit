---
title: Use BEM methodology for CSS class names
impact: MEDIUM
tags:
  - naming
  - css
  - bem
  - organization
---

# Use BEM Methodology for CSS Class Names

All component CSS classes MUST follow Block Element Modifier (BEM) naming: `.block__element--modifier`.

## Incorrect

```scss
// Inconsistent naming — no clear hierarchy
.btn { }
.btnIcon { }
.btn-text { }
.btn.primary { }
.btn.sm { }
.button-disabled { }
```

**Why this is wrong:** Mixed naming conventions make it impossible to tell which classes belong together, which are elements vs modifiers, and which component owns which styles. This leads to specificity wars and accidental style collisions.

## Correct

```scss
// BEM: Block__Element--Modifier
.button {
  // Block — the component root

  &__icon {
    // Element — a child of the block
  }

  &__text {
    // Element — another child
  }

  &--primary {
    // Modifier — a variant of the block
  }

  &--sm {
    // Modifier — a size variant
  }

  &:disabled {
    // Pseudo-class — not a BEM modifier, use native selectors
  }
}
```

```tsx
// In JSX — compose BEM classes
<button className={`button button--${variant} button--${size}`}>
  <span className="button__icon">{icon}</span>
  <span className="button__text">{children}</span>
</button>
```

**Why this is correct:** BEM creates a flat, predictable class structure. Every class name tells you: which component it belongs to (block), what role it plays (element), and what variation it represents (modifier).

## BEM Quick Reference

| Concept | Pattern | Example |
|---|---|---|
| Block | `.block` | `.card` |
| Element | `.block__element` | `.card__title` |
| Modifier | `.block--modifier` | `.card--featured` |
| Element + Modifier | `.block__element--modifier` | `.card__title--large` |

## Why It Matters

- **Scoping:** BEM class names are unique per component, preventing style leakage
- **Readability:** `.card__title--large` is self-documenting — you know exactly what it styles
- **Flat specificity:** No nesting beyond one level, avoiding specificity escalation
- **Team scalability:** New developers can follow the convention without guessing
