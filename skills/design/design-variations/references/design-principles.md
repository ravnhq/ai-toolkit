# Design Principles Reference

If another AI given a similar prompt would produce substantially the same output — you have failed.

This reference exists to prevent generic, safe, interchangeable UI. Every variation must have a point of view. Read this before planning variations. Use it as a lookup during generation.

---

## 0. Intent First

Before writing any CSS, answer three questions:

1. **Who is this human?** A developer evaluating pricing? A patient checking lab results? A student enrolling in a course? The answer changes everything — typography density, color temperature, interaction urgency.
2. **What must they accomplish?** Not "view information" — the specific action. Compare plans and commit. Dismiss a notification without losing context. Authenticate quickly and get out of the way.
3. **What should this feel like?** Clinical precision? Warm reassurance? Playful energy? Quiet authority? Name the feeling in two words. If you can't, you don't have a direction yet.

Write these answers as a comment at the top of each variation's CSS block. If two variations share the same answers, one of them has no reason to exist.

---

## 1. Domain Exploration

Before generating variations, explore the component's world. This is what separates "a card with different colors" from "six genuinely different design perspectives."

For each component, identify:

- **5+ concepts from the product's domain.** A pricing page lives in the world of value, commitment, comparison, trust, scarcity. A toast notification lives in the world of interruption, urgency, transience, acknowledgment, recovery. These concepts should influence layout, emphasis, and metaphor — not just copy.
- **5+ domain-appropriate colors.** Not "pick a nice blue." If the component is for a health app, think clinical white, vital-sign green, alert red, calm slate, trust navy. Derive colors from the domain, not from a random palette generator.
- **One signature element per variation.** The single detail that makes this variation memorable. A monospaced price display. A progress ring instead of a feature list. A left color bar that signals tier. If you remove the signature element and the variation still looks the same as another — it wasn't a real signature.
- **3 obvious defaults you're rejecting.** Name them explicitly. "I'm rejecting: centered layout, blue CTA, card-with-shadow." This forces you away from the first thing that comes to mind, which is also the first thing every other AI would produce.

---

## 2. Design Directions

Each variation should map to a design direction — a coherent set of choices about density, color temperature, depth, and rhythm. Here are six directions with concrete token profiles. You don't have to use these exact names, but every variation needs a direction this specific.

### Precision
Cool neutrals, tight spacing, visible structure. Think Linear, Vercel, Raycast.
```
palette:    slate-50 through slate-900, blue-500 accent
spacing:    compact (4/8/12/16px gaps)
radius:     small (4-6px)
depth:      borders only, no shadows
typography: 13-14px base, medium weight, monospace for data
feel:       "engineered tool"
```

### Warmth
Neutral-warm tones, generous whitespace, soft edges. Think Notion, Airbnb, Stripe.
```
palette:    stone-50 through stone-800, amber-600 or orange-500 accent
spacing:    generous (16/24/32px gaps)
radius:     medium-large (8-12px)
depth:      subtle single-layer shadows
typography: 15-16px base, regular weight, humanist sans
feel:       "comfortable, approachable"
```

### Sophistication
Muted palette, restrained typography, deliberate asymmetry. Think Aesop, Apple, Dieter Rams.
```
palette:    zinc-100 through zinc-900, single muted accent (slate-blue, sage, terracotta)
spacing:    spacious with asymmetric margins
radius:     minimal (2-4px) or none
depth:      flat, separation through whitespace and color
typography: elegant serif or thin sans, generous letter-spacing on headings
feel:       "curated, premium"
```

### Boldness
High contrast, oversized elements, confident color. Think Figma, Stripe Atlas, brutalist sites.
```
palette:    near-black backgrounds, white text, one vivid accent (violet-500, emerald-400)
spacing:    dramatic (large padding, tight internal gaps)
radius:     sharp (0-2px) or fully rounded (999px)
depth:      hard shadows (4px 4px 0) or none
typography: large headings (28-48px), heavy weight (700-900), tight line-height
feel:       "loud, confident, unapologetic"
```

### Utility
Dense, information-first, minimal decoration. Think Bloomberg Terminal, Grafana, AWS Console.
```
palette:    white/gray-50 background, gray-700 text, status colors only (green/amber/red)
spacing:    compact (4/8px gaps), maximize data density
radius:     small (2-4px)
depth:      1px borders, no shadows
typography: 12-13px, tabular figures, monospace for numbers
feel:       "dashboard, data-dense, professional"
```

