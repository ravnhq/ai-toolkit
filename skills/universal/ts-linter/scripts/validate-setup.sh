#!/usr/bin/env bash
# validate-setup.sh — Runs after linter + hooks setup to verify everything works.
# Usage: bash validate-setup.sh [project-root]
#
# Checks: ESLint loads, TypeScript compiles, hook script runs, settings.json is
# valid, and the generated config doesn't crash on a real file.
# Exits 0 if all checks pass, 1 if any fail.

set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || { echo "FAIL: can't cd to $ROOT"; exit 1; }

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN + 1)); }

echo "================================================"
echo "  Linter Setup Validation"
echo "================================================"
echo ""

# -----------------------------------------------------------
# 1. ESLint config exists
# -----------------------------------------------------------
echo "📋 Config files"

if [[ -f "eslint.config.mjs" ]] || [[ -f "eslint.config.js" ]] || [[ -f "eslint.config.ts" ]]; then
  pass "ESLint flat config found"
elif [[ -f ".eslintrc.js" ]] || [[ -f ".eslintrc.json" ]] || [[ -f ".eslintrc.yml" ]]; then
  warn "Legacy ESLint config found (flat config recommended)"
else
  fail "No ESLint config found"
fi

if [[ -f "tsconfig.json" ]]; then
  pass "tsconfig.json found"
else
  fail "tsconfig.json missing (type-aware rules won't work)"
fi

echo ""

# -----------------------------------------------------------
# 2. Detect package runner (supports npx, bunx, yarn PnP)
# -----------------------------------------------------------
echo "📦 Package runner"

RUNNER=""
if [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
  command -v bunx &>/dev/null && RUNNER="bunx"
elif [[ -f ".pnp.cjs" ]] || [[ -f ".pnp.js" ]]; then
  command -v yarn &>/dev/null && RUNNER="yarn exec"
fi
if [[ -z "$RUNNER" ]]; then
  command -v npx &>/dev/null && RUNNER="npx"
fi

if [[ -n "$RUNNER" ]]; then
  pass "Package runner detected: $RUNNER"
else
  fail "No package runner found (npx, bunx, or yarn)"
fi

# Check dependencies are available (PM-agnostic: test via runner, not node_modules)
if [[ -n "$RUNNER" ]]; then
  if $RUNNER eslint --version &>/dev/null; then
    pass "eslint is resolvable"
  else
    fail "eslint is not resolvable — run your package manager install first"
  fi
fi

echo ""

# -----------------------------------------------------------
# 3. ESLint actually loads without crashing
# -----------------------------------------------------------
echo "🔧 ESLint smoke test"

if [[ -n "$RUNNER" ]]; then
  if eslint_version=$($RUNNER eslint --version 2>&1); then
    pass "ESLint runs (${eslint_version})"
  else
    fail "ESLint crashes on --version: $eslint_version"
  fi
else
  fail "Skipping ESLint smoke test (no runner)"
fi

# Find a real .ts, .tsx, .js, or .jsx file to test against
test_file=""
for candidate in $(find src apps packages lib . -maxdepth 4 \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) 2>/dev/null | grep -v node_modules | head -5); do
  if [[ -f "$candidate" ]] && [[ ! "$candidate" =~ node_modules ]]; then
    test_file="$candidate"
    break
  fi
done

# Fall back to eslint.config.mjs itself if no source files found
if [[ -z "$test_file" ]] && [[ -f "eslint.config.mjs" ]]; then
  test_file="eslint.config.mjs"
fi

if [[ -n "$test_file" ]] && [[ -n "$RUNNER" ]]; then
  config_check=$($RUNNER eslint "$test_file" --no-error-on-unmatched-pattern 2>&1)
  eslint_exit=$?
  if [[ $eslint_exit -le 1 ]]; then
    # exit 0 = clean, exit 1 = lint errors (config loaded fine)
    pass "ESLint config loads successfully (tested on $test_file)"
  else
    # exit 2 = config/parse error
    fail "ESLint config fails to load: $(echo "$config_check" | head -5)"
  fi
else
  warn "No source files found to test config against"
fi

echo ""

# -----------------------------------------------------------
# 4. TypeScript compiles
# -----------------------------------------------------------
echo "🔍 TypeScript"

if [[ -n "$RUNNER" ]]; then
  if tsc_version=$($RUNNER tsc --version 2>&1); then
    pass "TypeScript compiler available ($tsc_version)"
  else
    fail "TypeScript compiler not found"
  fi

  # In Turborepo projects, `tsc --noEmit` at the root may check 0 files or fail
  # because the root tsconfig is a base config without `include`. Use the project's
  # typecheck script (which typically runs `turbo typecheck`) when available.
  TSC_CMD=""
  if [[ -f "package.json" ]]; then
    TSC_CMD=$(node -e "
      const pkg=JSON.parse(require('fs').readFileSync('package.json','utf8'));
      const s=pkg.scripts||{};
      const k=['typecheck','type-check','tsc','check'].find(k=>s[k]);
      if(k)process.stdout.write(k);
    " 2>/dev/null) || true
  fi

  if [[ -n "$TSC_CMD" ]]; then
    # Detect run prefix
    case "$RUNNER" in
      bunx)      RUN_PFX="bun run" ;;
      "yarn exec") RUN_PFX="yarn" ;;
      *)         if [[ -f "pnpm-lock.yaml" ]]; then RUN_PFX="pnpm run"; else RUN_PFX="npm run"; fi ;;
    esac
    tsc_check=$($RUN_PFX "$TSC_CMD" 2>&1)
    tsc_exit=$?
    tsc_label="$RUN_PFX $TSC_CMD"
  else
    tsc_check=$($RUNNER tsc --noEmit 2>&1)
    tsc_exit=$?
    tsc_label="tsc --noEmit"
  fi

  if [[ $tsc_exit -eq 0 ]]; then
    pass "TypeScript compiles clean ($tsc_label)"
  else
    error_count=$(echo "$tsc_check" | grep -c "error TS" || true)
    warn "TypeScript has $error_count type errors via $tsc_label (expected if linter was just added)"
  fi
