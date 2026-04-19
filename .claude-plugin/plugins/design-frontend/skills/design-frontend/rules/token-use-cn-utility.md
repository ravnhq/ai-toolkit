---
title: Use cn() for Conditional Classes
impact: MEDIUM
tags: tokens, utilities, classes
---

## Use cn() for Conditional Classes

Use the `cn()` utility (clsx + tailwind-merge) for conditional classes. Don't concatenate strings manually.

**Incorrect (manual concatenation):**

```tsx
// Bad - string concatenation
<button className={"btn " + (isActive ? "bg-primary" : "bg-secondary")} />

// Bad - template literal
<button className={`btn ${disabled ? 'opacity-50' : ''}`} />

// Bad - array join
<button className={['btn', isActive && 'active'].filter(Boolean).join(' ')} />
```

**Correct (cn utility):**

```tsx
import { cn } from '@/lib/utils';

// Good - cn() with conditionals
<button
  className={cn(
    "rounded-md px-4 py-2",
    isActive && "bg-primary text-primary-foreground",
    !isActive && "bg-secondary text-secondary-foreground",
    disabled && "cursor-not-allowed opacity-50"
  )}
/>

// Good - with variants
<div
  className={cn(
    "flex items-center",
    variant === 'centered' && "justify-center",
    variant === 'spread' && "justify-between",
    className  // Allow parent override
  )}
/>

// Good - accepting className prop
interface CardProps {
  className?: string;
}

function Card({ className }: CardProps) {
  return <div className={cn("rounded-lg border p-4", className)} />;
}
```

**cn() utility implementation:**

```typescript
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

**Why it matters:**
- `clsx` handles conditionals cleanly
- `tailwind-merge` resolves conflicting utilities
- Cleaner than manual string concatenation
- Parent className overrides work correctly

Reference: [tailwind-merge](https://github.com/dcastil/tailwind-merge)
