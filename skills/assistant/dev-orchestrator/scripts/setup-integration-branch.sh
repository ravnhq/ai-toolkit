#!/usr/bin/env bash
# Provision the integration branch for a worktree-orchestrator run.
#
# The integration branch is the merge target for every per-task worktree the
# orchestrator spawns. Each task worktree branches off the integration branch
# tip, runs its agent, and merges back into the integration branch. At
# the end of the run, the orchestrator hands the integration branch off to
# `agent-pr-creator` (integration branch -> protected base) instead of merging
# directly into main/develop.
#
# Usage:
#   setup-integration-branch.sh --name <branch> [--base <branch>] [--reuse]
#   setup-integration-branch.sh --ticket <id> [--prefix <prefix>] [--slug <slug>] \
#                               [--base <branch>] [--reuse]
#   setup-integration-branch.sh --task "<text>" [--base <branch>] [--reuse]
#
# Behavior:
#   - Resolves the protected base: explicit --base wins; else prefer develop, then
#     dev (integration branches). If neither exists, prefer main or master
#     whichever exists; if both exist, pick the one whose tip commit is newer
#     (committer timestamp). Errors out if none of these exist.
#   - Fetches origin and (best-effort) fast-forwards the local base branch
#     ref from origin/<base> when a remote-tracking branch exists.
#   - Derives the integration branch name from --name, --ticket (+optional
#     --prefix / --slug), or --task (auto-slug). At least one must be given.
#   - Creates the integration branch off the resolved base tip when it does
#     not exist. With --reuse, an existing branch is accepted as-is (no reset);
#     without --reuse, an existing branch is a hard error so we never silently
#     stomp on work from another run.
#   - Never checks anything out in the primary worktree — the branch is
#     created as a floating ref so the user keeps their original HEAD.
#
# Outputs (on success, parseable from stdout):
#   INTEGRATION_BRANCH=<branch>
#   BASE_BRANCH=<branch>
#
# Exit codes:
#   0  success
#   1  invalid args
#   2  cwd not inside a git repository
#   3  protected base could not be resolved
#   4  integration branch already exists (and --reuse was not passed)
#   5  failed to create the integration branch ref

set -euo pipefail

NAME=""
TICKET=""
PREFIX=""
SLUG=""
TASK=""
BASE=""
REUSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)   NAME="${2:-}"; shift 2 ;;
    --ticket) TICKET="${2:-}"; shift 2 ;;
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    --slug)   SLUG="${2:-}"; shift 2 ;;
    --task)   TASK="${2:-}"; shift 2 ;;
    --base)   BASE="${2:-}"; shift 2 ;;
    --reuse)  REUSE=1; shift ;;
    *)        echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$NAME" && -z "$TICKET" && -z "$TASK" ]]; then
  echo "one of --name, --ticket, or --task is required" >&2
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

  echo "no protected base branch found (need develop or dev, or main or master)" >&2
  return 3
}

slugify() {
  local input="$1"
  printf '%s' "$input" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-40
}

derive_branch_name() {
  if [[ -n "$NAME" ]]; then
    printf '%s' "$NAME"; return
  fi
  if [[ -n "$TICKET" ]]; then
    local p="${PREFIX:-ticket}"
    local s=""
    [[ -n "$SLUG" ]] && s="-$(slugify "$SLUG")"
    [[ -z "$s" && -n "$TASK" ]] && s="-$(slugify "$TASK")"
    printf '%s/%s%s' "$p" "$TICKET" "$s"
    return
  fi
  local task_slug
  task_slug="$(slugify "$TASK")"
  [[ -z "$task_slug" ]] && task_slug="task"
  printf 'feature/%s-%s' "$task_slug" "$(date +%s)"
}

BASE_BRANCH="$(resolve_base)" || exit $?

git -C "$REPO_ROOT" fetch origin --quiet 2>/dev/null || true

if git -C "$REPO_ROOT" rev-parse --verify "origin/$BASE_BRANCH" >/dev/null 2>&1; then
  if git -C "$REPO_ROOT" rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" >/dev/null 2>&1; then
    current_branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ "$current_branch" == "$BASE_BRANCH" ]]; then
      git -C "$REPO_ROOT" pull --ff-only origin "$BASE_BRANCH" >/dev/null 2>&1 || true
    else
      git -C "$REPO_ROOT" fetch origin "$BASE_BRANCH:$BASE_BRANCH" --quiet >/dev/null 2>&1 || true
    fi
  fi
  BASE_TIP="origin/$BASE_BRANCH"
else
  BASE_TIP="$BASE_BRANCH"
fi

INTEGRATION_BRANCH="$(derive_branch_name)"

if git -C "$REPO_ROOT" rev-parse --verify "$INTEGRATION_BRANCH" >/dev/null 2>&1; then
  if [[ "$REUSE" -eq 0 ]]; then
    echo "integration branch already exists: $INTEGRATION_BRANCH (pass --reuse to adopt it)" >&2
    exit 4
  fi
else
  if ! git -C "$REPO_ROOT" branch "$INTEGRATION_BRANCH" "$BASE_TIP" >/dev/null 2>&1; then
    echo "failed to create branch $INTEGRATION_BRANCH from $BASE_TIP" >&2
    exit 5
  fi
fi

echo "INTEGRATION_BRANCH=$INTEGRATION_BRANCH"
echo "BASE_BRANCH=$BASE_BRANCH"
