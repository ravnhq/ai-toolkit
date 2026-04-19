# Description Authoring

The `description` field is the primary triggering mechanism. Claude reads it to decide when to activate a skill. A weak description means the skill never triggers — or triggers for the wrong tasks.

## The Formula

```
[What it does] + [When to use] + [Key capabilities/triggers]
```

## Hard Constraints

- Maximum 1,024 characters
- No XML tags or angle brackets (`<`, `>`) in frontmatter
- Names containing `claude` or `anthropic` are reserved
- `name` must be kebab-case (lowercase letters, digits, hyphens)
- `SKILL.md` filename is case-sensitive — must be exact

## Good Descriptions

Include concrete trigger phrases — the specific words users say:

```yaml
description: >-
  Comprehensive document creation, editing, and analysis with support for
  tracked changes, comments, formatting preservation, and text extraction.
  Use when working with professional documents (.docx files) for:
  (1) Creating new documents, (2) Modifying or editing content,
  (3) Working with tracked changes, (4) Adding comments,
  or any other document tasks.
```

Key traits:
- States what the skill does (first sentence)
- Lists specific trigger scenarios with numbered conditions
- Includes file types and task keywords users actually say

## Bad Descriptions

```yaml
# Too vague — no triggers
description: Helps with documents.

# Too technical — users don't speak this way
description: Implements python-docx library patterns for OOXML manipulation.

# Missing "when to use" — only states capability
description: Creates and edits Word documents with formatting support.
```

## Negative Triggers

When a skill overtriggers, add scope constraints:

```yaml
description: >-
  Interface design for dashboards, admin panels, apps, tools, and interactive
  products. NOT for marketing design (landing pages, marketing sites, campaigns).
```

Use "NOT for" or "Do not use when" to exclude specific scenarios.

## Authoring Checklist

1. Write a one-sentence summary of the skill's purpose
2. Add "Use when" followed by numbered trigger conditions
3. If the skill overlaps with other domains, add exclusions
4. Verify it's under 1,024 characters
5. Test mentally: "If a user said [X], would this description match?"

## Frontmatter Template

```yaml
---
name: my-skill-name
description: >-
  [One-sentence purpose]. Use when: (1) [trigger], (2) [trigger], (3) [trigger].
  Triggers on: "[phrase 1]", "[phrase 2]", "[phrase 3]".
---
```

### Optional Frontmatter Fields

Beyond the required `name` and `description`:

| Field | Purpose |
|-------|---------|
| `license` | License reference (e.g., "Complete terms in LICENSE.txt") |
| `compatibility` | Platform compatibility notes |
| `metadata` | Arbitrary key-value pairs (category, tags, version) |
| `allowed-tools` | Restrict which tools the skill can use |
