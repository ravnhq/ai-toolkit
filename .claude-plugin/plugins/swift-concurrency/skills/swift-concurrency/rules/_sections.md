# Sections

This file defines all sections, their ordering, impact levels, and descriptions for Swift Concurrency rules.

---

## 1. Async/Await Patterns (async)

**Impact:** CRITICAL
**Description:** Core patterns for async/await usage, including avoiding dummy suspension points that mislead callers and add unnecessary overhead.

## 2. Actor Isolation (actor)

**Impact:** HIGH
**Description:** Actor-based data-race safety patterns for mutable shared state, providing compiler-verified thread-safety without manual locks.

## 3. Task Lifecycle (task)

**Impact:** HIGH
**Description:** Task lifecycle management, cancellation propagation, and structured concurrency patterns for automatic resource cleanup.

## 4. Sendable Conformance (sendable)

**Impact:** CRITICAL
**Description:** Sendable type conformance requirements for crossing concurrency boundaries safely, enforcing thread-safety at compile time.

## 5. Testing (test)

**Impact:** MEDIUM
**Description:** Patterns for testing async concurrent code, avoiding flaky tests, and using modern testing frameworks like Swift Testing.
