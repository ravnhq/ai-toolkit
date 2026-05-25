# Why Corvus installs Agent Skills under `skills/`, not `rules/`

## Problem

Corvus copies toolkit skills (folders with `SKILL.md`, optional `rules/`, `references/`, etc.) into a target directory chosen per product (Claude Code, Cursor, and others).

Originally, Corvus used **rules-style paths** for Claude and Cursor:

- `.claude/rules/<skill-name>/`
- `~/.claude/rules/<skill-name>/`
- `.cursor/rules/<skill-name>/`
- `~/.cursor/rules/<skill-name>/`

Those directories are where **Cursor Rules** and **Claude Code rules** (instruction files scoped as rules) are expected to live. The products treat **`skills/`** and **`rules/`** as different concepts:

- **Agent Skills** are packaged workflows: a directory per skill with `SKILL.md` at the root, loaded as skills in the UI and activation model.
- **Rules** are separate guidance files (often `.mdc` or markdown) used as standing rules, not the same as the Agent Skills folder layout.

Putting full skill trees under `…/rules/…` meant installs **looked and behaved like rules**, not like **installed skills**. That blocked the expected “skill plugin” / Agent Skill experience and contradicted how both ecosystems document local skills (e.g. project skills under `.claude/skills/`, `.cursor/skills/`).

## Change

Corvus now targets **Agent Skills locations** for Claude Code and Cursor:

| Product    | Project                         | Global (user)              |
|-----------|----------------------------------|----------------------------|
| Claude Code | `.claude/skills/<skill>/`      | `~/.claude/skills/<skill>/` |
| Cursor      | `.cursor/skills/<skill>/`       | `~/.cursor/skills/<skill>/` |

Other targets (OpenCode, Codex) still use each product’s documented `rules/` layout where that is the appropriate integration surface.

`corvus remove` continues to clean up **both** legacy paths (`…/rules/…`) and the new `…/skills/…` paths so older installs are not left behind.

## Summary

The change was **necessary** so installed toolkit content is treated as **Agent Skills** in Claude Code and Cursor, matching product semantics and documentation, instead of incorrectly landing under **rules** directories.
