#!/usr/bin/env bash
# detect-project.sh — Scans a project and outputs which ESLint modules to enable.
# Usage: bash detect-project.sh [project-root]
#
# Uses Node.js to parse package.json (guaranteed available in any TS project)
# instead of grep-based substring matching.
# Outputs a JSON object with boolean flags for each module.

set -euo pipefail

ROOT="${1:-.}"
PKG="$ROOT/package.json"

if [[ ! -f "$PKG" ]]; then
  echo "❌ No package.json found in $ROOT" >&2
  exit 1
fi

# Verify node is available
if ! command -v node &>/dev/null; then
  echo "❌ Node.js is required but not found in PATH" >&2
  exit 1
fi

# Helper: check if directory exists
has_dir() {
  [[ -d "$ROOT/$1" ]]
}

# --- Parse package.json with Node for accurate dependency detection ---
# This avoids grep substring false positives (e.g., "react" matching "react-native").

DEP_FLAGS=$(PKG_PATH="$PKG" node -e "
const pkg = JSON.parse(require('fs').readFileSync(process.env.PKG_PATH, 'utf8'));
const all = { ...pkg.dependencies, ...pkg.devDependencies, ...pkg.peerDependencies };
const has = (name) => name in all;

const flags = {
  react: has('react') || has('react-dom') || has('next'),
  reactNative: has('react-native') || has('expo'),
  tanstackQuery: has('@tanstack/react-query'),
  drizzle: has('drizzle-orm'),
  vitest: has('vitest'),
  jest: has('jest'),
  playwright: has('@playwright/test') || has('playwright'),
  testingLibrary: has('@testing-library/react'),
  prettier: has('prettier'),
  next: has('next'),
  expo: has('expo'),
  nestjs: has('@nestjs/core'),
};

// React Native implies React
if (flags.reactNative) flags.react = true;

// Detect lint/typecheck/test script names (PM prefix added later by shell)
const scripts = pkg.scripts || {};
const scriptInfo = {
  lintScript: null,
  typecheckScript: null,
  testScript: null,
};

for (const [key, val] of Object.entries(scripts)) {
  if (/^lint(:|$)/.test(key) && !scriptInfo.lintScript) scriptInfo.lintScript = key;
  if (/^(typecheck|type-check|tsc|check)$/.test(key) && !scriptInfo.typecheckScript) scriptInfo.typecheckScript = key;
  if (/^test(:|$)/.test(key) && !key.includes('e2e') && !scriptInfo.testScript) scriptInfo.testScript = key;
}

// Detect workspaces
const hasWorkspaces = !!(pkg.workspaces || (Array.isArray(pkg.workspaces) && pkg.workspaces.length > 0));

console.log(JSON.stringify({ ...flags, hasWorkspaces, scripts: scriptInfo }));
" 2>/dev/null)

if [[ -z "$DEP_FLAGS" ]]; then
  echo "❌ Failed to parse package.json with Node.js" >&2
  exit 1
fi

# Extract values from the Node output
get_flag() {
  echo "$DEP_FLAGS" | node -e "
    let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
      const obj=JSON.parse(d); console.log(obj['$1'] || false);
    });
  "
}

HAS_REACT=$(get_flag react)
HAS_REACT_NATIVE=$(get_flag reactNative)
HAS_TANSTACK_QUERY=$(get_flag tanstackQuery)
HAS_DRIZZLE=$(get_flag drizzle)
HAS_VITEST=$(get_flag vitest)
HAS_JEST=$(get_flag jest)
HAS_PLAYWRIGHT=$(get_flag playwright)
HAS_TESTING_LIBRARY=$(get_flag testingLibrary)
HAS_PRETTIER=$(get_flag prettier)
HAS_NEXT=$(get_flag next)
HAS_EXPO=$(get_flag expo)
HAS_NESTJS=$(get_flag nestjs)
HAS_WORKSPACES=$(get_flag hasWorkspaces)

