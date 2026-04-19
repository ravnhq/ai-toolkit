---
title: Compose Performance & UI — Lambdas, Lazy Lists, Animations, Theming
impact: HIGH
tags: compose, performance, recomposition, animation, theming
---

## Compose Performance & UI — Lambdas, Lazy Lists, Animations, Theming

Keep composables skippable, lazy lists efficient, animations declarative, and styles driven by theme tokens.

### Stable Lambdas

Lambdas that capture unstable references cause unnecessary recompositions. Use method references or hoist callbacks outside lazy scopes.

**Incorrect:**

```kotlin
// Bad - new lambda instance every recomposition, ItemRow always recomposes
LazyColumn {
    items(items, key = { it.id }) { item ->
        ItemRow(item = item, onDelete = { viewModel.deleteItem(item.id) })
    }
}

// Bad - inline lambda wrapping a simple method call
Button(onClick = { viewModel.submit() }) { Text("Submit") }
```

**Correct:**

```kotlin
// Good - hoist callback to avoid capture inside lazy scope
val onDelete = viewModel::deleteItem

LazyColumn {
    items(items, key = { it.id }) { item ->
        ItemRow(item = item, onDelete = { onDelete(item.id) })
    }
}

// Good - method reference for simple cases
Button(onClick = viewModel::submit) { Text("Submit") }

// Good - remember lambda when it captures stable values
val handleDelete = remember(item.id) { { onDelete(item.id) } }
```

### Lazy List Keys

Always provide a stable, unique `key` to `items()` in `LazyColumn`/`LazyRow`. Without keys, Compose uses positional index — inserting one item at the top recomposes every row.

**Incorrect:**

```kotlin
// Bad - no key, defaults to positional index
LazyColumn {
    items(messages) { message -> MessageRow(message) }
}
```

**Correct:**

```kotlin
// Good - unique ID as key
LazyColumn {
    items(messages, key = { it.id }) { message -> MessageRow(message) }
}

// Good - composite key when no single ID exists
items(chatEntries, key = { "${it.date}-${it.senderId}" }) { entry ->
    ChatBubble(entry)
}
```

Stable keys enable `animateItem()` animations, preserve internal component state (focus, text input) across reordering, and dramatically reduce recompositions for large lists.

### Animations

Use Compose's declarative animation APIs. Never write manual frame loops.

**Incorrect:**

```kotlin
// Bad - manual frame loop, janky, not composable-aware
LaunchedEffect(Unit) {
    while (true) {
        delay(16)
        radius += if (growing) 0.5f else -0.5f
    }
}
```

**Correct:**

```kotlin
// animate*AsState - simple value changes
val elevation by animateDpAsState(
    targetValue = if (expanded) 8.dp else 2.dp,
    label = "cardElevation"
)

// AnimatedVisibility - enter/exit transitions
AnimatedVisibility(
    visible = message != null,
    enter = fadeIn() + slideInVertically(),
    exit = fadeOut() + slideOutVertically()
) { /* content */ }

// InfiniteTransition - looping animations
val radius by rememberInfiniteTransition(label = "pulse").animateFloat(
    initialValue = 20f, targetValue = 40f,
    animationSpec = infiniteRepeatable(tween(1000), RepeatMode.Reverse),
    label = "radius"
)

// Animatable - imperative, coroutine-driven sequences
LaunchedEffect(isError) {
    if (isError) {
        offsetX.animateTo(10f, spring(dampingRatio = 0.3f))
        offsetX.animateTo(0f)
    }
}

// animateContentSize - layout size changes
Text(text, modifier = Modifier.animateContentSize().clickable { expanded = !expanded })
```

**API decision guide:**

| Scenario | API |
|----------|-----|
| Single value (color, size, offset) | `animate*AsState` |
| Show/hide with enter/exit | `AnimatedVisibility` |
| Switch between composables | `AnimatedContent` / `Crossfade` |
| Looping animation | `rememberInfiniteTransition` |
| Imperative control, sequences | `Animatable` |
| Layout size change | `Modifier.animateContentSize()` |
| Lazy list item add/remove | `Modifier.animateItem()` |

### Theming & Icons

Reference `MaterialTheme` tokens for colors, typography, and shapes. Never hardcode colors — they break dark theme, dynamic color, and high-contrast modes.

**Incorrect:**

```kotlin
// Bad - hardcoded colors, ignores theme
Surface(color = Color(0xFF6200EE)) {
    Text(title, color = Color.White, fontSize = 24.sp)
}

// Bad - mixing icon styles in the same bar
Icon(Icons.Default.Home, contentDescription = "Home")
Icon(Icons.Outlined.Settings, contentDescription = "Settings")
Icon(Icons.Rounded.Person, contentDescription = "Profile")
```

**Correct:**

```kotlin
// Good - theme tokens adapt to light/dark/dynamic color
Surface(color = MaterialTheme.colorScheme.primary) {
    Text(title, color = MaterialTheme.colorScheme.onPrimary,
         style = MaterialTheme.typography.headlineSmall)
}

// Good - consistent icon style throughout the app
Icon(Icons.Outlined.Home, contentDescription = "Home")
Icon(Icons.Outlined.Settings, contentDescription = "Settings")
Icon(Icons.Outlined.Person, contentDescription = "Profile")

// Good - semantic error colors
Box(modifier = Modifier.background(MaterialTheme.colorScheme.errorContainer)) {
    Text(message, color = MaterialTheme.colorScheme.onErrorContainer)
}
```

**Material 3 color roles:**

| Role | Use for |
|------|---------|
| `primary` / `onPrimary` | Key actions, FAB, active states |
| `secondary` / `onSecondary` | Supporting elements, chips |
| `surface` / `onSurface` | Backgrounds, cards, text |
| `error` / `onError` | Error states, destructive actions |
| `errorContainer` / `onErrorContainer` | Error banners, validation |

**Why it matters:**
- Unstable lambdas prevent Compose from skipping unchanged composables
- Missing lazy keys cause O(n) recompositions on every list mutation
- Manual animation loops bypass Compose's render pipeline and cause jank
- Hardcoded colors break dark theme and Material You dynamic color

Reference: [Compose performance](https://developer.android.com/develop/ui/compose/performance) | [Animation](https://developer.android.com/develop/ui/compose/animation/introduction) | [Material 3](https://developer.android.com/develop/ui/compose/designsystems/material3)
