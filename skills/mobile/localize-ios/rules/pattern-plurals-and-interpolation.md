---
title: Use Format Strings for Interpolation; Never Concatenate Localizable Strings
impact: HIGH
tags: pattern, plural, interpolation, format-string, translation
---

## Use Format Strings for Interpolation; Never Concatenate Localizable Strings

String interpolation and concatenation break localization. Different languages need different word order and pluralization. Use format strings (`%d`, `%@`, `%s`) in `.xcstrings` and let Apple's pluralization engine handle one/few/many variants.

**Incorrect (string concatenation; breaks translation):**

```swift
import SwiftUI

struct ItemListView: View {
    let count: Int
    let name: String

    var body: some View {
        VStack {
            // ❌ Concatenated strings; translator cannot reorder words
            Text(String(localized: "You have ") + "\(count)" + String(localized: " items"))

            // ❌ String interpolation in localizable key
            Text(String(localized: "User name is \(name)"))

            // ❌ Plural-ish approach without proper plural rules
            let message = count == 1
                ? String(localized: "One item")
                : String(localized: "Multiple items") + " (\(count))"
            Text(message)
        }
    }
}
```

**Correct (format string with interpolation):**

```swift
import SwiftUI

struct ItemListView: View {
    let count: Int
    let name: String

    var body: some View {
        VStack {
            // ✅ Format string; translator can reorder
            Text(String(localized: "You have \(count) items", locale: .current))

            // ✅ Format string for name
            Text(String(localized: "User name is \(name)", locale: .current))
        }
    }
}
```

**Correct (.xcstrings with plural variations):**

In `.xcstrings`:
```json
{
  "strings": {
    "itemCount": {
      "extractionState": "manual",
      "comment": "Number of items in the list",
      "localizations": {
        "en": {
          "variations": {
            "plural": {
              "one": {
                "stringUnit": {
                  "state": "translated",
                  "value": "You have 1 item"
                }
              },
              "other": {
                "stringUnit": {
                  "state": "translated",
                  "value": "You have %d items"
                }
              }
            }
          }
        },
        "fr": {
          "variations": {
            "plural": {
              "one": {
                "stringUnit": {
                  "state": "translated",
                  "value": "Vous avez 1 objet"
                }
              },
              "other": {
                "stringUnit": {
                  "state": "translated",
                  "value": "Vous avez %d objets"
                }
              }
            }
          }
        }
      }
    }
  }
}
```

In Swift:
```swift
import SwiftUI

struct ItemListView: View {
    let count: Int

    var body: some View {
        // ✅ Plural rule applied automatically by String() and .xcstrings
        Text(String(localized: "itemCount \(count)", locale: .current))
    }
}
```

**Correct (named format arguments for clarity):**

```swift
import SwiftUI

struct ItemListView: View {
    let count: Int
    let userName: String

    var body: some View {
        VStack {
            // ✅ Format with named parameter
            let itemMessage = String(
                localized: "itemCountMessage \(count)",
                locale: .current
            )
            Text(itemMessage)

            // ✅ Named parameter for string interpolation
            let userMessage = String(
                localized: "User name is %@",
                arguments: [userName]
            )
            Text(userMessage)
        }
    }
}
```

**Correct (uikit example with NSLocalizedString):**

```swift
import UIKit

class ItemViewController: UIViewController {
    let itemCount: Int
    let userName: String

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ NSLocalizedString with format string
        let itemLabel = UILabel()
        itemLabel.text = String(
            format: NSLocalizedString("You have %d items", comment: "Item count"),
            itemCount
        )

        // ✅ String(localized:) with interpolation
        let userLabel = UILabel()
        userLabel.text = String(localized: "User name is \(userName)")
    }
}
```

**Why it matters**

- **Word order varies by language** — English: "You have 5 items". Spanish: "Tienes 5 artículos". Concatenation forces English word order.
- **Pluralization rules differ** — English: one/other. Russian: one/few/many. Plural handling in `.xcstrings` respects language-specific rules; manual if-else is unreliable.
- **Translator context** — Format strings with placeholder text (`%d`, `%@`) let translators see where values are inserted; concatenation hides this.
- **Code maintainability** — Format strings are easier to refactor; concatenated strings scatter localization keys across the codebase.

Always use format strings (`%d`, `%@`) in `.xcstrings` keys. Avoid concatenating `String(localized:)` calls. Use `.xcstrings` plural variations (`one`/`other`) to handle language-specific pluralization rules automatically.
