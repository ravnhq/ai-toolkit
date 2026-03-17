---
name: agent-skills-manager
description: "Manage AI skills from the Ravn AI Toolkit via ravencito CLI — install,\
  \ update, remove, search, and configure skills for any project. Use when: (1) Installing\
  \ AI skills into a project, (2) Updating installed skills to latest versions, (3)\
  \ Browsing or searching available skills, (4) Configuring global or per-project\
  \ skill sets, (5) Troubleshooting ravencito setup. Triggers on: \"install skills\"\
  , \"add skills\", \"update skills\", \"ravencito\", \"skill manager\", \"browse\
  \ skills\", \"set up AI rules\"."
license: Complete terms in LICENSE.txt
metadata:
  category: assistant
  tags:
  - agent
  - skills
  - cli
  - ravencito
  - installation
  - configuration
  status: ready
  version: 1
---

# AI Skills Manager (ravencito)

Manage Ravn AI Toolkit skills using the `ravencito` CLI. Install, update, remove, and configure skills for any project without needing Bash knowledge.

## Prerequisites

Check if ravencito is installed:

```bash
ravencito --version
```

If not installed, run the bootstrap installer:

```bash
curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/cli/install.sh | bash
```

After installation, restart the shell or `source ~/.zshrc`.

## Workflow

### 1. Browse Available Skills

List all skills grouped by category:

```bash
ravencito list
```

Search by keyword:

```bash
ravencito search <keyword>
```

Preview a specific skill's details, rules, and dependencies:

```bash
ravencito info <skill-name>
```

### 2. Install Skills

**Interactive mode** (recommended for first-time users) — launches a picker UI:

```bash
ravencito
```

**Direct install** to the current project:

```bash
ravencito install <skill-name> [<skill-name> ...]
```

**Global install** — skills available in every project:

```bash
ravencito install --global <skill-name>
```

**Recipe install** — predefined skill sets for common stacks:

```bash
ravencito install --recipe fullstack-ts
ravencito install --recipe ios-swift
ravencito install --recipe backend-api
```

Dependencies are resolved automatically. Use `--no-deps` to skip.

### 3. Update Skills

Pull latest toolkit and update all installed skills:

```bash
ravencito update
```

ravencito auto-checks for updates every 7 days and prompts when new versions are available.

### 4. Manage Installed Skills

Check installed versions vs latest:

```bash
ravencito status
```

Remove a skill:

```bash
ravencito remove <skill-name>
ravencito remove --global <skill-name>
```

### 5. Team Collaboration

The `.ravencitorc` file in the project root tracks installed skills and can be committed to git. Teammates can sync all project skills with:

```bash
ravencito sync
```

### 6. Health Check

Run diagnostics to verify installation, dependencies, and configuration:

```bash
ravencito doctor
```

## Configuration

### Global Config (`~/.ravencito/config`)

| Key | Default | Description |
|-----|---------|-------------|
| `update_check` | 7 | Days between auto-update checks (0 = disabled) |
| `auto_deps` | true | Automatically install dependency skills |
| `global_skills` | (empty) | Comma-separated list of global skills with versions |

### Project Config (`.ravencitorc`)

| Key | Description |
|-----|-------------|
| `install_dir` | Where skills are copied (e.g., `.cursor/rules`) |
| `skills` | Comma-separated list of installed skills with versions |

## Skill Scoping

**Global skills** apply to every project. Set personal defaults:

```bash
ravencito install --global core-coding-standards lang-typescript
```

**Project skills** are project-specific additions. Stored in `.ravencitorc`:

```bash
ravencito install tech-react tech-drizzle
```

Both layers merge at runtime. Project versions take priority on conflicts.

## Available Recipes

| Recipe | Skills |
|--------|--------|
| `fullstack-ts` | lang-typescript, tech-react, tech-trpc, tech-drizzle, tech-vitest, design-frontend |
| `ios-swift` | swift-concurrency, liquid-glass-ios |
| `backend-api` | lang-typescript, tech-trpc, tech-drizzle, platform-testing |

## Examples

### Positive Trigger

User: "Install AI skills for my React + tRPC + Drizzle project"

Expected behavior: Run `ravencito install --recipe fullstack-ts` in the project directory. This installs all 6 skills with their dependencies resolved automatically.

### Non-Trigger

User: "Fix the TypeScript error in my API handler"

Expected behavior: Do not use this skill. Choose a more relevant skill like lang-typescript or tech-trpc.

## Troubleshooting

### ravencito Command Not Found

- Error: `ravencito: command not found` after installation.
- Cause: `~/.local/bin` is not in PATH, or shell was not restarted.
- Solution: Run `source ~/.zshrc` (or `~/.bashrc`) or restart the terminal. If still missing, add `export PATH="$HOME/.local/bin:$PATH"` to your shell config.

### Skills Not Installing

- Error: `Registry not found` when running install.
- Cause: The local toolkit cache is missing or corrupted.
- Solution: Run `ravencito update` to re-pull the repository cache at `~/.ravencito/repo/`.

### Outdated Skills After Update

- Error: `ravencito status` shows skills behind latest but `update` reports all up to date.
- Cause: The `.ravencitorc` version numbers may be stale.
- Solution: Run `ravencito remove <skill>` then `ravencito install <skill>` to force a fresh install.

### Doctor Reports Missing Dependencies

- Error: `ravencito doctor` warns about missing `jq` or `python3`.
- Cause: JSON parsing requires at least one of these tools.
- Solution: Install jq (`brew install jq` on macOS) or ensure python3 is available.
