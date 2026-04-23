# Profile Fidelity Reference

A variation claims a profile (Stripe, Linear, Cyberpunk, Luxury…) only if its CSS actually uses that profile's exact tokens. Naming "Stripe" in a plan comment then writing `border-radius: 12px; color: #3b82f6` is a lie — Stripe ships 4px radius and #635BFF.

This reference restates each of the most-used profiles from `design-principles.md` §2 as an **execution card**. Execution cards are stricter than the token list — they specify must-have imports, must-have tokens, and forbidden drifts.

## Usage

During step 4b (profile fidelity gate) of the skill workflow:

1. For each variation, copy its execution card into a CSS comment directly above that variation's scoped styles.
2. Use the card's exact hex values, exact radius, exact font-family string, exact transition timing. No rounding. No paraphrasing.
3. If a card requires a web font (e.g. Cormorant Garamond), the HTML `<head>` MUST include a matching Google Fonts `<link>` AND the variation's CSS MUST use the font with no system fallback that overrides it.
4. If you deviate from any token in the card, that variation fails the gate. Rebuild.

## Execution Cards

### Stripe (inspired by stripe.md)
- **Fonts:** `sohne-var` with OpenType `"ss01"` @ 16px weight-300 body, weight-400 buttons; fallback `SF Pro Display, -apple-system, sans-serif`
- **Background:** `#ffffff`
- **Text:** `#061b31` (deep navy for headings), `#64748d` (slate for body)
- **Surface:** `#f6f9fc` (subtle surface tint)
- **Accent:** `#533afd` (Stripe purple — NOT #3b82f6)
- **Border:** 1px solid `#e5edf5`
- **Radius:** 4px–8px (buttons 4px, cards up to 8px)
- **Shadow:** `rgba(50,50,93,0.25) 0px 30px 45px -30px, rgba(0,0,0,0.1) 0px 18px 36px -18px` (multi-layer, blue-tinted)
- **Button:** 8px 16px padding, 16px weight-400 with `"ss01"`
- **Input:** 40px height, `1px solid #e5edf5` border, focus `#533afd`
- **Card:** 4px–8px radius, border `#e5edf5`, shadow on hover
- **Depth:** Elevated `rgba(50,50,93,0.25) 0px 30px 45px -30px, rgba(0,0,0,0.1) 0px 18px 36px -18px`
- **Breakpoints:** 640 / 1024 / 1280
- **Touch targets:** 8px 16px button padding
- **Do:** Enable OpenType `"ss01"` on all sohne-var text; use weight 300 for headlines; apply blue-tinted shadows for elevation
- **Don't:** Use weight 600+ on sohne-var; use radius > 8px on cards; skip `"ss01"` feature; use pure black for headings
- **Forbidden:** radius > 4px on primary buttons; cyan/teal accents; neon glows; weight 700+ headlines
- **Font substitutes:** `Inter` for sohne-var (increase line-height +0.06 on body)
- **Known gaps:** Custom sohne-var font with `"ss01"` stylistic set not reproducible in CSS; use weight 300 Inter as closest approximation
- **Source:** getdesign.md/stripe/design-md

### Linear (inspired by linear.app.md)
- **Fonts:** `Inter Variable` with OpenType `"cv01", "ss03"` @ 16px weight-400 body, weight-510 UI; fallback `-apple-system, system-ui, Segoe UI`
- **Background:** `#08090a` (marketing), `#0f1011` (panels), `#191a1b` (surfaces)
- **Text:** `#f7f8f8` (primary), `#d0d6e0` (secondary), `#8a8f98` (tertiary)
- **Muted text:** `#62666d` (quaternary)
- **Accent:** `#5e6ad2` (brand indigo for bg), `#7170ff` (accent interactive)
- **Border:** `1px solid rgba(255,255,255,0.08)` (standard), `rgba(255,255,255,0.05)` (subtle)
- **Radius:** 6px (standard), 8px (cards), 12px (panels)
- **Shadow:** None — use background opacity stepping instead (`rgba(255,255,255,0.02/0.04/0.05)`)
- **Button:** 8px 16px padding, 6px radius, `rgba(255,255,255,0.02)` bg or brand indigo
- **Input:** 12px 14px padding, 6px radius, `rgba(255,255,255,0.02)` bg, `1px solid rgba(255,255,255,0.08)` border
- **Card:** `rgba(255,255,255,0.02)` bg, `1px solid rgba(255,255,255,0.08)` border, 8px radius
- **Depth:** Surface luminance stepping: `rgba(255,255,255,0.02)` → `0.04` → `0.05)`
- **Breakpoints:** 600 / 640 / 768 / 1024 / 1280
- **Touch targets:** Buttons 6px radius, 8px 16px padding
- **Do:** Use Inter Variable weight 510 as emphasis; apply `"cv01", "ss03"` on all text; use semi-transparent white borders
- **Don't:** Use weight 700; use solid dark borders; apply brand indigo decoratively; use pure white text
- **Forbidden:** Solid colored backgrounds on buttons; positive letter-spacing on display; weight > 590
- **Known gaps:** OpenType features `"cv01", "ss03"` not available in system Inter; use standard weight 500 as fallback
- **Source:** getdesign.md/linear.app/design-md

### Vercel / Geist (inspired by vercel.md)
- **Fonts:** `Geist` with OpenType `"liga"` @ 16px weight-400 body, weight-500 UI, weight-600 headings; fallback `Arial, Segoe UI, sans-serif`
- **Background:** `#ffffff` (primary), `#fafafa` (subtle tint)
- **Text:** `#171717` (primary — not pure black), `#4d4d4d` (secondary), `#808080` (placeholder)
- **Border:** `rgba(0,0,0,0.08) 0px 0px 0px 1px` (shadow-as-border technique)
- **Radius:** 6px (buttons), 8px (cards), 12px (featured)
- **Shadow:** Multi-layer stack: `rgba(0,0,0,0.08) 0px 0px 0px 1px, rgba(0,0,0,0.04) 0px 2px 2px, rgba(0,0,0,0.04) 0px 8px 8px -8px, #fafafa 0px 0px 0px 1px`
- **Button:** 8px 16px padding, 6px radius, shadow-border, weight-500
- **Input:** border via shadow-as-border, 6px radius, `#ffffff` bg
- **Card:** `#ffffff` bg, shadow-border + elevation stack, 8px radius
- **Gradients:** Soft pastel gradient wash behind hero (optional, barely visible)
- **Depth:** Shadow stacking (border + elevation + ambient + inner highlight via `#fafafa`)
- **Breakpoints:** 400 / 600 / 768 / 1024 / 1200
- **Touch targets:** Buttons 8px 16px padding, 6px radius
- **Do:** Use Geist with `"liga"` enabled; apply shadow-as-border instead of CSS border; use -2.4px letter-spacing at display sizes
- **Don't:** Use traditional CSS borders; use weight 700; introduce warm colors; skip ligatures
- **Forbidden:** border-radius > 8px on cards; pure black text; colorful accents; thick shadows
- **Known gaps:** Geist font not available; use Inter weight 500/600 with -1.2px letter-spacing at 48px as approximation
- **Source:** getdesign.md/vercel/design-md

### GitHub / Primer
- **Fonts:** `-apple-system, "Segoe UI", sans-serif` @ 14px
- **Background:** `#FFF`
- **Subtle surface:** `#F6F8FA`
- **Text:** `#1F2328`
- **Accent:** `#0969DA` (GitHub blue — NOT #3b82f6)
- **Success:** `#238636`
- **Danger:** `#DA3633`
- **Border:** 1px solid `#D0D7DE`
- **Radius:** 6px
- **Shadow:** `0 1px 0 rgba(27,31,36,0.04)` (super-subtle)
- **Button:** 8px 16px padding

### Notion (inspired by notion.md)
- **Fonts:** `NotionInter` (modified Inter) with OpenType `"lnum", "locl"` @ 16px weight-400 body, weight-500 UI, weight-600 semi-bold, weight-700 display; fallback `Inter, -apple-system, system-ui`
- **Background:** `#ffffff` (primary), `#f6f5f4` (warm white tint)
- **Text:** `rgba(0,0,0,0.95)` (primary — not pure black), `#615d59` (secondary warm gray)
- **Muted text:** `#a39e98` (warm gray for placeholders)
- **Accent:** `#0075de` (Notion blue), `#097fe8` (badge/focus blue)
- **Border:** `1px solid rgba(0,0,0,0.1)` (whisper border)
- **Radius:** 4px (buttons), 12px (cards), 16px (featured)
- **Shadow:** 4-layer card stack: `rgba(0,0,0,0.04) 0px 4px 18px, rgba(0,0,0,0.027) 0px 2.025px 7.85px, rgba(0,0,0,0.02) 0px 0.8px 2.93px, rgba(0,0,0,0.01) 0px 0.175px 1.04px`
- **Button:** 8px 16px padding, 4px radius, weight-600 @ 15px, hover scale(1.05)
- **Input:** 6px padding, 4px radius, `#ffffff` bg, `#a39e98` placeholder
- **Card:** `#ffffff` bg, 12px radius, whisper border, 4-layer shadow
- **Depth:** Multi-layer shadow with sub-0.05 opacity, background color alternation
- **Breakpoints:** 400 / 600 / 768 / 1080 / 1200
- **Touch targets:** Buttons 8px 16px padding
- **Do:** Use warm neutrals (#f6f5f4, #615d59, #a39e98); apply -2.125px letter-spacing at 64px; layer shadows with opacity ≤ 0.05
- **Don't:** Use cool grays; apply shadows on primary surfaces; use accents other than blue; use pure black text
- **Forbidden:** Cool gray palette; heavy shadows; single-radius design; non-warm neutrals
- **Known gaps:** NotionInter proprietary font; use Inter weight 400/600/700 with warm color palette as substitute
- **Source:** getdesign.md/notion/design-md

### Apple / HIG (inspired by apple.md)
- **Fonts:** `SF Pro Display` (hero/headings) and `SF Pro Text` (body/controls) @ 17px weight-400 body, weight-600 headings; fallback `Helvetica Neue, Arial, sans-serif`
- **Background:** `#ffffff` (primary), `#f5f5f7` (pale gray), `#000000` (immersive black)
- **Text:** `#1d1d1f` (primary), `#6e6e73` (secondary)
- **Accent:** `#0071e3` (action blue), `#0066cc` (body link blue), `#2997ff` (high-luminance)
- **Border:** `#d2d2d7` (soft gray), `#86868b` (mid gray for stronger definition)
- **Radius:** 6px–8px (buttons), 12px–18px (cards), 28px–36px (featured), 50px (capsules)
- **Shadow:** Minimal — `rgba(0,0,0,0.08)` to `rgba(0,0,0,0.22)` where used; depth via tonal contrast
- **Button:** Capsule (18px–56px radius) or 8px radius, 8px 15px padding, weight-600
- **Input:** Translucent/white bg, `#86868b` border, 8px radius, `#1d1d1f` text
- **Card:** White bg, minimal framing, image-first composition, 12px–18px radius
- **Depth:** Tonal contrast and surface stepping (`#000000` ↔ `#f5f5f7` ↔ `#ffffff`), minimal shadows
- **Breakpoints:** 375 / 640 / 833 / 1024 / 1240
- **Touch targets:** 44px minimum (controls, buttons)
- **Do:** Reserve blue for actions only; keep chrome understated; use capsule/circle geometry; let imagery carry drama
- **Don't:** Introduce secondary accent palettes; overuse shadows; mix unrelated fonts; use radius inconsistently
- **Forbidden:** Broad secondary accents; heavy shadows; unrelated font families; flat corners (use intentional radius tiers)
- **Known gaps:** SF Pro Display/Text proprietary; use `Inter` + increase line-height +0.02–0.06 on body
- **Source:** getdesign.md/apple/design-md

### Editorial / Magazine (NYT, The Verge, Bloomberg)
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Playfair Display` weights 400,600,700 AND `Source Serif 4` (or `Source Serif Pro` fallback) weight 400.
- **Heading font:** `"Playfair Display", Georgia, serif`
- **Body font:** `"Source Serif 4", Georgia, serif` @ 18px
- **Line-height:** 1.6 body, 1.15 headlines
- **Letter-spacing:** -0.02em headlines, 0 body
- **Text color:** `#2C3E50`
- **Background:** `#F8F9FA`
- **Rules / dividers:** 1px solid `#DDD`
- **Radius:** 0 (editorial design is square)
- **Max line length:** 65ch body
- **Forbidden:** sans-serif body text; rounded corners; colored accents; shadows

### Luxury / Fashion (Aesop, Hermès, Bottega Veneta)
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Cormorant Garamond` weights 300,400,500.
- **Font:** `"Cormorant Garamond", Georgia, serif` @ 15px weight-300
- **Heading:** same font, larger (36–48px)
- **Letter-spacing:** 0.1em (tracking for elegance)
- **Line-height:** 1.8
- **Text color:** `#544D4B` (warm gray-brown — NOT #111827, NOT #000)
- **Accent:** `#760402` (burgundy — NOT coral, NOT warm-stone, NOT green-brown)
- **Background:** `#F5F2EE` (warm cream) OR pure white
- **Padding:** 48px minimum on primary surfaces
- **Radius:** 0
- **Transitions:** 600ms ease (SLOW — never 150ms or 200ms)
- **Forbidden:** sans-serif fonts anywhere; radii > 0; fast transitions; cool grays; bright accents

### Wabi-Sabi / Bear / iA Writer
- **REQUIRED FONT IMPORT:** `Georgia` (system) OR `<link>` for `iA Writer Quattro` / `Lora`.
- **Font:** `"iA Writer Quattro", "Lora", Georgia, serif` @ 15–17px
- **Text color:** `#5D6E5E` (sage gray — NOT #111827)
- **Accent:** `#A9927D` (warm stone — used sparingly, for dismiss links or subtle dividers)
- **Background:** `#FAF9F6` (paper) OR `#FFF`
- **Padding:** 48px+ (generous whitespace)
- **Radius:** 0 or 4px (minimal)
- **Shadow:** NONE
- **Transitions:** NONE or very slow (400ms+) on opacity only
- **Forbidden:** any sans-serif primary text; animations faster than 400ms; accent colors outside the muted stone/sage palette; shadows

### Brutalist / Neubrutalist
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `IBM Plex Mono` weights 400,600.
- **Font:** `"IBM Plex Mono", monospace` @ 12–14px
- **Text color:** `#000`
- **Background:** `#FFF` or one flat vivid color (e.g. `#FFD700`, `#FF3366`)
- **Border:** 2px solid `#000` (thick, always black, always sharp)
- **Radius:** 0
- **Shadow:** `4px 4px 0 rgba(0,0,0,1)` (hard drop — no blur)
- **Transitions:** NONE (Brutalism rejects smooth transitions)
- **Forbidden:** soft shadows; rounded corners; pastel colors; smooth animations

### Cyberpunk / Supabase / Data-Dense
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Space Mono` weight 400,700 AND `JetBrains Mono` as fallback.
- **Font:** `"Space Mono", "JetBrains Mono", "IBM Plex Mono", monospace` @ 12–13px
- **Background:** `#0B0C10` (deep blue-black — NOT pure #000)
- **Surface:** `#1F2833`
- **Primary text:** `#18E0FF` (electric cyan) OR `#66FCF1` (mint)
- **Accent:** `#FF3CF2` (magenta) for danger / emphasis
- **Border:** 1px solid `rgba(24,224,255,0.3)` (cyan @ 30%)
- **Shadow (glow):** `0 0 20px rgba(24,224,255,0.4), 0 0 40px rgba(24,224,255,0.2)` — DEEP glow, not weak (0.15 is too weak)
- **Text-shadow:** `0 0 10px currentColor`
- **Radius:** 0 or 2px
- **Forbidden:** sans-serif anywhere; radii > 2px; subtle shadows (go LOUD or don't claim cyberpunk)

### Art Deco
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Bodoni Moda` weights 400,600 AND `Playfair Display` fallback.
- **Font:** `"Bodoni Moda", "Playfair Display", Georgia, serif`
- **Text color:** `#0A1B3D` (deep navy) on light; `#D4AF37` (gold) on dark
- **Accent:** `#D4AF37` (gold — the defining token)
- **Background:** `#F5F2EE` cream OR `#0A1B3D` navy
- **Border:** 2px solid `#D4AF37` or `#0A1B3D`
- **Radius:** 0 (sharp angles, never rounded)
- **Shadow:** `6px 6px 0 rgba(0,0,0,0.2)` (hard offset, no blur)
- **Patterns:** geometric, symmetric, strong verticals
- **Forbidden:** sans-serif primary text; radii > 0; soft shadows; pastel colors

### Monzo
- **Fonts:** `system-ui, "Inter", sans-serif`
- **Accent:** `#FF4F40` (Monzo coral — NOT red, NOT orange-red generic)
- **Surface:** `#FFF` or `#14233C` (dark mode)
- **Text (light):** `#14233C`
- **Text (dark):** `#FFF`
- **Radius:** 12px cards, 8px buttons (generous)
- **Shadow:** `0 4px 12px rgba(0,0,0,0.08)`
- **Font-variant-numeric:** `tabular-nums` (banking — numbers must align)
- **Forbidden:** radii < 8px; non-tabular numerics on money displays

### Spotify (inspired by spotify.md)
- **Fonts:** `SpotifyMixUI` / `CircularSp` @ 16px weight-400 body, weight-700 bold; fallback `system-ui, Helvetica Neue, Arial, sans-serif` (includes global scripts: Arabic, Hebrew, Cyrillic, Greek, Devanagari, CJK)
- **Background:** `#121212` (deepest), `#181818` (cards), `#1f1f1f` (interactive surfaces)
- **Text:** `#ffffff` (primary), `#b3b3b3` (secondary), `#cbcbcb` (near-white)
- **Muted text:** `#b3b3b3` (inactive nav), `#62666d` (disabled)
- **Accent:** `#1ed760` (Spotify green — only for play, active states, CTAs)
- **Border:** `#4d4d4d` (button borders), `#7c7c7c` (outlined borders)
- **Radius:** 4px (minimal), 8px (cards), 500px (pill buttons), 50% (play/circular)
- **Shadow:** Heavy on dark: `rgba(0,0,0,0.3) 0px 8px 8px` (cards), `rgba(0,0,0,0.5) 0px 8px 24px` (dialogs)
- **Button:** Pill 500px radius (large) or 9999px (small), 8px 16px padding, weight-700, uppercase + 1.4px–2px letter-spacing
- **Input:** Pill 500px radius, 12px 48px padding (icon-aware), inset border `rgb(124,124,124) 0px 0px 0px 1px inset`
- **Card:** `#181818` bg, 8px radius, `rgba(0,0,0,0.3)` shadow on hover
- **Depth:** Near-black layering: base `#121212` → surfaces `#181818/#1f1f1f` → elevated with shadows
- **Breakpoints:** <425 / 425–576 / 576–768 / 768–896 / 896–1024 / 1024–1280 / >1280
- **Touch targets:** Pill buttons 500px radius, circular play 50%
- **Do:** Use Spotify Green only for functional highlights; apply pill geometry to all buttons; use heavy shadows on dark; compact typography 10–24px range
- **Don't:** Use Spotify Green decoratively; use light backgrounds; skip pill geometry; use thin shadows; add secondary colors
- **Forbidden:** Green accents outside play controls; light-mode primary; non-pill button geometry; weak shadows on dark
- **Known gaps:** SpotifyMixUI proprietary; use system-ui weight 700/400 with green accent as substitute
- **Source:** getdesign.md/spotify/design-md

### Arc Browser
- **Fonts:** `"Inter", system-ui, sans-serif` @ 14px
- **Accent:** `#3139FB` (indigo — NOT #3b82f6)
- **Secondary accent:** `#FF5060` (coral)
- **Background:** `#FFF` with hints of `#F6F6FA`
- **Radius:** 12px
- **Shadow:** `0 2px 8px rgba(0,0,0,0.06)` subtle
- **Forbidden:** Tailwind blue `#3b82f6`; hard shadows

### Figma (inspired by figma.md)
- **Fonts:** `figmaSans` (variable) with weights 320/330/340/450/480/540/700 + OpenType `"kern"` @ 16px weight-330/400 body, weight-540 emphasis, weight-700 display; fallback `SF Pro Display, system-ui, helvetica`
- **Background:** `#ffffff` (primary), `rgba(0,0,0,0.08)` (subtle overlay)
- **Text:** `#000000` (pure black — all interface text), `#ffffff` (text on dark)
- **Border:** None or minimal; focus via dashed outlines
- **Radius:** 6px (small), 8px (cards), 50px (pills), 50% (circles)
- **Shadow:** Minimal — depth via background contrast and product screenshots; `rgba(0,0,0,0.08)–0.22` where used
- **Button:** Pill (50px) or circle (50%), weight-400, dashed 2px focus outline
- **Input:** Minimal styling, focus via dashed outline
- **Card:** White bg, 8px radius, minimal frame, product-screenshot driven
- **Gradients:** Vibrant multi-color hero gradient (green, yellow, purple, pink) for hero section only; no UI gradients
- **Depth:** Background contrast (white on gradient/dark) and image content; minimal shadows
- **Breakpoints:** <560 / 560–768 / 768–960 / 960–1280 / 1280–1440 / 1440–1920
- **Touch targets:** Pill/circle button geometry, adequate hit areas
- **Do:** Use variable font weights (320–540) precisely; keep interface strictly black + white; use dashed focus outlines; enable `"kern"` on all text
- **Don't:** Add interface colors; use standard font weights; use solid focus outlines; increase body weight > 450
- **Forbidden:** Interface colors beyond black + white; standard font weights; solid focus outlines; body weight > 450; rounded buttons (pill/circle only)
- **Known gaps:** figmaSans variable font not available; use `Inter` weights 300/400/600/700 with -0.14px letter-spacing as substitute
- **Source:** getdesign.md/figma/design-md

### Government / GOV.UK / USWDS
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Source Sans 3` weights 400,600,700.
- **Font:** `"Source Sans 3", system-ui, sans-serif` @ 16px (larger than most for accessibility)
- **Text:** `#0B0C0C` (GOV.UK specific — NOT #000)
- **Accent:** `#0050D8` (USWDS blue) OR `#1D70B8` (GOV.UK blue)
- **Background:** `#FFF`
- **Border:** 1px solid `#B1B4B6` (dividers)
- **Focus ring:** 3px solid `#FFDD00` (yellow — the signature GOV.UK focus)
- **Radius:** 0
- **Contrast:** WCAG AAA required
- **Forbidden:** radii > 0; low-contrast palettes; non-Source-Sans fonts; fancy animations

### Healthcare / One Medical / Calm
- **Font:** `"Open Sans", system-ui, sans-serif` @ 16px
- **Text:** `#2C3E50`
- **Accent:** `#17A2B8` (teal — clinical)
- **Background:** `#F8F9FA`
- **Radius:** 8px
- **Shadow:** `0 2px 8px rgba(0,0,0,0.06)`
- **Contrast:** WCAG AAA required
- **Forbidden:** aggressive accents; contrast below AAA

### Korean / Naver / Kakao
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Noto Sans KR` OR `Nanum Gothic`.
- **Font:** `"Noto Sans KR", "Nanum Gothic", system-ui, sans-serif` @ 13–14px
- **Text:** `#1A1A1A`
- **Accent:** `#FF5D31` (orange) OR `#03C75A` (Naver green)
- **Radius:** 4px
- **Density:** ULTRA-compact — 8–12px gaps, tight padding
- **Forbidden:** generous spacing; default web fonts

### Japanese / Muji / Uniqlo
- **REQUIRED FONT IMPORT:** `<link>` Google Fonts for `Noto Sans JP` OR use `"Yu Gothic"`.
- **Font:** `"Noto Sans JP", "Yu Gothic", sans-serif` @ 14px
- **Text:** `#222`
- **Line-height:** 1.4 (tighter)
- **Gap:** 12px
- **Padding:** 16px
- **Border:** 1px solid `#E0E0E0`
- **Radius:** 0–4px
- **Single accent:** one color per variation, no rainbows

---

## Brand-Inspired Profiles (from VoltAgent/awesome-design-md, MIT)

These cards are distilled from the upstream DESIGN.md corpus. Each claims inspiration from a public brand, not affiliation. For each card, the canonical source is `getdesign.md/<slug>/design-md`. When picking one of these profiles, treat its tokens as authoritative within a variation — drifting from the card = rebuild (per the "no generic drift" rule below).

### — AI & LLM Platforms —

### Claude (inspired by claude)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#141413`
- **Accent:** `#c96442`
- **Radius:** 8px
- **Breakpoints:** 479 / 640 / 767
- **Do:** Parchment (`#f5f4ed`) as the primary light background — the warm cream tone IS t
- **Don't:** use cool blue-grays anywhere — the palette is exclusively warm-toned
- **Source:** getdesign.md/claude/design-md

### Cohere (inspired by cohere)
- **Fonts:** CohereText
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#212121`
- **Radius:** 22px
- **Breakpoints:** 1024 / 1440 / 2560
- **Do:** 22px border-radius on all primary cards and containers — it's the visual signatu
- **Don't:** use border-radius other than 22px on primary cards — the signature radius matter
- **Source:** getdesign.md/cohere/design-md

### ElevenLabs (inspired by elevenlabs)
- **Fonts:** Waldenburg
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#f5f5f5`
- **Radius:** 20px
- **Breakpoints:** 1024
- **Do:** Waldenburg weight 300 for all display headings — the lightness IS the brand
- **Don't:** use bold (700) Waldenburg for headings — weight 300 is non-negotiable
- **Source:** getdesign.md/elevenlabs/design-md

### Minimax (inspired by minimax)
- **Fonts:** DM Sans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#3daeff`
- **Radius:** 9999px
- **Breakpoints:** 1024 / 768
- **Do:** white as the dominant background — let product cards provide the color
- **Don't:** add colored backgrounds to main content sections — white is structural
- **Source:** getdesign.md/minimax/design-md

### Mistral AI (inspired by mistral.ai)
- **Fonts:** Likely a custom font (Font Source detected) with
- **Background:** `#ffffff`
- **Text:** `#1f1f1f`
- **Accent:** `#fb6424`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1280 / 640
- **Do:** the warm color spectrum exclusively: ivory, cream, amber, gold, orange
- **Don't:** introduce cool colors (blue, green, purple) — the palette is exclusively warm
- **Source:** getdesign.md/mistral.ai/design-md

### Ollama (inspired by ollama)
- **Fonts:** SF Pro Rounded
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#262626`
- **Radius:** 12px
- **Breakpoints:** 1024 / 1280 / 640
- **Do:** pure white (`#ffffff`) as the page background — never off-white or cream
- **Don't:** introduce any chromatic color — no brand blue, no accent green, no warm tones
- **Source:** getdesign.md/ollama/design-md

### OpenCode (inspired by opencode.ai)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#fdfcfc`
- **Radius:** 6px
- **Breakpoints:** 1024 / 640 / 900
- **Do:** Follow upstream design principles
- **Don't:** Avoid drift from tokens
- **Source:** getdesign.md/opencode.ai/design-md

### Replicate (inspired by replicate)
- **Fonts:** rb-freigeist-neue
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#ea2804`
- **Radius:** 9999px
- **Breakpoints:** 128
- **Do:** pill-shaped (9999px) radius on EVERYTHING — buttons, images, badges, containers
- **Don't:** use any border-radius other than 9999px — the pill system is absolute
- **Source:** getdesign.md/replicate/design-md

### Runway ML (inspired by runwayml)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#030303`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1280 / 1600
- **Do:** full-bleed cinematic photography as the primary visual element
- **Don't:** add decorative colors to the interface — the only color comes from photography
- **Source:** getdesign.md/runwayml/design-md

### Together AI (inspired by together.ai)
- **Fonts:** The Future
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#fc4c02`
- **Radius:** 4px
- **Breakpoints:** 479 / 767 / 991
- **Do:** pastel gradients (pink/blue/lavender) for hero illustrations and decorative back
- **Don't:** use Brand Magenta (#ef2cc1) or Brand Orange (#fc4c02) as UI colors — they're for
- **Source:** getdesign.md/together.ai/design-md

### VoltAgent (inspired by voltagent)
- **Fonts:** system-ui
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#2fd6a1`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1440 / 1992
- **Do:** Abyss Black (`#050507`) as the landing page background and Carbon Surface (`#101
- **Don't:** use bright or light backgrounds as primary surfaces — the entire identity lives
- **Source:** getdesign.md/voltagent/design-md

### X.AI (inspired by x.ai)
- **Fonts:** GeistMono
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#1f2228`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1280 / 1536
- **Do:** `#1f2228` as the universal background -- never pure black `#000000`
- **Don't:** use box-shadows -- xAI has zero shadow elevation
- **Source:** getdesign.md/x.ai/design-md

### — Developer Tools —

### Cursor (inspired by cursor)
- **Fonts:** CursorGothic
- **Background:** `#f2f1ed`
- **Text:** `#26251e`
- **Accent:** `#f54e00`
- **Radius:** 8px
- **Breakpoints:** 1279 / 600 / 768
- **Do:** CursorGothic with aggressive negative letter-spacing at display sizes
- **Don't:** avoid drift from upstream tokens
- **Source:** getdesign.md/cursor/design-md

### Expo (inspired by expo)
- **Fonts:** Inter
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#1c2024`
- **Radius:** 36px
- **Breakpoints:** 1024 / 640
- **Do:** Cloud Gray (`#f0f0f3`) as the page background and Pure White (`#ffffff`) for ele
- **Don't:** introduce decorative colors into the interface chrome — the monochromatic palett
- **Source:** getdesign.md/expo/design-md

### Lovable (inspired by lovable)
- **Fonts:** Camera Plain Variable
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#1c1c1c`
- **Radius:** 1px
- **Breakpoints:** 1024 / 128 / 1280
- **Do:** the warm cream background (`#f7f4ed`) as the page foundation — it's the brand's
- **Don't:** use pure white (`#ffffff`) as a page background — the cream is intentional
- **Source:** getdesign.md/lovable/design-md

### Raycast (inspired by raycast)
- **Fonts:** Inter
- **Background:** `#07080a`
- **Text:** `#f9f9f9`
- **Accent:** `#FF6363`
- **Radius:** 12px
- **Breakpoints:** 1024 / 1200 / 600
- **Do:** `#07080a` (not pure black) as the background — the blue-cold tint is essential t
- **Don't:** use box-shadows liberally — Raycast uses inset highlights for depth
- **Source:** getdesign.md/raycast/design-md

### Superhuman (inspired by superhuman)
- **Fonts:** Super Sans VF
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#cbb7fb`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1440 / 768
- **Do:** Super Sans VF at weight 460 as the default — it's slightly heavier than regular,
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/superhuman/design-md

### Warp (inspired by warp)
- **Fonts:** Matter Regular
- **Background:** `#faf9f6`
- **Text:** `#3a3935`
- **Accent:** `#353534`
- **Radius:** 50px
- **Breakpoints:** 1500 / 810
- **Do:** warm off-white (`#faf9f6`) for backgrounds — the cream undertone prevents coldness
- **Don't:** use pure white or cool grays anywhere
- **Source:** getdesign.md/warp/design-md

### — Backend & Data —

### ClickHouse (inspired by clickhouse)
- **Fonts:** Inter
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#faff69`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1280 / 1536
- **Do:** Neon Volt (#faff69) as the sole chromatic accent — it must pop against pure blac
- **Don't:** introduce additional colors — the palette is strictly black, neon, green, and gr
- **Source:** getdesign.md/clickhouse/design-md

### Composio (inspired by composio)
- **Fonts:** abcDiatype
- **Background:** `#0f0f0f`
- **Text:** `#ffffff`
- **Accent:** `#00ffff`
- **Radius:** 4px
- **Breakpoints:** 1024 / 1440 / 768
- **Do:** Void Black (`#0f0f0f`) as the primary page background — never pure white for mai
- **Don't:** use bright backgrounds or light surfaces as primary containers
- **Source:** getdesign.md/composio/design-md

### HashiCorp (inspired by hashicorp)
- **Fonts:** __hashicorpSans_96f0ca
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#f0019b`
- **Radius:** 8px
- **Breakpoints:** 1150 / 768 / 992
- **Do:** HashiCorp Sans for headings and brand text, system-ui for body and UI text
- **Don't:** use product brand colors outside their product context (no Terraform purple on V
- **Source:** getdesign.md/hashicorp/design-md

### MongoDB (inspired by mongodb)
- **Fonts:** MongoDB Value Serif
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#00ed64`
- **Radius:** 30px
- **Breakpoints:** 1024 / 1280 / 1440
- **Do:** `#001e2b` (forest-black) for dark sections — not pure black
- **Don't:** use pure black (`#000000`) for dark backgrounds — always use teal-black (`#001e2
- **Source:** getdesign.md/mongodb/design-md

### PostHog (inspired by posthog)
- **Fonts:** IBM Plex Sans Variable
- **Background:** `#ffffff`
- **Text:** `#111827`
- **Accent:** `#23251d`
- **Radius:** 6px
- **Breakpoints:** 1024 / 1280 / 1536
- **Do:** the olive/sage color family (#4d4f46, #23251d, #bfc1b7) for text and borders — t
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/posthog/design-md

### Sanity (inspired by sanity)
- **Fonts:** waldenburgNormal
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#000000`
- **Radius:** 8px
- **Breakpoints:** 1100 / 112 / 120
- **Do:** the achromatic gray scale as the foundation -- maintain pure neutral discipline
- **Don't:** introduce warm or cool color tints to the neutral scale -- Sanity's grays are pu
- **Source:** getdesign.md/sanity/design-md

### Sentry (inspired by sentry)
- **Fonts:** Dammit Sans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#bf00ff`
- **Radius:** 8px
- **Breakpoints:** 1152 / 576 / 768
- **Do:** deep purple backgrounds (`#1f1633`, `#150f23`) — never pure black (`#000000`)
- **Don't:** use pure black (`#000000`) for backgrounds — always use the warm purple-blacks
- **Source:** getdesign.md/sentry/design-md

### Supabase (inspired by supabase)
- **Fonts:** Circular
- **Background:** `#fafafa`
- **Text:** `#000000`
- **Accent:** `#00c573`
- **Radius:** 8px
- **Breakpoints:** 128 / 600
- **Do:** near-black backgrounds (`#0f0f0f`, `#171717`) — depth comes from the gray border
- **Don't:** add box-shadows — they're invisible on dark backgrounds and break the border-def
- **Source:** getdesign.md/supabase/design-md

### — Productivity & SaaS —

### Cal.com (inspired by cal)
- **Fonts:** Cal Sans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#111111`
- **Radius:** 8px
- **Breakpoints:** 1024 / 1199 / 640
- **Do:** Cal Sans exclusively for headings (24px+) and never for body text — it's a displ
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/cal/design-md

### Intercom (inspired by intercom)
- **Fonts:** Saans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#0066ff`
- **Radius:** 4px
- **Breakpoints:** 425 / 530 / 600
- **Do:** Saans with 1.00 line-height and negative tracking on all headings
- **Don't:** round buttons beyond 4px
- **Source:** getdesign.md/intercom/design-md

### Mintlify (inspired by mintlify)
- **Fonts:** Inter
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#0066cc`
- **Radius:** 16px
- **Breakpoints:** 1024 / 768
- **Do:** Clean minimal design with generous whitespace
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/mintlify/design-md

### Resend (inspired by resend)
- **Fonts:** domaine
- **Background:** `#000000`
- **Text:** `#ffffff`
- **Accent:** `#ffffff`
- **Radius:** 8px
- **Breakpoints:** 480 / 600
- **Do:** pure black (`#000000`) as the page background — the void is the canvas
- **Don't:** lighten the background above `#000000` — the pure black void is non-negotiable
- **Source:** getdesign.md/resend/design-md

### Zapier (inspired by zapier)
- **Fonts:** Degular Display
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#ff6b35`
- **Radius:** 14px
- **Breakpoints:** 1024 / 1280 / 450
- **Do:** Degular Display exclusively for hero-scale headlines (40px+) with 0.90 line-heig
- **Don't:** use Degular Display for body text or UI elements -- it's display-only
- **Source:** getdesign.md/zapier/design-md

### — Design & Creative —

### Airbnb (inspired by airbnb)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#222222`
- **Accent:** `#e00b41`
- **Radius:** 14px
- **Breakpoints:** 1023 / 1127 / 1128
- **Do:** Ink Black `#222222` for every text layer below Rausch — this is the system's nea
- **Don't:** introduce secondary accent colors outside the Rausch / Plus Magenta / Luxe Purpl
- **Source:** getdesign.md/airbnb/design-md

### Airtable (inspired by airtable)
- **Fonts:** Haas
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#1b61c9`
- **Radius:** 16px
- **Breakpoints:** 1664
- **Do:** Clean design system with carefully considered type and spacing
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/airtable/design-md

### Framer (inspired by framer)
- **Fonts:** GT Walsheim Framer Medium
- **Background:** `#000000`
- **Text:** `#ffffff`
- **Accent:** `#0099ff`
- **Radius:** 40px
- **Breakpoints:** 110 / 1199 / 120
- **Do:** pure black (`#000000`) as the primary background — not dark gray, not charcoal
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/framer/design-md

### Miro (inspired by miro)
- **Fonts:** Roobert PRO Medium
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#2c7df7`
- **Radius:** 1px
- **Breakpoints:** 1024 / 1200 / 1280
- **Do:** pastel light/dark pairs for feature sections
- **Don't:** use heavy shadows
- **Source:** getdesign.md/miro/design-md

### Pinterest (inspired by pinterest)
- **Fonts:** Pin Sans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#e60023`
- **Radius:** 1px
- **Breakpoints:** 1312 / 1440 / 1680
- **Do:** warm neutrals (`#e5e5e0`, `#e0e0d9`, `#91918c`) — the warm olive/sand tone is th
- **Don't:** use cool gray neutrals — always warm/olive-toned
- **Source:** getdesign.md/pinterest/design-md

### Webflow (inspired by webflow)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#146ef5`
- **Radius:** 4px
- **Breakpoints:** 479 / 768 / 992
- **Do:** Use WF Visual Sans Variable at 500–600. Blue (#146ef5) for CTAs. 4px radius. tra
- **Don't:** Round beyond 8px for functional elements. Use secondary colors on primary CTAs.
- **Source:** getdesign.md/webflow/design-md

### — Fintech —

### Coinbase (inspired by coinbase)
- **Fonts:** CoinbaseDisplay
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#0052ff`
- **Radius:** 56px
- **Breakpoints:** 1280 / 1440 / 1600
- **Do:** Coinbase Blue (#0052ff) for primary interactive elements
- **Don't:** use the blue decoratively — it's functional only
- **Source:** getdesign.md/coinbase/design-md

### Kraken (inspired by kraken)
- **Fonts:** Kraken-Brand
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#7132f5`
- **Radius:** 6px
- **Breakpoints:** 1024 / 1280 / 1536
- **Do:** Kraken Purple (#7132f5) for CTAs and links
- **Don't:** use pill buttons — 12px is the max radius for buttons
- **Source:** getdesign.md/kraken/design-md

### Revolut (inspired by revolut)
- **Fonts:** Aeonik Pro
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#0066ff`
- **Radius:** 12px
- **Breakpoints:** 1024 / 1280 / 1920
- **Do:** Aeonik Pro weight 500 for all display headings
- **Don't:** use shadows — Revolut is flat by design
- **Source:** getdesign.md/revolut/design-md

### Wise (inspired by wise)
- **Fonts:** Wise Sans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#9fe870`
- **Radius:** 8px
- **Breakpoints:** 1440 / 576 / 992
- **Do:** Wise Sans weight 900 for display — the extreme boldness IS the brand
- **Don't:** use light font weights for Wise Sans — only 900
- **Source:** getdesign.md/wise/design-md

### — Enterprise —

### IBM (inspired by ibm)
- **Fonts:** IBM Plex Sans
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#0043ce`
- **Radius:** 0px
- **Breakpoints:** 1056 / 1312 / 1584
- **Do:** IBM Plex Sans at weight 300 for display sizes (42px+) — the lightness is intenti
- **Don't:** round button corners — 0px radius is the Carbon identity
- **Source:** getdesign.md/ibm/design-md

### NVIDIA (inspired by nvidia)
- **Fonts:** NVIDIA-EMEA
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#000000`
- **Radius:** 2px
- **Breakpoints:** 1024 / 1350 / 375
- **Do:** Strong geometric design with precision and scale
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/nvidia/design-md

### Semrush (inspired by semrush)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#0969DA`
- **Radius:** 8px
- **Breakpoints:** 640 / 1024 / 1280
- **Do:** Follow upstream design principles
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/semrush/design-md

### Uber (inspired by uber)
- **Fonts:** UberMove
- **Background:** `#000000`
- **Text:** `#ffffff`
- **Accent:** `#ffffff`
- **Radius:** 4px
- **Breakpoints:** 1119 / 1120 / 1136
- **Do:** true black (`#000000`) and pure white (`#ffffff`) as the primary palette -- the
- **Don't:** introduce color into the UI chrome -- Uber's interface is strictly black, white,
- **Source:** getdesign.md/uber/design-md

### — Automotive —

### BMW (inspired by bmw)
- **Fonts:** BMWTypeNextLatin Light
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#1c69d4`
- **Radius:** 0px
- **Breakpoints:** 1024 / 1280 / 1440
- **Do:** BMWTypeNextLatin Light (300) uppercase for all display headings
- **Don't:** round corners — zero radius is the BMW identity
- **Source:** getdesign.md/bmw/design-md

### Ferrari (inspired by ferrari)
- **Fonts:** Arial
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#DA291C`
- **Radius:** 0px
- **Breakpoints:** 1280 / 1920 / 375
- **Do:** Ferrari Red (`#DA291C`) sparingly — only for primary CTAs and brand-critical mom
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/ferrari/design-md

### Lamborghini (inspired by lamborghini)
- **Fonts:** LamboType
- **Background:** `#000000`
- **Text:** `#ffffff`
- **Accent:** `#ffeb00`
- **Radius:** 0px
- **Breakpoints:** 1024 / 120 / 1280
- **Do:** absolute black (`#000000`) as the primary background — never dark gray as a subs
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/lamborghini/design-md

### Renault (inspired by renault)
- **Fonts:** Inter, system-ui, sans-serif
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#EFDF00`
- **Radius:** 0px
- **Breakpoints:** 1024 / 1280 / 1440
- **Do:** Renault Yellow (`#EFDF00`) exclusively for super-primary CTAs — it carries the f
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/renault/design-md

### Tesla (inspired by tesla)
- **Fonts:** Universal Sans Display
- **Background:** `#ffffff`
- **Text:** `#000000`
- **Accent:** `#3E6AE1`
- **Radius:** 0px
- **Breakpoints:** 1024 / 1440 / 160
- **Do:** Electric Blue (`#3E6AE1`) exclusively for primary CTAs — never for decorative pu
- **Don't:** avoid drift from tokens
- **Source:** getdesign.md/tesla/design-md

### — Aerospace —

### SpaceX (inspired by spacex)
- **Fonts:** D-DIN-Bold
- **Background:** `#000000`
- **Text:** `#ffffff`
- **Accent:** `#ffffff`
- **Radius:** 0px
- **Breakpoints:** 1280 / 1350 / 1500
- **Do:** full-viewport photography as the primary design element — every section is a sce
- **Don't:** add cards, panels, or containers — text sits directly on photography
- **Source:** getdesign.md/spacex/design-md

## When to invent

A variation's thesis may call for a profile not in §2 (e.g., "Moroccan tilework," "Y2K pop," "Memphis Group"). Invent an execution card inline using the same shape: fonts, colors, accent, radius, shadow, forbiddens. Cite it in the variation plan and commit to it.

## The "no generic drift" rule

If you cannot state the profile's exact accent hex, radius, and font-family from memory or the card above, **you do not know the profile well enough to execute it** — pick a different profile or read §2 again before writing any CSS.
