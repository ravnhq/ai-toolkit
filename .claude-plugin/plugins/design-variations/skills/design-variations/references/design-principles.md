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

### Thesis before profile

Every variation has a THESIS (the design problem it solves) and a PROFILE (the visual vocabulary that solves it). Thesis comes first. Profile is subordinate.

**Wrong (profile-first):**
- "V2 — Stripe variation" → nothing said about what problem it solves
- "V5 — Cyberpunk toast" → aesthetic name, no design intent

**Right (thesis-first, profile subordinate):**
- **V2 Transience** (T5 · Wabi-Sabi profile) — *3-second auto-dismiss, no close button; treats notification as ephemeral context, not persistent UI*
- **V5 Command-line acknowledgment** (T4 · Cyberpunk profile) — *toast is a shell line; user acks by typing or pressing Enter, keyboard-first*
- **V3 Interruption urgency** (T2 · Government/GOV.UK profile) — *full-width bar at viewport top, high-contrast, dismiss requires explicit action*
- **V7 Acknowledgment replaces dismissal** (T3 · Monzo profile) — *prominent Confirm button takes the place of an X; user can't close without acting*

Each thesis names WHAT the variation solves. The profile names HOW it's styled. If you can't fill in both halves for every variation, the variation has no reason to exist.

### Thesis library (examples by component type)

**Toast**: Transience · Persistence · Interruption · Acknowledgment · Deniability (undo) · Batching · Categorization · Command-line · Status-line · Progress-linked
**Pricing**: Comparison-first · Anchor-tier · Decision-forcing · Progressive-reveal · Matrix-scan · Narrative-flow · Social-proof-weighted · Value-density · Flexible-toggle · Full-commitment
**Login**: Minimal-friction · Trust-signaling · Multi-path (social first) · Progressive (step-by-step) · Branded-context · Dense-horizontal · Immersive · Keyboard-first · Passwordless · Biometric-primary

Pick one thesis per variation. Two variations with the same thesis means one should be cut.

---

## 1. Domain Exploration

Before generating variations, explore the component's world. This is what separates "a card with different colors" from "six genuinely different design perspectives."

For each component, identify:

- **5+ concepts from the product's domain.** A pricing page lives in the world of value, commitment, comparison, trust, scarcity. A toast notification lives in the world of interruption, urgency, transience, acknowledgment, recovery. These concepts should influence layout, emphasis, and metaphor — not just copy.
- **5+ domain-appropriate colors.** Not "pick a nice blue." If the component is for a health app, think clinical white, vital-sign green, alert red, calm slate, trust navy. Derive colors from the domain, not from a random palette generator.
- **One signature element per variation.** The single detail that makes this variation memorable. A monospaced price display. A progress ring instead of a feature list. A left color bar that signals tier. If you remove the signature element and the variation still looks the same as another — it wasn't a real signature.
- **3 obvious defaults you're rejecting.** Name them explicitly. "I'm rejecting: centered layout, blue CTA, card-with-shadow." This forces you away from the first thing that comes to mind, which is also the first thing every other AI would produce.

---

## 2. Product Reference Profiles

Each variation must be grounded in a real product's or design tradition's visual language. These profiles use actual values from shipping products. Pick a profile and follow its specific CSS values — this is what keeps output looking real.

### A. Product Profiles

**Linear** — Dark-first, dense, engineered.
`bg: #0F0F10 | surface: #151516 | text: #EEEFF1 | accent: #D25E65 | font: Inter 13px | radius: 12px cards, 8px buttons | depth: no card shadows, borders only | spacing: 8px grid`

**Stripe** — Polished, editorial, trust-heavy.
`bg: #FFF | dark: #0A2540 | subtle: #F6F9FC | accent: #635BFF | text: #30313D | font: system 14px | radius: 4px | shadow: 0 1px 3px #e6ebf1 | input: 40px height, 10px 12px padding`

**Vercel/Geist** — Stark black-and-white, typographic.
`bg: #FFF | text: #000 | secondary: #666 | border: #EAEAEA | font: Geist 14px | letter-spacing: -0.01em body, -0.04em headings | radius: 0-4px sharp | depth: minimal`

