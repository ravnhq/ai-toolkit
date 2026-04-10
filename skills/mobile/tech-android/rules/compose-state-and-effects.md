---
title: Compose State & Side Effects — Hoisting, Remember, DerivedState, Effect Handlers
impact: HIGH
tags: compose, state, side-effects, remember, lifecycle
---

## Compose State & Side Effects — Hoisting, Remember, DerivedState, Effect Handlers

State flows down, events flow up. Side effects run in controlled handlers, never in the composition body.

### State Hoisting

Composables receive state as parameters and notify the caller via callbacks. Only keep state internal for purely visual concerns (animation, scroll position, tooltip visibility).

**Incorrect:**

```kotlin
// Bad - composable owns state, parent can't access or control it
@Composable
fun EmailField() {
    var email by remember { mutableStateOf("") }
    OutlinedTextField(value = email, onValueChange = { email = it })
}
```

**Correct:**

```kotlin
// Good - state hoisted, composable is stateless and reusable
@Composable
fun EmailField(
    email: String,
    onEmailChange: (String) -> Unit,
    isError: Boolean = false,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = email,
        onValueChange = onEmailChange,
        isError = isError,
        modifier = modifier
    )
}

// Caller controls state
@Composable
fun SignUpForm(viewModel: SignUpViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    EmailField(
        email = uiState.email,
        onEmailChange = viewModel::onEmailChanged,
        isError = uiState.emailError != null
    )
}
```

### remember vs rememberSaveable

Use `remember` for computed/derived values. Use `rememberSaveable` for user state that must survive rotation and process death.

**Incorrect:**

```kotlin
// Bad - user input lost on rotation
var query by remember { mutableStateOf("") }

// Bad - rememberSaveable for derived state (wasteful serialization)
val sorted by rememberSaveable { mutableStateOf(items.sortedBy { it.name }) }

// Bad - remember without key, stale closure
val greet = remember { { "Hello, user $userId" } }  // Never updates
```

**Correct:**

```kotlin
// Good - rememberSaveable for user input
var query by rememberSaveable { mutableStateOf("") }

// Good - remember(key) for derived/expensive values
val sorted = remember(items) { items.sortedBy { it.name } }

// Good - remember(key) to track parameter changes
val greet = remember(userId) { { "Hello, user $userId" } }

// Good - rememberSaveable with custom Saver for non-Parcelable types
var selectedDate by rememberSaveable(stateSaver = localDateSaver) {
    mutableStateOf(LocalDate.now())
}
```

**Decision guide:**

| Scenario | Use |
|----------|-----|
| User-typed text, toggle state | `rememberSaveable` |
| Computed/derived values from parameters | `remember(key)` |
| Expensive object creation (Regex, Formatter) | `remember` |
| Animation state | `remember` (via `Animatable`, `animate*AsState`) |
| Non-Parcelable types | `rememberSaveable` with custom `Saver` |

### derivedStateOf

Use `derivedStateOf` when the input changes more often than the output — it caches the derived value and only triggers recomposition when the result actually changes.

**Incorrect:**

```kotlin
// Bad - filtering runs on every recomposition
val filteredItems = if (showCompleted) items else items.filter { !it.completed }
```

**Correct:**

```kotlin
// Good - only recomputes when inputs change
val filteredItems by remember(items, showCompleted) {
    derivedStateOf {
        if (showCompleted) items else items.filter { !it.completed }
    }
}

// Good - derived state for scroll-dependent UI (listState changes every frame)
val showButton by remember {
    derivedStateOf { listState.firstVisibleItemIndex > 0 }
}
```

Don't use `derivedStateOf` for simple property access (`uiState.name`) or one-to-one mappings where output always changes with input.

### Side Effect Handlers

Never launch coroutines or register listeners directly in the composition body — use the right handler.

**Incorrect:**

```kotlin
// Bad - coroutine launched on EVERY recomposition
scope.launch { viewModel.loadUser(userId) }

// Bad - listener registered without cleanup
sensorManager.registerListener(listener, sensor, SENSOR_DELAY_NORMAL)
```

**Correct:**

```kotlin
// LaunchedEffect - runs once per key, cancels on key change or leave
LaunchedEffect(userId) {
    viewModel.loadUser(userId)
}

// DisposableEffect - register/unregister patterns with cleanup
DisposableEffect(Unit) {
    val listener = object : SensorEventListener { /* ... */ }
    sensorManager.registerListener(listener, sensor, SENSOR_DELAY_NORMAL)
    onDispose { sensorManager.unregisterListener(listener) }
}

// SideEffect - non-suspend code that runs after every successful composition
SideEffect { analytics.logScreenView("checkout") }

// LaunchedEffect + snapshotFlow - react to state changes as a Flow
LaunchedEffect(listState) {
    snapshotFlow { listState.firstVisibleItemIndex }
        .distinctUntilChanged()
        .collect { index -> analytics.logScroll(index) }
}
```

**Handler reference:**

| Handler | Suspend? | Cleanup? | Use case |
|---------|----------|----------|----------|
| `LaunchedEffect(key)` | Yes | Auto-cancels | One-shot loads, snapshotFlow |
| `DisposableEffect(key)` | No | `onDispose` | Register/unregister listeners |
| `SideEffect` | No | None | Sync Compose state to non-Compose code |
| `rememberCoroutineScope` | Yes | Cancels on leave | User-triggered events (onClick) |

**Why it matters:**
- Hoisted composables are reusable, testable, and follow UDF
- Wrong `remember` variant causes lost user input or stale closures
- `derivedStateOf` prevents expensive recomputations on unrelated state changes
- Side effects in the composition body run on every recomposition — unpredictable and leaky

Reference: [State in Compose](https://developer.android.com/develop/ui/compose/state) | [Side effects](https://developer.android.com/develop/ui/compose/side-effects)
