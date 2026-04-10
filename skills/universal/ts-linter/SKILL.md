---
name: ts-linter
description: 'Set up and enforce a strict, production-grade ESLint configuration for
  TypeScript projects, then systematically fix all linting issues. Use this skill
  whenever the user asks to add a linter or ESLint, enforce code quality rules, fix
  linting errors, clean up code style, or add type-aware linting. Trigger on: "lint",
  "eslint", "code quality", "static analysis", "strict linting", "make it stricter",
  "make the code stricter", "add better rules", "clean up the codebase", "enforce
  standards", "fix all the warnings", or "ShadCN lint errors". Handles detection,
  config generation, dependency installation, auto-fix, and manual remediation. Do
  NOT use for Biome or Rome projects, Prettier-only formatting, non-TypeScript/JavaScript
  projects, writing custom ESLint rules or plugins, husky/lint-staged/pre-commit hook
  setup, or when the user just wants to run an existing linter without changing its
  configuration.

  '
allowed-tools:
- Bash
- Read
- Write
- Edit
- Grep
- Glob
- Agent
metadata:
  category: universal
  extends: core-coding-standards
  tags:
  - eslint
  - typescript
  - linting
  - code-quality
  - static-analysis
  status: ready
  version: 8
---

# TypeScript Linter Skill

This skill introduces a strict, comprehensive ESLint configuration into a TypeScript project
and then systematically resolves every linting issue — auto-fixing what it can and manually
rewriting what it can't. The goal is zero lint errors with zero broken functionality.

## Core Principle

**Rules are immutable.** Once the ESLint configuration is generated, treat it as frozen. The
only lever is changing application code. Never suppress, disable, downgrade, or override a
rule — refactor the code to comply.

## Before Starting

Recommend the user commits their current state before any changes:
```bash
git add -A && git commit -m "checkpoint: before linter setup"
```
This gives a clean rollback point. If the project doesn't use git, warn that there is no
undo — proceed carefully, fix in small batches.

## Workflow Overview

1. **Detect** the project type by running `scripts/detect-project.sh`
2. **Generate** a tailored `eslint.config.mjs` from `references/eslint-config-reference.mjs`
3. **Install** all required dependencies using `scripts/generate-install-cmd.sh`
4. **Validate** the config actually loads before proceeding
5. **Auto-fix** using `eslint --fix` in batches
6. **Baseline** — capture error counts before manual fixes begin
7. **Manually fix** every remaining issue, verifying after each batch
8. **Verify** and produce a before/after summary comparing against baseline
9. **Install Claude Code hooks** (Claude Code only — auto-detect environment)

Steps 1-8 are platform-agnostic and work identically on Claude.ai, Claude Code, and the API.
Step 9 runs automatically when inside Claude Code (detected by the presence of a `.claude/`
directory) and is silently skipped otherwise.
This skill only handles ESLint for TypeScript/JavaScript. It does not conflict with other
skills (e.g., frontend-design, docx) since it only activates for linting-related requests.

---

## Step 1: Project Detection

Run the detection script to determine what the project uses:

```bash
bash <skill-path>/scripts/detect-project.sh .
```

This scans `package.json`, lockfiles, and directory structure, then outputs a JSON object
with boolean flags for each module (React, React Native, Drizzle, Vitest, Playwright, etc.),
the detected package manager, existing ESLint config type, and file globs for server/native/db/e2e
directories.

If the script is unavailable, run the detection manually:

```bash
cat package.json | grep -E "react-native|expo|next|@tanstack|drizzle-orm|vitest|jest|playwright|@testing-library"
ls tsconfig*.json
ls -d apps/ packages/ src/ server/ api/ native/ e2e/ 2>/dev/null
ls eslint.config.* .eslintrc* 2>/dev/null
ls pnpm-lock.yaml yarn.lock package-lock.json bun.lockb 2>/dev/null
```

Based on the results, determine which config sections to include:

| Detected Signal | Config Section |
|---|---|
| `react` or `react-dom` in deps | React (web) |
| `react-native` or `expo` in deps | React Native |
| `@tanstack/react-query` in deps | TanStack Query |
| `drizzle-orm` in deps | Drizzle ORM |
| `vitest` in devDeps | Vitest |
| `playwright` or `@playwright/test` in devDeps | Playwright |
| `@testing-library/react` in devDeps | Testing Library |
| `server/`, `api/`, or backend directories | Node.js backend |
| `components.json` + `@radix-ui/*` in deps | ShadCN UI overrides |
| Monorepo (`apps/`, `packages/`, workspaces) | Per-app overrides |

