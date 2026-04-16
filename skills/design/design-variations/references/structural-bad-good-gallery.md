# Structural Diversity: Bad vs Good Galleries

This document shows concrete failure modes and their fixes. Read it during planning (step 3) — it teaches what "skin variation" looks like so you can avoid it.

The rule from `design-principles.md` §9 and SKILL.md §"Structural Mutation": **at least half the variations in a gallery must use distinct DOM skeletons (distinct recipe codes).** Shared skeletons = CSS themes, not real variations.

Each example below shows the WRONG way (all variations share a skeleton), then the RIGHT way (structurally diverse set). Skeletons are shown after stripping inline styles, classes, and text — only the tag tree matters.

---

## Example 1 — Toast notifications (8 variations)

### ❌ BAD: all 8 variations use T1 (horizontal flex row)

```html
<!-- V1 Stripe -->     <div><div/><div><p/><p/></div><button/></div>
<!-- V2 Linear -->     <div><div/><div><p/><p/></div><button/></div>
<!-- V3 GitHub -->     <div><div/><div><p/><p/></div><button/></div>
<!-- V4 Editorial -->  <div><div/><div><p/><p/></div><button/></div>
<!-- V5 Cyberpunk -->  <div><div/><div><p/><p/></div><button/></div>
<!-- V6 Brutalist -->  <div><div/><div><p/><p/></div><button/></div>
<!-- V7 Art Deco -->   <div><div/><div><p/><p/></div><button/></div>
<!-- V8 Wabi-Sabi -->  <div><div/><div><p/><p/></div><button/></div>
```

**Verdict:** 8/8 identical DOM. These are 8 color/font repaints of one component. Same-HTML Test FAIL (0% distinct). Signature Test FAIL — cover color/typography and every variation looks identical.

**Why it happens:** the model defaults to the "standard toast" template (icon + content + close) then differentiates by restyling. The structural recipes in §9 are never consulted.

### ✓ GOOD: 7 distinct recipe codes across 8 variations

```html
<!-- V1 Stripe      T1 standard inline -->
<div><span/><div><p/><p/></div><button/></div>

<!-- V2 Editorial   T2 full-width bar, two-row -->
<section><h3/><div><p/><button/></div></section>

<!-- V3 Monzo       T3 stacked vertical with action row -->
<article><span/><h3/><p/><div><button/><button/></div></article>

<!-- V4 Cyberpunk   T4 terminal block -->
<pre><code/><code/><code/></pre>

<!-- V5 Wabi-Sabi   T5 minimal text-only, no frame -->
<p><strong/><span/></p>

<!-- V6 Korean      T6 dense single-line -->
<div><span/><span/><span/><time/><button/></div>

<!-- V7 Art Deco    T7 split panel -->
<div><aside/><main><h3/><p/><button/></main></div>

<!-- V8 Figma       T8 expandable (two-state) -->
<details><summary><span/><span/></summary><div><p/><div><button/></div></div></details>
```

**Verdict:** 8 distinct skeletons using 8 distinct recipes. Same-HTML Test PASS (100% distinct, exceeds 50% floor). Signature Test PASS — each variation is identifiable from layout alone (bar / column / pre / text / inline / split / disclosure widget).

**What changed:** every variation started with "what structure does this thesis need?" before any CSS. A "transience" thesis (T5) produced bare text; a "command-line" thesis (T4) produced `<pre><code>`; a "progressive disclosure" thesis (T8) produced `<details>`.

---

## Example 2 — Pricing cards (6 variations)

### ❌ BAD: all 6 are P1 (3-column card grid)

```html
<!-- V1–V6 all share this skeleton -->
<section>
  <div><h2/><p.price/><ul><li/><li/><li/></ul><button/></div>
  <div><h2/><p.price/><ul><li/><li/><li/></ul><button/></div>
  <div><h2/><p.price/><ul><li/><li/><li/></ul><button/></div>
</section>
```

**Verdict:** V1 through V6 are a 3-card grid, every single time. The "BOLD" variation gets a purple gradient; the "Editorial" variation switches to serif. Same DOM. Squint Test FAIL — every gallery cell flattens to three rectangles in a row.

