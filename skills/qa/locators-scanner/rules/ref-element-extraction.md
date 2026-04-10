---
title: Element extraction rules for page parsing
impact: HIGH
tags:
  - locators
  - parsing
  - extraction
  - html
---

## Element Categories

Capture every element that would be meaningful for test automation:

| Category | HTML elements |
|---|---|
| **Interactive** | `button`, `a`, `input`, `select`, `textarea`, `details`, `summary`, `dialog` |
| **Form** | `form`, `label`, `fieldset`, `legend`, `output`, `datalist`, `option` |
| **Content** | `h1`–`h6`, `p`, `span`, `div` (with text), `img`, `video`, `audio`, `figure`, `figcaption` |
| **Structural** | `nav`, `header`, `footer`, `main`, `aside`, `section`, `article`, `table`, `thead`, `tbody`, `tr`, `th`, `td`, `ul`, `ol`, `li` |

## Attribute Harvesting

For every element, collect these attributes when present:

- `id`
- `name`
- `class`
- `data-testid`, `data-test`, `data-cy`, `data-test-id` (and any `data-*` testing attribute)
- `role` (explicit ARIA role)
- `aria-label`, `aria-labelledby`, `aria-describedby`
- `placeholder`
- `type` (for inputs)
- `href` (for links)
- `alt` (for images)
- `title`
- Visible **text content** (trimmed, first 80 chars)
- **Tag name**
- Implicit ARIA role (e.g., `<button>` has implicit role `button`, `<a href>` has implicit role `link`)

## Filtering Rules

- Skip elements inside `<script>`, `<style>`, `<noscript>`, `<template>`, and `<svg>` (unless SVG is interactive — an SVG counts as interactive if it has `role`, `tabindex`, `onclick`, or `aria-label`).
- Skip elements with `hidden`, `aria-hidden="true"`, `display:none` in inline styles, or `type="hidden"`.
- For `<div>` and `<span>`, only include if they have at least one of: text content, a role attribute, a data-test attribute, an aria-label, or an id.
- Deduplicate elements that would produce the same locator.
