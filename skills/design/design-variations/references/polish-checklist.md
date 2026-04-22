# Polish & Rendering Checklist

A gallery with high structural diversity can still ship as slop if its variations have broken focus rings, missing font imports, or tiny touch targets. This checklist runs at step 6b (after compliance) and before shipping.

Each item is a **hard gate** — a variation that fails is rebuilt, not excused.

---

## 1. Web font loading

If any variation claims a profile whose execution card (in `profile-fidelity.md`) requires a specific web font, the gallery HTML MUST:

1. Include a `<link rel="preconnect">` to `fonts.googleapis.com` and `fonts.gstatic.com` (with `crossorigin`) in `<head>`.
2. Include a `<link href="https://fonts.googleapis.com/css2?family=...&display=swap">` that imports every required family with every required weight.
3. Use the family string in the variation's scoped CSS as the FIRST value in `font-family`, before any fallback.

**Rule:** if a profile requires `Cormorant Garamond` and the variation's CSS reads `font-family: -apple-system, "Cormorant Garamond", serif`, the fallback wins in most environments — **the variation fails**. The profile font MUST be first.

**Also:** for every custom font used in the gallery, there must be a corresponding Google Fonts `<link>`. Importing `Inter` but claiming `Playfair Display` in CSS means Playfair never loads.

Required imports by profile:
- **Editorial** → Playfair Display + Source Serif 4
- **Luxury** → Cormorant Garamond
- **Wabi-Sabi** → Lora or iA Writer Quattro (Georgia acceptable as system fallback only)
- **Brutalist, Cyberpunk, Data-Dense** → IBM Plex Mono AND/OR Space Mono
- **Art Deco** → Bodoni Moda + Playfair Display
- **Government** → Source Sans 3
- **Korean** → Noto Sans KR
- **Japanese** → Noto Sans JP

---

## 2. Focus-visible rings (mandatory on ALL interactive elements)

Every `<button>`, `<a>`, `<input>`, `<select>`, `<textarea>`, `<summary>`, and anything with `tabindex` MUST have a visible `:focus-visible` ring.

**Required pattern (double-ring technique):**
```css
.v1-button:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px #fff, 0 0 0 4px var(--accent, #635BFF);
}
```

