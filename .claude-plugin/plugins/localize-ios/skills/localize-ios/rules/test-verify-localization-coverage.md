---
title: Verify All Keys Are Translated; Test on Real Devices in Target Language
impact: MEDIUM
tags: test, testing, verification, coverage, device-testing
---

## Verify All Keys Are Translated; Test on Real Devices in Target Language

After adding strings to `.xcstrings`, test on real devices with the language set to each target locale. Verify no keys are missing, pseudo-localization catches expansion issues, and RTL rendering is correct.

**Incorrect (no testing; assumes all keys are localized):**

```swift
// Developer adds new key "settingsTitle" to .xcstrings in English only
// Releases app to Spanish/French markets without testing

struct SettingsView: View {
    var body: some View {
        Text("settingsTitle")  // ❌ Will fall back to English or show raw key on non-English device
    }
}
```

**Correct (verify translation coverage before release):**

**Step 1: In Xcode, open .xcstrings and check each key:**

```json
{
  "strings": {
    "settingsTitle": {
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Settings"
          }
        },
        "es": {
          "stringUnit": {
            "state": "translated",  // ✅ Marked as translated
            "value": "Configuración"
          }
        },
        "fr": {
          "stringUnit": {
            "state": "translated",  // ✅ Marked as translated
            "value": "Paramètres"
          }
        }
      }
    }
  }
}
```

**Step 2: Test on device — change System Language:**

1. iOS device: Settings → General → Language & Region → Change to Spanish (Español).
2. Return to app; verify "settingsTitle" renders as "Configuración" (not raw key or English).
3. Repeat for each target locale (Spanish, French, German, etc.).

**Step 3: Check Xcode build log for missing translations:**

```bash
# After building with `Product → Build`, check Xcode console:
# ⚠️ "settingsTitle" has no localization for locale "es"
```

If warnings appear, add translations before release.

**Correct (pseudo-localization for text expansion testing):**

In Xcode scheme:
1. Edit scheme → Run → App Language → select "Pseudo-Right-to-Left" or "Pseudo-Localization".
2. Build and run in simulator.
3. Verify:
   - No text is clipped or overflowed.
   - Layout remains usable with 20–30% longer strings.
   - Buttons and input fields accommodate expansion.

Example:
```swift
// English: "Save" (4 chars) → Pseudo: "Spåvé" (5 chars, with accents for testing)
// English: "Settings" (8 chars) → Pseudo: "Spéttïngès" (10+ chars)

// If UI is designed for exact "Save" width, pseudo-locale test will reveal overflow.
```

**Correct (automated key coverage check):**

```bash
#!/bin/bash
# Script to verify all keys in .xcstrings have all target languages

XCSTRINGS_FILE="Resources/Localization/Localizable.xcstrings"
TARGET_LANGUAGES=("en" "es" "fr" "de")

# Count localizations per key
jq '.strings[] | .localizations | keys' "$XCSTRINGS_FILE" | sort | uniq -c

# Expected output: Every key should have entries for all target languages
#      1 "de"
#      1 "en"
#      1 "es"
#      1 "fr"

# If output shows missing languages, add them before release.
```

**Correct (test translations in code preview):**

```swift
import SwiftUI

#Preview("English") {
    SettingsView()
        .environment(\.locale, Locale(identifier: "en"))  // ❌ Preview doesn't change system language
}

#Preview("Spanish - Manual") {
    // To test translated strings in preview, you must change device language
    // Preview environment locale does NOT affect String(localized:)
    SettingsView()
}
```

To actually test translations in Xcode Preview:
- Change Simulator language: Settings → General → Language & Region → Spanish.
- Canvas will auto-refresh and display Spanish translations.

**Correct (CI/CD check for translation keys):**

```bash
# GitHub Actions example: fail build if any key lacks a translation

name: Localization Check
on: [push, pull_request]

jobs:
  check-translations:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Verify .xcstrings coverage
        run: |
          # Exit 1 if any key has fewer than 3 localizations (en, es, fr)
          jq '.strings[] | select(.localizations | keys | length < 3)' \
            Resources/Localization/Localizable.xcstrings && exit 1 || exit 0
```

**Why it matters**

- **Incomplete translations** — Missing translations for a language cause the app to fall back to English, confusing users in that market.
- **Text expansion** — Translated strings often expand 20–35% longer. Fixed-width UI designed for English will break.
- **RTL rendering** — Arabic and Hebrew devices require layout mirroring; only testable on real RTL device/simulator.
- **Release blocking** — Shipping with untranslated keys is considered a localization bug and can result in app review rejection.

Always:
1. Verify all keys are marked `state: "translated"` in `.xcstrings` before release.
2. Test on real devices with target languages enabled (Settings → General → Language).
3. Use pseudo-localization to catch expansion/layout issues.
4. Automate coverage checks in CI/CD to prevent incomplete translations from being merged.