If a signal is absent, omit that entire section. Do not include commented-out blocks.

### CI Command Detection

Also check for CI configuration files to discover the exact lint/typecheck/test commands
that CI runs. These are authoritative — Step 8 verification must match them:

```bash
ls .github/workflows/*.yml .gitlab-ci.yml .circleci/config.yml Jenkinsfile 2>/dev/null
```

If a CI config exists, read it and extract any `eslint`, `tsc`, `npm run lint`,
`npm run typecheck`, or `npm run test` invocations. Record these as `CI_LINT_CMD`,
`CI_TSC_CMD`, and `CI_TEST_CMD`. These take priority over `detectedCommands` from
`package.json` when verifying in Step 8.

---

## Step 2: Generate the ESLint Config

Read the full reference config at `references/eslint-config-reference.mjs`.

Generate `eslint.config.mjs` using only the sections relevant to the detected project.
Every config MUST include these core sections (framework-agnostic):

- Global ignores
- `--max-warnings=0` CLI flag (treats any warning as a CI failure)
- `@eslint/js` recommended + `typescript-eslint` recommendedTypeChecked
- `eslint-plugin-de-morgan`, `unicorn`, `promise`, `security`, `sonarjs`, `regexp`
- `@eslint-community/eslint-plugin-eslint-comments`
- TypeScript type-aware linting parserOptions
- Core rule customizations (see reference config for exact values)
- Test/config file relaxations
- Unicorn customizations (filename-case with framework routing exceptions)
- `eslint-config-prettier` as the LAST entry (disables formatting rules)

Adapt file globs to match the actual project structure (e.g., `src/server/` instead of
`server/`). The detection output includes discovered globs in the `globs` field — replace
the placeholder globs in the reference config with those values.

If the project already has an ESLint config, read it first. Do not blindly overwrite —
merge the new rules into the existing structure. If it's `.eslintrc.*` (legacy format),
**always migrate to flat config** — ESLint v10+ removed eslintrc support entirely.
Extract the existing rules and recreate them as flat config entries. Preserve
project-specific rules. Show the user a diff.

---

## Step 3: Install Dependencies

Run the install command generator:

```bash
bash <skill-path>/scripts/detect-project.sh . | bash <skill-path>/scripts/generate-install-cmd.sh
```

This reads the detection JSON and outputs the exact install command for the detected
package manager, split by category. Review the output, then run the install command.

If the script is unavailable, install manually. Core packages (always needed):

```
eslint @eslint/js typescript-eslint globals eslint-config-prettier
eslint-plugin-de-morgan eslint-plugin-unicorn
eslint-plugin-promise eslint-plugin-security eslint-plugin-sonarjs
eslint-plugin-regexp @eslint-community/eslint-plugin-eslint-comments
```

Conditional packages: `eslint-plugin-react` + `eslint-plugin-react-hooks` +
`eslint-plugin-react-you-might-not-need-an-effect` (React), `@react-native/eslint-config`
(RN), `@tanstack/eslint-plugin-query` (TanStack), `eslint-plugin-drizzle` (Drizzle),
`eslint-plugin-n` (Node), `@vitest/eslint-plugin` (Vitest), `eslint-plugin-playwright`
(Playwright), `eslint-plugin-testing-library` (Testing Library).

Install as devDependencies. Show the user what was added.

---

## Step 4: Validate the Config

After installing dependencies, verify the config loads. Find any `.ts`, `.tsx`, `.js`,
or `.jsx` file in the project to test against — do not assume `src/index.ts` exists:

```bash
TEST_FILE=$(find src apps packages lib . -maxdepth 4 \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) 2>/dev/null | grep -v node_modules | head -1)
if [[ -z "$TEST_FILE" ]]; then
  TEST_FILE="eslint.config.mjs"
fi
npx eslint --print-config "$TEST_FILE" > /dev/null 2>&1
echo $?
```

Exit 0 = config loaded. Exit 2 = config/parse error. Do not proceed to auto-fix with a
broken config. See the Troubleshooting section for common config failures.

**Package manager note:** Replace `npx` with `bunx` (Bun) or `yarn exec` (Yarn PnP) if
your project uses a different package manager. The detection output's `packageManager`
field tells you which one to use.

---

## Step 5: Auto-Fix

```bash
npx eslint . --fix 2>&1 | head -100
```

For large projects (>500 files), fix by directory to keep diffs manageable.

After auto-fix, categorize remaining errors:

```bash
npx eslint . --format json 2>/dev/null | node <skill-path>/scripts/categorize-errors.js
```