**GitHub/Primer** — Functional, accessible, dev-familiar.
`bg: #FFF | subtle: #F6F8FA | text: #1F2328 | accent: #0969DA | success: #238636 | danger: #DA3633 | border: #D0D7DE | font: system 14px | radius: 6px | button: 8px 16px | shadow: 0 1px 0 rgba(27,31,36,0.04)`

**Notion** — Warm, content-first, document-like.
`bg: #FFF | hover: #F7F6F3 | sidebar: #FBFBFA | text: #37352F | gray: #787774 | accent: #2383E2 | font: system 16px | radius: 4px | depth: bg-color separation only`

**Apple/HIG** — Premium, translucent, generous.
`bg: rgba(255,255,255,0.72) | secondary: #F5F5F7 | text: #1D1D1F | accent: #007AFF | font: SF Pro 17px | radius: 16-20px | backdrop-filter: blur(20px) | border: 1px solid rgba(255,255,255,0.18) | shadow: 0 2px 8px rgba(0,0,0,0.08) | padding: 20-24px | touch: 44px min`

**Shopify/Polaris** — Merchant-friendly, green, systematic.
`bg: #FFF | surface: #F1F1F1 | text: #303030 | accent: #006620 | border: #C9CCCF | font: system 14px | radius: 8px | spacing: 4px base`

### B. Industry Profiles

**Editorial/Magazine** (NYT, The Verge, Bloomberg)
`font: 'Playfair Display' serif headlines, 'Source Serif 4' 18px body | line-height: 1.6 | letter-spacing: -0.02em heads | max-width: 65ch | color: #2C3E50 | bg: #F8F9FA | radius: 0 | depth: thin rules (1px solid #ddd)`

**Luxury/Fashion** (Aesop, Hermès, Bottega Veneta)
`font: 'Cormorant Garamond' 15px weight-300 | letter-spacing: 0.1em | line-height: 1.8 | color: #544D4B | accent: #760402 burgundy | padding: 48px | radius: 0 | depth: whitespace only | transition: 600ms ease`

**Fintech/Banking** (Wise, Mercury)
`accent: #9FE870 (Wise green) | dark: #163300 | font: system 14px | font-variant-numeric: tabular-nums | radius: 8px | shadow: 0 1px 3px rgba(0,0,0,0.06) | Mercury: bg #F0F0F0, text #141414`

**Healthcare/Wellness** (Calm, One Medical)
`text: #2C3E50 | bg: #F8F9FA | accent: #17A2B8 teal | font: 'Open Sans' 16px | line-height: 1.6 | radius: 8px | padding: 24px | shadow: 0 2px 8px rgba(0,0,0,0.06) | WCAG AAA required`

**Government/Civic** (GOV.UK, USWDS)
`text: #1B1B1B | accent: #0050D8 | font: 'Source Sans 3' 16px | radius: 0-4px | spacing: 8px base | GOV.UK text: #0B0C0C | max-accessibility focus`

**Gaming/Entertainment** (Discord, Steam)
`Discord: bg #313338, accent #5865F2, text #DBDEE1 | Steam: bg #171A21, surface #1B2838, accent #66C0F4, text #C7D5E0 | font: 'gg sans' 14px | radius: 8px | dense, vivid, dark`

**Education/EdTech** (Duolingo, Khan Academy)
`accent: #58CC02 green | font: 'Nunito' 16px weight-700 | radius: 16px | shadow: 0 4px 0 #E5E5E5 (3D button) | padding: 16px 24px | playful, rounded, progress-driven`

### C. Design Movement Profiles

**Swiss/International Typographic**
`font: 'Helvetica Neue' 400 | grid: 12-column, gap 24px | color: #000 on #FFF | radius: 0 | depth: 1px rules only | asymmetric columns (5/12 + 7/12)`

**Scandinavian/Nordic** (Klarna, Spotify, IKEA)
`font: system sans | color: #1A1A1A | accent: #FF3D00 Klarna coral or #1DB954 Spotify green | radius: 8px | shadow: 0 2px 8px rgba(0,0,0,0.08) | border: 1px solid #EEE | padding: 20px`

