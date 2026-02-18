# Validation Checklist

Every skill must meet these structural requirements. Validate each item before considering a skill complete.

## Frontmatter

- Must start with `---` and end with `---` on their own lines
- Must parse as valid YAML mapping
- Only these top-level keys are allowed: `name`, `description`, `license`, `allowed-tools`, `compatibility`, `metadata`

### `name` (required)

- Kebab-case: `/[a-z0-9]+(-[a-z0-9]+)*/`
- Must exactly match the skill's folder name
- Must not contain `claude` or `anthropic` (case-insensitive)

### `description` (required)

- Non-empty, <= 1,024 characters
- No angle brackets (`<` or `>`)
- Must include trigger language (e.g., `Use when`, `when`)

### `metadata.version` (optional)

- If present, must be a positive integer (e.g., `1`, `2`, `3`)

## Required Sections

These markdown headings must exist in the body:

- `## Workflow`
- `## Examples`
- `## Troubleshooting`

## Examples Section Format

Must contain two subsections under `## Examples`:

- `### Positive Trigger` — a user prompt that should activate the skill
- `### Non-Trigger` — a user prompt that should NOT activate the skill

Each must include:
- A prompt in format: `User: \u201c[prompt text]\u201d` (smart quotes)
- The text `Expected behavior:` followed by what should happen

The positive trigger prompt must contain more keywords from the description than the negative prompt does.

## Troubleshooting Section Format

Each troubleshooting entry must use these **exact literal strings** (no bold, no extra markdown):

```
- Error: [what goes wrong]
- Cause: [why it happens]
- Solution: [how to fix it]
```

Not `- **Error**:`, not `- _Error_:` — plain `- Error:` only.

## Performance Limits

- Body <= 500 lines
- Body <= 5,000 words
- Description <= 1,024 characters

## Other Rules

- No `README.md` in the skill folder
- All local markdown links must resolve to existing files

## Template

Copy-paste starting point that satisfies all requirements:

```markdown
---
name: my-skill-name
description: >-
  [What it does in one sentence]. Use when: (1) [trigger scenario],
  (2) [trigger scenario], (3) [trigger scenario].
  Triggers on: "[phrase]", "[phrase]", "[phrase]".
---

# My Skill Name

[Brief intro — what this skill enables.]

## Workflow

[Steps for using this skill.]

## Examples

### Positive Trigger

User: \u201c[A prompt using description keywords that should trigger this skill.]\u201d

Expected behavior: [What the skill should do.]

### Non-Trigger

User: \u201c[A prompt in a different domain that should NOT trigger this skill.]\u201d

Expected behavior: [What should happen instead.]

## Troubleshooting

### [Problem Name]

- Error: [What goes wrong.]
- Cause: [Why it happens.]
- Solution: [How to fix it.]
```
