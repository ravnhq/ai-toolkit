---
title: Testing Patterns for Async Concurrent Code
impact: MEDIUM
tags: testing, async, concurrency, swift-testing
---

## Testing Patterns for Async Concurrent Code

Testing concurrent code requires specific patterns to handle async expectations, side effects, and deterministic execution. Use the right tools and patterns to avoid flaky tests.

**Use await fulfillment in XCTest async contexts:**

```swift
// Incorrect - wait(for:) blocks and causes deadlocks
@Test
@MainActor
func fetchesData() async throws {
    let expectation = XCTestExpectation(description: "Data fetched")
    let fetcher = DataFetcher()

    Task {
        try await fetcher.fetch()
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)  // ❌ Deadlocks in async context
}

// Correct - await fulfillment suspends without blocking
@Test
@MainActor
func fetchesData() async throws {
    let expectation = XCTestExpectation(description: "Data fetched")
    let fetcher = DataFetcher()

    Task {
        try await fetcher.fetch()
        expectation.fulfill()
    }

    await fulfillment(of: [expectation], timeout: 1.0)  // ✅ Suspends
}
```

**Prefer Swift Testing over XCTest for new tests:**

```swift
// Incorrect - XCTest for new concurrent tests
final class ArticleSearcherTests: XCTestCase {
    @MainActor
    func testEmptyQuery() async {
        let searcher = ArticleSearcher()
        await searcher.search("")
        XCTAssertEqual(searcher.results, ArticleSearcher.allArticles)
    }
}

// Correct - Swift Testing with modern syntax
@Test
@MainActor
func emptyQuery() async {
    let searcher = ArticleSearcher()
    await searcher.search("")
    #expect(searcher.results == ArticleSearcher.allArticles)
}

// Swift Testing benefits:
// - @Test macro instead of XCTestCase subclass
// - #expect with cleaner syntax than XCTAssert
// - No test prefix required
// - Better async/await integration
// - Structs instead of classes
```

**Test unstructured tasks with defer trick:**

```swift
// Incorrect - no way to observe task completion
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

// Correct - defer trick with continuation
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

**Avoid flaky tests with serial executors:**

```swift
// Incorrect - flaky due to race condition
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

// Correct - use serial executor for determinism
import ConcurrencyExtras

@Test
@MainActor
func isLoadingState() async throws {
    try await withMainSerialExecutor {
        let fetcher = ImageFetcher { url in
            await Task.yield()  // Allow test to check state
            return imageData
        }

        let task = Task { try await fetcher.fetch(url) }

        // ✅ Deterministic - yield ensures task hasn't completed
        #expect(fetcher.isLoading == true)

        let _ = try await task.value
        #expect(fetcher.isLoading == false)
    }
}
```

**Test cancellation explicitly:**

```swift
@Test
@MainActor
func respectsCancellation() async throws {
    let processor = DataProcessor()

    let task = Task {
        try await processor.processLargeDataset()
    }

    // Give it a moment to start
    try await Task.sleep(for: .milliseconds(10))

    task.cancel()

    // Verify it stopped quickly (didn't process everything)
    do {
        try await task.value
        Issue.record("Expected CancellationError")
    } catch is CancellationError {
        // ✅ Expected
    }

    // Verify it stopped early
    #expect(processor.processedCount < processor.totalCount)
}
```

**Test actor isolation:**

```swift
@Test
func actorIsolationWorks() async {
    actor Counter {
        var count = 0
        func increment() { count += 1 }
        func get() -> Int { count }
    }

    let counter = Counter()

    // Spawn 1000 concurrent tasks
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<1000 {
            group.addTask {
                await counter.increment()
            }
        }
    }

    // ✅ Actor serialization prevents data races
    let final = await counter.get()
    #expect(final == 1000)  // Always passes (never flaky)
}
```

**Mock async dependencies:**

```swift
// Protocol for dependency injection
protocol DataFetcher {
    func fetch(_ id: String) async throws -> Data
}

// Mock that doesn't hit network
struct MockDataFetcher: DataFetcher {
    var result: Result<Data, Error>

    func fetch(_ id: String) async throws -> Data {
        // No actual async work, just return mock data
        try result.get()
    }
}

@Test
func handlesNetworkError() async {
    let mockFetcher = MockDataFetcher(
        result: .failure(URLError(.notConnectedToInternet))
    )
    let viewModel = ViewModel(fetcher: mockFetcher)

    await viewModel.load()

    #expect(viewModel.error != nil)
    #expect(viewModel.data == nil)
}
```

**Testing patterns checklist:**

- Use `await fulfillment` not `wait(for:)` in async XCTest methods
- Prefer Swift Testing (@Test, #expect) for new concurrent tests
- Use defer trick with continuations for unstructured task side effects
- Use serial executors (ConcurrencyExtras) to eliminate flaky tests
- Test cancellation explicitly by starting, canceling, and verifying early exit
- Mock async dependencies with synchronous implementations
- Test actor isolation with concurrent access patterns

**Why it matters:**

- **Flaky tests**: Race conditions make tests unreliable without proper patterns
- **Deadlocks**: Blocking in async contexts causes tests to hang
- **Coverage**: Concurrent code has unique failure modes that need specific tests
- **Modern tools**: Swift Testing is designed for async/await, XCTest is legacy
- **Debugging**: Proper test patterns make failures reproducible and debuggable

Reference: [Swift Testing Documentation](https://developer.apple.com/documentation/testing), [ConcurrencyExtras](https://github.com/pointfreeco/swift-concurrency-extras), [Swift Concurrency Course](https://www.swiftconcurrencycourse.com)
