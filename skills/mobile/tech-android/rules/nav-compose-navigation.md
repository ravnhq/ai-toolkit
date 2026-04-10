---
title: Compose Navigation — Single Activity, Type-Safe Args, Deep Links
impact: HIGH
tags: navigation, compose, type-safety, deep-links, architecture
---

## Compose Navigation — Single Activity, Type-Safe Args, Deep Links

Use one Activity as the host, define routes as typed data classes, and register deep links in the navigation graph.

### Single-Activity Architecture

Handle all screen transitions with Compose Navigation. Avoid multiple Activities for in-app screens.

**Incorrect:**

```kotlin
// Bad - separate Activity per screen, Intent-based navigation
class HomeActivity : ComponentActivity() { /* ... */ }
class ProfileActivity : ComponentActivity() { /* ... */ }

fun navigateToProfile(context: Context, userId: String) {
    val intent = Intent(context, ProfileActivity::class.java)
    intent.putExtra("USER_ID", userId)  // Untyped, error-prone
    context.startActivity(intent)
}
```

**Correct:**

```kotlin
// Good - one Activity hosts the entire app
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AppTheme { AppNavigation() }
        }
    }
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Home) {
        composable<Home> {
            HomeScreen(onNavigateToProfile = { userId ->
                navController.navigate(Profile(userId))
            })
        }
        composable<Profile> { backStackEntry ->
            val profile: Profile = backStackEntry.toRoute()
            ProfileScreen(userId = profile.userId)
        }
    }
}
```

Multiple Activities are still appropriate for launching external apps (camera, file picker), separate process requirements (media playback), or legacy module integration.

### Type-Safe Navigation Arguments

Define routes as `@Serializable` data classes (Navigation 2.8+). Never use raw string routes with manual argument parsing.

**Incorrect:**

```kotlin
// Bad - string routes, nullable manual parsing, crash-prone
NavHost(navController, startDestination = "home") {
    composable("profile/{userId}") { backStackEntry ->
        val userId = backStackEntry.arguments?.getString("userId") ?: return@composable
        ProfileScreen(userId)
    }
}

navController.navigate("profile/user123")  // Hardcoded string
```

**Correct:**

```kotlin
// Good - typed route definitions
@Serializable data object Home
@Serializable data class Profile(val userId: String)
@Serializable data class Order(val orderId: String, val showReview: Boolean = false)

// Good - type-safe NavHost
NavHost(navController, startDestination = Home) {
    composable<Profile> { backStackEntry ->
        val profile: Profile = backStackEntry.toRoute()
        ProfileScreen(profile.userId)
    }
    composable<Order> { backStackEntry ->
        val order: Order = backStackEntry.toRoute()
        OrderScreen(order.orderId, order.showReview)
    }
}

// Good - type-safe navigation calls
navController.navigate(Profile(userId = "user123"))
navController.navigate(Order(orderId = "ord456", showReview = true))
```

### Deep Links

Register deep links in the navigation graph, not just the manifest. The manifest declares intent filters for the OS; the navigation graph handles routing, argument extraction, and back stack synthesis.

```xml
<!-- Manifest — declares intent filter for the OS -->
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="example.com" />
    </intent-filter>
</activity>
```

```kotlin
// Navigation graph — handles routing with type-safe args and back stack
composable<Profile>(
    deepLinks = listOf(
        navDeepLink<Profile>(basePath = "https://example.com/profile")
    )
) { backStackEntry ->
    val profile: Profile = backStackEntry.toRoute()
    ProfileScreen(profile.userId)
}
// Automatically: matches URI → extracts typed args → builds back stack (Home → Profile)
```

**Why it matters:**
- Typed routes fail at compile time; string routes fail at runtime
- Single Activity simplifies shared state, theming, and process death restoration
- Navigation graph deep links get automatic argument extraction and correct back stack
- Refactoring a parameter name updates all usages — no scattered string constants

Reference: [Navigation with Compose](https://developer.android.com/develop/ui/compose/navigation) | [Type safe navigation](https://developer.android.com/guide/navigation/design/type-safety)
