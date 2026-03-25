# xcstrings-tool

[xcstrings-tool](https://github.com/liamnichols/xcstrings-tool-plugin) is a Swift Package Plugin that generates type-safe Swift accessors for `.xcstrings` keys at build time.

## Why Use It

Without xcstrings-tool:
```swift
label.text = String(localized: "featureTitle")  // typo = silent runtime bug
```

With xcstrings-tool:
```swift
label.text = .localizable(.featureTitle)  // typo = compile error
```

## Installation

### Swift Package Manager (Xcode)

1. File → Add Package Dependencies
2. Paste: `https://github.com/liamnichols/xcstrings-tool-plugin`
3. Choose version `1.0.0` or later
4. Add to the app target

### Add the Build Plugin

In Xcode: Target → Build Phases → Run Build Tool Plug-ins → `+` → select `XCStringsToolPlugin`

After adding, build the project (Cmd+B) to generate the Swift types.

## Generated API

Given `Localizable.xcstrings` with key `"featureTitle"`, xcstrings-tool generates:

```swift
// Auto-generated — do not edit
extension String.Localizable {
    static var featureTitle: Self { .init("featureTitle") }
}
```

The call site uses the `.localizable(...)` factory on `String`:

```swift
label.text = .localizable(.featureTitle)
```

### Key-to-Property Name Conversion

camelCase keys map directly to property names:

| Key | Generated property |
|---|---|
| `"featureTitle"` | `.featureTitle` |
| `"featureButtonLabel"` | `.featureButtonLabel` |
| `"featureEmptyStateMessage"` | `.featureEmptyStateMessage` |

## Usage

Prefer type inference — omit `String.` when the compiler can infer the type. Only use `String.localizable(...)` explicitly when there is no inference context.

For entries with format specifiers (`%@`, `%lld`, etc.), the generated case has associated values. Pass arguments directly — never wrap with `String(format:)`.

```swift
// Inferred (preferred) — simple string from a named table
label.text = .localizable(.screenTitle)

// Inferred with argument — string with a format specifier
label.text = .localizable(.welcomeMessage(user.name))

// Inferred on a UIKit method call
button.setTitle(.localizable(.confirmButtonLabel), for: .normal)

// SwiftUI Text with argument
Text(.localizable(.signedInAs(username)))

// Explicit String — only when inference is unavailable
let title = String.localizable(.screenTitle)
```

### Format Specifiers

When a localized string contains interpolated values, use the following format specifiers inside the `value` fields:

| Specifier | Swift type | Example value |
|---|---|---|
| `%@` | `String` | `"Hello, %@"` |
| `%lld` | `Int` | `"%lld days ago"` |
| `%llu` | `UInt` | `"%llu items"` |
| `%f`, `%.2f` | `Double` | `"%f points"` |

Use these specifiers in **both** the `en` and translation values wherever a dynamic value is passed into the string.

## Usage by Context

### UIKit

```swift
// String property
label.text = .localizable(.featureTitle)

// UIButton
button.setTitle(.localizable(.featureButtonLabel), for: .normal)
```

### SwiftUI

```swift
// Text view
Text(.localizable(.featureTitle))

// Text view with argument
Text(.localizable(.welcomeMessage(user.name)))

// Button label
Button(action: { ... }) {
    Text(.localizable(.featureButtonLabel))
}
```

### Switch statements returning String

```swift
var title: String {
    switch self {
    case .stateA: .localizable(.featureStatATitle)
    case .stateB: .localizable(.featureStateBTitle)
    }
}
```

### Cross-target exception

If the file being localized belongs to a target that does **not** have `XCStringsToolPlugin` in its Build Phases (e.g. a shared framework or extension target), use `String(localized:, table:)` explicitly, passing the table name matching the `.xcstrings` file:

```swift
// Framework or extension target — plugin not available
label.text = String(localized: "featureTitle", table: "Localizable")
```

This applies even if the main app target has xcstrings-tool installed. The typed API is only available to targets that run the plugin.

## Decision: xcstrings-tool vs String(localized:)

| | xcstrings-tool | String(localized:) |
|---|---|---|
| Compile-time key safety | Yes | No |
| Setup required | Yes (SPM plugin) | No |
| Works without a build | No | Yes |
| Recommended for new projects | Yes | Fallback only |

**Default recommendation**: suggest xcstrings-tool. If the user declines or it's not installed, use `String(localized:)` throughout.

## Checking if Already Installed

Search for `xcstrings-tool` in `Package.swift` or look for `XCStringsToolPlugin` in the `.pbxproj`. If the generated file `String+Localizable.swift` exists in DerivedData, the plugin is active.