# Prettier config files (Node might not detect .prettierrc)
if [[ "$HAS_PRETTIER" == "false" ]]; then
  for f in .prettierrc .prettierrc.json .prettierrc.yml .prettierrc.js prettier.config.mjs prettier.config.js; do
    if [[ -f "$ROOT/$f" ]]; then
      HAS_PRETTIER=true
      break
    fi
  done
fi

# --- Directory-based detection ---

HAS_NODE_BACKEND=false
for dir in server api src/server src/api packages/api apps/api apps/server; do
  if has_dir "$dir"; then
    HAS_NODE_BACKEND=true
    break
  fi
done

HAS_MONOREPO=false
if has_dir "apps" || has_dir "packages" || [[ -f "$ROOT/pnpm-workspace.yaml" ]] || [[ -f "$ROOT/lerna.json" ]] || [[ "$HAS_WORKSPACES" == "true" ]]; then
  HAS_MONOREPO=true
fi

# --- Scan workspace package.json files for dependencies ---

if [[ "$HAS_MONOREPO" == "true" ]]; then
  WORKSPACE_FLAGS=$(PROJECT_ROOT="$ROOT" node -e "
    const fs = require('fs');
    const path = require('path');
    const root = process.env.PROJECT_ROOT;

    // Resolve workspace glob patterns to actual directories
    let patterns = [];

    // Try pnpm-workspace.yaml (line-by-line extraction)
    const pnpmWs = path.join(root, 'pnpm-workspace.yaml');
    if (fs.existsSync(pnpmWs)) {
      const lines = fs.readFileSync(pnpmWs, 'utf8').split('\n');
      for (const line of lines) {
        const m = line.match(/^\s*-\s*['\"]?([^'\"]+)['\"]?\s*$/);
        if (m) patterns.push(m[1]);
      }
    }

    // Fallback: package.json workspaces field
    if (patterns.length === 0) {
      try {
        const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
        const ws = Array.isArray(pkg.workspaces) ? pkg.workspaces : (pkg.workspaces && pkg.workspaces.packages) || [];
        patterns = ws;
      } catch(e) {}
    }

    // Expand glob patterns (simple: only supports trailing /*)
    const dirs = [];
    for (const p of patterns) {
      const clean = p.replace(/\/\*$/, '');
      const base = path.join(root, clean);
      if (fs.existsSync(base) && fs.statSync(base).isDirectory()) {
        if (p.endsWith('/*')) {
          try {
            for (const entry of fs.readdirSync(base)) {
              const full = path.join(base, entry);
              if (fs.statSync(full).isDirectory()) dirs.push(full);
            }
          } catch(e) {}
        } else {
          dirs.push(base);
        }
      }
    }

    // Scan each workspace for dependencies
    const flags = {
      react: false, reactNative: false, tanstackQuery: false, drizzle: false,
      vitest: false, jest: false, playwright: false, testingLibrary: false,
      prettier: false, next: false, expo: false, nestjs: false,
    };

    for (const dir of dirs) {
      const pkgPath = path.join(dir, 'package.json');
      if (!fs.existsSync(pkgPath)) continue;
      try {
        const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
        const all = { ...pkg.dependencies, ...pkg.devDependencies, ...pkg.peerDependencies };
        const has = (n) => n in all;
        if (has('react') || has('react-dom') || has('next')) flags.react = true;
        if (has('react-native') || has('expo')) { flags.reactNative = true; flags.react = true; }
        if (has('@tanstack/react-query')) flags.tanstackQuery = true;
        if (has('drizzle-orm')) flags.drizzle = true;
        if (has('vitest')) flags.vitest = true;
        if (has('jest')) flags.jest = true;
        if (has('@playwright/test') || has('playwright')) flags.playwright = true;
        if (has('@testing-library/react')) flags.testingLibrary = true;
        if (has('prettier')) flags.prettier = true;
        if (has('next')) flags.next = true;
        if (has('expo')) flags.expo = true;
        if (has('@nestjs/core')) flags.nestjs = true;
      } catch(e) {}
    }
    console.log(JSON.stringify(flags));
  " 2>/dev/null) || true

  if [[ -n "$WORKSPACE_FLAGS" ]]; then
    # Merge workspace flags into root flags (OR logic)
    merge_flag() {
      local ws_val
      ws_val=$(echo "$WORKSPACE_FLAGS" | node -e "
        let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
          console.log(JSON.parse(d)['$1'] || false);
        });
      ")
      if [[ "$ws_val" == "true" ]]; then
        echo "true"
      else
        echo "$2"
      fi
    }
    HAS_REACT=$(merge_flag react "$HAS_REACT")
    HAS_REACT_NATIVE=$(merge_flag reactNative "$HAS_REACT_NATIVE")
    HAS_TANSTACK_QUERY=$(merge_flag tanstackQuery "$HAS_TANSTACK_QUERY")
    HAS_DRIZZLE=$(merge_flag drizzle "$HAS_DRIZZLE")
    HAS_VITEST=$(merge_flag vitest "$HAS_VITEST")
    HAS_JEST=$(merge_flag jest "$HAS_JEST")
    HAS_PLAYWRIGHT=$(merge_flag playwright "$HAS_PLAYWRIGHT")
    HAS_TESTING_LIBRARY=$(merge_flag testingLibrary "$HAS_TESTING_LIBRARY")
    HAS_PRETTIER=$(merge_flag prettier "$HAS_PRETTIER")
    HAS_NEXT=$(merge_flag next "$HAS_NEXT")
    HAS_EXPO=$(merge_flag expo "$HAS_EXPO")
    HAS_NESTJS=$(merge_flag nestjs "$HAS_NESTJS")
  fi
fi

# --- NestJS implies Node backend ---

if [[ "$HAS_NESTJS" == "true" ]]; then
  HAS_NODE_BACKEND=true
fi

# --- Detect ShadCN UI ---
# ShadCN generates multi-component files by design. Detected via:
# 1. components.json (ShadCN config file), AND
# 2. @radix-ui/* or class-variance-authority in deps

HAS_SHADCN=false
if [[ -f "$ROOT/components.json" ]]; then
  # Verify it's actually ShadCN by checking for Radix UI or CVA in deps
  SHADCN_CONFIRM=$(PKG_PATH="$PKG" node -e "
    const pkg = JSON.parse(require('fs').readFileSync(process.env.PKG_PATH, 'utf8'));
    const all = { ...pkg.dependencies, ...pkg.devDependencies };
    const hasRadix = Object.keys(all).some(k => k.startsWith('@radix-ui/'));
    const hasCva = 'class-variance-authority' in all;
    console.log(hasRadix || hasCva);
  " 2>/dev/null)
  if [[ "$SHADCN_CONFIRM" == "true" ]]; then
    HAS_SHADCN=true
  fi
fi

# --- Detect package manager ---

PKG_MANAGER="npm"
if [[ -f "$ROOT/pnpm-lock.yaml" ]]; then
  PKG_MANAGER="pnpm"
elif [[ -f "$ROOT/yarn.lock" ]]; then
  PKG_MANAGER="yarn"
elif [[ -f "$ROOT/bun.lockb" ]] || [[ -f "$ROOT/bun.lock" ]]; then
  PKG_MANAGER="bun"
fi

# --- Detect monorepo build tool ---

BUILD_TOOL="none"
if [[ -f "$ROOT/turbo.json" ]]; then
  BUILD_TOOL="turbo"
elif [[ -f "$ROOT/nx.json" ]]; then
  BUILD_TOOL="nx"
elif [[ -f "$ROOT/lerna.json" ]]; then
  BUILD_TOOL="lerna"
fi

# --- Detect existing ESLint config ---

EXISTING_CONFIG="none"
if [[ -f "$ROOT/eslint.config.mjs" ]]; then
  EXISTING_CONFIG="flat-mjs"
elif [[ -f "$ROOT/eslint.config.js" ]]; then
  EXISTING_CONFIG="flat-js"
elif [[ -f "$ROOT/eslint.config.ts" ]]; then
  EXISTING_CONFIG="flat-ts"
elif [[ -f "$ROOT/.eslintrc.js" ]] || [[ -f "$ROOT/.eslintrc.json" ]] || [[ -f "$ROOT/.eslintrc.yml" ]] || [[ -f "$ROOT/.eslintrc" ]]; then
  EXISTING_CONFIG="legacy"
fi

# --- Discover file globs ---

build_glob_array() {
  local dirs=("$@")
  local result="["
  local first=true
  for dir in "${dirs[@]}"; do
    if has_dir "$dir"; then
      $first || result+=","
      result+="\"**/${dir}/**/*.ts\",\"**/${dir}/**/*.tsx\",\"**/${dir}/**/*.js\",\"**/${dir}/**/*.jsx\",\"**/${dir}/**/*.mjs\""
      first=false
    fi
  done
  result+="]"
  echo "$result"
}

SERVER_GLOBS=$(build_glob_array server api src/server src/api packages/api apps/api apps/server)
NATIVE_GLOBS=$(build_glob_array native apps/native apps/mobile packages/native packages/mobile)
DB_GLOBS=$(build_glob_array db src/db packages/db apps/api/db server/db)
E2E_GLOBS=$(build_glob_array e2e tests/e2e test/e2e apps/web/e2e packages/e2e)

# --- Extract detected commands (PM-aware) ---

# Build the run prefix for the detected package manager
case "$PKG_MANAGER" in
  pnpm)  RUN_PREFIX="pnpm run" ;;
  yarn)  RUN_PREFIX="yarn" ;;
  bun)   RUN_PREFIX="bun run" ;;
  *)     RUN_PREFIX="npm run" ;;
