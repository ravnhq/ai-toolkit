# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Design Tokens (tokens)

**Impact:** CRITICAL
**Description:** Always use design tokens for colors, spacing, typography, and other visual properties. Never hardcode raw values — the token system is the single source of truth for visual consistency.

## 2. Accessibility (aria)

**Impact:** HIGH
**Description:** All interactive components must use React Aria hooks for keyboard navigation, screen reader support, and focus management. Follow WCAG AA standards.

## 3. Naming Conventions (naming)

**Impact:** MEDIUM
**Description:** Use BEM methodology for CSS class names and consistent naming patterns for component files, props, and variants.
