---
title: Never Hardcode Colors
impact: HIGH
tags: tokens, colors, theming
---

## Never Hardcode Colors

Use design tokens (CSS variables via Tailwind) for all colors. Never use hex codes, RGB, or color names directly.

**Incorrect (hardcoded colors):**

```tsx
// Bad - hex codes
<div className="bg-[#1a1a1a] text-[#ffffff]" />
<div style={{ backgroundColor: '#594BFF' }} />

// Bad - arbitrary Tailwind colors
<p className="text-zinc-400" />  // Not from design system
<button className="bg-blue-500" /> // Not semantic

// Bad - color constants
const BRAND_COLOR = '#594BFF';
const COLORS = { primary: '#594BFF', error: '#EF4444' };
```

**Correct (design tokens):**

```tsx
// Good - semantic design tokens
<div className="bg-background text-foreground" />
<div className="bg-card text-card-foreground" />
<button className="bg-primary text-primary-foreground" />
<p className="text-muted-foreground" />
<span className="text-destructive" />

// Good - using CSS variables
<div className="bg-[hsl(var(--accent))]" /> // When utility doesn't exist
```

**Available tokens (shadcn):**

| Token | Use |
|-------|-----|
| `background/foreground` | Page backgrounds, text |
| `card/card-foreground` | Card surfaces |
| `primary/primary-foreground` | Primary actions |
| `secondary/secondary-foreground` | Secondary actions |
| `muted/muted-foreground` | Subtle backgrounds, secondary text |
| `accent/accent-foreground` | Highlights, hovers |
| `destructive/destructive-foreground` | Errors, deletions |
| `border`, `input`, `ring` | Borders, inputs, focus rings |

**Why it matters:**
- Theme switching becomes impossible with hardcoded colors
- No consistency across the application
- Dark mode breaks completely
- Maintenance nightmare when brand colors change

Reference: [Tailwind CSS Theme Configuration](https://tailwindcss.com/docs/theme)
