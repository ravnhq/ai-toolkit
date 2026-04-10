# Common Type-System Weakness Patterns

Reference guide for type weaknesses that frequently cause bugs. Use this when auditing commits to recognize patterns.

## Nullable/Optional Values Modeled Too Loosely

**Pattern:** A field can be null or absent, but the type doesn't encode this.

**TypeScript example:**
```typescript
// Weak: User could have no email, but email is not Optional
interface User {
  id: string;
  email: string;  // Could be null at runtime
  name: string;
}

// Better: Make nullability explicit
interface User {
  id: string;
  email: string | null;  // Clear null is possible
  name: string;
}
```

**Signs in commits:** Added null checks in functions, guard clauses before accessing properties, catch blocks for undefined errors.

---

## Sentinel Values Masking Missing Data

**Pattern:** Using `""`, `"null"`, `-1`, `0` as placeholders for missing data instead of encoding optionality in the type.

**TypeScript example:**
```typescript
// Weak: API returns "" when no phone exists
interface Contact {
  id: number;
  phone: string;  // Could be "" to mean "no phone"
}

// Better: Encode absence in the type
interface Contact {
  id: number;
  phone: string | null;  // Explicit: phone may not exist
}
```

**Signs in commits:** Checks like `if (value === "")`, `if (value === -1)`, string comparisons for special values.

---

## External API Shapes Drifting from Domain Types

**Pattern:** Raw API responses accepted as-is without mapping to domain types at the boundary.

**TypeScript example:**
```typescript
// Weak: API response used directly as domain type
async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return data as User;  // Assumes shape matches; could be wrong
}

// Better: Map at the boundary
async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return {
    id: data.user_id,        // Map explicitly
    email: data.email_addr,
    name: data.full_name
  };
}
```

**Signs in commits:** Added mapping/transformation logic, validation added at API boundaries, type mismatches between API and domain resolved.

---

## Unions or Enums Too Broad

**Pattern:** Type accepts a wider value set than the domain allows.

**TypeScript example:**
```typescript
// Weak: Status could be any string
interface Order {
  id: string;
  status: string;  // Could be "pending", "invalid-state", anything
}

// Better: Restrict to valid states
interface Order {
  id: string;
  status: "pending" | "processing" | "completed" | "cancelled";
}
```

**Signs in commits:** String → Literal type refactors, added validation for status/enum values, switch statements that handle invalid cases.

---

## Invalid States Representable as Valid Objects

**Pattern:** Field combinations encode impossible domain states.

**TypeScript example:**
```typescript
// Weak: Can represent impossible state (completed with no completion time)
interface Task {
  id: string;
  status: "pending" | "completed";
  completedAt: Date | null;
}
// Invalid: status === "completed" but completedAt === null

// Better: Use discriminated union
type Task =
  | { id: string; status: "pending"; completedAt: null }
  | { id: string; status: "completed"; completedAt: Date };
```

**Signs in commits:** Added guards checking combinations of fields, refactored to discriminated unions, tests validating state invariants.

---

## Guard or Normalization Logic Compensating for Permissive Types

**Pattern:** Runtime checks exist only because the type is too wide. A stricter type would make these checks impossible.

**TypeScript example:**
```typescript
// Weak: Function must check for impossible values
function formatEmail(email: string): string {
  if (email === null || email === "") return "N/A";
  return email.toLowerCase();
}

// Better: Type guarantees email is never null
function formatEmail(email: string): string {
  return email.toLowerCase();
}
```

**Signs in commits:** Added null checks that shouldn't be necessary, added validation before using values, runtime errors caught by guards.

---

## Function Signatures Accepting Impossible Data

**Pattern:** Parameters or returns are typed too widely, forcing callers to handle cases that never occur.

**TypeScript example:**
```typescript
// Weak: Accepts any object
async function saveUser(user: unknown): Promise<void> {
  const result = user as any;
  db.save(result);  // Could be anything
}

// Better: Require the exact shape
async function saveUser(user: Omit<User, 'id'>): Promise<void> {
  db.save(user);  // Type guarantees user has correct shape
}
```

**Signs in commits:** `any` → explicit types, `unknown` → narrowed unions, added runtime validation removed after type narrowing.

---

## Async/Promise Violations

**Pattern:** Forgetting to await, missing error handling for rejected promises, or lost type information in chains.

**TypeScript example:**
```typescript
// Weak: Promise not awaited; type is Promise<User>, not User
const user = fetchUser(id);  // user is Promise<User>, not User
console.log(user.name);      // Error: name doesn't exist on Promise

// Better: Explicitly await or handle promise
const user = await fetchUser(id);  // user is User
console.log(user.name);            // Works
```

**Signs in commits:** Added `.then()` chains, added `await` keywords, converted callback chains to async/await, error handlers added for unhandled promise rejections.

---

## Missing Type Narrowing After Checks

**Pattern:** After checking for null/undefined, type is not narrowed, requiring redundant checks.

**TypeScript example:**
```typescript
// Weak: Check happens but type doesn't narrow
function process(value: string | null) {
  if (value) {
    // TypeScript doesn't know value is string here (old version)
    console.log(value.length);  // Type error
  }
}

// Better: Modern TypeScript narrows automatically
function process(value: string | null) {
  if (value !== null) {
    console.log(value.length);  // Works; type narrowed to string
  }
}
```

**Signs in commits:** Type narrowing added with explicit `as` casts, refactored to use better control flow, `!` operators added and then removed.

---

## Using `any` as a Workaround

**Pattern:** Type issues solved with `any` instead of fixing the underlying type.

**TypeScript example:**
```typescript
// Weak: Using any to bypass type system
function parseConfig(data: any): Config {
  return data as Config;
}

// Better: Parse with validation
function parseConfig(data: unknown): Config {
  if (!isValidConfig(data)) throw new Error("Invalid config");
  return data as Config;
}
```

**Signs in commits:** Removed `any` types, added type validation, replaced casts with proper type guards.

---

## Recommendations by Language

### TypeScript
- Use strict mode: `"strict": true` in tsconfig.json
- Enable `noImplicitAny` and `noUnusedLocals`
- Prefer explicit over implicit: type everything
- Use discriminated unions for state machines
- Validate at API boundaries (zod, io-ts, valibot)

### Python
- Use type hints with `from typing import`
- Leverage dataclasses or Pydantic for validation
- Use `Optional[T]` instead of `T | None` (in older Python)
- Validate at module boundaries with pydantic

### Swift
- Use optionals explicitly: `T?` vs `T!`
- Prefer non-optional types; unwrap deliberately
- Use `guard let` and `if let` for safe unwrapping
- Leverage Swift's type system for state machines (enums)

### Kotlin
- Use nullable types explicitly: `T?` vs `T`
- Use safe call operator `?.` and Elvis operator `?:`
- Prefer `sealed class` for state machines
- Leverage smart casts with `is` operator
