---
name: figma-to-react-components
description: Convert Figma component designs into production-ready React implementations
  with design token integration, accessibility via React Aria, and comprehensive documentation.
  Use when building React components from Figma designs, generating component implementation
  specs, or bridging design-to-development workflows.
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: frontend
  tags:
  - figma
  - react
  - design-tokens
  - component-generation
  - accessibility
  - react-aria
  - design-handoff
  status: ready
  version: 4
---

# Figma to React Component Converter

Convert Figma component designs into production-ready React components with full design token integration, accessibility support via React Aria, and comprehensive documentation. Works with any design token system (SCSS variables, CSS custom properties, Tailwind, or JavaScript tokens).

## Prerequisites

- **Figma MCP** — Figma MCP server configured and running
- **React Aria** — `react-aria` and `react-stately` installed
- **Design tokens** (optional) — If the project already has a token system (SCSS, CSS vars, Tailwind, JS/TS), map to it. If not, tokens are extracted from Figma and generated as part of the workflow.
- **Storybook** (optional) — For component documentation and visual testing

## Project Configuration Discovery

On first use in a project, discover the local configuration before generating code. Search the codebase to determine:

1. **Token import path** — Where tokens are imported from. Search for existing token files:
   - SCSS: `@import 'styles/tokens'` or `@import 'path/to/variables'`
   - CSS: `@import 'tokens.css'` or custom properties in `:root`
   - Tailwind: `tailwind.config.ts` theme extension
   - JS/TS: `import { tokens } from './tokens'`
   - **If no token files exist:** Tokens will be extracted from Figma and generated during Phase 2. Ask the user which format to generate (SCSS, CSS custom properties, or Tailwind) and where to save them.

2. **Component output directory** — Where components live (e.g., `src/components/`)

3. **Stories directory** — Where Storybook stories live (e.g., `stories/` or co-located)

4. **Styling approach** — SCSS modules, CSS modules, Tailwind utility classes, styled-components, etc.

5. **Icon/asset strategy** — Project icon library location and import convention

Cache these findings for the session. If unsure about any setting, ask the user before generating code.

## Workflow

Follow these phases in order:

### Phase 1: Extract Figma Design Context

Use Figma MCP tools to gather component information:

```
Figma:get_design_context(fileKey, nodeId)   # Component structure and tokens
Figma:get_variable_defs(fileKey, nodeId)     # Variable definitions for token mapping
Figma:get_screenshot(fileKey, nodeId)        # Visual reference
```

**What to extract:**
- Component structure and hierarchy
- Applied variables/tokens (colors, spacing, typography)
- Variant properties (size, state, hierarchy)
- Interactive states (hover, pressed, disabled, focus)
- Text styles and their token mappings
- Layout constraints and spacing values
- Icons and image fills

### Phase 2: Map Design Tokens

**If the project has existing tokens:** Cross-reference Figma variables to the project's token system using `references/token-mapping-guide.md`.

**If the project has NO token files:** Extract tokens directly from Figma and generate token files. See `references/token-mapping-guide.md` § "Extracting Tokens from Figma" for the full workflow:
1. Use `get_variable_defs` to pull all variable collections from the Figma file
2. Ask the user for their preferred format (SCSS, CSS custom properties, or Tailwind) and output directory
3. Generate organized token files (colors, spacing, typography, radius, elevation) using semantic naming conventions
4. Create an index/barrel file that imports all token partials
5. Proceed with mapping component values to the newly generated tokens

**Token categories to map (or generate):**
- Colors (backgrounds, text, borders, icons)
- Spacing (padding, margins, gaps)
- Typography (font family, size, weight, line height)
- Border radius
- Elevation/shadows
- Component sizes (heights, widths, icon sizes)

**Important:** Use the project's token variable names, never raw values (see `rules/tokens-never-hardcode.md`).

### Phase 3: Generate Props Documentation

Create props documentation following `references/props-template.md`.

**Required sections:**
- Overview (max 200 characters)
- Component Properties (Props table + React Aria Properties table)
- Size Variants (using typography token names)
- Hierarchy Variants
- State Variants (default, hover, pressed, disabled, focus)
- Icons (token references for icon sizes)
- Typography (token names from Figma descriptions)
- Accessibility (Focus State, Keyboard Navigation, Disabled State, Color Contrast)
- Usage Guidelines

**Prop naming:** Follow conventions in `references/figma-property-conventions.md`.

### Phase 4: Generate React Component Code

Create the component following `references/component-patterns.md`.

