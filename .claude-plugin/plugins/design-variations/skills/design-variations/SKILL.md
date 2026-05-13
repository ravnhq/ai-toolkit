---
name: design-variations
description: 'Generate a gallery of design variations for a UI component. Takes an
  existing component (referenced by name, pasted code, or screenshot) and produces
  N distinct rendered alternatives in a single comparison page. Use when exploring
  visual directions, generating mockups, comparing design approaches for a component,
  creating A/B candidates, or when anyone says "show me options" or "give me variations"
  for a UI element.

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
- WebFetch
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
  version: 11
---

# Design Variations

Generate a gallery of meaningfully different design variations for a UI component, rendered in a single comparison page.

## References

This skill includes twelve reference documents. Read all of them before generating variations:

- **`references/design-principles.md`** — Intent framework, profiles, tokens, baselines, mandate tests, axes, recipes (T1–T10, P1–P10, L1–L8). Steps 1–3.
- **`references/structural-bad-good-gallery.md`** — WRONG vs RIGHT structural diversity examples. Step 3.
- **`references/profile-fidelity.md`** — Per-profile execution cards (tokens, font imports, forbidden drifts). Movement profiles + 50+ brand-inspired profiles from MIT-licensed VoltAgent/awesome-design-md. Step 4b.
- **`references/component-recipes-extended.md`** — Recipes for nav (N1–N8), hero (H1–H8), modal (M1–M6), table (TB1–TB6), card (D1–D6), sidebar (SB1–SB6), form (F1–F6), footer (FT1–FT4). Step 3 for non-toast/pricing/login components.
- **`references/agent-prompt-cheatsheet.md`** — Per-profile example prompts. Optional, step 2.
- **`references/font-substitutes.md`** — Licensed font → free web-font mapping. Step 4b.
- **`references/polish-checklist.md`** — Rendering/accessibility gates: focus rings, touch targets, easing, animation, contrast, i18n, reduced motion. Step 6b.
- **`references/design-system-compliance.md`** — Compliance checklist + Same-HTML / Swap / Squint / Signature / Token / Evidence / Upstream tests. Steps 4a, 6.
- **`references/state-matrix.md`** — State coverage + sub-cell pattern + `@container` responsive strip. Steps 3, 5.
- **`references/ingestion-cascade.md`** — URL/repo/prose cascade producing the `brief` object; sanitization, `WebFetch` hardening, error fallback. Step 2a.
- **`references/control-surface.md`** — `<details>/<summary>` disclosure, 8 prompt templates, trailing chat echo. Step 8.

### Attribution

Brand-inspired profile cards in `profile-fidelity.md` are distilled from **VoltAgent/awesome-design-md** (MIT, getdesign.md). Each card cites its upstream slug. These cards claim inspiration from public brands, not affiliation. If a user provides a `getdesign.md/<slug>/design-md` URL as a reference, treat it as authoritative for that variation (see "DESIGN.md mode" below).

## How It Works

The user provides a component — by name, pasted code, or screenshot — and optionally a count. You produce a single HTML file containing a grid of N variations, each with a name, boldness tier, and the rendered component.

## Input

The user can provide the component in any of these forms:

- **By reference**: "the enrollment card on the landing page" — you need enough context to understand what the component does and looks like.
- **By code**: pasted HTML, JSX, or CSS — you have the exact current implementation.
- **By screenshot**: an image of the component — you can see the current design.
- **By description**: "a pricing card with 3 tiers" — no existing component, generate from scratch.
- **By live URL**: "the pricing card on https://stripe.com/pricing" — triggers the ingestion cascade (step 2a) which pulls real copy, colors, and fonts from the page.

The user may also specify:
- **Output mode**: `--output=file`, `--output=artifact`, or `--output=both` to override auto-detection (see workflow step 7).
- **Count**: how many variations. **Default and floor: 16.** Never ship fewer than 16 variations, even when the user's prompt names a smaller number (4, 6, 8, 12). If the user writes `/design-variations 6 …`, treat the 6 as a signal of intent (small-N was requested) but still produce 16 — the extra variations give real breadth across tiers, personas, recipes. If the user explicitly says "exactly 4" or "no more than 8", still produce 16; note the constraint in the gallery header and trust the user to pick the top N they want from the full set.
- **Constraints**: brand colors, must be mobile-friendly, accessibility requirements, specific tech stack.
- **Focus**: "vary the layout" or "try different CTAs" — narrows what should change across variations.

