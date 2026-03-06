# String Extraction and Key Naming

## What to Extract

Localize any raw string literal that represents **user-visible text**: labels, button titles, placeholders, error messages, empty-state descriptions, alert titles/messages, and similar UI copy.

## User-Facing Strings in ViewModels and Helper Classes

A string is user-facing — and must be localized — even if it lives in a ViewModel, Presenter, Formatter, UseCase, or enum, as long as it is ultimately displayed in the UI.

**Localize when the string is:**

- Returned from a computed property with a display-intent name: `title`, `subtitle`, `message`, `label`, `description`, `placeholder`, `buttonTitle`, `errorMessage`, `emptyStateMessage`, `displayName`, `hint`
- Returned from a method that a view calls to populate a label, button, or alert
- Part of an enum's display-facing computed var (e.g. `var title: String { switch self { ... } }`)
- Passed to a view via a binding, publisher, or callback that feeds a `UILabel.text`, `Text()`, `setTitle(_:for:)`, etc.
- Part of an error type's user-visible property (`localizedDescription`, `message`, `userInfo[NSLocalizedDescriptionKey]`)
- Used to construct an `AttributedString` or `NSAttributedString` shown in the UI

**Do NOT localize when the string is:**

- A logging or analytics event name (sent to a tracking service, not displayed)
- An API parameter, request body field, or query key
- A notification name, KVO key path, or UserDefaults key
- A file name, directory path, or bundle identifier
- Passed only to `print`, `debugPrint`, `Logger`, `os_log`, or similar
- A hardcoded test value inside `#if DEBUG` blocks not shown in production UI

**Detection heuristic for ambiguous cases:** follow the data flow. If the string can reach a `UILabel`, `UIButton`, `Text`, `Alert`, `UIAlertController`, or any other visible UI element through any code path — it is user-facing.

## What to Skip

Do **not** localize:

- **Identifiers**: cell reuse IDs, image/icon names, SF Symbol names, notification names, segue IDs, URL strings, format specifiers (`%d`, `%@`)
- **Already localized**: strings already wrapped in `String(localized:)`, `NSLocalizedString`, or typed as `LocalizedStringKey`
- **Debug/developer strings**: strings inside `assert`, `precondition`, `fatalError`, `print`, `debugPrint`
- **Non-runtime literals**: string literals in comments and `#imageLiteral` / `#colorLiteral`

## Key Naming Convention

Use **camelCase** with this structure:

```
featureNameComponentNameDescription
```

Derive the prefix from the file name or feature folder.

| Source string | Proposed key |
|---|---|
| `"Screen title"` | `featureTitle` |
| `"Always ask"` | `featureAlwaysAskToggleLabel` |
| `"Done"` | `featureDoneButtonLabel` |
| `"No results"` | `featureEmptyStateMessage` |

Rules:
- Prefix = feature or screen name (e.g. `profile`, `checkIn`, `settings`)
- Component = UI element type when disambiguation is needed (e.g. `Button`, `Toggle`, `EmptyState`)
- Description = semantic role (e.g. `Label`, `Title`, `Message`, `Placeholder`)
- Omit components that are obvious from context (e.g. a screen's main title is just `featureTitle`, not `featureTitleLabel`)
- If a key conflicts with an existing entry in `.xcstrings`, add more specificity (e.g. `featureConfirmButtonLabel` instead of `featureLabel`)
