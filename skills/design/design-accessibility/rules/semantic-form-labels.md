---
title: Every Form Input Needs a Label
impact: HIGH
tags: semantic, forms, labels
---

## Every Form Input Needs a Label

Every form input must have an associated label. Placeholder text is not a label.

**Incorrect (no label):**

```tsx
// Bad - placeholder is not a label
<input placeholder="Email" />

// Bad - visually hidden label doesn't exist
<input id="email" />  {/* No label element */}

// Problems:
// - Screen readers can't identify the field
// - Clicking label doesn't focus input
// - Placeholder disappears when typing
```

**Correct (proper label):**

```tsx
// Good - explicit label with htmlFor
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// Good - using form library (shadcn)
<FormField
  name="email"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Email</FormLabel>
      <FormControl>
        <Input {...field} />
      </FormControl>
    </FormItem>
  )}
/>

// Good - visually hidden but accessible
<label htmlFor="search" className="sr-only">Search</label>
<input id="search" type="search" placeholder="Search..." />
```

**Label association methods:**

1. `htmlFor` + `id` (explicit association)
2. Wrapping input in label (implicit)
3. `aria-labelledby` (ARIA, use sparingly)

```tsx
// Method 1: htmlFor (preferred)
<label htmlFor="name">Name</label>
<input id="name" />

// Method 2: Wrapping
<label>
  Name
  <input />
</label>
```

**Why it matters:**
- Screen readers announce label when input is focused
- Clicking label focuses the input (larger click target)
- Required for WCAG 2.1 Level A compliance

Reference: [WCAG 1.3.1 Info and Relationships](https://www.w3.org/WAI/WCAG21/Understanding/info-and-relationships.html)
