---
name: liquid-glass
description: Guide for adopting Apple's Liquid Glass design system in SwiftUI apps (iOS 26+, macOS Tahoe 26+). Covers glassEffect modifiers, GlassEffectContainer, morphing transitions, platform-specific patterns, and anti-patterns to avoid.
license: MIT
metadata:
  version: 1.0.0
  model: claude-opus-4-5-20251101
  platforms: iOS 26+, iPadOS 26+, macOS Tahoe 26+, watchOS 26+, tvOS 26+
---

# Liquid Glass

Adopt Apple's Liquid Glass design system correctly in SwiftUI.

---

## Triggers

Use this skill when:
- Building or updating SwiftUI apps for iOS 26+ / macOS Tahoe 26+
- Implementing glass effects, floating toolbars, or morphing UI
- User mentions "liquid glass", "glass effect", "iOS 26 design"
- Reviewing code that uses `.glassEffect()` or `GlassEffectContainer`
- Migrating existing apps to the new Apple design language

---

## Quick Reference

| API | Purpose | Example |
|-----|---------|---------|
| `.glassEffect()` | Basic glass (capsule) | `view.glassEffect()` |
| `.glassEffect(.regular.tint(.blue))` | Tinted glass | Color emphasis |
| `.glassEffect(.regular.interactive())` | Touch-responsive | Buttons, controls |
| `.glassEffect(.clear, in: .circle)` | High transparency | Media overlays |
| `GlassEffectContainer` | Group + morph | Multiple glass views |
| `.glassEffectID(_:in:)` | Morphing identity | Animated transitions |
| `.buttonStyle(.glass)` | Translucent button | Standard actions |
| `.buttonStyle(.glassProminent)` | Opaque button | Primary actions |

---

## Core Principle

**Glass is for NAVIGATION, not CONTENT.**

```
+----------------------------------------+
|  Glass Layer (toolbars, controls, FAB) |  <-- .glassEffect() HERE
+----------------------------------------+
|                                        |
|  Content Layer (lists, media, text)    |  <-- NEVER glass
|                                        |
+----------------------------------------+
```

---

## Glass Effect Basics

### Minimal Usage

```swift
Button("Action") { }
    .padding()
    .glassEffect()  // Default: .regular variant, .capsule shape
```

### Full Signature

```swift
.glassEffect(
    _ style: GlassEffectStyle = .regular,
    in shape: some Shape = .capsule,
    isEnabled: Bool = true
)
```

### Variants

| Variant | Transparency | Use Case |
|---------|--------------|----------|
| `.regular` | Medium | Most UI elements (default) |
| `.clear` | High | Over media-rich backgrounds |
| `.identity` | None | Conditional disabling |

**`.clear` Requirements** (all must be met):
1. Element is over media-rich content
2. Content won't suffer from dimming
3. Content above glass is bold/bright

### Tinting

```swift
.glassEffect(.regular.tint(.blue))
.glassEffect(.regular.tint(.purple.opacity(0.6)))
```

### Interactive (iOS only)

```swift
.glassEffect(.regular.interactive())  // Enables touch feedback
```

Interactive behaviors:
- Scale on press
- Bounce animation
- Shimmer effect
- Touch-point illumination

---

## Shapes

| Shape | Code | Platform Preference |
|-------|------|---------------------|
| Capsule | `.capsule` (default) | iOS/iPadOS primary |
| Circle | `.circle` | Icon buttons |
| Rounded Rect | `RoundedRectangle(cornerRadius: 16)` | macOS preference |
| Concentric | `.rect(cornerRadius: .containerConcentric)` | Nested elements |
| Ellipse | `.ellipse` | Special cases |

### Platform-Specific Shapes

```swift
#if os(iOS)
.glassEffect(in: .capsule)  // iOS favors capsules
#else
.glassEffect(in: RoundedRectangle(cornerRadius: 8))  // macOS: rounded rect for small controls
#endif
```

---

## GlassEffectContainer

**Required when using multiple glass effects.** Provides:
- Automatic blending of overlapping shapes
- Consistent blur/lighting
- Smooth morphing transitions
- Better rendering performance

### Basic Usage

```swift
GlassEffectContainer {
    HStack(spacing: 16) {
        Button("Home") { }
            .glassEffect()
        Button("Search") { }
            .glassEffect()
        Button("Profile") { }
            .glassEffect()
    }
    .padding()
}
```

### Spacing Parameter

Controls merge distance—elements within this distance morph together:

```swift
GlassEffectContainer(spacing: 40) {
    // Elements within 40pt blend/morph
}
```

---

## Morphing Transitions

Fluid shape transitions require **three components**:

