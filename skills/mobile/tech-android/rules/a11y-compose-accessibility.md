---
title: Compose Accessibility — Descriptions, Semantics Trees, Headings, Touch Targets
impact: HIGH
tags: accessibility, compose, screen-reader, semantics, touch
---

## Compose Accessibility — Descriptions, Semantics Trees, Headings, Touch Targets

Every meaningful UI element must be accessible: labeled for screen readers, semantically marked for navigation, and large enough to tap.

### Content Descriptions

Every meaningful non-text element (icons, images, buttons without text) must have a content description for screen readers.

**Incorrect:**

```kotlin
// Bad - icon button with no description
IconButton(onClick = { onDelete() }) {
    Icon(Icons.Default.Delete, contentDescription = null) // Silent to TalkBack!
}

// Bad - decorative image announced with filename
Image(
    painter = painterResource(R.drawable.hero_banner),
    contentDescription = "hero_banner"  // Meaningless to users
)
```

**Correct:**

```kotlin
// Good - meaningful description for action icon
IconButton(onClick = { onDelete() }) {
    Icon(Icons.Default.Delete, contentDescription = "Delete item")
}

// Good - decorative image marked as such (null = skipped by TalkBack)
Image(
    painter = painterResource(R.drawable.hero_banner),
    contentDescription = null
)
```

**Decision guide:**
- **Actionable icon** → describe the action ("Delete item", "Open menu")
- **Informational image** → describe the content ("Photo of sunset over ocean")
- **Decorative image** → set `contentDescription = null`

### Merging Semantics Trees

Use `semantics(mergeDescendants = true)` to collapse a composable subtree into a single TalkBack node. Without it, TalkBack reads each child individually, forcing users to swipe through every `Text`, `Icon`, and `Image` inside a card or row.

**Incorrect:**

```kotlin
// Bad - TalkBack reads 4 separate nodes: icon, name, email, chevron
Row(modifier = Modifier.clickable { navigateToProfile() }) {
    Icon(Icons.Default.Person, contentDescription = "Avatar")
    Column {
        Text("Jane Doe")
        Text("jane@example.com")
    }
    Icon(Icons.Default.ChevronRight, contentDescription = "Go")
}
```

**Correct:**

```kotlin
// Good - TalkBack reads one node: "Jane Doe, jane@example.com"
Row(
    modifier = Modifier
        .semantics(mergeDescendants = true) { }
        .clickable { navigateToProfile() }
) {
    Icon(Icons.Default.Person, contentDescription = null) // Merged — no need for description
    Column {
        Text("Jane Doe")
        Text("jane@example.com")
    }
    Icon(Icons.Default.ChevronRight, contentDescription = null) // Decorative within merged tree
}

// Good - card with custom accessibility label
Card(
    modifier = Modifier
        .semantics(mergeDescendants = true) {
            contentDescription = "Order #1234, shipped, tap to view details"
        }
        .clickable { navigateToOrder(orderId) }
) {
    Text("Order #1234")
    Text("Status: Shipped")
    Icon(Icons.Default.LocalShipping, contentDescription = null)
}
```

**When to merge:**
- **Clickable rows/cards** with icon + text → merge so TalkBack announces it as one item
- **List items** with multiple text fields → merge to avoid per-field swiping
- **Info groups** (label + value pairs) → merge for a single coherent announcement

**When NOT to merge:**
- Container has **independently interactive children** (e.g., a row with both a checkbox and a delete button)
- Children need **separate focus** for navigation (e.g., form fields inside a section)

### Heading Semantics

Use the `heading()` semantic property so TalkBack users can navigate between sections with swipe gestures.

**Incorrect:**

```kotlin
// Bad - visually styled as heading but no semantics
Text(
    text = "Account Settings",
    style = MaterialTheme.typography.headlineMedium
    // TalkBack reads this as plain text — users can't jump to it
)
```

**Correct:**

```kotlin
// Good - semantic heading property
Text(
    text = "Account Settings",
    style = MaterialTheme.typography.headlineMedium,
    modifier = Modifier.semantics { heading() }
)
```

Apply `heading()` to screen titles, section headers in lists or forms, and any text visually styled as a heading.

### Touch Target Size

All interactive elements must have a minimum touch target of 48×48dp, regardless of visual size.

**Incorrect:**

```kotlin
// Bad - icon is 24dp with no touch padding
Icon(
    Icons.Default.Close,
    contentDescription = "Close",
    modifier = Modifier
        .size(24.dp)
        .clickable { onClose() }  // Touch target = 24dp, too small!
)
```

**Correct:**

```kotlin
// Good - IconButton automatically ensures 48dp touch target
IconButton(onClick = { onClose() }) {
    Icon(Icons.Default.Close, contentDescription = "Close", modifier = Modifier.size(24.dp))
}

// Good - explicit minimum touch target via sizeIn
Icon(
    Icons.Default.Close,
    contentDescription = "Close",
    modifier = Modifier
        .sizeIn(minWidth = 48.dp, minHeight = 48.dp)
        .clickable { onClose() }
)
```

**Why it matters:**
- TalkBack users cannot interact with unlabeled elements
- Without heading semantics, users must listen through every item sequentially
- Users with motor impairments cannot reliably tap small targets (WCAG 2.5.5)
- Required for WCAG 2.1 Level A compliance

Reference: [Accessibility in Compose](https://developer.android.com/develop/ui/compose/accessibility)
