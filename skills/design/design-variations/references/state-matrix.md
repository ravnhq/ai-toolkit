# State Matrix (optional)

Designers showing variations to stakeholders often leave out the "hard states" — empty, loading, error, overflow. The gallery looks clean but fails the first real-data review.

This file is **opt-in**. The designer (or user) decides per-gallery whether state coverage matters. When it does, this file lists what's worth rendering per component type. When it doesn't — for pure visual exploration — skip this entirely.

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
