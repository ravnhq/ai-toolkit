---
title: Examples Only When Needed
impact: MEDIUM
tags: content, examples, brevity, disambiguation
---

## Examples Only When Needed

Include examples in the rewritten prompt only when the desired output format or content is genuinely ambiguous. Do not add examples for obvious structures.

**Incorrect (unnecessary example for obvious format):**

```markdown
List 5 popular JavaScript frameworks.

Example output:
1. React
2. Vue
3. Angular
4. Svelte
5. Next.js
```

A numbered list of names needs no example. The example wastes tokens and may anchor the model on the specific items shown.

**Incorrect (example that anchors instead of clarifying):**

```markdown
Write 3 product taglines for a task management app.

Example: "Get things done, together."
```

The model will mimic the style and length of the example instead of exploring the space of possible taglines.

**Correct (example disambiguates a non-obvious format):**

```markdown
For each JavaScript framework, provide a one-line summary in this format:

- **[Name]** ([Category]) — [One sentence: what makes it distinct from alternatives]

Example:
- **Svelte** (Compiler) — Shifts work from runtime to compile step, producing vanilla JS with no framework overhead
```

The format (bold name, parenthetical category, dash, differentiator sentence) is not obvious from the instruction alone. The example makes it concrete.

**Correct (example disambiguates tone or style):**

```markdown
Write error messages for a developer CLI tool. Match this voice:

Example: "Config file not found at ./config.yml — run `init` to create one, or pass --config to point somewhere else."

Not this: "Error: Configuration file is missing. Please ensure the file exists."
```

The example here clarifies the difference between two valid tones (casual-helpful vs. formal-generic) that the instruction alone cannot convey.

**Why it matters:** Every example in a prompt is an implicit constraint. The model treats examples as targets to match, not just illustrations. Unnecessary examples narrow the output space without adding clarity. They also consume tokens that could be spent on better specification. Use examples as disambiguation tools, not decoration.
