---
title: Use Discriminated Unions for Type-Safe Variants
impact: HIGH
tags: typescript, type-safety, unions, exhaustiveness
---

## Use Discriminated Unions for Type-Safe Variants

When you have a union type with multiple variants, use a discriminator field to enable exhaustive checking and eliminate the need for type assertions.

**Incorrect (manual type narrowing with assertions):**

```typescript
// Union without discriminator - requires manual narrowing
type ApiResponse =
  | { data: User[] }
  | { error: string };

function handleResponse(response: ApiResponse) {
  // Unsafe - have to guess which variant
  if ('data' in response) {
    return response.data; // TypeScript can't verify this is safe
  }
  if ('error' in response) {
    return response.error;
  }
  // No exhaustiveness checking - could add new variant and miss it here
}

// Redux actions without discriminator
type Action =
  | { userId: string; name: string }
  | { userId: string; error: string };

function reducer(state: State, action: Action) {
  // Can't tell if this is success or error action!
  if ('name' in action) {
    return { ...state, user: { id: action.userId, name: action.name } };
  }
  // What if both 'name' and 'error' are present?
}
```

**Correct (discriminated union with exhaustive checking):**

```typescript
// Add 'type' discriminator field
type ApiResponse =
  | { type: 'success'; data: User[] }
  | { type: 'error'; error: string };

function handleResponse(response: ApiResponse) {
  switch (response.type) {
    case 'success':
      return response.data; // TypeScript knows this is the success variant
    case 'error':
      return response.error; // TypeScript knows this is the error variant
    // If you add a new variant, TypeScript forces you to handle it here
  }
}

// Redux actions with discriminator
type Action =
  | { type: 'USER_LOADED'; userId: string; name: string }
  | { type: 'USER_ERROR'; userId: string; error: string }
  | { type: 'USER_LOADING'; userId: string };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'USER_LOADED':
      // TypeScript knows 'name' exists here
      return { ...state, user: { id: action.userId, name: action.name } };
    case 'USER_ERROR':
      // TypeScript knows 'error' exists here
      return { ...state, error: action.error };
    case 'USER_LOADING':
      return { ...state, loading: true };
    // Compiler error if we forget to handle a variant!
  }
}
```

**Result type pattern:**

```typescript
// Classic Result<T, E> pattern for fallible operations
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

async function loadUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.users.findUnique({ where: { id } });
    return { ok: true, value: user };
  } catch (error) {
    return { ok: false, error: error as Error };
  }
}

// Usage - compiler forces you to check
const result = await loadUser('123');
if (result.ok) {
  console.log(result.value.name); // TypeScript knows 'value' exists
} else {
  console.error(result.error.message); // TypeScript knows 'error' exists
}
```

**Discriminator fields:**

Common names for the discriminator field:
- `type` - for tagged unions, actions, events
- `kind` - for AST nodes, variants
- `status` - for state machines
- `ok` / `success` - for Result types (boolean discriminator)

**Why it matters:**

- **Exhaustiveness checking**: TypeScript will error if you forget to handle a variant
- **No type assertions needed**: Discriminator narrows the type automatically
- **Refactoring safety**: Adding/removing variants causes compile errors at all usage sites
- **Self-documenting**: The discriminator field explicitly names each variant
- **IDE support**: Better autocomplete and go-to-definition for variant-specific fields
