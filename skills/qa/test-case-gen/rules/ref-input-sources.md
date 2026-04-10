---
title: Input source types and processing rules
impact: HIGH
tags:
  - test-case
  - input
  - url
  - html
  - mcp
  - parsing
---

## Input Source Types

Identify the source from what the user provides before executing any mode.

| Source | Detection signal | Processing path |
|---|---|---|
| **URL** | Starts with `http://` or `https://` | Navigate via browser MCP; capture rendered DOM |
| **HTML/XML** | Starts with `<`, contains tags | Parse markup directly; no MCP call |
| **Text description** | Feature description, story, PRD, or prose | No parsing; use text as-is |

If the user provides both a URL and a text description, prefer the URL for structural context and use the text for behavioral intent.

## URL Processing

1. Call `navigate_page` with the target URL.
2. Call `evaluate_script` with `document.documentElement.outerHTML` to capture the rendered DOM.
3. Extract from the DOM:
   - **Forms** — all `<form>` elements, fields (`input`, `select`, `textarea`), validation attributes (`required`, `minlength`, `pattern`), and submit targets.
   - **Interactive flows** — buttons, links, dialogs, elements with `role="button"`, `role="dialog"`, `role="tab"`.
   - **Navigation structure** — `<nav>` elements and internal links.
   - **State indicators** — `aria-disabled`, `aria-expanded`, `aria-selected`, `aria-live` (imply preconditions or dynamic states).
4. Skip invisible elements: `aria-hidden="true"`, `display:none`, `type="hidden"`.

**MCP fallback**: If browser MCP is unavailable or navigation fails, ask: "A browser MCP is required to fetch the page. Please enable chrome-devtools-mcp in Claude Code, or paste the rendered HTML from DevTools (F12 → right-click `<body>` → Copy outerHTML) and I'll continue from there."

## HTML/XML Processing

1. Accept the raw markup directly without navigating any URL.
2. Apply the same extraction rules as URL processing step 3.
3. If the markup is a partial fragment, extract what is present and note scope limitations in `coverage_summary`.
4. For Android/iOS XML layouts, map XML element types to platform equivalents:
   - `<Button>` / `<ImageButton>` → interactive button
   - `<EditText>` / `<TextView>` → input field / content display
   - `<RecyclerView>` / `<ListView>` → list/collection flow
   - `<CheckBox>` / `<RadioButton>` / `<Switch>` → toggle state

## Text Description Processing

No parsing step. Use the feature description, story, acceptance criteria, or PRD as semantic input. Apply Equivalence Partitioning, Boundary Value Analysis, and State Transition Testing based on described behaviors.

## Context Propagation

Record the input source used in `coverage_summary.input_source`:

| Value | Meaning |
|---|---|
| `"url"` | DOM captured via browser MCP or from a user-provided URL |
| `"html"` | User pasted raw HTML/XML markup |
| `"text"` | Feature description or prose input |
