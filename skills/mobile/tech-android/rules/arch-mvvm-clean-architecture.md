---
title: MVVM + Clean Architecture — Layers, UDF, ViewModel Purity
impact: CRITICAL
tags: architecture, mvvm, clean-architecture, state, viewmodel
---

## MVVM + Clean Architecture — Layers, UDF, ViewModel Purity

Follow a strict layer hierarchy with unidirectional data flow. State flows down, events flow up, and each layer only knows about the one directly below it.

### Layer Hierarchy

```
Composable → ViewModel → UseCase (optional) → Repository → DataSource
```

- **Composable** — observes UI state, emits user events. No business logic.
- **ViewModel** — holds `StateFlow<UiState>`, handles events, orchestrates use cases or repositories. No Android framework imports.
- **UseCase** — optional, only when business logic spans multiple repositories or needs to be reused across ViewModels. Pure Kotlin. Always define as interface + implementation.
- **Repository** — single source of truth for a data type. Coordinates between data sources. Exposes suspend functions or Flows. Always define as interface + implementation.
- **DataSource** — remote (API clients) and local (Room DAOs, DataStore). Framework dependencies live here. Always define as interface + implementation.

Every UseCase, Repository, and DataSource must be split into an **interface** (consumed by the layer above) and an **implementation** (injected via Hilt). This enables testing with fakes, swapping implementations, and enforces layer boundaries at compile time.

**Incorrect (concrete classes, layers bypassed):**

```kotlin
// Bad - Composable calls repository directly, skipping ViewModel
@Composable
fun ProfileScreen(repository: ProfileRepository) {
    val profile = repository.getProfile().collectAsState(null)
}

// Bad - no interface, ViewModel coupled to concrete implementation
class ProfileRepository(private val api: ProfileApi) {
    suspend fun getProfile(): Result<Profile> = runCatching {
        api.getProfile().toDomain()
    }
}

class ProfileViewModel(
    private val repo: ProfileRepository  // Concrete class — can't substitute for tests
) : ViewModel() { /* ... */ }
```

**Correct (interface/implementation pairs, clean boundaries):**

```kotlin
// DataSource — interface defines the contract
interface ProfileRemoteDataSource {
    suspend fun fetchProfile(): ProfileDto
}

class ProfileRemoteDataSourceImpl(
    private val api: ProfileApi
) : ProfileRemoteDataSource {
    override suspend fun fetchProfile(): ProfileDto = api.getProfile()
}

// Repository — interface consumed by ViewModel/UseCase
interface ProfileRepository {
    suspend fun getProfile(): Result<Profile>
    suspend fun saveName(name: String)
}

class ProfileRepositoryImpl(
    private val remote: ProfileRemoteDataSource,
    private val local: ProfileLocalDataSource
) : ProfileRepository {
    override suspend fun getProfile(): Result<Profile> = runCatching {
        remote.fetchProfile().toDomain()
    }
    override suspend fun saveName(name: String) { local.updateName(name) }
}

// ViewModel — depends on interfaces only
class ProfileViewModel(
    private val profileRepository: ProfileRepository  // Interface, not Impl
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    fun onSaveClicked() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            profileRepository.saveName(_uiState.value.name)
                .onSuccess { _uiState.update { it.copy(isLoading = false) } }
                .onFailure { e ->
                    _uiState.update { it.copy(isLoading = false, error = e.message) }
                }
        }
    }
}
```

### Unidirectional Data Flow

State flows down from ViewModel to Composable via `StateFlow`. Events flow up from Composable to ViewModel via method calls. The UI never mutates state directly.

**Incorrect (bidirectional state mutation):**

```kotlin
class ProfileViewModel : ViewModel() {
    var name = mutableStateOf("")         // Exposed mutable state!
    var isLoading = mutableStateOf(false) // Multiple independent states can go out of sync
}

@Composable
fun ProfileScreen(viewModel: ProfileViewModel) {
    TextField(
        value = viewModel.name.value,
        onValueChange = { viewModel.name.value = it }  // Direct mutation!
    )
}
```

**Correct (UDF with direct methods):**

```kotlin
data class ProfileUiState(
    val name: String = "",
    val isLoading: Boolean = false,
    val error: String? = null
)

class ProfileViewModel(
    private val profileRepository: ProfileRepository  // Interface
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    fun onNameChanged(name: String) {
        _uiState.update { it.copy(name = name) }
    }

    fun onSaveClicked() { /* ... */ }
}

@Composable
fun ProfileScreen(viewModel: ProfileViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    TextField(
        value = uiState.name,
        onValueChange = viewModel::onNameChanged  // Event flows UP
    )
}
```

**Correct (UDF with sealed events — for complex screens):**

```kotlin
sealed interface ProfileEvent {
    data class OnNameChanged(val name: String) : ProfileEvent
    data object OnSaveClicked : ProfileEvent
}

class ProfileViewModel(
    private val profileRepository: ProfileRepository  // Interface
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    fun handleEvent(event: ProfileEvent) {
        when (event) {
            is ProfileEvent.OnNameChanged ->
                _uiState.update { it.copy(name = event.name) }
            is ProfileEvent.OnSaveClicked -> { /* ... */ }
        }
    }
}

@Composable
fun ProfileScreen(viewModel: ProfileViewModel) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    TextField(
        value = uiState.name,
        onValueChange = { viewModel.handleEvent(ProfileEvent.OnNameChanged(it)) }
    )
}
```

> **When to use each approach:**
> - **Direct methods** — simpler screens with few actions; easier to read and navigate.
> - **Sealed events** — complex screens with many actions, or when you need to log/intercept all user interactions through a single entry point (analytics, debugging).

### ViewModel Purity

ViewModels must have zero Android framework imports. All dependencies are injected as **interfaces** — the ViewModel never sees concrete implementations or framework types.

**What to abstract:**

| Instead of | Inject |
|------------|--------|
| `Context` | Repository or provider interface |
| `SharedPreferences` | `PreferencesRepository` interface backed by DataStore |
| `ConnectivityManager` | `NetworkMonitor` interface |
| `R.string.*` | `StringProvider` interface or pass strings from Composable |

**Why it matters:**
- ViewModels become testable with plain JUnit — no Robolectric or instrumentation
- Prevents Activity/Context memory leaks
- Data sources can be swapped (API → local cache) without touching ViewModel or UI
- State transitions are explicit, traceable, and free of race conditions

Reference: [Guide to app architecture](https://developer.android.com/topic/architecture)
