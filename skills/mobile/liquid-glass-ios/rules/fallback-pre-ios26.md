---
title: Check iOS Version Before Using GlassEffect; Provide Pre-26 Fallback
impact: HIGH
tags: fallback, availability, ios-version, backwards-compatibility
---

## Check iOS Version Before Using GlassEffect; Provide Pre-26 Fallback

glassEffect requires iOS 26+. If the app supports iOS 24 or 25, use `@available(iOS 26, *)` or `if #available()` to check at runtime and provide solid background fallback for older versions.

**Incorrect (unconditional glassEffect on iOS 24+ target):**

```swift
struct NavigationBar: View {
    var body: some View {
        HStack {
            Text("My App")
                .font(.headline)
            Spacer()
            Image(systemName: "gearshape.fill")
        }
        .padding()
        .background(Material.glass)  // ❌ Crashes or renders incorrectly on iOS 24-25
    }
}
```

**Incorrect (runtime glassEffect without fallback):**

```swift
struct GlassButton: View {
    var body: some View {
        Button(action: {}) {
            Text("Filter")
        }
        .padding()
        .background(
            #if os(iOS)
            Material.glass
            #else
            Color.blue
            #endif
        )  // ❌ Uses compile-time check; no runtime fallback for iOS 24-25
    }
}
```

**Correct (runtime availability check with solid fallback):**

```swift
struct NavigationBar: View {
    var body: some View {
        HStack {
            Text("My App")
                .font(.headline)
            Spacer()
            Image(systemName: "gearshape.fill")
        }
        .padding()
        .background(
            Group {
                if #available(iOS 26, *) {
                    Material.glass  // ✅ iOS 26+ gets glass
                } else {
                    Color(UIColor.systemGray6)  // ✅ iOS 24-25 get solid color
                }
            }
        )
    }
}
```

**Or (availability attribute on view):**

```swift
@available(iOS 26, *)
struct GlassNavBar: View {
    var body: some View {
        HStack {
            Text("My App")
                .font(.headline)
            Spacer()
            Image(systemName: "gearshape.fill")
        }
        .padding()
        .background(Material.glass)
    }
}

struct PreiOS26NavBar: View {
    var body: some View {
        HStack {
            Text("My App")
                .font(.headline)
            Spacer()
            Image(systemName: "gearshape.fill")
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }
}

struct NavigationBar: View {
    var body: some View {
        if #available(iOS 26, *) {
            GlassNavBar()
        } else {
            PreiOS26NavBar()
        }
    }
}
```

**Correct (helper function for reuse):**

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            HStack {
                Text("Title")
                    .font(.headline)
            }
            .padding()
            .background(adaptiveGlassOrSolid())  // ✅ Reusable fallback

            List {
                ForEach(items) { item in
                    Text(item.name)
                        .padding()
                        .background(adaptiveGlassOrSolid())
                }
            }
        }
    }

    @ViewBuilder
    func adaptiveGlassOrSolid() -> some View {
        if #available(iOS 26, *) {
            Material.glass
        } else {
            Color(UIColor.systemGray6)
        }
    }
}
```

**Why it matters**

- **Crashes or undefined behavior** on iOS 24-25 when `Material.glass` is applied without availability check.
- **Graceful degradation** ensures users on older iOS versions see a functioning UI (solid background) instead of a broken one.
- **App Store guideline compliance** — apps targeting iOS 24+ must handle older OS versions; otherwise they may be rejected.

Always wrap glassEffect uses in `if #available(iOS 26, *)` and provide a solid color fallback. Test on iOS 24 and 25 simulators to confirm the fallback renders correctly.