This groups errors by rule, shows which are auto-fixable vs manual, and suggests a
prioritized fix order. If the script is unavailable, run `npx eslint . --format compact`
and group errors manually by rule name.

---

## Step 6: Baseline

Before starting manual fixes, capture the starting state. This is your reference point for
the before/after summary at the end.

```bash
npx eslint . --format json 2>/dev/null | node <skill-path>/scripts/categorize-errors.js
npx tsc --noEmit 2>&1 | tail -1
# Run tests and capture count
```

Record:

```
📋 Baseline (post auto-fix):
   Lint errors: <total> across <n> files (<top-3-rules-with-counts>)
   TypeScript: clean / <n> errors
   Tests: <passed>/<total>
```

Keep these numbers — you will compare against them in Step 8.

---

## Step 7: Manual Fix — Systematic Remediation

Work through remaining errors by category, not by file. Fix order (highest-impact,
lowest-risk first):

1. **Unused imports/variables** (`@typescript-eslint/no-unused-vars`) — remove unused
   imports. Check for side-effect imports before removing.
2. **Type safety** (`no-explicit-any`, `no-unsafe-*`) — replace `any` with proper types.
   Use `unknown` with type guards for complex cases. Test files are already relaxed.
3. **Deprecated APIs** (`@typescript-eslint/no-deprecated`) — look up replacements.
4. **Unicorn rules** — mechanical transforms. Do filename renames last, in a separate batch.
5. **Promise handling** — add `.catch()` or convert to async/await with try/catch.
6. **Cognitive complexity** — extract helpers, split conditionals into named booleans.
7. **Max-lines** — split files over 300 lines. Update all affected imports.
8. **React-specific** — extract nested/multi components into separate files.

### Documentation Lookup

Before attempting a manual fix, determine whether research is needed:

- **Skip lookup** for trivial fixes: unused imports, missing return types, simple renames.
- **Do lookup** when: the rule is unfamiliar, the fix requires a deprecated API replacement, the correct type narrowing is unclear, or the refactor pattern is non-obvious.

Lookup fallback chain (use the first that succeeds):

1. **Rule URL from linter output** — ESLint errors include a docs link. Read it.
2. **Documentation tools** — if MCP doc providers (Context7, etc.) or `/context7` are available, query them for the relevant library/API.
3. **Web search** — search for the rule name + "TypeScript" + the specific pattern.
4. **Flag to user** — if no source clarifies the fix, report the rule and ask before guessing.

### Fix Principles

- **Rules are immutable.** Do not add `eslint-disable`, `eslint-disable-next-line`, `@ts-ignore`, `@ts-expect-error`, or modify `eslint.config.mjs` to weaken a rule.
- **Fix the code, not the rule.** If a rule flags `any`, replace with a proper type — do not cast through `unknown` as a shortcut. If a rule flags cognitive complexity, extract named helpers.
- **Behavior must be preserved.** Every refactor must produce identical runtime behavior. Flag public API signature changes to the user before applying.
- **Research before refactoring.** Follow the Documentation Lookup chain above — understand what the rule enforces and why before proposing a fix.
- Check `tsc --noEmit` and tests after every batch of fixes.
- Fix in batches of 5 files max, then verify. If tests break, revert and redo one at a time.
- Never rename files and fix lint in the same batch — renames touch every import site.
- No drive-by changes — only touch code flagged by a violation.
- If a violation appears genuinely unfixable without suppression (e.g., a third-party type definition forces `any`), report it as a **blocked item** with rule name, file, line, and reason. Wait for the user to decide — do not suppress silently.
- If two consecutive batches don't reduce the error count, report blocked items to the user with specific refactor options for each, then wait for direction.

### Progress Reporting

Fixing a large codebase takes many turns. After each batch of fixes, report progress so
the user can track status and decide whether to continue:

```
📊 Progress: 47 errors remaining (down from 83)
   Fixed this batch: 12 errors across 5 files (unused imports)
   Blocked: 2 (third-party type forces `any` — see blocked items below)
   Next: 18 type safety errors (@typescript-eslint/no-explicit-any)
   ✅ tsc --noEmit: clean | ✅ Tests: 42 passed
```

If the remaining errors are all in one category that requires significant refactoring,
ask the user whether to proceed with deeper refactoring or defer those violations to a
follow-up task. Do not offer eslint-disable as an option.

---

## Step 8: Verification and Before/After Summary

Use the project's actual commands — the same ones CI runs. Prefer CI-detected commands
(from Step 1 CI detection) over `detectedCommands` from `package.json`, and use raw
`npx` fallbacks only if neither exists:

