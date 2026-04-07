---
title: Use Glass Effect for Visual Hierarchy, Not Every Surface
impact: CRITICAL
tags: glass, swiftui, layer-placement, background
---

## Use Glass Effect for Visual Hierarchy, Not Every Surface

The glassEffect modifier creates frosted glass layers with blur and tint. Use it to establish visual hierarchy (navigation, overlay, emphasis); do not apply it to every background or container to avoid visual noise and performance overhead.

**Incorrect (glass effect on all surfaces):**

```swift
VStack {
    Text("Header")
        .padding()
        .background(Material.glass)  // ❌ Unnecessary; not a focal element

    List {
        ForEach(items) { item in
            NavigationLink(destination: ItemDetail(item)) {
                HStack {
                    Image(systemName: "star.fill")
                    Text(item.name)
                }
                .padding()
                .background(Material.glass)  // ❌ List row does not need glass
            }
        }
    }
    .background(Material.glass)  // ❌ Over-applied; clutters UI
}
```

**Correct (glass for focal overlays and navigation):**

```swift
struct ContentView: View {
    @State var showFilters = false

    var body: some View {
        ZStack {
            // Base content — solid background
            List(items) { item in
                NavigationLink(destination: ItemDetail(item)) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text(item.name)
                    }
                }
            }
            .background(Color.background)

            // Floating action button with glass — focal element
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .glassEffect(material: .regular)  // ✅ Focal point; glass justified
                }
                .padding()
            }

            // Filter overlay with glass — transient UI
            if showFilters {
                VStack(alignment: .leading) {
                    Text("Filters")
                        .font(.headline)
                    Divider()
                    FilterOptions()
                }
                .padding()
                .background(Material.glass)  // ✅ Overlay pattern; glass appropriate
                .cornerRadius(12)
                .padding()
            }
        }
    }
}
```

**Or (glass for navigation bars and system chrome):**

```swift
struct NavigationStack: View {
    var body: some View {
        NavigationView {
            List(items) { item in
                Text(item.title)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Menu") { /* action */ }
                }
            }
            .navigationBarBackground {
                Color.background
                    .glassEffect(material: .thick)  // ✅ Navigation bar; glass standard
            }
        }
    }
}
```

**Why it matters**

Glass effects demand GPU resources for blur and tint compositing. Applying glassEffect indiscriminately causes:
- **Frame rate drops** when scrolling or animating.
- **Visual clutter** if not used with intention.
- **Battery drain** from sustained blur rendering.

Reserve glass for focal overlays, navigation chrome, and transient UI (modals, popovers, floating controls) where the visual emphasis and interactivity justify the cost. Keep base content (lists, text, backgrounds) with solid colors or simple gradients.