### Expressive
Gradient accents, layered depth, animated touches. Think Arc Browser, Lottie demos, creative tools.
```
palette:    light base with gradient accents (violet→blue, coral→amber)
spacing:    medium (12/16/24px)
radius:     large (12-16px)
depth:      layered shadows + subtle backdrop-blur
typography: rounded sans (Plus Jakarta, Nunito), medium weights
feel:       "creative, energetic, modern"
```

---

## 3. CSS Polish Baseline

Every variation must include this baseline. These are the invisible details that separate professional output from demos.

**Font rendering (add to the gallery's body/root):**
```css
body {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
  font-feature-settings: "kern" 1, "liga" 1;
}
```

**Colored shadows instead of gray:** Professional shadows pick up the hue of the element or its background. Never use pure gray rgba for shadows on colored elements.
```css
/* gray shadow — flat, lifeless */
box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);

/* colored shadow — alive, grounded */
box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);  /* blue card */
box-shadow: 0 4px 12px rgba(16, 185, 129, 0.15);  /* green card */
```
For neutral/white cards, gray shadows are fine. For any element with a background color, tint the shadow to match.

**Progressive shadow layers** (Josh Comeau technique — stacks create realistic light):
```css
box-shadow:
  0 1px 1px rgba(0,0,0,0.08),
  0 2px 2px rgba(0,0,0,0.06),
  0 4px 4px rgba(0,0,0,0.05),
  0 8px 8px rgba(0,0,0,0.04),
  0 16px 16px rgba(0,0,0,0.03);
```

**Easing curves (use MD3 standard, not generic `ease`):**
```css
--ease-standard:  cubic-bezier(0.4, 0, 0.2, 1);   /* most UI transitions */
--ease-enter:     cubic-bezier(0, 0, 0.2, 1);      /* elements appearing */
--ease-exit:      cubic-bezier(0.4, 0, 1, 1);       /* elements leaving */
```
Duration: 150-200ms for micro-interactions (hover, focus). 250-350ms for layout changes. Never exceed 500ms.

**Focus rings (double-ring technique for clear visibility):**
```css
button:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px #fff, 0 0 0 4px var(--accent);
}
```

**Button active state (makes buttons feel physical):**
```css
button:active {
  transform: translateY(0);
  box-shadow: /* reduce shadow one level */;
}
```

---

## 3b. Tinted Neutrals

Pure grays (#f5f5f5, #e5e5e5) feel sterile. Professional palettes use tinted neutrals — grays with a faint hue that matches the design direction.

**How:** Add a tiny amount of chroma to your neutral scale. The tint should be nearly invisible per pixel but creates subconscious cohesion across the surface.

```css
/* Warm neutrals (for Warmth, Expressive directions) */
--surface-0: oklch(99% 0.005 60);    /* barely warm white */
--surface-1: oklch(97% 0.008 60);    /* warm gray-50 */
--surface-2: oklch(93% 0.008 60);    /* warm gray-100 */

/* Cool neutrals (for Precision, Utility directions) */
--surface-0: oklch(99% 0.005 250);   /* barely cool white */
--surface-1: oklch(97% 0.008 250);   /* cool gray-50 */
--surface-2: oklch(93% 0.008 250);   /* cool gray-100 */

/* Sage neutrals (for Sophistication direction) */
--surface-0: oklch(99% 0.005 150);   /* barely green white */
--surface-1: oklch(97% 0.008 150);   /* sage gray-50 */
--surface-2: oklch(93% 0.008 150);   /* sage gray-100 */
```

Fallback: if oklch isn't desired, use the Tailwind named scales (slate = cool, stone = warm, zinc = neutral) instead of the generic gray scale.

---

## 3c. Surface Elevation

Don't reach for heavy shadows to create depth. Use lightness shifts on neutral backgrounds — it's how modern design systems actually work.

```
Base surface:     oklch(100% 0 0)        white
Raised surface:   oklch(97% 0.005 H)     +3% darker, faint tint
Elevated:         oklch(95% 0.008 H)     +5% darker
Overlay:          oklch(93% 0.008 H)     +7% darker
```

For dark mode or dark variations:
```
Base surface:     oklch(15% 0.005 H)     deep background
Raised surface:   oklch(18% 0.005 H)     +3% lighter
Elevated:         oklch(21% 0.008 H)     +6% lighter
Overlay:          oklch(24% 0.008 H)     +9% lighter
```

Combine lightness shifts with a single subtle shadow layer when needed. Never stack heavy shadows on top of tinted backgrounds — it looks muddy.

---

## 4. Token Foundations

When the user doesn't provide a design system, use this default token set. Derived from Radix Themes and Tailwind — the same values used by shadcn/ui, Vercel, and Linear.

### Spacing Scale
```
4px     tight gaps (icon-to-label)
8px     inline spacing (between related items)
12px    form padding, small gaps
16px    base component padding
24px    section spacing inside components
32px    between component groups
40px    large section breaks
48px    page section padding
64px    layout-level spacing
```

Every padding, margin, and gap value must come from this scale. No 5px, 7px, 10px, 13px, 15px, 17px, 22px. If a value isn't on the scale, it's wrong.

### Type Scale
```
12px    captions, fine print, badges
14px    secondary text, labels, metadata
16px    body text (base)
18px    large body, emphasized text
20px    small heading
24px    section heading
28px    card heading, component title
35px    page heading
60px    hero/display (use sparingly)
```

Weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold). Line heights: body at 1.5, headings at 1.2, single-line elements at 1.

Font stack: `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`

For Sophistication or Expressive directions, you may substitute: `'Plus Jakarta Sans'`, `'DM Sans'`, `'Source Serif 4'`, or `'Fraunces'` — import from Google Fonts CDN.

### Border Radius Scale
```
2px     minimal (utility, data-dense)
4px     small elements (badges, chips)
6px     buttons, inputs
8px     standard cards
12px    large cards, containers
16px    modals, large surfaces
9999px  pills, fully rounded
```

Pick one radius strategy per variation and apply it everywhere. Don't mix 4px buttons with 12px cards.

### Elevation (Shadows)

Use layered shadows for realistic depth. Each level adds distance from the surface.

**Level 0 — Flat:**
```css
box-shadow: none;
border: 1px solid var(--gray-200);
```

**Level 1 — Resting:**
```css
box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
```

**Level 2 — Card:**
```css
box-shadow:
  0 0 0 1px rgba(0, 0, 0, 0.03),
  0 1px 1px 0 rgba(0, 0, 0, 0.07),
  0 2px 3px 0 rgba(0, 0, 0, 0.05);
```

**Level 3 — Elevated:**
```css
box-shadow:
  0 0 0 1px rgba(0, 0, 0, 0.03),
  0 2px 4px -1px rgba(0, 0, 0, 0.07),
  0 4px 12px -4px rgba(0, 0, 0, 0.1);
```

**Level 4 — High:**
```css
box-shadow:
  0 0 0 1px rgba(0, 0, 0, 0.03),
  0 8px 24px -4px rgba(0, 0, 0, 0.08),
  0 12px 32px -8px rgba(0, 0, 0, 0.12);
```

Always offset shadows downward (Y > 0). The first `0 0 0 1px` layer is a border-like ring for definition on light backgrounds.

### Color

**Neutral grays (Tailwind slate):**
```
50:  #f9fafb    subtle backgrounds
100: #f3f4f6    card backgrounds, zebra rows
200: #e5e7eb    borders, dividers
300: #d1d5db    disabled borders
400: #9ca3af    placeholder text
500: #6b7280    secondary text
600: #4b5563    body text (on white)
700: #374151    strong body text
800: #1f2937    headings
900: #111827    high-emphasis text
```

No pure black (#000). Primary text is gray-800 or gray-900. Secondary text is gray-500.

**Accent color:** one per variation, derived from the domain exploration (section 1). Use it for CTAs and active states only. Don't rainbow.

---

## 5. Component Recipes

Use these as baselines. They represent correct, production-quality implementations. Your variations should feel at least this polished — then diverge in direction.

### Pricing Card
```css
.pricing-tier {
  display: flex;
  flex-direction: column;
  padding: 24px;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
  background: #fff;
  min-height: 400px;
}
.pricing-tier.featured {
  border: 2px solid #3b82f6;
  box-shadow: 0 4px 12px -4px rgba(59, 130, 246, 0.2);
}
.pricing-name {
  font-size: 14px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #6b7280;
  margin-bottom: 8px;
}
.pricing-amount {
  font-size: 35px;
  font-weight: 700;
  color: #111827;
  line-height: 1.1;
  margin-bottom: 4px;
}
.pricing-period {
  font-size: 14px;
  color: #6b7280;
  margin-bottom: 24px;
}
.pricing-features {
  list-style: none;
  padding: 0;
  margin: 0 0 24px 0;
  flex: 1;
}
.pricing-features li {
  font-size: 14px;
  color: #374151;
  padding: 8px 0;
  border-bottom: 1px solid #f3f4f6;
  display: flex;
  align-items: center;
  gap: 8px;
}
.pricing-cta {
  width: 100%;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 150ms ease;
  border: none;
}
```

### Toast Notification
```css
.toast {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 16px;
  border-radius: 8px;
  background: #fff;
  max-width: 360px;
  box-shadow:
    0 0 0 1px rgba(0,0,0,0.03),
    0 4px 12px -4px rgba(0,0,0,0.1),
    0 8px 24px -8px rgba(0,0,0,0.08);
}
.toast-title {
  font-size: 14px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
}
.toast-message {
  font-size: 14px;
  color: #6b7280;
  line-height: 1.5;
}
```

### Login Form
```css
.login-form {
  max-width: 360px;
  padding: 32px;
  background: #fff;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
}
.login-heading {
  font-size: 20px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 8px;
}
.form-input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
  color: #111827;
  transition: all 150ms ease;
}
.form-input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
}
.form-submit {
  width: 100%;
  padding: 10px 16px;
  background: #111827;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}
```

---

## 6. Anti-Patterns — The Slop Detector

These are the tells that mark AI-generated UI. If you catch yourself doing any of these, stop and redesign. This list is derived from Impeccable's anti-pattern database and real-world AI UI audits.

### The top AI fingerprints (most recognizable tells)
- **Purple/violet gradients.** The single most common AI-generated color choice. If your variation has a purple gradient and it's not the explicit design thesis, replace it.
- **Cyan/teal on dark backgrounds.** The second most common. Dark mode + cyan accent = instant "AI made this" signal.
- **Thick colored side-stripe borders on cards.** The `border-left: 4px solid blue` pattern on list items or cards. It's the AI equivalent of clip art.
- **Dark backgrounds with colored box-shadow glow.** `box-shadow: 0 0 20px rgba(99, 102, 241, 0.3)` on a dark card. Neon glow is not depth.
- **Gradient text on metrics.** `background: linear-gradient(...); -webkit-background-clip: text` on a big number. Gratuitous.
- **Hero metric layout.** Big number + small label + 3 stat cards below + gradient. This layout is the AI equivalent of "Hello World."
- **Glassmorphism on dark mode.** Frosted glass with neon accents on dark backgrounds. Overused to the point of parody.

### Layout and structure
- **Nested cards.** A card inside a card inside a section is noise. One level of containment per component.
- **Centered everything.** Body text and feature lists are left-aligned. Center only headings and single-line CTAs when appropriate.
- **Symmetry addiction.** Real layouts have intentional asymmetry — a wider content column, a sidebar that breaks the grid, an image that bleeds past the container edge.
- **Same-sized cards with icon + heading + text, repeated.** Three identical cards in a row is a template, not a design. Vary card content or structure to reflect real differences in the data.
- **Card around every single element.** Use alignment and spacing to group related items. A card is for containment of a discrete unit, not decoration.

### Color and depth
- **Pure gray shadows on colored elements.** If the element has a blue background, its shadow should be tinted blue (see section 3).
- **Gratuitous gradients.** A gradient is a design thesis, not a default. If the gradient isn't the point of the variation, use a flat color.
- **Gray text on colored backgrounds.** Use white at 70-90% opacity or a tinted lighter shade. Gray-500 on blue-600 is unreadable.
- **Pure black (#000) or pure white (#fff).** Use gray-900 (#111827) for text. Use oklch(99% ...) or #fafafa for backgrounds. Pure values feel harsh.
- **Rainbow accents.** Blue buttons + green badges + purple headers = visual chaos. One accent color per variation.
- **Heavy drop shadows on everything.** `box-shadow: 0 10px 30px black` is never the answer.
- **Borders AND shadows AND gradients on the same element.** Pick one depth strategy.

### Typography
- **More than 2 font families.** One sans + one mono is enough. Two sans-serifs fighting each other looks like a mistake.
- **Off-scale font sizes.** 11px, 13px, 15px, 17px, 19px — if it's not on the type scale, don't use it.
- **Decorative fonts for body text.** Display and script faces are for headings only, and even then sparingly.
- **All-caps body text.** Uppercase removes word-shape recognition. Reserve for short labels (tier names, badges, overlines) only.
- **Missing font smoothing.** Every gallery must include `-webkit-font-smoothing: antialiased`. Without it, text renders heavier on macOS and looks cheap.

### Interaction
- **Bounce/elastic easing.** `cubic-bezier(0.68, -0.55, 0.27, 1.55)` feels like 2015. Use MD3 standard: `cubic-bezier(0.4, 0, 0.2, 1)`.
- **Hover effects that change layout.** Scale transforms on cards that push siblings, or padding changes on hover. Hover should change color, shadow, or subtle transform only.
- **No hover/focus states at all.** Every interactive element needs a visible response.
- **Generic `transition: all`** without specifying properties. Always list specific properties: `transition: background-color 200ms var(--ease-standard), box-shadow 200ms var(--ease-standard)`.

### Content
- **"Lorem ipsum" or "Description goes here."** Use realistic content that matches the component's purpose.
- **"Click Here" as button text.** Use action verbs: "Get Started", "Sign In", "Upgrade to Pro".

---

## 7. The Mandate — Pre-Delivery Checks

Run these four tests on every variation before including it in the gallery. If a variation fails any test, redesign it.

### Swap Test
Take two of your variations. Swap their color palettes. If they still look like the same two variations — their difference was only color, and you need to redesign one of them. Variations must differ in structure, hierarchy, or concept — not just surface treatment.

### Squint Test
Blur your eyes (or zoom to 25%). Can you still tell what's most important in each variation? The primary action and key data should be visually dominant even when blurred. If everything flattens to the same gray, your hierarchy is broken.

### Signature Test
Cover the color and typography of a variation. Can you still identify which one it is from layout and structure alone? If not, it lacks a signature element. Every variation needs at least one structural choice that's unique to it — a sidebar layout, a horizontal feature comparison, a progress indicator replacing a feature list, a split-screen login.

### Token Test
Inspect every value in your CSS. Is every spacing value from the scale? Every font size from the type scale? Every color from the palette? Every radius consistent? A single off-scale value (padding: 15px, font-size: 13px, border-radius: 7px) fails this test.

---

## 8. Variation Dimensions

When planning variations, vary along these axes. Use at least 3 different dimensions across your set. If two variations share the same dimension, they need different design directions.

- **Layout**: horizontal vs. vertical vs. grid vs. split-screen. Zone reordering (header on side, CTA on top, media-first).
- **Density**: compact (4-8px gaps, 12-13px type) vs. spacious (24-32px gaps, 16-18px type). These create completely different feelings.
- **Emphasis**: which element is the focal point? Price vs. features vs. CTA vs. social proof vs. brand.
- **Visual language**: MD3 elevated vs. outlined vs. glassmorphic vs. dark mode vs. brutalist vs. editorial.
- **Data framing**: "3,151 enrolled" vs. "Join 3,151 others" vs. progress ring vs. live activity feed vs. geographic visualization.
- **Interaction model**: passive display vs. single CTA vs. expandable accordion vs. inline actions vs. toggle between views.

---

## 9. Interaction Polish

Static mockups still need these to feel real:

- **Hover on buttons**: darken background by one shade, optional `translateY(-1px)`, lift shadow one level. Use `transition: background-color 200ms var(--ease-standard), transform 150ms var(--ease-standard)`.
- **Active on buttons**: `transform: translateY(0)` + reduce shadow one level. This makes buttons feel physical — they press in.
- **Hover on cards**: shadow Level 2 → Level 3, optional `translateY(-2px)`. Use `transition: box-shadow 200ms var(--ease-standard), transform 200ms var(--ease-standard)`.
- **Focus rings on inputs**: double-ring technique — `box-shadow: 0 0 0 2px #fff, 0 0 0 4px var(--accent)`. The white gap makes the ring visible on any background.
- **Focus-visible only**: use `:focus-visible` not `:focus` so keyboard users see rings but mouse clicks don't.
- **Transitions**: 150-200ms with MD3 standard easing `cubic-bezier(0.4, 0, 0.2, 1)`. Always specify properties explicitly (`transition: background-color 200ms ...`), never `transition: all`.
- **Cursor**: `pointer` on all interactive elements.

---

## Quick Reference: Common Mistakes

| Mistake | Fix |
|---------|-----|
| Random spacing (5px, 10px, 15px) | Every value from the spacing scale |
| Pure black text (#000) | gray-800 (#1f2937) or gray-900 (#111827) |
| Gray text on colored bg | White at 70-90% opacity or tinted light shade |
| Heavy drop shadows | Layered shadows from elevation scale, or lightness shifts |
| Inconsistent border-radius | One radius strategy per variation |
| Multiple accent colors | One accent + grays. Derived from domain. |
| Cramped padding | Min 16px card padding, 10px 16px button padding |
| No hover states | Transitions on every interactive element |
| Centered body text | Left-align text and feature lists |
| Decorative gradients | Gradients only as variation thesis |
| Variations that only differ in color | Must differ in structure (Swap Test) |
| Off-scale font sizes (11px, 13px) | Use the type scale |
| No signature element | One unique structural choice per variation |
