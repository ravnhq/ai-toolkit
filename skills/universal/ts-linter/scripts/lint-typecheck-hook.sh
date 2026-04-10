#!/usr/bin/env bash
# lint-typecheck-hook.sh — Claude Code PostToolUse hook
#
# Zero external dependencies (no jq). Parses stdin JSON with bash builtins.
# Runs ESLint on the edited file. Outputs blocking JSON if errors found.
# Includes a circuit breaker: after 5 consecutive failures on the same file,
# stops blocking so Claude isn't stuck in an infinite fix loop.
#
# Install: cp this to .claude/hooks/lint-typecheck.sh && chmod +x it
# Configure: add PostToolUse hook in .claude/settings.json

# --- Safety: suppress noisy shell profile output ---
# (Claude Code hooks inherit the user's shell; .zshrc/.bashrc that print
#  on startup will corrupt stdout JSON. This script never sources profiles.)

set -uo pipefail

# --- Read stdin (JSON payload from Claude Code) ---
input=$(cat 2>/dev/null) || input=""
if [[ -z "$input" ]]; then
  exit 0
fi

# --- Extract file_path and cwd without jq ---
# Works for Edit, Write, MultiEdit — all put file_path in tool_input.
# Handles both "file_path": "/abs/path" and "file_path": "rel/path".
file_path=""
if [[ "$input" =~ \"file_path\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  file_path="${BASH_REMATCH[1]}"
fi

# Extract cwd from payload and cd into it for lockfile/runner detection
hook_cwd=""
if [[ "$input" =~ \"cwd\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
  hook_cwd="${BASH_REMATCH[1]}"
fi
if [[ -n "$hook_cwd" ]] && [[ -d "$hook_cwd" ]]; then
  cd "$hook_cwd" || true
fi

# --- Early exits ---
# No file path extracted
if [[ -z "$file_path" ]]; then
  exit 0
fi

# File doesn't exist (might have been deleted/moved)
if [[ ! -f "$file_path" ]]; then
  exit 0
fi

# Not a JS/TS file
if [[ ! "$file_path" =~ \.(js|ts|jsx|tsx|mjs|mts|cjs|cts)$ ]]; then
  exit 0
fi

# Inside ignored directories
if [[ "$file_path" =~ (node_modules|\.next|dist|build|\.expo|\.turbo|coverage|\.wrangler)/ ]]; then
  exit 0
fi

# --- Circuit breaker ---
# Track consecutive failures per file. After 5 failures on the same file,
# stop blocking — the issue likely needs human intervention.
BREAKER_DIR="${TMPDIR:-/tmp}/claude-lint-breaker"
mkdir -p "$BREAKER_DIR" 2>/dev/null || true

# Create a safe filename from the path (replace / with __)
safe_name="${file_path//\//__}"
breaker_file="$BREAKER_DIR/$safe_name"

fail_count=0
if [[ -f "$breaker_file" ]]; then
  fail_count=$(cat "$breaker_file" 2>/dev/null || echo 0)
  # If not a number, reset
  if ! [[ "$fail_count" =~ ^[0-9]+$ ]]; then
    fail_count=0
  fi
fi

if [[ "$fail_count" -ge 5 ]]; then
  # Circuit open: stop blocking, let Claude finish.
  # Reset the counter so next session starts fresh.
  rm -f "$breaker_file" 2>/dev/null
  exit 0
fi

# --- Detect package runner ---
# Supports npx, pnpm, bunx, and yarn (PnP). Falls back gracefully.
RUNNER=""
if [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
  command -v bunx &>/dev/null && RUNNER="bunx"
elif [[ -f "pnpm-lock.yaml" ]]; then
  command -v pnpm &>/dev/null && RUNNER="pnpm exec"
elif [[ -f ".pnp.cjs" ]] || [[ -f ".pnp.js" ]]; then
  command -v yarn &>/dev/null && RUNNER="yarn exec"
fi
if [[ -z "$RUNNER" ]]; then
  command -v npx &>/dev/null && RUNNER="npx" || exit 0
fi

# Quick check that eslint is actually installed in the project
# Skip node_modules check for Yarn PnP, Bun, and pnpm (strict node_modules)
if [[ "$RUNNER" == "npx" ]]; then
  if [[ ! -d "node_modules/.bin" ]] || ! npx eslint --version &>/dev/null; then
    exit 0
  fi
else
  if ! $RUNNER eslint --version &>/dev/null; then
    exit 0
  fi
fi

# --- Run ESLint on the single file ---
lint_out=$($RUNNER eslint "$file_path" 2>&1)
lint_exit=$?

if [[ $lint_exit -eq 0 ]]; then
  # File is clean — reset the circuit breaker for this file
  rm -f "$breaker_file" 2>/dev/null
  exit 0
fi

# --- No config in scope: don't block ---
# ESLint v9 flat config prints "Could not find config file" when no
# eslint.config.* exists walking up from the linted file (e.g., tooling dirs
# outside the main project tree). This is not a lint error — skip silently.
if echo "$lint_out" | grep -q "Could not find config file"; then
  exit 0
fi

# --- ESLint failed: increment breaker and output blocking JSON ---
new_count=$((fail_count + 1))
echo "$new_count" > "$breaker_file" 2>/dev/null

# Truncate output to prevent overwhelming Claude (max 80 lines, ~4KB)
truncated_out=$(echo "$lint_out" | head -80)
line_count=$(echo "$lint_out" | wc -l | tr -d ' ')
if [[ "$line_count" -gt 80 ]]; then
  truncated_out="${truncated_out}
... ($((line_count - 80)) more lines truncated)"
fi

# Escape the output for valid JSON (handle quotes, backslashes, newlines)
escaped_out=$(printf '%s' "$truncated_out" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output blocking JSON — this is the only way Claude sees the errors.
# Without "decision": "block", Claude silently discards this output.
printf '{"decision":"block","reason":"ESLint errors in %s (attempt %d/5):\\n%s\\n\\nFix these errors before continuing."}\n' \
  "$file_path" "$new_count" "$escaped_out"

exit 0
