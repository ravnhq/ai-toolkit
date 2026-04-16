---
name: design-variations
description: >
  Generate a gallery of design variations for a UI component. Takes an existing
  component (referenced by name, pasted code, or screenshot) and produces N
  distinct rendered alternatives in a single comparison page. Use when exploring
  visual directions, generating mockups, comparing design approaches for a
  component, creating A/B candidates, or when anyone says "show me options" or
  "give me variations" for a UI element.
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: design
  tags:
  - design
  - variations
  - mockup
  - ui
  - components
  - exploration
  - gallery
  status: ready
  version: 1
---

# Design Variations

Generate a gallery of meaningfully different design variations for a UI component, rendered in a single comparison page.

## References

This skill includes two reference documents. Read them before generating variations:

- **`references/design-principles.md`** — Visual hierarchy, spacing scales, typography, color, depth, Gestalt principles, and what makes a variation compelling. Read this during step 1-2 (understanding and planning) so every variation is grounded in solid design.
- **`references/design-system-compliance.md`** — Pre-flight checklist for spacing, depth, patterns, color, typography, and accessibility. Read this during step 4 (self-review) and fix all violations before showing the gallery to the user.

## How It Works

The user provides a component — by name, pasted code, or screenshot — and optionally a count. You produce a single HTML file containing a grid of N variations, each with a name, boldness tier, and the rendered component.

## Input

The user can provide the component in any of these forms:

- **By reference**: "the enrollment card on the landing page" — you need enough context to understand what the component does and looks like.
- **By code**: pasted HTML, JSX, or CSS — you have the exact current implementation.
- **By screenshot**: an image of the component — you can see the current design.
- **By description**: "a pricing card with 3 tiers" — no existing component, generate from scratch.

The user may also specify:
- **Count**: how many variations (default: 6). Respect the exact number requested.
- **Constraints**: brand colors, must be mobile-friendly, accessibility requirements, specific tech stack.
- **Focus**: "vary the layout" or "try different CTAs" — narrows what should change across variations.

## Variation Strategy

This is the core of the skill. Each variation must represent a different *design thesis*, not just a different color or font. The goal is to help the user explore genuinely different approaches so they can pick a direction.

### Boldness Tiers

Distribute variations across these tiers. Label each variation with its tier in the gallery.

- **MIN** — Conservative. Small tweaks to typography, spacing, or color that preserve the original structure. Safe, production-ready feel. Include 1-2 of these.
- **MID** — Moderate reinterpretation. Different layout, information hierarchy, or interaction pattern. The component is recognizable but restructured. This is the bulk of your variations.
- **BOLD** — Aggressive departure. Different visual language entirely — glassmorphism, brutalist, illustrative, dark mode, oversized type. Pushes beyond what the user would likely try on their own. Include 1-2 of these.
- **UNIQUE** — Conceptual wildcard. Reframes what the component *is*. Adds unexpected data, changes the metaphor, or takes a completely unconventional approach. Include at most 1 of these for larger sets (10+).

The distribution should feel like a spectrum, not random. Order variations from most conservative to most experimental in the gallery.

### What Makes a Good Variation

Each variation should have a *reason to exist* — a specific design idea it's exploring. Before generating code, decide what each variation's thesis is. Examples:

- "Social proof via live activity feed" (not just "added a green dot")
- "Information density — show multiple metrics in the same footprint"
- "Minimalist — remove everything except the core number and CTA"
- "Geographic framing — recontextualize the count as global reach"

If you can't articulate why a variation is different from the others, cut it and think of a better one.

### What Makes a Bad Variation

- Two variations that only differ in color scheme
- Changing the font but keeping everything else identical
- Placeholder content that doesn't match the component's purpose
- Variations that break the component's core function (a CTA card with no CTA)

## Output

### Single-file HTML gallery

Produce one self-contained `.html` file. No external dependencies except CDN fonts if needed. The gallery page itself should be clean and functional — it's a tool, not a showcase.

