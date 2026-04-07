---
title: Use LocalizedStringKey in SwiftUI; String(localized:) for UIKit
impact: CRITICAL
tags: api, localization, swiftui, uikit, string-type
---

## Use LocalizedStringKey in SwiftUI; String(localized:) for UIKit

SwiftUI's `Text` and `Label` accept `LocalizedStringKey` directly; use this when possible for cleaner code. UIKit and non-view code use `String(localized:)`. Never mix APIs in the same project; pick one strategy and apply it consistently.

**Incorrect (mixing LocalizedStringKey and String(localized:) randomly):**

```swift
import SwiftUI

struct ContentView: View {
    let title = String(localized: "contentTitle")  // ❌ String(localized:) in SwiftUI

    var body: some View {
        VStack {
            Text(LocalizedStringKey("contentHeading"))  // ❌ Inconsistent API choice

            HStack {
                Text("actionButton")  // ❌ Not localized at all
                Button(action: {}) {
                    Text(LocalizedStringKey("submit"))  // ❌ Mixed patterns
                }
            }
        }
    }
}
```

**Correct (LocalizedStringKey for SwiftUI views):**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("contentTitle")  // ✅ SwiftUI Text accepts LocalizedStringKey implicitly

            HStack {
                Text("actionButton")  // ✅ Implicit LocalizedStringKey

                Button(action: {}) {
                    Text("submit")  // ✅ Implicit LocalizedStringKey
                }
            }
        }
    }
}
```

**Or (explicit LocalizedStringKey when needed):**

```swift
struct ContentView: View {
    @State var message: LocalizedStringKey = "greeting"  // ✅ Explicit LocalizedStringKey property

    var body: some View {
        VStack {
            Text(message)  // ✅ Consistent with property type

            Button(action: { message = "farewell" }) {
                Text("switchMessage")
            }
        }
    }
}
```

**Correct (String(localized:) for UIKit and non-view code):**

```swift
import UIKit

class HomeViewController: UIViewController {
    let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ String(localized:) for UIKit labels
        titleLabel.text = String(localized: "homeTitle")

        // ✅ String(localized:) in view model
        let viewModel = HomeViewModel(
            title: String(localized: "vmTitle"),
            message: String(localized: "vmMessage")
        )
    }
}

class HomeViewModel {
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}
```

**Correct (xcstrings-tool typed API if installed):**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text(.localizable.contentTitle)  // ✅ Typed accessor; requires xcstrings-tool plugin

            Button(action: {}) {
                Text(.localizable.submit)  // ✅ Compile-time type safety
            }
        }
    }
}
```

**Correct (ViewModel that returns localized strings):**

```swift
class ItemViewModel {
    var displayTitle: String {
        return String(localized: "itemTitle")  // ✅ String(localized:) in non-view logic
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale.current
        return formatter.string(from: date)  // ✅ Auto-localized by DateFormatter
    }
}

struct ItemView: View {
    let viewModel: ItemViewModel

    var body: some View {
        VStack {
            Text(viewModel.displayTitle)  // ✅ String → Text accepts String directly
            Text(viewModel.formattedDate(Date()))
        }
    }
}
```

**Why it matters**

- **LocalizedStringKey** — Designed for SwiftUI views; SwiftUI's `Text`, `Label`, and `Picker` have special handling for LocalizedStringKey that enables previews to switch language on the fly.
- **String(localized:)** — Works everywhere (SwiftUI, UIKit, non-view code); returns a String type; explicitly localized at that point.
- **Consistency** — Mixing both APIs in the same file confuses translators and makes key extraction unreliable.
- **xcstrings-tool typed API** — `.localizable.keyName` provides compile-time safety; typos in key names are caught immediately. Only available when xcstrings-tool plugin is installed.

Choose one API per project:
- **SwiftUI-only** → prefer `LocalizedStringKey` (implicit or explicit).
- **UIKit or mixed** → use `String(localized:)` everywhere for consistency.
- **Typed API available** → use `.localizable.keyName` if xcstrings-tool is installed.

Test that key extraction and code generation work correctly before committing.
