---
name: promptify
description: Transform user requests into detailed, precise prompts for AI models.
  Use when users say 'promptify', 'promptify this', 'rewrite this prompt', 'make this
  prompt better/more specific', or explicitly request prompt engineering or improvement
  of their request for better AI responses.
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: assistant
  tags:
  - agent
  - prompt-engineering
  - clarity
  - specification
  - rewriting
  status: ready
  version: 6
  triggers:
    positive:
    - 'Promptify this: audit all skills against our findings doc.'
    - Rewrite this prompt for better results.
    - Make this prompt more specific.
    - Can you improve this prompt?
    negative:
    - Generate mock customer data in JSON format.
    - Write a React component for a login form.
    - Fix the bug in the checkout flow.
  guidance: |-
    `promptify` transforms user requests into precise, structured prompts.
    Only activate when the user explicitly requests prompt improvement or rewriting.
    Do not activate for direct task execution requests.
---

# Promptify

Transform user requests into detailed, precise prompts optimised for AI model consumption.

## Core Task

Rewrite the user's request as a clear, specific, and complete prompt that guides an AI model to produce the desired output without ambiguity. Treat the output as specification language, not casual natural language.

## Workflow

### 1. Analyze

Read the user's request carefully. Identify:

- The core intent and desired outcome
- Missing context (audience, domain, environment)
- Unstated constraints (length, tone, format)
- Expected output format

### 2. Decide Output Mode

Based on the analysis, choose how to proceed:

- **Request is clear and complete** — produce direct rewritten prompt
- **1-2 minor gaps** — fill with marked `[Assumption: X]` placeholders and proceed
- **Major gaps** (audience, scope, tech stack unknown) — ask clarifying questions before rewriting
- **Multiple distinct objectives** — split into separate prompts

### 3. Structure

Apply the four-block pattern to organise the prompt. See `rules/structure-four-block-pattern.md`.

- **Context** - Background, audience, domain
- **Task** - What the AI must do
- **Constraints** - Boundaries, rules, limitations
- **Output Format** - Exact structure of the response

Not every prompt needs all four blocks. Use only what adds clarity. For common prompt types, start from the skeletons in `references/prompt-blueprints.md`.

### 4. Draft

Apply the rules in `rules/` to sharpen the prompt:

- Replace vague terms with measurable requirements
- Surface missing information as placeholders or questions (see `rules/clarity-surface-missing-info.md`)
- Include success criteria defining what a good answer must include or avoid
- Mark any assumptions explicitly
- Add examples only where the desired output is genuinely ambiguous
- Specify exact format (headings, bullet style, length)
- Break complex tasks into numbered sequential steps

### 5. Self-Check

Before delivery, verify the draft against the rule checklist (see `rules/quality-self-check.md`):

- [ ] No vague qualifiers (be-specific)
- [ ] Missing info surfaced (surface-missing-info)
- [ ] Success criteria defined (include-success-criteria)
- [ ] Assumptions marked (state-assumptions)
- [ ] Format specified (specify-format)
- [ ] Examples only if ambiguous (examples-only-when-needed)
- [ ] No filler or politeness (minimal-fluff)

If any check fails, fix the violation and re-check. Stop after the checklist passes or after two refinement passes (whichever comes first).

### 6. Output

Present the final prompt to the user as a markdown block, clearly labeled. Do not add commentary beyond the prompt itself.

### 7. Deliver

After presenting the prompt, offer the user two options:

1. **Execute now** — Treat the generated prompt as your new instruction and proceed based on the current conversation context. Use your normal judgement to decide the best next action — plan complex tasks, implement simple ones directly, or ask clarifying questions if needed.
2. **Save to file** — Write the prompt to a markdown file in the current working directory (e.g. `promptify-<timestamp>.md` where `<timestamp>` is epoch seconds). Let the user know the file path.

## Writing Guidelines

### Structure

- Begin with a single short paragraph summarising the overall task
- Use headings (##, ###, ####) for sections only where appropriate (no first-level title)
- Use **bold**, _italics_, bullet points (`-`), and numbered lists (1., 2.) liberally for organisation
- Never use emojis
- Never use `*` for bullet points, always use `-`

### Language

- Use plain, straightforward, precise language
- Avoid embellishments, niceties, or creative flourishes
- Think of language as specification/code, not natural language
- Be clear and specific in all instructions

### Content

- Keep the prompt concise: 0.75X to 1.5X the length of the original request
- Do not add or invent information not present in the input
- Do not include unnecessary complexity or verbosity

## Examples

### Positive Trigger

User: "Promptify this: audit all skills against our findings doc."

Expected behavior: Use `promptify` guidance, follow its workflow, and return actionable output.

### Non-Trigger

User: "Generate mock customer data in JSON format."

Expected behavior: Do not prioritize `promptify`; choose a more relevant skill or proceed without it.

## Troubleshooting

### Skill Does Not Trigger

- Error: The skill is not selected when expected.
- Cause: Request wording does not clearly match the description trigger conditions.
- Solution: Rephrase with explicit domain/task keywords from the description and retry.

### Guidance Conflicts With Another Skill

- Error: Instructions from multiple skills conflict in one task.
- Cause: Overlapping scope across loaded skills.
- Solution: State which skill is authoritative for the current step and apply that workflow first.

### Output Is Too Generic

- Error: Result lacks concrete, actionable detail.
- Cause: Task input omitted context, constraints, or target format.
- Solution: Add specific constraints (environment, scope, format, success criteria) and rerun.
