---
title: Use React Aria hooks for interactive components
impact: HIGH
tags:
  - accessibility
  - react-aria
  - keyboard-navigation
---

# Use React Aria Hooks for Interactive Components

All interactive components (buttons, inputs, selects, dialogs, etc.) MUST use React Aria hooks for accessibility. Do not implement ARIA attributes manually.

## Incorrect

```tsx
// Manual ARIA — incomplete and error-prone
const Button = ({ onClick, disabled, children }) => {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      role="button"
      aria-disabled={disabled}
      tabIndex={disabled ? -1 : 0}
    >
      {children}
    </button>
  );
};
```

**Why this is wrong:** Manual ARIA implementation misses edge cases: keyboard event handling (Enter vs Space), touch event normalization, focus management during press, disabled state announcement timing, and cross-browser quirks. It's also easy to add conflicting or redundant attributes.

## Correct

```tsx
import React from 'react';
import { useButton } from 'react-aria';
import type { AriaButtonProps } from 'react-aria';

interface ButtonProps extends AriaButtonProps {
  variant?: 'primary' | 'secondary';
  children: React.ReactNode;
}

export const Button = ({ variant = 'primary', children, ...ariaProps }: ButtonProps) => {
  const ref = React.useRef(null);
  const { buttonProps } = useButton(ariaProps, ref);

  return (
    <button
      {...buttonProps}
      ref={ref}
      className={`button button--${variant}`}
    >
      {children}
    </button>
  );
};
```

**Why this is correct:** `useButton` handles keyboard events, touch normalization, disabled state management, press state tracking, and proper ARIA attribute spreading — all tested across browsers and assistive technologies.

## Common React Aria Hooks

| Component Type | Hook | Stately Hook |
|---|---|---|
| Button | `useButton` | — |
| Text Input | `useTextField` | — |
| Checkbox | `useCheckbox` | `useToggleState` |
| Select/Dropdown | `useSelect` | `useSelectState` |
| Dialog/Modal | `useDialog` | `useOverlayTriggerState` |
| Link | `useLink` | — |
| Switch/Toggle | `useSwitch` | `useToggleState` |
| Tabs | `useTabList`, `useTab` | `useTabListState` |

## Why It Matters

- **Correctness:** React Aria is maintained by Adobe and tested against WCAG AA across all major browsers and screen readers
- **Completeness:** Handles edge cases that manual implementations miss (virtual click events, long press, focus restoration)
- **Consistency:** All interactive components behave the same way, reducing user confusion
- **Maintenance:** Accessibility fixes upstream benefit all components automatically
