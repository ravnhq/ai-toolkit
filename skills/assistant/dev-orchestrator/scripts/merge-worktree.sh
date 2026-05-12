#!/usr/bin/env bash
# Auto-merge a worktree-orchestrator feature branch back into its base.
#
# Usage:
#   merge-worktree.sh <worktree_path> <feature_branch> <base_branch> [--keep-branch] [--summary "<text>"]
#
# Exit codes:
#   0  merged cleanly (worktree + branch cleaned up unless --keep-branch)
#   1  invalid args
#   2  merge conflicts (left in progress; conflicted files printed to stdout)
#   3  primary worktree dirty (refuse to touch user state)
#   4  base checkout / fast-forward failed
#   5  no commits on the feature branch
#   6  push failed (merge already landed locally; surfaced for visibility)

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "usage: merge-worktree.sh <worktree_path> <feature_branch> <base_branch> [--keep-branch] [--summary <text>]" >&2
  exit 1
fi

WT_PATH="$1"; shift
FEATURE="$1"; shift
BASE="$1"; shift

KEEP_BRANCH=0
SUMMARY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-branch) KEEP_BRANCH=1; shift ;;
    --summary)     SUMMARY="${2:-}"; shift 2 ;;
    *)             echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

PRIMARY_ROOT="$(git -C "$WT_PATH" worktree list --porcelain | awk '/^worktree / { print $2; exit }')"
if [[ -z "$PRIMARY_ROOT" ]]; then
  echo "could not resolve primary worktree from $WT_PATH" >&2
  exit 1
fi

if [[ -n "$(git -C "$PRIMARY_ROOT" status --porcelain)" ]]; then
  echo "primary worktree at $PRIMARY_ROOT is dirty; refusing to merge" >&2
  exit 3
fi

if ! git -C "$WT_PATH" rev-list --count "$BASE..$FEATURE" >/dev/null 2>&1; then
  echo "could not compare $BASE..$FEATURE" >&2
  exit 5
fi
NEW_COMMITS="$(git -C "$WT_PATH" rev-list --count "$BASE..$FEATURE")"
if [[ "$NEW_COMMITS" -eq 0 ]]; then
  echo "no new commits on $FEATURE relative to $BASE" >&2
  exit 5
fi

if ! git -C "$PRIMARY_ROOT" checkout "$BASE" >/dev/null 2>&1; then
  echo "checkout of $BASE failed" >&2
  exit 4
fi

git -C "$PRIMARY_ROOT" fetch origin --quiet 2>/dev/null || true
if git -C "$PRIMARY_ROOT" rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then
  if ! git -C "$PRIMARY_ROOT" pull --ff-only origin "$BASE" >/dev/null 2>&1; then
    echo "fast-forward pull of $BASE failed; resolve manually before retrying" >&2
    exit 4
  fi
fi

MSG="Merge agent work from $FEATURE"
if [[ -n "$SUMMARY" ]]; then
  MSG="$MSG: $SUMMARY"
fi

set +e
git -C "$PRIMARY_ROOT" merge --no-ff "$FEATURE" -m "$MSG" >/dev/null 2>&1
MERGE_EXIT=$?
set -e

if [[ "$MERGE_EXIT" -ne 0 ]]; then
  git -C "$PRIMARY_ROOT" diff --name-only --diff-filter=U
  exit 2
fi

PUSH_STATUS="local-only"
if git -C "$PRIMARY_ROOT" rev-parse --verify "origin/$BASE" >/dev/null 2>&1; then
  if git -C "$PRIMARY_ROOT" push origin "$BASE" >/dev/null 2>&1; then
    PUSH_STATUS="pushed"
  else
    PUSH_STATUS="push-failed"
  fi
fi

git -C "$PRIMARY_ROOT" worktree remove "$WT_PATH" >/dev/null 2>&1 || \
  git -C "$PRIMARY_ROOT" worktree remove --force "$WT_PATH" >/dev/null 2>&1 || true

if [[ "$KEEP_BRANCH" -eq 0 ]]; then
  git -C "$PRIMARY_ROOT" branch -d "$FEATURE" >/dev/null 2>&1 || \
    git -C "$PRIMARY_ROOT" branch -D "$FEATURE" >/dev/null 2>&1 || true
fi

echo "MERGE_STATUS=clean"
echo "PUSH_STATUS=$PUSH_STATUS"

if [[ "$PUSH_STATUS" == "push-failed" ]]; then
  exit 6
fi
exit 0
