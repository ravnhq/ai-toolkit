# Async Algorithms

Swift Async Algorithms package for working with streams of values over time.

## Overview

The [swift-async-algorithms](https://github.com/apple/swift-async-algorithms) package provides algorithms on top of `AsyncSequence`, similar to how Swift Algorithms extends `Sequence`. It's the modern replacement for many Combine operators.

```swift
import AsyncAlgorithms
```

## Key Algorithms

### Combining Sequences

**combineLatest** - Emit combined values when either sequence emits

```swift
let messages = AsyncStream { ... }
let notifications = AsyncStream { ... }

for await (message, notification) in combineLatest(messages, notifications) {
    updateBadge(messageCount: message.count, notificationCount: notification.count)
}
```

**merge** - Emit values from multiple sequences as they arrive

```swift
let localEvents = AsyncStream<Event> { ... }
let remoteEvents = AsyncStream<Event> { ... }

for await event in merge(localEvents, remoteEvents) {
    process(event)
}
```

**zip** - Pair values from two sequences (waits for both)

```swift
let users = fetchUsers()
let avatars = fetchAvatars()

for await (user, avatar) in zip(users, avatars) {
    display(user: user, avatar: avatar)
}
```

**chain** - Concatenate sequences (completes first before second)

```swift
let cached = loadFromCache()
let fresh = fetchFromNetwork()

for await item in chain(cached, fresh) {
    process(item)
}
```

### Time-Based Operations

**debounce** - Emit value after a quiet period

```swift
let searchQueries: AsyncStream<String> = ...

for await query in searchQueries.debounce(for: .milliseconds(300)) {
    await performSearch(query)
}
```

**throttle** - Limit emission rate

```swift
let locationUpdates: AsyncStream<CLLocation> = ...

for await location in locationUpdates.throttle(for: .seconds(1)) {
    await updateMap(location)
}
```

### Transformation

**compacted** - Filter out nil values

```swift
let optionalValues: AsyncStream<Int?> = ...

for await value in optionalValues.compacted() {
    // value is non-optional Int
    process(value)
}
```

**removeDuplicates** - Filter consecutive duplicates

```swift
let states: AsyncStream<AppState> = ...

for await state in states.removeDuplicates() {
    render(state)
}
```

**adjacentPairs** - Emit pairs of consecutive values

```swift
let values: AsyncStream<Int> = ...

for await (previous, current) in values.adjacentPairs() {
    let delta = current - previous
    updateDelta(delta)
}
```

### Chunking

**chunked(by:)** - Group by condition

```swift
let transactions: AsyncStream<Transaction> = ...

for await chunk in transactions.chunked(by: { $0.date == $1.date }) {
    processDailyTransactions(chunk)
}
```

**chunked(into:)** - Fixed-size groups

```swift
let items: AsyncStream<Item> = ...

for await batch in items.chunked(into: 10) {
    await uploadBatch(batch)
}
```

### Utility

**interspersed(with:)** - Insert element between values

```swift
let lines: AsyncStream<String> = ...

for await line in lines.interspersed(with: "---") {
    print(line)
}
```

## When to Use Async Algorithms vs AsyncSequence

| Use Case | Tool |
|----------|------|
| Simple iteration over async data | `AsyncSequence` / `for await` |
| Combining multiple streams | `combineLatest`, `merge`, `zip` |
| Debouncing user input | `debounce` |
| Rate limiting | `throttle` |
| Processing in batches | `chunked` |
| Filtering duplicates | `removeDuplicates` |

## Migration from Combine

Many Async Algorithms operations map directly to Combine operators:

| Combine | Async Algorithms |
|---------|------------------|
| `combineLatest` | `combineLatest` |
| `merge` | `merge` |
| `zip` | `zip` |
| `debounce` | `debounce` |
| `throttle` | `throttle` |
| `removeDuplicates` | `removeDuplicates` |
| `compactMap` | `compacted` (for nil filtering) |

### Example: Migrating a Combine Publisher

**Before (Combine):**
```swift
cancellable = $searchText
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .removeDuplicates()
    .sink { [weak self] query in
        self?.performSearch(query)
    }
```

**After (Async Algorithms):**
```swift
Task {
    for await query in searchTextStream
        .debounce(for: .milliseconds(300))
        .removeDuplicates() {
        await performSearch(query)
    }
}
```

## Real-World Patterns

### Debounced Search

```swift
@MainActor
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Result] = []

    private var searchTask: Task<Void, Never>?

    func startSearch() {
        searchTask = Task {
            let queryStream = $query.values // AsyncPublisher from Combine

            for await query in queryStream.debounce(for: .milliseconds(300)) {
                guard !query.isEmpty else {
                    results = []
                    continue
                }

                do {
                    results = try await searchService.search(query)
                } catch {
                    // Handle error
                }
            }
        }
    }
}
```

### Combining Multiple Data Sources

```swift
func observeNotificationBadge() async {
    let messages = messageService.unreadCount()
    let alerts = alertService.pendingCount()

    for await (messageCount, alertCount) in combineLatest(messages, alerts) {
        let total = messageCount + alertCount
        await MainActor.run {
            updateBadge(count: total)
        }
    }
}
```

### Deep Link Handling

```swift
func handleDeepLinks() async {
    let urlSchemeLinks = NotificationCenter.default
        .notifications(named: .deepLinkReceived)
        .map { $0.userInfo?["url"] as? URL }
        .compacted()

    let universalLinks = NotificationCenter.default
        .notifications(named: .universalLinkReceived)
        .map { $0.userInfo?["url"] as? URL }
        .compacted()

    for await url in merge(urlSchemeLinks, universalLinks) {
        await router.handle(deepLink: url)
    }
}
```

## Best Practices

1. **Use debounce for user input** - Prevents excessive API calls during typing
2. **Use throttle for high-frequency events** - Location updates, scroll events
3. **Use merge for multiple event sources** - Combining local and remote streams
4. **Use combineLatest for dependent state** - When UI depends on multiple values
5. **Use chunked for batch processing** - Network uploads, database writes

## Installation

**Swift Package Manager:**
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
]
```

## Further Reading

- [swift-async-algorithms GitHub](https://github.com/apple/swift-async-algorithms)
- [WWDC 2022: Meet Swift Async Algorithms](https://developer.apple.com/videos/play/wwdc2022/110355/)
