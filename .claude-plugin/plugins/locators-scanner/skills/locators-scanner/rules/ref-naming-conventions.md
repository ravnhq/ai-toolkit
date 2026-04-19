---
title: Element naming conventions for POM properties and JSON keys
impact: MEDIUM
tags:
  - locators
  - naming
  - pom
  - conventions
---

## Element Naming Conventions

Generate `elementName` following these rules:

### 1. Source the base name (priority order)

1. `aria-label` text
2. Associated `<label>` text
3. `placeholder` text
4. Visible text content (first ~40 chars)
5. `alt` text (for images)
6. `name` attribute
7. `id` attribute (cleaned of dynamic parts)
8. `data-testid` value

### 2. Append element type suffix

| Element | Suffix |
|---|---|
| `<button>` | `...Button` |
| `<a>` | `...Link` |
| `<input type="text\|email\|password\|search">` | `...Input` |
| `<input type="checkbox">` | `...Checkbox` |
| `<input type="radio">` | `...Radio` |
| `<select>` | `...Dropdown` or `...Select` |
| `<textarea>` | `...Textarea` |
| `<img>` | `...Image` |
| `<h1>`–`<h6>` | `...Heading` |
| `<table>` | `...Table` |
| `<nav>` | `...Nav` |
| `<form>` | `...Form` |
| `<section>`, `<div>` (structural) | `...Section` or `...Container` |
| `<p>`, `<span>` (content) | `...Text` |

### 3. Format

camelCase — e.g., `signInButton`, `emailAddressInput`, `mainNavigationNav`, `heroImage`

Page classes use PascalCase — e.g., `LoginPage`, `DashboardPage`

### 4. Handle duplicates

If two elements would get the same name, add a distinguishing qualifier — e.g., `topSignInButton` / `bottomSignInButton` or `primarySubmitButton` / `secondarySubmitButton`.
