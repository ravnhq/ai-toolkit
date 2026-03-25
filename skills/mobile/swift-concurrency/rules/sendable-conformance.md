---
title: Require Sendable for Actor and Task Boundaries
impact: CRITICAL
tags: sendable, thread-safety, data-races, type-safety
---

## Require Sendable for Actor and Task Boundaries

Types that cross concurrency boundaries (passed to actors, tasks, or async functions) must conform to `Sendable` to guarantee thread-safety at compile time.

**Incorrect (non-Sendable type crosses boundaries):**

```swift
class UserSession {  // ❌ Class is not Sendable (mutable reference type)
    var userId: String
    var authToken: String
}

actor AuthManager {
    func login(_ session: UserSession) {  // ⚠️ Non-Sendable in actor
        // Multiple tasks could modify session concurrently → data race
    }
}

Task {
    let session = UserSession()
    await authManager.login(session)  // ❌ Data race possible
    session.userId = "changed"  // Concurrent modification!
}
```

**Correct (explicit Sendable conformance):**

```swift
// Option 1: Make it a value type (struct)
struct UserSession: Sendable {  // ✅ Value types are Sendable if all properties are
    let userId: String
    let authToken: String
}

// Option 2: Use an actor for mutable reference type
actor UserSession {  // ✅ Actors are implicitly Sendable
    var userId: String
    var authToken: String

    init(userId: String, authToken: String) {
        self.userId = userId
        self.authToken = authToken
    }
}

// Option 3: Immutable class (final + all let properties)
final class UserSession: Sendable {  // ✅ Immutable classes can be Sendable
    let userId: String
    let authToken: String

    init(userId: String, authToken: String) {
        self.userId = userId
        self.authToken = authToken
    }
}
```

**Make public value types explicitly Sendable:**

```swift
// Incorrect - implicit conformance for public type
public struct Person {  // ⚠️ Warning: Sendable conformance inferred
    var name: String
    var age: Int
}

// Correct - explicit Sendable for public API
public struct Person: Sendable {  // ✅ Explicit conformance
    var name: String
    var age: Int
}

// Internal types can remain implicit
struct InternalPerson {  // ✅ OK - internal type, implicit Sendable
    var name: String
}
```

**Sendable closures require immutable captures:**

```swift
// Incorrect - mutable capture in @Sendable closure
var count = 0
store.filter { contact in  // ❌ Error: mutable capture in @Sendable closure
    count += 1
    return contact.age > 18
}

// Correct - capture immutable snapshot
let initialCount = count  // Create immutable copy
store.filter { [initialCount] contact in  // ✅ Captures immutably
    print("Starting with \(initialCount)")
    return contact.age > 18
}

// Or use let from the start
let count = 0
store.filter { contact in  // ✅ count is immutable
    return contact.age > 18
}
```

**Use actors instead of @unchecked Sendable:**

```swift
// Incorrect - @unchecked Sendable with mutable state
final class UserCache: @unchecked Sendable {
    private let lock = NSLock()
    private var users: [String: User] = [:]

    func get(_ id: String) -> User? {
        lock.lock()
        defer { lock.unlock() }
        return users[id]
    }

    // ⚠️ Easy to forget lock somewhere
    var count: Int {
        users.count  // ❌ Data race! No lock held
    }
}

// Correct - actor with compiler verification
actor UserCache {
    private var users: [String: User] = [:]

    func get(_ id: String) -> User? {
        users[id]  // ✅ Compiler guarantees safety
    }

    var count: Int {
        users.count  // ✅ Impossible to forget isolation
    }
}
```

**Only use @unchecked Sendable as documented last resort:**

```swift
// Valid use case - wrapping proven thread-safe type
final class ThreadSafeCache: @unchecked Sendable {
    // SAFETY: os_unfair_lock provides thread-safety for all accesses.
    // All methods acquire lock before accessing `storage`.
    // Lock is never held across suspension points.
    private let lock = os_unfair_lock_t.allocate(capacity: 1)
    private var storage: [String: Data] = [:]

    init() {
        os_unfair_lock_init(lock)
    }

    func get(_ key: String) -> Data? {
        os_unfair_lock_lock(lock)
        defer { os_unfair_lock_unlock(lock) }
        return storage[key]
    }

    // All paths documented and protected
}
```

**Sendable requirements by context:**

```swift
// Actor methods require Sendable parameters
actor Database {
    func save(_ user: User) {  // ✅ User must be Sendable
        // ...
    }
}

// Task closures are @Sendable
Task {
    let data = capturedData  // ✅ data must be Sendable
    await process(data)
}

// Async functions crossing isolation boundaries
@MainActor
func updateUI(with data: DataModel) {  // ✅ DataModel must be Sendable
    // Called from background → main thread
}

// Global variables must be Sendable
let sharedConfig: AppConfig = ...  // ✅ AppConfig must be Sendable
```

**What types are Sendable:**

- **Value types** (structs, enums) where all stored properties are Sendable
- **Actors** (implicitly Sendable)
- **Immutable classes** (`final class` with only `let` properties, all Sendable)
- **@MainActor types** (serialized on main thread)
- **@unchecked Sendable** (opt-out, use sparingly with documentation)

**What types are NOT Sendable:**

- Mutable classes (unless using `@unchecked Sendable`)
- Classes with `var` properties
- Types containing non-Sendable properties
- Closures that capture mutable state

**Why it matters:**

- **Compile-time safety**: Sendable violations are caught at compile time, not runtime
- **Prevents data races**: Types crossing concurrency boundaries are guaranteed thread-safe
- **Eliminates entire bug class**: No more subtle concurrency bugs from shared mutable state
- **Documentation**: `Sendable` conformance signals thread-safety to API users
- **Future-proof**: Explicit `Sendable` on public APIs prevents accidental breaking changes

Reference: [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
