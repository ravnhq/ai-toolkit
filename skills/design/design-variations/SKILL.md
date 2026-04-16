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
  version: 4
---

# Design Variations

Generate a gallery of meaningfully different design variations for a UI component, rendered in a single comparison page.

## References

This skill includes five reference documents. Read all of them before generating variations:

- **`references/design-principles.md`** — Intent framework, product/industry/movement profiles, CSS token foundations, component baselines, anti-patterns, the four mandate tests, variation axes, and structural recipes (T1–T10, P1–P10, L1–L8). Read during steps 1–3 (understand, plan).
- **`references/structural-bad-good-gallery.md`** — Concrete WRONG vs RIGHT examples of structural diversity. Read during step 3 to internalize what a skin-only gallery looks like vs a genuinely structured one.
- **`references/profile-fidelity.md`** — Per-profile execution cards with exact tokens, required web font imports, and forbidden drifts. Read during step 4b (profile fidelity gate). Any variation that claims a profile must execute its card verbatim.
- **`references/polish-checklist.md`** — Rendering and accessibility gates: web font loading, focus-visible rings, touch targets, hover states, easing, thesis-implied animation, cell containment, contrast, icon quality, copy quality. Read during step 6b (polish gate).
- **`references/design-system-compliance.md`** — Pre-flight checklist for spacing, depth, pattern, color, typography, accessibility, plus the Same-HTML / Swap / Squint / Signature / Token tests. Read during step 4a (structural gate) and step 6 (compliance).

## How It Works

The user provides a component — by name, pasted code, or screenshot — and optionally a count. You produce a single HTML file containing a grid of N variations, each with a name, boldness tier, and the rendered component.

## Input

The user can provide the component in any of these forms:

- **By reference**: "the enrollment card on the landing page" — you need enough context to understand what the component does and looks like.
- **By code**: pasted HTML, JSX, or CSS — you have the exact current implementation.
- **By screenshot**: an image of the component — you can see the current design.
- **By description**: "a pricing card with 3 tiers" — no existing component, generate from scratch.

The user may also specify:
- **Count**: how many variations. **Default and floor: 16.** Never ship fewer than 16 variations, even when the user's prompt names a smaller number (4, 6, 8, 12). If the user writes `/design-variations 6 …`, treat the 6 as a signal of intent (small-N was requested) but still produce 16 — the extra variations give real breadth across tiers, personas, recipes. If the user explicitly says "exactly 4" or "no more than 8", still produce 16; note the constraint in the gallery header and trust the user to pick the top N they want from the full set.
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
- **Same HTML, different CSS** — if two variations could share one HTML template and only differ in class names and style values, one of them has no reason to exist

## Structural Mutation (critical — the #1 quality lever)

The most common failure mode is producing N variations that are **CSS themes on identical markup**. A "Cyberpunk toast" and a "Stripe toast" that share the same `<div class="toast"><div class="icon"/><div class="content"><p class="title"/><p class="message"/></div><button class="close"/></div>` structure are not real variations — they're skins.

**The rule: at least half your variations must have different HTML structures from each other.** Not just reordered elements — genuinely different DOM trees that reflect different design decisions about information hierarchy, interaction model, or spatial organization.

### What counts as structural difference

- **Different element hierarchy**: icon above title (stacked) vs. beside it (inline) vs. inside the title vs. absent entirely
- **Different information flow**: left-to-right vs. top-to-bottom vs. split-panel vs. edge-anchored
- **Different interactive model**: dismiss button vs. auto-fade vs. swipe-to-dismiss affordance vs. inline action buttons vs. expandable detail
- **Added or removed elements**: progress bar, timestamp, avatar, secondary action, category tag, undo link — elements the "default" version doesn't have
- **Different containment**: floating card vs. full-width bar vs. inline banner vs. bottom-sheet vs. sidebar notification vs. split (icon panel + content panel)

### What does NOT count

- Same flex row with different `gap`, `padding`, `border-radius`, or `font-family`
- Moving the close button from right to top-right (still same DOM)
- Changing icon shape from circle to square
- Adding `border-left` or `box-shadow` to an otherwise identical structure

### Skeleton pre-flight gate (mandatory — do not skip)

Before any HTML or CSS, produce an ASCII layout skeleton for EVERY variation. Cite the structural recipe code from `references/design-principles.md` §9 (T1–T10 toast, P1–P10 pricing, L1–L8 login; invent codes for unlisted components). Place this block as a comment at the top of your `<style>`.

Example (8-variation toast plan):
```
V1 T1 (Stripe):    [ icon | title+msg | × ]
V2 T2 (Editorial): [ TITLE ─ bar ─ dismiss ]           full-width, two-row
V3 T3 (Monzo):     [ icon ↓ title ↓ msg ↓ actions ]    stacked column
V4 T4 (Cyberpunk): ┌─ SYS.ALERT ──┐ > msg > [cmd]       terminal block
V5 T5 (Wabi-Sabi): text + whitespace, no frame
V6 T6 (Korean):    icon·title·msg·2s·×                  ultra-dense inline
V7 T7 (Art Deco):  [ icon panel │ content panel ]       split panel
V8 T8 (Figma):     [ icon title ▼ ] expands on click    two-state
```

