#!/usr/bin/env bash
# test-detect-project.sh — Tests for detect-project.sh
# Usage: bash test-detect-project.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT="$SCRIPT_DIR/detect-project.sh"
TMPDIR_BASE=$(mktemp -d)
PASS=0
FAIL=0

cleanup() { rm -rf "$TMPDIR_BASE"; }
trap cleanup EXIT

# Helper: extract a field from JSON output
get_json() {
  local json_file="$1" path="$2"
  node -e "
    const obj=JSON.parse(require('fs').readFileSync('$json_file','utf8'));
    const val = '$path'.split('.').reduce((o,k)=>o!=null?o[k]:undefined, obj);
    console.log(val === undefined ? 'undefined' : typeof val === 'string' ? val : JSON.stringify(val));
  "
}

# Helper: run detect and save output to a temp file, return the path
run_detect() {
  local dir="$1"
  local out_file
  out_file="$TMPDIR_BASE/output-$(basename "$dir").json"
  bash "$DETECT" "$dir" > "$out_file"
  echo "$out_file"
}

assert_eq() {
  local label="$1" actual="$2" expected="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label — expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

# ─── Fixture A: Flat single-package repo ───

echo "=== Fixture A: Flat repo with Next.js + Prettier ==="
DIR_A="$TMPDIR_BASE/flat-repo"
mkdir -p "$DIR_A"
cat > "$DIR_A/package.json" <<'APKG'
{
  "name": "flat-app",
  "dependencies": { "next": "14.0.0", "react": "18.0.0", "react-dom": "18.0.0" },
  "devDependencies": { "prettier": "3.0.0", "typescript": "5.0.0" },
  "scripts": { "lint": "eslint .", "typecheck": "tsc --noEmit" }
}
APKG

OUT_A=$(run_detect "$DIR_A")
assert_eq "next=true"       "$(get_json "$OUT_A" modules.next)"       "true"
assert_eq "react=true"      "$(get_json "$OUT_A" modules.react)"      "true"
assert_eq "prettier=true"   "$(get_json "$OUT_A" modules.prettier)"   "true"
assert_eq "monorepo=false"  "$(get_json "$OUT_A" modules.monorepo)"   "false"
assert_eq "nestjs=false"    "$(get_json "$OUT_A" modules.nestjs)"     "false"
assert_eq "buildTool=none"  "$(get_json "$OUT_A" buildTool)"          "none"

# ─── Fixture B: pnpm monorepo with Next.js + NestJS + Turbo ───

echo ""
echo "=== Fixture B: pnpm monorepo (Next.js in apps/web, NestJS in apps/api, Turbo) ==="
DIR_B="$TMPDIR_BASE/pnpm-monorepo"
mkdir -p "$DIR_B/apps/web" "$DIR_B/apps/api/src"

cat > "$DIR_B/package.json" <<'BPKG'
{
  "name": "monorepo-root",
  "private": true,
  "devDependencies": { "typescript": "5.0.0", "prettier": "3.0.0" },
  "scripts": { "lint": "turbo run lint" }
}
BPKG

cat > "$DIR_B/pnpm-workspace.yaml" <<'BWORK'
packages:
  - 'apps/*'
BWORK

cat > "$DIR_B/apps/web/package.json" <<'BWEB'
{
  "name": "web",
  "dependencies": { "next": "14.0.0", "react": "18.0.0", "react-dom": "18.0.0" }
}
BWEB

cat > "$DIR_B/apps/api/package.json" <<'BAPI'
{
  "name": "api",
  "dependencies": { "@nestjs/core": "10.0.0", "@nestjs/common": "10.0.0" }
}
BAPI

touch "$DIR_B/turbo.json"
touch "$DIR_B/pnpm-lock.yaml"

OUT_B=$(run_detect "$DIR_B")
assert_eq "next=true"         "$(get_json "$OUT_B" modules.next)"         "true"
assert_eq "nestjs=true"       "$(get_json "$OUT_B" modules.nestjs)"       "true"
assert_eq "react=true"        "$(get_json "$OUT_B" modules.react)"        "true"
assert_eq "monorepo=true"     "$(get_json "$OUT_B" modules.monorepo)"     "true"
assert_eq "nodeBackend=true"  "$(get_json "$OUT_B" modules.nodeBackend)"  "true"
assert_eq "prettier=true"     "$(get_json "$OUT_B" modules.prettier)"     "true"
assert_eq "buildTool=turbo"   "$(get_json "$OUT_B" buildTool)"            "turbo"
assert_eq "pkgManager=pnpm"   "$(get_json "$OUT_B" packageManager)"       "pnpm"

# ─── Fixture C: npm workspaces monorepo ───

echo ""
echo "=== Fixture C: npm workspaces monorepo (React in packages/ui) ==="
DIR_C="$TMPDIR_BASE/npm-workspaces"
mkdir -p "$DIR_C/packages/ui"

cat > "$DIR_C/package.json" <<'CPKG'
{
  "name": "npm-mono",
  "private": true,
  "workspaces": ["packages/*"],
  "devDependencies": { "typescript": "5.0.0" }
}
CPKG

cat > "$DIR_C/packages/ui/package.json" <<'CUI'
{
  "name": "ui",
  "dependencies": { "react": "18.0.0", "react-dom": "18.0.0" }
}
CUI

OUT_C=$(run_detect "$DIR_C")
assert_eq "react=true"       "$(get_json "$OUT_C" modules.react)"      "true"
assert_eq "monorepo=true"    "$(get_json "$OUT_C" modules.monorepo)"   "true"
assert_eq "buildTool=none"   "$(get_json "$OUT_C" buildTool)"          "none"
assert_eq "nestjs=false"     "$(get_json "$OUT_C" modules.nestjs)"     "false"

# ─── Fixture D: No package.json (should exit 1) ───

echo ""
echo "=== Fixture D: No package.json ==="

DIR_D="$TMPDIR_BASE/fixture-d"
mkdir -p "$DIR_D"

if bash "$DETECT" "$DIR_D" > /dev/null 2>&1; then
  echo "  ✗ Expected exit 1 for missing package.json"
  FAIL=$((FAIL + 1))
else
  echo "  ✓ Correctly exits 1 for missing package.json"
  PASS=$((PASS + 1))
fi

# ─── Fixture E: Bun project with bun.lock (text-based lockfile) ───

echo ""
echo "=== Fixture E: Bun project with bun.lock ==="

DIR_E="$TMPDIR_BASE/fixture-e"
mkdir -p "$DIR_E"

cat > "$DIR_E/package.json" <<'EPKG'
{
  "name": "bun-app",
  "dependencies": { "hono": "4.0.0" },
  "devDependencies": { "typescript": "5.0.0" }
}
EPKG

touch "$DIR_E/bun.lock"

OUT_E=$(run_detect "$DIR_E")
assert_eq "pkgManager=bun"  "$(get_json "$OUT_E" packageManager)"     "bun"

# ─── Fixture F: Existing eslint flat config ───

echo ""
echo "=== Fixture F: Existing eslint.config.mjs ==="

DIR_F="$TMPDIR_BASE/fixture-f"
mkdir -p "$DIR_F"

cat > "$DIR_F/package.json" <<'FPKG'
{
  "name": "flat-config-app",
  "dependencies": {},
  "devDependencies": { "eslint": "9.0.0", "typescript": "5.0.0" }
}
FPKG

touch "$DIR_F/eslint.config.mjs"

OUT_F=$(run_detect "$DIR_F")
assert_eq "existingConfig=flat-mjs" "$(get_json "$OUT_F" existingConfig)" "flat-mjs"

# ─── Fixture G: Project with "check" script (command detection) ───

echo ""
echo "=== Fixture G: 'check' script detection ==="

DIR_G="$TMPDIR_BASE/fixture-g"
mkdir -p "$DIR_G"

cat > "$DIR_G/package.json" <<'GPKG'
{
  "name": "check-app",
  "dependencies": {},
  "devDependencies": { "typescript": "5.0.0" },
  "scripts": {
    "check": "tsc --noEmit"
  }
}
GPKG

OUT_G=$(run_detect "$DIR_G")
assert_eq "typecheck=npm run check" "$(get_json "$OUT_G" detectedCommands.typecheck)" "npm run check"

# ─── Fixture H: pnpm monorepo install command uses -Dw ───

echo ""
echo "=== Fixture H: generate-install-cmd.sh uses -Dw for pnpm monorepo ==="

# Feed a minimal pnpm monorepo detection JSON to generate-install-cmd.sh
INSTALL_CMD=$(echo '{"modules":{"react":false,"reactNative":false,"tanstackQuery":false,"drizzle":false,"vitest":false,"jest":false,"playwright":false,"testingLibrary":false,"nodeBackend":false,"monorepo":true},"packageManager":"pnpm","buildTool":"turbo"}' | bash "$SCRIPT_DIR/generate-install-cmd.sh" 2>&1)

if echo "$INSTALL_CMD" | grep -q "pnpm add -Dw"; then
  echo "  ✓ pnpm monorepo uses -Dw flag"
  PASS=$((PASS + 1))
else
  echo "  ✗ pnpm monorepo should use -Dw flag, got: $(echo "$INSTALL_CMD" | head -5)"
  FAIL=$((FAIL + 1))
fi

# Non-monorepo pnpm should use plain -D
INSTALL_CMD_FLAT=$(echo '{"modules":{"react":false,"reactNative":false,"tanstackQuery":false,"drizzle":false,"vitest":false,"jest":false,"playwright":false,"testingLibrary":false,"nodeBackend":false,"monorepo":false},"packageManager":"pnpm","buildTool":"none"}' | bash "$SCRIPT_DIR/generate-install-cmd.sh" 2>&1)

if echo "$INSTALL_CMD_FLAT" | grep -q "pnpm add -D "; then
  echo "  ✓ pnpm flat project uses -D flag (no -w)"
  PASS=$((PASS + 1))
else
  echo "  ✗ pnpm flat project should use plain -D, got: $(echo "$INSTALL_CMD_FLAT" | head -5)"
  FAIL=$((FAIL + 1))
fi

# ─── Summary ───

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[[ $FAIL -eq 0 ]] || exit 1
