# Product

## Register

brand

## Users

Engineers — primarily Ravn-internal developers and external practitioners landing from GitHub, search, or social posts. They arrive looking for a working setup for a specific Claude Code / AI-dev problem (an LSP that actually registers, a plugin that doesn't break, a skill worth installing). They are skim-readers who want the answer in under thirty seconds, with copyable commands, before deciding whether to read more. They distrust marketing prose and reward precision.

## Product Purpose

The Ravn AI Toolkit site is the public-facing surface for an open marketplace of modular AI dev skills. The blog and docs exist to:

- Document working setups for Claude Code, Codex, and adjacent AI dev tooling, with enough specificity that readers can copy and ship.
- Establish Ravn as a credible voice on AI-assisted engineering through evidence (commands that run, issues that link, dates that anchor), not opinion.
- Funnel readers toward installing skills from the marketplace and, secondarily, toward Ravn the company.

Success looks like: a reader lands on a post, gets the working command in seconds, installs a skill, and remembers the site the next time they hit a tooling problem.

## Brand Personality

Ravn-adjacent, more editorial. Inherits ravn.co's restraint, technical-corporate confidence, and warm beige-gold-on-dark palette, but leans editorial for long-form readability: generous typography, prose density, blog-as-craft. Three words: **precise, restrained, evidenced**. Voice is confident without hyperbole; outcomes over adjectives; cite the issue number, name the version, show the command.

## Anti-references

- SaaS-cream landing pages (white + soft pastel + rounded cards + smiling illustrations).
- "AI startup" neon-on-black aesthetic; glowing gradients; magenta-cyan duotones.
- The hero-metric template: gigantic number, small label, gradient accent, repeat.
- Identical icon-card grids for "features".
- Navy-and-gold fintech reflex — the gold here is warm beige (`#b7986a`), not enterprise-finance metallic.
- Gradient text. Glassmorphism. Bouncy springy motion. Em dashes in body copy.
- Generic dev-tool dark themes that look like every other terminal-themed marketing site.

## Design Principles

1. **Show the command, not the claim.** Every assertion is backed by something a reader can run, link, or verify. The page earns trust through evidence density, not language.
2. **Optimize for the fast exit.** A reader who lands, copies the working setup, and leaves in thirty seconds is the success case. Layouts must serve scanning first, deep reading second.
3. **Restraint is the brand.** One accent (warm gold), one type family for prose, one for code. Resist decoration. Whitespace and typographic rhythm carry the design.
4. **Editorial over corporate.** Long-form posts read like a magazine column, not a product page. Line length, leading, and hierarchy take precedence over "above the fold" instincts.
5. **Anchor every claim in time.** Versions, dates, issue numbers, model IDs. AI tooling shifts weekly; the site's credibility comes from saying when something was true.

## Accessibility & Inclusion

- Target WCAG 2.2 AA. Body and muted text on dark surfaces must hit 4.5:1; the gold accent (`#b7986a`) on `#161616` measures ~6.7:1 and is safe for text.
- Respect `prefers-reduced-motion` for any hover or transform animations introduced.
- Code blocks readable without color cues; never rely on color alone to convey meaning (e.g. diff +/-).
- Logical heading order in posts (`h1` for title, `h2` for sections, no skipping levels).
- All interactive elements keyboard reachable with visible focus styles.
