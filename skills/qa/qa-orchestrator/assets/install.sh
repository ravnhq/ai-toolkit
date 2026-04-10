#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# QA Agents — Project Setup Script
# Sets up .qa/ directory with config, test plan, and env file.
# Agent personality skills are installed via: npx skills add
# ============================================================

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  QA Agents — Project Setup${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""

info "Setting up QA config in: $TARGET_DIR"

# ── Detect MCPs ───────────────────────────────────────────────

SETTINGS_FILE="$TARGET_DIR/.claude/settings.local.json"
DETECTED_ISSUE_TRACKER="none"
DETECTED_PLAYWRIGHT=false
DETECTED_GITHUB_REPO=""

if [ -f "$SETTINGS_FILE" ]; then
  info "Scanning for MCP tools..."

  if grep -q "mcp__linear__save_issue" "$SETTINGS_FILE" 2>/dev/null; then
    DETECTED_ISSUE_TRACKER="linear"
    ok "Issue tracker: Linear MCP"
  elif grep -q "mcp__github__create_issue" "$SETTINGS_FILE" 2>/dev/null; then
    DETECTED_ISSUE_TRACKER="github"
    ok "Issue tracker: GitHub MCP"
  else
    warn "No issue tracker MCP detected — bugs will be reported inline"
  fi

  if grep -q "mcp__plugin_playwright_playwright\|mcp__playwright" "$SETTINGS_FILE" 2>/dev/null; then
    DETECTED_PLAYWRIGHT=true
    ok "Browser automation: Playwright MCP"
  else
    warn "Playwright MCP not detected"
    echo -e "  ${YELLOW}Install:${NC} claude mcp add playwright -- npx @anthropic-ai/mcp-playwright"
  fi
fi

if [ -d "$TARGET_DIR/.git" ]; then
  REMOTE_URL=$(cd "$TARGET_DIR" && git remote get-url origin 2>/dev/null || echo "")
  if [ -n "$REMOTE_URL" ]; then
    DETECTED_GITHUB_REPO=$(echo "$REMOTE_URL" | sed -E 's#.*[:/]([^/]+/[^/.]+)(\.git)?$#\1#')
    info "GitHub repo: $DETECTED_GITHUB_REPO"
  fi
fi

echo ""

# ── Generate config files ─────────────────────────────────────

info "Generating config files..."
mkdir -p "$TARGET_DIR/.qa/reports"

# .qa/config.yml
CONFIG="$TARGET_DIR/.qa/config.yml"
if [ -f "$CONFIG" ]; then
  warn "Skipping .qa/config.yml (exists)"
else
  cat > "$CONFIG" <<YAML
issue_tracker:
  provider: auto
  detected: $DETECTED_ISSUE_TRACKER
  linear:
    team_id: ""
    label_names: ["Bug", "QA"]
  github:
    repo: "$DETECTED_GITHUB_REPO"
    labels: ["bug", "qa"]
  jira:
    project_key: ""
    issue_type: "Bug"

playwright:
  available: $DETECTED_PLAYWRIGHT

personalities:
  builtin:
    - qa-happy-path
    - qa-chaos-monkey
    - qa-bug-fixer
  custom: []

severity_map:
  BLOCKER: 1
  HIGH: 2
  MEDIUM: 3
  LOW: 4
YAML
  ok ".qa/config.yml"
fi

# .env.qa
ENV="$TARGET_DIR/.env.qa"
if [ -f "$ENV" ]; then
  warn "Skipping .env.qa (exists)"
else
  cat > "$ENV" <<'ENVFILE'
# QA Agent Environment — DO NOT COMMIT
QA_PORTAL_URL=http://localhost:3000
QA_API_URL=http://localhost:8080
QA_API_BASE_PATH=/api

QA_TEST_USER_EMAIL=
QA_TEST_USER_PASSWORD=
QA_ADMIN_EMAIL=
QA_ADMIN_PASSWORD=

QA_AUTH_METHOD=bearer
QA_AUTH_TOKEN=

QA_AGENT_TIMEOUT=300
QA_AUTO_CREATE_ISSUES=true
ENVFILE
  ok ".env.qa"
fi

# .qa/test-plan.md
PLAN="$TARGET_DIR/.qa/test-plan.md"
if [ -f "$PLAN" ]; then
  warn "Skipping .qa/test-plan.md (exists)"
else
  cat > "$PLAN" <<'PLAN_MD'
# QA Test Plan

## Scope
**Feature/PR**:
**Date**:

## UI Flows (for qa-happy-path)

### Flow 1 — [Flow Name]
- **Type**: ui
- **Steps**:
  1. Navigate to [page]
  2. [Action]
- **Expected**: [What should happen]

## API Endpoints (for qa-chaos-monkey)

### Endpoint 1 — [Method] [Path]
- **Auth**: [required | none]
- **Required fields**: [field1, field2]
- **Expected success**: [status code]

## Acceptance Criteria
- [ ] All UI flows pass
- [ ] No 500 errors on any endpoint
- [ ] Auth boundaries enforced
PLAN_MD
  ok ".qa/test-plan.md"
fi

# ── Update .gitignore ─────────────────────────────────────────

GITIGNORE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q "^\.env\.qa$" "$GITIGNORE" 2>/dev/null; then
    echo -e "\n# QA agent credentials\n.env.qa" >> "$GITIGNORE"
    ok "Added .env.qa to .gitignore"
  fi
else
  echo -e "# QA agent credentials\n.env.qa" > "$GITIGNORE"
  ok "Created .gitignore"
fi

# ── Done ──────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "Next steps:"
echo "  1. Fill in .env.qa with your app URLs and test credentials"
echo "  2. Fill in .qa/config.yml with issue tracker details"
echo "  3. Write your test plan in .qa/test-plan.md"
echo "  4. Install QA skills: npx skills add ravnhq/ai-toolkit -s qa-orchestrator qa-happy-path qa-chaos-monkey qa-bug-fixer"
echo "  5. Run /qa-run in Claude Code"
echo ""
