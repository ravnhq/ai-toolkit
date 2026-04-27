# QA Chaos Monkey — Section Definitions

## Sections

### std — Shared Standards
Impact: CRITICAL
Order: 1
Rules that apply to every adversarial test run regardless of mode.

### sec — Security Rules
Impact: CRITICAL
Order: 2
Rules for testing authentication, authorization, and security boundaries.

### edge — Edge Case Rules
Impact: HIGH
Order: 3
Rules for testing deduplication, race conditions, and boundary values.

### rpt — Reporting Rules
Impact: HIGH
Order: 4
Rules for bug reporting format and issue tracker integration.