**Requirements:**
- React Aria hooks for accessibility (see `rules/aria-use-react-aria-hooks.md`)
- TypeScript with explicit prop interfaces
- BEM naming convention for CSS classes (see `rules/naming-bem-methodology.md`)
- Proper disabled state handling
- Focus management with `:focus-visible` (see `rules/aria-focus-visible-only.md`)
- Build props from actual Figma MCP extraction, not assumptions

### Phase 5: Generate Styles

Create the stylesheet using the project's token system.

**Structure:**
- Import tokens from the discovered project path
- Base styles using token references
- State modifiers (`:hover`, `:active`, `:disabled`, `:focus-visible`)
- Size variant modifiers
- Hierarchy/variant modifiers
- Use semantic token names (see `rules/tokens-use-semantic-names.md`)

### Phase 6: Create Storybook Story

Generate Storybook documentation showing all variants:
- Default story with primary args
- Size variants side by side
- Hierarchy/visual variants
- State demonstrations (default, disabled)
- Include React Aria prop controls (`aria-label`, `aria-labelledby`, `aria-describedby`)

### Phase 7: Testing & Validation

After implementation, validate:
- Visual comparison with Figma design (within 2px tolerance)
- All variants render correctly
- Interactive states (hover, focus, pressed, disabled) work as expected
- Keyboard navigation functions properly
- No hardcoded values remain — all visual properties use tokens

### Phase 8: Cleanup Junk Files

The Figma MCP sometimes generates temporary files during extraction:
- Remove root-level SVG files generated by Figma MCP
- Remove temporary images not in project asset directories
- Verify no orphaned files from the MCP extraction process

## Output Structure

Deliver all artifacts in this order:

1. **Props Documentation** (`[ComponentName]-props.md`)
   - All tokens referenced by variable name
   - Complete accessibility documentation

2. **React Component** (`[ComponentName].tsx`)
   - TypeScript with full type safety
   - React Aria integration
   - No inline SVG code — use project's icon library

3. **Styles** (`[ComponentName].[scss|module.scss|css]`)
   - Token-based styling
   - BEM methodology
   - All state variants

4. **Storybook Story** (`[ComponentName].stories.tsx`)
   - Interactive examples with React Aria props
   - All variants demonstrated

## Rules

See [rules index](rules/_sections.md) for token, accessibility, and naming rules.

## Examples

### Positive Trigger

User: "Convert this Figma button component to React with all its variants and states."

Expected behavior: Use `figma-to-react-components` guidance — extract Figma context via MCP, map tokens, generate typed React component with React Aria, create styles using project tokens, and produce Storybook story.

### Non-Trigger

User: "Write unit tests for this payment service."

Expected behavior: Do not prioritize `figma-to-react-components`; choose a more relevant skill or proceed without it.

## Troubleshooting

### Figma Tokens Not Found

- Error: Figma variables do not map to any project tokens.
- Cause: Token variable names in Figma differ from project token names, token files are in an unexpected location, or the project has no token files yet.
- Solution: First search the codebase for token files. If found, map Figma variable names to project token names using `references/token-mapping-guide.md`. If no token files exist, extract tokens from Figma using `get_variable_defs` and generate token files — see `references/token-mapping-guide.md` § "Extracting Tokens from Figma".

### React Aria Hook Selection Unclear

- Error: Unsure which React Aria hook to use for a given component.
- Cause: Component type does not match a standard pattern (Button, TextField, Select, etc.).
- Solution: Check the React Aria hooks table in `rules/aria-use-react-aria-hooks.md`. For complex components, compose multiple hooks or use `useFocusRing` as a baseline.

### Generated Styles Use Raw Values

- Error: Component styles contain hardcoded pixel values or hex colors instead of tokens.
- Cause: Token mapping was skipped or incomplete during Phase 2.
- Solution: Re-run token mapping against the project's token system. Replace every raw value with its token reference. If no token exists, flag it as a gap with a `/* TODO */` comment.

### Component Props Do Not Match Figma

- Error: Generated React props do not align with Figma component properties.
- Cause: Props were assumed instead of extracted from Figma MCP.
- Solution: Re-extract using `get_design_context` and rebuild props from actual Figma component definitions. Follow naming conventions in `references/figma-property-conventions.md`.

## Workflow

1. Identify whether the request matches a Figma-to-React conversion task.
2. Follow the 8-phase workflow: extract design context, map tokens, generate props docs, build component, create styles, write story, validate, clean up.
3. Verify all output uses project tokens (no hardcoded values) and includes React Aria accessibility.
