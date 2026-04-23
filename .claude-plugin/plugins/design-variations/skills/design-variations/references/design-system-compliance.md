# Design System Compliance Check

Run this checklist on every variation before showing work to the user. Fix violations yourself — don't wait for the user to catch them.

This check has three modes:

- **With a design system**: the user provided brand colors, spacing rules, component patterns, or a reference to an existing system. Check against those constraints.
- **Without a design system**: no system was provided. Check against the defaults in `design-principles.md` to ensure internal consistency.
- **Upstream DESIGN.md mode**: the variation claims a brand-inspired profile (e.g. `claude`, `supabase`, `airbnb`, `tesla`). Check against the profile's card in `profile-fidelity.md` AND — if you want the strictest gate — against the canonical upstream at `https://getdesign.md/design-md/<slug>/DESIGN.md`. The card's `Accent`, `Background`, `Radius`, `Shadow`, and `Button` fields must appear byte-identical in the variation's CSS. A generic blue where the card says `#D97757` = rebuild.

---

## 1. Spacing Check

**If the user specified a spacing scale or grid**, verify against it.
**Otherwise**, verify against the default 4/8px base scale.

- [ ] All spacing values are multiples of 4px (4, 8, 12, 16, 20, 24, 32, 48, 64)
- [ ] No arbitrary values like 5px, 7px, 13px, 17px, 22px
- [ ] Padding is symmetrical unless the asymmetry is intentional and visible
  - Buttons: horizontal padding >= vertical padding (e.g., `10px 20px`, not `20px 10px`)
  - Cards: equal padding on all sides unless a specific layout justifies otherwise
- [ ] Spacing between related elements (label+value, icon+text) is tighter than spacing between groups
- [ ] Consistent gap values within the same component across all variations

**Common violations:**
```css
/* Bad — arbitrary values */
padding: 15px 23px;
margin-bottom: 11px;
gap: 7px;

/* Good — on the scale */
padding: 16px 24px;
margin-bottom: 12px;
gap: 8px;
```

---

## 2. Depth Check

Determine which depth strategy the variation uses, then verify consistency.

### Borders-only strategy
- [ ] No `box-shadow` except subtle rings (`0 0 0 1px rgba(...)`)
- [ ] Border colors are from the neutral palette (grays), not random hex
- [ ] Border widths are consistent (1px for separators, 2-3px for accents)

### Subtle shadows strategy
- [ ] Single-layer shadows only (one `box-shadow` value, not stacked)
- [ ] Shadow offset is downward (Y > 0), not centered (`0 0 Xpx`)
- [ ] Shadow blur is proportional to offset (blur >= 2x offset)
- [ ] No borders competing with shadows on the same element (pick one)

### Layered shadows strategy
- [ ] Multiple shadow layers are consistent across elements at the same elevation
- [ ] Outer layer is softer/wider, inner layer is tighter/darker
- [ ] Not mixing layered shadows with hard borders

