# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Architecture (arch)

**Impact:** CRITICAL
**Description:** Clean Architecture layer boundaries and unidirectional data flow. The foundation for testable, maintainable Android apps.

## 2. Accessibility (a11y)

**Impact:** HIGH
**Description:** Content descriptions, touch targets, and heading semantics for inclusive Compose UI.

## 3. Concurrency (concurrency)

**Impact:** CRITICAL
**Description:** Structured concurrency with coroutines, lifecycle-aware Flow collection, and proper dispatcher usage.

## 4. Compose (compose)

**Impact:** HIGH
**Description:** Jetpack Compose patterns including state hoisting, remember/rememberSaveable, side effects, animations, theming, recomposition stability, and lazy list performance.

## 5. Persistence (room)

**Impact:** MEDIUM
**Description:** Room database patterns for entity design, migrations, and reactive queries.

## 6. Networking (net)

**Impact:** HIGH
**Description:** Retrofit and Ktor client configuration, error handling, and best practices.

## 7. Navigation (nav)

**Impact:** MEDIUM
**Description:** Compose Navigation patterns including type-safe arguments, deep links, and single-activity architecture.

## 8. Dependency Injection (di)

**Impact:** MEDIUM
**Description:** Hilt/Dagger scoping and assisted injection for correct lifecycle management.

## 9. Testing (test)

**Impact:** HIGH
**Description:** Compose UI testing via semantics, testable coroutine code, and Flow testing with Turbine.

## 10. Permissions (perm)

**Impact:** HIGH
**Description:** Runtime permission requests, rationale handling, and permission state management in Compose.
