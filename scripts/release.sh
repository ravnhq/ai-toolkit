#!/usr/bin/env bash
#
# Manual per-skill build release (local use only).
# CI handles releases automatically on merge to main.
# Use this script when you need to release outside the normal PR flow.
#
# Usage: ./scripts/release.sh <skill-name> [build]
# Example: ./scripts/release.sh core-coding-standards
# Example: ./scripts/release.sh core-coding-standards 12

set -euo pipefail

SKILL_NAME="${1:-}"
SET_BUILD="${2:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
  echo -e "${RED}✗ Error: $1${NC}" >&2
  exit 1
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

info() {
  echo -e "${YELLOW}→ $1${NC}"
}

if [[ -z "$SKILL_NAME" ]]; then
  error "Usage: $0 <skill-name> [build]\nExample: $0 core-coding-standards"
fi

SKILL_PATH=$(find skills -path "*/${SKILL_NAME}/SKILL.md" -not -path "*/_drafts/*" | head -1)
if [[ -z "$SKILL_PATH" || ! -f "$SKILL_PATH" ]]; then
  error "Skill not found: ${SKILL_NAME}"
fi

if [[ -n "$SET_BUILD" && ! "$SET_BUILD" =~ ^[1-9][0-9]*$ ]]; then
  error "Build must be a positive integer (e.g., 1, 2, 3)"
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  error "Working directory has uncommitted changes. Commit or stash them first."
fi

# Check if on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
  info "Warning: Not on main branch (current: $CURRENT_BRANCH)"
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

info "Releasing build for $SKILL_NAME..."

# Step 1: Validate skills and marketplace entry
info "Running skills audit..."
if ! ruby scripts/skills_audit.rb; then
  error "Skills audit failed. Fix issues before releasing."
fi
success "Skills audit passed"

info "Validating marketplace.json entry..."
SKILL_NAME="$SKILL_NAME" ruby -e "
require 'json'
skill = ENV.fetch('SKILL_NAME')
marketplace = JSON.parse(File.read('marketplace.json'))
entry = marketplace['skills']&.find { |s| s['name'] == skill }
abort \"Skill #{skill} missing from marketplace.json\" unless entry
"
success "Found $SKILL_NAME in marketplace.json"

# Step 2: Bump build (shared script also updates marketplace.json)
info "Bumping build in $SKILL_PATH..."
if [[ -n "$SET_BUILD" ]]; then
  NEW_BUILD=$(ruby scripts/skill_version.rb "$SKILL_PATH" "$SET_BUILD")
else
  NEW_BUILD=$(ruby scripts/skill_version.rb "$SKILL_PATH")
fi
success "Updated $SKILL_NAME build to $NEW_BUILD"

# Step 3: Check tag doesn't already exist
TAG="skill-${SKILL_NAME}-b${NEW_BUILD}"
if git rev-parse "$TAG" >/dev/null 2>&1; then
  error "Tag $TAG already exists"
fi

# Step 4: Commit build bump
info "Committing build bump..."
git add "$SKILL_PATH" marketplace.json
git commit -m "chore(${SKILL_NAME}): bump build to ${NEW_BUILD}"
success "Created commit"

# Step 5: Create annotated tag
info "Creating annotated tag $TAG..."
git tag -a "$TAG" -m "Release ${SKILL_NAME} build ${NEW_BUILD}"
success "Created tag $TAG"

# Step 6: Ask about pushing
echo
info "Build release prepared locally:"
echo "  Skill: $SKILL_NAME"
echo "  Build: $NEW_BUILD"
echo "  Tag: $TAG"
echo "  Commit: $(git rev-parse --short HEAD)"
echo
read -p "Push to remote? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # Push commit and tag
  info "Pushing to remote..."
  git push origin "$CURRENT_BRANCH"
  git push origin "$TAG"
  success "Pushed commit and tag"
else
  info "Release prepared but not pushed. To push manually:"
  echo "  git push origin $CURRENT_BRANCH"
  echo "  git push origin $TAG"
fi
