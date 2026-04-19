# Props Documentation Template

Use this template when generating component props documentation from Figma designs.

---

## Overview
<!--
Brief description of the component (max 200 characters).
What it does, when to use it.
-->

## Component Properties

<!--
All components should use React Aria for accessibility.
Include both component-specific props AND React Aria attributes in separate tables:
1. Props table: Component-specific properties
2. React Aria Properties table: Accessibility attributes (aria-*, role, etc.)
-->

### Props

| Prop | Type | Default | Description |
|---|---|---|---|
| `variant` | `'primary' \| 'secondary'` | `'primary'` | Visual style variant |
| `size` | `'sm' \| 'md' \| 'lg'` | `'md'` | Component size |
| `isDisabled` | `boolean` | `false` | Whether the component is disabled |
| `children` | `React.ReactNode` | — | Content to render |

### React Aria Properties

| Prop | Type | Description |
|---|---|---|
| `aria-label` | `string` | Accessible label (overrides visible text) |
| `aria-labelledby` | `string` | ID of element that labels this component |
| `aria-describedby` | `string` | ID of element that provides additional description |
| `onPress` | `(e: PressEvent) => void` | Handler called when pressed (React Aria) |

## Size Variants

<!--
Use typography token names from your project's token system instead of listing individual properties.
Format: - **Typography**: `[token-name]` (description with font family, size, weight, line height)

Use variable syntax for icon sizes and spacing:
- Icon Size: `[icon-size-token]` (dimensions)
- Spacing: `[spacing-token]` (value)

Never use raw pixel values without their token reference.
-->

## Hierarchy Variants

## State Variants

<!--
Document all states extracted from Figma:
- Default
- Hover
- Pressed/Active
- Disabled
- Focus
- Loading (if applicable)
- Error (if applicable)
-->

## Surface Variants

<!--
If the component has variants for different background surfaces (light/dark).
-->

## Icons

<!--
Document icon positioning, sizing tokens, and available slots.
-->

## Typography

<!--
List typography tokens used by the component, including responsive variants if applicable.
-->

## Visual Characteristics

<!--
Border radius, elevation, transitions, and other visual details.
-->

## Accessibility

<!--
Include these subsections and reference the React Aria Properties:
-->

### Focus State
<!--
Describe focus ring appearance and how keyboard navigation or assistive technology triggers focus.
Reference the focus token used.
-->

### Keyboard Navigation
<!--
List keyboard interactions (Tab, Enter, Space, Arrow keys, Escape, etc.)
-->

### Disabled State
<!--
Explain disabled appearance and screen reader announcements.
-->

### Color Contrast
<!--
Document WCAG compliance and contrast ratios for all states.
-->

## Usage Guidelines

<!--
When to use vs not use this component.
Common patterns and anti-patterns.
-->
