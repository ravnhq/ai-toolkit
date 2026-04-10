---
title: Always Use .xcstrings Over Legacy .strings Files
impact: CRITICAL
tags: catalog, xcstrings, localization, string-catalog
---

## Always Use .xcstrings Over Legacy .strings Files

String Catalogs (`.xcstrings`, Xcode 15+) are Apple's official replacement for legacy `.strings` files. They provide compile-time key safety, automatic pluralization, and single-source-of-truth for all languages. Never create new `.strings` files; migrate legacy projects to `.xcstrings` immediately.

**Incorrect (using legacy .strings file):**

```
# Localizable.strings (legacy)
"homeTitle" = "Welcome Home";
"itemCount" = "You have %d items";
```

Problems:
- No compile-time safety; typos in keys are caught at runtime.
- Pluralization handled manually with numbered keys (`itemCount_one`, `itemCount_many`).
- Each language needs a separate `.strings` file; impossible to see all translations at a glance.
- No editor UI in Xcode; translations are raw key-value pairs.

**Correct (using .xcstrings String Catalog, Xcode 15+):**

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "homeTitle" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Welcome Home"
          }
        },
        "es" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Bienvenido a Casa"
          }
        }
      }
    },
    "itemCount" : {
      "extractionState" : "manual",
      "localizations" : {
        "en" : {
          "variations" : {
            "plural" : {
              "one" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "You have 1 item"
                }
              },
              "other" : {
                "stringUnit" : {
                  "state" : "translated",
                  "value" : "You have %d items"
                }
              }
            }
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

Benefits:
- ✅ Compile-time key safety via xcstrings-tool plugin.
- ✅ Built-in pluralization with `variations.plural.one/other`.
- ✅ All languages in one file; easy to audit translation coverage.
- ✅ Xcode UI editor for translations; drag-and-drop, mark as reviewed.
- ✅ Device-language filtering in Xcode previews.

**Correct (migrate legacy .strings to .xcstrings):**

If the project has legacy `.strings` files:

1. Create `Localizable.xcstrings` (see `references/xcstrings-format.md`).
2. Open in Xcode's String Catalog editor (right-click → Open As → Xcode String Catalog).
3. Add keys and translations from legacy `.strings` files into the new `.xcstrings`.
4. Delete old `.strings` files from Xcode (remove references from `project.pbxproj`).
5. Run `swift build` or `Cmd+B` in Xcode to verify xcstrings-tool generates typed accessors.

**Correct (check Xcode version and availability):**

```swift
// Xcode 15+ (iOS 15+)
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(String(localized: "homeTitle"))  // ✅ .xcstrings API
    }
}
```

**Why it matters**

- **Runtime safety** — Typos in legacy `.strings` keys fail silently; xcstrings catches them at compile time.
- **Pluralization** — Manual plural handling in `.strings` is error-prone. String Catalogs handle pluralization rules per language (English: one/other; Russian: one/few/other; etc.).
- **Translator experience** — Legacy files are flat text; String Catalogs UI in Xcode lets translators mark strings as reviewed, add notes, and track progress.
- **Apple official** — String Catalogs are the recommended format for iOS 15+. Apple is actively improving the UI and format; legacy `.strings` will eventually be deprecated.

Always create new projects with `.xcstrings`. Migrate existing projects from `.strings` to `.xcstrings` as a first localization pass. Never mix both formats in a single project.
