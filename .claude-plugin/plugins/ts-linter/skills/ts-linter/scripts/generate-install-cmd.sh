#!/usr/bin/env bash
# generate-install-cmd.sh — Given detection JSON (stdin or file), outputs the install command.
# Usage: bash detect-project.sh /path/to/project | bash generate-install-cmd.sh
#   or:  bash generate-install-cmd.sh < detection.json

set -euo pipefail

INPUT=$(cat)

# Parse JSON with Node.js (portable, no jq needed)
# Checks modules.* first (detect-project.sh nests flags), then top-level (packageManager)
get_field() {
  node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));const v=d.modules?.['$1']??d['$1']??'';process.stdout.write(String(v))" <<< "$INPUT"
}

PKG_MANAGER=$(get_field "packageManager")
MONOREPO=$(get_field "monorepo")
REACT=$(get_field "react")
REACT_NATIVE=$(get_field "reactNative")
TANSTACK=$(get_field "tanstackQuery")
DRIZZLE=$(get_field "drizzle")
VITEST=$(get_field "vitest")
PLAYWRIGHT=$(get_field "playwright")
TESTING_LIB=$(get_field "testingLibrary")
NODE_BACKEND=$(get_field "nodeBackend")

# --- Core packages (always installed) ---
CORE_PKGS=(
  "eslint"
  "@eslint/js"
  "typescript"
  "typescript-eslint"
  "@eslint-community/eslint-plugin-eslint-comments"
  "eslint-config-prettier"
  "eslint-plugin-de-morgan"
  "eslint-plugin-promise"
  "eslint-plugin-regexp"
  "eslint-plugin-security"
  "eslint-plugin-sonarjs"
  "eslint-plugin-unicorn"
  "globals"
)

REACT_PKGS=()
NATIVE_PKGS=()
QUERY_PKGS=()
DRIZZLE_PKGS=()
TEST_PKGS=()
NODE_PKGS=()
# --- Conditional packages ---

if [[ "$REACT" == "true" ]]; then
  REACT_PKGS=(
    "eslint-plugin-react"
    "eslint-plugin-react-hooks"
    "eslint-plugin-react-you-might-not-need-an-effect"
  )
fi

if [[ "$REACT_NATIVE" == "true" ]]; then
  NATIVE_PKGS=("@react-native/eslint-config")
fi

if [[ "$TANSTACK" == "true" ]]; then
  QUERY_PKGS=("@tanstack/eslint-plugin-query")
fi

if [[ "$DRIZZLE" == "true" ]]; then
  DRIZZLE_PKGS=("eslint-plugin-drizzle")
fi

if [[ "$VITEST" == "true" ]]; then
  TEST_PKGS+=("@vitest/eslint-plugin")
fi

if [[ "$PLAYWRIGHT" == "true" ]]; then
  TEST_PKGS+=("eslint-plugin-playwright")
fi

if [[ "$TESTING_LIB" == "true" ]]; then
  TEST_PKGS+=("eslint-plugin-testing-library")
fi

if [[ "$NODE_BACKEND" == "true" ]]; then
  NODE_PKGS=("eslint-plugin-n")
fi

# --- Build install command ---

ALL_PKGS=("${CORE_PKGS[@]}" "${REACT_PKGS[@]}" "${NATIVE_PKGS[@]}" "${QUERY_PKGS[@]}" "${DRIZZLE_PKGS[@]}" "${TEST_PKGS[@]}" "${NODE_PKGS[@]}")

case "$PKG_MANAGER" in
  pnpm)
    # pnpm monorepos require -w to install at the workspace root
    if [[ "$MONOREPO" == "true" ]]; then
      CMD="pnpm add -Dw"
    else
      CMD="pnpm add -D"
    fi
    ;;
  yarn)  CMD="yarn add -D" ;;
  bun)   CMD="bun add -D" ;;
  *)     CMD="npm install -D" ;;
esac

echo "# ================================================"
echo "# ESLint Dependencies Install Command"
echo "# Package manager: $PKG_MANAGER"
echo "# ================================================"
echo ""
# Print as a single executable command (no inline comments that break continuations)
# Collect all packages into a flat list, then print with continuations except the last
{
  for pkg in "${ALL_PKGS[@]}"; do
    echo "$pkg"
  done
} | {
  total=${#ALL_PKGS[@]}
  i=0
  echo "$CMD \\"
  while IFS= read -r pkg; do
    i=$((i + 1))
    if [[ $i -lt $total ]]; then
      echo "  $pkg \\"
    else
      echo "  $pkg"
    fi
  done
}

# Print summary as comments after the command
echo ""
echo "# Total packages: ${#ALL_PKGS[@]}"
echo "#"
echo "# Categories included:"
echo "#   Core: ${#CORE_PKGS[@]} packages"
if [[ ${#REACT_PKGS[@]} -gt 0 ]]; then echo "#   React: ${#REACT_PKGS[@]} packages"; fi
if [[ ${#NATIVE_PKGS[@]} -gt 0 ]]; then echo "#   React Native: ${#NATIVE_PKGS[@]} packages"; fi
if [[ ${#QUERY_PKGS[@]} -gt 0 ]]; then echo "#   TanStack Query: ${#QUERY_PKGS[@]} packages"; fi
if [[ ${#DRIZZLE_PKGS[@]} -gt 0 ]]; then echo "#   Drizzle ORM: ${#DRIZZLE_PKGS[@]} packages"; fi
if [[ ${#TEST_PKGS[@]} -gt 0 ]]; then echo "#   Testing: ${#TEST_PKGS[@]} packages"; fi
if [[ ${#NODE_PKGS[@]} -gt 0 ]]; then echo "#   Node.js: ${#NODE_PKGS[@]} packages"; fi
