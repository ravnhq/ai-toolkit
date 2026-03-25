---
title: Coroutines & Flows — Scopes, Dispatchers, Flow Patterns, Lifecycle Collection
impact: CRITICAL
tags: coroutines, flow, lifecycle, dispatchers, structured-concurrency
---

## Coroutines & Flows — Scopes, Dispatchers, Flow Patterns, Lifecycle Collection

Always use structured concurrency with lifecycle-aware scopes, pick the right dispatcher, and collect Flows with lifecycle awareness.

### Structured Scopes — Never Use GlobalScope

Launch coroutines in `viewModelScope` or `lifecycleScope`. Never use `GlobalScope` or raw `CoroutineScope` — they leak coroutines past the lifecycle of the screen.

**Incorrect:**

```kotlin
// Bad - GlobalScope outlives the screen, can't be cancelled
class SearchViewModel : ViewModel() {
    fun search(query: String) {
        GlobalScope.launch {
            val results = repository.search(query)
            _results.value = results  // May update destroyed ViewModel
        }
    }
}

// Bad - manual CoroutineScope without cancellation
class ProfileViewModel : ViewModel() {
    private val scope = CoroutineScope(Dispatchers.Main) // Never cancelled!

    fun loadProfile() {
        scope.launch { /* runs after ViewModel is cleared */ }
    }
}
```

**Correct:**

```kotlin
// Good - viewModelScope cancels when ViewModel is cleared
class SearchViewModel : ViewModel() {
    fun search(query: String) {
        viewModelScope.launch {
            val results = repository.search(query)
            _results.value = results
        }
    }
}

// Good - rememberCoroutineScope for user-triggered actions in Compose
@Composable
fun UploadButton(onUpload: suspend () -> Unit) {
    val scope = rememberCoroutineScope()
    Button(onClick = { scope.launch { onUpload() } }) {
        Text("Upload")
    }
}

// Good - structured child coroutines for parallel work
viewModelScope.launch {
    val orders = async { orderRepo.sync() }
    val inventory = async { inventoryRepo.sync() }
    orders.await()
    inventory.await()
}

// Good - application-scoped work uses an injected custom scope
class AnalyticsLogger(
    private val analyticsService: AnalyticsService,
    private val scope: CoroutineScope  // Injected, testable, cancellable
) {
    fun logEvent(event: AnalyticsEvent) {
        scope.launch { analyticsService.send(event) }
    }
}
```

### Dispatchers

Use the right dispatcher for each operation. Never block `Dispatchers.Main`.

**Incorrect:**

```kotlin
// Bad - blocking file read on Main
viewModelScope.launch {
    val content = File("log.txt").readText()  // Blocks UI → ANR!
}

// Bad - CPU-bound sort on IO (wastes the larger IO thread pool)
val sorted = withContext(Dispatchers.IO) {
    items.sortedByDescending { it.score }
}
```

**Correct:**

```kotlin
// Good - IO for blocking I/O
val content = withContext(Dispatchers.IO) { File("log.txt").readText() }

// Good - Default for CPU-bound work
val sorted = withContext(Dispatchers.Default) { items.sortedByDescending { it.score } }

// Good - repository enforces its own dispatcher (main-safe)
interface ApiRepository {
    suspend fun parseResponse(json: String): List<Item>
}

class ApiRepositoryImpl(
    private val defaultDispatcher: CoroutineDispatcher = Dispatchers.Default
) : ApiRepository {
    override suspend fun parseResponse(json: String): List<Item> {
        return withContext(defaultDispatcher) { Json.decodeFromString(json) }
    }
}
```

**Dispatcher reference:**

| Dispatcher | Use for | Examples |
|-----------|---------|----------|
| `Main` | UI updates, state emission | Updating `StateFlow`, navigation |
| `IO` | Blocking I/O (disk, network, DB) | File reads, Retrofit, Room queries |
| `Default` | CPU-heavy computation | Sorting, JSON parsing, image processing |

> If the operation waits for something external → `IO`. If it crunches data in memory → `Default`. If it touches the UI → `Main`.

### Flows — Creation, Operators, StateFlow vs SharedFlow

Repositories and data sources expose `Flow<T>` for reactive streams. ViewModels convert them to `StateFlow<UiState>` for the UI.

**Incorrect:**

```kotlin
// Bad - LiveData in new code (prefer Flow for the entire stack)
class OrderRepository {
    fun getOrders(): LiveData<List<Order>> { /* ... */ }
}

// Bad - creating a new Flow on every call instead of exposing a shared stream
class OrderRepository {
    suspend fun getOrders(): Flow<List<Order>> {
        return flow { emit(api.getOrders()) }  // Cold, re-fetches every collect
    }
}

// Bad - MutableStateFlow exposed directly to the UI
class OrderViewModel : ViewModel() {
    val orders = MutableStateFlow<List<Order>>(emptyList())  // UI can mutate!
}
```

