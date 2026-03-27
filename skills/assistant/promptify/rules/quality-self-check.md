---
title: Self-Check Before Delivery
impact: HIGH
tags: quality, validation, gate, checklist
---

## Self-Check Before Delivery

Before presenting the rewritten prompt, verify it against the rule checklist. Fix any violations before delivery.

**Incorrect (delivering a prompt that violates own rules):**

```markdown
Rewritten prompt:
Write a good, comprehensive guide to setting up CI/CD.
Cover the important parts and make it useful for developers.
Include some examples if helpful.
```

This violates: be-specific ("good", "comprehensive", "important", "useful"), specify-format (no output structure defined), surface-missing-info (which CI/CD tool? which language?), include-success-criteria (no definition of "useful").

**Correct (self-check catches violations, then fixes them):**

```markdown
Self-check:
[ ] be-specific — FAIL: "good", "comprehensive", "important", "useful"
[ ] specify-format — FAIL: no output structure
[ ] surface-missing-info — FAIL: CI/CD tool and language unspecified
[ ] include-success-criteria — FAIL: no success definition
[x] minimal-fluff — PASS
[x] state-assumptions — PASS (none made)

Fixed rewritten prompt:
## Context
Audience: backend developers using GitHub Actions with a Node.js monorepo.

## Task
Write a setup guide for CI/CD covering:
1. Workflow file structure and trigger configuration
2. Test, lint, and build steps
3. Deployment to staging on PR merge, production on tag

## Constraints
- 1000-1500 words
- Each step includes a working YAML snippet
- Skip Docker-based workflows

## Output Format
Markdown with H2 per section. Inline YAML code blocks with `yaml` syntax highlighting.
```

**Why it matters:** Without a self-check gate, promptify can produce output that violates its own rules. The self-check acts as a compile step: catch errors before the prompt ships. One pass through the checklist takes seconds and prevents the user from receiving a polished-looking but still vague prompt.
