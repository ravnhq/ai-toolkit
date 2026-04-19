# Claude Code Integration

After the linter is set up and passing, install Claude Code hooks and the TypeScript LSP
plugin automatically. Do not ask for permission — this step runs whenever Claude Code is
detected. This ensures Claude Code automatically lints and type-checks every file it edits,
creating a self-correcting loop where errors are caught and fixed before Claude finishes.

Proceed with all substeps below.

## Install the TypeScript LSP Plugin

This gives Claude Code real-time type information, go-to-definition, and diagnostics.
Use the official Anthropic plugin from the default marketplace:

```bash
# Install the language server globally
npm install -g typescript-language-server typescript
```

Then tell the user to run this inside their Claude Code session:

```
/plugin install typescript-lsp@claude-plugins-official
```

The `claude-plugins-official` marketplace is available by default — no need to add it.
This plugin uses `typescript-language-server --stdio` and covers `.ts`, `.tsx`, `.js`,
`.jsx`, `.mts`, `.cts`, `.mjs`, `.cjs` files.

After installing, the user should run `/reload-plugins` to activate it in the current
session.

## Detect Lint/Typecheck/Test Commands

The detection script (`scripts/detect-project.sh`) now outputs a `detectedCommands` field
with the lint, typecheck, and test commands it found in `package.json` scripts. Use those
values directly:

```bash
bash <skill-path>/scripts/detect-project.sh . | node -e "
  let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
    const o=JSON.parse(d);
    console.log('LINT_CMD:', o.detectedCommands.lint || 'npx eslint . --max-warnings=0');
    console.log('TSC_CMD:', o.detectedCommands.typecheck || 'npx tsc --noEmit');
    console.log('TEST_CMD:', o.detectedCommands.test || '(none)');
  });
"
```

If the detection script is unavailable, read `package.json` scripts manually:

```bash
cat package.json | grep -E '"lint"|"typecheck"|"type-check"|"check"|"tsc"|"test"'
```

Map what you find:

| `package.json` script | Hook variable | Fallback |
|---|---|---|
| `"lint"` or `"lint:check"` | `LINT_CMD` | `npx eslint` (or `pnpm exec eslint` for pnpm) |
| `"typecheck"` or `"type-check"` or `"tsc"` | `TSC_CMD` | `npx tsc --noEmit` (or `pnpm exec tsc --noEmit`) |
| `"test"` or `"test:unit"` | `TEST_CMD` | (skip if absent) |

Common patterns to detect:

- `"lint": "eslint ."` → use `npm run lint` for the Stop hook
- `"lint": "turbo lint"` → use `npm run lint` (turbo handles parallelism)
- `"typecheck": "tsc --noEmit"` → use `npm run typecheck` for the Stop hook
- `"check": "biome check"` → different linter, still wire it up
- No lint script at all → add `"lint": "eslint ."` to package.json scripts

For the **PostToolUse** hook (per-file), always use `npx eslint <file>` directly —
`npm run lint` runs the full project which is too slow for per-edit feedback.

For the **Stop** hook (end-of-response), use the `npm run` commands since they run
the full project and may include flags or turbo orchestration the user has set up.

## Create the Hook and Settings

Create `.claude/hooks/lint-typecheck.sh` in the project root. The bundled script is at
`scripts/lint-typecheck-hook.sh`:

```bash
mkdir -p .claude/hooks
cp <skill-path>/scripts/lint-typecheck-hook.sh .claude/hooks/lint-typecheck.sh
chmod +x .claude/hooks/lint-typecheck.sh
```

Then create or merge into `.claude/settings.json`, using the detected commands.
A template is at `references/claude-code-settings.json` — replace the placeholders:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/lint-typecheck.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "<LINT_CMD> 2>&1 | head -30 && <TSC_CMD> 2>&1 | head -30"
          }
        ]
      }
    ]
  }
}
```

Replace `<LINT_CMD>` and `<TSC_CMD>` with the actual detected commands. Examples:

- Detected `"lint": "eslint ."` and `"typecheck": "tsc --noEmit"`:
  `"command": "npm run lint 2>&1 | head -30 && npm run typecheck 2>&1 | head -30"`

- Detected `"lint": "turbo lint"` and `"typecheck": "turbo typecheck"`:
  `"command": "npm run lint 2>&1 | head -50 && npm run typecheck 2>&1 | head -50"`

- Nothing detected (fallback):
  `"command": "npx eslint . --max-warnings=0 2>&1 | head -30 && npx tsc --noEmit 2>&1 | head -30"`

If `.claude/settings.json` already exists, merge the `hooks` key into it. Do not overwrite
existing settings.

## How the Self-Correcting Loop Works

1. Claude edits a file
2. `PostToolUse` hook fires, runs ESLint on that single file
3. If errors exist, hook outputs `{"decision": "block", "reason": "ESLint: ..."}`
4. Claude sees the errors and edits the file again to fix them
5. Hook fires again on the new edit
6. Repeats until the file is clean
7. When Claude finishes, `Stop` hook runs the full project lint + typecheck
8. If anything fails, Claude continues fixing

Without `"decision": "block"` in the JSON output, Claude silently discards hook output.
The hook script handles this correctly. Always exit 0 from hooks — communication happens
through the JSON, not exit codes.

This is deterministic enforcement — unlike CLAUDE.md instructions, hooks cannot be ignored.

## Run the Self-Test

After creating the hook and settings, validate the entire setup:

```bash
bash <skill-path>/scripts/validate-setup.sh .
```

This script checks:
- ESLint config exists and loads without crashing
- All core dependencies are installed
- TypeScript compiles (or reports how many errors exist)
- Hook script exists, is executable, and runs without crashing
- Hook correctly outputs `{"decision": "block", ...}` when lint errors exist
- Hook correctly skips non-TS files and handles empty stdin
- `settings.json` is valid JSON with the expected hook keys
- Circuit breaker state is clean

If any checks fail, fix them before declaring the setup complete. Show the user the
full output so they can see what passed and what needs attention.

## Hook Reliability Details

The hook script (`lint-typecheck-hook.sh`) is designed to never crash and never block
the user incorrectly:

- **No external dependencies**: Parses JSON with bash regex, not `jq`. Works on any
  system with bash 3.2+.
- **Circuit breaker**: Tracks consecutive failures per file in `/tmp/claude-lint-breaker/`.
  After 5 failures on the same file, stops blocking so Claude isn't stuck in an infinite
  loop. Resets automatically when the file passes or on the next session.
- **Graceful degradation**: If ESLint isn't installed, `npx` isn't available, or
  `node_modules` is missing, the hook silently exits 0 (no block).
- **Output truncation**: Limits ESLint output to 80 lines to avoid overwhelming Claude's
  context window with massive error dumps.
- **Safe JSON escaping**: Handles quotes, backslashes, and newlines in ESLint output
  without breaking the JSON structure.
- **Ignored directories**: Skips `node_modules`, `.next`, `dist`, `build`, `.expo`,
  `.turbo`, `coverage`, `.wrangler` — matching the ESLint config's ignores.