Structure:
```
┌──────────────────────────────────────────────────┐
│ ComponentName — N Variations                     │
│ Description of what was varied and why           │
├────────────┬────────────┬────────────┬───────────┤
│ 1. Name    │ 2. Name    │ 3. Name    │ 4. Name   │
│ TIER       │ TIER       │ TIER       │ TIER      │
│            │            │            │           │
│ [rendered  │ [rendered  │ [rendered  │ [rendered │
│  component]│  component]│  component]│  componen]│
│            │            │            │           │
└────────────┴────────────┴────────────┴───────────┘
```

### Gallery requirements

- **Grid layout**: responsive, 2-4 columns depending on component size. Each cell has a light gray background (#f5f5f5) to frame the variation.
- **Labels**: each cell shows the variation number, name, and boldness tier.
- **Header**: component name, variation count, and a one-line description of the brief.
- **Self-contained**: all CSS inline or in a `<style>` block. No external stylesheets except font imports.
- **Consistent sizing**: all variation cells should be the same dimensions so comparison is easy.

### Cell structure (critical — prevents label overlap)

Each gallery cell MUST use a structural layout with the label/header area physically separated from the component preview area. Never use absolute positioning for labels — the component will overflow into them.

```html
<div class="variation-cell">
  <!-- HEADER: fixed structural area, not overlaid -->
  <div class="variation-header">
    <span class="variation-name">1. Precision Standard</span>
    <span class="variation-tier">MIN</span>
  </div>
  <!-- PREVIEW: bounded area for the component -->
  <div class="variation-preview">
    <!-- rendered component goes here -->
  </div>
</div>
```

```css
.variation-cell {
  display: flex;
  flex-direction: column;
  background: #f5f5f5;
  border-radius: 8px;
  overflow: hidden;
}
.variation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid #e5e7eb;
  background: #fff;
  flex-shrink: 0; /* never collapse */
}
.variation-name {
  font-size: 13px;
  font-weight: 600;
  color: #374151;
}
.variation-tier {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 2px 8px;
  border-radius: 4px;
  background: #f3f4f6;
  color: #6b7280;
}
.variation-preview {
  padding: 24px;
  overflow: hidden; /* safety net */
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}
```

This structure guarantees the label is always visible regardless of component height. Do NOT use `position: absolute` for labels — it causes components to overlap titles.

### Component containment (critical)

This is the most common failure mode. The component variations MUST fit inside their gallery cells without overflow. The gallery is a comparison tool — if components overflow, clip, or break their cells, the gallery is useless.

**Size the grid to the component, not the other way around.** Before writing CSS:

1. Estimate the rendered width of the largest variation. A 3-column pricing card needs ~800-1000px. A single toast needs ~360px. A login form needs ~400px.
2. Set `grid-template-columns` based on that width. If the component needs 800px+, use a single column or `repeat(auto-fit, minmax(800px, 1fr))`. If it's a small component like a toast (300-400px), you can fit 2-3 per row.
3. Never use `minmax(320px, 1fr)` as a default — that assumes small components. Match the minimum to the component's actual needs.

**Rules:**
- Every variation must render completely within its cell. No horizontal overflow, no clipped content, no scrollbars.
- If a variation uses an internal multi-column layout (like 3 pricing tiers side by side), the cell must be wide enough to hold all columns at readable sizes.
- Set `overflow: hidden` on cells as a safety net, but design the grid so it's never triggered.
- Test mentally: "If I open this at 1400px viewport width, does every variation have enough room?" If not, reduce columns or increase minimums.

**Gallery column guide by component type:**

| Component type | Min cell width | Columns at 1400px |
|---|---|---|
| Small (toast, badge, pill, single CTA) | 360px | 3 |
| Medium (single card, form, single-column) | 480px | 2 |
| Wide (multi-column card, comparison table, nav bar) | 700px+ | 1-2 |
| Full-width (hero, pricing with 3+ tiers) | 900px+ | 1 |

For wide/full-width components, a 1-column gallery is fine. The user compares by scrolling vertically, which is better than seeing broken layouts.

### Rendering the variations

Each variation is rendered as actual HTML/CSS inside its cell — not a description or a mockup image. The user should see the component as it would appear in a browser.

**Design each variation to fit its cell.** Don't build a component at its "ideal" full-page width and hope it fits. Build it to work within the cell dimensions you chose. If the cell is 480px wide, the component layout should work at 480px. If a variation's thesis requires a wide layout (3-column pricing), either give it a full-width cell or adapt the layout to stack vertically at the cell width.

Use realistic content that matches the component's purpose. If the original shows "3,151 enrolled", keep similar data across variations so the user is comparing design, not content.

### File naming

Save as `{component-name}-variations.html` in the working directory. Use kebab-case. Example: `enrollment-card-variations.html`

## Workflow

1. **Understand the component**: read the reference, code, or screenshot. Identify its purpose, key data, and primary action. Read `references/design-principles.md` to ground your design thinking.
2. **Identify design system constraints**: if the user referenced a design system, brand, or existing codebase, extract the palette, spacing scale, font stack, border-radius scale, and shadow strategy. These constrain all variations. If no system was specified, use the defaults from the design principles reference.
3. **Plan the variation spectrum**: before writing any HTML, list each variation by name, tier, and thesis (1 sentence each). Use the variation dimensions from the design principles (hierarchy, density, interaction model, visual metaphor, data framing, CTA treatment) to ensure you're exploring different axes, not the same one repeatedly. Write this plan as a comment at the top of the HTML file.
4. **Generate the gallery**: build the single HTML file with all variations rendered in the grid. Apply the design principles throughout — spacing from the scale, colors from a coherent palette, proper hierarchy in every variation.
5. **Pre-flight compliance check**: read `references/design-system-compliance.md` and run the full checklist against every variation. Fix all violations before presenting. Check spacing (multiples of 4/8), depth consistency (don't mix borders and shadows), color compliance (no random hex, no pure black text, contrast ratios), typography (from the type scale), and accessibility (contrast, touch targets). Fix violations yourself — don't wait for the user to catch them.
6. **Self-review**: verify that variations are genuinely different from each other (not just color swaps), that the tier distribution is correct, and that all variations preserve the component's core function.

## Examples

### Positive Trigger

User: "/design-variations 20 The bottom right card that shows how many people have enrolled in the class on the landing page."

Expected behavior: Generate a single HTML file with 20 enrollment card variations distributed across MIN/MID/BOLD/UNIQUE tiers, ordered from conservative to experimental.

### Positive Trigger: Code Input

User: "Here's my pricing component: [pasted JSX]. Give me 6 variations."

Expected behavior: Parse the JSX, understand the pricing card structure, generate 6 variations preserving the pricing data but exploring different layouts and visual treatments.

### Positive Trigger: Screenshot

User: [screenshot of a nav bar] "Show me 8 different takes on this."

Expected behavior: Analyze the screenshot, identify the nav bar structure and elements, generate 8 variations.

### Non-Trigger

User: "Fix the CSS on my button — it's not centering properly."

Expected behavior: Do not use this skill. This is a bug fix, not a design exploration.

## Troubleshooting

### Variations all look the same

- Error: Generated variations only differ in superficial ways (color, font size)
- Cause: Skipped the planning step or planned without distinct theses
- Solution: Go back to step 2 of the workflow. Write out each variation's thesis. If two theses sound similar, merge them and think of a new one.

### Components overflow their gallery cells

- Error: Variations are clipped, overlapping, or extending outside their grid cells
- Cause: Grid cells are too narrow for the component's natural width. A 3-column pricing card needs ~900px but the grid cell is 320px.
- Solution: Size the grid to the component. Read the "Component containment" section above. Use the column guide table. For wide components (pricing cards, nav bars, comparison tables), use 1-column layout. Never default to `minmax(320px, 1fr)`.

### Gallery doesn't render correctly

- Error: HTML file shows broken layout or overlapping components
- Cause: Variation CSS is leaking between cells
- Solution: Scope all variation styles. Use unique class prefixes per variation (e.g., `.v1-card`, `.v2-card`) or use CSS containment.

### User says "I want more like #4 but different"

- Error: Not really an error — the user picked a direction and wants to go deeper
- Cause: Normal design workflow
- Solution: Take variation #4 as the new baseline and run the skill again with that specific variation as input. Narrow the variation focus to whatever made #4 appealing.
