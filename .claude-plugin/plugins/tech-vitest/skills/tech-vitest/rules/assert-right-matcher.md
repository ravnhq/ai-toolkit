---
title: Use the Right Matcher for Clear Assertions
impact: LOW
tags: assertions, matchers, readability
---

## Use the Right Matcher for Clear Assertions

Choose specific matchers for better error messages and clearer intent.

**Equality:**

```typescript
// Primitives - use toBe
expect(status).toBe('active');
expect(count).toBe(5);
expect(isValid).toBe(true);

// Objects/arrays - use toEqual (deep equality)
expect(user).toEqual({ id: '1', name: 'Test' });
expect(items).toEqual(['a', 'b', 'c']);

// toStrictEqual - stricter (checks undefined props, class instances)
expect(result).toStrictEqual({ id: '1', name: 'Test' });
```

**Truthiness:**

```typescript
// Specific truthy/falsy checks
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();
expect(value).toBeDefined();
```

**Numbers:**

```typescript
expect(price).toBeGreaterThan(0);
expect(price).toBeLessThanOrEqual(100);
expect(percentage).toBeCloseTo(0.3, 2);  // Floating point
```

**Strings:**

```typescript
expect(message).toContain('error');
expect(email).toMatch(/^.+@.+\..+$/);
expect(name).toHaveLength(10);
```

**Arrays:**

```typescript
expect(items).toHaveLength(3);
expect(items).toContain('apple');
expect(items).toContainEqual({ id: '1' });  // Deep equality
expect(items).toEqual(expect.arrayContaining(['a', 'b']));
```

**Objects:**

```typescript
expect(user).toHaveProperty('name');
expect(user).toHaveProperty('address.city', 'NYC');
expect(user).toMatchObject({ name: 'Test' });  // Partial match
expect(result).toEqual(expect.objectContaining({ id: '1' }));
```

**Errors:**

```typescript
expect(() => validate(null)).toThrow();
expect(() => validate(null)).toThrow('Invalid input');
expect(() => validate(null)).toThrow(ValidationError);
await expect(asyncFn()).rejects.toThrow('error');
```

**Why it matters:**
- Specific matchers give better error messages
- Clearer test intent
- Fewer false positives/negatives
- Easier debugging when tests fail

Reference: [Vitest Expect API](https://vitest.dev/api/expect.html)