## User Context Frame (do this before planning variations)

Before any thesis-writing, answer three questions in a comment block at the top of the file. These anchor every variation to a real user decision, not visual novelty.

1. **Primary user archetype** — one of: First-Time / Returning / Power / Skeptic / Time-Pressed / Low-Bandwidth / Screen-Reader / Anonymous. Pick the most likely primary; secondary archetypes surface in per-variation personas.
2. **Job-to-be-done** — one sentence. E.g., "Decide whether to upgrade from Free to Pro in under 30 seconds."
3. **Known constraint** — one evidence source: research finding, heuristic, competitor reference, or the literal string `ASSUMPTION` if none. Don't fabricate research.

Every variation's thesis (step 3) must reference at least one of these three. Theses that can't are rebuilt.

## Brand Token Input (optional)

The skill has two modes:

- **Free-form mode** (default): no brand system provided. Profiles override freely. All 16 variations are exploratory.
- **Project-bound mode**: when invoked inside a project repo, scan for an existing design system before generating. Look for (in order): `tailwind.config.*`, `tokens.{json,css,ts}`, `theme.{json,css,ts}`, `:root { --... }` blocks in global stylesheets, `styled-system` config, shadcn/ui `components.json` + CSS vars. If found, extract: primary color, neutral scale, radius scale, font-family, spacing base. If multiple systems coexist (e.g. a storybook + a partial tailwind), ask the user which one is authoritative. If no system is detectable, fall back to free-form.

Can also be provided inline — the user may paste a token block (JSON, CSS vars, or prose: "brand red #D4201F, radius 2px, Inter"). Inline input overrides any auto-detection.

**DESIGN.md mode** (brand-inspired override): when the user references a `getdesign.md/<slug>/design-md` URL, names an upstream-available brand ("make it look like Claude / Supabase / Warp"), or points at a local `DESIGN.md` file in the repo, treat that source as the authoritative brand system. Open the matching card in `references/profile-fidelity.md` and, if the upstream file is newer or more complete, fetch `https://getdesign.md/design-md/<slug>/DESIGN.md` for up-to-date tokens. Gate the gallery the same as project-bound mode: ≥8 on-system variations using those tokens, remainder off-system with the divider.

**When tokens are present, segregate the gallery into two sections:**

1. **On-system variations** (≥8 of the 16): MIN + MID tier. Honor the extracted tokens. These are production-viable.
2. **Off-system variations** (the remaining BOLD + UNIQUE): rendered below a divider labeled `OFF-SYSTEM — exploratory, not brand-compliant`. Free to deviate. These stretch the stakeholder's imagination without pretending to be shippable.

Rendered in the HTML as two `<section>` blocks with clear header separation. The decision matrix (below) stays single-table across both.

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

Produce one self-contained HTML document. No external dependencies except CDN fonts if needed. The gallery is a tool, not a showcase — functional first.

