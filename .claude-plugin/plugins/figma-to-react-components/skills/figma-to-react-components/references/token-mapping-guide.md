# Token Mapping Guide

How to discover, understand, and map design tokens from Figma to your project's token system — regardless of format.

## Token Architecture

Most design token systems follow a three-layer hierarchy:

```
Layer 1: Primitive Tokens (raw values)
  $blue-500: #3b82f6
  $gray-900: #111827
  $space-4: 16px

Layer 2: Semantic Tokens (purpose-based aliases)
  $color-action-primary: $blue-500
  $color-text-primary: $gray-900
  $spacing-md: $space-4

Layer 3: Component Tokens (scoped overrides)
  $button-bg-primary: $color-action-primary
  $card-padding: $spacing-md
```

**Always reference the most specific layer available.** Prefer semantic over primitive. Prefer component tokens over semantic when they exist.

---

## Discovering Project Tokens

Before mapping Figma variables to code, find where tokens live in your project.

### SCSS Variables

```bash
# Find token files
fd '\.scss$' --type f | rg -l '\$color-|^\$spacing-|^\$radius-'

# Common locations
build/scss/_tokens.scss
src/styles/tokens/_colors.scss
src/tokens/variables.scss
```

Usage: `$color-action-primary-default`

### CSS Custom Properties

```bash
# Find custom property definitions
rg --type css ':root|--color-|--spacing-|--radius-'

# Common locations
src/styles/tokens.css
src/styles/variables.css
public/design-tokens.css
```

Usage: `var(--color-action-primary-default)`

### Tailwind Configuration

```bash
# Find Tailwind config
fd 'tailwind\.config\.(js|ts|cjs|mjs)$'

# Check theme extension
rg 'extend|colors|spacing' tailwind.config.*
```

Usage: `bg-primary text-on-primary p-4 rounded-md`

### JavaScript/TypeScript Token Objects

```bash
# Find JS/TS token files
fd 'tokens?\.(js|ts|json)$' --type f
rg 'export.*tokens|export.*theme' --type ts --type js
```

Usage: `tokens.color.action.primary.default` or `theme.spacing.md`

---

## Mapping by Category

### Colors

**What to look for in Figma:**
- Applied fill colors with variable references
- State variants (default, hovered, pressed, disabled)
- Inverted variants for dark backgrounds

**Mapping pattern:**

| Figma Variable | Semantic Purpose | Token Reference |
|---|---|---|
| `color/action/primary/default` | Primary button background | `$color-action-primary-default` |
| `color/action/primary/hovered` | Primary button hover state | `$color-action-primary-hovered` |
| `color/text/primary` | Main body text | `$color-text-primary` |
| `color/surface/primary` | Card/container background | `$color-surface-primary` |
| `color/border/input/default` | Form input border | `$color-border-input-default` |

**Common naming patterns across systems:**

```
Buttons:     $color-{buttons|action}-{variant}-{state}
Text:        $color-text-{role}-{variant}
Surface:     $color-{surface|bg}-{role}
Border:      $color-border-{element}-{state}
Icon:        $color-icon-{role}-{variant}
Semantic:    $color-{success|error|warning|info}-{usage}
```

### Spacing

**What to look for in Figma:**
- Auto layout padding and gap values
- Fixed margin/padding on frames

**Common scale:**

| Value | Token (typical names) |
|---|---|
| 0px | `$spacing-none` / `$space-0` |
| 4px | `$spacing-2xs` / `$space-1` |
| 8px | `$spacing-xs` / `$space-2` |
| 12px | `$spacing-sm` / `$space-3` |
| 16px | `$spacing-md` / `$space-4` |
| 24px | `$spacing-lg` / `$space-6` |
| 32px | `$spacing-xl` / `$space-8` |
| 48px | `$spacing-2xl` / `$space-12` |
| 64px | `$spacing-3xl` / `$space-16` |

### Typography

**What to look for in Figma:**
- Text style names in the design panel
- Font family, size, weight, and line height
- Responsive variants (desktop vs mobile)

**Mapping pattern:**

| Figma Text Style | Token Reference | Properties |
|---|---|---|
| `Text/MD/Regular` | `$typography-text-md-regular` | Font, 16px, 400, 1.5 |
| `Text/SM/Bold` | `$typography-text-sm-bold` | Font, 14px, 700, 1.5 |
| `Headline/LG` | `$typography-headline-lg` | Font, 32px, 400, 1.2 |
| `CTA/MD` | `$typography-cta-md` | Font, 16px, 500, 1.0 |

**Formats vary by system:**

- **Composite tokens:** `$typography-text-md-regular` (encodes all properties)
- **Individual properties:** `$font-size-md`, `$font-weight-regular`, `$line-height-normal`
- **Tailwind:** `text-base font-normal leading-normal`

### Border Radius

**Common scale:**

| Value | Token (typical names) |
|---|---|
| 0px | `$radius-none` / `$radius-square` |
| 4px | `$radius-sm` |
| 8px | `$radius-md` |
| 12px | `$radius-lg` |
| 24px | `$radius-xl` |
| 9999px | `$radius-full` (pills/circles) |

### Elevation / Shadows

**What to look for in Figma:**
- Drop shadow effects on frames
- Multiple shadow layers for depth

**Common scale:**

