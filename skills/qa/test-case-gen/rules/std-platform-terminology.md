---
title: Platform Terminology
impact: HIGH
tags:
  - platform
  - terminology
  - verbs
  - ui-elements
---

# Platform Terminology

Use the correct interaction verbs and UI element names for the target platform. Mismatched terminology makes steps unexecutable on the target device and creates confusion during handoff to developers and automation engineers.

## Interaction Verbs

| Action | `web` | `ios` | `android` |
|---|---|---|---|
| Primary tap/click | click | tap | tap |
| Extended press | (right-click for context) | long press | long press |
| Gesture | scroll | swipe | swipe |
| Touch pressure | — | Force Touch / 3D Touch | — |
| Navigate back | browser back | Navigation Bar back button | system back button |
| Dismiss / reveal menu | — | swipe up/down | swipe up/down |
| Navigate to address | navigate to URL | — | — |
| Context menu | right-click | — | overflow menu (⋮) |

**Cross-platform rule:** Use mobile-first verbs (`tap`, `swipe`) as the primary verb. When the web equivalent differs meaningfully, add a platform note in the step's `notes` field. Never use `click` as the primary verb in cross-platform test cases.

## UI Element Names

| Concept | `web` | `ios` | `android` |
|---|---|---|---|
| Top navigation | Navbar | Navigation Bar | Toolbar (AppBar) |
| Tab navigation | Tabs | Tab Bar | Bottom Navigation |
| Overflow menu | Dropdown | Action Sheet | Bottom Sheet |
| Dialog | Modal / Dialog | Alert | Dialog |
| Selection control | Dropdown | Picker | Spinner |
| Loading indicator | Spinner | Activity Indicator | Progress Bar |
| Floating action button | — | — | FAB |
| Inline message | Tooltip | — | Snackbar / Toast |
| Side navigation | Sidebar | — | Navigation Drawer |
| Breadcrumb path | Breadcrumb | — | — |

## Examples

### Incorrect vs. Correct

**Web — incorrect:**
> Step: "Tap the Tab Bar to go to the dashboard."

**Web — correct:**
> Step: "Click the Navbar link to navigate to the dashboard."

---

**iOS — incorrect:**
> Step: "Click the Dropdown to select a country."

**iOS — correct:**
> Step: "Tap the Picker to select a country."

## Why It Matters

Using the wrong vocabulary (e.g., `click` on iOS, `Tab Bar` on web) makes test steps unexecutable on the target device. It also confuses handoff to developers and automation engineers who rely on precise element names to locate UI components and write selectors.