**Brutalist/Neubrutalist**
`font: 'IBM Plex Mono' 12px | color: #000 on #FFF | border: 2px solid #000 | radius: 0 | shadow: 4px 4px 0 rgba(0,0,0,0.3) | no transitions`

**Japanese Information Density** (Muji, Uniqlo)
`font: 'Yu Gothic' 14px | line-height: 1.4 | color: #222 | gap: 12px | padding: 16px | border: 1px solid #E0E0E0 | radius: 0-4px | dense hierarchy, single accent`

**Neomorphism/Soft UI**
`bg: #E8F0F7 | raised: shadow 8px 8px 16px #B8BEC7, -8px -8px 16px #FFF | pressed: inset same | radius: 16px | border: none | bg must match parent`

**Claymorphism/3D Pastel**
`bg: linear-gradient(135deg, #F5D4E6, #FFE8D6) | radius: 40px | shadow: inset -2px -2px 5px rgba(255,255,255,0.7), inset 3px 3px 5px rgba(0,0,0,0.1), 0 8px 20px rgba(0,0,0,0.12)`

**Data-Dense/Terminal**
`font: 'Courier New' 11px | line-height: 1.4 | bg: #F5F5F5 | td: padding 2px 6px, border 1px solid #D0D0D0 | radius: 0 | status: green #4CAF50, amber #FF9800, red #F44336`

**Retro/Nostalgic** (90s, vaporwave)
`font: 'Courier New' | color: #00FF88 on #0A0A0A | text-shadow: 0 0 10px #00FF88, 0 0 20px #0088FF | border: 1px solid #00FF88 | radius: 0 | scanlines: bg-image linear-gradient(0deg, rgba(0,0,0,0.15) 50%, transparent 50%) bg-size 100% 4px`

### D. Art & Architecture Movement Profiles

**Art Deco** — Geometric luxury, gilt edges, commanding verticals.
`font: 'Bodoni Moda' serif 16px | color: #0A1B3D navy on #FFF | accent: #D4AF37 gold | border: 2px solid #0A1B3D | radius: 0 | shadow: 6px 6px 0 rgba(0,0,0,0.2) | clip-path: chamfered corners | letter-spacing: 0.15em uppercase`

**Bauhaus** — Primary colors, geometric shapes, functional form.
`font: 'Futura' sans-serif 14px | colors: #C8302A red, #E8C018 yellow, #1E3878 blue on #FFF | border: none | radius: 0 | shadow: none | grid-based layout | geometric accents only`

**De Stijl/Mondrian** — Black grid, primary blocks, pure orthogonality.
`font: 'Helvetica Neue' 12px | color: #000 on #FFF | accent: #FF0000, #0000FF, #FFD700 | border: 6px solid #000 | radius: 0 | shadow: none | CSS Grid rigid structure | no curves anywhere`

**Memphis Design** — Pastels + bold primaries, playful geometry, 80s irreverence.
`font: 'Space Grotesk' 14px weight-700 | colors: #F48196 pink, #86CCCA teal, #C9AECF lavender, #FFD700 | radius: 30px | shadow: 3px 3px 0 rgba(0,0,0,0.15) | decorative: squiggly borders, geometric patterns`

**Cyberpunk/Sci-Fi** — Neon on black, terminal aesthetic, digital decay.
`font: 'Space Mono' monospace 12px | color: #18E0FF cyan on #0B0C10 | accent: #FF3CF2 magenta | border: 1px solid #18E0FF | radius: 2px | shadow: 0 0 20px rgba(24,224,255,0.4) | text-shadow: 0 0 10px currentColor | scanlines: bg-image repeating-linear-gradient`

**Art Nouveau** — Organic curves, earth tones, ornamental flowing lines.
`font: 'Cormorant Garamond' serif 16px weight-300 | color: #3D3D1F on #E8DCC8 | accent: #8B5A3C copper | radius: 50% organic | shadow: none | border: decorative SVG curves | transition: 500ms ease`

