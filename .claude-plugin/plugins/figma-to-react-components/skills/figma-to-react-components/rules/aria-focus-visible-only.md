---
title: Use focus-visible instead of focus for styling
impact: HIGH
tags:
  - accessibility
  - focus-management
  - css
---

# Use :focus-visible Instead of :focus

Style focus indicators with `:focus-visible`, not `:focus`. This shows focus rings only for keyboard/assistive technology users, not mouse clicks.

## Incorrect

```scss
.button {
  &:focus {
    outline: 2px solid blue;
    outline-offset: 2px;
  }
}
```

**Why this is wrong:** `:focus` fires on every focus event — including mouse clicks. This creates annoying visual rings when users click buttons, leading teams to remove focus styles entirely (`outline: none`), which breaks keyboard accessibility.

## Correct

```scss
.button {
  // Remove default outline — we provide our own indicator
  &:focus {
    outline: none;
  }

  // Show focus ring only for keyboard/assistive technology navigation
  &:focus-visible {
    outline: none;
    box-shadow: /* use your project's focus token */;
  }
}
```

**Why this is correct:** `:focus-visible` only matches when the browser determines the user is navigating via keyboard or assistive technology. Mouse users see no ring; keyboard users see a clear indicator.

## With React Aria's useFocusRing

For components that need programmatic focus ring control:

```tsx
import { useFocusRing } from 'react-aria';

const Card = ({ children, onClick }) => {
  const { isFocusVisible, focusProps } = useFocusRing();

  return (
    <div
      {...focusProps}
      className={`card ${isFocusVisible ? 'card--focus-visible' : ''}`}
      onClick={onClick}
    >
      {children}
    </div>
  );
};
```

## Why It Matters

- **User experience:** Mouse users don't see unnecessary focus rings cluttering the UI
- **Accessibility preserved:** Keyboard and screen reader users still see clear focus indicators
- **No workarounds needed:** Eliminates the temptation to use `outline: none` globally, which destroys keyboard accessibility
- **Browser support:** `:focus-visible` is supported in all modern browsers
