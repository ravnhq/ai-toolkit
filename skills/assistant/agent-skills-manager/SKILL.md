---
name: agent-skills-manager
description: 'Manage AI skills from the Ravn AI Toolkit via corvus CLI — install,
  update, remove, search, and configure skills for any project. Use when: (1) Installing
  AI skills into a project, (2) Updating installed skills to latest versions, (3)
  Browsing or searching available skills, (4) Configuring global or per-project skill
  sets, (5) Troubleshooting corvus setup. Triggers on: "install skills", "add skills",
  "update skills", "corvus", "skill manager", "browse skills", "set up AI rules".'
license: Complete terms in LICENSE.txt
metadata:
  category: assistant
  tags:
  - agent
  - skills
  - cli
  - corvus
  - installation
  - configuration
  status: ready
  version: 3
---

# AI Skills Manager (corvus)

Manage Ravn AI Toolkit skills using the `corvus` CLI. Install, update, remove, and configure skills for any project without needing Bash knowledge.

## Prerequisites

Check if corvus is installed:

```bash
corvus --version
```

If not installed, run the bootstrap installer:

```bash
curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/install.sh | bash
```

After installation, restart the shell or `source ~/.zshrc`.

## Workflow

### 1. Browse Available Skills

List all skills grouped by category:

```bash
corvus list
```

Search by keyword:

```bash
corvus search <keyword>
```

Preview a specific skill's details, rules, and dependencies:

```bash
corvus info <skill-name>
```

### 2. Install Skills

**Interactive mode** (recommended for first-time users) — launches a picker UI:

```bash
corvus
```

**Direct install** to the current project:

```bash
corvus install <skill-name> [<skill-name> ...]
```

**Target flags** — install to a specific tool's rules directory:

| Flag | Target |
|------|--------|
| `--claude` | `.claude/rules` (project) |
| `--cursor` | `.cursor/rules` (project) |
| `--codex` | `.codex/rules` (project) |
| `--global-claude` | `~/.claude/rules` (global) |
| `--global-cursor` | `~/.cursor/rules` (global) |
| `--global-codex` | `~/.codex/rules` (global) |

```bash
corvus install --claude tech-react
corvus install --codex lang-typescript
corvus install --global-claude core-coding-standards
```

**Recipe install** — predefined skill sets for common stacks:

```bash
corvus install --recipe fullstack-ts
corvus install --recipe ios-swift
corvus install --recipe backend-api
```

Dependencies are resolved automatically. Use `--no-deps` to skip.

### 3. Update Skills

Pull latest toolkit and update all installed skills:

```bash
corvus update
```

corvus auto-checks for updates every 7 days and prompts when new versions are available.

### 4. Manage Installed Skills

Check installed versions vs latest:

```bash
corvus status
```

Remove a skill:

```bash
corvus remove <skill-name>
corvus remove --global <skill-name>
```

### 5. Team Collaboration

The `.corvusrc` file in the project root tracks installed skills and can be committed to git. Teammates can sync all project skills with:

```bash
corvus sync
```

### 6. Health Check

Run diagnostics to verify installation, dependencies, and configuration:

```bash
corvus doctor
```

### 7. Shell Completions

Print setup instructions for your shell:

```bash
corvus completions          # auto-detect shell
corvus completions --shell zsh
corvus completions --shell bash
corvus completions --shell fish
```

Follow the printed instructions to add completions to your shell config. For fish, the output will guide you to create a completions file at `~/.config/fish/completions/corvus.fish`.

## Configuration

### Global Config (`~/.corvus/config`)

| Key | Default | Description |
|-----|---------|-------------|
| `update_check` | 7 | Days between auto-update checks (0 = disabled) |
| `auto_deps` | true | Automatically install dependency skills |
| `global_skills` | (empty) | Comma-separated list of global skills with versions |

### Project Config (`.corvusrc`)

| Key | Description |
|-----|-------------|
| `install_dir` | Where skills are copied (e.g., `.cursor/rules`) |
| `skills` | Comma-separated list of installed skills with versions |

## Skill Scoping

**Global skills** apply to every project. Set personal defaults:

```bash
corvus install --global core-coding-standards lang-typescript
```

**Project skills** are project-specific additions. Stored in `.corvusrc`:

```bash
corvus install tech-react tech-drizzle
```

Both layers merge at runtime. Project versions take priority on conflicts.

## Available Recipes

| Recipe | Skills |
|--------|--------|
| `fullstack-ts` | lang-typescript, tech-react, tech-trpc, tech-drizzle, tech-vitest, design-frontend |
| `ios-swift` | swift-concurrency, liquid-glass-ios |
| `backend-api` | lang-typescript, tech-trpc, tech-drizzle, platform-testing |

## Maintaining corvus

Use this section when making changes to the corvus CLI itself (TypeScript source in `cli-ts/`).

### Version Locations

Both must be kept in sync on every release:

| File | Field |
|------|-------|
| `cli-ts/src/core/paths.ts` | `CORVUS_VERSION` constant |
| `cli-ts/package.json` | `"version"` field |

### Workflow for Every corvus Change

1. Make the code changes in `cli-ts/src/`.
2. Run tests: `cd cli-ts && npm test`
3. Read the current version from `cli-ts/src/core/paths.ts`, propose the next version to the user (increment build number), and wait for approval:
   > "Current version is `0.1.0`. Proposed next version: `0.1.1`. Approve?"
4. Update `CORVUS_VERSION` in `paths.ts` and `"version"` in `package.json` atomically.
5. Bump the skill version: `ruby scripts/skill_version.rb skills/assistant/agent-skills-manager/SKILL.md build`
6. Commit, push to fork, update PR.

## Examples

### Positive Trigger

User: "Install AI skills for my React + tRPC + Drizzle project"

Expected behavior: Run `corvus install --recipe fullstack-ts` in the project directory. This installs all 6 skills with their dependencies resolved automatically.

### Non-Trigger

User: "Fix the TypeScript error in my API handler"

Expected behavior: Do not use this skill. Choose a more relevant skill like lang-typescript or tech-trpc.

## Troubleshooting

### corvus Command Not Found

- Error: `corvus: command not found` after installation.
- Cause: `~/.local/bin` is not in PATH, or shell was not restarted.
- Solution: Run `source ~/.zshrc` (or `~/.bashrc`) or restart the terminal. If still missing, add `export PATH="$HOME/.local/bin:$PATH"` to your shell config.

### Skills Not Installing

- Error: `Registry not found` when running install.
- Cause: The local toolkit cache is missing or corrupted.
- Solution: Run `corvus update` to re-pull the repository cache at `~/.corvus/repo/`.

### Outdated Skills After Update

- Error: `corvus status` shows skills behind latest but `update` reports all up to date.
- Cause: The `.corvusrc` version numbers may be stale.
- Solution: Run `corvus remove <skill>` then `corvus install <skill>` to force a fresh install.
