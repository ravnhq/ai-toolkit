# Liquid Glass Design Reference for iOS 26+

A comprehensive guide to implementing Liquid Glass effects in iOS 26+ applications. This reference consolidates all design patterns, best practices, and technical requirements for working with Apple's Liquid Glass design system.

## Table of Contents

- [Platform & Availability](#platform--availability)
- [Navigation & UI Layer](#navigation--ui-layer)
- [Variants & Styling](#variants--styling)
- [Container & Multi-Element Management](#container--multi-element-management)
- [Morphing & Animations](#morphing--animations)
- [Performance & Limits](#performance--limits)
- [Accessibility](#accessibility)
- [UIKit Integration](#uikit-integration)
- [Framework Interoperability](#framework-interoperability)

---

## Platform & Availability

### Always Wrap Glass with #available(iOS 26.0, *)

Glass effects are only available on iOS 26.0+ and iPadOS 26.0+. Always wrap glass code in availability checks to prevent crashes on older iOS versions.

**Incorrect:**

```swift
// ❌ WRONG: No availability check, crashes on iOS 25 and below
struct NavBar: View {
    var body: some View {
        NavigationStack {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("My App")
                            .glassEffect()  // ❌ Crashes on iOS < 26
                    }
                }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Availability check with fallback
struct NavBar: View {
    var body: some View {
        NavigationStack {
            ContentView()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        if #available(iOS 26.0, *) {
                            Text("My App")
                                .glassEffect()  // ✅ Safe on iOS 26+
                        } else {
                            Text("My App")
                                .background(.ultraThinMaterial)  // Fallback
                        }
                    }
                }
        }
    }
}
```

**Why it matters:** The `.glassEffect()` modifier and related APIs (`UIGlassEffect`, `GlassEffectContainer`) don't exist on iOS 25 and earlier. Calling them without availability checks causes immediate runtime crashes. Using `#available` ensures graceful degradation with appropriate fallback styling for older iOS versions.

**Reference:** [Checking API Availability](https://developer.apple.com/documentation/swift/checking-api-availability)

---

## Navigation & UI Layer

### Apply Glass to Navigation Layer Only, Never Content

Liquid Glass is designed exclusively for navigation and chrome elements (nav bars, toolbars, tab bars, sheets). Applying glass to content reduces readability and violates Apple's design system.

**Incorrect:**

```swift
// ❌ WRONG: Glass applied to content
struct ContentView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VStack {
                Image("photo")
                    .glassEffect()  // Content should not have glass

                Text("Description")
                    .glassEffect()  // Text content with glass is unreadable

                ContentCard()
                    .glassEffect()  // Cards are content, not navigation
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Glass only on navigation elements
struct ContentView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                ScrollView {
                    // Content with NO glass
                    Image("photo")
                    Text("Description")
                    ContentCard()
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("My App")
                            .glassEffect()  // ✅ Navigation chrome only
                    }
                }
            }
        }
    }
}
```

**Why it matters:** Glass creates depth through optical distortion, which is perfect for separating navigation from content but makes text and images harder to read. Applying glass to content violates HIG guidelines and creates accessibility issues.

**Reference:** [HIG - Liquid Glass](https://developer.apple.com/design/human-interface-guidelines/liquid-glass)

### Never Apply Glass in Scrolling Lists or Grids

Never apply glass effects to list rows, grid cells, or any repeated elements in scrollable containers. This causes severe performance degradation and frame drops during scrolling.

**Incorrect:**

```swift
// ❌ WRONG: Glass on every list row
struct MessageList: View {
    let messages: [Message]

    var body: some View {
        if #available(iOS 26.0, *) {
            List(messages) { message in
                MessageRow(message)
                    .glassEffect()  // ❌ Hundreds of glass effects while scrolling
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Glass only on fixed navigation elements
struct MessageList: View {
    let messages: [Message]

    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                List(messages) { message in
                    MessageRow(message)  // ✅ Standard row styling
                }
                .navigationTitle("Messages")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ComposeButton()
                            .glassEffect()  // ✅ Single fixed element
                    }
                }
            }
        }
    }
}
```

**Why it matters:** During scrolling, iOS constantly creates/destroys views for list cells. Each new glass effect requires GPU initialization and rendering setup. With dozens of cells scrolling at 120fps, this creates hundreds of effect instantiations per second, overwhelming the GPU and causing visible stuttering. Glass is designed for static navigation chrome, not dynamic content.

**Reference:** [Performance Best Practices for Glass](https://developer.apple.com/documentation/swiftui/glasseffect/performance)

---

## Variants & Styling

### Use .regular Variant as Default for Standard UI

The `.regular` variant is the default and correct choice for all standard UI elements like navigation bars, toolbars, tab bars, and sheets. Other variants are for specific use cases only.

**Incorrect:**

```swift
// ❌ WRONG: Using .clear for standard navigation
struct AppView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("My App")
                                .glassEffect(.clear)  // ❌ Wrong variant
                        }
                    }
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: .regular for standard navigation
struct AppView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("My App")
                                .glassEffect(.regular)  // ✅ Default variant
                        }
                    }
            }
        }
    }
}
```

**Why it matters:** The `.regular` variant provides optimal contrast and readability for standard UI contexts. Using `.clear` in non-media contexts reduces legibility and violates Apple's design guidelines. `.clear` is only for overlaying rich media content like video players.

**Reference:** [HIG - Choosing Glass Variants](https://developer.apple.com/design/human-interface-guidelines/liquid-glass#choosing-variants)

### Use .clear Variant Only Over Rich Media Content

The `.clear` variant is designed exclusively for controls that overlay rich media content (video, photos, immersive experiences). Never use it for standard UI elements.

**Incorrect:**

```swift
// ❌ WRONG: .clear on standard UI with text background
struct SettingsView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            List {
                Section("Preferences") {
                    // List content
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Done") {}
                        .glassEffect(.clear)  // ❌ No media background
                }
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: .clear only over video/media
struct VideoPlayerView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VideoPlayer(player: player)
                .overlay(alignment: .bottom) {
                    PlaybackControls()
                        .glassEffect(.clear)  // ✅ Over video content
                }
        }
    }
}
```

**Why it matters:** The `.clear` variant has minimal optical distortion optimized for media-rich backgrounds where visual content needs to show through. On standard UI backgrounds (solid colors, subtle gradients), it reduces contrast to the point of illegibility and provides poor separation from content.

**Reference:** [HIG - Glass Variant Use Cases](https://developer.apple.com/design/human-interface-guidelines/liquid-glass#use-cases)

### Use .identity Variant to Conditionally Disable Glass

Use the `.identity` variant to temporarily disable glass effects based on conditions (debug mode, low power mode, user preferences) without removing the modifier.

**Incorrect:**

```swift
// ❌ WRONG: Conditional compilation removes the modifier
struct NavBar: View {
    var isDebugMode: Bool

    var body: some View {
        if #available(iOS 26.0, *) {
            Text("App Name")
                #if DEBUG
                // No glass effect - inconsistent code paths
                #else
                .glassEffect(.regular)
                #endif
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Use .identity to disable conditionally
struct NavBar: View {
    var isDebugMode: Bool

    var body: some View {
        if #available(iOS 26.0, *) {
            Text("App Name")
                .glassEffect(isDebugMode ? .identity : .regular)
        }
    }
}
```

**Why it matters:** Using `.identity` keeps the glass modifier structure intact while dynamically disabling the effect. This maintains consistent view hierarchy, simplifies testing, and allows runtime toggling without code branching. Removing modifiers conditionally creates different view hierarchies that can cause layout bugs.

**Reference:** [SwiftUI GlassEffect Variants API](https://developer.apple.com/documentation/swiftui/glasseffect/variants)

### Never Mix Glass Variants in Same Container

All glass elements within a single container must use the same variant (.regular, .clear, or .identity). Mixing variants causes rendering inconsistencies and visual discord.

**Incorrect:**

```swift
// ❌ WRONG: Mixing .regular and .clear variants
struct MediaControls: View {
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                PlayButton()
                    .glassEffectID("play", in: glassNamespace)
                    .glassEffect(.regular)  // Regular variant

                VolumeControl()
                    .glassEffectID("volume", in: glassNamespace)
                    .glassEffect(.clear)  // ❌ Different variant!
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Consistent variant across container
struct MediaControls: View {
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                PlayButton()
                    .glassEffectID("play", in: glassNamespace)

                VolumeControl()
                    .glassEffectID("volume", in: glassNamespace)
            }
            .glassEffect(.clear)  // ✅ Single variant for entire container
        }
    }
}
```

**Why it matters:** Each variant has different optical properties (lensing strength, transparency, refraction). Mixing them creates visual inconsistency and breaks the unified material appearance that glass is designed to provide. Apply the variant to the container, not individual children.

**Reference:** [HIG - Liquid Glass Variants](https://developer.apple.com/design/human-interface-guidelines/liquid-glass#variants)

### Use Semantic Colors, Never Hardcoded RGB Values

Always use semantic system colors (`.blue`, `.red`, etc.) for glass tinting. Never use hardcoded RGB values, as glass auto-adapts semantic colors to light/dark mode.

**Incorrect:**

```swift
// ❌ WRONG: Hardcoded RGB prevents dark mode adaptation
struct PrimaryButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Button("Submit") {}
                .glassEffect(.regular.tint(
                    Color(red: 0.0, green: 0.478, blue: 1.0)  // ❌ Hardcoded
                ))
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Semantic colors adapt automatically
struct PrimaryButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Button("Submit") {}
                .glassEffect(.regular.tint(.blue))  // ✅ Semantic color
        }
    }
}

// Or use custom semantic colors from asset catalog
extension Color {
    static let brandPrimary = Color("BrandPrimary")  // ✅ Asset catalog
}

struct BrandButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Button("Continue") {}
                .glassEffect(.regular.tint(.brandPrimary))
        }
    }
}
```

**Why it matters:** Glass effects automatically adjust semantic colors for light/dark mode, increasing/decreasing saturation and brightness as needed. Hardcoded RGB values don't adapt, resulting in poor contrast in dark mode or washed-out colors in light mode. Semantic colors also respect accessibility settings like Increase Contrast.

**Reference:** [HIG - Color and Semantic Colors](https://developer.apple.com/design/human-interface-guidelines/color)

### Only Tint Primary Actions, Keep Secondary Un-tinted

Tinted glass should only be used for the primary call-to-action (CTA). Secondary actions and navigation elements should remain un-tinted to maintain visual hierarchy.

**Incorrect:**

```swift
// ❌ WRONG: Tinting multiple actions dilutes hierarchy
struct ActionSheet: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VStack(spacing: 20) {
                Button("Continue") {}
                    .glassEffect(.regular.tint(.blue))

                Button("Skip") {}
                    .glassEffect(.regular.tint(.green))  // ❌ Secondary tinted

                Button("Cancel") {}
                    .glassEffect(.regular.tint(.red))  // ❌ Too much tint
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Only primary action is tinted
struct ActionSheet: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VStack(spacing: 20) {
                Button("Continue") {}
                    .glassEffect(.regular.tint(.blue))  // ✅ Primary only

                Button("Skip") {}
                    .glassEffect(.regular)  // ✅ Un-tinted secondary

                Button("Cancel") {}
                    .glassEffect(.regular)  // ✅ Un-tinted secondary
            }
        }
    }
}
```

**Why it matters:** Tinting creates visual emphasis through color. When multiple elements are tinted, the hierarchy becomes unclear and users can't identify the primary action. Un-tinted glass provides sufficient affordance for secondary actions while keeping focus on the primary CTA.

**Reference:** [HIG - Glass Effect Tinting](https://developer.apple.com/design/human-interface-guidelines/liquid-glass#tinting)

### Add .interactive() for Touch-Responsive Elements

Apply `.interactive()` modifier to glass elements that respond to touch (buttons, controls) to provide elastic visual feedback that enhances perceived responsiveness.

**Incorrect:**

```swift
// ❌ WRONG: Button has no touch feedback
struct PlayButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Button {
                playVideo()
            } label: {
                Image(systemName: "play.fill")
            }
            .glassEffect(.regular)  // ❌ Missing interactive feedback
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Interactive glass responds to touch
struct PlayButton: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Button {
                playVideo()
            } label: {
                Image(systemName: "play.fill")
            }
            .glassEffect(.regular.interactive())  // ✅ Elastic touch response
        }
    }
}
```

**Why it matters:** The `.interactive()` modifier adds subtle elastic compression/expansion animations when the element is touched, providing immediate visual feedback that the button is responding. This improves perceived performance and makes the UI feel more responsive, especially important for glass buttons where the visual style is subtle.

**Reference:** [SwiftUI GlassEffect Interactive API](https://developer.apple.com/documentation/swiftui/glasseffect/interactive)

---

## Container & Multi-Element Management

### Use GlassEffectContainer for Multiple Glass Elements

When displaying multiple interactive elements that need glass, always use GlassEffectContainer with proper spacing to prevent visual artifacts and maintain optical clarity.

**Incorrect:**

```swift
// ❌ WRONG: Individual glass effects too close together
struct ActionBar: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            HStack(spacing: 8) {  // Too close!
                Button("Save").glassEffect()
                Button("Share").glassEffect()
                Button("Delete").glassEffect()
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: GlassEffectContainer with proper spacing
struct ActionBar: View {
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 40) {  // ✅ 40pt spacing
                Button("Save")
                    .glassEffectID("save", in: glassNamespace)

                Button("Share")
                    .glassEffectID("share", in: glassNamespace)

                Button("Delete")
                    .glassEffectID("delete", in: glassNamespace)
            }
            .glassEffect(.regular)
        }
    }
}
```

**Why it matters:** Glass effects need physical separation (min 20pt, recommended 40pt) to prevent optical interference. GlassEffectContainer manages this spacing automatically and renders all children within a single glass layer, avoiding stacking artifacts while maintaining visual separation.

**Reference:** [SwiftUI GlassEffectContainer API](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)

### Never Stack Glass on Glass (Causes Visual Artifacts)

Stacking multiple glass effects creates compounding optical distortion that produces visual artifacts, rendering glitches, and makes UI elements unreadable.

**Incorrect:**

```swift
// ❌ WRONG: Glass-on-glass stacking
struct ToolbarView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VStack {
                Button("Option 1").glassEffect()
                Button("Option 2").glassEffect()
                Button("Option 3").glassEffect()
            }
            .glassEffect()  // Triple-stacked glass causes artifacts
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Use GlassEffectContainer for multiple elements
struct ToolbarView: View {
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 40) {
                Button("Option 1")
                    .glassEffectID("btn1", in: glassNamespace)

                Button("Option 2")
                    .glassEffectID("btn2", in: glassNamespace)

                Button("Option 3")
                    .glassEffectID("btn3", in: glassNamespace)
            }
            .glassEffect()  // ✅ Single glass layer
        }
    }
}
```

**Why it matters:** Each glass layer adds optical distortion. Stacking them compounds the effect, causing visual artifacts like color fringing, blur halos, and rendering glitches that make UI unusable. GlassEffectContainer manages multiple elements within a single glass layer.

**Reference:** [WWDC 2025 Session 219 - Meet Liquid Glass](https://developer.apple.com/videos/wwdc2025/)

---

## Morphing & Animations

### Declare @Namespace for Glass Morphing

Always declare a `@Namespace` property when using glass morphing transitions. The namespace provides the coordination space for matching glass IDs across view states.

**Incorrect:**

```swift
// ❌ WRONG: No namespace for morphing IDs
struct MorphingView: View {
    @State private var isExpanded = false

    var body: some View {
        if #available(iOS 26.0, *) {
            if isExpanded {
                ExpandedView()
                    .glassEffectID("view", in: ???)  // ❌ No namespace declared
            } else {
                CompactView()
                    .glassEffectID("view", in: ???)  // ❌ Can't compile
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: @Namespace declared for coordination
struct MorphingView: View {
    @Namespace private var glassNamespace  // ✅ Namespace property
    @State private var isExpanded = false

    var body: some View {
        if #available(iOS 26.0, *) {
            if isExpanded {
                ExpandedView()
                    .glassEffectID("view", in: glassNamespace)
            } else {
                CompactView()
                    .glassEffectID("view", in: glassNamespace)
            }
        }
    }
}
```

**Why it matters:** The `@Namespace` creates a unique identifier space that SwiftUI uses to match views across state changes. Without it, `glassEffectID` cannot function. The namespace must be declared in the same view that contains both source and destination states - passing namespaces across view boundaries breaks the morphing system.

**Reference:** [SwiftUI Namespace API](https://developer.apple.com/documentation/swiftui/namespace)

### Use Same glassEffectID for Morphing Animations

When animating between two glass states, use the same `glassEffectID` in both views to trigger automatic morphing transitions. Different IDs result in fade transitions instead of fluid morphing.

**Incorrect:**

```swift
// ❌ WRONG: Different IDs cause fade instead of morph
struct CardView: View {
    @Namespace private var glassNamespace
    @State private var isExpanded = false

    var body: some View {
        if #available(iOS 26.0, *) {
            if isExpanded {
                ExpandedCard()
                    .glassEffectID("expanded", in: glassNamespace)  // ❌ Different ID
            } else {
                CompactCard()
                    .glassEffectID("compact", in: glassNamespace)  // ❌ Different ID
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Same ID enables morphing
struct CardView: View {
    @Namespace private var glassNamespace
    @State private var isExpanded = false

    var body: some View {
        if #available(iOS 26.0, *) {
            if isExpanded {
                ExpandedCard()
                    .glassEffectID("card", in: glassNamespace)  // ✅ Same ID
            } else {
                CompactCard()
                    .glassEffectID("card", in: glassNamespace)  // ✅ Same ID
            }
        }
    }
}
```

**Why it matters:** SwiftUI's glass morphing system uses the ID to match source and destination views. When IDs match, the system creates a fluid morphing animation that distorts the glass shape/size between states. Different IDs cause the system to treat them as unrelated views, resulting in a cross-fade transition that breaks the glass material illusion.

**Reference:** [WWDC 2025 Session 323 - Build with Liquid Glass](https://developer.apple.com/videos/wwdc2025/)

### Max 5 Concurrent Morphing Transitions

Limit concurrent glass morphing animations to 5 simultaneous transitions. More than this causes animation jank, frame drops, and poor user experience.

**Incorrect:**

```swift
// ❌ WRONG: 20 elements morphing simultaneously
struct DashboardGrid: View {
    @Namespace private var glassNamespace
    @State private var expandedIDs: Set<Int> = []

    var body: some View {
        if #available(iOS 26.0, *) {
            LazyVGrid(columns: columns) {
                ForEach(0..<20) { index in
                    WidgetCard(
                        isExpanded: expandedIDs.contains(index)
                    )
                    .glassEffectID("widget-\(index)", in: glassNamespace)
                    .onTapGesture {
                        // ❌ Can trigger 20 simultaneous morphs
                        withAnimation {
                            expandedIDs.toggle(index)
                        }
                    }
                }
            }
            .glassEffect()
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Limit to single expanded item (1 morph at a time)
struct DashboardGrid: View {
    @Namespace private var glassNamespace
    @State private var expandedID: Int? = nil

    var body: some View {
        if #available(iOS 26.0, *) {
            LazyVGrid(columns: columns) {
                ForEach(0..<20) { index in
                    WidgetCard(
                        isExpanded: expandedID == index
                    )
                    .glassEffectID("widget-\(index)", in: glassNamespace)
                    .onTapGesture {
                        withAnimation {
                            expandedID = expandedID == index ? nil : index
                        }  // ✅ Only 1 morph at a time
                    }
                }
            }
            .glassEffect()
        }
    }
}
```

**Why it matters:** Glass morphing requires real-time computation of interpolated optical distortion between source and destination shapes. Each morph is GPU-intensive. Running more than 5 concurrently exceeds available GPU bandwidth, causing animations to stutter or drop frames. Limiting to 1-2 simultaneous morphs provides the smoothest experience.

**Reference:** [WWDC 2025 Session 323 - Animation Performance](https://developer.apple.com/videos/wwdc2025/)

---

## Performance & Limits

### Maximum ~20 Glass Elements on Screen Simultaneously

Limit the number of simultaneous glass effects to approximately 20 on screen at any time. Exceeding this causes GPU overload, frame drops, and battery drain.

**Incorrect:**

```swift
// ❌ WRONG: 100 glass elements cause performance collapse
struct GalleryView: View {
    let items = Array(0..<100)

    var body: some View {
        if #available(iOS 26.0, *) {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(items, id: \.self) { item in
                        ThumbnailCard(item)
                            .glassEffect()  // ❌ 100 glass effects!
                    }
                }
            }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Glass only on visible navigation/chrome
struct GalleryView: View {
    let items = Array(0..<100)

    var body: some View {
        if #available(iOS 26.0, *) {
            NavigationStack {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(items, id: \.self) { item in
                            ThumbnailCard(item)  // ✅ No glass on content
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Gallery")
                            .glassEffect()  // ✅ Single glass element
                    }
                }
            }
        }
    }
}
```

**Why it matters:** Each glass effect requires GPU computation for real-time optical distortion and rendering. The GPU can efficiently handle ~20 effects while maintaining 120fps on ProMotion devices. Beyond this, frame rate drops below 60fps, device heats up, and battery drains rapidly. Glass is for navigation chrome, not repeated content.

**Reference:** [WWDC 2025 Session 219 - Performance Guidelines](https://developer.apple.com/videos/wwdc2025/)

---

## Accessibility

### Glass Auto-Respects Reduce Transparency and Increase Contrast

Glass effects automatically adapt to Reduce Transparency and Increase Contrast accessibility settings. Never override this behavior or implement custom fallbacks—the system handles it correctly.

**Incorrect:**

```swift
// ❌ WRONG: Manual fallback overrides automatic behavior
struct NavBar: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency

    var body: some View {
        if #available(iOS 26.0, *) {
            Text("App Name")
                .background {
                    if reduceTransparency {
                        Color.black.opacity(0.9)  // ❌ Manual override
                    } else {
                        Color.clear
                            .glassEffect()
                    }
                }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Glass auto-adapts, no manual handling needed
struct NavBar: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Text("App Name")
                .glassEffect()  // ✅ Auto-respects all a11y settings
        }
    }
}
```

**Why it matters:** When Reduce Transparency is enabled, glass automatically renders as a frostier, more opaque material with increased contrast. When Increase Contrast is enabled, glass is replaced with solid black/white backgrounds with borders. Manual fallbacks create inconsistent experiences and often have insufficient contrast, violating WCAG 2.1 AA standards. Trust the system's automatic adaptation.

**Reference:** [Accessibility and Glass Effects](https://developer.apple.com/documentation/swiftui/glasseffect/accessibility)

### Test With All Accessibility Settings Enabled

Always test glass UIs with Reduce Transparency, Increase Contrast, and Reduce Motion enabled. Glass must remain fully functional and readable in all accessibility modes.

**Incorrect:**

```swift
// ❌ WRONG: No accessibility testing, assuming defaults
struct MediaPlayer: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VideoPlayer(player)
                .overlay(alignment: .bottom) {
                    Controls()
                        .glassEffect(.clear)
                    // ❌ Did you test with Reduce Transparency?
                    // Controls might be invisible!
                }
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Tested with all settings, ensured visibility
struct MediaPlayer: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            VideoPlayer(player)
                .overlay(alignment: .bottom) {
                    Controls()
                        .glassEffect(.clear)
                        .accessibilityLabel("Playback controls")
                    // ✅ Tested:
                    // - Reduce Transparency: Controls become opaque ✓
                    // - Increase Contrast: Solid background + border ✓
                    // - Reduce Motion: No morphing animations ✓
                    // - VoiceOver: All controls reachable ✓
                }
        }
    }
}
```

**Why it matters:** Approximately 20% of iOS users have at least one accessibility setting enabled. Glass with `.clear` variant can become nearly invisible with Reduce Transparency off. Morphing animations can cause motion sickness if not disabled with Reduce Motion. Failing to test creates barriers for millions of users and violates App Store accessibility requirements.

**Test checklist:**
1. Settings → Accessibility → Display → Reduce Transparency: ON
2. Settings → Accessibility → Display → Increase Contrast: ON
3. Settings → Accessibility → Motion → Reduce Motion: ON
4. Enable VoiceOver and verify all elements are reachable

**Reference:** [Testing for Accessibility](https://developer.apple.com/documentation/accessibility/testing-for-accessibility)

### Ensure VoiceOver Labels Work With Glass Elements

Glass elements must have proper accessibility labels and hints. Visual glass effects don't automatically provide semantic meaning to screen readers.

**Incorrect:**

```swift
// ❌ WRONG: No accessibility labels
struct ToolBar: View {
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                Button {
                    share()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                    // ❌ VoiceOver reads: "Button"
                }
                .glassEffectID("share", in: glassNamespace)

                Button {
                    delete()
                } label: {
                    Image(systemName: "trash")
                    // ❌ VoiceOver reads: "Button"
                }
                .glassEffectID("delete", in: glassNamespace)
            }
            .glassEffect()
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Descriptive labels and hints
struct ToolBar: View {
    @Namespace private var glassNamespace

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                Button {
                    share()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .glassEffectID("share", in: glassNamespace)
                .accessibilityLabel("Share")  // ✅ Clear label
                .accessibilityHint("Opens share sheet")

                Button {
                    delete()
                } label: {
                    Image(systemName: "trash")
                }
                .glassEffectID("delete", in: glassNamespace)
                .accessibilityLabel("Delete")  // ✅ Clear label
                .accessibilityHint("Deletes this item")
            }
            .glassEffect()
        }
    }
}
```

**Why it matters:** Glass is a visual effect that doesn't convey semantic information to screen readers. Without proper labels, VoiceOver users only hear "Button" with no context about what the button does. This makes the UI unusable for blind and low-vision users. All interactive glass elements must have descriptive labels and optional hints explaining their action.

**Reference:** [Accessibility Labels and Hints](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)-4p4kv)

---

## UIKit Integration

### Use configureWithGlassEffect() for UIKit Navigation Bars

For UIKit navigation bars, use the `configureWithGlassEffect()` method on `UINavigationBarAppearance` instead of manually applying glass views. This ensures correct system integration.

**Incorrect:**

```swift
// ❌ WRONG: Manually adding glass view to navigation bar
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect()
            let effectView = UIVisualEffectView(effect: glassEffect)
            effectView.frame = navigationController?.navigationBar.bounds ?? .zero
            navigationController?.navigationBar.addSubview(effectView)
            // ❌ Breaks navigation bar layout, touch handling, and animations
        }
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Use appearance API
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 26.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithGlassEffect()  // ✅ System integration

            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
}
```

**Why it matters:** `configureWithGlassEffect()` properly integrates glass with the navigation bar's layout system, touch handling, and scroll edge behaviors. Manually adding glass views breaks system animations, interferes with navigation bar buttons, and doesn't adapt to scroll position. The appearance API is the correct integration point.

**Reference:** [UINavigationBarAppearance Glass Configuration](https://developer.apple.com/documentation/uikit/uinavigationbarappearance/configurewithglasseffect)

---

## Framework Interoperability

### Don't Wrap UIKit Glass in SwiftUI or Vice Versa

Never wrap a UIKit glass view in SwiftUI's `UIViewRepresentable`, or apply SwiftUI `.glassEffect()` to a `UIViewControllerRepresentable`. Use native glass APIs for each framework.

**Incorrect:**

```swift
// ❌ WRONG: Wrapping UIKit glass in SwiftUI
struct GlassView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect()
            return UIVisualEffectView(effect: glassEffect)
        } else {
            return UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        }
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        GlassView()
            .glassEffect()  // ❌ Double glass effect!
    }
}
```

**Correct:**

```swift
// ✅ CORRECT: Use native SwiftUI glass
struct ContentView: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            Text("Content")
                .glassEffect()  // ✅ Native SwiftUI glass
        }
    }
}

// ✅ CORRECT: Use native UIKit glass
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect()
            let effectView = UIVisualEffectView(effect: glassEffect)
            // Add to view hierarchy
        }
    }
}
```

**Why it matters:** Wrapping framework-specific glass implementations creates double-layering (glass-on-glass), breaks automatic accessibility adaptation, and causes rendering artifacts. Each framework has optimized glass implementations that work with their respective rendering engines. Mixing them prevents proper optimization and breaks system behaviors.

**Reference:** [SwiftUI and UIKit Interoperability](https://developer.apple.com/documentation/swiftui/uikit-integration)

---

## Quick Reference Summary

### Core Principles
- Glass is for navigation chrome, never content
- Use `.regular` variant by default
- Never stack glass on glass
- Limit to ~20 glass effects on screen
- Always wrap with `#available(iOS 26.0, *)`

### Variants
- `.regular` - Default for standard UI
- `.clear` - Only for rich media overlays
- `.identity` - Conditionally disable glass

### Modifiers
- `.interactive()` - Add to touchable elements
- `.tint()` - Only on primary actions
- Use semantic colors, never hardcoded RGB

### Multi-Element Patterns
- Use `GlassEffectContainer` with 40pt spacing
- Declare `@Namespace` for morphing
- Use same `glassEffectID` for morph transitions
- Limit to max 5 concurrent morphs

### Accessibility
- Glass auto-adapts to system settings
- Test with all accessibility modes enabled
- Add proper VoiceOver labels
- Never override automatic behavior

### Performance
- No glass in scrolling lists
- Max ~20 glass elements on screen
- Max 5 concurrent morphing animations
- GPU-intensive, use sparingly

### UIKit Integration
- Use `configureWithGlassEffect()` for nav bars
- Don't mix UIKit/SwiftUI glass implementations
- Use native APIs for each framework