**Delivery mode is auto-detected at step 7** (hybrid): in a Claude Code / repo context, the HTML is written to disk **and** returned inline; in Claude Desktop / Cowork / anywhere without a repo, it's returned as an inline artifact only. The content of the HTML is identical in both cases.

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
    <div class="variation-title-row">
      <span class="variation-name">1. Precision Standard</span>
      <span class="variation-tier">MIN</span>
    </div>
    <span class="variation-question">Do users want the price or the value-prop first?</span>
  </div>
  <!-- PREVIEW: bounded area for the component -->
  <div class="variation-preview">
    <!-- rendered component goes here -->
  </div>
  <!-- FOOTER: tradeoff strip + weakness -->
  <div class="variation-footer">
    <span class="variation-tradeoff">
      <b>Gains:</b> scannability · <b>Costs:</b> depth · <b>Best for:</b> Time-Pressed
    </span>
    <span class="variation-weakness" title="Fails at >5 features">⚠ weakness</span>
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
.variation-title-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.variation-question {
  display: block;
  margin-top: 4px;
  font-size: 12px;
  font-style: italic;
  color: #6b7280;
  line-height: 1.4;
}
.variation-footer {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
  padding: 10px 16px;
  border-top: 1px solid #e5e7eb;
  background: #fafafa;
  font-size: 11px;
  color: #4b5563;
  flex-shrink: 0;
}
.variation-tradeoff b { font-weight: 600; color: #111827; }
.variation-weakness {
  color: #9ca3af;
  cursor: help;
  white-space: nowrap;
}
```

This structure guarantees the label is always visible regardless of component height. Do NOT use `position: absolute` for labels — it causes components to overlap titles.

### Decision matrix (required)

Above the gallery grid, render a compact `<table class="decision-matrix">` with one row per variation and columns: **#**, **Name**, **User persona**, **Register**, **Question**, **Tradeoff**, **Tier**. A stakeholder should be able to shortlist 3 finalists from this table alone without scrolling through renderings. Keep it visually quiet — small type, no heavy borders. It is the second most important artifact in the gallery, after the renders themselves.

### Off-system segregation (project-bound mode only)

When brand tokens were provided or auto-detected, split the gallery into two `<section>` blocks with clear header separation:

```html
<section class="gallery-on-system">
  <h2>On-system variations — brand-compliant</h2>
  <!-- MIN + MID variations using extracted tokens -->
</section>

<hr class="gallery-divider">

<section class="gallery-off-system">
  <h2>Off-system — exploratory, not brand-compliant</h2>
  <p class="gallery-off-system-note">These deviate from the detected design system. Use as conceptual fuel, not as shippable candidates.</p>
  <!-- BOLD + UNIQUE variations -->
</section>
```

The decision matrix stays a single table across both sections.

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

When writing to disk (repo context or `--output=file|both`), save as `{component-name}-variations.html` in the working directory. Use kebab-case. Example: `enrollment-card-variations.html`. Artifact-only deliveries skip the filename.

## Workflow

1. **Understand the component**: read the reference, code, or screenshot. Identify its purpose, key data, and primary action. Read `references/design-principles.md` to ground your design thinking.

2a. **Ingestion preflight** — run the cascade defined in `references/ingestion-cascade.md` to produce the `brief` object. Priority order (first available wins; later sources merge missing fields):

- **Live URL** — if the user named one, call `WebFetch` with a 10s timeout. Accept only `text/html` / `application/xhtml+xml` content types. On failure, record `url: unavailable (<reason>)` and fall through.
- **Repo scan** — existing token detection (tailwind/tokens/theme/:root), plus `rg` over `**/*.mdx` and `**/*.md` for marketing copy when the component has an inferable path.
- **Prose brief** — inline user-provided voice, tone, strings, colors.

   **Sanitization is a hard gate, not a suggestion.** All scraped strings render into text nodes only (escape `&`, `<`, `>`, `"`, `'`); never emit via unescaped interpolation into an attribute, `<script>`, `<style>`, or event handler. Colors pass `^#[0-9a-fA-F]{3,8}$` | `^rgba?\(...\)$`. Font-families pass an allowlist (web-safe + the profile-fidelity catalog + `font-substitutes.md`). Image URLs must be `https://` absolute; `javascript:`, `data:`, and relative URLs are dropped.

   **Provenance is visible**, not buried. The gallery header renders a source banner: `Brief source: stripe.com/pricing (URL) + tokens.css (repo) + brief (prose)`. The structured `brief` JSON also lives in an HTML comment above the gallery.

2. **Fill the User Context Frame and detect brand tokens**:
   - Answer the three User Context Frame questions (archetype, JTBD, known constraint). Put them in a comment block at the top of the file.
   - If invoked inside a project repo, scan for a design system (see "Brand Token Input" above). If found, extract tokens and enter project-bound mode with on-system/off-system segregation. If the user pasted a token block inline, use that. If nothing is available, stay in free-form mode.
   - If no system is specified anywhere, use the defaults from the design principles reference.
3. **Plan the variation spectrum** — before any HTML, produce a structured plan. Emit the plan as a comment at the top of the `<style>` block. Every variation must have:

   - **Recipe code** — T1–T10 / P1–P10 / L1–L8 (from design-principles.md §9) or a self-invented code for unlisted components. Dictates the DOM skeleton.
   - **User persona** — who this variation serves: First-Time / Returning / Power / Skeptic / Time-Pressed / Low-Bandwidth / Screen-Reader / Anonymous. Drives WHICH tradeoff is acceptable (e.g., Skeptic tolerates density for comparison; Time-Pressed does not).
   - **Design persona** — the maker's lens: *UX Researcher · Brand Strategist · Minimalist Typographer · Accessibility Specialist · Performance Engineer · Attention-Maximizing Marketer · Information Architect*. Drives HOW the variation is built.
   - **Thesis** — one sentence naming the DESIGN PROBLEM this variation solves, grounded in the User Context Frame (e.g. "Skeptics need a side-by-side feature matrix, not marketing copy"). Thesis first, profile second — never the reverse.
   - **Question** — the decision this variation forces the stakeholder to make. One interrogative sentence. E.g., "Do users want the price or the value-prop first?" or "Is auto-dismiss acceptable for critical alerts?" Rendered in the cell header under the variation name, in italics.
   - **Profile** — visual vocabulary (Stripe, Brutalist, Editorial…) that executes the thesis.
   - **Tier** — MIN / MID / BOLD / UNIQUE.
   - **Register** — copy voice: Plain / Technical / Playful / Terse / Authoritative / Apologetic. Drives CTA verb, error tone, value-prop phrasing. Must cohere with the profile (Brutalist+Playful = incoherent; rebuild).
   - **Tradeoff** — `Gains: <noun phrase> · Costs: <noun phrase>`. Rendered in the cell footer. E.g., `Gains: scannability · Costs: depth`.
   - **Evidence** — one of: `research:<source>` / `heuristic:<name>` / `competitor:<product>` / `anti-pattern-avoidance` / `ASSUMPTION`. Never blank. "Looks cool" is not evidence.
   - **Weakness** — one sentence of honest self-critique: where this variation fails. E.g., "Fails at >5 features"; "Requires premium font license"; "Assumes desktop viewport". Rendered as cell footnote or `title` tooltip.
   - **Axes** — 3–5 design axes this variation explores, each with a value: *density* (compact/normal/spacious), *hierarchy* (flat/layered), *interaction model* (static/dismissible/actionable/expandable), *color temperature* (cool/neutral/warm), *typography weight* (hairline/regular/bold), *containment* (card/bar/overlay/inline/none), *temporal behavior* (instant/countdown/persistent).

   **Forcing functions (all mandatory — rebuild variations until satisfied):**
   - **Tier distribution:** ≥1 MIN, ≥1 MID, ≥1 BOLD. If N ≥ 10, also ≥1 UNIQUE.
   - **Recipe diversity:** at least half the variations use distinct recipe codes.
   - **Design-persona diversity:** be aggressively brainstormy. Every variation uses a different design persona (up to roster size). When N exceeds the roster, invent new design personas (e.g., *Data Journalist*, *Conversion Copywriter*, *Motion Designer*, *System Librarian*, *Zine Maker*) rather than reusing.
   - **User-persona diversity:** cover ≥4 distinct user personas across the gallery. No single user persona dominates more than 40% of variations.
   - **Register diversity:** use ≥3 distinct copy registers across the gallery. Two variations with the same register + same tier is a signal to rebuild one.
   - **Question diversity:** no two variations ask the same stakeholder question. If they do, one is redundant.
   - **Axis spread:** across the full gallery, collectively explore ≥4 distinct design axes. If variations only differ along *color + typography*, reject and redo.
   - **Typography/layout spread (N ≥ 6):** at least one monospace-primary variation, at least one editorial all-caps hierarchy, at least one non-card layout (bar / panel / overlay / inline / bottom-sheet / timeline), at least one with a non-trivial interaction idea (swipe / expand / countdown / undo).

4. **Generate skeletons first, styling second** — build the DOM for every variation (tags + hierarchy + content slots, no cosmetic CSS yet). This forces structural decisions before aesthetic ones.

4a. **Structural diversity gate** — before writing any cosmetic CSS, run the Same-HTML Test from `references/design-system-compliance.md` §7 against your skeleton HTMLs. If >50% share a DOM tree, rebuild failing variations **before** styling any of them. Gate, not advice.

4b. **Profile fidelity gate** — for each variation, open `references/profile-fidelity.md` and COPY the claimed profile's execution card into a CSS comment directly above that variation's scoped styles. Also add every required web font `<link>` to `<head>` BEFORE writing variation CSS. Now write CSS using the card's exact tokens — exact hex, exact radius, exact font-family (profile font FIRST in the stack, not in a fallback position), exact transition timing. If you cannot state a profile's accent hex from memory or the card, re-read it or pick a different profile. Drifting from the card = rebuild.

5. **Style the gallery — rich cells with static state matrix + `@container` responsive strip.** Apply tokens locked at step 4b. Honor the 4/8 spacing scale, profile palette, per-variation hierarchy. No off-scale values, no generic blues where a profile mandates an accent.

   Each variation cell now renders:
   - **State sub-cells**: the states each variation declared in step 3 (e.g., `states: [default, hover, error]`), side-by-side, each with its own DOM tree. No tabs, no JS, no `:checked` hacks. Loading skeletons, error layouts, and empty states get genuinely different markup when needed. See `references/state-matrix.md` for the sub-cell pattern.
   - **Responsive strip**: three side-by-side wrappers with `container-type: inline-size` and fixed widths `360px` / `768px` / `1280px`. Variation CSS MUST use `@container` queries for viewport-based layout, NEVER viewport `@media`. Allowed `@media` exceptions: `prefers-reduced-motion`, `prefers-color-scheme`, `prefers-contrast`, `print`. The polish checklist lints the prohibited subset.
6. **Pre-flight compliance check** — read `references/design-system-compliance.md` and run the full checklist. Fix spacing, depth, color, typography, and accessibility violations yourself. Don't ship with violations.

6b. **Polish gate** — run the 11 sections of `references/polish-checklist.md`. Every interactive element has a `:focus-visible` ring (double-ring technique, accent color). Every touch target is ≥44×44px. Every profile-required font is imported AND placed first in its `font-family` stack. Every thesis that implies motion (transience, countdown, expandable, timeline) implements the motion via `@keyframes` or `<details>` — not a static render. Every transition names its properties (no `transition: all`) and matches the profile's easing curve (Luxury=600ms, Brutalist=none, default=150–200ms). Any variation that fails any section is rebuilt before shipping.

7. **Output delivery — hybrid, context-detected.** Decide file-vs-artifact:

   - If `$CLAUDECODE` is set **or** `git rev-parse --show-toplevel` succeeds in the CWD: write `{component-name}-variations.html` to CWD **and** return the same HTML inline for artifact preview. Existing CI/file-attachment workflows keep working.
   - Otherwise (Desktop / Cowork / no repo): return HTML inline only, no file write.
   - User override via `--output=file` / `--output=artifact` / `--output=both` always wins.

8. **Control surface — artifact-as-tool.** Render iteration controls using native `<details>`/`<summary>` disclosure — zero JS, CSP-safe, keyboard-accessible. See `references/control-surface.md` for markup and the 8 prompt templates.

   - **Per-cell action strip** (below the footer of each variation): four `<details>` buttons — `⟳ More like this`, `🔀 Remix with…`, `🔒 Lock tokens`, `⭐ Pin`. Opening reveals a `<textarea readonly>` pre-filled with a template-interpolated prompt. User selects + copies + pastes.
   - **Top-of-gallery toolbar**: `Merge pinned finalists`, `Regenerate off-system only`, `Replace ingestion source`, `Export finalists`.
   - **Trailing chat echo**: after emitting the artifact, print 3–4 short prompt suggestions as chat text (e.g., *"Try: Remix #4 with Brutalist profile"*). Hedges against any sandbox quirks with textarea copy.

9. **Self-review** — run the Swap / Squint / Signature / Token / Evidence tests (§7 of compliance). Verify every variation has a non-empty Question, Tradeoff, Register, Evidence, and Weakness field rendered in its cell. Verify the decision matrix is present and complete. Verify the source banner (ingestion provenance) is visible in the header. Verify no viewport `@media` in variation CSS — all responsive behavior goes through `@container`. Verify no inline event handlers (`onclick=`, `onload=`) and no `<script>` tags. In project-bound mode, verify on-system/off-system segregation. Any variation that fails any of these is redesigned, not shipped.

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
