# Design

Captured from `docs/assets/css/style.css` on 2026-05-11. Editorial-leaning Ravn-adjacent dark theme.

## Theme

Dark, single mode. The scene: an engineer reading a how-to at 11pm in a dim room on a 14" laptop, having just hit a broken plugin. Dark surface reduces glare against the surrounding terminal/IDE windows they came from; warm gold accent signals "human-written, not Medium boilerplate."

## Color

Strategy: **Restrained.** Tinted near-black neutrals plus a single warm gold accent used for emphasis, links, post meta, and hover states. Accent occupies well under 10% of any view.

| Token | Value | Role |
|---|---|---|
| `--bg` | `#161616` | Page background |
| `--bg-elevated` | `#1e1e1e` | Elevated surfaces (unused on post layout, reserved) |
| `--bg-card` | `#222222` | Cards (avoid on post body) |
| `--code-bg` | `#1a1a1a` | Inline and block code background |
| `--text` | `#ffffff` | Headings and strong emphasis |
| `--text-muted` | `#adb5bd` | Body prose, secondary metadata |
| `--gold` | `#b7986a` | Accent: links, post meta, logo dot, blockquote rule |
| `--gold-dim` | `rgba(183,152,106,0.15)` | Link underline, blockquote fill |
| `--border` | `#2a2a2a` | Hairlines, separators |

Contrast (WCAG): muted text on bg ≈ 7.2:1 (AAA); gold on bg ≈ 6.7:1 (AA large + body).

## Typography

| Family | Use | Weights |
|---|---|---|
| Work Sans | All UI and prose | 400, 600, 800 |
| Source Code Pro | Inline `code` and `pre` blocks | 400, 600 |

Scale (post layout):

| Token | Size | Weight | Line height | Use |
|---|---|---|---|---|
| Post h1 | 42px | 800 | 1.2 | Post title |
| Post h2 (section) | 13px | 600 | — | Section labels: uppercase, 2px letter-spacing, gold, preceded by hairline rule |
| Body | 17px | 400 | 1.8 | `.post-content p` |
| Code (block) | 14px | 400 | inherits | `pre code` |
| Meta | 12px | 600 | — | Uppercase, 2px letter-spacing, gold |

Body line length: container is 780px; body at 17px yields ~70ch — within the 65–75ch target.

Hierarchy is carried by **weight contrast** (800 vs 400) and the dramatic shift to small-uppercase gold for section labels — an editorial move, not a SaaS "h2 is just smaller h1" reflex.

## Layout

- Container: `max-width: 780px`, centered, 24px horizontal padding.
- Vertical rhythm: 48px between major sections, 24px between paragraphs, 96px above footer.
- Post header sits below a 48px "Back to blog" link and is separated from body by 48px margin.
- Section h2s are preceded by a 1px top border + 48px padding-top — the hairline replaces a heavier divider. Bottom margin after h2 is tight (8px) so the label sits visually attached to its section.
- No cards in post body. Code blocks and blockquotes are the only "boxed" content.

## Components

### Post meta
Uppercase, tracked, gold. Date · author with optional GitHub avatar (20px circle) inline. Visible above the title.

### Code (inline)
Mono, 0.88em, gold text on `--code-bg` with 1px border, 4px radius. Visually distinct from links (links are gold underlined; code is gold boxed).

### Code (block)
`<pre>` with `--code-bg`, 1px border, 8px radius, 20px/24px padding. Inner `code` is muted-gray (`--text-muted`), 14px. No syntax highlighting layer yet.

### Blockquote
Left rule: 3px solid gold, gold-dim fill, asymmetric radius (`0 8px 8px 0`). Not currently used in the LSP post.

### Links (in prose)
Gold text + 1px gold-dim bottom border that brightens to full gold on hover. No `text-decoration: underline`.

### Back link
Uppercase, tracked, muted, with `←` glyph prefix. Hover → gold.

## Motion

- All transitions: `0.3s ease` on `color`, `opacity`, `transform`.
- The "read more" link translates 4px right on hover; no other transforms.
- No keyframe animations. Respect `prefers-reduced-motion` (not yet wired — track as gap).

## Gaps / opportunities (vs PRODUCT.md principles)

1. **Reduced-motion** media query is missing.
2. **Reading-time estimate** absent — useful for the "fast exit" principle.
3. **Anchor links on h2s** absent — useful for reference posts where readers deep-link to a specific setup.
4. **Permalink / copy-link affordance** absent.
5. **TOC for longer posts** absent; not needed for the LSP post but worth designing.
6. **`prefers-reduced-motion`, focus-visible, and skip-link** not present; accessibility floor for AA.
