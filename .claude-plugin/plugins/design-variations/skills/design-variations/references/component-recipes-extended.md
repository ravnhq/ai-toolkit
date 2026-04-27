# Extended Component Recipes

Structural recipes for components not covered in `design-principles.md §9`. Each code is a DOM skeleton, not a theme. Cite the code in your variation plan comment, following the same rules as Toast/Pricing/Login: **at least half of variations must use distinct codes; profile ≠ recipe.**

Usage: Cite the recipe code in your skeleton plan (step 3 of the workflow). Same rules apply: ≥50% of variations must use distinct codes; profile ≠ recipe.

---

## Navigation Bar (N1–N8)

### N1: Horizontal-links with CTA-right
`[ logo | link link link link | cta ]`

Standard desktop nav: logo left-aligned, horizontal link set center, prominent CTA button right. Navigation links at 14–15px. CTA uses primary accent color with hover state darkening. Collapses to hamburger menu on mobile.

Examples upstream: Stripe, Apple, Notion, Vercel

Works well for: SaaS marketing sites, fintech platforms, product launches. Signals clarity and trustworthiness.

### N2: Centered-logo split nav
`[ links | centered logo | links+cta ]`

Logo floats in the center of the nav. Equal link sets on left and right. Creates bilateral symmetry that works well for premium brands or editorial sites. Less common on product sites; signals luxury.

Examples upstream: Airtable, Composio

Works well for: Luxury goods, high-end services, editorial/publishing platforms.

### N3: Sticky top bar with search
`[ logo | search-input (full-width or wide) | account-menu ]`

Search-forward navigation. Logo small (left), large search field center, account/profile icon right. Sticky behavior keeps search always accessible. Used in SaaS dashboards and documentation sites.

Examples upstream: Linear.app, Supabase, Figma

Works well for: Documentation, product dashboards, knowledge management tools.

### N4: Tabbed sub-nav below main nav
`[ primary nav (sticky top) ] → [ secondary tabs/breadcrumb ]`

Two-tier navigation: primary horizontal nav (logo + links + CTA) at viewport top, secondary category/section tabs below on lighter background. Tabs indicate current section and allow fast switching within category.

Examples upstream: Apple, Cal.com, Cursor

Works well for: Multi-section marketing sites, ecommerce with product categories, educational platforms.

### N5: Side-aligned logo with vertical divider
`[ logo ] | [ links link link link ] [ cta ]`

Vertical divider separates logo from content. Creates tighter visual grouping. Logo remains prominent left anchor. Often pairs with slightly larger type and generous padding.

Examples upstream: Notion, Figma

Works well for: Professional/enterprise SaaS, finance apps, design tools.

### N6: Icon-heavy nav with minimal text
`[ logo | icon icon icon (text on hover) | cta ]`

Navigation primarily icon-driven. Text labels appear on hover/mobile expansion. Compact, minimal footprint. High visual density while keeping viewport clean.

Examples upstream: Linear.app, Supabase

Works well for: Developer tools, data-dense dashboards, mobile-first apps.

### N7: Full-width colored header nav
`[ FULL WIDTH DARK/COLORED BG: logo links cta ]`

Navigation sits on a distinct colored background (often brand color at 10–20% opacity or a dark accent). Creates visual separation from hero/content below. Maintains sticky behavior on scroll.

Examples upstream: Stripe, Composio, Cursor

Works well for: Bold brand expression, fintech/enterprise, statement-making launches.

### N8: Mega-menu with grid layout
`[ logo | expandable-link (reveals grid menu) | cta ]`

Navigation link expands to reveal a grid-based dropdown menu with categorized links, images, and descriptive text. High information density in dropdown state.

Examples upstream: Notion, Apple, Figma

Works well for: Multi-product companies, large SaaS suites, platforms with many sections.

---

## Hero Section (H1–H8)

### H1: Single-column centered text
`[ centered headline (large) | centered subheading | centered CTA button ]`

Vertical stack: large display headline (48–80px), warm subtitle or intro copy, prominent button. All elements center-aligned. Maximum visual simplicity. Generous top/bottom padding.

Examples upstream: Stripe, Notion, Vercel

Works well for: B2B SaaS, clean product launches, minimalist brands.

### H2: Headline-left, image-right split
`[ left column: headline + subtext + CTA ] [ right column: image/screenshot ]`

Binary layout: text on left occupies ~40–45% width, image/screenshot on right ~55–60%. Text column uses left alignment. Creates dynamic asymmetry. Works well for showing product in context.

Examples upstream: Apple, Figma, Composio

Works well for: Product showcases, feature announcements, developer tools.

