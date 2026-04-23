# Font Substitutes

When a profile's primary font is licensed or proprietary and not available via a free web-font CDN, use these fallbacks. Ordered: exact free match → close visual match → generic family fallback.

| Profile Font | License | Upstream Brand(s) | Free Substitute | Why it works | Notes |
|---|---|---|---|---|---|
| SF Pro Display / SF Pro Text | Apple proprietary (HIG) | Apple, Apple-ecosystem | Inter, -apple-system, system-ui | Inter matches metrics closely; system font on macOS/iOS | When substituting, increase line-height +0.02–0.06 on body sizes. SF Pro weight 400 → Inter weight 400–500. SF Pro weight 600 → Inter weight 600. |
| sohne-var | Stripe custom variable font (OFL licensed but proprietary integration) | Stripe | Inter Variable (if available), Geist Variable, or Inter + DM Sans | Inter matches tightness and modern feel. sohne-var weight 300 → Inter weight 300 (or 400 if weight 300 unavailable). Track letter-spacing proportionally. | Stripe's signature is weight 300 + negative tracking; Inter 300 + -1.4px at 56px approximates well. |
| NotionInter (Modified Inter) | Notion custom font | Notion | Inter (official Google Fonts) | NotionInter IS a modified Inter; Google Fonts Inter is 99% compatible. Same metrics, same variable axes. | Use Google Fonts Inter directly. Notion's customization is minimal. |
| Geist | OFL (Vercel open-source) | Vercel | Geist (https://vercel.com/fonts, free OFL) | Exact match — Geist is free and open-source. | Install from Vercel's font CDN or Google Fonts. |
| gg sans | Discord custom font | Discord | Trebuchet MS (system fallback), or Inter | gg sans is geometric sans; Inter approximates well. System fallback acceptable for casual use. | Discord hasn't released gg sans freely; Inter is closest match. |
| Circular Sp / Circular Std | Spotify (proprietary, licensed from Colophon Foundry) | Spotify | Manrope, DM Sans, or Rubik | Spotify's Circular is a geometric sans. Manrope is closest free alternative (geometric, friendly). DM Sans and Rubik also work but are slightly less rounded. | Spotify's green accent (#1DB954) pairs well with any modern sans. Use whichever feels closest. |
| Space Grotesk / Space Mono | OFL (Colophon Foundry via Google Fonts) | Various (Memphis Design, Cyberpunk profiles) | Space Grotesk, Space Mono (both free on Google Fonts) | Exact matches — both are free, open-source, and available via Google Fonts CDN. | No substitution needed; use the fonts directly. |
| Source Sans 3 / Source Serif 4 | OFL (Adobe open-source) | Government (GOV.UK-inspired), Editorial profiles | Source Sans 3, Source Serif 4 (both free on Google Fonts) | Exact matches — Adobe's Source family is free and widely available. | Use Google Fonts or Adobe Fonts CDN. |
| Playfair Display | OFL (Claus Eggers Sørensen via Google Fonts) | Editorial, Luxury profiles | Playfair Display (free on Google Fonts) | Exact match — free serif display font. | Use Google Fonts directly. Excellent for luxury and editorial. |
| Cormorant Garamond | OFL (Ebrahim Hamzaoui via Google Fonts) | Luxury, Art Deco, Art Nouveau profiles | Cormorant Garamond (free on Google Fonts) | Exact match — free serif with high elegance. | Use Google Fonts. Pairs well with generous padding and letter-spacing. |
| DM Sans | OFL (Colophon Foundry via Google Fonts) | Multiple (Luxury, Mid-Century, Modern profiles) | DM Sans (free on Google Fonts) | Exact match — free, modern, geometric sans. | Available on Google Fonts. Clean, versatile. |
| IBM Plex Mono / IBM Plex Sans | OFL (IBM open-source) | Brutalist, Data-Dense profiles, code contexts | IBM Plex Mono, IBM Plex Sans (both free on Google Fonts) | Exact matches — free, professional, open-source. | Use Google Fonts or IBM Fonts CDN. IBM Plex Mono is excellent for terminal/code aesthetics. |
| Futura | Proprietary (Adobe/Monotype) | Bauhaus profile | DM Sans, Inter, or Helvetica Neue (system) | Futura is geometric sans; DM Sans or Inter approximate the friendly geometry. | If Futura unavailable, Helvetica Neue (system) is acceptable fallback, though slightly heavier. |
| Helvetica Neue | Proprietary (system font) | Swiss, Mid-Century profiles, system fallbacks | Inter, or system: -apple-system, BlinkMacSystemFont, Segoe UI | Inter is modern equivalent of Helvetica. System fonts work for fallback. | `-apple-system, BlinkMacSystemFont` is macOS/iOS native and excellent fallback. |
| Inter (Google Fonts) | OFL (Rasmus Andersson via Google Fonts) | Universal fallback, Stripe, Vercel, many others | Inter (free on Google Fonts, GitHub) | Exact match — Inter is free, open-source, ubiquitous. | Use as your default system font. Available everywhere. |
| Plus Jakarta Sans | OFL (Google Fonts) | Sophistication direction (design-principles.md §4) | Plus Jakarta Sans (free on Google Fonts) | Exact match — free, modern, geometric sans with personality. | Use Google Fonts. Slightly more playful than Inter; great for friendly brands. |

## CDN & Installation

### Google Fonts (Recommended)
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Space+Grotesk:wght@400;700&family=Playfair+Display:wght@400;700&display=swap" rel="stylesheet">
```

### Vercel Fonts (Geist)
```html
<link rel="preconnect" href="https://cdn.vercel.com/fonts">
<link href="https://cdn.vercel.com/fonts/geist/style.css" rel="stylesheet">
```

### System Fonts (macOS/iOS/Windows Native)
```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
```

## Notes on Font Weight & Tracking Substitution

When replacing a licensed font with a free substitute:

1. **Weight mapping**: Most custom fonts (sohne-var, SF Pro) map closely to standard weight values (300=Light, 400=Regular, 600=SemiBold, 700=Bold). Use the same weight number in the substitute unless metrics feel off.

2. **Letter-spacing**: If the licensed font uses tight tracking (negative values), preserve the same tracking in the substitute. Example: `letter-spacing: -1.4px` at 56px sohne-var → `letter-spacing: -1.4px` at 56px Inter.

3. **Line-height adjustments**: Some substitutes may render slightly tighter or looser. If body text feels off, add 0.02–0.06 to line-height. Example: Notion's NotionInter at 1.50 line-height body → Inter may need 1.52–1.56 line-height.

4. **Variable fonts**: If the substitute supports variable fonts (Inter, Space Grotesk, Geist), you can use finer weight control (e.g., `font-weight: 450` instead of jumping from 400 to 500).

## Emergency Fallback Stack

If a font fails to load or is unavailable, always provide a fallback chain:

```css
font-family: 'FontName', 'FontSubstitute', system-ui, -apple-system, sans-serif;
```

Example for a Stripe-inspired design:
```css
font-family: 'Inter', 'SF Pro Display', -apple-system, system-ui, sans-serif;
```

This ensures the design renders cleanly even if the primary CDN is down.
