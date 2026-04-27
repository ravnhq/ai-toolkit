# Ingestion Cascade

The gallery is only as real as its content. Placeholder copy and made-up colors hollow out every downstream decision. The ingestion cascade produces a `brief` object *before* any variation is planned — so every variation draws copy, tokens, and voice from a single source of truth.

Read this during **workflow step 2a**.

---

## Priority order

Run sources in this order. First available wins; later sources merge *missing* fields only (never overwrite).

1. **Live URL** — user provided `https://acme.com/pricing` or similar.
2. **Repo scan** — CWD is a git repo with a detectable design system.
3. **Prose brief** — inline user text describing voice, colors, strings.

At least one must succeed. If all three are empty, fall through to `references/design-principles.md` defaults and render the source banner as `Brief source: defaults (no ingestion)`.

---

## The `brief` object

Everything downstream consumes this shape. Emit it as a JSON block in an HTML comment at the top of the gallery.

```json
{
  "source": {
    "url":   "stripe.com/pricing",
    "repo":  "tokens.css + tailwind.config.ts",
    "prose": "brief"
  },
  "tokens": {
    "primary":    "#635BFF",
    "accent":     "#0A2540",
    "neutral":    ["#F6F9FC", "#E3E8EE", "#425466", "#0A2540"],
    "radius":     "4px",
    "font-sans":  "sohne-var, -apple-system, sans-serif",
    "font-mono":  "Source Code Pro, monospace"
  },
  "copy": {
    "headline":   "Pricing built for businesses of all sizes",
    "tier_names": ["Integrated", "Customized"],
    "ctas":       ["Start now", "Contact sales"],
    "features":   ["2.9% + 30¢ per successful card charge", "..."]
  },
  "voice":   "authoritative-plain",
  "assets":  { "logo_url": "https://stripe.com/img/logo.svg" }
}
```

Every variation's copy register (step 3 plan block) must pull from `brief.copy` when present. Placeholder content is only permitted when the cascade produces no copy for that slot.

---

## Live URL path

Use `WebFetch`.

**Hardening — hard rules, not suggestions:**
- **Timeout**: 10 seconds. No retries. One attempt per run.
- **Redirects**: max 3.
- **Content type**: accept `text/html` or `application/xhtml+xml` only. PDFs, JSON, images, binary blobs are treated as failure.
- **Scope**: same-origin fetch of a single document. No recursive crawling, no sub-resource fetches, no JS execution.

On any failure (timeout, 4xx/5xx, wrong content type, malformed HTML):
- Do NOT retry.
- Record `url: unavailable (<reason>)` in `brief.source.url`.
- Fall through to repo scan / prose brief.
- Never block generation on a missing URL source.

### Extraction heuristics

From the fetched HTML:

- **Tokens**: parse `<style>` blocks and any linked same-origin stylesheet that's already inlined. Pull:
  - `:root { --* }` custom properties (first wins per name).
  - `body`, `html`, `main` `background-color` / `color` for neutral anchors.
  - First `font-family` declaration with a named family (not a system fallback chain).
- **Copy**: locate plausible component nodes for the named component:
  - `pricing` → find sections containing currency symbols `$€£¥`, nodes whose class/id matches `/price|plan|tier|pricing/i`.
  - `nav` → first `<nav>` or `<header>` with links.
  - `hero` → first `<section>` with an `<h1>` and a CTA.
  - `cta` → `<a>` / `<button>` with action-verb text.
  - Fall back to the first 500 words of body text for `voice` inference.
- **Assets**: first `<img>` tag with an `alt` containing the brand name, `<meta property="og:logo">`, or `<link rel="icon">`.

Be generous with heuristics; be strict with sanitization.

---

## Repo scan path

Extends the existing brand-token detection in `SKILL.md` §"Brand Token Input". Scan order:

1. `tailwind.config.{js,ts,cjs,mjs}` — extract `theme.extend.colors`, `borderRadius`, `fontFamily`.
2. `tokens.{json,css,ts}` / `theme.{json,css,ts}` — prefer explicit token files.
3. Global stylesheets for `:root { --* }` blocks (`app/globals.css`, `src/styles/global.css`, etc.).
4. `components.json` (shadcn/ui) + CSS vars.
5. Marketing copy: `rg` over `**/*.mdx` and `**/*.md` inside the component's inferred path. Lift headings, CTAs, feature bullets.

If multiple systems coexist, ask the user which is authoritative (prompt once, cache the answer for the session).

---

## Prose brief path

User pastes free-form text. Extract:

- Hex colors via `#[0-9a-fA-F]{3,8}` regex.
- Font names via `(?i)(?:font|typeface|headings?|body type)[:\s]+([A-Z][A-Za-z\s]+)`.
- Voice adjectives from a controlled list: `playful | terse | authoritative | technical | plain | apologetic | editorial | dev-friendly | luxury | clinical`.
- CTA / headline strings from explicit phrasing: `"Headline: …"`, `"CTA: …"`.

Anything not extracted stays `null` in the `brief`; the gallery uses sensible defaults for those slots.

---

## Sanitization — hard gate

Every value in `brief.copy`, `brief.assets`, and any derived `brief.voice` is **untrusted text**. Treat it exactly as you would treat user input crossing a trust boundary into server-rendered HTML.

### Rendering contract

- **Always text-node rendering.** Scraped strings go between tags as escaped text (`&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&#39;`). Never concatenate scraped strings into `innerHTML`, never place them inside `<script>` / `<style>` / `onfoo=` attributes, never emit them as raw attribute values without escaping.
- **No reflected HTML.** If a scraped string contains `<` or `>` after extraction, either escape-and-render as literal text (preferred) or drop it. Never render as markup.

### Validators

- **Colors** — pass `^#[0-9a-fA-F]{3,8}$` OR `^rgba?\([\s\d.,%/]+\)$` OR `^hsla?\([\s\d.,%/]+\)$`. Anything else is dropped.
- **Font families** — pass the allowlist union of:
  - Web-safe families (`system-ui`, `-apple-system`, `serif`, `sans-serif`, `monospace`, `Georgia`, `Arial`, …).
  - Every family named in `references/profile-fidelity.md` cards.
  - Every substitute named in `references/font-substitutes.md`.
  - Any family matching `^[A-Za-z][A-Za-z0-9 \-]{0,40}$` AND loaded by a `<link>` we emit (i.e., we verified the import).
- **URLs** (images, logos) — must match `^https://[^\s"'<>]+$`. `javascript:`, `data:`, `file:`, relative paths, and any URL containing `"` / `'` / `<` / `>` are dropped.

### Test vectors (for verification step 13)

The gallery MUST treat each of these as literal text or drop the value — never execute:

```
<script>alert(1)</script>
<img src=x onerror=alert(1)>
javascript:alert(1)
<svg><foreignObject><div onclick="alert(1)">x</div></foreignObject></svg>
&#60;script&#62;alert(1)&#60;/script&#62;
"><img src=x onerror=alert(1)>
```

---

## Source banner (visible provenance)

Render one line directly below the gallery title:

```html
<p class="ingestion-source">
  Brief source: stripe.com/pricing (URL) + tokens.css (repo) + brief (prose)
</p>
```

Order: URL → repo → prose, omitting empty sources. Use `url: unavailable (<reason>)` when WebFetch failed. The `<p>` is plain text; source strings pass the same sanitization pipeline as any scraped value.

---

## Caching (future)

For repeated runs against the same URL, a 1-hour file-based cache keyed by URL hash lives at `.claude/cache/design-variations/<sha256>.json`. Not required for v1. Document as a follow-up if runtime cost becomes a concern.