**Mid-Century Modern** — Atomic-age optimism, warm geometry, retro palette.
`font: 'DM Sans' 14px | color: #1A1A1A on #F5F1E8 cream | accent: #DE6F20 burnt-orange, #009B8D teal, #E8AB18 mustard | border: 1px solid #1A1A1A | radius: 2px | shadow: 2px 2px 4px rgba(0,0,0,0.15)`

**Vaporwave/Synthwave** — Pink/purple haze, retro grid, digital nostalgia.
`font: 'Space Mono' 12px | gradient: linear-gradient(135deg, #FF71CE, #01CDFE) | bg: #0F0F1E | border: 1px solid rgba(255,113,206,0.3) | radius: 0 | shadow: 0 0 15px rgba(255,113,206,0.4) | perspective grid overlay`

**Y2K/Frutiger Aero** — Glossy, translucent, sky-blue optimism, bubble shapes.
`font: 'Inter' 13px weight-500 | color: #1A1A1A on #87CEEB to #FFF gradient | accent: #32CD32 lime | border: 2px solid rgba(255,255,255,0.6) | radius: 24px | shadow: 0 8px 16px rgba(0,0,0,0.1) | backdrop-filter: blur(12px) brightness(1.1) | glossy surfaces`

**Wabi-Sabi/Zen** — Imperfect, muted earth, asymmetric, generous negative space.
`font: 'Georgia' serif 15px | color: #5D6E5E on #F5F3F0 | accent: #A9927D warm-stone | border: none | radius: 4px | shadow: none | CSS Grid unequal columns (5fr 7fr) | generous padding: 48px+ | no animations`

### E. Niche Product Profiles

**Spotify** — Dark-first, bold green accent, music energy.
`bg: #191414 | surface: #121212 | text: #FFFFFF | accent: #1DB954 | font: 'Circular Sp' / system 14px | radius: 500px pills, 8px buttons | depth: no shadows, bg-color separation | spacing: 8px grid`

**Telegram** — Light blue, fast messaging, minimal chrome.
`bg: #FFFFFF | surface: #F5F5F5 | text: #000000 | accent: #0088CC | font: system 16px | radius: 8px cards, 24px avatars | depth: 1px borders only | spacing: 12px grid`

**Obsidian** — Dark purple-gray, knowledge graph, markdown-native.
`bg: #1E1E2E | surface: #2D2D3D | text: #E0E0E0 | accent: #6C31E3 | font: system mono 14px | radius: 4px elements, 8px panels | depth: no shadows, borders | spacing: 6px grid`

**Arc Browser** — Colorful, spatial, playful but functional.
`bg: #FFFFFF | surface: #F9F9F9 | text: #000000 | accent: #3139FB indigo | secondary: #FF5060 coral | font: system 13px | radius: 8px cards, 12px tabs | depth: subtle 2px shadows | spacing: 8px grid`

**Figma** — Light, purple accent, collaborative precision.
`bg: #FFFFFF | surface: #F5F5F5 | text: #333333 | accent: #7B61FF | font: Inter 12px | radius: 4px components, 8px buttons | depth: 1px borders | spacing: 8px grid`

**Monzo** — Bold coral neobank, card-centric, mobile-first.
`bg: #FFFFFF | surface: #F8F8F8 | text: #111111 | accent: #D96949 coral | font: system 16px | radius: 12px cards, 20px buttons | depth: 4px card shadows | spacing: 16px grid`

**Superhuman** — Minimal, keyboard-first, speed-obsessed.
`bg: #0F0F10 | surface: #1A1A1B | text: #EEEEEE | accent: #5B9EFF | font: 'Operator Mono' 13px | radius: 0 | depth: no shadows | spacing: 4px grid`

**Things 3** — Clean white, subtle depth, craft-focused task management.
`bg: #FFFFFF | surface: #F9F9F9 | text: #333333 | accent: #2DA6DA | font: system 14px | radius: 8px cards, 12px buttons | depth: subtle soft shadows | spacing: 12px grid`

