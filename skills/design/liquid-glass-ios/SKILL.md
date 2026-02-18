---
name: liquid-glass-ios
description: Apple's Liquid Glass design system for iOS 26+ and iPadOS 26+. Use when
  building iOS 26+ UI with glassEffect, implementing GlassEffectContainer, working
  with glass morphing transitions, or migrating from UIKit to SwiftUI glass APIs.
metadata:
  category: design
  tags:
  - ios
  - liquid-glass
  - apple
  - swiftui
  - design
  status: ready
  version: 2
---

# Liquid Glass Design for iOS

Implementation patterns for Apple's Liquid Glass design system in iOS 26+ and iPadOS 26+, covering SwiftUI glassEffect APIs and UIKit NSGlassEffectView integration.

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

### Skill Does Not Trigger

- Error: The skill is not selected when expected.
- Cause: Request wording does not clearly match the description trigger conditions.
- Solution: Rephrase with explicit domain/task keywords from the description and retry.

### Guidance Conflicts With Another Skill

- Error: Instructions from multiple skills conflict in one task.
- Cause: Overlapping scope across loaded skills.
- Solution: State which skill is authoritative for the current step and apply that workflow first.

### Output Is Too Generic

- Error: Result lacks concrete, actionable detail.
- Cause: Task input omitted context, constraints, or target format.
- Solution: Add specific constraints (environment, scope, format, success criteria) and rerun.

## Workflow

1. Identify whether the request clearly matches `liquid-glass-ios` scope and triggers.
2. Apply the skill rules and referenced guidance to produce a concrete result.
3. Validate output quality against constraints; if gaps remain, refine once with explicit assumptions.
