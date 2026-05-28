#!/usr/bin/env bash
# Merge a worktree-orchestrator feature branch back into a base branch.
#
# The base is supplied by the caller. In the dependency-aware integration
# pattern the base is the orchestrator's integration branch (so each task
# worktree merges into the integration branch before agent-pr-creator opens
# a PR from the integration branch to the protected base). The script is
# also usable for the legacy "merge straight to main/develop" flow.
#
# The merge runs inside a DEDICATED integration worktree for <base_branch> —
# it never checks out <base_branch> in the user's primary worktree, so the
# user's HEAD and working tree are never touched. A merge conflict is left
# in progress inside that dedicated worktree (contained, not in the primary
# checkout) for the reconciler / user to resolve.
#
# Usage:
#   merge-worktree.sh <worktree_path> <feature_branch> <base_branch> \
#       [--keep-branch] [--no-push] [--summary "<text>"]
#
# Outputs (on success, parseable from stdout):
#   MERGE_STATUS=clean
#   PUSH_STATUS=<pushed|local-only|push-failed>
#   INTEGRATION_WORKTREE=<absolute path>   # validate / push against this
#
# Exit codes:
#   0  merged cleanly (feature worktree + branch cleaned up unless --keep-branch)
#   1  invalid args
#   2  merge conflicts (left in progress inside the integration worktree;
#      conflicted files printed to stdout)
#   3  integration worktree dirty (refuse to merge onto unsaved state)
#   4  could not provision the dedicated integration worktree
#   5  no commits on the feature branch
#   6  push failed (merge already landed locally; surfaced for visibility)

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: merge-worktree.sh <worktree_path> <feature_branch> <base_branch> [--keep-branch] [--no-push] [--summary <text>]" >&2
  exit 1
fi

WT_PATH="$1"; shift
FEATURE="$1"; shift
BASE="$1"; shift

KEEP_BRANCH=0
NO_PUSH=0
SUMMARY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-branch) KEEP_BRANCH=1; shift ;;
    --no-push)     NO_PUSH=1; shift ;;
    --summary)     SUMMARY="${2:-}"; shift 2 ;;
    *)             echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# The first entry of `worktree list` is always the primary (main) worktree.
PRIMARY_ROOT="$(git -C "$WT_PATH" worktree list --porcelain | awk '/^worktree / { print $2; exit }')"
if [[ -z "$PRIMARY_ROOT" ]]; then
  echo "could not resolve primary worktree from $WT_PATH" >&2
  exit 1
fi

# Find an existing worktree already checked out on BASE, if any.
find_worktree_for_branch() {
  local target="$1"
  git -C "$PRIMARY_ROOT" worktree list --porcelain | awk -v b="refs/heads/$target" '
    $1 == "worktree" { p = $2 }
    $1 == "branch" && $2 == b { print p; exit }
  '
}

# Verify the feature branch actually carries commits before doing anything.
if ! git -C "$WT_PATH" rev-list --count "$BASE..$FEATURE" >/dev/null 2>&1; then
  echo "could not compare $BASE..$FEATURE" >&2
  exit 5
fi
NEW_COMMITS="$(git -C "$WT_PATH" rev-list --count "$BASE..$FEATURE")"
if [[ "$NEW_COMMITS" -eq 0 ]]; then
  echo "no new commits on $FEATURE relative to $BASE" >&2
  exit 5
fi

# Provision (or reuse) a dedicated integration worktree for BASE. This is the
# only place BASE is ever checked out — the primary worktree is never touched.
INTEGRATION_WT="$(find_worktree_for_branch "$BASE")"
if [[ -z "$INTEGRATION_WT" ]]; then
  REPO_NAME="$(basename "$PRIMARY_ROOT")"
  REPO_PARENT="$(dirname "$PRIMARY_ROOT")"
  BASE_LEAF="${BASE##*/}"
  INTEGRATION_WT="${REPO_PARENT}/${REPO_NAME}-integration-${BASE_LEAF}"
  if [[ -e "$INTEGRATION_WT" ]]; then
    echo "integration worktree path exists but is not a worktree on $BASE: $INTEGRATION_WT" >&2
    exit 4
  fi
  if ! git -C "$PRIMARY_ROOT" worktree add "$INTEGRATION_WT" "$BASE" >/dev/null 2>&1; then
    echo "failed to create integration worktree for $BASE at $INTEGRATION_WT" >&2
    exit 4
  fi
