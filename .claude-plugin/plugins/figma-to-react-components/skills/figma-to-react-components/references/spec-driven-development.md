# Spec-Driven Component Development

A structured workflow for building React components from Figma designs using the Figma MCP, React Aria, and your project's design token system.

---

## Prerequisites

- [ ] Figma MCP server configured and running
- [ ] React and React Aria installed
- [ ] Design token system available (SCSS, CSS vars, Tailwind, or JS tokens)
- [ ] Storybook configured (optional but recommended)

---

## Development Workflow

### Phase 1: Design Discovery

**Objective:** Extract component specifications from Figma using MCP.

#### Steps:

1. **Identify Component in Figma**
   - Component name: `[COMPONENT_NAME]`
   - Figma file/node ID: `[FIGMA_NODE_ID]`

2. **Extract Component Properties via Figma MCP**

   ```
   Use Figma MCP to retrieve the following for [COMPONENT_NAME]:
   - Component variants and properties
   - Spacing/layout specifications
   - Color tokens and references
   - Typography styles
   - Interactive states (hover, focus, active, disabled)
   - Accessibility requirements
   - Always refer to project token variables, never raw values

   Prop Naming Conventions:
   - Use lowerCamelCase for all prop names
   - Remove emojis from Figma property names in code
   - Single text element → use 'children' prop
   - Multiple text elements → use named props (title, supportingText, etc.)
   ```

3. **Document Extracted Specifications**

   **Visual Properties:**
   - Colors: `[List color tokens from Figma]`
   - Typography: `[Font family, sizes, weights]`
   - Spacing: `[Padding, margins, gaps]`
   - Border radius: `[Values]`
   - Shadows/effects: `[If applicable]`

   **Component Variants:**
   - Variant 1: `[name]` - `[description]`
   - Variant 2: `[name]` - `[description]`

   **Interactive States:**

   > The states listed below are EXAMPLES ONLY. Build component props based on what you extract from the Figma MCP. Not all components follow this exact structure. Always read the component properties directly from Figma via MCP.

   Common states (for reference, not prescriptive):
   - Default
   - Hover
   - Focus
   - Active
   - Disabled (often treated as a boolean prop)
   - Loading (if applicable)

   **Icons and Assets:**
   - Use your project's icon library per its conventions
   - For components with image fills: Use a project placeholder image or leave configurable via props
   - Add Storybook props for image/video URLs only if the component contains media fill layers

   **Accessibility Requirements:**
   - React Aria hook and attributes needed
   - Keyboard navigation support
   - Screen reader considerations

---

### Phase 2: Technical Specification

**Objective:** Define the component API and implementation approach.

#### Token Mapping

Map Figma tokens to your project's token system (see `references/token-mapping-guide.md`):

```
// Example mapping — adapt to your token format
Figma "color/action/primary/default"  →  [your-token: action-primary-bg]
Figma "spacing/md"                    →  [your-token: spacing-md]
Figma "radius/md"                     →  [your-token: radius-md]
```

#### React Aria Integration

**Selected React Aria Hook:** `[e.g., useButton, useTextField, useSelect]`

**Rationale:** `[Why this hook provides the needed accessibility and interaction patterns]`

---

### Phase 3: Implementation Specification

**Objective:** Create implementation plan with clear acceptance criteria.

#### File Structure

```
[project-components-dir]/
  [ComponentName]/
    [ComponentName].tsx
    [ComponentName].[scss|module.scss|css]
    index.ts
[project-stories-dir]/
  [ComponentName].stories.tsx
```

#### Implementation Requirements

1. **Component Structure**
   - React functional component with TypeScript
   - React Aria hook for accessibility
   - Support all variants defined in Figma
   - Handle all interactive states

2. **Styling Requirements**
   - Import tokens from your project's token system
   - Use BEM naming for CSS classes (or project convention)
   - Implement responsive behavior if defined in Figma
   - Support theming through token references

3. **Accessibility Requirements**
   - Keyboard navigation support
   - Proper ARIA attributes via React Aria
   - Focus management with `:focus-visible`
   - Screen reader compatibility
   - Minimum touch target size (44x44px)

4. **Acceptance Criteria**
   - [ ] Component matches Figma design (within 2px tolerance)
   - [ ] All variants render correctly
   - [ ] All interactive states work as expected
   - [ ] Keyboard navigation functions properly
   - [ ] Screen reader announces component correctly
   - [ ] Storybook story includes all variants and states
   - [ ] TypeScript types are properly defined
   - [ ] Component is properly exported

---

### Phase 4: Implementation

**Objective:** Build the component following the specification.

#### Implementation Steps

1. Use Figma MCP to retrieve detailed design specifications for `[COMPONENT_NAME]`
2. Create `[ComponentName].tsx` with:
   - TypeScript interface matching the API spec
   - React Aria hook implementation
   - All variants and states from Figma
   - Proper prop handling and defaults
3. Create styles file with:
   - Token imports from your project's system
   - Styles for all variants
   - Styles for all interactive states
   - Responsive styles if needed
4. Create `index.ts` for clean exports
5. Ensure accessibility:
   - Keyboard navigation
   - ARIA attributes via React Aria
   - Focus management
   - Semantic HTML

---

### Phase 5: Storybook Documentation

**Objective:** Create comprehensive Storybook stories for documentation and testing.

#### Story Structure

```typescript
import type { Meta, StoryObj } from '@storybook/react';
import { ComponentName } from '[project-components-path]/ComponentName';

const meta: Meta<typeof ComponentName> = {
  title: 'Components/ComponentName',
  component: ComponentName,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
  argTypes: {
    // Define controls for each prop
  },
};

export default meta;
type Story = StoryObj<typeof meta>;

// Stories to include:
// - Default
// - All variants
// - All sizes
// - Interactive states
// - Disabled state
// - Loading state (if applicable)
// - With custom content
// - Accessibility testing story
```

---

## Quality Checklist

Before marking a component as complete:

- [ ] Figma design specifications extracted via MCP
- [ ] Component implements all Figma variants
- [ ] Token references correctly imported from project system
- [ ] React Aria integration implemented
- [ ] All interactive states working
- [ ] TypeScript types properly defined
- [ ] Component is fully accessible
- [ ] Storybook story created with all variants
- [ ] All acceptance criteria met
- [ ] Component tested in isolation
- [ ] No hardcoded values — all visual properties use tokens
- [ ] Documentation is complete

---

## Usage

To use this workflow for each new component:

1. Copy the relevant phase sections
2. Fill in `[PLACEHOLDER]` values with component-specific information
3. Use Figma MCP to extract design specifications
4. Follow each phase sequentially
5. Validate against the quality checklist
