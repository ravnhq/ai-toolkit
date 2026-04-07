---
title: Always Localize Accessibility Labels and Descriptions
impact: HIGH
tags: accessibility, a11y, voiceover, labels, semantics
---

## Always Localize Accessibility Labels and Descriptions

Accessibility labels (`.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`) are read aloud by VoiceOver. If not localized, users in non-English locales hear English text. Include all a11y strings in `.xcstrings` with context for translators.

**Incorrect (accessibility labels not localized):**

```swift
import SwiftUI

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .accessibilityLabel("Favorite")  // ❌ English only; VoiceOver reads in English even on French device

            Text(item.title)
            Text(item.description)

            Button(action: { /* delete */ }) {
                Image(systemName: "trash.fill")
            }
            .accessibilityLabel("Delete this item")  // ❌ Not localized
            .accessibilityHint("Tap to permanently remove the item")  // ❌ Not localized
        }
    }
}
```

**Correct (a11y labels in .xcstrings):**

In `.xcstrings`:
```json
{
  "strings": {
    "favoriteLabel": {
      "extractionState": "manual",
      "comment": "VoiceOver label for favorite star icon",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Favorite"
          }
        },
        "fr": {
          "stringUnit": {
            "state": "translated",
            "value": "Favori"
          }
        },
        "es": {
          "stringUnit": {
            "state": "translated",
            "value": "Favorito"
          }
        }
      }
    },
    "deleteItemLabel": {
      "extractionState": "manual",
      "comment": "VoiceOver label for delete button",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Delete this item"
          }
        }
      }
    },
    "deleteItemHint": {
      "extractionState": "manual",
      "comment": "VoiceOver hint describing delete action",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Tap to permanently remove the item"
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

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .accessibilityLabel(Text("favoriteLabel"))  // ✅ Localized from .xcstrings

            Text(item.title)
            Text(item.description)

            Button(action: { /* delete */ }) {
                Image(systemName: "trash.fill")
            }
            .accessibilityLabel(Text("deleteItemLabel"))  // ✅ Localized
            .accessibilityHint(Text("deleteItemHint"))  // ✅ Localized
        }
    }
}
```

**Correct (contextual a11y labels):**

```swift
import SwiftUI

struct RatingControl: View {
    @State var rating: Int = 0

    var body: some View {
        HStack {
            ForEach(1...5, id: \.self) { index in
                Button(action: { rating = index }) {
                    Image(systemName: rating >= index ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .accessibilityLabel(Text("ratingLabel \(index)"))  // ✅ Contextual
                        .accessibilityValue(Text("ratingValue \(rating)/5"))  // ✅ Current value
                }
            }
        }
    }
}
```

In `.xcstrings`:
```json
{
  "strings": {
    "ratingLabel": {
      "comment": "VoiceOver label for individual star in rating control",
      "localizations": {
        "en": {
          "stringUnit": {
            "value": "Star %d"
          }
        },
        "fr": {
          "stringUnit": {
            "value": "Étoile %d"
          }
        }
      }
    },
    "ratingValue": {
      "comment": "VoiceOver value for current rating",
      "localizations": {
        "en": {
          "stringUnit": {
            "value": "%d out of 5 stars"
          }
        }
      }
    }
  }
}
```

**Correct (screen identifiers):**

```swift
import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        VStack {
            Text("User Profile")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("profileScreenLabel"))  // ✅ Screen identifier for VoiceOver
    }
}
```

**Why it matters**

- **International accessibility** — VoiceOver users outside English-speaking countries rely on native-language a11y text. Untranslated labels force them to use unfamiliar terms.
- **Legal compliance** — WCAG 2.1 and Apple's accessibility guidelines require accessible content to be localized when the app is localized.
- **Translator guidance** — Include a `comment` in `.xcstrings` for each a11y string explaining the UI context (e.g., "VoiceOver label for favorite star icon") so translators understand where and how the text is used.

Always include `.accessibilityLabel`, `.accessibilityHint`, and `.accessibilityValue` strings in `.xcstrings`. Test with VoiceOver on devices set to other languages (Settings → Accessibility → VoiceOver; then Settings → General → Language) to confirm translations are active.
