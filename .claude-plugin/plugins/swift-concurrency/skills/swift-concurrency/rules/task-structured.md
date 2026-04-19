---
title: Understand Task Lifecycle and Cancellation
impact: HIGH
tags: tasks, cancellation, structured-concurrency, lifecycle
---

## Understand Task Lifecycle and Cancellation

Tasks don't stop automatically when canceled. You must manually check cancellation at appropriate points, and prefer structured concurrency for automatic resource cleanup.

**Incorrect (ignores cancellation):**

```swift
let task = Task {
    let data = try await URLSession.shared.data(from: url)
    // No cancellation check - continues even if canceled
    let processed = await expensiveProcessing(data)  // Wastes resources
    let stored = await storeInDatabase(processed)     // Wasteful work
    return stored
}

task.cancel()  // Task continues running! Wastes CPU, network, battery
```

**Correct (checks cancellation at breakpoints):**

```swift
let task = Task {
    try Task.checkCancellation()  // Before expensive work

    let data = try await URLSession.shared.data(from: url)

    try Task.checkCancellation()  // After network, before processing

    let processed = await expensiveProcessing(data)

    try Task.checkCancellation()  // Before database

    return await storeInDatabase(processed)
}

task.cancel()  // Stops at next checkpoint
```

**Check cancellation in loops:**

```swift
// Incorrect - loop continues after cancellation
for item in largeArray {
    await process(item)  // Continues even if canceled
}

// Correct - check at each iteration
for item in largeArray {
    try Task.checkCancellation()  // Throws CancellationError
    await process(item)
}

// Or use guard for custom handling
for item in largeArray {
    guard !Task.isCancelled else {
        cleanup()
        break
    }
    await process(item)
}
```

**Prefer structured concurrency over unstructured tasks:**

```swift
// Incorrect - unstructured tasks require manual management
func loadProfile() async throws -> Profile {
    let userTask = Task { try await fetchUser() }
    let settingsTask = Task { try await fetchSettings() }

    // ❌ Must manually manage cancellation and errors
    let user = try await userTask.value
    let settings = try await settingsTask.value

    return Profile(user: user, settings: settings)
}
// If function throws early, tasks keep running (resource leak)

// Correct - structured concurrency with async let
func loadProfile() async throws -> Profile {
    async let user = fetchUser()
    async let settings = fetchSettings()

    // ✅ Automatic cancellation if function exits early
    return try await Profile(user: user, settings: settings)
}
// If this throws, both operations are automatically canceled

// Or use task group for dynamic parallelism
func loadAll(ids: [String]) async throws -> [User] {
    try await withThrowingTaskGroup(of: User.self) { group in
        for id in ids {
            group.addTask { try await fetchUser(id: id) }
        }

        var users: [User] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }
    // ✅ All child tasks canceled automatically if parent throws or exits
}
```

**Never nest Task blocks inside structured concurrency:**

```swift
// Incorrect - nested Task loses cancellation
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

// Correct - direct work in task group
await withTaskGroup(of: Void.self) { group in
    for item in items {
        group.addTask {
            await process(item)  // ✅ Cancels with group
        }
    }

    group.cancelAll()  // All tasks stop
}
```

**Avoid Task.detached unless truly independent:**

```swift
// Incorrect - detached task loses parent's cancellation
func processData() async {
    Task.detached {
        // ❌ Continues running even if parent is canceled
        await expensiveWork()
    }
}

// Correct - inherit cancellation with regular Task
func processData() async {
    Task {
        // ✅ Inherits parent's cancellation state
        await expensiveWork()
    }
}

// Valid use case - truly independent background work
Task.detached(priority: .background) {
    await DirectoryCleaner.cleanup()  // Should run regardless of caller
}
```

**Cancellation patterns:**

```swift
// Pattern 1: Throw CancellationError
try Task.checkCancellation()

// Pattern 2: Guard with custom handling
guard !Task.isCancelled else {
    cleanup()
    throw CancellationError()
}

// Pattern 3: URLSession respects cancellation automatically
let (data, _) = try await URLSession.shared.data(from: url)
// ✅ Network request canceled if task is canceled
```

**Why it matters:**

- **Resource efficiency**: Unchecked cancellation wastes CPU, memory, network bandwidth, and battery
- **Responsiveness**: Long-running tasks may continue indefinitely after cancellation
- **Automatic cleanup**: Structured concurrency (`async let`, task groups) automatically cancels children when parent exits
- **Leak prevention**: Unstructured tasks can leak resources if not manually canceled
- **Proper hierarchies**: Structured concurrency maintains task trees with automatic cancellation propagation

**Where to check cancellation:**

- Before expensive operations (network, database, heavy computation)
- After `await` points (where task might have been canceled)
- Inside loops (at each iteration)
- Before multi-step operations (to avoid partial work)

Reference: [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/), [SE-0304: Structured Concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)