| Command | Priority 1 (CI config) | Priority 2 (package.json) | Fallback |
|---|---|---|---|
| Lint | `CI_LINT_CMD` | `npm run lint` | `npx eslint . --max-warnings=0` |
| Typecheck | `CI_TSC_CMD` | `npm run typecheck` | `npx tsc --noEmit` |
| Tests | `CI_TEST_CMD` | `npm run test` | (skip if no test script) |

**Always** include `--max-warnings=0` when running ESLint directly. If the project's
`npm run lint` script does not include this flag, run `npx eslint . --max-warnings=0`
as an additional check.

```bash
# Example using detected commands:
npm run lint
npm run typecheck
npm run test
```

**Completion gate — you are NOT done until all commands exit 0.** Loop: diagnose the
failure from the output, fix the code, re-run the failing command. Repeat until clean.
Do not produce the Before/After Summary until every command passes.

Once verification passes, produce a before/after summary comparing against the Step 6 baseline:

```
## Before/After Summary

| Metric           | Before (baseline) | After        | Delta   |
|------------------|--------------------|--------------|---------|
| Lint errors      | <n>                | <n>          | -<n>    |
| Files with errors| <n>                | <n>          | -<n>    |
| TypeScript       | clean / <n> errors | clean        |         |
| Tests            | <passed>/<total>   | <passed>/<total> |     |

### Refactors applied
- <rule-name>: <1-line description of refactor> (x<count>)
- ...

### Blocked items (if any)
- <rule-name> in <file>:<line> — <reason code-only fix is not possible>
```

This summary is mandatory — do not declare done without it.

### Monorepos

Place `eslint.config.mjs` at the root. Scope rules with file globs (`apps/web/**/*.tsx`).
Install dependencies at root. Adapt per-app overrides to actual app names.

**Turborepo / pnpm workspaces — tsconfig setup:**

Turborepo projects typically have a root `tsconfig.json` that acts as a base config
(`"compilerOptions"` only, no `"include"`), with per-workspace configs that extend it
(e.g., `apps/web/tsconfig.json` with `"extends": "../../tsconfig.base.json"`). For
ESLint's type-aware rules to work:

1. Keep `tsconfigRootDir: import.meta.dirname` in the ESLint config (points to the root).
   ESLint's `projectService` walks up from each file to find the nearest `tsconfig.json`.
2. Do NOT set `"include"` in the root `tsconfig.json` — let each workspace config define
   its own. A root `include` that covers everything can cause ESLint to use the wrong
   tsconfig for workspace files.
3. Add root-level scripts or config `.ts` files to `allowDefaultProject` if they aren't
   covered by any tsconfig (e.g., `"scripts/seed.ts"`).
4. If a workspace uses project references (`"references": [...]`), ESLint still resolves
   correctly — no extra config needed.

---

## Step 9: Claude Code Hook Installation

**Environment detection:** Check if a `.claude/` directory exists in the project root or any
parent directory. If it does, you are inside Claude Code — proceed with this step automatically.
If it does not exist, skip this step silently.

```bash
if [[ -d ".claude" ]] || [[ -d "../.claude" ]] || [[ -d "../../.claude" ]]; then
  echo "Claude Code detected — installing hooks"
else
  echo "Not in Claude Code — skipping Step 9"
fi
```

When Claude Code is detected, read `references/claude-code-integration.md` and execute the
setup automatically. This includes:

- PostToolUse hook (per-file lint via `scripts/lint-typecheck-hook.sh`) — automatic
- Stop hook (full project lint + typecheck) — automatic
- Self-test validation (`scripts/validate-setup.sh`) — automatic
- Hook reliability details (circuit breaker, graceful degradation, output truncation)
- TypeScript LSP plugin — **requires user action**: tell the user to run
  `/plugin install typescript-lsp@claude-plugins-official` in their Claude Code session

After installation, inform the user what was set up and how to remove it:

```
Installed Claude Code lint hooks:
- .claude/hooks/lint-typecheck.sh (PostToolUse: lints each file after edit)
- .claude/settings.json hooks entry (Stop: full project lint + typecheck)
To remove: delete .claude/hooks/lint-typecheck.sh and the "hooks" key from .claude/settings.json
```

---

## Examples

### Positive Trigger

User: "Add eslint to this TypeScript project and fix all linting errors"

Expected behavior: Runs the full 9-step workflow — detects project, generates strict config, installs dependencies, auto-fixes, manually remediates, and verifies clean.

### Non-Trigger

User: "Format this Python file with black and isort"

