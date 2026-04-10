---
title: Avoid !important Overrides
impact: MEDIUM
tags: layout, css, specificity
---

## Avoid !important Overrides

If you need `!important` to override styles, something is wrong with the component architecture.

**Incorrect (using !important):**

```tsx
// Bad - forcing override with !important
<div className="!p-0" />
<div className="!bg-transparent" />
<button className="!text-sm" />

// Bad - indicates component doesn't accept customization
<Card className="!rounded-none" /> // Why doesn't Card accept this?
```

**Correct (proper customization):**

```tsx
// Good - component accepts className
function Card({ className, children }) {
  return (
    <div className={cn("rounded-lg border p-4", className)}>
      {children}
    </div>
  );
}

// Usage - className override works
<Card className="rounded-none" />  // No !important needed

// Good - variant props for common variations
<Card variant="flat" />  // No border/shadow
<Card size="compact" />  // Less padding
```

**When you see !important, ask:**

1. Is the base component too specific?
2. Should this be a variant prop?
3. Is there CSS specificity conflict?
4. Are you fighting a library's styles?

**Fixing the root cause:**

```tsx
// Instead of: <Button className="!bg-red-500" />
// Add a variant:
<Button variant="destructive" />

// Instead of: <Card className="!p-0" />
// Accept padding prop or variant:
<Card padding="none" />
```

**Why it matters:**
- !important is a code smell
- Makes styles unmaintainable
- Indicates missing component flexibility
- Creates specificity wars

Reference: [Tailwind Specificity](https://tailwindcss.com/docs/configuration#important)
