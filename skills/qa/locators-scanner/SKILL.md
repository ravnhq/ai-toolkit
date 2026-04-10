---
name: locators-scanner
description: Scan a website URL and extract the best locators for every visible element
  on the page, outputting a Page Object Model (POM) code file and/or a JSON locator
  map tailored to a specific test automation framework (Playwright, Cypress, or WebdriverIO).
  Use when users say "scan this page for locators", "extract locators from URL", "get
  selectors from website", "generate page object from URL", "build POM from page",
  "find locators for this URL", "what locators should I use for this page", "scan
  this page for elements", "extract selectors", "generate locator map", "get element
  selectors for testing", or mention scanning/extracting locators from a website.
  Also trigger when a user pastes a URL and asks to generate a page object, locator
  map, or selectors for Playwright, Cypress, or WebdriverIO. Also explicitly triggered
  by the /locators command.
metadata:
  version: 1
---

# Locator Extractor Skill

Senior QA automation engineer role. Scans a single web page, identifies every visible element, and produces the best locator per element following the **native locator philosophy** of the chosen framework.

## Workflow

`URL + framework → Fetch HTML → Parse elements → Rank locators → Generate outputs → Deliver`

## Step 1 — Gather Inputs

| Input | Required | Default |
|---|---|---|
| **URL** | Yes | — |
| **Framework** (Playwright / Cypress / WebdriverIO) | Yes | — |
| **Page name** | No | Infer from `<title>` or URL path |
| **Output formats** | No | Both POM + JSON |

If framework is ambiguous, ask: *"Which framework — Playwright, Cypress, or WebdriverIO?"*

## Step 2 — Fetch & Parse

Retrieve the fully rendered page using the browser MCP:

1. Call the browser MCP navigate/goto tool with the target URL.
2. Once navigation completes, call the MCP's JavaScript execution tool and evaluate `document.documentElement.outerHTML` to capture the fully rendered DOM.
3. Use the resulting HTML as the source for Step 3.

If the browser MCP tools are unavailable or fail, ask the user to provide the rendered HTML directly:
> "A browser MCP (e.g. chrome-devtools-mcp or @playwright/mcp) is required to fetch the page. Please enable one in Claude Code and retry, or paste the rendered HTML from DevTools (F12 → right-click `<body>` → Copy → Copy outerHTML) and I'll continue from there."

Do NOT stop the skill — wait for user input and continue to Step 3.

Parse all visible `<body>` elements per `rules/ref-element-extraction.md`.

## Step 3 — Rank & Select Locator

Apply the framework hierarchy (`rules/ref-playwright-strategy.md`, `rules/ref-cypress-strategy.md`, or `rules/ref-webdriverio-strategy.md`): walk top-to-bottom, pick first usable attribute, ensure uniqueness (chain/filter if not), fall back to minimal CSS. Record recommended + fallback locator. Use `rules/ref-aria-roles.md` for implicit ARIA roles and `rules/ref-naming-conventions.md` for names.

## Step 4 — Generate Outputs

Produce POM + JSON using the framework POM template and `rules/ref-json-schema.md`. See `rules/ref-output-formats.md` for confidence levels, file naming, and summary fields.

## Step 5 — Deliver

Save to `/mnt/user-data/outputs/`, present files, provide summary per `rules/ref-output-formats.md`. Apply `rules/ref-edge-cases.md` throughout.

## Rules Reference

| Rule | File | When to use |
|---|---|---|
| Element extraction | `rules/ref-element-extraction.md` | Step 2 |
| Playwright strategy + POM | `rules/ref-playwright-strategy.md` | Steps 3–4 |
| Cypress strategy + POM | `rules/ref-cypress-strategy.md` | Steps 3–4 |
| WebdriverIO strategy + POM | `rules/ref-webdriverio-strategy.md` | Steps 3–4 |
| Implicit ARIA roles | `rules/ref-aria-roles.md` | Step 3 |
| JSON schema | `rules/ref-json-schema.md` | Step 4 |
| Naming conventions | `rules/ref-naming-conventions.md` | Steps 3–4 |
| Output formats & confidence | `rules/ref-output-formats.md` | Steps 4–5 |
| Edge cases | `rules/ref-edge-cases.md` | Throughout |

## Examples

- **Playwright:** "Scan https://example.com/login for Playwright locators" → `LoginPage.ts` + `login-locators.json`
- **Cypress:** "Extract selectors from https://app.example.com/dashboard using Cypress" → `DashboardPage.js` + `dashboard-locators.json`
- **WebdriverIO:** "Generate a page object from https://shop.example.com/checkout for WebdriverIO" → `CheckoutPage.js` + `checkout-locators.json`

### Positive Trigger

User: "Scan https://example.com/login for Playwright locators and generate a page object"

### Non-Trigger

User: "Write unit tests for my login form using Jest"

## Troubleshooting

- Error: Browser MCP is unavailable or fails to fetch the page
- Cause: No browser MCP (chrome-devtools-mcp or @playwright/mcp) is enabled in Claude Code
- Solution: Prompt the user to enable a browser MCP, or ask them to paste the rendered HTML from DevTools (F12 → right-click `<body>` → Copy outerHTML)
- Expected behavior: Skill continues to Step 3 using the user-provided HTML and does not stop

- Error: Non-unique locator generated for an element
- Cause: Element lacks a unique identifier (id, data-testid, or accessible name)
- Solution: Chain with parent scope or index per framework rules; flag `confidence: low` in the JSON output
- Expected behavior: A best-effort locator is produced with a low-confidence warning

- Error: Framework is not specified
- Cause: User provided a URL without stating Playwright, Cypress, or WebdriverIO
- Solution: Ask: "Which framework — Playwright, Cypress, or WebdriverIO?"
- Expected behavior: User confirms the framework and skill proceeds to Step 2

- Error: Auth-gated URL fails to load
- Cause: Target page requires login credentials the browser MCP does not have
- Solution: Ask the user to log in, navigate to the page, and paste the rendered HTML from DevTools
- Expected behavior: Skill processes the authenticated page HTML and generates locators
