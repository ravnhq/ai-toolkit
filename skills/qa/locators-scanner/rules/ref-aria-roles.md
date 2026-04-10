---
title: Implicit ARIA roles lookup for common HTML elements
impact: MEDIUM
tags:
  - locators
  - aria
  - accessibility
  - roles
---

## Implicit ARIA Roles

When determining `getByRole` (Playwright) or `aria/` (WebdriverIO) locators, use implicit roles for common HTML elements:

| HTML Element | Implicit Role | Notes |
|---|---|---|
| `<a href="...">` | `link` | Only when `href` is present |
| `<button>` | `button` | |
| `<input type="checkbox">` | `checkbox` | |
| `<input type="radio">` | `radio` | |
| `<input type="text">` | `textbox` | |
| `<input type="email">` | `textbox` | |
| `<input type="password">` | `textbox` | Note: accessible name from label |
| `<input type="search">` | `searchbox` | |
| `<input type="number">` | `spinbutton` | |
| `<input type="range">` | `slider` | |
| `<textarea>` | `textbox` | |
| `<select>` | `combobox` | |
| `<option>` | `option` | |
| `<img>` | `img` | |
| `<table>` | `table` | |
| `<tr>` | `row` | |
| `<th>` | `columnheader` | |
| `<td>` | `cell` | |
| `<form>` | `form` | Only when has accessible name |
| `<nav>` | `navigation` | |
| `<main>` | `main` | |
| `<header>` | `banner` | When top-level |
| `<footer>` | `contentinfo` | When top-level |
| `<aside>` | `complementary` | |
| `<section>` | `region` | Only when has accessible name |
| `<article>` | `article` | |
| `<h1>`–`<h6>` | `heading` | With `level` attribute |
| `<ul>`, `<ol>` | `list` | |
| `<li>` | `listitem` | |
| `<dialog>` | `dialog` | |
| `<details>` | `group` | |
| `<summary>` | `button` | (within `<details>`) |
| `<progress>` | `progressbar` | |
| `<meter>` | `meter` | |
| `<output>` | `status` | |
