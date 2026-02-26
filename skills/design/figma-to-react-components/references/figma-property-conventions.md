# Figma Property Conventions

How to translate Figma component properties into React props. These conventions apply regardless of design system.

---

## Prop Naming Rules

### 1. Always Use lowerCamelCase

All React prop names use lowerCamelCase, matching standard React conventions.

```typescript
// Figma property → React prop
"Icon Leading"  → iconLeading
"Is Disabled"   → isDisabled
"Success Label" → successLabel
"Show Divider"  → showDivider
```

If Figma uses different casing (PascalCase, kebab-case, etc.), convert to lowerCamelCase.

### 2. Figma Emoji Indicators

Figma uses emojis to indicate special property behaviors. Remove emojis in code but understand what they signal:

**Editable text (pencil emoji)** — Indicates editable text content in Figma. In Figma, this requires both a boolean (show/hide) and a string (content) property. In React, simplify to a single prop where empty/undefined means hidden.

```typescript
// Figma: "Label" (editable text)
// React: Use children or named prop — empty = hidden
children?: React.ReactNode;

// For multiple text elements:
label?: string;
title?: string;
supportingText?: string;
```

**Swappable instance (swap emoji)** — Indicates swappable instances (typically icons) in Figma. In Figma, this requires a boolean (show/hide) and a swap instance. In React, use boolean + ReactNode pattern.

```typescript
// Figma: "Icon Leading" (swappable icon)
// React: Boolean to show + ReactNode to customize
iconLeading?: boolean;
iconLeadingSwap?: React.ReactNode;
```

### 3. Text Content Props

| Scenario | React Convention |
|---|---|
| Single text element | Use `children` prop |
| Multiple text elements | Use named props (`title`, `description`, `label`) |
| Optional text | Empty/undefined = hidden (no separate boolean needed) |

```typescript
// Single text — use children
interface ButtonProps {
  children: React.ReactNode;
}

// Multiple text elements — use named props
interface CardProps {
  title: string;
  description?: string;
  supportingText?: string;
}
```

### 4. Icon Props

| Scenario | React Convention |
|---|---|
| Required icon | `icon: React.ReactNode` |
| Optional icon (single) | `icon?: React.ReactNode` |
| Optional icon with position | `iconLeading?: boolean` + `iconLeadingSwap?: React.ReactNode` |
| Multiple icon slots | Name by position: `iconLeading`, `iconTrailing` |

```typescript
// Figma: "Icon Leading" (swappable icon slot)
iconLeading?: boolean;
iconLeadingSwap?: React.ReactNode;

// Figma: "Icon Trailing" (swappable icon slot)
iconTrailing?: boolean;
iconTrailingSwap?: React.ReactNode;
```

### 5. Boolean Prefixes

Use consistent prefixes for boolean props:

| Prefix | Use Case | Examples |
|---|---|---|
| `is` | Component state | `isDisabled`, `isLoading`, `isActive`, `isSelected` |
| `has` | Feature presence | `hasIcon`, `hasBorder`, `hasDivider` |
| `show` | Visibility toggle | `showLabel`, `showDivider`, `showBadge` |

### 6. Variant Props

Map Figma variant properties directly:

```typescript
// Figma: "Size" with options sm, md, lg
size?: 'sm' | 'md' | 'lg';

// Figma: "Hierarchy" with options primary, secondary, tertiary
hierarchy?: 'primary' | 'secondary' | 'tertiary';
// OR use "variant" if that matches your project's convention
variant?: 'primary' | 'secondary' | 'tertiary';

// Figma: "State" with options default, hover, pressed, disabled
// Don't create a "state" prop — these are CSS/interaction states, not props.
// Use isDisabled for the disabled case; CSS handles hover/pressed.
isDisabled?: boolean;
```

---

## Figma → React Translation Examples

```typescript
// Figma: "Label" (editable text)
// React: Use children or named prop
children?: React.ReactNode;

// Figma: "Icon Leading" (swappable icon)
// React: Boolean + swap instance
iconLeading?: boolean;
iconLeadingSwap?: React.ReactNode;

// Figma: "Size" with options (sm, lg)
// React: Union type
size?: 'sm' | 'lg';

// Figma: "Is Disabled" or "Disabled"
// React: Use 'is' prefix
isDisabled?: boolean;

// Figma: "Show Badge"
// React: Keep as-is or use children pattern
showBadge?: boolean;
badgeContent?: React.ReactNode;

// Figma: "Surface" with options (light, dark)
// React: Keep as-is
surface?: 'light' | 'dark';
```

---

## Common Pitfalls

1. **Don't create state props for CSS states** — Hover, pressed, and focus are CSS/interaction states, not component props. Only `isDisabled` and `isLoading` need props.
2. **Don't duplicate Figma's internal structure** — Figma needs booleans to show/hide layers. React can use conditional rendering with `undefined` checks.
3. **Don't assume all Figma variants are props** — Some Figma variants (like "State: Hover") are for design documentation, not component API.
4. **Always extract props from Figma MCP** — Don't guess at component properties. Use `get_design_context` to read actual Figma component definitions.
