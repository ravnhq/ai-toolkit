# State Matrix

Designers showing variations to stakeholders often leave out the "hard states" — empty, loading, error, overflow. The gallery looks clean but fails the first real-data review.

This file now serves two roles:

1. **State coverage menu** (per-component lists of states worth rendering — unchanged).
2. **Rich cell rendering pattern** (static sub-cells + `@container` responsive strip — the mechanism workflow step 5 uses to render declared states side-by-side without JS).

## When to include states

Include when:
- The variations are headed toward implementation (not pure inspiration).
- A stakeholder has asked "what does this look like with real data?"
- The component carries risk in error/empty conditions (auth, payment, destructive actions).

Skip when:
- The brief is "show me directions" and aesthetic decisions come first.
- The component is inherently single-state (a static badge, a logo lockup).

## How to distribute states

Don't duplicate variations to show states. Instead, pick a subset of variations and render each in a different state. A 16-variation gallery might render 12 in default state and 4 in non-default states (one loading, one error, one empty, one overflow). Label the state explicitly in the cell header: `V7. Terminal · Register: Technical · State: ERROR`.

## Per-component state menus

Pick 1–3 per gallery. These are suggestions, not mandates.

### Pricing card
- **default** — all tiers visible, one highlighted as recommended
- **single-tier** — product sells one thing only (many SaaS launch states)
- **no-featured** — no recommendation, user decides unaided
- **long-feature-list** — 12+ features per tier, tests vertical density
- **annual-toggle-on** — discount state visible, cross-out on monthly
- **enterprise-contact** — last tier is "Contact sales" instead of price

### Login form
- **default** — idle, empty fields
- **loading** — submit in flight, spinner + disabled state
- **error-credentials** — "Incorrect email or password"
- **error-rate-limit** — "Too many attempts. Try again in 5 min."
- **oauth-only** — no password, just SSO providers
- **oauth-plus-password** — hybrid, SSO primary + password secondary
- **two-factor** — code entry after initial auth
- **passwordless** — "Check your email" post-submit state

### Toast / notification
- **default** — single line, info
- **success** — action confirmation
- **error** — with retry action
- **long-message** — 2–3 lines of wrapped content
- **stacked** — 3 toasts in the same corner, animating order
- **with-undo** — countdown bar + "Undo" action
- **persistent** — requires explicit dismiss, no auto-fade
- **progress** — file upload / background job with live %

### Navigation bar
- **default** — signed out
- **signed-in** — avatar + menu
- **mobile-collapsed** — hamburger state
- **scrolled** — condensed/pinned variant
- **search-open** — search dominates the bar
- **notifications-badge** — unread indicator

### Data table / list
- **default** — populated with 5–10 rows
- **empty** — first-time user, with onboarding CTA
- **loading** — skeleton rows
- **error** — failed fetch, retry affordance
- **filtered-no-results** — user has filters applied, no matches
- **overflow** — 1000+ rows, pagination or virtualization visible
- **row-selected** — bulk-action bar appears

### Dashboard card / metric tile
- **default** — number + delta + sparkline
- **no-data** — metric hasn't started collecting
- **loading** — skeleton shimmer
- **error** — failed to load this metric
- **long-number** — "1,293,847,221" — tests digit overflow
- **negative-delta** — red/down variant

### Modal / dialog
- **default** — standard content
- **confirm-destructive** — red primary action, typed confirmation
- **loading** — submit in flight, can't dismiss
- **error-inline** — validation failure inside the modal
- **tall-content** — requires internal scroll
- **mobile** — full-screen takeover variant

### Empty state
- **first-time** — onboarding, "Create your first X"
- **filtered-empty** — "No results for <query>"
- **cleared-all** — user just archived/deleted everything
- **error** — "Couldn't load" vs no-content

### Fintech / regulated surfaces (payments, banking, crypto, KYC)

Use when the component touches money, identity, or regulated actions. Copy register skews toward Authoritative / Apologetic; timing and affordances carry legal weight.

- **unverified** — action blocked pending identity check ("Complete verification to continue")
- **kyc-pending** — verification submitted, awaiting review (show ETA, not just a spinner)
- **cooldown** — rate-limited after suspicious activity or failed attempts (show remaining time explicitly)
- **rate-limited** — generic throttle, distinct from cooldown (app-level vs account-level)
- **regulatory-hold** — funds or action frozen pending compliance action (never hide; explain the next step)
- **two-factor-required** — secondary auth step before continuing (inline, not a redirect)
- **geo-restricted** — jurisdiction blocks this feature ("Not available in your region")
- **maintenance-window** — scheduled downtime, shown before the user commits an action
- **price-moved** — quoted rate no longer valid, user must re-confirm (crypto/FX)
- **success-with-receipt** — post-action state that includes transaction hash / reference number / timestamp

