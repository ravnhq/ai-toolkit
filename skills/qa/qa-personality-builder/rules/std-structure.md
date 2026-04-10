---
title: Personality files must follow the Vercel skill structure
impact: CRITICAL
tags:
  - qa
  - personality
  - structure
  - skill
---

## Rule

Every custom QA personality must be a valid Vercel Agent Skill with: YAML frontmatter (name, description, allowed-tools, metadata), persona section, test scenarios from `.qa/test-plan.md`, structured output format, multi-provider bug reporting, and Troubleshooting section.

## Incorrect

```markdown
# My Tester

Test the webhooks. Report bugs.
```

- Error: Missing YAML frontmatter, no persona, no structured output format, no bug reporting section, no troubleshooting.
- Cause: Personality file was written as freeform text instead of following the skill structure.

## Correct

```markdown
---
name: qa-webhook-tester
description: |-
  Test webhook integrations by simulating inbound events.
  Trigger on "test webhooks" or "simulate webhook events".
allowed-tools: WebFetch Bash Read
metadata:
  version: 1
  category: qa
  tags: [qa, webhook, testing]
  status: ready
---

# QA Webhook Tester

You are a QA engineer specializing in webhook integration testing...

## Persona
- **Role**: API Integration QA Specialist
- **Attitude**: Precise, protocol-aware
...

## What You Test
Read `.qa/test-plan.md` for webhook flows...

## Output Format
[structured format]

## Bug Reporting
Read `.qa/config.yml` to determine issue tracker...
[multi-provider block]

## Troubleshooting
- Error: [error]
- Cause: [cause]
- Solution: [solution]
- Expected behavior: [expected]
```

- Complete YAML frontmatter with all required fields.
- Persona, test plan integration, structured output, bug reporting, and troubleshooting sections.

## Why it matters

The Vercel Agent Skills spec enables tool discovery, auto-invocation, and validation by the skills harness. Files that don't follow the structure won't be recognized by the skills system, won't appear in the `/` menu, and won't pass CI validation.