esac

LINT_SCRIPT=$(echo "$DEP_FLAGS" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const o=JSON.parse(d);console.log(o.scripts?.lintScript||'')})")
TSC_SCRIPT=$(echo "$DEP_FLAGS" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const o=JSON.parse(d);console.log(o.scripts?.typecheckScript||'')})")
TEST_SCRIPT=$(echo "$DEP_FLAGS" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const o=JSON.parse(d);console.log(o.scripts?.testScript||'')})")

LINT_CMD=""
TSC_CMD=""
TEST_CMD=""
[[ -n "$LINT_SCRIPT" ]] && LINT_CMD="$RUN_PREFIX $LINT_SCRIPT"
[[ -n "$TSC_SCRIPT" ]] && TSC_CMD="$RUN_PREFIX $TSC_SCRIPT"
[[ -n "$TEST_SCRIPT" ]] && TEST_CMD="$RUN_PREFIX $TEST_SCRIPT"

# --- Output ---

cat <<EOF
{
  "modules": {
    "react": $HAS_REACT,
    "reactNative": $HAS_REACT_NATIVE,
    "tanstackQuery": $HAS_TANSTACK_QUERY,
    "drizzle": $HAS_DRIZZLE,
    "vitest": $HAS_VITEST,
    "jest": $HAS_JEST,
    "playwright": $HAS_PLAYWRIGHT,
    "testingLibrary": $HAS_TESTING_LIBRARY,
    "nodeBackend": $HAS_NODE_BACKEND,
    "monorepo": $HAS_MONOREPO,
    "prettier": $HAS_PRETTIER,
    "next": $HAS_NEXT,
    "expo": $HAS_EXPO,
    "nestjs": $HAS_NESTJS,
    "shadcn": $HAS_SHADCN
  },
  "packageManager": "$PKG_MANAGER",
  "buildTool": "$BUILD_TOOL",
  "existingConfig": "$EXISTING_CONFIG",
  "detectedCommands": {
    "lint": "${LINT_CMD:-}",
    "typecheck": "${TSC_CMD:-}",
    "test": "${TEST_CMD:-}"
  },
  "globs": {
    "server": $SERVER_GLOBS,
    "native": $NATIVE_GLOBS,
    "db": $DB_GLOBS,
    "e2e": $E2E_GLOBS
  }
}
EOF