fi

# Refuse to merge onto an integration worktree with unsaved changes.
if [[ -n "$(git -C "$INTEGRATION_WT" status --porcelain)" ]]; then
  echo "integration worktree $INTEGRATION_WT is dirty; refusing to merge" >&2
  exit 3
fi

# Keep the local integration branch current with origin only when it has a
# remote-tracking branch (legacy "merge straight to main" flow). During the
# orchestrator's Phase 3 the integration branch is not yet pushed, so this is
# a no-op and the merge proceeds against the local tip.
git -C "$INTEGRATION_WT" fetch origin --quiet 2>/dev/null || true
if git -C "$INTEGRATION_WT" rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then
  if ! git -C "$INTEGRATION_WT" pull --ff-only origin "$BASE" >/dev/null 2>&1; then
    echo "fast-forward pull of $BASE failed; resolve manually before retrying" >&2
    exit 4
  fi
fi

MSG="Merge agent work from $FEATURE"
if [[ -n "$SUMMARY" ]]; then
  MSG="$MSG: $SUMMARY"
fi

set +e
git -C "$INTEGRATION_WT" merge --no-ff --no-edit "$FEATURE" -m "$MSG" >/dev/null 2>&1
MERGE_EXIT=$?
set -e

if [[ "$MERGE_EXIT" -ne 0 ]]; then
  echo "merge conflict in $INTEGRATION_WT — resolve there (not in the primary checkout):" >&2
  git -C "$INTEGRATION_WT" diff --name-only --diff-filter=U
  exit 2
fi

PUSH_STATUS="local-only"
if [[ "$NO_PUSH" -eq 0 ]] && git -C "$INTEGRATION_WT" rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then
  if git -C "$INTEGRATION_WT" push origin "$BASE" >/dev/null 2>&1; then
    PUSH_STATUS="pushed"
  else
    PUSH_STATUS="push-failed"
  fi
fi

# Remove the per-task feature worktree (never the integration worktree).
if ! git -C "$PRIMARY_ROOT" worktree remove "$WT_PATH" >/dev/null 2>&1; then
  echo "warning: clean worktree remove failed for $WT_PATH; attempting force" >&2
  git -C "$PRIMARY_ROOT" worktree remove --force "$WT_PATH" >/dev/null 2>&1 || \
    echo "warning: $WT_PATH still on disk — remove manually: git worktree remove \"$WT_PATH\"" >&2
fi

# Delete the feature branch only after confirming it is an ancestor of BASE
# (i.e. its commits are safely preserved in the integration branch). `git
# branch -d` checks reachability from the CURRENT HEAD, which here is the
# primary worktree's branch, not BASE — so it would false-refuse on every
# clean merge. We verify against BASE explicitly, then delete; if the ancestry
# check fails we keep the branch rather than risk losing unmerged work.
if [[ "$KEEP_BRANCH" -eq 0 ]]; then
  if git -C "$INTEGRATION_WT" merge-base --is-ancestor "$FEATURE" "$BASE" >/dev/null 2>&1; then
    git -C "$PRIMARY_ROOT" branch -D "$FEATURE" >/dev/null 2>&1 || \
      echo "warning: could not delete merged branch $FEATURE — remove manually" >&2
  else
    echo "warning: kept branch $FEATURE — not an ancestor of $BASE after merge" >&2
  fi
fi

echo "MERGE_STATUS=clean"
echo "PUSH_STATUS=$PUSH_STATUS"
echo "INTEGRATION_WORKTREE=$INTEGRATION_WT"

if [[ "$PUSH_STATUS" == "push-failed" ]]; then
  exit 6
fi
exit 0
