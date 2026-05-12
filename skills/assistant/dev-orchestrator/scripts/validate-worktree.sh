#!/usr/bin/env bash
# Auto-detect and run lint / type-check / test commands inside a worktree.
#
# Usage:
#   validate-worktree.sh <worktree_path>
#
# Stops on first failing check. Absent checks count as PASS.
#
# Exit codes:
#   0  all detected checks passed (or none detected)
#   1  invalid args
#   2  a check failed (failing command and tail of output printed)

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: validate-worktree.sh <worktree_path>" >&2
  exit 1
fi

WT_PATH="$1"
cd "$WT_PATH"

run_check() {
  local label="$1"; shift
  echo "→ $label: $*"
  set +e
  local output
  output="$("$@" 2>&1)"
  local rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    echo "failure: $label  (exit $rc)"
    echo "------ last 40 lines ------"
    printf '%s\n' "$output" | tail -n 40
    return "$rc"
  fi
  echo "success: $label"
  return 0
}

has_npm_script() {
  [[ -f package.json ]] || return 1
  node -e "process.exit(require('./package.json').scripts && require('./package.json').scripts['$1'] ? 0 : 1)" 2>/dev/null
}

if [[ -f package.json ]]; then
  if has_npm_script lint; then
    run_check "npm run lint" npm run lint --silent || exit 2
  fi
  if has_npm_script typecheck; then
    run_check "npm run typecheck" npm run typecheck --silent || exit 2
  elif [[ -f tsconfig.json ]] && command -v npx >/dev/null 2>&1; then
    run_check "tsc --noEmit" npx --no-install tsc --noEmit || exit 2
  fi
  if has_npm_script test; then
    if grep -q '"jest"' package.json 2>/dev/null; then
      run_check "npm test" npm test --silent -- --watch=false --passWithNoTests || exit 2
    else
      run_check "npm test" npm test --silent || exit 2
    fi
  fi
fi

if [[ -f pyproject.toml || -f setup.py ]]; then
  if command -v ruff >/dev/null 2>&1; then
    run_check "ruff check" ruff check . || exit 2
  fi
  if command -v mypy >/dev/null 2>&1 && [[ -f mypy.ini || -f pyproject.toml ]]; then
    run_check "mypy" mypy . || exit 2
  fi
  if [[ -d tests || -d test ]] && command -v pytest >/dev/null 2>&1; then
    run_check "pytest" pytest -q || exit 2
  fi
fi

if [[ -f Gemfile ]]; then
  if command -v bundle >/dev/null 2>&1; then
    if [[ -f .rubocop.yml ]]; then
      run_check "rubocop" bundle exec rubocop || exit 2
    fi
    if [[ -d spec ]]; then
      run_check "rspec" bundle exec rspec || exit 2
    fi
  fi
fi

echo "VALIDATION_STATUS=pass"
exit 0
