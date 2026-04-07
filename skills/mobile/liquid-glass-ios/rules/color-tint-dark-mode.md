---
title: Adapt Glass Tint to Light/Dark Mode; Avoid Washing Out Content
impact: MEDIUM
tags: color, tint, dark-mode, appearance, contrast
---

## Adapt Glass Tint to Light/Dark Mode; Avoid Washing Out Content

Glass tint colors must adapt to light and dark mode to maintain visual hierarchy and contrast. A single tint color can wash out content under one mode or become too prominent in another. Use `@Environment(\.colorScheme)` to adjust tint darkness.

**Incorrect (fixed tint color; washes out in one mode):**

```swift
struct FilterOverlay: View {
    var body: some View {
        VStack {
            Text("Filters")
                .font(.headline)
                .foregroundColor(.black)  // ❌ Invisible on dark background

            FilterControls()
        }
        .padding()
        .background(Material.glass)
        .tint(Color.blue.opacity(0.3))  // ❌ Fixed tint; too light in dark mode
        .cornerRadius(12)
    }
}
```

**Incorrect (no consideration for content underneath):**

```swift
struct ContentWithGlass: View {
    var body: some View {
        ZStack {
            // Content underneath
            Image("backgroundPhoto")  // Could be light or dark

            // Glass overlay with fixed tint
            VStack {
                Text("Overlay Text")  // May be hard to read depending on photo
                    .foregroundColor(.gray)  // ❌ Gray text on glass tint
            }
            .padding()
            .background(Material.glass)
            .tint(Color.yellow.opacity(0.2))  // ❌ Fixed tint; may not adapt to content
        }
    }
}
```

**Correct (adapt tint to light/dark mode):**

```swift
struct FilterOverlay: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Filters")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)  // ✅ Adaptive text

            FilterControls()
        }
        .padding()
        .background(Material.glass)
        .tint(
            colorScheme == .dark
                ? Color.white.opacity(0.1)  // ✅ Subtle tint for dark mode
                : Color.black.opacity(0.05)  // ✅ Subtle tint for light mode
        )
        .cornerRadius(12)
    }
}
```

**Or (use semantic Material variants):**

```swift
struct FilterOverlay: View {
    var body: some View {
        VStack {
            Text("Filters")
                .font(.headline)

            FilterControls()
        }
        .padding()
        .background(Material.thin)  // ✅ Automatically adapts tint to light/dark
        .cornerRadius(12)
    }
}
```

**Correct (no tint washing out content):**

```swift
struct ContentWithGlass: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Image("backgroundPhoto")

            // Glass overlay with high-contrast text and adaptive tint
            VStack(spacing: 12) {
                Text("Overlay Text")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 1)  // ✅ Shadow aids readability over glass

                Button(action: {}) {
                    Text("Action")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding()
            .background(
                Material.glass
                    .opacity(colorScheme == .dark ? 0.8 : 0.6)  // ✅ Thicker glass in dark
            )
            .cornerRadius(12)
        }
    }
}
```

**Why it matters**

- **Light mode with light tint** — glass becomes nearly transparent; content disappears.
- **Dark mode with light tint** — glass becomes too opaque; overlay drowns out content underneath.
- **Semantic clarity** — users expect visual hierarchy to be consistent across light/dark mode; inconsistent tint breaks expectations.

Always check `@Environment(\.colorScheme)` and adjust glass tint opacity or use Material variants (`.thin`, `.regular`, `.thick`) that adapt automatically. Avoid fixed colors that clash with backgrounds or content. Test on both light and dark modes before shipping.