**Correct:**

```kotlin
// Good - Repository exposes Flow, backed by Room or a persistent source
class OrderRepositoryImpl(
    private val orderDao: OrderDao,
    private val api: OrderApi
) : OrderRepository {
    // Room returns a reactive Flow that emits on every DB change
    override fun getOrders(): Flow<List<Order>> = orderDao.observeAll()

    override suspend fun refresh() {
        val remote = api.getOrders()
        orderDao.upsertAll(remote.map { it.toEntity() })
    }
}

// Good - ViewModel converts Flow to StateFlow with stateIn
class OrderViewModel(
    private val orderRepository: OrderRepository
) : ViewModel() {

    val orders: StateFlow<List<Order>> = orderRepository.getOrders()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),  // 5s grace for rotation
            initialValue = emptyList()
        )

    init { viewModelScope.launch { orderRepository.refresh() } }
}
```

**Combining multiple Flows in a ViewModel:**

```kotlin
// Good - combine multiple data sources into a single UiState
class DashboardViewModel(
    private val userRepository: UserRepository,
    private val orderRepository: OrderRepository
) : ViewModel() {

    val uiState: StateFlow<DashboardUiState> = combine(
        userRepository.getUser(),
        orderRepository.getOrders()
    ) { user, orders ->
        DashboardUiState(userName = user.name, orderCount = orders.size)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = DashboardUiState()
    )
}
```

**Common Flow operators:**

| Operator | Use case |
|----------|----------|
| `map` | Transform each emission (`flow.map { it.toDomain() }`) |
| `filter` | Skip emissions that don't match (`flow.filter { it.isActive }`) |
| `combine` | Merge multiple Flows into one (all latest values) |
| `flatMapLatest` | Switch to a new Flow when upstream emits (search-as-you-type) |
| `distinctUntilChanged` | Skip consecutive duplicate emissions |
| `catch` | Handle upstream errors without crashing the collection |
| `onEach` | Side effects per emission (logging) without consuming |
| `debounce` | Wait for a pause in emissions (search input) |

**StateFlow vs SharedFlow:**

| | `StateFlow` | `SharedFlow` |
|---|-------------|--------------|
| **Has current value** | Yes (`.value`) | No |
| **Replays on new collector** | Last value (always 1) | Configurable (`replay`) |
| **Conflates** | Yes (skips intermediate) | Configurable |
| **Use for** | UI state, always-readable data | One-shot events (navigation, snackbars) |

```kotlin
// StateFlow for UI state — always has a current value
private val _uiState = MutableStateFlow(ProfileUiState())
val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

// SharedFlow for one-shot events — no replay, no conflation
private val _events = MutableSharedFlow<UiEvent>()  // replay = 0 by default
val events: SharedFlow<UiEvent> = _events.asSharedFlow()
```

### Lifecycle-Aware Flow Collection

Use `collectAsStateWithLifecycle` in Compose. Never use `collectAsState` — it keeps collecting when the app is backgrounded.

**Incorrect:**

```kotlin
// Bad - collectAsState keeps GPS/sensor flows running in background
@Composable
fun LocationScreen(viewModel: LocationViewModel) {
    val location by viewModel.locationFlow.collectAsState()
}
```

**Correct:**

```kotlin
// Good - stops collecting when lifecycle < STARTED
@Composable
fun LocationScreen(viewModel: LocationViewModel) {
    val location by viewModel.locationFlow.collectAsStateWithLifecycle()
    Text("Lat: ${location.lat}, Lng: ${location.lng}")
}

// Good - repeatOnLifecycle in View system (non-Compose)
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        viewModel.locationFlow.collect { location -> updateUI(location) }
    }
}
```

**Why it matters:**
- `GlobalScope` and raw scopes leak coroutines past navigation and rotation
- Blocking Main causes ANR dialogs after 5 seconds
- Wrong dispatcher wastes threads — IO has 64+ threads, Default is sized to CPU cores
- Background Flow collection wastes battery on GPS, network, and sensor work
- `withContext` is cheap — it doesn't create a new coroutine, just switches threads

Reference: [Coroutines on Android](https://developer.android.com/kotlin/coroutines) | [collectAsStateWithLifecycle](https://developer.android.com/reference/kotlin/androidx/lifecycle/compose/package-summary#collectAsStateWithLifecycle)