**Bear/iA Writer** — Extreme minimalism, typography-first writing tools.
`bg: #FFFFFF / #F5F6F6 | text: #424242 | accent: #FF9500 (Bear) / #333 (iA) | font: custom sans 15px | radius: 0 | depth: none | spacing: 8px grid | max-width: 65ch`

**Supabase** — Dev-tool dark, Postgres green, technical density.
`bg: #11181C | surface: #1B2330 | text: #C9D1D9 | accent: #34B27B | font: mono 13px | radius: 4px | depth: 1px borders | spacing: 4px grid`

**Tailwind UI** — Clean defaults, utility-driven, developer-trusted.
`bg: #FFFFFF | surface: #F9FAFB | text: #111827 | accent: #3B82F6 | font: system 14px | radius: 6px components, 8px buttons | depth: 1px borders + subtle shadows | spacing: 4px base`

**Framer** — Motion-forward, bold typography, creative energy.
`bg: #FFF / #0F0F10 | surface: #F5F5F5 / #1A1A1A | text: #000 / #FFF | accent: #2563EB | font: Inter 14px weight-700 headings | radius: 8px | depth: motion shadows on hover | spacing: 8px grid`

### F. Regional/Cultural Profiles

**Korean** (Naver, Kakao) — Extreme density, animated, mobile-first, vibrant CTAs.
`font: 'Nanum Barun Gothic' 14px | color: #1A1A1A | bg: #FFFFFF | accent: #FF5D31 orange | secondary: #00D4FF | radius: 4px | shadow: 0 2px 8px rgba(0,0,0,0.12) | spacing: 4px grid | dense layout, small gaps, heavy information`

**Chinese** (Ant Design, WeChat) — Systematic tokens, structured hierarchy, blue primary.
`font: 'PingFang SC' / system 14px | color: #000000 | bg: #FAFAFA | primary: #1677FF | success: #52C41A | error: #FF4D4F | warning: #FAAD14 | border: 1px solid #D9D9D9 | radius: 2px | shadow: 0 2px 8px rgba(0,0,0,0.06) | spacing: 8px token grid`

**Indian** (Flipkart, Swiggy, CRED) — Bold deals, celebration-driven, mobile-optimized.
`font: Inter / Rubik 14px | color: #152336 | bg: #F1F3F6 | primary: #0C73EB blue | accent: #FC8019 orange | highlight: #F8E831 yellow | radius: 8px | shadow: 0 4px 12px rgba(0,0,0,0.15) | spacing: 8px/16px | bold CTAs, deal badges, celebration gradients`

**Arabic/Middle Eastern** — RTL, ornamental geometry, calligraphic, rich golds.
`direction: rtl | font: 'Segoe UI' / Arabic Typesetting 16px | color: #1A1A1A | bg: #F5F5F5 | primary: #0066CC | accent: #D4AF37 gold | radius: 4px | shadow: 0 2px 6px rgba(0,0,0,0.1) | spacing: 16px | border-top: 3px solid gold on headers | geometric pattern overlays at 10% opacity`

**Latin American** (Nubank, Mercado Libre) — Bold fintech, vibrant, disruptive energy.
`font: system sans 14px weight-600 | color: #1A1A1A | bg: #FFFFFF | primary: #8C1CE4 purple (Nubank) | accent: #FFE600 yellow (MeLi) | radius: 12px | shadow: 0 8px 16px rgba(0,0,0,0.1) | spacing: 16px | mobile-first stacks | bright gradients`

**African** (M-Pesa, Flutterwave) — Mobile-first, accessibility-focused, bold greens, practical.
`font: Inter / system 16px | color: #1A1A1A | bg: #FFFFFF | primary: #3AA335 green | accent: #FF6B35 orange | radius: 8px | shadow: 0 2px 8px rgba(0,0,0,0.1) | spacing: 12px/16px | WCAG AA minimum | 44px min touch targets | high contrast, large body text`

**German/Swiss Enterprise** (SAP Fiori) — Structured, systematic, compliance-ready.
`font: 'SAP 72' / system sans 14px | color: #1A1A1A | bg: #FFFFFF | primary: #0A6ED1 | success: #107E3E | error: #BB0000 | warning: #E89B00 | radius: 0 | shadow: 0 1px 3px rgba(0,0,0,0.08) | spacing: 8px grid | persistent left nav | audit-ready structure`