### Within one variation
- [ ] Only one depth strategy is used (don't mix borders-only on some elements and shadows on others in the same card)

---

## 3. Pattern Check

**If the user referenced a design system or existing components**, check pattern consistency:

- [ ] Button styles match the referenced system (shape, padding, font-weight, border-radius)
- [ ] Card treatment matches existing cards (same shadow, radius, padding, background)
- [ ] Form inputs match existing inputs (height, border style, focus ring, placeholder color)
- [ ] Font family matches the referenced system
- [ ] Icon style is consistent (outline vs filled, size, stroke width)

**If no design system was provided**, check internal consistency:

- [ ] All buttons within one variation use the same base style (only vary color/weight for primary vs secondary)
- [ ] All text at the same hierarchy level uses the same font-size and weight
- [ ] Border-radius is from a consistent scale (not 4px on buttons and 7px on cards)
- [ ] If icons are used, they share the same visual style and size

---

## 4. Color Check

**If the user specified a color palette**, verify:

- [ ] All colors come from the specified palette or are semantic grays
- [ ] No random hex codes that don't belong to the palette
- [ ] Accent color usage matches the system's intent (primary for CTAs, secondary for less emphasis)

**If no palette was specified**, verify:

- [ ] Each variation uses a constrained palette (one accent + neutrals, not a rainbow)
- [ ] Text colors are from a neutral gray scale, not random grays
- [ ] No pure black (#000000) for body text — use #111, #1a1a1a, #0f172a, or similar
- [ ] No gray text on colored backgrounds — use tinted or semi-transparent alternatives
- [ ] Accent colors are used for emphasis, not decoration
- [ ] Contrast ratios meet minimums: 4.5:1 for body text, 3:1 for large text and UI elements

**Common violations:**
```css
/* Bad — pure black, arbitrary gray */
color: #000;
color: #777;

/* Good — intentional dark, from a scale */
color: #111827;  /* gray-900 */
color: #6b7280;  /* gray-500 */
```

---

## 5. Typography Check

- [ ] Font sizes are from the type scale (12, 14, 16, 18, 20, 24, 30, 36, 48), not arbitrary
- [ ] Line-height scales with font size: 1.5+ for body (14-18px), 1.1-1.3 for headings (24px+)
- [ ] Font weights are limited to 2-3 values per variation (e.g., 400, 600, 700)
- [ ] No more than 2 font families per variation
- [ ] Letter-spacing: positive for uppercase text, zero or slightly negative for large headings

---

## 6. Accessibility Check

- [ ] All text meets WCAG AA contrast ratios (4.5:1 body, 3:1 large text)
- [ ] Interactive elements have visible focus states
- [ ] Touch targets are at least 44x44px on mobile-targeted variations
- [ ] Color is not the only indicator of state or meaning (add icons, text, or patterns)
- [ ] Text is not embedded in decorative elements that would prevent selection/reading

---

## 7. The Mandate (Cross-Variation Checks)

These checks compare variations against each other. Run them after all individual checks pass.

- [ ] **Same HTML Test (run first)**: compare the HTML structure (not CSS) of every pair of variations. Strip all class names, inline styles, and text content — look only at element nesting. If two variations have the same nesting tree (e.g., both are `div > div.icon + div > p + p + button`), they fail. At least half the variations in any set must have genuinely different DOM trees. Refer to the structural recipes in `design-principles.md` §9 — each recipe number (T1-T10, P1-P10, L1-L8) represents a distinct structure. Two variations using the same recipe number share a structure.
- [ ] **Swap Test**: take any two variations and swap their color palettes. If they still look like the same two designs, they differ only in color — redesign one of them.
- [ ] **Squint Test**: blur your eyes on each variation. The primary action and key data must be visually dominant. If everything flattens to the same gray, hierarchy is broken.
- [ ] **Signature Test**: cover the color and typography. Can you identify each variation from layout/structure alone? If not, it lacks a signature element.
- [ ] **Token Test**: every spacing value from the scale, every font size from the type scale, every color from the palette, every radius consistent. One off-scale value fails.
- [ ] **Evidence Test**: every variation's `Evidence` field names a real source — `research:<note>` / `heuristic:<name>` / `competitor:<product>` / `anti-pattern-avoidance` / `ASSUMPTION`. Blank fields or "it looks cool" fail. `ASSUMPTION` is acceptable but must be the literal string so a reviewer can flag it for validation.
- [ ] **Brand-compliance Test** (project-bound mode only): MIN + MID variations live in the on-system section and only use tokens from the detected design system. A MIN variation that drops an off-system font or accent color fails — either fix it or demote it to the off-system section.

---

## How to Use This Checklist

After generating all variations and before presenting the gallery:

1. Scan each variation against sections 1-6 above
2. Run section 7 (The Mandate) across the full set
3. Fix any violations directly — don't flag them to the user
4. If the user specified a design system, sections 3 and 4 use the "with system" rules
5. If not, use the "without system" defaults
6. One pass through all variations is sufficient — you don't need to re-run after fixing

The goal is that every variation in the gallery looks intentional and polished, even the BOLD and UNIQUE ones. Wild concepts still need clean execution.
