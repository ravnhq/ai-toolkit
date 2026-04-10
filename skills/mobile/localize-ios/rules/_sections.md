# Sections

This file defines all sections, their ordering, impact levels, and descriptions for localize-ios rules.

---

## 1. String Catalog Format (catalog)

**Impact:** CRITICAL
**Description:** Always use `.xcstrings` (Xcode 15+) over legacy `.strings` files. String Catalogs provide compile-time safety, automatic pluralization, and device-language variants.

## 2. Localization API (api)

**Impact:** CRITICAL
**Description:** Choose the correct API — `String(localized:)` for manual setup, or `.localizable(...)` when xcstrings-tool is installed. Never mix APIs in the same target.

## 3. String Patterns (pattern)

**Impact:** HIGH
**Description:** Handle plurals, interpolation, and formatting correctly. Avoid string concatenation; use format strings and plural rules instead.

## 4. Accessibility (a11y)

**Impact:** HIGH
**Description:** Localize accessibility labels and descriptions. Do not skip a11y strings; translators need context for alternative text.

## 5. Layout & RTL (layout)

**Impact:** MEDIUM
**Description:** Right-to-left (RTL) languages require mirrored layouts, longer strings, and number formatting. Test with Arabic, Hebrew, Farsi.

## 6. Testing (test)

**Impact:** MEDIUM
**Description:** Verify localized content by switching device language, testing pseudo-locales (long strings, RTL simulators), and checking key coverage.
