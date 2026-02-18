---
title: Always Use Named Exports
impact: MEDIUM
tags: imports, exports, modules
---

## Always Use Named Exports

Use named exports exclusively. Never use default exports. Named exports enable better refactoring (renames propagate automatically), better IDE autocomplete (the editor knows what a module exports), and easier grep-ability (you can search for exact symbol names). Maintain consistent import ordering across all files.

**Incorrect (default exports, unordered imports):**

```typescript
// Bad - default export
export default function UserProfile({ userId }: Props) {
  // ...
}

// Bad - default can be imported under any name, causing inconsistency
import UserProfile from "./UserProfile";
import Profile from "./UserProfile"; // Same thing, different name

// Bad - unordered imports
import { usePosts } from "./use-posts";
import { z } from "zod";
import { Button } from "@/shared/components/ui/button";
import { useState } from "react";
```

**Correct (named exports, ordered imports):**

```typescript
// Good - named export
export function UserProfile({ userId }: Props) {
  // ...
}

// Good - named import is consistent everywhere
import { UserProfile } from "./UserProfile";

// Good - imports ordered: external -> shared/internal -> local
import { useState } from "react";

import { z } from "zod";

import { db } from "@/db";

// Shared/internal packages
import { Button } from "@/shared/components/ui/button";

// Local/feature imports
import { usePosts } from "./use-posts";
```

**Guidelines:**

- Always use named exports -- never `export default`
- Named exports enforce consistent naming across the codebase
- Import order: external packages, then shared/internal packages, then local imports -- separated by blank lines
- This applies to all file types: components, utilities, hooks, types, constants
