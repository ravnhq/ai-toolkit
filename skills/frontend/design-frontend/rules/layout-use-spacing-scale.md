---
title: Use Consistent Spacing Scale
impact: MEDIUM
tags: layout, spacing, consistency
---

## Use Consistent Spacing Scale

Use Tailwind's spacing scale consistently. Avoid arbitrary values.

**Incorrect (arbitrary spacing):**

```tsx
// Bad - arbitrary values
<div style={{ padding: '13px' }} />
<div className="p-[13px]" />
<div className="mt-[7px]" />
<div className="gap-[22px]" />
```

**Correct (spacing scale):**

```tsx
// Good - use the scale
<div className="p-4" />     {/* 16px */}
<div className="p-6" />     {/* 24px */}
<div className="mt-2" />    {/* 8px */}
<div className="gap-4" />   {/* 16px */}
```

**Tailwind spacing scale:**

| Class | Size | Common Use |
|-------|------|------------|
| `0` | 0px | Remove spacing |
| `1` | 4px | Tiny gaps |
| `2` | 8px | Small gaps, icon spacing |
| `3` | 12px | Form field gaps |
| `4` | 16px | Standard padding, card padding |
| `6` | 24px | Section padding |
| `8` | 32px | Large section spacing |

**Common patterns:**

```tsx
// Card padding
<Card className="p-4 md:p-6" />

// Form field spacing
<div className="space-y-4">
  <FormField />
  <FormField />
</div>

// Section spacing
<section className="space-y-8">
  <Header />
  <Content />
</section>

// Inline elements
<div className="flex items-center gap-2">
  <Icon />
  <span>Text</span>
</div>
```

**Why it matters:**
- Consistent rhythm creates visual harmony
- Easier to maintain and update
- Reduces design decisions during development
- Tailwind purges arbitrary values less efficiently

Reference: [Tailwind Spacing](https://tailwindcss.com/docs/customizing-spacing)