## Rendering notes

- Label the state in the cell header, don't hide it.
- Keep the state coherent with the Register. A Playful "empty" state has different copy than an Authoritative one — that's the point.
- An "error" rendered in a Luxury profile should still feel Luxury (slow, deliberate) — error is not an excuse to drop profile fidelity.
- Loading states must actually animate (shimmer, spinner) unless the profile explicitly forbids motion (Brutalist).

## How to decide for this gallery

Answer in the User Context Frame comment block:

```
states: default-only              // pure exploration
states: default + error           // auth component, error is high-risk
states: default + loading + empty // data component, wants real-data review
```

If unsure, default to `default-only` and let the stakeholder ask for more.

---

## Rich cell rendering (workflow step 5)

When a variation declares states, render them as **static side-by-side sub-cells** inside the variation's preview area. No tabs, no `:checked` toggles, no JS.

### Cell skeleton

```html
<div class="variation-cell">
  <div class="variation-header">…</div>

  <!-- Preview area now contains TWO strips: states (top) and responsive (bottom) -->
  <div class="variation-preview">

    <!-- State sub-cells: one per declared state -->
    <div class="variation-states">
      <figure class="state">
        <figcaption>default</figcaption>
        <!-- rendered component in default state -->
      </figure>
      <figure class="state">
        <figcaption>hover</figcaption>
        <!-- rendered component in hover state (e.g., :hover selectors forced via a class) -->
      </figure>
      <figure class="state">
        <figcaption>error</figcaption>
        <!-- rendered component with distinct error DOM -->
      </figure>
    </div>

    <!-- Responsive strip: 3 wrappers with container-type: inline-size -->
    <div class="variation-responsive">
      <figure class="viewport viewport--desktop">
        <figcaption>1280</figcaption>
        <div class="viewport__frame">
          <!-- same rendered component, wrapped for container query -->
        </div>
      </figure>
      <figure class="viewport viewport--tablet">
        <figcaption>768</figcaption>
        <div class="viewport__frame">
          <!-- same rendered component -->
        </div>
      </figure>
      <figure class="viewport viewport--mobile">
        <figcaption>360</figcaption>
        <div class="viewport__frame">
          <!-- same rendered component -->
        </div>
      </figure>
    </div>

  </div>

  <div class="variation-footer">…</div>
</div>
```

### Required CSS for the responsive strip

```css
.viewport__frame {
  container-type: inline-size;
  overflow: hidden;
  border: 1px solid #e5e7eb;
}
.viewport--desktop .viewport__frame { width: 1280px; max-width: 100%; }
.viewport--tablet  .viewport__frame { width: 768px;  max-width: 100%; }
.viewport--mobile  .viewport__frame { width: 360px;  max-width: 100%; }
```

Variation component CSS MUST use `@container` queries for viewport-responsive behavior:

```css
/* Good */
@container (max-width: 500px) {
  .v4-card { flex-direction: column; }
}

/* Bad — viewport @media does NOT fire on a fixed-width container */
@media (max-width: 500px) {
  .v4-card { flex-direction: column; }
}
```

### Allowed `@media` exceptions

`@media` is still permitted for accessibility/print features — these respond to user preference, not viewport width, and work identically inside or outside a container:

- `prefers-reduced-motion`
- `prefers-color-scheme`
- `prefers-contrast`
- `print`

Any other `@media` query (`min-width`, `max-width`, `orientation`, `hover`, `pointer`) in variation CSS is a polish-checklist failure — rebuild.

### Why static sub-cells beat tabs

- **Structural states work natively.** A loading skeleton, an error layout, and a default render can have completely different DOM trees — each sub-cell is independent.
- **No JS, no ARIA radiogroup burden, no keyboard-trap risk, no CSP concerns.**
- **Faster decisions.** Stakeholders compare states visually in one glance instead of clicking through tabs.
- **Print-friendly.** Print the gallery and states come through.

### When NOT to render multiple states

If a variation's thesis is single-state (e.g., a static badge, a decorative mark), render only the `default` sub-cell. Declaring a state you don't actually have is worse than skipping it — empty or lorem-filled "error" sub-cells break trust.
