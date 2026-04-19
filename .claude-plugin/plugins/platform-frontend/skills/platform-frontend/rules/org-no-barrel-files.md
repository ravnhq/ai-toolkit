---
title: Avoid Barrel Files (Index Re-exports)
impact: MEDIUM
tags: organization, imports, performance
---

## Avoid Barrel Files (Index Re-exports)

Import directly from files instead of using index.ts barrel files that re-export everything.

**Incorrect (barrel files):**

```typescript
// components/index.ts (barrel file)
export * from './button';
export * from './card';
export * from './input';
export * from './modal';
// ... 50 more exports

// Usage - imports entire barrel
import { Button, Card } from '@/components';
```

**Correct (direct imports):**

```typescript
// No barrel file - import directly
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
```

**Problems with barrel files:**

1. **Slow IDE**: Auto-import must resolve entire barrel
2. **Circular dependencies**: Barrels increase cycle risk
3. **Bundle bloat**: Tree-shaking is harder
4. **Hidden dependencies**: Unclear where code lives

**When barrels are acceptable:**

- Package entry points (library public API)
- Very small, stable groups (2-3 items)

**Why it matters:**
- IDE auto-complete becomes sluggish
- Build times increase
- "Where does Button come from?" requires searching
- Accidental imports of unused code
