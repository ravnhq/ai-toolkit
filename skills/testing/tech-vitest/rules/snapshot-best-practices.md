---
title: Use Snapshots Intentionally for Stable Output
impact: MEDIUM
tags: snapshot, testing, assertion
---

## Use Snapshots Intentionally for Stable Output

Use `toMatchSnapshot()` and `toMatchInlineSnapshot()` only for stable, non-volatile output. Snapshots are powerful for catching unintended regressions in UI and data structure serialization, but misuse can hide bugs. Always review snapshot diffs before committing.

**Problem: snapshot hides bugs instead of catching them**

```typescript
// BAD — snapshot on dynamic data masks bugs
test('generates order summary', () => {
  const order = createOrder({
    items: [{ name: 'Widget', price: 100 }],
    timestamp: new Date(), // Changes every test run
  });

  // Snapshot passes even if tax calculation breaks
  expect(order).toMatchSnapshot();
});
```

**Solution: snapshot stable output, assert volatile parts separately**

```typescript
// GOOD — snapshot structure, assert calculations
test('generates order summary', () => {
  vi.setSystemTime(new Date('2024-01-01'));

  const order = createOrder({
    items: [{ name: 'Widget', price: 100 }],
  });

  // Assert calculations explicitly
  expect(order.subtotal).toBe(100);
  expect(order.tax).toBe(10);
  expect(order.total).toBe(110);

  // Snapshot only the structure and label strings
  expect({
    id: order.id,
    status: order.status,
    itemNames: order.items.map(i => i.name),
  }).toMatchSnapshot();
});
```

**Inline snapshots for short strings:**

```typescript
// Good — use inline snapshots for readable, compact assertions
test('formats user display name', () => {
  const name = formatDisplayName({ first: 'Jane', last: 'Doe' });
  expect(name).toMatchInlineSnapshot('"Jane Doe"');
});

test('generates error message', () => {
  expect(() => {
    validateEmail('invalid');
  }).toThrowErrorMatchingInlineSnapshot(
    '[Error: Email must contain @ symbol]'
  );
});
```

**Update snapshots intentionally with --ui:**

```bash
# Review changes before accepting
vitest --ui

# Or update from CLI, then review in git diff
vitest -u
git diff __snapshots__/

# In CI, never auto-update
vitest --no-update
```

**Common pitfall: snapshots with IDs and timestamps:**

```typescript
// BAD — snapshot includes generated values
const user = createUser({ email: 'test@example.com' });
expect(user).toMatchSnapshot();
// ❌ Snapshot fails every time due to id, createdAt

// GOOD — exclude volatile fields
const { id, createdAt, ...stable } = user;
expect(stable).toMatchSnapshot();
expect(id).toBeDefined();
expect(createdAt).toBeInstanceOf(Date);
```

**Snapshot vs explicit assertions:**

| Use Case | Tool | Why |
|----------|------|-----|
| Component rendering (JSX) | `toMatchSnapshot()` | Structure rarely changes; CSS updates obvious |
| UI error message | `toMatchSnapshot()` or inline | User-facing text should be versioned |
| JSON API response | Explicit assertions | Assertions document the contract; snapshots hide it |
| Serialized data (dates, IDs) | Explicit assertions | Volatile fields break snapshots |
| HTML structure | `toMatchSnapshot()` | Catches DOM changes at a glance |

**Why it matters:**
- Snapshots are maintenance-heavy; each code change requires review and re-acceptance
- Snapshots mask regressions in logic (e.g., tax calculations) if data is volatile
- Used correctly, snapshots catch regressions in output format and structure
- Inline snapshots stay in test files and are easier to review
- Snapshot diffs in PR reviews document what changed and why

Reference: [Vitest Snapshot Testing](https://vitest.dev/guide/snapshot.html)
