---
name: liquid-glass-ios
description: Apple's Liquid Glass design system for iOS 26+ and iPadOS 26+. Use when
  building iOS 26+ UI with glassEffect, implementing GlassEffectContainer, working
  with glass morphing transitions, or migrating from UIKit to SwiftUI glass APIs.
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
  - liquid-glass
  - apple
  - swiftui
  - design
  status: ready
  version: 6
---

# Liquid Glass Design for iOS

Implementation patterns for Apple's Liquid Glass design system in iOS 26+ and iPadOS 26+, covering SwiftUI glassEffect APIs and UIKit NSGlassEffectView integration.

## Overview

Liquid Glass is Apple's next-generation frosted glass design pattern for iOS 26 and iPadOS 26+. It provides visual hierarchy, depth, and interactive feedback through translucent glass layers with tint and blur effects. Use glassEffect to create adaptive, accessible glass overlays that enhance UI without sacrificing readability.

## Rules

See [rules index](rules/_sections.md) for detailed patterns covering:
- Glass effect usage and proper layer placement
- Accessibility with glass effects (contrast, readability, reduced transparency)
- Fallback patterns for pre-iOS 26 versions
- Performance optimization for glass rendering
- Color and tint management

## References

See [references/liquid-glass.md](references/liquid-glass.md) for comprehensive guidance organized by:

- **Platform & Availability** - iOS 26+ version checking and fallbacks
- **Navigation & UI Layer** - Proper layer placement for glass effects
- **Variants & Styling** - Glass variants (regular, thin, clear) and color usage
- **Container & Multi-Element Management** - GlassEffectContainer patterns and spacing
- **Morphing & Animations** - Transition effects and identity management
- **Performance & Limits** - Element constraints and optimization
- **Accessibility** - VoiceOver and reduced transparency support
- **UIKit Integration** - NSGlassEffectView patterns
- **Framework Interoperability** - SwiftUI and UIKit mixing constraints

## Examples

### Positive Trigger

User: "Implement iOS 26 glassEffect navigation with proper fallbacks."

Expected behavior: Use `liquid-glass-ios` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Implement Android Compose Material 3 bottom navigation."

Expected behavior: Do not prioritize `liquid-glass-ios`; choose a more relevant skill or proceed without it.

## Troubleshooting

### Glass effect not showing on older iOS versions

- Error: Glass effect does not render on iOS 24 and earlier devices.
- Cause: glassEffect modifier requires iOS 26+; fallback pattern not implemented.
- Solution: Use `@available(iOS 26, *)` or `if #available(iOS 26, *)` to check version before applying glass; provide solid color fallback for earlier versions.

### Accessibility: reduced transparency ignored

- Error: Glass effect renders with full transparency even when reduced transparency is enabled in Settings.
- Cause: Glass effect modifier not checking `accessibilityReduceTransparency` environment value.
- Solution: Use `@Environment(\.accessibilityReduceTransparency)` to detect setting; switch to solid overlay when true.

### Glass effect performance degradation

- Error: Frame rate drops or jank when scrolling list with multiple glass effect views.
- Cause: Excessive glass rendering overhead; too many simultaneous glass layers.
- Solution: Limit glass effects to 2-3 per screen; use `shouldRasterize` for static glass containers; benchmark with Instruments (Core Animation).

### Guidance Conflicts With Another Skill

- Error: Instructions from multiple skills conflict in one task.
- Cause: Overlapping scope across loaded skills.
- Solution: State which skill is authoritative for the current step and apply that workflow first.

### Output Is Too Generic

- Error: Result lacks concrete, actionable detail.
- Cause: Task input omitted context, constraints, or target format.
- Solution: Add specific constraints (environment, scope, format, success criteria) and rerun.

## Workflow

1. **Identify scope** — Confirm the request matches `liquid-glass-ios` (iOS 26+ UI, glassEffect, glass morphing, or UIKit glass migration).
2. **Check platform** — Determine iOS version target and whether fallback patterns are needed for iOS 24-25.
3. **Review rules** — Consult [rules/](rules/) for glass usage patterns, accessibility, performance, and color/tint management.
4. **Reference guidance** — Use [references/liquid-glass.md](references/liquid-glass.md) for layer placement, GlassEffectContainer patterns, and animation strategies.
5. **Apply and validate** — Implement glass effects, check accessibility (reduced transparency), test on device with Instruments, and verify frame rate stability.
6. **Validate output** — Ensure glass layers respect safe areas, accessibility settings, and performance budgets; refine once if needed.
