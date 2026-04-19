---
title: Limit Simultaneous Glass Layers to Maintain 60 FPS
impact: HIGH
tags: performance, glass, rendering, frame-rate, optimization
---

## Limit Simultaneous Glass Layers to Maintain 60 FPS

Glass effects incur significant GPU cost (blur + tint compositing). Rendering more than 2–3 glass layers simultaneously on screen often causes frame rate drops. Profile with Instruments (Core Animation tool) and optimize layer count.

**Incorrect (too many simultaneous glass layers):**

```swift
struct ListWithGlassEverywhere: View {
    var items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                        .padding()
                        .background(Material.glass)  // ❌ Glass on every title

                    Text(item.description)
                        .font(.body)
                        .padding()
                        .background(Material.glass)  // ❌ Glass on every description

                    HStack {
                        Button("Like") { }
                            .padding()
                            .background(Material.glass)  // ❌ Glass on every button

                        Button("Share") { }
                            .padding()
                            .background(Material.glass)  // ❌ Glass on every button
                    }
                }
                .background(Material.glass)  // ❌ Glass on every row container
            }
        }
    }
}
```
Result: Scrolling drops to 30–40 FPS on older devices.

**Correct (glass on focal elements only):**

```swift
struct ListWithOptimizedGlass: View {
    var items: [Item]

    var body: some View {
        List {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 12) {
                    // Title without glass — solid background
                    Text(item.title)
                        .font(.headline)
                        .padding()
                        .background(Color(UIColor.systemGray6))  // ✅ Solid color

                    // Description without glass
                    Text(item.description)
                        .font(.body)
                        .padding()
                        .background(Color(UIColor.systemGray5))  // ✅ Solid color

                    // Action buttons — glass only on primary action
                    HStack {
                        Button("Like") { }
                            .padding()
                            .background(Color(UIColor.systemGray5))  // ✅ Solid secondary

                        Button("Share") { }
                            .padding()
                            .background(Material.glass)  // ✅ Glass on focal action
                    }
                }
                .padding()
                .background(Color.white)  // ✅ Solid row background
            }
        }
    }
}
```
Result: Smooth 60 FPS scrolling; glass used sparingly on focal "Share" button.

**Correct (rasterize static glass containers):**

```swift
struct StaticGlassContainer: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Filter Options")
                .font(.headline)
            FilterControls()
            ApplyButton()
        }
        .padding()
        .background(Material.glass)  // ✅ Single glass layer
        .cornerRadius(12)
        .rasterizationScale(.fixed(1.0))  // ✅ Cache as bitmap; reduces per-frame cost
        .drawingGroup()  // Alternative: groups and flattens rendering
    }
}
```

**Or (profile and measure):**

```swift
struct PerformanceOptimizedView: View {
    @State var showInstruments = false

    var body: some View {
        ZStack {
            // Base content
            ScrollView {
                LazyVStack {
                    ForEach(0..<100) { index in
                        Text("Item \(index)")
                            .padding()
                            .background(Color(UIColor.systemGray6))
                    }
                }
            }

            // Floating glass action — 1 layer only
            VStack {
                Spacer()
                Button(action: { showInstruments.toggle() }) {
                    Image(systemName: "speedometer")
                        .foregroundColor(.white)
                }
                .padding()
                .glassEffect(material: .regular)
            }
        }
    }
}
```

**Profile steps:**
1. Open Xcode → Debug → Simulators → Window → Device.
2. Open Instruments (Cmd+I) → select "Core Animation".
3. Enable "Color Blended Layers" in rendering options.
4. Scroll through your glass-heavy view; watch frame counter at top.
5. If FPS < 55, reduce glass layer count or rasterize static containers.

**Why it matters**

- **GPU overhead** — blur compositing for each glass layer consumes significant GPU bandwidth.
- **Battery drain** — sustained high GPU usage reduces battery life, especially on older devices (iPhone 11–13).
- **User experience** — jank (frame drops) during scrolling makes the app feel unpolished and slow.

Limit simultaneous glass layers to 2–3 on screen. Use solid backgrounds for secondary elements. Rasterize static glass containers to cache them as bitmaps. Profile with Instruments and adjust until sustained 60 FPS is achieved.