### H3: Full-bleed image with text overlay
`[ full-width background image ] [ centered text overlay: headline + subtext + CTA ]`

Background image spans full viewport width. Text content floats centered on top, often with semi-transparent backdrop or dark overlay for readability. Maximum visual impact.

Examples upstream: Luxury brands, Spotify, Editorial designs

Works well for: High-end/luxury products, lifestyle brands, cinematic presentations.

### H4: Headline-top, dual-column cards below
`[ centered headline ] [ two-column grid: card card ]`

Large headline sits above a 2-column card grid. Each card is self-contained (image, title, CTA). Creates rhythm: focus headline then multiple entry points.

Examples upstream: Apple, Cal.com, Cursor

Works well for: Product families, feature highlights, multi-use-case introductions.

### H5: Asymmetric layout: wide text + narrow visual
`[ text column (wide) ] [ visual element (narrow, offset vertically) ]`

Text content takes majority width (60–70%), paired with a smaller visual element (30–40%) positioned off-center or floating. Intentional imbalance creates sophistication.

Examples upstream: Apple (retail flow), Editorial/luxury

Works well for: Premium/editorial narratives, complex product stories, design-forward brands.

### H6: Metric/stat-forward hero
`[ centered headline ] [ 3–4 stat cards in a row: number | label ]`

Headline positioned above a grid of prominent metrics (enrollment count, satisfaction %, ROI figure). Each metric displayed large (28–40px) with small label. Creates credibility through data.

Examples upstream: Notion, Stripe, Figma

Works well for: B2B/enterprise SaaS, fintech, platforms with strong social proof.

### H7: Gradient or solid color background with white text
`[ full-color or gradient background ] [ white text: headline + subtext + CTA ]`

Background is a solid brand color or gradient. All text rendered in white or light shade. Creates bold, statement-making visual. Often full-viewport height on initial load.

Examples upstream: Figma, Composio, Cursor

Works well for: Tech companies, creative tools, B2B-to-consumer platforms.

### H8: Product demo / code block integrated
`[ headline left ] [ live code/demo screenshot right ]`

Similar to H2 but the right column is a terminal, code editor, or live demo. Text communicates the value, visual proves the capability. Developer-oriented.

Examples upstream: Linear.app, Supabase, Composio

Works well for: Developer tools, CLIs, technical SaaS, API-first products.

---

## Modal / Overlay (M1–M6)

### M1: Centered card modal
`[ border: 1px solid... | heading (top-left aligned) | content area | action-row (buttons) at bottom ]`

Standard centered modal: contained card, dark backdrop, heading at top, body content in middle, action buttons (Primary + Secondary) at bottom right. Typical max-width: 400–500px.

Examples upstream: Stripe, Apple, Notion

Works well for: Confirmation dialogs, form modals, alerts, product tours.

### M2: Full-width modal with dark overlay
`[ full-viewport dark backdrop (0.5+ opacity) ] [ modal card spans 90% viewport width, max-width 1000px ]`

Modal spans most of viewport width (not tiny centered card). Dark overlay is opaque. Used for high-information modals: tables, multi-step forms, feature galleries.

Examples upstream: Apple (store modals), Figma, Linear.app

Works well for: Data tables, comparison modals, detailed configurations.

### M3: Slide-in side panel (drawer)
`[ full-height panel from right or left edge ] [ header with close button | content area | footer actions ]`

Modal slides in from side, not centered. Takes 30–50% viewport width. Often used for navigation panels, filter sidebars, or detail views. Backdrop blur optional.

Examples upstream: Apple, Cursor, Modern product dashboards

Works well for: Sidebar menus, filter panels, detailed previews without losing context.

### M4: Bottom sheet (mobile-optimized)
`[ modal anchored to bottom, spans full width ] [ header with drag handle | content (scrollable) | sticky footer actions ]`

Modal anchors to bottom of viewport, full width. Often has a drag handle at top to indicate draggability. Content area scrolls. Footer actions fixed.

Examples upstream: Spotify, Monzo, Mobile SaaS

Works well for: Mobile interactions, temporary overlays, non-blocking modals.

### M5: Toast-like notification modal (transient)
`[ floating card (small, 300–400px) ] [ icon + title + message ] [ optional close button ] [ auto-dismiss or manual ]`

Smaller, less intrusive than standard modal. Often appears in corner (top-right common). May auto-dismiss after 3–5 seconds. Used for brief confirmations, warnings.

Examples upstream: Stripe, Notion, Linear.app

Works well for: Status updates, validation feedback, success confirmations.