### G. Profile Selection Strategy

For N variations, mix across ALL categories (A-F). The wider the spread, the more genuinely different the output.

**Example for 8 variations:**
- 2 product profiles (A/E): Linear + Monzo
- 1 industry profile (B): Editorial
- 2 movement profiles (C/D): Brutalist + Art Deco
- 1 niche product (E): Bear/iA Writer
- 1 regional (F): Korean density
- 1 hybrid: "Wabi-Sabi meets Stripe" — generous whitespace + editorial trust signals

**Example for 12 variations:**
- 2 product (A): Stripe, Vercel
- 2 industry (B): Fintech, Gaming
- 2 classic movements (C): Swiss, Neomorphism
- 2 art movements (D): Cyberpunk, Mid-Century Modern
- 2 niche products (E): Obsidian, Things 3
- 1 regional (F): Latin American
- 1 hybrid: "Japanese Density meets Linear" — dark, dense, monospaced metrics

**Rules:**
- Never pick 2+ profiles from the same subcategory (e.g., don't use both Linear and Vercel — they're too similar)
- At least one profile should be from D (art movements) or F (regional) — these produce the most unexpected results
- Hybrids combine two profiles from different categories — name both parents explicitly
- For 4 or fewer variations: at least 3 different categories represented
- For 8+: at least 5 different categories represented

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

## 9. Structural Mutation Recipes

CSS-only variations are themes, not designs. This section lists fundamentally different HTML structures for common component types. Each structure implies a different DOM tree — not just different class names on the same elements.

**Rule: at least half the variations in any set must use a different structure from this list (or one you invent). Two variations that share a structure must come from very different profiles to justify it.**

### Quick-reference cheatsheet

Cite these codes in your variation plan. Full structure details below.

| Toast | | Pricing | | Login | |
|---|---|---|---|---|---|
| T1 | flex-row (icon│content│×) | P1 | 3-col card grid | L1 | centered card |
| T2 | full-width bar, two-row | P2 | horizontal rows (table-like) | L2 | split-screen (brand│form) |
| T3 | stacked col + action row | P3 | featured + 2 thumbnails | L3 | minimal inline (no frame) |
| T4 | terminal block (pre>code) | P4 | tabbed single-card | L4 | step-by-step (fieldsets) |
| T5 | text-only, no frame | P5 | carousel / slider | L5 | social-first with email fallback |
| T6 | ultra-dense single line | P6 | comparison matrix (table) | L6 | dense horizontal (label│input) |
| T7 | split panel (icon│content) | P7 | vertical accordion | L7 | full-page takeover |
| T8 | expandable (`<details>`) | P8 | asymmetric split | L8 | command-line (pre>code) |
| T9 | bottom-sheet with progress | P9 | progressive reveal | | |
| T10 | timeline entry (dot on line) | P10 | full-bleed stacked sections | | |

For components not listed (buttons, badges, modals, nav bars, data tables…), invent a code in the same style and document the structure in your variation plan comment.

### Toast / Notification

| # | Structure | HTML skeleton | Good profiles |
|---|-----------|--------------|---------------|
| T1 | Standard inline | `flex-row: icon + column(title, msg) + close` | Stripe, Tailwind, GitHub |
| T2 | Full-width bar | `flex-row across viewport: icon + title + msg + dismiss` — no card, no shadow, just a bar at edge of screen | Vercel, Swiss, Government |
| T3 | Stacked vertical | `flex-col: icon centered → title → msg → action-row(buttons)` | Monzo, Things 3, Apple |
| T4 | Terminal / code block | `pre-formatted block: status-line + message + command-row` — monospace, no "card" feel | Cyberpunk, Linear, Data-Dense, Supabase |
| T5 | Minimal text-only | No icon, no card, no border — just styled text with generous whitespace and a subtle dismiss | Wabi-Sabi, Bear/iA Writer, Luxury |
| T6 | Dense single-line | Everything on one line: `icon · title · msg · timestamp · ×` — maximum information, minimum height | Korean, Japanese, Telegram |
| T7 | Split panel | `grid: 2 columns — left column is icon/status zone (colored bg), right column is content` | Art Deco, De Stijl, Mid-Century |
| T8 | Expandable | Collapsed: `icon + title + chevron`. Expanded: reveals message + actions. Two-state HTML. | Figma, Arc, Obsidian |
| T9 | Bottom sheet | Wider, shorter, anchored to bottom — `flex-row with progress bar on top edge` | Spotify, Monzo (mobile) |
| T10 | Timeline entry | No card — a dot/line on a vertical timeline, content beside it. For notification lists. | Notion, GitHub, Linear |

