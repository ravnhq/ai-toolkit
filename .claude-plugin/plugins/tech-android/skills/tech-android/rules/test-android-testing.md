---
title: Android Testing — Compose Semantics, Dispatchers, Turbine
impact: HIGH
tags: testing, compose, coroutines, dispatchers, flow, turbine
---

## Android Testing — Compose Semantics, Dispatchers, Turbine

Test composables via semantics, inject dispatchers for deterministic coroutine tests, and use Turbine for sequential Flow assertions.

### Compose UI Testing via Semantics

Test composables by querying semantics (text, content descriptions, test tags) — never by internal state, class names, or node position.

**Incorrect:**

```kotlin
// Bad - testing internal state directly
@Test
fun loginButton_showsLoading() {
    val viewModel = LoginViewModel()
    composeTestRule.setContent { LoginScreen(viewModel) }

    viewModel.onLoginClicked("user", "pass")
    assertTrue(viewModel.uiState.value.isLoading)  // Not a UI test!
}

// Bad - fragile node index queries
@Test
fun thirdItem_isVisible() {
    composeTestRule.setContent { ItemList(items) }

    composeTestRule.onAllNodes(hasClickAction())[2].assertIsDisplayed()
}
```

**Correct:**

```kotlin
// Good - test what the user sees
@Test
fun loginButton_showsLoadingIndicator() {
    composeTestRule.setContent {
        LoginScreen(viewModel = LoginViewModel())
    }

    composeTestRule.onNodeWithText("Log in").performClick()

    composeTestRule
        .onNodeWithContentDescription("Loading")
        .assertIsDisplayed()
}

// Good - test tag for elements without text
@Test
fun profileImage_isDisplayed() {
    composeTestRule.setContent {
        ProfileScreen(user = testUser)
    }

    composeTestRule
        .onNodeWithTag("profile_avatar")
        .assertIsDisplayed()
}

// Good - combined matchers for specificity
@Test
fun deleteButton_inFirstItem_isClickable() {
    composeTestRule.setContent { ItemList(items) }

    composeTestRule
        .onNode(
            hasText("Delete") and hasAnyAncestor(hasText(items.first().title))
        )
        .assertHasClickAction()
}

// Good - test user flows end-to-end
@Test
fun signUpFlow_showsSuccessMessage() {
    composeTestRule.setContent { SignUpScreen() }

    composeTestRule.onNodeWithText("Email").performTextInput("test@example.com")
    composeTestRule.onNodeWithText("Password").performTextInput("securePass123")
    composeTestRule.onNodeWithText("Sign Up").performClick()

    composeTestRule.onNodeWithText("Account created").assertIsDisplayed()
}
```

### Injecting Dispatchers for Testable Coroutines

Never hardcode `Dispatchers.IO` or `Dispatchers.Main` inside classes. Inject dispatchers so tests can substitute `TestDispatcher` for deterministic execution.

**Incorrect:**

```kotlin
// Bad - hardcoded Dispatchers.IO, untestable
class UserRepository {
    suspend fun getUser(id: String): User {
        return withContext(Dispatchers.IO) {  // Can't control in tests
            api.getUser(id)
        }
    }
}
```

**Correct:**

```kotlin
// Good - dispatcher injected via constructor
class UserRepositoryImpl(
    private val api: UserApi,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : UserRepository {
    override suspend fun getUser(id: String): User {
        return withContext(ioDispatcher) {
            api.getUser(id)
        }
    }
}

// Good - Hilt module for dispatchers
@Module
@InstallIn(SingletonComponent::class)
object DispatcherModule {
    @Provides
    @IoDispatcher
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @Provides
    @DefaultDispatcher
    fun provideDefaultDispatcher(): CoroutineDispatcher = Dispatchers.Default
}

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

// Good - test with TestDispatcher
@Test
fun getUser_returnsUser() = runTest {
    val testDispatcher = UnconfinedTestDispatcher(testScheduler)
    val repo = UserRepositoryImpl(
        api = FakeUserApi(),
        ioDispatcher = testDispatcher  // Deterministic, no threading
    )

    val user = repo.getUser("1")

    assertEquals("Alice", user.name)
}

// Good - ViewModel test with MainDispatcherRule
class UserViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    @Test
    fun loadUser_updatesState() = runTest {
        val viewModel = UserViewModel(FakeUserRepository())
        viewModel.loadUser("1")
        assertEquals("Alice", viewModel.uiState.value.name)
    }
}

class MainDispatcherRule(
    val testDispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {
    override fun starting(description: Description) {
        Dispatchers.setMain(testDispatcher)
    }
    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}
```

### Testing Flows with Turbine

Use the Turbine library to test Flow emissions with clear, sequential assertions instead of manual collection with `toList()` or `first()`.

**Incorrect:**

```kotlin
// Bad - collecting to list, timing-dependent
@Test
fun searchResults_emitFiltered() = runTest {
    val viewModel = SearchViewModel(FakeRepository())
    viewModel.search("kotlin")

    val results = viewModel.results.take(1).toList()
    assertEquals(3, results.first().size)
}
```

**Correct:**

```kotlin
// Good - Turbine asserts emissions in order
@Test
fun search_emitsLoadingThenResults() = runTest {
    val viewModel = SearchViewModel(FakeRepository())

    viewModel.results.test {
        viewModel.search("kotlin")

        assertEquals(emptyList(), awaitItem())        // Initial state
        assertEquals(3, awaitItem().size)              // Search results

        cancelAndIgnoreRemainingEvents()
    }
}

// Good - test state transitions
@Test
fun load_transitionsThroughStates() = runTest {
    val viewModel = DataViewModel(FakeRepository())

    viewModel.uiState.test {
        assertEquals(UiState.Idle, awaitItem())        // Initial

        viewModel.load()

        assertEquals(UiState.Loading, awaitItem())     // Loading
        val success = awaitItem()                       // Success
        assertIs<UiState.Success>(success)
        assertEquals(5, success.items.size)

        cancelAndIgnoreRemainingEvents()
    }
}

// Good - test error handling
@Test
fun load_emitsErrorOnFailure() = runTest {
    val repo = FakeRepository(shouldFail = true)
    val viewModel = DataViewModel(repo)

    viewModel.uiState.test {
        skipItems(1)  // Skip initial Idle state

        viewModel.load()

        assertEquals(UiState.Loading, awaitItem())
        val error = awaitItem()
        assertIs<UiState.Error>(error)
        assertEquals("Network error", error.message)

        cancelAndIgnoreRemainingEvents()
    }
}
```

**Key Turbine APIs:**

| Method | Purpose |
|--------|---------|
| `awaitItem()` | Wait for and return next emission |
| `skipItems(n)` | Skip `n` emissions |
| `awaitComplete()` | Assert the Flow completed |
| `awaitError()` | Assert the Flow threw |
| `cancelAndIgnoreRemainingEvents()` | Clean up |
| `expectNoEvents()` | Assert nothing was emitted |

**Why it matters:**
- Semantic tests survive refactors — they verify what users see, not implementation details
- Hardcoded dispatchers make tests flaky; `TestDispatcher` gives deterministic execution
- `MainDispatcherRule` replaces `Dispatchers.Main` for ViewModel tests
- Turbine asserts each emission sequentially — catches regressions in state ordering

Reference: [Compose testing](https://developer.android.com/develop/ui/compose/testing) | [Testing coroutines](https://developer.android.com/kotlin/coroutines/test) | [Turbine](https://github.com/cashapp/turbine)