| Level | Token | Use Case |
|---|---|---|
| None | `$elevation-none` | Flat elements |
| Small | `$elevation-sm` | Subtle lift (cards) |
| Medium | `$elevation-md` | Floating elements |
| Large | `$elevation-lg` | Modals, popovers |
| XL | `$elevation-xl` | Top-level overlays |

---

## Extracting Tokens from Figma

When the project has **no existing token files**, extract them directly from Figma and generate token files for the codebase.

### Step 1: Pull Variable Collections

Use the Figma MCP to retrieve all variables defined in the design file:

```
Figma:get_variable_defs(fileKey, nodeId)
```

This returns all variable collections — typically organized as:
- **Primitives** — Raw values (colors, numbers)
- **Semantic / Tokens** — Purpose-based aliases referencing primitives
- **Component-specific** — Scoped overrides for individual components

### Step 2: Choose Output Format

Ask the user which format to generate and where to save. Common choices:

| Format | File Extension | Example Output Path |
|---|---|---|
| SCSS variables | `_tokens.scss` | `src/styles/tokens/` |
| CSS custom properties | `tokens.css` | `src/styles/` |
| Tailwind theme extension | `tailwind.config.ts` | project root |

### Step 3: Generate Token Files

Organize extracted variables into categorized files:

**SCSS example:**
```
src/styles/tokens/
├── _colors.scss        # $color-action-primary-default: #3b82f6;
├── _spacing.scss       # $spacing-md: 16px;
├── _typography.scss    # $font-size-md: 16px; $font-weight-medium: 500;
├── _radius.scss        # $radius-md: 8px;
├── _elevation.scss     # $elevation-md: 0 2px 4px rgba(0,0,0,0.1);
└── _index.scss         # @forward all partials
```

**CSS custom properties example:**
```css
:root {
  /* Colors */
  --color-action-primary-default: #3b82f6;
  --color-action-primary-hovered: #2563eb;
  --color-text-primary: #111827;

  /* Spacing */
  --spacing-sm: 12px;
  --spacing-md: 16px;
  --spacing-lg: 24px;

  /* Typography */
  --font-size-sm: 14px;
  --font-size-md: 16px;

  /* Radius */
  --radius-md: 8px;

  /* Elevation */
  --elevation-md: 0 2px 4px rgba(0, 0, 0, 0.1);
}
```

### Naming Convention for Generated Tokens

Convert Figma variable paths to token names using kebab-case:

| Figma Variable Path | Generated SCSS | Generated CSS |
|---|---|---|
| `Tokens/color/action/primary/default` | `$color-action-primary-default` | `--color-action-primary-default` |
| `Tokens/color/text/primary` | `$color-text-primary` | `--color-text-primary` |
| `Numeric Tokens/spacing/md` | `$spacing-md` | `--spacing-md` |
| `Numeric Tokens/radius/md` | `$radius-md` | `--radius-md` |

Rules:
- Strip the collection prefix (`Tokens/`, `Numeric Tokens/`, etc.)
- Convert `/` separators to `-`
- Lowercase everything
- Prefix with `$` (SCSS) or `--` (CSS custom properties)

### Step 4: Create Index File

Generate a barrel file so components can import all tokens with a single line:

**SCSS:** `_index.scss`
```scss
@forward 'colors';
@forward 'spacing';
@forward 'typography';
@forward 'radius';
@forward 'elevation';
```

**CSS:** Import in your app's global stylesheet or `<link>` in HTML.

### Step 5: Proceed with Mapping

Once token files are generated, continue with the standard mapping workflow below — the component's Figma variables now have corresponding token references in the codebase.

---

## Handling Missing Tokens

When a Figma value has no matching token:

1. **Check for aliases** — the token may exist under a different name. Search your token files for the raw value.
2. **Check for component tokens** — some values only exist at the component level, not globally.
3. **Use the closest semantic token** — if `$spacing-md` (16px) exists but you need 20px, prefer 16px or 24px to match the scale.
4. **Flag to the design team** — if no token fits, document it as a gap. Use a comment: `/* TODO: missing token for 20px spacing — using $spacing-md (16px) as closest match */`
5. **Never invent tokens** — don't create new token names. Use what the system provides.

---

## Format Comparison Table

The same semantic token across different formats:

| Concept | SCSS | CSS Custom Props | Tailwind | JS/TS |
|---|---|---|---|---|
| Primary action bg | `$color-action-primary` | `var(--color-action-primary)` | `bg-primary` | `tokens.color.action.primary` |
| Medium spacing | `$spacing-md` | `var(--spacing-md)` | `p-4` | `tokens.spacing.md` |
| Body text | `$color-text-primary` | `var(--color-text-primary)` | `text-primary` | `tokens.color.text.primary` |
| Medium radius | `$radius-md` | `var(--radius-md)` | `rounded-md` | `tokens.radius.md` |
| Card shadow | `$elevation-md` | `var(--elevation-md)` | `shadow-md` | `tokens.elevation.md` |

---

## Token Discovery Workflow

When starting a new component:

1. **Extract from Figma** — Use `get_design_context` and `get_variable_defs` to list all variables applied to the component
2. **Identify token format** — Determine which format your project uses (SCSS, CSS vars, Tailwind, JS)
3. **Search for matches** — For each Figma variable, search your token files for corresponding values
4. **Map by category** — Group mappings into colors, spacing, typography, radius, elevation
5. **Flag gaps** — Document any Figma values that don't have matching tokens
6. **Verify in code** — Confirm tokens compile/resolve correctly before using in the component