1. `GlassEffectContainer` grouping
2. `@Namespace` for identity tracking
3. `.glassEffectID(_:in:)` modifier

### Example: Expandable Toolbar

```swift
struct ExpandableToolbar: View {
    @State private var isExpanded = false
    @Namespace private var animation

    var body: some View {
        GlassEffectContainer(spacing: 30) {
            HStack(spacing: 12) {
                Button {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.left" : "plus")
                }
                .glassEffect(.regular.interactive())
                .glassEffectID("toggle", in: animation)

                if isExpanded {
                    Button("Edit") { }
                        .glassEffect()
                        .glassEffectID("edit", in: animation)

                    Button("Share") { }
                        .glassEffect()
                        .glassEffectID("share", in: animation)

                    Button("Delete") { }
                        .glassEffect(.regular.tint(.red))
                        .glassEffectID("delete", in: animation)
                }
            }
            .padding()
        }
    }
}
```

---

## Button Styles

```swift
// Translucent - standard actions
Button("Cancel") { }
    .buttonStyle(.glass)

// Opaque/emphasized - primary actions
Button("Done") { }
    .buttonStyle(.glassProminent)
```

---

## Modifier Order

**Apply `.glassEffect()` AFTER appearance modifiers:**

```swift
// CORRECT
Text("Label")
    .font(.headline)
    .foregroundStyle(.white)
    .padding()
    .glassEffect()

// WRONG - glass applied before styling
Text("Label")
    .glassEffect()
    .font(.headline)  // Won't work as expected
```

---

## Accessibility

Liquid Glass automatically adapts to accessibility settings:

| Setting | Adaptation |
|---------|------------|
| Reduce Transparency | Increased frosting |
| Increase Contrast | Stark colors/borders |
| Reduce Motion | Toned down animations |

### Manual Override (if needed)

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

.glassEffect(reduceTransparency ? .identity : .regular)
```

---

## Anti-Patterns

| Don't | Why | Instead |
|-------|-----|---------|
| Glass on content (lists, tables) | Obscures readability | Glass on navigation only |
| Multiple glass views without container | Performance + no morphing | Use `GlassEffectContainer` |
| Inconsistent shapes across app | Visual fragmentation | Pick one shape family |
| Skip animation on state changes | Jarring transitions | Always use `withAnimation` |
| `.clear` over dimmable content | Content becomes unreadable | Use `.regular` |
| `.interactive()` without purpose | Confusing affordances | Only for tappable elements |
| Glass on every view | Visual noise | Selective, purposeful use |

---

## Common Patterns

### Floating Action Button

```swift
GlassEffectContainer {
    Button {
        // action
    } label: {
        Image(systemName: "plus")
            .font(.title2)
            .foregroundStyle(.white)
    }
    .frame(width: 56, height: 56)
    .glassEffect(.regular.interactive(), in: .circle)
}
```

### Toolbar

```swift
GlassEffectContainer {
    HStack {
        ToolbarButton(icon: "pencil")
        ToolbarButton(icon: "trash")
        Spacer()
        ToolbarButton(icon: "square.and.arrow.up")
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
}

struct ToolbarButton: View {
    let icon: String
    var body: some View {
        Button { } label: {
            Image(systemName: icon)
                .frame(width: 44, height: 44)
        }
        .glassEffect(.regular.interactive())
    }
}
```

### Segmented Control

```swift
GlassEffectContainer(spacing: 0) {
    HStack(spacing: 0) {
        ForEach(options, id: \.self) { option in
            Button(option) {
                withAnimation(.bouncy) {
                    selected = option
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassEffect(selected == option ? .regular : .identity)
        }
    }
}
```

---

## Platform Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 26.0+ |
| iPadOS | 26.0+ |
| macOS | Tahoe 26.0+ |
| watchOS | 26.0+ |
| tvOS | 26.0+ |
| Xcode | 26+ |

---

## Verification Checklist

Before shipping Liquid Glass UI:

- [ ] Glass applied only to navigation layer, not content
- [ ] All multiple glass views wrapped in `GlassEffectContainer`
- [ ] `.glassEffect()` applied after appearance modifiers
- [ ] Consistent shape usage (capsule vs rounded rect)
- [ ] State changes wrapped in `withAnimation`
- [ ] `.interactive()` only on tappable elements
- [ ] Tested with Reduce Transparency enabled
- [ ] Tested on target platforms

---

## References

- [API Reference](references/api-reference.md) - Complete modifier signatures
- [Patterns Catalog](references/patterns.md) - More implementation examples

---

## Sources

- [Apple Newsroom: Liquid Glass Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [WWDC25: Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Understanding GlassEffectContainer - DEV](https://dev.to/arshtechpro/understanding-glasseffectcontainer-in-ios-26-2n8p)
