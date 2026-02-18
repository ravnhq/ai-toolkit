---
title: Maintain Visible Focus Indicators
impact: HIGH
tags: keyboard, focus, visual
---

## Maintain Visible Focus Indicators

Focus indicators must be visible. Never remove focus outlines without providing an alternative.

**Incorrect (removing focus):**

```css
/* BAD - removes all focus indicators */
*:focus {
  outline: none;
}

/* BAD - removes focus completely */
button:focus {
  outline: 0;
}
```

**Correct (visible focus):**

```css
/* Good - use focus-visible for keyboard-only focus */
*:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
}

/* Good - custom focus style */
button:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.5);
}

/* Good - Tailwind classes (shadcn provides this) */
/* focus-visible:ring-2 focus-visible:ring-ring */
```

**focus vs focus-visible:**

| Pseudo-class | When Active |
|--------------|-------------|
| `:focus` | Any focus (click or keyboard) |
| `:focus-visible` | Keyboard focus only |

Using `:focus-visible` shows focus rings only for keyboard users, hiding them for mouse clicks.

**Why it matters:**
- Keyboard users need to see where focus is
- 15% of users navigate primarily by keyboard
- Required for WCAG 2.4.7 Level AA
- Don't sacrifice keyboard users for aesthetics

Reference: [WCAG 2.4.7 Focus Visible](https://www.w3.org/WAI/WCAG21/Understanding/focus-visible.html)