Expected behavior: Do not use this skill. It only handles ESLint for TypeScript/JavaScript projects.

**Example 1: Greenfield setup**
Input: "Add eslint to this project"
Detection: React + Vitest + pnpm monorepo
Expected behavior: Generates config with React/Vitest/monorepo sections, installs 18 devDependencies
via pnpm, runs auto-fix (fixes 47 errors), manually fixes 12 remaining, verifies clean.

**Example 2: Fix existing warnings**
Input: "Fix all the linting warnings in our codebase"
Detection: Existing `eslint.config.mjs` already present
Expected behavior: Reads existing config, runs `categorize-errors.js` (finds 83 errors across 6 rules),
fixes in priority order, verifies `tsc` and `vitest run` pass after each batch.

**Example 3: Strict upgrade**
Input: "Make our linter stricter, we have too many any types"
Detection: React Native + Expo + Drizzle + existing loose config
Expected behavior: Merges strict rules into existing config (adds sonarjs, unicorn, security, type-aware
checking), installs 8 new plugins, auto-fixes 120 errors, manually replaces 34 `any` types,
renames 7 files to kebab-case in a separate batch, verifies clean.

---

## Troubleshooting

- Error: ESLint config crashes on load (exit 2)
- Cause: Missing plugin import
- Solution: Check that the plugin package is installed and the import name matches

- Error: `Cannot find tsconfig`
- Cause: Wrong `tsconfigRootDir` or missing `allowDefaultProject` entry
- Solution: Set `tsconfigRootDir: import.meta.dirname` and add root JS config files to `allowDefaultProject`

- Error: `Definition for rule X was not found`
- Cause: Plugin uses legacy format, not flat config
- Solution: Use the plugin's `flat/recommended` export instead of the legacy extends syntax

- Error: `tsc --noEmit` fails after fixes
- Cause: A fix removed a needed import or broke a type
- Solution: Revert the last batch (`git stash`), redo one file at a time to isolate

- Error: Auto-fix introduces new errors
- Cause: Rule conflict between plugins (e.g., unicorn vs react)
- Solution: Identify which plugin owns the conflicting rule and configure it in the reference config's dedicated section to resolve the conflict (this is config structure, not rule suppression)

- Error: Hook fires but Claude ignores output
- Cause: Missing `"decision": "block"` in JSON
- Solution: Ensure the hook outputs `{"decision": "block", "reason": "..."}` — without this field, Claude discards it

- Error: Hook doesn't fire
- Cause: Matcher is case-sensitive
- Solution: Use `Edit|Write|MultiEdit` (PascalCase), not `edit|write|multiedit`

- Error: Hook script crashes
- Cause: Shell profile prints output on startup
- Solution: The bundled script avoids sourcing profiles; if using a custom script, wrap noisy `.zshrc` lines in `[[ $- == *i* ]]`

- Error: Circuit breaker tripped (hook stops blocking)
- Cause: 5 consecutive failures on same file
- Solution: The issue needs human intervention. Fix manually, then delete `$TMPDIR/claude-lint-breaker/` (or `/tmp/claude-lint-breaker/` if `$TMPDIR` is unset) to reset

- Error: ESLint is extremely slow (>30s)
- Cause: Type-aware rules on a huge codebase
- Solution: Scope `recommendedTypeChecked` to `src/` only, or use `recommended` (no type info) for faster runs

---

## Bundled Files Reference

| File | Purpose | When to use |
|---|---|---|
| `scripts/detect-project.sh` | Parses package.json with Node.js, outputs JSON with module flags, commands, globs | Step 1 (detection) |
| `scripts/generate-install-cmd.sh` | Takes detection JSON, outputs categorized install command | Step 3 (install) |
| `scripts/categorize-errors.js` | Groups ESLint JSON output by rule, shows fix priority (Node.js, no Python needed) | Step 5 (after auto-fix) |
| `scripts/lint-typecheck-hook.sh` | Claude Code PostToolUse hook with circuit breaker | Step 9 (Claude Code only) |
| `scripts/validate-setup.sh` | Runs checks to verify the entire setup works | Step 9 (after hook setup) |
| `scripts/test-detect-project.sh` | Test suite for detect-project.sh with fixture directories | Development / CI |
| `references/eslint-config-reference.mjs` | Full ESLint config template with all sections | Step 2 (config generation) |
| `references/claude-code-settings.json` | Template `.claude/settings.json` with hook config | Step 9 (Claude Code only) |
| `references/claude-code-integration.md` | Full Claude Code setup guide (LSP, hooks, self-test) | Step 9 (Claude Code only) |
