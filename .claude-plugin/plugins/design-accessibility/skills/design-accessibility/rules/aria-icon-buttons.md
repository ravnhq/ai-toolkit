---
title: Icon-Only Buttons Need Labels
impact: HIGH
tags: aria, buttons, icons
---

## Icon-Only Buttons Need Labels

Icon-only buttons must have an accessible label. Use `aria-label` or visually hidden text.

**Incorrect (no label):**

```tsx
// Bad - screen reader just says "button"
<button onClick={handleDelete}>
  <Trash className="h-4 w-4" />
</button>

// Bad - icon alt text doesn't help
<button onClick={handleDelete}>
  <img src="/trash.svg" alt="trash" />
</button>
```

**Correct (with accessible label):**

```tsx
// Good - aria-label
<button onClick={handleDelete} aria-label="Delete item">
  <Trash className="h-4 w-4" />
</button>

// Good - using shadcn Button
<Button variant="ghost" size="icon" aria-label="Delete item">
  <Trash className="h-4 w-4" />
</Button>

// Good - visually hidden text
<button onClick={handleDelete}>
  <Trash className="h-4 w-4" aria-hidden="true" />
  <span className="sr-only">Delete item</span>
</button>
```

**Hide decorative icons:**

```tsx
// Icon next to text - hide from screen readers
<button>
  <Check className="h-4 w-4 mr-2" aria-hidden="true" />
  Save Changes
</button>
// Screen reader: "Save Changes, button"
```

**Tailwind sr-only class:**

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  border: 0;
}
```

**Why it matters:**
- Screen readers can't interpret icons
- "Button" announcement is useless
- Users need to know what the button does
- Required for WCAG 1.1.1 Non-text Content

Reference: [WCAG 1.1.1 Non-text Content](https://www.w3.org/WAI/WCAG21/Understanding/non-text-content.html)
