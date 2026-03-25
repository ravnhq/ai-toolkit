---
title: Never Add Dummy Suspension Points
impact: CRITICAL
tags: async, await, suspension, anti-pattern
---

## Never Add Dummy Suspension Points

When a linter warns that an `async` function has no `await`, adding dummy `Task.yield()` or `Task.sleep()` just to silence the warning is dangerous and misleading.

**Incorrect (dummy suspension to silence warning):**

```swift
func processData(_ data: Data) async -> Result {
    await Task.yield()  // ❌ Dummy suspension, no actual async work

    let processed = transform(data)  // Synchronous work
    return Result(processed)
}

// Or another dummy pattern
func calculateTotal(_ items: [Item]) async -> Double {
    await Task.sleep(nanoseconds: 0)  // ❌ Dummy sleep
    return items.reduce(0) { $0 + $1.price }
}
```

**Correct (remove async if no suspension needed):**

```swift
func processData(_ data: Data) -> Result {
    let processed = transform(data)
    return Result(processed)
}

// Caller no longer needs await
let result = processData(data)  // Synchronous call
```

**Or (if async is needed for protocol conformance):**

```swift
protocol DataProcessor {
    func processData(_ data: Data) async -> Result
}

// Keep async for protocol conformance, document why
func processData(_ data: Data) async -> Result {
    // Synchronous implementation of async protocol requirement
    // No actual suspension points, but must conform to protocol
    let processed = transform(data)
    return Result(processed)
}
```

**When async is truly needed:**

Only mark functions `async` if they:
1. Perform actual asynchronous work (`URLSession`, database calls, file I/O)
2. Call other `async` functions
3. Must conform to an `async` protocol requirement

**Why it matters:**

- **Misleads callers**: Dummy suspension points make callers think the function does async work, when it's actually synchronous
- **Performance overhead**: Unnecessary task switching adds latency for no benefit
- **Hides design issues**: If the function is synchronous, it should be marked as such
- **Violates principles**: `async` should indicate genuine asynchronous operations, not compiler appeasement
- **Makes code harder to understand**: Future maintainers will assume there's async work happening

**Swift 6 strict concurrency catches this:**

```swift
// Swift 6 will warn about this anti-pattern
func noRealAsyncWork(_ x: Int) async -> Int {  // ⚠️ Function is 'async' but does not contain any suspension points
    return x * 2
}
```

Reference: [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