### M6: Dialog with embedded form or confirmation text
`[ heading ] [ body text (important message) ] [ optional form fields or illustrative content ] [ dual-button footer: Cancel | Confirm/Submit ]`

Modal for confirmation or decision-making. Text-prominent (not just icon + title). May include form inputs. Clear dual CTA pattern: dismiss and confirm.

Examples upstream: All design systems (standard UX pattern)

Works well for: Destructive actions, critical confirmations, multi-step decisions.

---

## Data Table / Comparison Matrix (TB1–TB6)

### TB1: Standard data grid
`[ header row: th th th th ] [ body rows: td td td td ] [ optional: footer summary row ]`

Classic table: header row with column labels, data rows with left-aligned text and right-aligned numeric values. Often alternating row backgrounds (zebra striping). Borders on row dividers.

Examples upstream: Stripe (pricing matrix), Apple (specs), Linear.app (comparison)

Works well for: Feature comparison, pricing matrices, product specifications.

### TB2: Compact micro-table (data-dense)
`[ minimal padding, small font (12–13px) ] [ no row backgrounds ] [ subtle borders ] [ icon indicators instead of text where possible ]`

High-density table: small type, tight padding (4–6px), minimal visual weight. Used in dashboards, monitoring UIs. Every row visible without scroll preferred.

Examples upstream: Linear.app, Supabase, Figma

Works well for: Dashboards, monitoring, real-time data, dev tools.

### TB3: Card-based table (responsive grid)
`[ on desktop: standard table ] [ on mobile: converts to card-per-row format, each row becomes a card with label-value pairs ]`

Single HTML table that displays as grid on desktop, cards on mobile. Each row becomes a self-contained card on smaller viewports.

Examples upstream: Modern responsive SaaS (Apple, Notion)

Works well for: Responsive tables, product lists, flexible data displays.

### TB4: Sortable/filterable header table
`[ header row with icons (▲▼) indicating sort state ] [ optional: filter chips above table ] [ body rows update based on sort/filter state ]`

Table with interactive headers (click to sort). Often includes filter UI above table. Visual indicators (chevrons) show active sort direction.

Examples upstream: Apple (store filters), Linear.app (issue lists), Figma

Works well for: Large datasets, issue trackers, product catalogs.

### TB5: Comparison matrix (fixed columns)
`[ left column: feature names (sticky, 200–300px) ] [ right columns: product tiers with checkmarks or values ]`

Horizontal feature/product comparison: feature names locked on left, tier columns scroll horizontally. Sticky header and left column for usability.

Examples upstream: Stripe (pricing), Apple (specs comparison), SaaS pricing pages

Works well for: Pricing tables, product feature comparison, specification matrices.

### TB6: Timeline table
`[ left: date/time column (or vertical line) ] [ right: event cards with content ] [ alternating left/right layout optional ]`

Table-like timeline: dates on left (or vertical spine), events on right. Dividers show progression. Often full-width cards paired with small date labels.

Examples upstream: Notion, Editorial/publishing sites

Works well for: Timelines, release notes, event logs, stories.

---

## Dashboard Card / Widget (D1–D6)

### D1: Metric card (simple)
`[ small label (12px) | large metric number (28–40px weight 700) | optional: trend indicator (↑/↓) ]`

Minimal dashboard card: small gray label at top, huge number below (right-aligned or left-aligned), optional subtle trend indicator. Typical size: 200×120px. No border, subtle background color or white.

Examples upstream: Notion, Stripe, Apple (retail dashboard mockups)

Works well for: Key performance indicators, analytics dashboards, real-time metrics.

### D2: Metric card with graph
`[ label + trend | large metric number | sparkline or mini-chart below number ]`

Metric card with embedded small chart (sparkline, bar chart, or area chart). Chart shows trend over time. Makes dashboard scannable and data-rich.

Examples upstream: Linear.app, Supabase, Figma (analytics products)

Works well for: Analytics dashboards, real-time monitoring, business intelligence.

### D3: Status/progress card
`[ label | progress ring (circular) or linear progress bar | percentage or count | status text ]`

Card focused on progress display. Ring or linear bar occupies center. Text labels describe state (e.g., "75% complete"). Color indicates status (green=good, yellow=warning, red=critical).

Examples upstream: Apple, Notion, Modern dashboards

Works well for: Project tracking, task management, goal visualization.

### D4: Multi-row list card
`[ card heading | list of 3–5 items (title + value pairs) | optional: "View all" link at bottom ]`

Card containing a mini-list inside: each item is a row with left-aligned label and right-aligned value. Compact alternative to a full table. Footer link to detail view.

Examples upstream: Linear.app, Stripe, Figma

