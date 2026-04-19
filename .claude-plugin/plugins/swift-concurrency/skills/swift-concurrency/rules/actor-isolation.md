---
title: Use Actor Isolation for Data-Race Safety
impact: HIGH
tags: actors, isolation, thread-safety, concurrency
---

## Use Actor Isolation for Data-Race Safety

Actors provide compiler-verified thread-safety without manual lock management. Use actors for mutable shared state in async contexts instead of manual locks or `@unchecked Sendable`.

**Incorrect (manual locking with @unchecked Sendable):**

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    func get(_ key: String) async -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return items[key]  // ❌ Holding lock during async is problematic
    }

    func set(_ key: String, value: Data) {
        lock.lock()
        defer { lock.unlock() }
        items[key] = value
    }

    // ⚠️ Easy to forget lock in computed properties
    var count: Int {
        items.count  // ❌ Data race! No lock held
    }
}
```

**Correct (actor with compiler-verified safety):**

```swift
actor Cache {
    private var items: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        items[key]  // ✅ Compiler guarantees isolation
    }

    func set(_ key: String, value: Data) {
        items[key] = value  // ✅ Automatic serialization
    }

    var count: Int {
        items.count  // ✅ Impossible to forget isolation
    }

    // Nonisolated for synchronous, immutable access
    nonisolated var isEmpty: Bool {
        // Can only access immutable state
        true  // Computed based on immutable properties
    }
}

// Usage - await required for actor methods
let cache = Cache()
await cache.set("key", value: data)
let value = await cache.get("key")
```

**Use isolated parameters to reduce suspension points:**

```swift
actor BankAccount {
    private var balance: Double

    func getBalance() -> Double { balance }
    func withdraw(amount: Double) throws { ... }
}

// Incorrect - multiple suspension points
struct Charger {
    static func charge(amount: Double, from account: BankAccount) async throws {
        let balance = await account.getBalance()  // Suspension 1
        guard balance >= amount else { throw InsufficientFunds() }

        try await account.withdraw(amount: amount)  // Suspension 2
        return await account.getBalance()  // Suspension 3
        // ⚠️ Account state can change between each await (reentrancy)
    }
}

// Correct - isolated parameter eliminates suspensions
struct Charger {
    static func charge(
        amount: Double,
        from account: isolated BankAccount  // ✅ Inherits caller's isolation
    ) throws -> Double {
        // No await needed - we're isolated to account
        let balance = account.getBalance()  // No suspension
        guard balance >= amount else { throw InsufficientFunds() }

        try account.withdraw(amount: amount)  // No suspension
        return account.getBalance()  // No suspension
        // ✅ Atomic operation - account state cannot change mid-function
    }
}
```

**Actor isolation for global mutable state:**

```swift
// Incorrect - global mutable, no protection
var globalCache: [String: Data] = [:]  // ❌ Data race!

// Correct - actor isolation
@MainActor
var globalCache: [String: Data] = [:]  // ✅ Serialized on main thread

// Or use a custom actor
actor GlobalCache {
    static let shared = GlobalCache()
    private var items: [String: Data] = [:]

    func get(_ key: String) -> Data? { items[key] }
    func set(_ key: String, value: Data) { items[key] = value }
}
```

**Why it matters:**

- **Compiler verification**: Actors enforce isolation at compile time - you can't accidentally access actor state without `await`
- **No manual locks**: No need to remember `lock()`/`unlock()`, no deadlocks, no forgotten locks
- **Async-safe**: Actors work naturally with async/await, unlike manual locks which can't be held across suspension points
- **Reentrancy safety**: Each `await` is a potential reentrancy point, but actors serialize all access automatically
- **Performance**: Isolated parameters eliminate suspension overhead for atomic multi-step operations

**When to use actors vs @unchecked Sendable:**

- **Prefer actors** for almost all mutable shared state in async contexts
- Use `@unchecked Sendable` only when:
  - Wrapping proven thread-safe types (`os_unfair_lock`, dispatch queues)
  - Performance-critical synchronous code where actor overhead is measured and unacceptable
  - Always document why `@unchecked Sendable` is safe

Reference: [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md), [SE-0313: Isolated Parameters](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md)
