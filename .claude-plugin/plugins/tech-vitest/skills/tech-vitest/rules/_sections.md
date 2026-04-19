# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Mocking (mock)

**Impact:** HIGH
**Description:** Vitest provides vi.mock, vi.fn, and vi.spyOn for mocking. Understand when and how to use each.

- [mock-msw-external-apis](./mock-msw-external-apis.md) — Use MSW to mock HTTP APIs at the network level

## 2. Hooks (hooks)

**Impact:** MEDIUM
**Description:** Test lifecycle hooks (beforeEach, afterEach, etc.) for setup and teardown. Use judiciously.

## 3. Assertions (assert)

**Impact:** LOW
**Description:** Vitest's expect API with matchers. Choose the right matcher for clear, readable assertions.