- Use `:focus-visible` not `:focus` (so mouse clicks don't trigger rings).
- Use a 2px transparent/white inner gap so the ring is visible on any background.
- Use the profile's accent color as the outer ring.
- GOV.UK variations: use `#FFDD00` (GOV.UK yellow) instead of the accent color.

**Rule:** any variation with interactive elements missing focus-visible rings **fails**.

---

## 3. Touch targets

Every interactive element MUST have a hit area ≥ 44×44 CSS pixels (WCAG AAA + Apple HIG mandate).

For small visual elements (icon buttons, close buttons, ✕):
- Either set `min-width: 44px; min-height: 44px` on the button directly, OR
- Use a larger `<button>` wrapper with generous padding and a smaller visual icon inside.

**Rule:** `width: 24px; height: 24px` on a close button = fails, regardless of how "minimal" the design claims to be. Rework to padding-based hit area.

---

## 4. Hover states

Every button and interactive card MUST have a visible `:hover` state:
- Buttons: darken/shift background one shade, optional `translateY(-1px)`, shadow lift.
- Cards (clickable): shadow level-up, optional `translateY(-2px)`.
- Links: underline on hover OR color shift + weight shift.

**Specify transitions explicitly** — `transition: all ...` is forbidden. Name the properties: `transition: background-color 200ms var(--ease-standard), box-shadow 200ms var(--ease-standard)`.

**Rule:** any interactive element with no visible hover response fails.

---

## 5. Transition easing matches profile

- **Default ease** (most profiles): `cubic-bezier(0.4, 0, 0.2, 1)` (MD3 standard) at 150–200ms.
- **Luxury profile:** 600ms cubic-bezier(0.4, 0, 0.2, 1) — SLOWER than default.
- **Wabi-Sabi profile:** 400–600ms or no transitions at all.
- **Brutalist profile:** NO transitions (instant state changes).

**Rule:** a Luxury variation with `transition: 200ms` fails. A Brutalist variation with any transition fails.

---

## 6. Thesis-implied animation

If a variation's thesis uses words implying motion/time — *transience, countdown, auto-dismiss, progressive, expandable, reveal, timeline* — the variation MUST render that behavior, not just claim it:

- **Transience / auto-dismiss** → `@keyframes fadeOut` animating opacity 1→0 over the dismiss window, OR a visible progress bar animating `width: 100% → 0%` over the same window.
- **Countdown** → animated progress bar or numeric timer, NOT a static "60%" bar.
- **Expandable** → `<details>` element OR a CSS-state-driven height transition; the chevron must rotate on open.
- **Timeline** → a visible dot-on-line structure; the dot pulses or the line is clearly vertical and connects entries.
- **Progressive reveal** → CSS to show/hide sibling fieldsets or staggered animation on enter.

**Rule:** a variation whose thesis implies motion but whose CSS is static fails. "I'll describe it in the header" is not an implementation.

---

## 7. Cell containment (rendering bug guardrails)

- Every `.variation-preview` MUST have `overflow: hidden` as a safety net.
- Every variation's outermost wrapper MUST fit the cell's declared `padding` box.
- If a variation uses `position: absolute`, it MUST be inside a `position: relative` ancestor that is clipped by the cell.
- No variation may use a fixed pixel width > the cell's min-width (per the SKILL.md component-containment table).

**Rule:** any variation that visibly clips or overflows its cell in a 1400px viewport fails. Test mentally before rendering: "at 1400px viewport with this gallery's column count, does each variation's content fit the cell width?"

---

## 8. Contrast (WCAG AA minimum, AAA where profile mandates)

- Body text contrast ≥ 4.5:1 against its background.
- Large text (18px+ bold, 24px+ regular) contrast ≥ 3:1.
- UI chrome and borders ≥ 3:1.
- **Profiles requiring AAA:** Healthcare, Government — body text ≥ 7:1.

Specific watch-outs:
- Gray text on colored backgrounds: use white @ 70–90% opacity instead of #6B7280 on #3B82F6.
- Dark-mode variations: white text on near-black is fine; cyan text on near-black is fine AT full opacity; cyan text with 0.6 opacity is usually a fail.
- Luxury/Wabi-Sabi sage tones: `#5D6E5E` on `#F5F2EE` hits ~4.8:1, borderline — add weight or size.

**Rule:** any text below AA fails. Re-derive the color, don't ship it dim.

---

## 9. Icon / glyph quality

- Don't use emoji (✓ ✕ ☰) as primary UI glyphs on non-playful profiles. They render inconsistently across OSes.
- Prefer inline SVG for icons. If using a single-char symbol, choose a Unicode Geometric or Math symbol (×, ·, ⌃, ◆) over emoji.
- Icon size ≥ 16px; icon stroke weight consistent across a variation.

**Rule:** a Stripe or Linear variation using 🔔 as its toast icon fails polish.

---

## 10. Dark-mode variations

If a variation uses a dark background:
- Text at full weight, not opacity-dimmed.
- Shadows tinted with the accent (blue bg → blue-tinted shadow), not pure black.
- Borders at ~15–30% white/accent opacity.
- Inputs: surface slightly lighter than the main dark background (never pure black inputs on near-black background).

**Forbidden combos (see design-principles.md §6):**
- Cyan accent on near-black background (unless explicitly Cyberpunk profile and executed at FULL glow intensity, not weak).
- Purple/violet gradients on dark mode (generic AI fingerprint).
- Glassmorphism on dark mode (parody at this point).

---

## 11. Copy register (voice as a design axis)

Each variation declares a **register** in its plan: Plain / Technical / Playful / Terse / Authoritative / Apologetic. Every string in the variation — CTA verb, value-prop, error tone, empty-state message — must match that register.

- No "Lorem ipsum", "Description goes here", "Sample text".
- Button labels are action verbs matching register:
  - Plain: "Get started", "Sign in"
  - Technical: "Authenticate", "Commit changes"
  - Playful: "Let's go", "Cook something up"
  - Terse: "Start", "Go"
  - Authoritative: "Begin enrollment", "Confirm"
  - Apologetic: "Try again", "Let us fix this"
- Content matches thesis: an "urgency" toast says "Session expires in 30s", not "This is a notification message."
- Copy across variations in the same gallery must NOT be identical when theses or registers differ. Identical microcopy across variations is a red flag that register wasn't honored.

**Coherence rule:** profile and register must be mutually compatible. Brutalist + Apologetic, Luxury + Terse-SMS-slang, Government + Playful — these collide. If they clash, rebuild one.

**Rule:** a variation with generic placeholder copy, register-mismatched copy, or copy identical to another variation fails polish, regardless of how clean the CSS is.

---

## 12. Internationalization floor

- **Text expansion**: no fixed widths on text containers. Every variation must survive a 1.6× text expansion (simulating German/Finnish) without clipping or breaking layout. Use `min-width` + flexible layout, not `width`.
- **RTL (directional)**: at least one variation in any gallery of N ≥ 12 is rendered with `dir="rtl"` either wholesale or as a paired state. Icon-left layouts, arrows, and progress affordances must mirror — not just the text flow. Logical properties (`margin-inline-start`, `padding-inline-end`) preferred over `margin-left` / `padding-right` where the profile allows.
- **Long-content reality**: at least one variation renders with realistic overflow content (3-line message, 12-item feature list, 40-character button label). The goal is stakeholder confidence that the design doesn't break on real copy.

**Rule:** a gallery of ≥12 variations with zero RTL representation and zero text-expansion-safe variations fails polish. Fix by adding one RTL-rendered variation and making text containers fluid.

---

## 13. Reduced motion

Every variation whose thesis implies motion (transience, countdown, expandable, timeline, progressive reveal) MUST pair its animation with a reduced-motion fallback.

```css
@media (prefers-reduced-motion: no-preference) {
  .v3-toast { animation: slideIn 240ms var(--ease-standard); }
  .v3-toast__progress { animation: countdown 3s linear; }
}
/* Static end-state for reduced-motion users — no @media wrapper, always applies as baseline */
.v3-toast { opacity: 1; transform: none; }
.v3-toast__progress { width: 0; }
```

- The baseline (outside the `@media`) renders the animation's END state, not its start.
- Transitions on hover/focus can remain unguarded if they're short (<200ms) and non-essential.
- Essential state-change animations (enter, exit, countdown) MUST be guarded.

**Rule:** a variation that auto-dismisses or counts down but has no reduced-motion fallback fails polish and WCAG 2.3.3.

---

## How to run this checklist

After compliance (`design-system-compliance.md`), run sections 1–11 on each variation. For each failure, rebuild the specific element and re-check. Don't ship the gallery until every variation passes every section.
