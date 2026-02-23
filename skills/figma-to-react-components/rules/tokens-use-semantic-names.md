---
title: Use semantic token names over primitive values
impact: HIGH
tags:
  - design-tokens
  - naming
  - abstraction
---

# Use Semantic Token Names Over Primitive Values

Reference semantic (purpose-based) tokens rather than primitive (value-based) tokens. Semantic tokens describe *what* a value is for, not *what* the value is.

## Incorrect

```scss
// Primitive token — describes the color value, not its purpose
.button {
  background-color: $blue-500;
  color: $white;
  border: 1px solid $blue-600;

  &:hover {
    background-color: $blue-600;
  }

  &:disabled {
    background-color: $gray-300;
  }
}
```

**Why this is wrong:** Primitive tokens (`$blue-500`) don't convey intent. If the brand's primary color changes from blue to teal, every primitive reference must be found and updated. There's no way to know which `$blue-500` usages are "primary action" vs "info badge" vs "link color".

## Correct

```scss
// Semantic tokens — describe purpose and state
.button {
  background-color: $color-action-primary-default;
  color: $color-text-on-action-primary;
  border: 1px solid $color-border-action-primary;

  &:hover:not(:disabled) {
    background-color: $color-action-primary-hovered;
  }

  &:disabled {
    background-color: $color-action-primary-disabled;
  }
}
```

**Why this is correct:** Semantic tokens encode intent. `$color-action-primary-default` clearly means "primary action background in default state." When the brand changes, only the token definition changes — every component inherits the update.

## Token Hierarchy

Design token systems typically have three layers:

```
Primitive (raw values)     →  $blue-500: #3b82f6
    ↓
Semantic (purpose)         →  $color-action-primary-default: $blue-500
    ↓
Component (scoped)         →  $button-bg-primary: $color-action-primary-default
```

Always reference the most specific (semantic or component) layer available. Only fall back to primitives when no semantic token exists — and flag it as a gap to the design team.

## Why It Matters

- **Intent clarity:** Code reads as purpose ("action primary") not implementation ("blue 500")
- **Theme flexibility:** Semantic tokens can map to different primitives per theme without touching component code
- **Reduced coupling:** Components don't need to know or care about specific color values
- **Scalability:** Adding dark mode, high-contrast mode, or a rebrand only requires updating token mappings
