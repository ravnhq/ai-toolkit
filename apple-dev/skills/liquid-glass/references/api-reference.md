# Liquid Glass API Reference

Complete modifier signatures and parameters.

---

## glassEffect

```swift
func glassEffect(
    _ style: GlassEffectStyle = .regular,
    in shape: some Shape = .capsule,
    isEnabled: Bool = true
) -> some View
```

### GlassEffectStyle

| Style | Description |
|-------|-------------|
| `.regular` | Medium transparency, default for most UI |
| `.clear` | High transparency for media-rich backgrounds |
| `.identity` | No effect (conditional disabling) |

### Style Modifiers

```swift
// Tinting
GlassEffectStyle.regular.tint(_ color: Color) -> GlassEffectStyle

// Interactive (iOS only)
GlassEffectStyle.regular.interactive(_ isInteractive: Bool = true) -> GlassEffectStyle

// Chaining
.regular.tint(.blue).interactive()
```

### Supported Shapes

```swift
.capsule                              // Default, iOS-preferred
.circle                               // Circular buttons
.ellipse                              // Oval shapes
RoundedRectangle(cornerRadius: CGFloat)  // Custom corners
.rect(cornerRadius: RectangleCornerRadii)  // Per-corner control
.rect(cornerRadius: .containerConcentric)  // Nested alignment
```

---

## GlassEffectContainer

```swift
struct GlassEffectContainer<Content: View>: View {
    init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    )
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `spacing` | `CGFloat?` | `nil` | Merge distance for morphing |

### Behavior

- Elements within `spacing` distance blend together
- `nil` spacing uses system default
- Higher values = more aggressive merging

---

## glassEffectID

```swift
func glassEffectID<ID: Hashable>(
    _ id: ID,
    in namespace: Namespace.ID
) -> some View
```

### Requirements

1. View must be inside `GlassEffectContainer`
2. Namespace must be shared across morphing views
3. State changes must use `withAnimation`

### Example

```swift
@Namespace private var ns

GlassEffectContainer {
    if showDetail {
        DetailView()
            .glassEffect()
            .glassEffectID("card", in: ns)
    } else {
        CompactView()
            .glassEffect()
            .glassEffectID("card", in: ns)
    }
}
```

---

## Button Styles

### GlassButtonStyle

```swift
.buttonStyle(.glass)
```

- Translucent appearance
- Standard for secondary actions

### GlassProminentButtonStyle

```swift
.buttonStyle(.glassProminent)
```

- Opaque/emphasized
- Primary actions (Done, Submit, etc.)

---

## Environment Values

### Accessibility

```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency
@Environment(\.accessibilityReduceMotion) var reduceMotion
@Environment(\.accessibilityIncreaseContrast) var increaseContrast
```

### Usage

```swift
var body: some View {
    Button("Action") { }
        .glassEffect(reduceTransparency ? .identity : .regular)
}
```

---

## Platform Availability

```swift
@available(iOS 26.0, *)
@available(iPadOS 26.0, *)
@available(macOS 26.0, *)
@available(watchOS 26.0, *)
@available(tvOS 26.0, *)
```

### Conditional Compilation

```swift
#if canImport(SwiftUI) && compiler(>=6.0)
// iOS 26+ glass effects
.glassEffect()
#else
// Fallback for older OS
.background(.ultraThinMaterial)
#endif
```
