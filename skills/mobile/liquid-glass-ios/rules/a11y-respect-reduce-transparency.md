---
title: Always Respect Reduce Transparency; Provide Solid Fallback
impact: HIGH
tags: accessibility, a11y, glass, voiceover, reduced-transparency
---

## Always Respect Reduce Transparency; Provide Solid Fallback

Glass effects rely on blur and transparency for visual effect. Users with reduced transparency enabled in Accessibility settings expect solid, opaque overlays instead. Check `accessibilityReduceTransparency` and switch to solid background when enabled.

**Incorrect (glass effect ignores accessibility setting):**

```swift
struct FilterPanel: View {
    var body: some View {
        VStack {
            Text("Filters")
                .font(.headline)
            Divider()
            FilterControls()
        }
        .padding()
        .background(Material.glass)  // ❌ Ignores reduced transparency setting
        .cornerRadius(12)
    }
}
```

**Incorrect (no transparency fallback for contrast):**

```swift
struct OverlayView: View {
    var body: some View {
        Text("Content with low contrast")
            .foregroundColor(.gray)  // ❌ Gray text on glass may be hard to read
            .padding()
            .background(Material.glass)  // ❌ No guaranteed contrast
            .cornerRadius(12)
    }
}
```

**Correct (check accessibility setting and fall back to solid):**

```swift
struct FilterPanel: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        VStack {
            Text("Filters")
                .font(.headline)
            Divider()
            FilterControls()
        }
        .padding()
        .background(
            Group {
                if reduceTransparency {
                    Color(UIColor.systemGray6)  // ✅ Solid opaque color
                } else {
                    Material.glass  // ✅ Glass when transparency is allowed
                }
            }
        )
        .cornerRadius(12)
    }
}
```

**Or (custom helper for clean code):**

```swift
struct FilterPanel: View {
    var body: some View {
        VStack {
            Text("Filters")
                .font(.headline)
            Divider()
            FilterControls()
        }
        .padding()
        .background(AccessibleGlassBackground())  // ✅ Encapsulates a11y logic
        .cornerRadius(12)
    }
}

struct AccessibleGlassBackground: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Color(UIColor.systemGray6)
        } else {
            Material.glass
        }
    }
}
```

**Correct (ensure text contrast on glass):**

```swift
struct OverlayView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text("Accessible content on glass")
            .foregroundColor(colorScheme == .dark ? .white : .black)  // ✅ High contrast
            .padding()
            .background(Material.glass)
            .cornerRadius(12)
    }
}
```

**Why it matters**

- **Reduced transparency** is enabled by users with visual processing disorders, vestibular conditions, or general sensitivity to motion and blur.
- **Glass + light text** on bright backgrounds creates low contrast ratios (WCAG AA failure).
- **No fallback** forces accessibility-dependent users to request a redesign or disable the feature entirely.

Always check `@Environment(\.accessibilityReduceTransparency)` before applying glass. Provide a solid, high-contrast alternative that meets WCAG AA standards (4.5:1 text contrast ratio).