else
  fail "Skipping TypeScript check (no runner)"
fi

echo ""

# -----------------------------------------------------------
# 5. Claude Code hook infrastructure
# -----------------------------------------------------------
echo "🪝 Claude Code hooks"

if [[ -f ".claude/hooks/lint-typecheck.sh" ]]; then
  pass "Hook script exists"

  if [[ -x ".claude/hooks/lint-typecheck.sh" ]]; then
    pass "Hook script is executable"
  else
    fail "Hook script is NOT executable (run: chmod +x .claude/hooks/lint-typecheck.sh)"
  fi

  # Dry-run the hook with a fake payload to verify it doesn't crash
  if [[ -n "$test_file" ]]; then
    fake_payload="{\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$test_file\"},\"tool_response\":{},\"session_id\":\"test\",\"cwd\":\"$PWD\"}"
    hook_out=$(echo "$fake_payload" | timeout 15 .claude/hooks/lint-typecheck.sh 2>&1)
    hook_exit=$?

    if [[ $hook_exit -eq 0 ]]; then
      pass "Hook script runs without crashing"

      if [[ -n "$hook_out" ]]; then
        # Verify it's valid JSON
        if echo "$hook_out" | grep -q '"decision"'; then
          pass "Hook outputs valid blocking JSON (lint errors found in test file — expected)"
        else
          fail "Hook output doesn't contain \"decision\" field — Claude will ignore it"
        fi
      else
        pass "Hook ran clean (no lint errors in test file, or file was skipped)"
      fi
    else
      fail "Hook script crashed with exit code $hook_exit"
    fi
  else
    warn "Skipping hook dry-run (no test file available)"
  fi

  # Test with a synthetic known-bad TS file to prove blocking works
  bad_file=".claude-validate-bad-$$.ts"
  echo 'const x: any = 1; const y: any = 2;' > "$bad_file"
  bad_payload="{\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$bad_file\"},\"tool_response\":{},\"session_id\":\"test\",\"cwd\":\"$PWD\"}"
  bad_out=$(echo "$bad_payload" | timeout 15 .claude/hooks/lint-typecheck.sh 2>&1)
  rm -f "$bad_file"
  if [[ -n "$bad_out" ]] && echo "$bad_out" | grep -q '"decision"'; then
    pass "Hook correctly blocks on known-bad TS file"
  else
    warn "Hook did not block on synthetic bad file (ESLint may not flag 'any' without type-aware rules)"
  fi

  # Test with a non-TS file to verify it skips gracefully
  skip_payload='{"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"README.md"},"tool_response":{},"session_id":"test","cwd":"."}'
  if skip_out=$(echo "$skip_payload" | timeout 5 .claude/hooks/lint-typecheck.sh 2>&1) && [[ -z "$skip_out" ]]; then
    pass "Hook correctly skips non-TS files"
  else
    warn "Hook produced unexpected output for non-TS file"
  fi

  # Test with empty stdin
  if empty_out=$(echo "" | timeout 5 .claude/hooks/lint-typecheck.sh 2>&1) && [[ -z "$empty_out" ]]; then
    pass "Hook handles empty stdin gracefully"
  else
    fail "Hook crashes on empty stdin"
  fi
else
  warn "Hook script not found at .claude/hooks/lint-typecheck.sh (Claude Code integration not set up)"
fi

# Check settings.json
if [[ -f ".claude/settings.json" ]]; then
  pass "Claude Code settings.json exists"

  # Verify it contains hook configuration
  if grep -q '"PostToolUse"' .claude/settings.json 2>/dev/null; then
    pass "PostToolUse hook configured"
  else
    warn "PostToolUse hook not found in settings.json"
  fi

  if grep -q '"Stop"' .claude/settings.json 2>/dev/null; then
    pass "Stop hook configured"
  else
    warn "Stop hook not found in settings.json"
  fi

  # Verify it's valid JSON (using node since it's always available in a TS project)
  if node -e "JSON.parse(require('fs').readFileSync('.claude/settings.json','utf8'))" 2>/dev/null; then
    pass "settings.json is valid JSON"
  else
    fail "settings.json is NOT valid JSON — hooks won't load"
  fi
else
  warn "No .claude/settings.json found (Claude Code integration not set up)"
fi

echo ""

# -----------------------------------------------------------
# 6. Circuit breaker state is clean
# -----------------------------------------------------------
echo "🔌 Circuit breaker"

breaker_dir="${TMPDIR:-/tmp}/claude-lint-breaker"
if [[ -d "$breaker_dir" ]]; then
  stale_count=$(find "$breaker_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$stale_count" -gt 0 ]]; then
    warn "$stale_count stale breaker files from previous sessions (cleaning up)"
    rm -rf "$breaker_dir"
    mkdir -p "$breaker_dir"
    pass "Circuit breaker state cleaned"
  else
    pass "Circuit breaker state is clean"
  fi
else
  pass "No circuit breaker state (fresh install)"
fi

echo ""

# -----------------------------------------------------------
# Summary
# -----------------------------------------------------------
echo "================================================"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "================================================"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "  ⛔ $FAIL check(s) failed. Fix these before using the linter."
  exit 1
elif [[ $WARN -gt 0 ]]; then
  echo ""
  echo "  ⚠️  All critical checks passed, but $WARN warning(s) to review."
  exit 0
else
  echo ""
  echo "  🎉 Everything looks good. Linter is ready."
  exit 0
fi
