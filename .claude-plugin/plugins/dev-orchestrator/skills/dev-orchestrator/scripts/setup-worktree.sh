#!/usr/bin/env bash
# Provision an isolated git worktree + feature branch for a single
# orchestrator sub-task. The worktree is created off whatever base branch
# the caller supplies — typically the integration branch produced by
# `setup-integration-branch.sh`, but any branch the orchestrator wants to
# fork from works (a protected base when running outside the integration
# pattern, for example).
#
# Usage:
#   setup-worktree.sh --task "<task body>" [--branch <name>] [--base <branch>]
#
# Emits two machine-readable lines on success:
#   WORKTREE_PATH=<absolute path>
#   WORKTREE_BRANCH=<branch name>
#
# Exit codes:
#   0  success
#   1  invalid args / missing prerequisites
#   2  cwd not inside a git repo
#   3  base branch does not exist
#   4  worktree path collision
#   5  git worktree add failed

set -euo pipefail

TASK=""
BRANCH=""
BASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)   TASK="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --base)   BASE="${2:-}"; shift 2 ;;
    *)        echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TASK" && -z "$BRANCH" ]]; then
  echo "either --task or --branch is required" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "not inside a git repository" >&2
  exit 2
fi

ensure_local_ref() {
  local name="$1"
  if git -C "$REPO_ROOT" rev-parse --verify "$name" >/dev/null 2>&1; then
    return 0
  fi
  if git -C "$REPO_ROOT" rev-parse --verify "origin/$name" >/dev/null 2>&1; then
    git -C "$REPO_ROOT" branch --no-track "$name" "origin/$name" >/dev/null 2>&1 || true
    if git -C "$REPO_ROOT" rev-parse --verify "$name" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

resolve_base() {
  if [[ -n "$BASE" ]]; then
    if git -C "$REPO_ROOT" rev-parse --verify "$BASE" >/dev/null 2>&1; then
      echo "$BASE"; return 0
    fi
    if git -C "$REPO_ROOT" rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then
      git -C "$REPO_ROOT" branch --no-track "$BASE" "origin/$BASE" >/dev/null 2>&1 || true
      if git -C "$REPO_ROOT" rev-parse --verify "$BASE" >/dev/null 2>&1; then
        echo "$BASE"; return 0
      fi
    fi
    echo "explicit --base '$BASE' not found locally or on origin" >&2
    return 3
  fi

  git -C "$REPO_ROOT" fetch origin --quiet 2>/dev/null || true

  local candidate
  for candidate in develop dev; do
    if ensure_local_ref "$candidate"; then
      echo "$candidate"; return 0
    fi
  done

  local main_ok=0 master_ok=0
  ensure_local_ref main && main_ok=1 || true
  ensure_local_ref master && master_ok=1 || true

  if [[ "$main_ok" -eq 1 && "$master_ok" -eq 0 ]]; then
    echo main; return 0
  fi
  if [[ "$main_ok" -eq 0 && "$master_ok" -eq 1 ]]; then
    echo master; return 0
  fi
  if [[ "$main_ok" -eq 1 && "$master_ok" -eq 1 ]]; then
    local ct_main ct_master
    ct_main="$(git -C "$REPO_ROOT" log -1 --format=%ct main 2>/dev/null || echo 0)"
    ct_master="$(git -C "$REPO_ROOT" log -1 --format=%ct master 2>/dev/null || echo 0)"
    if [[ "$ct_main" -ge "$ct_master" ]]; then
      echo main; return 0
    fi
    echo master; return 0
  fi

  echo "no protected base branch found (need develop or dev, or main or master); pass --base explicitly" >&2
  return 3
}

slugify() {
  local input="$1"
  printf '%s' "$input" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-40
}

BASE_BRANCH="$(resolve_base)" || exit $?

git -C "$REPO_ROOT" fetch origin --quiet 2>/dev/null || true

if [[ -z "$BRANCH" ]]; then
  SLUG="$(slugify "$TASK")"
  [[ -z "$SLUG" ]] && SLUG="task"
  BRANCH="agent/${SLUG}-$(date +%s)"
fi

BRANCH_LEAF="${BRANCH##*/}"
REPO_NAME="$(basename "$REPO_ROOT")"
REPO_PARENT="$(dirname "$REPO_ROOT")"
WT_PATH="${REPO_PARENT}/${REPO_NAME}-${BRANCH_LEAF}"

if [[ -e "$WT_PATH" ]]; then
  echo "path already exists: $WT_PATH" >&2
  exit 4
fi

if ! git -C "$REPO_ROOT" worktree add "$WT_PATH" -b "$BRANCH" "$BASE_BRANCH" >/dev/null 2>&1; then
  echo "git worktree add failed; see 'git worktree list' for state" >&2
  exit 5
fi

for f in .env .env.local .env.development .env.production .env.test .envrc .tool-versions .nvmrc; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    cp "$REPO_ROOT/$f" "$WT_PATH/$f"
  fi
done

if compgen -G "$REPO_ROOT/.env.*" >/dev/null; then
  for f in "$REPO_ROOT"/.env.*; do
    [[ -f "$f" ]] || continue
    cp "$f" "$WT_PATH/$(basename "$f")"
  done
fi

echo "WORKTREE_PATH=$WT_PATH"
echo "WORKTREE_BRANCH=$BRANCH"