Works well for: Recent activity, quick lists, condensed data views.

### D5: Action card / Quick-access
`[ icon (large, centered) | card title | brief description | CTA button at bottom ]`

Card designed for action, not data display. Large icon at top, heading, short description, prominent button. Often used in sets of 4+ for quick access to common functions.

Examples upstream: Apple (store), Notion, Figma

Works well for: Quick actions, feature discovery, onboarding guides.

### D6: Media card with overlay
`[ full card is background image | dark overlay (0.3–0.5 opacity) | text overlay: title + description | CTA button floating on image ]`

Card where image is the background. Text and actions float over a dark overlay. Used for visual showcases, recommendations, or featured content.

Examples upstream: Apple, Spotify, Monzo

Works well for: Visual recommendations, album/product showcases, editorial highlights.

---

## Sidebar / Navigation Panel (SB1–SB6)

### SB1: Vertical list sidebar
`[ sticky header (logo or title) | vertical link list (indented, no icons) | optional: footer (account/settings) ]`

Standard sidebar: vertical list of navigation links. Each link left-aligned (or indented). No icons. Links may have hover and active states. Footer may contain user menu.

Examples upstream: Linear.app, Supabase, Figma, Notion

Works well for: App dashboards, documentation, content management.

### SB2: Icon + text sidebar
`[ icons (24–32px) left-aligned | text label right of icon ] [ optional: collapsed view shows icons only ]`

Sidebar with icon-text pairs. Each navigation item combines left icon and right label. May support collapse behavior: icons remain visible, text hides.

Examples upstream: Linear.app, Supabase, Cursor

Works well for: Collapsible sidebars, icon-forward apps, responsive dashboards.

### SB3: Accordion sidebar
`[ expandable section headers (categories) ] [ nested link list under each category ] [ visual indicator (arrow) showing expand/collapse state ]`

Sidebar organized in collapsible sections. Each section is a category (e.g., "Documents", "Settings", "Team"). Click to expand/collapse. Links appear nested under category header.

Examples upstream: Notion, Figma, Modern product dashboards

Works well for: Large navigation trees, hierarchical content, feature organization.

### SB4: Sticky floating sidebar
`[ always-visible floating panel | fixed position (left edge) | may overlay content on scroll ] [ width: 200–300px ]`

Sidebar floats (position: fixed) on left edge. Maintains position as user scrolls. May use semi-transparency or slight shadow to separate from content. Often with close button for mobile.

Examples upstream: Apple, Cursor, Modern design tools

Works well for: Document navigation, quick-access panels, persistent context.

### SB5: Minimal sidebar (icons only)
`[ vertical icon grid | no text labels (except on hover/tooltip) ] [ compact: 60–80px wide ]`

Highly compact sidebar: only icons visible by default. Labels appear on hover or in tooltips. Maximizes content width. Very app-like.

Examples upstream: Linear.app, Figma, Design tools

Works well for: Space-constrained apps, icon-literate user bases, professional dashboards.

### SB6: Right-side activity/info panel
`[ floats on RIGHT edge (not left) ] [ shows: recent activity, user info, or detail view ] [ may push main content left or overlay ]`

Sidebar positioned on right instead of left. Often contains secondary content: activity log, user profile, detailed metadata for selected item.

Examples upstream: Linear.app, Figma, Notion

Works well for: Dual-pane layouts, activity feeds, detail panels.

---

## Form / Input Block (F1–F6)

### F1: Vertical form (standard)
`[ label | input | optional helper text ] × N fields | CTA button below all fields ]`

Vertical stacking: label above each input field, helper text below input. Full width. Submit button takes full width or standard button width below fields. Spacing: 16–24px between field groups.

Examples upstream: Stripe, Apple, Notion

Works well for: Sign-up, login, data entry, checkout flows.

### F2: Horizontal form (dense)
`[ label left (100–120px wide) | input right (remaining width) ] × N | CTA button below ]`

Label-input pairs aligned horizontally. Label on left (fixed width or flex), input on right. High density. Often used in admin/dashboard forms.

Examples upstream: Apple (store), SAP Fiori, Japanese/Korean design systems

Works well for: Admin interfaces, dense configurations, data tables with inline editing.

### F3: Inline form (single line)
`[ input | button ] — all on one line`

Input and submit button on same line. Minimal wrapper. Often used in search bars, quick-action forms, newsletter signups.

Examples upstream: Stripe, Apple, Vercel

Works well for: Search, email capture, minimal friction entry points.

### F4: Step-by-step form (progressive disclosure)
`[ step 1: show field 1 only | CTA: Next ] → [ step 2: show field 2 only | CTAs: Back, Next ] → [ final: show submit ]`

