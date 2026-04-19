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

### Stripe
- **Fonts:** `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` @ 14px
- **Background:** `#FFF`
- **Dark text / heading:** `#0A2540`
- **Body text:** `#30313D`
- **Subtle surface:** `#F6F9FC`
- **Accent:** `#635BFF` (Stripe purple — NOT #3b82f6, NOT any generic blue)
- **Border:** 1px solid `#E3E8EE`
- **Radius:** 4px (buttons, cards — all of it)
- **Shadow:** `0 1px 3px rgba(0,0,0,0.04), 0 4px 12px rgba(0,0,0,0.04)`
- **Inputs:** 40px height, 10px 12px padding
- **Forbidden:** radius > 4px on any primary surface; cyan/teal accents; neon glows

### Linear
- **Fonts:** `"Inter", -apple-system, sans-serif` @ 13px
- **Background:** `#0F0F10` (near-black, not pure #000)
- **Surface:** `#151516`
- **Text:** `#EEEFF1`
- **Muted text:** `#8A8F98`
- **Accent:** `#D25E65` (coral-red — NOT green, NOT purple)
- **Border:** 1px solid `#26262B`
- **Radius:** 12px cards, 8px buttons, 6px inputs
- **Shadow:** NONE on cards — use borders for depth
- **Spacing:** 8px grid
- **Forbidden:** card shadows; pure black background; blue/green accents

### Vercel / Geist
- **Fonts:** `"Geist", -apple-system, sans-serif` @ 14px; letter-spacing `-0.01em` body, `-0.04em` headings
- **Background:** `#FFF`
- **Text:** `#000` (Vercel is one of the few profiles that uses pure black)
- **Secondary text:** `#666`
- **Border:** 1px solid `#EAEAEA`
- **Radius:** 6px (or 0 for buttons)
- **Shadow:** minimal — avoid
- **Forbidden:** colorful accents (Vercel is stark BW+grey); rounded corners > 8px

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

### Notion
- **Fonts:** `-apple-system, "Segoe UI", sans-serif` @ 16px (NOT 14px)
- **Background:** `#FFFFFF`
- **Hover surface:** `#F7F6F3` (warm — NOT gray-100)
- **Sidebar:** `#FBFBFA`
- **Text:** `#37352F` (warm gray — NOT #111827, NOT #000)
- **Muted text:** `#787774`
- **Accent:** `#2383E2` (NOT Tailwind blue)
- **Radius:** 4px (small)
- **Depth:** background-color separation ONLY — no shadows, no borders on primary surfaces
- **Forbidden:** cool grays; shadows on cards; accents that aren't #2383E2

### Apple / HIG
- **Fonts:** `"SF Pro Display", -apple-system, sans-serif` @ 17px
- **Background:** `rgba(255,255,255,0.72)` with `backdrop-filter: blur(20px)`
- **Secondary surface:** `#F5F5F7`
- **Text:** `#1D1D1F`
- **Accent:** `#007AFF` (iOS blue)
- **Border:** 1px solid `rgba(255,255,255,0.18)` (subtle, inside blur)
- **Radius:** 16–20px (generous)
- **Shadow:** `0 2px 8px rgba(0,0,0,0.08)`
- **Padding:** 20–24px on cards
- **Touch targets:** 44px minimum
- **Forbidden:** hard shadows; small radii; pure white backgrounds (always translucent)

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

### Spotify
- **Fonts:** `"Circular", system-ui, sans-serif` @ 14px (use `system-ui` as honest fallback)
- **Background:** `#191414` (dark) OR `#FFF` (light)
- **Accent:** `#1DB954` (Spotify green — specific, not generic green)
- **Text:** `#FFF` on dark
- **Radius:** 4px on buttons, 8px on cards
- **Forbidden:** generic greens; light-mode primary (Spotify is dark-first)

### Arc Browser
- **Fonts:** `"Inter", system-ui, sans-serif` @ 14px
- **Accent:** `#3139FB` (indigo — NOT #3b82f6)
- **Secondary accent:** `#FF5060` (coral)
- **Background:** `#FFF` with hints of `#F6F6FA`
- **Radius:** 12px
- **Shadow:** `0 2px 8px rgba(0,0,0,0.06)` subtle
- **Forbidden:** Tailwind blue `#3b82f6`; hard shadows

### Figma
- **Fonts:** `"Inter", system-ui, sans-serif` @ 13–14px
- **Accent:** `#7B61FF` (purple-blue — Figma's specific)
- **Secondary:** `#0ACF83` (Figma green)
- **Radius:** 4px (consistent everywhere)
- **Shadow:** `0 1px 3px rgba(0,0,0,0.1)`
- **Forbidden:** radii != 4px on primary surfaces

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

## When to invent

A variation's thesis may call for a profile not in §2 (e.g., "Moroccan tilework," "Y2K pop," "Memphis Group"). Invent an execution card inline using the same shape: fonts, colors, accent, radius, shadow, forbiddens. Cite it in the variation plan and commit to it.

## The "no generic drift" rule

If you cannot state the profile's exact accent hex, radius, and font-family from memory or the card above, **you do not know the profile well enough to execute it** — pick a different profile or read §2 again before writing any CSS.
