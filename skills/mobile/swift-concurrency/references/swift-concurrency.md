# Swift Concurrency Patterns Reference

This document consolidates best practices and patterns for Swift Concurrency, extracted from Apple's documentation, Swift Evolution proposals, and real-world development experience. These patterns cover async/await fundamentals, structured concurrency, actors, Sendable conformance, memory management, testing, and migration strategies.

## 1. Async/Await Fundamentals

### Never Fix async_without_await With Dummy Suspension

When a linter warns that an `async` function has no `await`, adding dummy `Task.yield()` or `Task.sleep()` just to silence the warning is dangerous and misleading.

**Incorrect (dummy suspension to silence warning):**

```swift
func processData(_ data: Data) async -> Result {
    await Task.yield()  // ❌ Dummy suspension, no actual async work

    let processed = transform(data)  // Synchronous work
    return Result(processed)
}
```

**Correct (remove async if no suspension needed):**

```swift
func processData(_ data: Data) -> Result {
    let processed = transform(data)
    return Result(processed)
}
```

**Or (if async is needed for protocol conformance):**

```swift
protocol DataProcessor {
    func processData(_ data: Data) async -> Result
}

// Keep async for protocol conformance, document why
func processData(_ data: Data) async -> Result {
    // Synchronous implementation of async protocol requirement
    let processed = transform(data)
    return Result(processed)
}
```

**Why it matters:** Dummy suspension points mislead callers into thinking the function does async work, add unnecessary overhead from task switching, hide the fact that the function could be synchronous, and violate the principle that `async` indicates actual asynchronous operations. Only mark functions `async` if they genuinely perform asynchronous work or must conform to an async protocol.

