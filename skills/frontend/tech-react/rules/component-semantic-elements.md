---
title: Use Semantic HTML Elements
impact: MEDIUM
tags: accessibility, html, semantics
---

## Use Semantic HTML Elements

Use the right HTML element for the job. Don't make divs behave like buttons.

**Incorrect (div as interactive element):**

```tsx
// Bad - div with click handler
<div onClick={handleSubmit} className="button-styles">
  Submit
</div>

// Problems:
// - Not keyboard accessible (can't Tab to it)
// - Screen readers don't announce it as a button
// - No :focus styles by default
// - No disabled state
```

**Correct (semantic elements):**

```tsx
// Good - actual button
<button onClick={handleSubmit} className="button-styles">
  Submit
</button>

// Good - link for navigation
<Link to="/settings">Settings</Link>

// Good - semantic structure
<nav>
  <ul>
    <li><Link to="/">Home</Link></li>
    <li><Link to="/about">About</Link></li>
  </ul>
</nav>

<main>
  <article>
    <h1>Article Title</h1>
    <p>Content...</p>
  </article>
</main>
```

**Element selection guide:**

| Purpose | Element |
|---------|---------|
| Clickable action | `<button>` |
| Navigation | `<a>` or Link component |
| Main content | `<main>` |
| Navigation menu | `<nav>` |
| Section heading | `<h1>` - `<h6>` |
| Form input | `<input>`, `<select>`, `<textarea>` |
| Article/post | `<article>` |
| Sidebar | `<aside>` |

**Why it matters:**
- Screen readers depend on semantics
- Keyboard navigation relies on focusable elements
- Search engines understand semantic structure
- Built-in accessibility features for free

Reference: [Semantic HTML](https://developer.mozilla.org/en-US/docs/Glossary/Semantics#semantics_in_html)