Form fields revealed progressively. Each step shows 1–2 fields, Next button advances. User can go back. Reduces cognitive load. Simulate with CSS states.

Examples upstream: Superhuman, Arc browser, Modern checkout flows

Works well for: Long forms, sensitive data entry, mobile forms, user onboarding.

### F5: Multi-column form (grid layout)
`[ grid: 2 or 3 columns ] [ label above input in each column ] [ full-width footer with CTAs ]`

Form fields arranged in grid: First Name + Last Name on one row, Address on next full-width row, etc. Responsive: collapses to single column on mobile.

Examples upstream: Apple, Stripe, Modern checkout flows

Works well for: Complex forms, address entry, user registration, configurations.

### F6: Form with side panel (vertical divider)
`[ left column: form fields ] [ vertical divider ] [ right column: summary/preview or info ]`

Two-column layout: left column is input fields, right column shows preview, summary, or instructional content. Creates context and guidance without cluttering the form itself.

Examples upstream: Apple (store configuration), Figma, Design tools

Works well for: Checkout/configuration, complex data entry, checkout with preview.

---

## Footer (FT1–FT4)

### FT1: Multi-column link footer
`[ dark bg (typically brand dark or gray-900) ] [ 4–5 columns: category heading + nested links ] [ copyright + secondary links at bottom ]`

Standard footer: multiple columns of categorized links, each with a bold heading and nested link list. Bottom row has copyright and secondary links. Full-width dark background.

Examples upstream: Stripe, Apple, Notion

Works well for: Large sites with many pages, b2b/marketing sites, platforms with multiple products.

### FT2: Minimal centered footer
`[ centered logo | centered copyright + links | optional: social icons ]`

Minimal footer: centered layout, logo at top, copyright + important links centered below, optional social icons. Clean and simple. Often used on small/focused sites.

Examples upstream: Vercel, Figma, Modern minimalist brands

Works well for: Simple product sites, focused landing pages, startups.

### FT3: Newsletter signup + links footer
`[ left: newsletter signup (email + CTA button) ] [ right: link columns ]`

Newsletter capture integrated into footer. Left side has email input and signup CTA. Right side continues with footer links. Balances conversion with navigation.

Examples upstream: Stripe, Notion, Vercel

Works well for: Audience growth, engagement, marketing-forward sites.

### FT4: Compact single-line footer
`[ logo / copyright | link link link | social icons ] — all on one line`

Ultra-compact footer: logo or copyright left, 3–4 links center, social icons right. All on one line. Minimal space footprint.

Examples upstream: Apple (some pages), Minimalist brands, Single-page apps

Works well for: Apps, tools, focused micro-sites, mobile-optimized sites.

---

## Notes on Upstream Coverage

- **Navigation**: All major brands (Stripe, Apple, Notion, Vercel, Figma, Composio, Cursor) employ variations of N1 (horizontal + CTA-right). N3 (search-forward) appears in Linear.app and developer tools. N4 (tabbed sub-nav) is common in Apple and multi-section sites. Fewer than 3 distinct structural patterns observed for N5–N8; codes reflect observed or reasonable extrapolations.

- **Hero**: Universal pattern is H1 (centered text) or H2 (split layout). H3 (full-bleed image) appears in luxury/lifestyle upstream examples. H4 (headline + cards) in Apple and multi-feature launches. H5–H8 derived from structural variation principles and less frequent upstream patterns.

- **Modal**: M1–M2 dominate (centered card, full-width modal). M3–M4 (side panel, bottom sheet) common in mobile-first and modern SaaS. M5–M6 less distinct as separate codes; grouped with toast-like and dialog patterns.

- **Table**: TB1–TB2 ubiquitous (standard, compact). TB3 (responsive cards) increasingly common. TB4–TB5 (sortable, comparison matrix) frequent in fintech and pricing. TB6 (timeline) less common but structurally distinct.

- **Dashboard Card**: D1–D3 most frequent. D4–D6 seen in product dashboards and modern analytics tools, though fewer explicit instances in upstream files.

- **Sidebar**: SB1–SB2 standard. SB3 (accordion) common in Notion and Figma. SB4–SB6 less frequent but structurally justified.

- **Form**: F1–F3 standard across all brands. F4 (step-by-step) explicitly mentioned in Superhuman and Arc. F5–F6 less frequently cited but observed in checkout and configuration contexts.

- **Footer**: FT1–FT2 ubiquitous. FT3 (newsletter) common in SaaS. FT4 (single-line) minimal adoption but valid for app footers.