### Pricing Card / Tier Comparison

| # | Structure | HTML skeleton | Good profiles |
|---|-----------|--------------|---------------|
| P1 | Side-by-side columns | `grid: 3 equal columns, each a card` — the standard | Stripe, Tailwind, Apple |
| P2 | Stacked comparison | `flex-col: each tier is a horizontal row with name/price/features/CTA in columns` — table-like | Swiss, Data-Dense, Government, SAP |
| P3 | Featured + thumbnails | `grid: 1 large featured card + 2 smaller cards beside or below it` — hero tier | Luxury, Editorial, Apple |
| P4 | Tabbed / toggle | One card, tabs or segmented control to switch between tiers — only one visible at a time | Arc, Figma, Superhuman |
| P5 | Slider / carousel | One tier visible, arrows or dots to navigate between — mobile-first | Spotify, Monzo, Korean |
| P6 | Comparison matrix | No individual cards — a grid/table with features as rows, tiers as columns, checkmarks | Linear, GitHub, Japanese, SAP |
| P7 | Vertical accordion | Each tier is a collapsible section — expand to see features | Things 3, Notion, Bear |
| P8 | Asymmetric split | Two tiers get 30% width, featured tier gets 40% — intentional imbalance | Editorial, De Stijl, Wabi-Sabi |
| P9 | Progressive reveal | Start with prices only, "See details" expands features per tier | Vercel, Superhuman, Telegram |
| P10 | Full-bleed tier pages | Each tier is a full-width section with its own background treatment, stacked vertically | Luxury, Art Deco, Brutalist |

### Login / Auth Form

| # | Structure | HTML skeleton | Good profiles |
|---|-----------|--------------|---------------|
| L1 | Centered card | `centered container: heading + inputs + button + links` — the standard | Stripe, Tailwind, GitHub |
| L2 | Split screen | `grid: 2 columns — left is brand/illustration panel, right is form` | Apple, Luxury, Art Deco, Spotify |
| L3 | Minimal inline | No card, no border — just inputs and button floating in whitespace | Wabi-Sabi, Bear, Vercel |
| L4 | Step-by-step | Email on screen 1, password on screen 2 — progressive disclosure (simulate with CSS states) | Superhuman, Arc, Linear |
| L5 | Social-first | Large social login buttons at top, email/password collapsed below "or use email" divider | Figma, Spotify, Arc |
| L6 | Dense horizontal | Labels and inputs side-by-side (label left, input right), compact | Japanese, Korean, SAP, Data-Dense |
| L7 | Full-page takeover | No card — form elements at vertical center of a full-color or full-image background | Luxury, Art Deco, Vaporwave |
| L8 | Command-line | Terminal-style: `>email:` then `>password:` with blinking cursor, monospace | Cyberpunk, Linear, Supabase, Data-Dense |

### Generic Component (buttons, badges, cards, modals)

For any component not listed above, generate structural variety by varying these axes:

1. **Containment**: card vs. inline vs. floating vs. full-width vs. none (bare elements)
2. **Axis**: horizontal vs. vertical vs. grid vs. radial
3. **Element count**: add elements (timestamp, avatar, tag, secondary action) or remove them (icon-only, text-only)
4. **Interaction shape**: static vs. expandable vs. togglable vs. draggable affordance
5. **Information density**: one piece of data per view vs. all data visible vs. progressive disclosure

---

## 10. Interaction Polish (formerly §9)

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
