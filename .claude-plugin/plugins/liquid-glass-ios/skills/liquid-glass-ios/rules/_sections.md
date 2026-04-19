# Sections

This file defines all sections, their ordering, impact levels, and descriptions for Liquid Glass iOS rules.

---

## 1. Glass Effect Usage (glass)

**Impact:** CRITICAL
**Description:** Proper use of the glassEffect modifier, when to apply glass vs. solid backgrounds, layer placement, and avoiding common anti-patterns.

## 2. Accessibility (a11y)

**Impact:** HIGH
**Description:** Glass effects must respect reduced transparency settings, maintain sufficient contrast for text, and provide proper semantic labels for VoiceOver users.

## 3. Fallback Patterns (fallback)

**Impact:** HIGH
**Description:** Glass effects require iOS 26+. Always provide solid color fallbacks for iOS 24-25 to ensure graceful degradation.

## 4. Performance (perf)

**Impact:** HIGH
**Description:** Glass rendering is computationally expensive. Limit simultaneous glass layers, avoid animating glass properties excessively, and use rasterization for static containers.

## 5. Color & Tint (color)

**Impact:** MEDIUM
**Description:** Glass tint colors must adapt to light/dark mode, avoid washing out content underneath, and maintain visual hierarchy.