### ✓ GOOD: 6 distinct recipes

```html
<!-- V1 Stripe       P1 side-by-side columns -->
<section><article/><article/><article/></section>

<!-- V2 SAP          P2 stacked comparison (horizontal rows) -->
<table><thead><tr><th/><th/><th/><th/></tr></thead>
<tbody><tr><td.name/><td.price/><td.features/><td><button/></td></tr>
       <tr><td.name/><td.price/><td.features/><td><button/></td></tr>
       <tr><td.name/><td.price/><td.features/><td><button/></td></tr></tbody></table>

<!-- V3 Apple        P3 featured + thumbnails -->
<section><article.featured/><aside><article/><article/></aside></section>

<!-- V4 Arc          P4 tabbed single-card -->
<div role="tablist"><button/><button/><button/></div>
<section role="tabpanel"><h2/><p.price/><ul/><button/></section>

<!-- V5 Linear       P6 comparison matrix -->
<table><thead><tr><th/><th/><th/><th/></tr></thead>
<tbody><tr><th/><td/><td/><td/></tr>
       <tr><th/><td/><td/><td/></tr>
       <tr><th/><td/><td/><td/></tr></tbody></table>

<!-- V6 Luxury       P10 full-bleed stacked tier pages -->
<section.tier-hero><h2/><p.price/><ul/><button/></section>
<section.tier-hero><h2/><p.price/><ul/><button/></section>
<section.tier-hero><h2/><p.price/><ul/><button/></section>
```

**Verdict:** 6 distinct recipes (P1, P2, P3, P4, P6, P10). The matrix (V5) uses a real `<table>`. The tabs (V4) use `role="tablist"`. The full-bleed (V6) uses stacked `<section>` elements at viewport width. You cannot reduce any of these to another by a stylesheet change.

---

## Example 3 — Login forms (4 variations)

### ❌ BAD: all 4 are L1 (centered card)

```html
<!-- V1–V4 all share this skeleton -->
<div>
  <form>
    <h1/>
    <label><span/><input type="email"/></label>
    <label><span/><input type="password"/></label>
    <label><input type="checkbox"/><span/></label>
    <button type="submit"/>
    <a href="#"/>
  </form>
</div>
```

**Verdict:** 4/4 are centered cards with the same input order. Even the "Brutalist" and "Wabi-Sabi" variants are just visual reskins of the same form. Same-HTML Test FAIL (0% distinct).

### ✓ GOOD: 4 distinct recipes

```html
<!-- V1 Stripe       L1 centered card -->
<div><form><h1/><label/><input/><label/><input/><button/><a/></form></div>

<!-- V2 Apple        L2 split screen (brand panel + form panel) -->
<main><aside.brand><h1/><p/></aside>
      <section.form><form><label/><input/><label/><input/><button/></form></section></main>

<!-- V3 Linear       L4 step-by-step (email screen → password screen) -->
<form><fieldset data-step="1"><label/><input type="email"/><button/></fieldset>
      <fieldset data-step="2" hidden><label/><input type="password"/><button/></fieldset></form>

<!-- V4 Cyberpunk    L8 command-line / terminal -->
<pre><code>&gt; email: <input type="email"/></code>
     <code>&gt; password: <input type="password"/></code>
     <code>&gt; <button type="submit">auth</button></code></pre>
```

**Verdict:** 4 distinct recipes (L1, L2, L4, L8). V3 uses `<fieldset data-step>` to model a two-step flow. V4 uses `<pre><code>` with embedded inputs. Every variation is unmistakable at a glance.

---

## How to use this reference

During step 3 (planning), compare your variation plan to the BAD examples above. If your plan looks like "V1 Stripe card, V2 Brutalist card, V3 Editorial card, V4 Wabi-Sabi card," you're in failure mode — all four are cards, only the paint differs. Rewrite the plan with distinct recipe codes before generating HTML.

During step 4a (structural diversity gate), reduce each variation's DOM to its tag-tree skeleton (drop classes, drop styles, drop text). If two skeletons match, you've shipped a skin, not a variation. Rebuild.
