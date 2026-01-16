# Liquid Glass Patterns Catalog

Production-ready implementations for common UI patterns.

---

## Navigation Patterns

### Bottom Tab Bar Replacement

```swift
struct GlassTabBar: View {
    @Binding var selection: Tab
    @Namespace private var animation

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selection == tab,
                        namespace: animation
                    ) {
                        withAnimation(.bouncy) {
                            selection = tab
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}

struct TabButton: View {
    let tab: Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title3)
                Text(tab.title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
        .glassEffect(isSelected ? .regular.interactive() : .identity)
        .glassEffectID(tab.rawValue, in: namespace)
    }
}
```

### Floating Toolbar

```swift
struct FloatingToolbar: View {
    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 12) {
                ToolbarItem(icon: "pencil", action: {})
                ToolbarItem(icon: "eraser", action: {})

                Divider()
                    .frame(height: 24)

                ToolbarItem(icon: "arrow.uturn.backward", action: {})
                ToolbarItem(icon: "arrow.uturn.forward", action: {})
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct ToolbarItem: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 44, height: 44)
        }
        .glassEffect(.regular.interactive())
    }
}
```

---

## Control Patterns

### Segmented Picker

```swift
struct GlassSegmentedPicker<T: Hashable & CaseIterable & CustomStringConvertible>: View {
    @Binding var selection: T
    @Namespace private var animation

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        withAnimation(.bouncy) {
                            selection = option
                        }
                    } label: {
                        Text(option.description)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .foregroundStyle(selection == option ? .primary : .secondary)
                    .glassEffect(selection == option ? .regular : .identity)
                    .glassEffectID("\(option)", in: animation)
                }
            }
        }
    }
}
```

### Toggle Button Group

```swift
struct GlassToggleGroup: View {
    @State private var selectedOptions: Set<String> = []
    let options: [String]

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selectedOptions.contains(option)
                    Button {
                        withAnimation(.bouncy) {
                            if isSelected {
                                selectedOptions.remove(option)
                            } else {
                                selectedOptions.insert(option)
                            }
                        }
                    } label: {
                        Text(option)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .glassEffect(isSelected ? .regular.tint(.blue) : .regular)
                }
            }
        }
    }
}
```

---

## Action Patterns

### Floating Action Button (FAB)

```swift
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        GlassEffectContainer {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)
            .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}

// Usage
FloatingActionButton(icon: "plus") {
    // Create action
}
```

### Expandable FAB

```swift
struct ExpandableFAB: View {
    @State private var isExpanded = false
    @Namespace private var animation

    let primaryIcon: String
    let actions: [(icon: String, action: () -> Void)]

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 12) {
                if isExpanded {
                    ForEach(actions.indices, id: \.self) { index in
                        Button(action: actions[index].action) {
                            Image(systemName: actions[index].icon)
                                .font(.title3)
                        }
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                        .glassEffectID("action-\(index)", in: animation)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Button {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : primaryIcon)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(width: 56, height: 56)
                .glassEffect(.regular.interactive(), in: .circle)
                .glassEffectID("primary", in: animation)
            }
        }
    }
}
```

---

## Card Patterns

### Morphing Card

```swift
struct MorphingCard: View {
    @State private var isExpanded = false
    @Namespace private var animation

    var body: some View {
        GlassEffectContainer {
            if isExpanded {
                ExpandedCardContent(
                    namespace: animation,
                    onCollapse: {
                        withAnimation(.bouncy) { isExpanded = false }
                    }
                )
            } else {
                CollapsedCardContent(
                    namespace: animation,
                    onExpand: {
                        withAnimation(.bouncy) { isExpanded = true }
                    }
                )
            }
        }
    }
}

struct CollapsedCardContent: View {
    let namespace: Namespace.ID
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            HStack {
                Image(systemName: "photo")
                    .glassEffectID("icon", in: namespace)
                Text("View Details")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
        }
        .glassEffect()
        .glassEffectID("card", in: namespace)
    }
}

struct ExpandedCardContent: View {
    let namespace: Namespace.ID
    let onCollapse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .glassEffectID("icon", in: namespace)
                Spacer()
                Button(action: onCollapse) {
                    Image(systemName: "xmark")
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }

            Text("Detailed content here...")
                .padding(.vertical)
        }
        .padding()
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .glassEffectID("card", in: namespace)
    }
}
```

---

## Media Overlay Patterns

### Video Controls

```swift
struct VideoControlsOverlay: View {
    @Binding var isPlaying: Bool
    @Binding var showControls: Bool

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 24) {
                Button { /* rewind */ } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                .glassEffect(.clear.interactive())  // .clear for media overlay

                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                .frame(width: 64, height: 64)
                .glassEffect(.clear.interactive(), in: .circle)

                Button { /* forward */ } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
                .glassEffect(.clear.interactive())
            }
            .padding()
        }
        .opacity(showControls ? 1 : 0)
    }
}
```

---

## Platform-Adaptive Patterns

### Cross-Platform Toolbar

```swift
struct AdaptiveToolbar: View {
    var body: some View {
        GlassEffectContainer {
            HStack(spacing: platformSpacing) {
                ForEach(actions) { action in
                    Button(action: action.perform) {
                        Label(action.title, systemImage: action.icon)
                            .labelStyle(platformLabelStyle)
                    }
                    .glassEffect(.regular.interactive(), in: platformShape)
                }
            }
            .padding(platformPadding)
        }
    }

    private var platformShape: some Shape {
        #if os(iOS)
        .capsule
        #else
        RoundedRectangle(cornerRadius: 6)
        #endif
    }

    private var platformSpacing: CGFloat {
        #if os(iOS)
        12
        #else
        8
        #endif
    }

    private var platformPadding: CGFloat {
        #if os(iOS)
        16
        #else
        12
        #endif
    }

    private var platformLabelStyle: some LabelStyle {
        #if os(iOS)
        .iconOnly
        #else
        .titleAndIcon
        #endif
    }
}
```

---

## State Management Pattern

### View Model for Glass UI

```swift
@Observable
class GlassUIState {
    var activeSection: Section = .home
    var expandedItems: Set<String> = []
    var isToolbarVisible = true

    func toggleItem(_ id: String) {
        if expandedItems.contains(id) {
            expandedItems.remove(id)
        } else {
            expandedItems.insert(id)
        }
    }

    func isExpanded(_ id: String) -> Bool {
        expandedItems.contains(id)
    }
}

// Usage with animation
struct ContentView: View {
    @State private var uiState = GlassUIState()
    @Namespace private var animation

    var body: some View {
        GlassEffectContainer {
            ForEach(items) { item in
                ItemRow(
                    item: item,
                    isExpanded: uiState.isExpanded(item.id),
                    namespace: animation
                ) {
                    withAnimation(.bouncy) {
                        uiState.toggleItem(item.id)
                    }
                }
            }
        }
    }
}
```