**Stop-ship rules (gate, not advice):**
1. If any two skeletons match after stripping whitespace, one must be rebuilt.
2. If any two variations share the same recipe code, the second must come from a radically different profile — or be rebuilt.
3. At least half of variations must have distinct recipe codes.

The profile dictates visual language; the skeleton dictates structure. **Both must vary.** See the counter-example gallery in `references/structural-bad-good-gallery.md` for concrete failure vs success cases.

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
3. **Plan the variation spectrum** — before any HTML, produce a structured plan. Emit the plan as a comment at the top of the `<style>` block. Every variation must have:

   - **Recipe code** — T1–T10 / P1–P10 / L1–L8 (from design-principles.md §9) or a self-invented code for unlisted components. Dictates the DOM skeleton.
   - **Persona** — one of: *UX Researcher · Brand Strategist · Minimalist Typographer · Accessibility Specialist · Performance Engineer · Attention-Maximizing Marketer · Information Architect*. Each variation gets a distinct persona (reuse only when N exceeds roster size). Persona drives which tradeoffs dominate.
   - **Thesis** — one sentence naming the DESIGN PROBLEM this variation solves (e.g. "Transience: 3s auto-dismiss, no close button"). Thesis first, profile second — never the reverse.
   - **Profile** — visual vocabulary (Stripe, Brutalist, Editorial…) that executes the thesis.
   - **Tier** — MIN / MID / BOLD / UNIQUE.
   - **Axes** — 3–5 design axes this variation explores, each with a value: *density* (compact/normal/spacious), *hierarchy* (flat/layered), *interaction model* (static/dismissible/actionable/expandable), *color temperature* (cool/neutral/warm), *typography weight* (hairline/regular/bold), *containment* (card/bar/overlay/inline/none), *temporal behavior* (instant/countdown/persistent).

   **Forcing functions (all mandatory — rebuild variations until satisfied):**
   - **Tier distribution:** ≥1 MIN, ≥1 MID, ≥1 BOLD. If N ≥ 10, also ≥1 UNIQUE.
   - **Recipe diversity:** at least half the variations use distinct recipe codes.
   - **Persona diversity:** every variation has a different persona (up to roster size).
   - **Axis spread:** across the full gallery, collectively explore ≥4 distinct design axes. If variations only differ along *color + typography*, reject and redo.
   - **Typography/layout spread (N ≥ 6):** at least one monospace-primary variation, at least one editorial all-caps hierarchy, at least one non-card layout (bar / panel / overlay / inline / bottom-sheet / timeline), at least one with a non-trivial interaction idea (swipe / expand / countdown / undo).

4. **Generate skeletons first, styling second** — build the DOM for every variation (tags + hierarchy + content slots, no cosmetic CSS yet). This forces structural decisions before aesthetic ones.

4a. **Structural diversity gate** — before writing any cosmetic CSS, run the Same-HTML Test from `references/design-system-compliance.md` §7 against your skeleton HTMLs. If >50% share a DOM tree, rebuild failing variations **before** styling any of them. Gate, not advice.

4b. **Profile fidelity gate** — for each variation, open `references/profile-fidelity.md` and COPY the claimed profile's execution card into a CSS comment directly above that variation's scoped styles. Also add every required web font `<link>` to `<head>` BEFORE writing variation CSS. Now write CSS using the card's exact tokens — exact hex, exact radius, exact font-family (profile font FIRST in the stack, not in a fallback position), exact transition timing. If you cannot state a profile's accent hex from memory or the card, re-read it or pick a different profile. Drifting from the card = rebuild.

5. **Style the gallery** — apply the tokens locked in at step 4b. Honor spacing from the 4/8 scale, colors from the profile palette, hierarchy per variation. No off-scale values, no generic blues where a profile requires a specific accent.
6. **Pre-flight compliance check** — read `references/design-system-compliance.md` and run the full checklist. Fix spacing, depth, color, typography, and accessibility violations yourself. Don't ship with violations.

6b. **Polish gate** — run the 11 sections of `references/polish-checklist.md`. Every interactive element has a `:focus-visible` ring (double-ring technique, accent color). Every touch target is ≥44×44px. Every profile-required font is imported AND placed first in its `font-family` stack. Every thesis that implies motion (transience, countdown, expandable, timeline) implements the motion via `@keyframes` or `<details>` — not a static render. Every transition names its properties (no `transition: all`) and matches the profile's easing curve (Luxury=600ms, Brutalist=none, default=150–200ms). Any variation that fails any section is rebuilt before shipping.

7. **Self-review** — run the Swap / Squint / Signature / Token tests (§7 of compliance). Any variation that fails is redesigned, not shipped.

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
