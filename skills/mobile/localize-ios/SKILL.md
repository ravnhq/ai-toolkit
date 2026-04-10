---
name: localize-ios
description: 'Localizes UIKit Views and ViewControllers and SwiftUI Views. Extracts
  hardcoded text, generates camelCase keys, replaces literals with String(localized:)
  or LocalizedStringKey, and creates or updates Localizable.xcstrings. Use when: (1)
  localizing a UIKit or SwiftUI file, (2) extracting hardcoded strings from Swift,
  (3) adding xcstrings entries. Triggers on: localize, extract strings, add localization,
  make localizable, xcstrings, localize this view, localize this file. NOT for general
  Swift tasks unrelated to localization.'
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: mobile
  tags:
  - ios
  - swift
  - localization
  - xcstrings
  - swiftui
  - uikit
  status: ready
  version: 5
---

# Localize Swift

Localize UIKit Views and ViewControllers and SwiftUI Views: extract hardcoded strings, generate consistent keys, replace literals with the correct Swift API, and create or update the `.xcstrings` String Catalog.

## Overview

String Catalogs (`.xcstrings`, Xcode 15+) are the Apple-recommended localization format. This skill guides extraction of hardcoded strings, generation of camelCase keys, and replacement with typed APIs (`String(localized:)` or xcstrings-tool's `.localizable(...)`).

## Rules

See [rules index](rules/_sections.md) for detailed patterns covering:
- Always use String Catalogs over legacy `.strings` files
- LocalizedStringKey vs. String(localized:) API selection
- Plural rules and string interpolation patterns
- Accessibility label localization
- RTL layout considerations
- Testing localized content

## Workflow

### 1. Check xcstrings-tool

**This step is a hard gate. Do not read the target file, extract strings, propose keys, or take any other action until this step reaches a terminal outcome. The workflow does not advance until one of the two outcomes below is confirmed.**

Search for `xcstrings-tool` in `Package.swift` and for `XCStringsToolPlugin` in `project.pbxproj`.

**Outcome A — Already installed:** note it and move to step 2.

**Outcome B — Not installed:** inform the user it is not present, explain the benefit (compile-time key safety), and ask: _"Would you like to install xcstrings-tool before continuing, or proceed without it?"_ Then stop and wait.

- If the user says **no / skip**: note that `String(localized:)` will be used throughout, then move to step 2.
- If the user says **yes**: follow the installation steps in `references/xcstrings-tool.md → Installation`, ask them to build (Cmd+B), then verify `XCStringsToolPlugin` appears in `project.pbxproj`. If not found, inform the user the plugin is still missing and do not advance. Only move to step 2 once confirmed present.

### 2. Read the target file

Read the Swift file the user points to. Classify it as one of:

- **View layer** — UIKit ViewController, UIView subclass, SwiftUI View
- **ViewModel / Presenter** — class or struct that owns display-intent properties (e.g. `title`, `message`, `buttonLabel`) consumed by a view
- **Helper / Formatter / Enum** — produces strings that eventually reach the UI (e.g. an enum with a `var title: String` switch, a date formatter returning display text)

The classification affects the replacement API (see step 6) but all three types can contain strings that need localization.

### 3. Extract hardcoded strings

Find all raw string literals that represent user-visible text. For ViewModel and helper files, apply the data-flow heuristic in `references/key-naming.md → User-Facing Strings in ViewModels and Helper Classes` to determine whether each string reaches the UI. See the full exclusion list there as well.

Present all candidates to the user before making changes.

### 4. Propose localization keys

Use **camelCase** — `featureNameComponentNameDescription`. Derive the prefix from the file name or feature folder.

| Source string | Proposed key |
|---|---|
| `"Screen title"` | `featureTitle` |
| `"Always ask"` | `featureAlwaysAskToggleLabel` |
| `"Done"` | `featureDoneButtonLabel` |
| `"No results"` | `featureEmptyStateMessage` |

See `references/key-naming.md` for naming rules and conflict resolution. Present the full key list to the user and **confirm before making any changes**. Accept corrections.

### 5. Update the .xcstrings file

See `references/xcstrings-format.md` for exact JSON structure.

1. **Search the project for all `*.xcstrings` files.**
   - If **more than one** is found, ask the user which file to add the new keys to before proceeding.
   - If **exactly one** is found, use it directly.
   - If **none** is found, create one (see step 2).

2. **Creating `Localizable.xcstrings`** — locate the `Resources` folder in the main target. Identify it by the presence of any of: `*.xcassets` directories, `.mp4` files, `.json` files, or other static resource files. Inside `Resources`, create a `Localization/` subfolder and write `Localizable.xcstrings` there using the base structure from `references/xcstrings-format.md`:
   ```
   Resources/
   └── Localization/
       └── Localizable.xcstrings
   ```
   Then **immediately register it in `project.pbxproj`** by running the bundled script:
   ```bash
   swift sh .claude/skills/localize-ios/scripts/add_to_xcodeproj.swift \
     "path/to/App.xcodeproj" \
     "path/to/Resources/Localization/Localizable.xcstrings" \
     --group Localization
   ```
   The script will:
   - Detect the main app target automatically (by `productType = "com.apple.product-type.application"`)
   - Create a `Localization` PBXGroup if it doesn't exist, nested under the parent `Resources` group
   - Add the file reference with `path = Localizable.xcstrings` (the group's `path` handles the directory)
   - Add the build file to the correct target's `PBXResourcesBuildPhase`

   Verify the script output confirms the target name, file reference UUID, and build file UUID.

   Unless the user explicitly requests otherwise, the `.xcstrings` file must always belong to the main app target. Use `--target "TargetName"` to override if needed.

3. Add each new key as an entry under `"strings"` with:
   - `"extractionState": "manual"`
   - A `"comment"` describing context for translators
   - The source string as the English value with `"state": "new"`

4. **Check for existing translations.** Search `project.pbxproj` for the `knownRegions` array to detect all languages configured in the project. Do **not** rely on inspecting the `.xcstrings` file itself. For each language code found in `knownRegions` other than `en` and `Base`:
   - Add a `"localizations"` entry for that language on every new key
   - Provide the actual translation — do not copy the English value
   - Set `"state": "translated"`
   - If you are not confident in the translation accuracy, set `"state": "needs_review"` and add a note in the report

### 6. Replace strings in the Swift file

Apply API selection in this order:

1. **xcstrings-tool installed → use typed API** (`.localizable(...)`) everywhere in the target.
2. **xcstrings-tool not installed → use** `String(localized:)`.
3. **Cross-target exception:** file belongs to a target without `XCStringsToolPlugin` → use `String(localized:, table:)`.

See `references/xcstrings-tool.md → Usage by Context` for code patterns covering UIKit, SwiftUI, and switch statements.

### 7. Report results

After all changes, output:

- A table of replaced strings → keys
- Path to the created/updated `.xcstrings` file
- xcstrings-tool recommendation if not installed
- Next steps: add translations in Xcode's String Catalog editor, then build to regenerate typed accessors

## Examples

### Positive Trigger

User: "Localize ProfileViewController.swift"

Expected behavior: Read the file, extract all hardcoded user-facing strings, propose camelCase keys, confirm with the user, replace strings with `String(localized:)`, and create/update `Localizable.xcstrings`.

### Non-Trigger

User: "Fix the layout bug in ProfileViewController where the button is clipped."

Expected behavior: Do not use this skill. Investigate and fix the layout issue directly without invoking the localization workflow.

## Troubleshooting

### Switch statement strings not replaced

- Error: Raw string literals inside switch cases remain hardcoded after running the workflow.
- Cause: Each switch case returns a String and must be wrapped individually — there is no single call site.
- Solution: Replace each case's string literal with `String(localized: "key")` or `.localizable(.key)` one by one.

### .xcstrings file not found

- Error: No `Localizable.xcstrings` file exists in the project.
- Cause: The project has not been localized yet.
- Solution: Create `Resources/Localization/Localizable.xcstrings` using the base structure from `references/xcstrings-format.md`, then run `scripts/add_to_xcodeproj.swift` (via `swift sh`) to register it in `project.pbxproj`. Both steps are required — the file must exist on disk AND be referenced in the project.

### .xcstrings file created but missing in Xcode

- Error: `Localizable.xcstrings` exists on disk but does not appear in Xcode's project navigator and is not bundled.
- Cause: The file was written to disk but `project.pbxproj` was not updated.
- Solution: Run `scripts/add_to_xcodeproj.swift` (via `swift sh`) with the correct `.xcodeproj` path and file path. Confirm the script output shows the target and group where the file was added, then reopen the project in Xcode.

### xcstrings-tool typed accessors missing after adding keys

- Error: After adding keys to `.xcstrings`, `.localizable(...)` properties are not available.
- Cause: xcstrings-tool runs as a build-time plugin — it regenerates Swift types only when the project builds.
- Solution: Build the project (Cmd+B in Xcode) to trigger code generation. If the types still do not appear, verify the plugin is added to the app target's Build Phases.

### .xcstrings file added to wrong target

- Error: `Localizable.xcstrings` is registered in `project.pbxproj` but xcstrings-tool does not generate typed accessors, or the strings are not found at runtime.
- Cause: The file was added to an extension target's `PBXResourcesBuildPhase` instead of the main app target's.
- Solution: The `add_to_xcodeproj.swift` script automatically finds the main app target by `productType = .application`. If you need a specific target, use `--target "TargetName"`. For manual fixes, move the build file entry from the extension target's `PBXResourcesBuildPhase` to the main app target's phase.

### Localizable.xcstrings registered under wrong group in Xcode navigator

- Error: Xcode build error "The file 'Localizable.xcstrings' couldn't be opened because there is no such file" even though the file exists on disk.
- Cause: `scripts/add_to_xcodeproj.swift` created the `Localization` PBXGroup but nested it under the wrong parent group (e.g. `UI` instead of `Resources`). Xcode resolves the file path by walking the group chain, so the wrong parent causes the resolved path to differ from the actual disk path.
- Solution: Verify in `project.pbxproj` that the `Localization` group appears in the `children` array of the `Resources` group (not any other group). If it is under the wrong parent, remove the entry from the wrong group's `children` array and add it to the `Resources` group's `children` array.

### Key naming conflict with existing entries

- Error: A proposed key already exists in `.xcstrings` with a different source string.
- Cause: The same key was reused across different UI contexts.
- Solution: Make the key more specific by adding more context segments, e.g. `featureConfirmButtonLabel` instead of `featureLabel`.
