# Control Surface

Artifacts can't send messages to Claude. The gallery closes the iteration loop by emitting **copy-pasteable prompts** the stakeholder pastes back into chat.

This is the third upgrade in the skill (workflow step 8). Zero JS, CSP-safe, keyboard-accessible, works in every sandbox.

---

## Pattern: `<details>` + `<textarea>`

The only primitive: a native disclosure widget whose opened state reveals a pre-filled textarea.

```html
<details class="ds-control">
  <summary>⟳ More like this</summary>
  <label class="ds-control__label" for="ds-ctrl-v4-more">
    Copy this prompt (Cmd/Ctrl+A, Cmd/Ctrl+C), paste into chat.
  </label>
  <textarea
    id="ds-ctrl-v4-more"
    class="ds-control__prompt"
    readonly
    rows="4"
    aria-label="Ready-to-paste prompt for more variations like #4"
  >Generate 8 more variations in the direction of variation #4 ("Precision Standard", tier: MIN, profile: Stripe, thesis: "Skeptics need a side-by-side feature matrix"). Keep the recipe code (P1) constant. Vary register, density, and typography. Re-render the full gallery.</textarea>
</details>
```

**Rules:**
- `<details>` and `<summary>` only. No `onclick`, no `onload`, no `<script>`, no inline event handlers.
- Every textarea has an `aria-label` AND a visible `<label>`.
- `readonly` — never `disabled` (disabled textareas are unreadable by some screen readers).
- `rows` is set so the textarea shows the full prompt without scrolling.

**Styling hints** (profile-agnostic; fits any gallery aesthetic):
- `<summary>` has `:focus-visible` ring per polish-checklist §2.
- `<summary>` is styled as a button (padding, border-radius, hover state).
- Closed state: only the summary is visible. Opened state: label + textarea appear below.
- The textarea uses a mono font so prompts are easy to scan.

---

## Prompt templates

Eight templates: four per-cell (one per control), four toolbar. Each interpolates variation metadata (`{N}` = variation number; others from step-3 plan block).

### Per-cell

**1. ⟳ More like this**
```
Generate 8 more variations in the direction of variation #{N}
("{name}", tier: {tier}, profile: {profile},
thesis: "{thesis}"). Keep the recipe code ({recipe_code}) constant.
Vary register, density, and typography. Re-render the full gallery.
```

**2. 🔀 Remix with…**  (ask user to name a second variation — template uses `{M}` as a placeholder)
```
Remix variation #{N} ("{name}") with variation #{M}'s typography and
layout treatment. Keep #{N}'s thesis and profile. Render at {tier} tier.
Replace only #{N} in the gallery; leave others intact.
```

**3. 🔒 Lock tokens**
```
Lock the brand tokens from variation #{N} ({primary}, {accent}, {font_sans},
{radius}). Regenerate the full gallery using only these tokens. Vary
structure, layout, and register across the 16 variations; do not alter
color/typography.
```

**4. ⭐ Pin as finalist**
```
Pin variation #{N} ("{name}") as a finalist. Add it to the finalists set.
When I'm done pinning, regenerate a deep-dive gallery showing only the
pinned finalists with all declared states rendered, full responsive strip,
and side-by-side copy variants.
```

### Toolbar

**5. Merge pinned finalists**
```
Merge the pinned finalists into a single deep-dive comparison page.
Render each finalist at full size (one per row), with every declared state,
every responsive breakpoint, a side-by-side A/B copy variant, and an
annotated tradeoff table. Export this as a separate HTML document.
```

**6. Regenerate off-system only**
```
Regenerate only the off-system (BOLD + UNIQUE) variations in the current
gallery. Keep the on-system (MIN + MID) variations identical. Push the
off-system tier further — more experimental profiles, more structural
departure.
```

**7. Replace ingestion source**
```
Replace the current ingestion source with: [PASTE NEW URL OR PROSE BRIEF
HERE]. Keep the same component and variation count. Regenerate the full
gallery using the new brief.
```

**8. Export finalists**
```
Export the currently pinned finalists as a standalone, self-contained HTML
document (no gallery chrome, no decision matrix — just the finalist
variations at full size). Use the file naming pattern
{component}-finalists.html and also return inline as an artifact.
```

---

## Trailing chat echo

After emitting the artifact, the skill prints 3–4 short prompt suggestions as plain chat text immediately below the artifact handoff line. Desktop/Cowork surfaces these as suggested responses in some configurations; in every other case they're a visible menu:

```
Quick iteration suggestions (paste any into chat):

• More like #4 with a Brutalist profile
• Merge #3 and #7 at BOLD tier
• Lock tokens from #11, regenerate the rest
• Pin #2, #6, #14 as finalists and deep-dive
```

Pick the suggestions from the current gallery's standout variations (highest-evidence theses, most-distinct recipes), not a fixed list.

---

## Iteration-move vocabulary

Stakeholders call these by name; the skill recognizes the vocabulary on the next turn:

| Move             | Effect                                                    |
|------------------|-----------------------------------------------------------|
| **more like N**  | Narrow on #N's thesis, generate N+8 in that direction.    |
| **remix N+M**    | Merge #N's structure with #M's typography/layout.         |
| **lock tokens N**| Freeze #N's color+type; regenerate structure variants.    |
| **pin N**        | Add #N to finalists set (state carried across turns).     |
| **deep-dive**    | Finalists only, full states + responsive + A/B copy.      |
| **push bold**    | Regenerate only off-system tier, more experimental.       |
| **replace source**| Swap ingestion brief; regenerate full gallery.           |
| **export finalists**| Standalone HTML for the pinned set.                   |

All moves are idempotent per turn — running "more like #4" twice produces two fresh galleries, not a stateful pile.

---

## Accessibility gates (tracked in polish-checklist §14)

- Every `<summary>` has a `:focus-visible` ring (double-ring technique).
- Every `<textarea>` has both `aria-label` and a visible `<label>`.
- No textarea is `disabled`; all are `readonly`.
- Prompt text is plain ASCII — no smart quotes, no em dashes that break shell quoting if the user pastes into a CLI.
- The `<details>` opens on click AND on Enter/Space (native behavior; do not override).

Any variation shipped without these fails polish, same as a missing focus ring.
