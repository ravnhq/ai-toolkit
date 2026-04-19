---
title: Never Use any
impact: HIGH
tags: typescript, type-safety, errors
---

## Never Use any

The `any` type disables TypeScript's protection. Use `unknown` and narrow, or fix the underlying type issue.

**Incorrect:**

```typescript
function processData(data: any) {
  return data.items.map((item: any) => item.name);
}

// Silently accepts anything, crashes at runtime
processData("not an object"); // Runtime error: Cannot read 'items' of string
```

**Correct:**

```typescript
interface DataWithItems {
  items: Array<{ name: string }>;
}

function processData(data: DataWithItems) {
  return data.items.map(item => item.name);
}

// Or with unknown + validation
function processUnknown(data: unknown) {
  if (!isDataWithItems(data)) {
    throw new Error('Invalid data format');
  }
  return data.items.map(item => item.name);
}
```

**Also avoid:**

- `@ts-nocheck` - never use
- `@ts-ignore` - only with explicit approval for exceptional cases
- Type assertions (`as`) - fix the underlying type instead

**Why it matters:** Every `any` is a potential runtime crash. TypeScript exists to catch errors at compile time - don't circumvent it.
