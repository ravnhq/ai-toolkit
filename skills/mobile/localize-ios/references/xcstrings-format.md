# .xcstrings File Format

`.xcstrings` is a JSON-based String Catalog introduced in Xcode 15. One file replaces all per-language `.strings` and `.stringsdict` files.

## Base Structure

Create as `Localizable.xcstrings` in the main target's resource group:

```json
{
  "sourceLanguage": "en",
  "strings": {},
  "version": "1.0"
}
```

## Adding an Entry

Each key maps to a string entry object:

```json
{
  "sourceLanguage": "en",
  "strings": {
    "checkInShare.title": {
      "comment": "Title of the check-in share modal",
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "new",
            "value": "Share your check-in?"
          }
        }
      }
    }
  },
  "version": "1.0"
}
```

## Key Fields

| Field | Required | Notes |
|---|---|---|
| `extractionState` | Yes | Always `"manual"` for hand-authored keys |
| `comment` | Recommended | Shown to translators in Xcode |
| `localizations` | Yes | Include at minimum the source language (`en`) |
| `state` | Yes | `"new"` for untranslated, `"translated"` once done |

## Multi-Entry Example

```json
{
  "sourceLanguage": "en",
  "strings": {
    "checkInShare.title": {
      "comment": "Title of the share modal for a new check-in",
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": { "state": "new", "value": "Share your check-in?" }
        }
      }
    },
    "checkInShare.alwaysAskToggle.label": {
      "comment": "Label for the always-ask toggle in the share modal",
      "extractionState": "manual",
      "localizations": {
        "en": {
          "stringUnit": { "state": "new", "value": "Always ask" }
        }
      }
    }
  },
  "version": "1.0"
}
```

## Plural Variants

For strings with counts, use `"variations"` with `"plural"`:

```json
"friends.count": {
  "comment": "Number of friends in a list",
  "extractionState": "manual",
  "localizations": {
    "en": {
      "variations": {
        "plural": {
          "one": { "stringUnit": { "state": "new", "value": "%lld friend" } },
          "other": { "stringUnit": { "state": "new", "value": "%lld friends" } }
        }
      }
    }
  }
}
```

## State Values

| State | Meaning |
|---|---|
| `"new"` | Source string added, not yet translated |
| `"translated"` | Translation provided |
| `"needs_review"` | Source changed after translation |

## Xcode Behavior

- Xcode generates per-language `.strings` files from this catalog at build time
- Keys missing from a translation fall back to the source language value
- Edit translations directly in Xcode's String Catalog editor (click `Localizable.xcstrings` in the navigator)
- Adding a new language: Project settings → Info → Localizations → `+`