Reference: [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

### Avoid Redundant try/await in async let

`async let` starts execution immediately. Don't use `try await` in the `async let` line - handle errors at the await point where you access the value.

**Incorrect (redundant keywords):**

```swift
async let data = try await fetchData()  // ❌ Redundant try/await
let result = await data
```

**Correct (errors handled at await point):**

```swift
async let data = fetchData()  // ✅ Starts immediately
let result = try await data   // Errors handled here
```

**Why it matters:** The redundant keywords don't add safety and create confusion about when execution starts. `async let` starts the operation immediately without waiting. Errors are naturally handled when you `await` the result.

Reference: [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

### Use async let for Fixed Parallel Operations

When you have a fixed number of independent async operations, use `async let` for automatic structured concurrency with compile-time known parallelism.

**Incorrect (sequential execution):**

```swift
func loadProfile() async throws -> Profile {
    let user = try await fetchUser()
    let settings = try await fetchSettings()  // Waits for user first
    let notifications = try await fetchNotifications()  // Waits for settings

    return Profile(user: user, settings: settings, notifications: notifications)
}
```

**Correct (parallel execution):**

```swift
func loadProfile() async throws -> Profile {
    async let user = fetchUser()
    async let settings = fetchSettings()
    async let notifications = fetchNotifications()

    return try await Profile(
        user: user,
        settings: settings,
        notifications: notifications
    )
}
```

**Why it matters:** Sequential awaits waste time when operations are independent. `async let` starts all operations immediately in parallel, provides automatic cancellation on scope exit, and reduces total execution time proportionally to the number of parallel operations. For dynamic/loop-based parallelism, use task groups instead.

Reference: [Swift Concurrency Course](https://www.swiftconcurrencycourse.com)

---

### Use Typed Errors for Precise API Contracts

Swift 6 supports typed throws to specify exact error types, making API contracts explicit and eliminating impossible error cases.

**Incorrect (generic Error):**

```swift
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// Caller doesn't know which errors to handle
do {
    let data = try await fetchData()
} catch {
    // What type is error? URLError? DecodingError? NetworkError?
}
```

**Correct (typed throws):**

```swift
enum NetworkError: Error {
    case invalidResponse
    case decodingFailed(DecodingError)
    case requestFailed(URLError)
}

func fetchData() async throws(NetworkError) -> Data {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    } catch let error as URLError {
        throw .requestFailed(error)
    } catch {
        throw .invalidResponse
    }
}

// Caller knows exactly which errors to handle
do {
    let data = try await fetchData()
} catch .invalidResponse {
    // Handle invalid response
} catch .requestFailed(let urlError) {
    // Handle network error
}
```

**Why it matters:** Typed errors make API contracts explicit, enable exhaustive error handling, eliminate impossible catch cases, and improve code documentation. Callers know exactly which errors can occur without reading implementation details.

Reference: [Swift Evolution - Typed throws](https://github.com/apple/swift-evolution/blob/main/proposals/0413-typed-throws.md)

---

## 2. Tasks & Structured Concurrency

### Use Task.detached Only With Clear Justification

`Task.detached` creates tasks with no connection to the caller - no priority inheritance, no task-local values, no cancellation propagation. This is rarely what you want.

**Incorrect (detached task loses context):**

```swift
@MainActor
func processData(_ data: Data) {
    Task.detached {  // ❌ Loses @MainActor context
        let result = await process(data)
        // How do we update UI? Not on MainActor anymore!
    }
}
```

**Correct (regular Task inherits context):**

```swift
@MainActor
func processData(_ data: Data) {
    Task {  // ✅ Inherits @MainActor, priority, cancellation
        let result = await process(data)
        updateUI(result)  // Safe - still on @MainActor
    }
}
```

**Valid use case (completely independent background work):**

```swift
Task.detached(priority: .background) {
    await DirectoryCleaner.cleanup()  // Truly independent, low priority
}
```

**Why it matters:** Detached tasks lose actor isolation, priority, task-local values, and cancellation state. They're isolated from the caller's execution context, making it easy to violate thread-safety assumptions. Regular `Task { }` inherits priority and can be used in most cases. Only use `Task.detached` for truly independent background work that should run regardless of caller state.

Reference: [Swift Concurrency Course - Detached Tasks](https://www.swiftconcurrencycourse.com)

---

### Check Cancellation at Natural Breakpoints

Tasks don't stop automatically when canceled. You must manually check `Task.isCancelled` or call `Task.checkCancellation()` at appropriate points to stop work.

**Incorrect (ignores cancellation):**

```swift
let task = Task {
    let data = try await URLSession.shared.data(from: url)
    // No cancellation check - continues even if canceled
    let processed = await expensiveProcessing(data)  // Wastes resources
    let stored = await storeInDatabase(processed)     // Wasteful work
    return stored
}

task.cancel()  // Task continues running!
```

**Correct (checks cancellation at breakpoints):**

```swift
let task = Task {
    try Task.checkCancellation()  // Before network

    let data = try await URLSession.shared.data(from: url)

    try Task.checkCancellation()  // After network, before processing

    let processed = await expensiveProcessing(data)

    try Task.checkCancellation()  // Before database

    return await storeInDatabase(processed)
}

task.cancel()  // Stops at next checkpoint
```

**Why it matters:** Unchecked cancellation wastes CPU, memory, network bandwidth, and battery. Long-running tasks may continue indefinitely even after being canceled. Check cancellation before expensive operations, after await points, and in loops. Use `try Task.checkCancellation()` to throw `CancellationError`, or `guard !Task.isCancelled` for custom handling.

Reference: [Swift Concurrency Course - Task Cancellation](https://www.swiftconcurrencycourse.com)

---

### Use Discarding Task Groups for Fire-and-Forget Work

When you don't need task results (logging, analytics, preloading), use `withDiscardingTaskGroup` for better memory efficiency.

**Incorrect (storing unused results):**

```swift
await withTaskGroup(of: Void.self) { group in
    group.addTask { await logEvent("user_login") }
    group.addTask { await preloadCache() }
    group.addTask { await syncAnalytics() }

    // Must iterate to avoid leaking results
    for await _ in group { }  // ❌ Unnecessary overhead
}
```

**Correct (discarding task group):**

```swift
await withDiscardingTaskGroup { group in
    group.addTask { await logEvent("user_login") }
    group.addTask { await preloadCache() }
    group.addTask { await syncAnalytics() }
}  // ✅ Automatically waits, no result storage
```

**Why it matters:** Regular task groups store all results in memory until consumed with `next()` or iteration. For side-effect work where results don't matter, this wastes memory. Discarding task groups don't store results, automatically wait for completion, and prevent result buffer growth. Use for logging, analytics, cache warming, notifications, and other fire-and-forget operations.

Reference: [Swift Concurrency Course - Discarding Task Groups](https://www.swiftconcurrencycourse.com)

---

### Never Nest Task Blocks Inside Task Groups

Nesting `Task { }` blocks inside task groups or structured concurrency creates unstructured tasks that don't participate in the parent's cancellation hierarchy.

**Incorrect (nested Task loses cancellation):**

```swift
await withTaskGroup(of: Void.self) { group in
    for item in items {
        group.addTask {
            // ❌ This nested Task is UNSTRUCTURED
            Task {
                await process(item)  // Won't cancel when group cancels!
            }
        }
    }

    group.cancelAll()  // Nested tasks continue running!
}
```

**Correct (direct work in task group):**

```swift
await withTaskGroup(of: Void.self) { group in
    for item in items {
        group.addTask {
            await process(item)  // ✅ Cancels with group
        }
    }

    group.cancelAll()
}
```

**Why it matters:** Nested `Task { }` blocks inherit actor context (e.g., `@MainActor`) but do NOT inherit cancellation. When the parent group or task is canceled, nested tasks continue executing, leading to resource leaks, unnecessary work, and potential crashes when accessing deallocated state.

Reference: [Swift Concurrency Course - Task Groups](https://www.swiftconcurrencycourse.com)

---

### Prefer Structured Concurrency Over Unstructured Tasks

Structured concurrency (`async let`, task groups) provides automatic cancellation propagation and resource cleanup. Use unstructured `Task { }` only when you need independent lifecycle.

**Incorrect (unstructured tasks require manual management):**

```swift
func loadProfile() async throws -> Profile {
    let userTask = Task { try await fetchUser() }
    let settingsTask = Task { try await fetchSettings() }

    // ❌ Must manually manage cancellation and errors
    let user = try await userTask.value
    let settings = try await settingsTask.value

    return Profile(user: user, settings: settings)
}
// If function throws early, tasks keep running
```

**Correct (structured concurrency with auto-cleanup):**

```swift
func loadProfile() async throws -> Profile {
    async let user = fetchUser()
    async let settings = fetchSettings()

    // ✅ Automatic cancellation if scope exits
    return try await Profile(user: user, settings: settings)
}
// If function throws, user and settings tasks auto-cancel
```

**Why it matters:** Structured concurrency provides automatic cancellation propagation (child tasks cancel when parent does), guaranteed cleanup on scope exit, and compile-time safety. Unstructured tasks can leak, continue running after errors, and require manual cancellation. Only use unstructured `Task { }` for fire-and-forget work or when tasks must outlive their creation scope.

Reference: [SE-0304: Structured Concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)

---

### Implement Timeout Using Task Group Pattern

Swift doesn't provide built-in timeout, but you can implement it using task groups by racing the operation against a sleep task.

**Incorrect (no timeout, hangs indefinitely):**

```swift
let data = try await slowNetworkRequest()  // ❌ May never complete
```

**Correct (timeout using task group):**

```swift
struct TimeoutError: Error {}

func withTimeout<T>(
    _ duration: Duration,
    operation: @Sendable @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }

        group.addTask {
            try await Task.sleep(for: duration)
            throw TimeoutError()
        }

        guard let result = try await group.next() else {
            throw TimeoutError()
        }

        group.cancelAll()  // Cancel remaining task
        return result
    }
}

// Usage
let data = try await withTimeout(.seconds(5)) {
    try await slowNetworkRequest()
}
```

**Why it matters:** Operations without timeouts can hang indefinitely, consuming resources and blocking user workflows. The task group pattern provides a clean, reusable timeout mechanism. The first task to complete (either the operation or the timeout) wins, and the other is automatically canceled. This prevents resource leaks and provides predictable failure modes.

Reference: [Swift Concurrency Course - Task Groups](https://www.swiftconcurrencycourse.com)

---

## 3. Actors & Isolation

### Avoid assumeIsolated in Favor of Explicit Isolation

`assumeIsolated` bypasses compiler checks and crashes at runtime if the assumption is wrong. Prefer explicit `@MainActor` or `await MainActor.run`.

**Incorrect (assumeIsolated with hidden assumptions):**

```swift
@MainActor
func updateUI() {
    // Implementation
}

func methodB() {
    // ❌ Assumes main thread, crashes if wrong
    MainActor.assumeIsolated {
        updateUI()
    }
}
```

**Correct (explicit isolation with compile-time safety):**

```swift
@MainActor
func updateUI() {
    // Implementation
}

@MainActor  // ✅ Compiler verifies isolation
func methodB() {
    updateUI()
}

// Or if can't mark @MainActor
func methodC() async {
    await MainActor.run {  // ✅ Explicit hop, no crash risk
        updateUI()
    }
}
```

**Valid use case (proven invariant):**

```swift
func setup() {
    assert(Thread.isMainThread, "Must be called on main thread")

    MainActor.assumeIsolated {
        // OK - documented precondition, asserted
        updateUI()
    }
}
```

**Why it matters:** `assumeIsolated` crashes at runtime if the assumption is wrong, bypasses compiler safety checks, and hides isolation requirements from callers. Explicit `@MainActor` or `await MainActor.run` provides compile-time verification, clearer API contracts, and no crash risk. Only use `assumeIsolated` when you have a proven invariant (e.g., legacy callback known to run on main thread), and always document and assert the assumption.

Reference: [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

### Complete State Changes Before Suspension Points

Actors release their lock at `await` suspension points, allowing other tasks to interleave. State can change between suspension points within the same method.

**Incorrect (state changes after suspension):**

```swift
actor BankAccount {
    var balance: Double

    func deposit(amount: Double) async {
        balance += amount

        // ⚠️ Actor unlocked during await - balance may change!
        await logActivity("Deposited \(amount)")

        // ⚠️ Balance may be different now
        print("Balance: \(balance)")
    }
}

// Parallel deposits may all print same balance:
async let _ = account.deposit(50)
async let _ = account.deposit(50)
async let _ = account.deposit(50)
// Balance: 150
// Balance: 150
// Balance: 150
```

**Correct (complete state work before suspension):**

```swift
actor BankAccount {
    var balance: Double

    func deposit(amount: Double) async {
        balance += amount
        let newBalance = balance  // Capture state BEFORE suspension

        await logActivity("Deposited \(amount)")

        // Use captured value, not mutable state
        print("Balance: \(newBalance)")
    }
}
```

**Why it matters:** Actor reentrancy is a common source of subtle bugs. Assuming state is unchanged after `await` leads to race conditions, incorrect calculations, and data corruption. All critical state changes must complete before the first suspension point in an actor method.

Reference: [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

---

### Use Mutex for Synchronous Low-Contention Access

When you need thread-safe mutable state in synchronous code with low contention, use `Mutex` from the Synchronization framework instead of actors.

**Incorrect (actor forces async for sync code):**

```swift
actor Counter {
    private var count: Int = 0

    func increment() { count += 1 }  // Actor method
}

// Usage - forces async
func updateCount(counter: Counter) async {
    await counter.increment()  // ❌ Unnecessary suspension for sync work
}
```

**Correct (Mutex for synchronous access):**

```swift
import Synchronization

final class Counter {
    private let count = Mutex<Int>(0)

    var currentCount: Int {
        count.withLock { $0 }
    }

    func increment() {
        count.withLock { $0 += 1 }  // ✅ Synchronous, no await
    }
}

// Usage - synchronous
func updateCount(counter: Counter) {
    counter.increment()  // ✅ No await needed
}
```

**Why it matters:** Actors require `await` even for simple operations, adding suspension overhead. `Mutex` provides synchronous locking for simple state protection without async overhead. Use `Mutex` for synchronous contexts, legacy code integration, and fine-grained locking. Use actors when you can adopt async/await, need logical isolation, or work in async contexts. Requires iOS 18+, macOS 15+.

Reference: [Swift Synchronization](https://github.com/apple/swift-evolution/blob/main/proposals/0433-mutex.md)

---

### Do Not Use @MainActor as Blanket Fix

Adding `@MainActor` to silence concurrency warnings without understanding isolation needs forces unnecessary main-thread execution and harms performance.

**Incorrect (@MainActor on non-UI code):**

```swift
@MainActor  // ❌ Forces background work onto main thread
class DataProcessor {
    func processLargeDataset(_ data: [Item]) async -> [Result] {
        // Heavy computation on main thread - blocks UI!
        return data.map { processItem($0) }
    }
}
```

**Correct (isolated only where needed):**

```swift
class DataProcessor {
    func processLargeDataset(_ data: [Item]) async -> [Result] {
        // ✅ Runs on background thread
        return data.map { processItem($0) }
    }

    @MainActor
    func updateUI(with results: [Result]) {
        // Only UI updates on main thread
        self.displayResults(results)
    }
}
```

**Why it matters:** `@MainActor` forces all method calls to serialize on the main thread, blocking UI and degrading performance. Only use `@MainActor` for code that genuinely accesses UI or must run on the main thread. Background operations, networking, parsing, and computation should run concurrently on background threads. Indiscriminate use of `@MainActor` eliminates the benefits of async/await concurrency.

Reference: [SE-0316: Global Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0316-global-actors.md)

---

### Prefer Actors Over Manual Locks for Async Code

Actors provide compiler-verified thread-safety without manual lock management. Manual locks are error-prone and don't compose well with async/await.

**Incorrect (manual locking with @unchecked Sendable):**

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    func get(_ key: String) async -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return items[key]  // ❌ Holding lock during async is wrong
    }

    // ⚠️ Easy to forget lock
    var count: Int {
        items.count  // Data race!
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
        items[key] = value
    }

    var count: Int { items.count }  // ✅ Impossible to forget isolation
}
```

**Why it matters:** Manual locks require correct acquisition/release in all code paths, can't be held across suspension points, don't compose with async/await, and aren't checked by the compiler. Actors provide automatic serialization, compiler verification, support for async methods, and elimination of manual lock management. Use `Mutex` for synchronous low-contention cases; use actors for async contexts.

Reference: [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

---

### Use Isolated Parameters to Reduce Suspension Points

Isolated parameters let you inherit the caller's actor isolation, eliminating await suspension points for multiple actor method calls.

**Incorrect (multiple suspension points):**

```swift
struct Charger {
    static func charge(amount: Double, from account: BankAccount) async throws {
        let balance = await account.getBalance()  // Suspension 1
        guard balance >= amount else { throw InsufficientFunds() }

        try await account.withdraw(amount: amount)  // Suspension 2
        return await account.getBalance()  // Suspension 3
    }
}
```

**Correct (isolated parameter, no suspensions):**

```swift
struct Charger {
    static func charge(
        amount: Double,
        from account: isolated BankAccount
    ) throws -> Double {
        // No await needed - we're isolated to account
        let balance = account.getBalance()  // ✅ No suspension
        guard balance >= amount else { throw InsufficientFunds() }

        try account.withdraw(amount: amount)  // ✅ No suspension
        return account.getBalance()  // ✅ No suspension
    }
}
```

**Why it matters:** Each `await` is a suspension point where actor state can change due to reentrancy. Isolated parameters eliminate suspensions by running the entire function within the caller's actor isolation. This reduces reentrancy bugs, improves performance by avoiding thread hops, and enables atomic multi-step actor operations. Use isolated parameters for helper functions and transaction-like operations.

Reference: [SE-0313: Improved control over actor isolation](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md)

---

## 4. Sendable & Data Safety

### Make Public Value Types Explicitly Sendable

Public structs and enums require explicit `Sendable` conformance. The compiler can't verify internal details across module boundaries.

**Incorrect (implicit conformance for public type):**

```swift
public struct Person {  // ⚠️ Warning: Sendable conformance inferred, but public
    var name: String
    var age: Int
}
```

**Correct (explicit Sendable for public API):**

```swift
public struct Person: Sendable {  // ✅ Explicit conformance
    var name: String
    var age: Int
}
```

**Internal types can remain implicit:**

```swift
struct InternalPerson {  // ✅ OK - internal type, implicit Sendable
    var name: String
}
```

**Why it matters:** The compiler can't verify that future internal changes to public types maintain thread-safety across modules. Explicit `Sendable` makes the conformance intentional and part of the public contract. Non-public types can use implicit conformance when all stored properties are Sendable. This ensures that `Sendable` conformance is a deliberate, documented API decision.

Reference: [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)

---

### Use Actor Isolation for Global Mutable Variables

Global mutable variables are accessible from any context and must be concurrency-safe. Use actor isolation or make them immutable and Sendable.

**Incorrect (mutable global without isolation):**

```swift
class ImageCache {
    static var shared = ImageCache()  // ⚠️ Mutable, not concurrency-safe
    private var images: [URL: UIImage] = [:]
}
```

**Correct (actor isolation):**

```swift
@MainActor
class ImageCache {
    static var shared = ImageCache()  // ✅ Isolated to MainActor
    private var images: [URL: UIImage] = [:]
}
```

**Or (immutable + Sendable):**

```swift
final class ImageCache: Sendable {
    static let shared = ImageCache()  // ✅ Immutable, Sendable

    // Internal mutable state protected by actor or Mutex
}
```

**Or (nonisolated(unsafe) as last resort):**

```swift
struct APIProvider: Sendable {
    nonisolated(unsafe) static private(set) var shared: APIProvider!  // ⚠️ Document safety

    static func configure(apiURL: URL) {
        // Called once at app launch on main thread
        shared = APIProvider(apiURL: apiURL)
    }
}
```

**Why it matters:** Global variables can be accessed from any isolation domain (main thread, background tasks, actors). Without protection, concurrent access causes data races. Actor isolation (`@MainActor`) serializes all access. Immutable + `Sendable` guarantees thread-safety through immutability. `nonisolated(unsafe)` disables checks - use only when you can prove single-threaded initialization, and use `private(set)` to limit mutations.

Reference: [Swift Concurrency Course - Global Variables](https://www.swiftconcurrencycourse.com)

---

### Capture Immutably in @Sendable Closures

`@Sendable` closures can only capture immutable values. Use capture lists to create immutable snapshots of mutable variables.

**Incorrect (capturing mutable variable):**

```swift
var query = "search"

store.filter { contact in  // ❌ Error: mutable capture in @Sendable closure
    contact.name.contains(query)
}

query = "new search"  // Mutation visible to closure
```

**Correct (immutable capture list):**

```swift
var query = "search"

store.filter { [query] contact in  // ✅ Captures immutable snapshot
    contact.name.contains(query)
}

query = "new search"  // Mutation NOT visible to closure
```

**Or use let binding:**

```swift
let query = "search"  // ✅ Immutable from the start

store.filter { contact in
    contact.name.contains(query)
}
```

**Why it matters:** Mutable variables captured by `@Sendable` closures create data races when the closure runs on a different thread. The compiler prevents mutable captures to eliminate this entire class of bugs. Capture lists create an immutable snapshot at capture time, ensuring thread-safety. Use `[value]` syntax to capture immutably, or declare variables with `let` when possible.

Reference: [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)

---

### Prefer Actors Over @unchecked Sendable for Mutable State

When you need thread-safe mutable state, use actors for compiler-verified safety instead of `@unchecked Sendable` with manual locks.

**Incorrect (@unchecked Sendable, manual locking):**

```swift
final class UserCache: @unchecked Sendable {
    private let lock = NSLock()
    private var users: [UUID: User] = [:]

    func getUser(_ id: UUID) -> User? {
        lock.lock()
        defer { lock.unlock() }
        return users[id]
    }

    func setUser(_ user: User) {
        lock.lock()  // ⚠️ Easy to forget
        defer { lock.unlock() }
        users[user.id] = user
    }

    // ❌ Forgot lock - data race!
    func count() -> Int {
        users.count
    }
}
```

**Correct (actor with automatic safety):**

```swift
actor UserCache {
    private var users: [UUID: User] = [:]

    func getUser(_ id: UUID) -> User? {
        users[id]  // ✅ Compiler guarantees isolation
    }

    func setUser(_ user: User) {
        users[user.id] = user
    }

    func count() -> Int {
        users.count  // ✅ Impossible to forget isolation
    }
}
```

**Why it matters:** `@unchecked Sendable` disables all compiler safety checks, making it easy to introduce data races through forgotten locks or incorrect lock ordering. Actors provide compile-time verification that all state access is serialized. The compiler prevents direct property access and enforces isolation. Only use `@unchecked Sendable` for proven thread-safe code with manual synchronization you can't refactor, and document why it's safe.

Reference: [SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)

---

### Use @unchecked Sendable Only as Documented Last Resort

`@unchecked Sendable` disables compiler safety checks. It should only be used when you have proven thread-safety through manual synchronization, and the reason must be documented.

**Incorrect (hiding safety issues):**

```swift
final class Cache: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]

    // ⚠️ Forgot lock - data race!
    var count: Int {
        items.count
    }

    func get(_ key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return items[key]
    }
}
```

**Correct (use actor instead):**

```swift
actor Cache {
    private var items: [String: Data] = [:]

    var count: Int { items.count }  // ✅ Compiler-verified safety

    func get(_ key: String) -> Data? {
        items[key]
    }

    func set(_ key: String, value: Data) {
        items[key] = value
    }
}
```

**Why it matters:** `@unchecked Sendable` eliminates compile-time safety without adding runtime checks. It's easy to forget synchronization in one code path, introducing data races that are difficult to debug. Thread Sanitizer may not catch all cases. Use actors for automatic, compiler-verified thread-safety instead.

Reference: [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)

---

## 5. Threading & Execution

### Use @concurrent to Force Background Execution

The `@concurrent` attribute ensures a function runs on the global concurrent executor (background threads), not inheriting the caller's isolation.

**Incorrect (inherits MainActor, blocks UI):**

```swift
func processLargeFile(_ data: Data) async -> Result {
    // ❌ If called from @MainActor, runs on main thread
    return await heavyProcessing(data)
}

@MainActor
func loadAndProcess() async {
    let result = await processLargeFile(data)  // Blocks UI!
}
```

**Correct (@concurrent forces background):**

```swift
@concurrent
func processLargeFile(_ data: Data) async -> Result {
    // ✅ Always runs on background thread
    return await heavyProcessing(data)
}

@MainActor
func loadAndProcess() async {
    let result = await processLargeFile(data)  // ✅ Runs in background
}
```

**Why it matters:** By default, async functions inherit the caller's actor isolation. If a `@MainActor` function calls an async function without explicit isolation, that function also runs on the main thread, potentially blocking UI. `@concurrent` breaks inheritance and forces background execution on the global concurrent executor. Use for CPU-intensive work, large file processing, and operations that should never block the main thread.

Reference: [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)

---

### Configure Default Actor Isolation for App Targets

For app targets (not libraries), set `@MainActor` as default isolation to ensure UI code runs on the main thread by default.

**Incorrect (no default isolation, easy to forget @MainActor):**

```swift
// No default isolation configured
class ViewModel {  // ⚠️ Could be accessed from any thread
    var items: [Item] = []

    func updateItems(_ newItems: [Item]) {
        items = newItems  // ⚠️ May cause UI crashes
    }
}
```

**Correct (configure default @MainActor isolation):**

```swift
// In build settings, enable: Default Actor Isolation = @MainActor

class ViewModel {  // ✅ Implicitly @MainActor
    var items: [Item] = []

    func updateItems(_ newItems: [Item]) {
        items = newItems  // ✅ Safe - on main thread
    }
}

// Opt-out where needed
nonisolated class BackgroundProcessor {
    func process() async {
        // Runs on background
    }
}
```

**Configuration:**
```
// In target build settings or Package.swift
swiftSettings: [
    .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
    .unsafeFlags(["-Xfrontend", "-default-actor-isolation=main-actor"])
]
```

**Why it matters:** App code is predominantly UI-bound. Defaulting to `@MainActor` isolation makes the common case (UI code) safe by default. Background processing can opt-out with `nonisolated`. This reduces boilerplate `@MainActor` annotations and prevents accidental main-thread violations. Don't use for library targets where callers control execution context.

Reference: [Swift Forums - Default Isolation](https://forums.swift.org/t/default-actor-isolation/64094)

---

### Think in Isolation Domains Not Threads

Swift Concurrency uses isolation domains (actors, `@MainActor`, nonisolated), not direct thread management. Tasks can switch threads but maintain isolation.

**Incorrect (thread-based thinking):**

```swift
func updateUI() {
    // ❌ Thread.current unreliable in async contexts
    if Thread.isMainThread {
        label.text = "Updated"
    } else {
        DispatchQueue.main.async {
            label.text = "Updated"
        }
    }
}
```

**Correct (isolation-based thinking):**

```swift
@MainActor
func updateUI() {
    // ✅ Guaranteed to be on MainActor, compiler-verified
    label.text = "Updated"
}

// Or explicit hop
func updateUIFromBackground() async {
    await MainActor.run {
        label.text = "Updated"
    }
}
```

**Why it matters:** Swift tasks don't map 1:1 to threads - a task may resume on a different thread after `await`. `Thread.current` is unreliable in async contexts (unavailable in Swift 6 language mode). Isolation domains (`@MainActor`, actors) provide the guarantee you actually need: serialized access to shared state. Actors serialize task execution regardless of underlying threads. Think "which actor isolation?" not "which thread?"

Reference: [Swift Concurrency Course - Threading](https://www.swiftconcurrencycourse.com)

---

### Avoid Thread.current in Async Contexts

`Thread.current` is unreliable in async code because tasks can resume on different threads after suspension. In Swift 6 language mode, it's unavailable from async contexts.

**Incorrect (relying on Thread.current):**

```swift
func processData() async {
    print("Starting on: \(Thread.current)")  // ❌ Unreliable

    try await Task.sleep(for: .seconds(1))

    print("Resumed on: \(Thread.current)")  // ❌ Likely different thread!
}
```

**Correct (reason about isolation, not threads):**

```swift
@MainActor
func processData() async {
    // ✅ Guaranteed MainActor isolation, regardless of thread

    try await Task.sleep(for: .seconds(1))

    // ✅ Still on MainActor after suspension
}

// Or use actor isolation
actor DataProcessor {
    func process() async {
        // ✅ Guaranteed actor isolation
        try await Task.sleep(for: .seconds(1))
        // ✅ Still isolated to this actor
    }
}
```

**Why it matters:** Tasks use a cooperative thread pool and may resume on any available thread after `await`. Thread identity is not preserved across suspension points. In Swift 6, `Thread.current` is unavailable in async contexts to prevent reliance on this unstable property. Use actor isolation (`@MainActor`, custom actors) to guarantee execution context. Isolation domains are stable across suspensions; threads are not.

Reference: [Swift Evolution - SE-0392](https://github.com/apple/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md)

---

## 6. Memory Management

### Cancel Stored Tasks to Prevent Retain Cycles

When storing tasks as properties, cancel them in `deinit` to break potential retain cycles and stop unnecessary work.

**Incorrect (task continues after deallocation attempt):**

```swift
final class DataManager {
    var task: Task<Void, Never>?

    func startWork() {
        task = Task {
            await self.work()  // ⚠️ Retain cycle if not using weak self
        }
    }

    // Missing: deinit { task?.cancel() }
}
```

**Correct (cancel task in deinit):**

```swift
final class DataManager {
    var task: Task<Void, Never>?

    func startWork() {
        task = Task { [weak self] in
            while let self = self {
                await self.work()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    deinit {
        task?.cancel()  // ✅ Stops task when object deallocates
    }
}

// Or with isolated deinit (Swift 6.2+)
@MainActor
final class DataManager {
    var task: Task<Void, Never>?

    isolated deinit {
        task?.cancel()  // ✅ Can access actor-isolated state
    }
}
```

**Why it matters:** Stored tasks without `deinit` cancellation continue running even when the owner is being deallocated. If the task uses `[weak self]`, cancellation stops unnecessary work. If the task uses strong `self`, cancellation is necessary to break the retain cycle. Canceling tasks is good resource hygiene. Use `isolated deinit` (Swift 6.2+) when the task is stored in actor-isolated state.

Reference: [Swift Concurrency Course - Memory Management](https://www.swiftconcurrencycourse.com)

---

### Guard Let Self in Async Sequence Loops

Async sequences may run indefinitely. Use `[weak self]` with `guard let self` to exit the loop when the object deallocates.

**Incorrect (strong capture in infinite sequence):**

```swift
@MainActor
final class AppLifecycleViewModel {
    private(set) var isActive = false
    private var task: Task<Void, Never>?

    func startObserving() {
        task = Task {
            for await _ in NotificationCenter.default.notifications(
                named: .didBecomeActive
            ) {
                isActive = true  // ❌ Strong capture, never ends
            }
        }
    }
}

var viewModel: AppLifecycleViewModel? = .init()
viewModel?.startObserving()
viewModel = nil  // ⚠️ Never deallocated - sequence continues forever
```

**Correct (weak self + guard exits loop):**

```swift
@MainActor
final class AppLifecycleViewModel {
    private(set) var isActive = false
    private var task: Task<Void, Never>?

    func startObserving() {
        task = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(
                named: .didBecomeActive
            ) {
                guard let self = self else { return }  // ✅ Exits when self deallocates
                self.isActive = true
            }
        }
    }
}

var viewModel: AppLifecycleViewModel? = .init()
viewModel?.startObserving()
viewModel = nil  // ✅ Deallocated, loop exits
```

**Why it matters:** Async sequences (notifications, websockets, streams) often run indefinitely. Without `[weak self]`, the task holds `self` alive forever. `guard let self` provides an early exit point when the object is released. The loop terminates cleanly when `self` becomes `nil`. Use this pattern for: notification observers, async stream monitoring, websocket handlers, and any infinite async sequence.

Reference: [Swift Concurrency Course - Memory Management](https://www.swiftconcurrencycourse.com)

---

### Use Weak Self for Long-Running and Infinite Tasks

When a task captures `self` strongly and runs for an extended period or indefinitely, create a retain cycle if `self` owns the task.

**Incorrect (retain cycle with long-running task):**

```swift
@MainActor
final class ImageLoader {
    var task: Task<Void, Never>?

    func startPolling() {
        task = Task {
            while true {
                self.pollImages()  // ❌ Strong capture, retain cycle
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

var loader: ImageLoader? = .init()
loader?.startPolling()
loader = nil  // ⚠️ Loader never deallocated!
```

**Correct (weak self breaks cycle):**

```swift
@MainActor
final class ImageLoader {
    var task: Task<Void, Never>?

    func startPolling() {
        task = Task { [weak self] in
            while let self = self {  // ✅ Exits when self deallocates
                self.pollImages()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}

var loader: ImageLoader? = .init()
loader?.startPolling()
loader = nil  // ✅ Loader deallocated, task stops
```

**Why it matters:** When `self` owns the task and the task strongly captures `self`, neither can be deallocated (retain cycle). Long-running tasks keep the cycle alive indefinitely. Use `[weak self]` for: polling loops, infinite async sequences, long-running monitoring, and any task stored as a property. Short-lived tasks can use strong captures if acceptable for the object to live until completion.

Reference: [Swift Concurrency Course - Memory Management](https://www.swiftconcurrencycourse.com)

---

## 7. Testing Concurrency

### Use await fulfillment Not wait in Async Tests

In async test methods, use `await fulfillment(of:)` instead of `wait(for:)` to avoid deadlocks with expectations.

**Incorrect (wait causes deadlock):**

```swift
@MainActor
func testSearchTask() async {
    let searcher = ArticleSearcher()
    let expectation = expectation(description: "Search complete")

    searcher.startSearchTask("swift")

    _ = withObservationTracking {
        searcher.results
    } onChange: {
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10)  // ❌ Deadlock!
    XCTAssertEqual(searcher.results.count, 1)
}
```

**Correct (await fulfillment):**

```swift
@MainActor
func testSearchTask() async {
    let searcher = ArticleSearcher()
    let expectation = expectation(description: "Search complete")

    _ = withObservationTracking {
        searcher.results
    } onChange: {
        expectation.fulfill()
    }

    searcher.startSearchTask("swift")

    await fulfillment(of: [expectation], timeout: 10)  // ✅ Non-blocking
    XCTAssertEqual(searcher.results.count, 1)
}
```

**Why it matters:** `wait(for:)` blocks the current thread, which causes deadlocks in async contexts where the expectation must be fulfilled on the same thread. `await fulfillment(of:)` suspends the async function without blocking, allowing the expectation to complete. Always use `await fulfillment` in async test methods. This applies to XCTest; Swift Testing uses `confirmation` instead.

Reference: [Swift Concurrency Course - Testing](https://www.swiftconcurrencycourse.com)

---

### Use Defer Trick for Testing Async Side Effects

When testing unstructured tasks that produce side effects, use defer trick with continuations to observe completion.

**Incorrect (no way to observe completion):**

```swift
@MainActor
final class Logger {
    private(set) var logs: [String] = []

    func log(_ message: String) {
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            logs.append(message)  // Side effect in unstructured task
        }
    }
}

@Test
@MainActor
func logsMessage() async {
    let logger = Logger()
    logger.log("test")
    #expect(logger.logs == ["test"])  // ❌ Fails - task not complete
}
```

**Correct (defer trick observes side effect):**

```swift
@MainActor
final class Logger {
    private(set) var logs: [String] = []
    var onLog: (() -> Void)?

    func log(_ message: String) {
        Task {
            defer { onLog?() }  // ✅ Signal completion

            try? await Task.sleep(for: .milliseconds(100))
            logs.append(message)
        }
    }
}

@Test
@MainActor
func logsMessage() async {
    let logger = Logger()

    await withCheckedContinuation { continuation in
        logger.onLog = {
            continuation.resume()
        }
        logger.log("test")
    }

    #expect(logger.logs == ["test"])  // ✅ Passes
}
```

**Why it matters:** Unstructured tasks (`Task { }`) don't provide a direct way to await their completion. The defer trick uses a callback to signal when the task finishes, allowing tests to observe side effects reliably. Use continuations or confirmations to await the callback. This pattern works for logging, analytics, cache updates, and other fire-and-forget operations that need testing.

Reference: [Swift Concurrency Course - Testing](https://www.swiftconcurrencycourse.com)

---

### Prefer Swift Testing Over XCTest for New Tests

Swift Testing provides better concurrency support, modern Swift syntax with macros, and cleaner test structure compared to XCTest.

**Incorrect (XCTest for new tests):**

```swift
final class ArticleSearcherTests: XCTestCase {
    @MainActor
    func testEmptyQuery() async {
        let searcher = ArticleSearcher()
        await searcher.search("")
        XCTAssertEqual(searcher.results, ArticleSearcher.allArticles)
    }
}
```

**Correct (Swift Testing):**

```swift
@Test
@MainActor
func emptyQuery() async {
    let searcher = ArticleSearcher()
    await searcher.search("")
    #expect(searcher.results == ArticleSearcher.allArticles)
}
```

**Benefits:**
- `@Test` macro instead of `XCTestCase` subclass
- `#expect` with cleaner syntax than `XCTAssert`
- Structs preferred over classes
- No `test` prefix required
- Better async/await integration
- More flexible test organization

**Why it matters:** Swift Testing is the modern, recommended testing framework for Swift. It's designed from the ground up with concurrency in mind. XCTest has legacy async support but wasn't built for Swift Concurrency. Use Swift Testing for new tests; maintain XCTest tests in legacy codebases until migration is practical.

Reference: [Swift Testing Documentation](https://developer.apple.com/documentation/testing)

---

### Use Serial Executor to Eliminate Flaky Concurrency Tests

Tests that check intermediate async state are flaky due to race conditions. Use `withMainSerialExecutor` from ConcurrencyExtras for deterministic task scheduling.

**Incorrect (flaky test):**

```swift
@Test
@MainActor
func isLoadingState() async throws {
    let fetcher = ImageFetcher()

    let task = Task { try await fetcher.fetch(url) }

    // ❌ Flaky - task may complete before we check
    #expect(fetcher.isLoading == true)

    try await task.value
    #expect(fetcher.isLoading == false)
}
```

**Correct (serial executor for determinism):**

```swift
import ConcurrencyExtras

@Test
@MainActor
func isLoadingState() async throws {
    try await withMainSerialExecutor {
        let fetcher = ImageFetcher { url in
            await Task.yield()  // Allow test to check state
            return Data()
        }

        let task = Task { try await fetcher.fetch(url) }

        await Task.yield()  // Switch to task

        #expect(fetcher.isLoading == true)  // ✅ Reliable

        try await task.value
        #expect(fetcher.isLoading == false)
    }
}
```

**Critical requirement:**

```swift
@Suite(.serialized)  // Tests must run serially
@MainActor
final class ImageFetcherTests {
    // Tests using withMainSerialExecutor
}
```

**Why it matters:** Default concurrency allows tasks to interleave unpredictably, causing flaky tests. Serial executor makes MainActor tasks execute sequentially and deterministically. `Task.yield()` becomes a predictable scheduling point. Add package: `https://github.com/pointfreeco/swift-concurrency-extras.git`. Mark suite with `.serialized` to prevent parallel execution conflicts.

Reference: [Swift Concurrency Extras](https://github.com/pointfreeco/swift-concurrency-extras)

---

## 8. Migration & Interop

### Wrap Closure APIs With Async Alternatives First

Before migrating closure-based implementations, add async wrappers using continuations. This lets callers migrate first while keeping old code working.

**Incorrect (removing closure API immediately):**

```swift
// ❌ Breaking change - forces all callers to migrate at once
func fetchImage(urlRequest: URLRequest) async throws -> UIImage {
    // New implementation
}
// Old closure-based API removed - breaks existing callers
```

**Correct (async wrapper alongside closure API):**

```swift
// Keep existing API, mark deprecated
@available(*, deprecated, renamed: "fetchImage(urlRequest:)",
           message: "Consider using the async/await alternative.")
func fetchImage(urlRequest: URLRequest,
                completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) {
    // ... existing implementation
}

// Add async wrapper
func fetchImage(urlRequest: URLRequest) async throws -> UIImage {
    return try await withCheckedThrowingContinuation { continuation in
        fetchImage(urlRequest: urlRequest) { result in
            continuation.resume(with: result)
        }
    }
}
```

**Xcode shortcut:** Refactor → Add Async Wrapper

**Why it matters:** Adding async wrappers first allows gradual migration of callers, maintains backward compatibility, enables testing with async/await before rewriting internals, and lets colleagues start using modern APIs immediately. Callers can migrate on their own schedule. Once all callers are migrated, you can rewrite or remove the closure-based implementation.

Reference: [Swift Concurrency Course - Migration](https://www.swiftconcurrencycourse.com)

---

### Replace Combine Pipelines With AsyncAlgorithms

Combine doesn't integrate well with Swift Concurrency. Replace Combine publishers with AsyncSequence and swift-async-algorithms for better integration.

**Incorrect (mixing Combine and async/await):**

```swift
import Combine

class DataManager {
    var cancellables = Set<AnyCancellable>()

    func observeUpdates() async {
        NotificationCenter.default
            .publisher(for: .dataUpdated)
            .sink { [weak self] _ in
                // ❌ Awkward bridging between Combine and async
                Task { await self?.handleUpdate() }
            }
            .store(in: &cancellables)
    }
}
```

**Correct (AsyncSequence with async algorithms):**

```swift
import AsyncAlgorithms

class DataManager {
    func observeUpdates() async {
        for await notification in NotificationCenter.default.notifications(
            named: .dataUpdated
        ) {
            await handleUpdate()  // ✅ Natural async/await flow
        }
    }
}

// With debounce, throttle, etc.
func observeSearchQuery() async {
    for await query in searchQueryStream.debounce(for: .milliseconds(300)) {
        await performSearch(query)
    }
}
```

**Add package:**
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
]
```

**Why it matters:** Combine and async/await don't compose well - bridging requires awkward `Task { }` wrappers. `AsyncSequence` is the native concurrency primitive for streams. Swift Async Algorithms provides familiar operators (debounce, throttle, merge, combineLatest) for `AsyncSequence`. The integration is seamless, type-safe, and easier to reason about than mixing paradigms.

Reference: [Swift Async Algorithms](https://github.com/apple/swift-async-algorithms)

---

### Never Pass NSManagedObject Across Isolation Boundaries

`NSManagedObject` cannot conform to `Sendable` due to mutable properties and thread-affinity requirements. Pass `NSManagedObjectID` instead, which is thread-safe.

**Incorrect (passing managed object):**

```swift
@MainActor
func displayArticle(_ article: Article) {  // ❌ Article is NSManagedObject
    titleLabel.text = article.title
}

func processInBackground(article: Article) async throws {  // ❌ Not Sendable
    try await backgroundContext.perform {
        article.title = "Updated"  // ❌ Wrong context!
        try backgroundContext.save()
    }
}
```

**Correct (pass NSManagedObjectID):**

```swift
@MainActor
func displayArticle(id: NSManagedObjectID) {
    guard let article = viewContext.object(with: id) as? Article else {
        return
    }
    titleLabel.text = article.title
}

func processInBackground(articleID: NSManagedObjectID) async throws {
    let backgroundContext = container.newBackgroundContext()
    try await backgroundContext.perform {
        guard let article = backgroundContext.object(with: articleID) as? Article else {
            return
        }
        article.title = "Updated"
        try backgroundContext.save()
    }
}
```

**Why it matters:** Core Data's thread-safety rules don't change with Swift Concurrency. Accessing managed objects from the wrong thread causes crashes, data corruption, and undefined behavior. `NSManagedObjectID` is explicitly Sendable and can be safely passed between contexts. Enable Core Data debugging (`-com.apple.CoreData.ConcurrencyDebug 1`) to catch violations.

Reference: [Swift Concurrency Course - Core Data](https://www.swiftconcurrencycourse.com)

---

### Migrate Strict Concurrency Incrementally

Enable strict concurrency checking in stages (Minimal → Targeted → Complete) rather than jumping to Complete, which can overwhelm with hundreds of errors.

**Incorrect (enabling Complete immediately):**

```swift
// Build Settings → Strict Concurrency Checking = Complete
// Result: 500+ errors, overwhelming to fix
```

**Correct (incremental approach):**

```swift
// Stage 1: Minimal (only code with explicit concurrency annotations)
// Build Settings → Strict Concurrency Checking = Minimal
// Fix errors → commit

// Stage 2: Targeted (all Sendable conformances)
// Build Settings → Strict Concurrency Checking = Targeted
// Fix new errors → commit

// Stage 3: Complete (entire codebase, Swift 6 equivalent)
// Build Settings → Strict Concurrency Checking = Complete
// Fix remaining errors → commit
```

**Levels explained:**
- **Minimal**: Only checks code with `@Sendable`, `@MainActor`, `async`, etc.
- **Targeted**: Adds Sendable conformance verification
- **Complete**: Checks entire codebase (matches Swift 6 mode)

**Why it matters:** Jumping to Complete exposes all concurrency issues at once, creating hundreds of cascading errors. Incremental migration lets you fix errors in manageable batches, commit progress, and avoid the concurrency rabbit hole. Each stage builds on the previous, reducing surprise errors. Allow 30 minutes per day for gradual migration rather than attempting completion in one session.

Reference: [Migrating to Swift 6](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)

---

### Do Not Combine Migration With Architecture Refactors

Swift Concurrency migration should focus solely on concurrency changes. Don't combine with architecture refactors, API modernization, or code style improvements.

**Incorrect (mixing concerns):**

```swift
// PR: "Migrate UserManager to Swift 6 + refactor to MVVM"
// Changes:
// - Add @MainActor
// - Extract ViewModel
// - Rename methods
// - Add Sendable
// - Refactor dependencies
// - Update coding style
// ❌ Impossible to review, high risk
```

**Correct (focused migration):**

```swift
// PR 1: "Add Sendable to UserManager"
// Changes:
// - Make UserManager: Sendable
// - Add @MainActor where needed
// - Fix isolation issues
// ✅ Reviewable, low risk

// PR 2 (later): "Refactor UserManager to MVVM"
// Changes:
// - Extract ViewModel
// - Update architecture
// ✅ Separate concern, clear purpose
```

**Why it matters:** Combining migration with refactoring creates large, hard-to-review PRs, makes it difficult to isolate bugs, and increases risk of breaking changes. It's harder to revert if issues arise. Focus on minimal changes: one class/module at a time, small PRs that merge quickly, concurrency changes only. Create separate tickets for non-concurrency improvements and address them after migration stabilizes.

Reference: [Swift Concurrency Course - Migration Habits](https://www.swiftconcurrencycourse.com)

---

### Use @preconcurrency Only With Documentation

`@preconcurrency` suppresses Sendable warnings for imported modules. Use only when the module will be updated later, and document why and when it will be removed.

**Incorrect (@preconcurrency without context):**

```swift
@preconcurrency import ThirdPartySDK  // ❌ No explanation

class MyManager {
    let sdk = ThirdPartySDK()
}
```

**Correct (@preconcurrency with documentation):**

```swift
// TODO: Remove @preconcurrency when ThirdPartySDK adds Sendable conformance
// Issue: SDK v2.5 doesn't conform to Sendable
// Tracked: https://github.com/vendor/sdk/issues/123
@preconcurrency import ThirdPartySDK

class MyManager {
    let sdk = ThirdPartySDK()
}
```

**Or with ticket:**

```swift
// JIRA-1234: Migrate to ThirdPartySDK 3.0 with Sendable support
@preconcurrency import ThirdPartySDK
```

**Why it matters:** `@preconcurrency` hides concurrency warnings, which can mask real safety issues. Without documentation, it's unclear why it's there, when it can be removed, or who's responsible for cleanup. Document: the reason for using `@preconcurrency`, the ticket/issue tracking removal, and the expected timeline. Remove `@preconcurrency` as soon as the dependency adds Sendable support.

Reference: [SE-0337: @preconcurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0337-support-incremental-migration-to-concurrency-checking.md)

---

## References

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [Swift Concurrency Course](https://www.swiftconcurrencycourse.com)
- [Swift Evolution Proposals](https://github.com/apple/swift-evolution)
- [Swift Async Algorithms](https://github.com/apple/swift-async-algorithms)
- [Swift Concurrency Extras](https://github.com/pointfreeco/swift-concurrency-extras)
- [Migrating to Swift 6](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/)
