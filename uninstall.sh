#!/usr/bin/env bash
set -euo pipefail

# Removes the corvus binary from the locations install.sh writes to.
#
# By default, leaves ~/.corvus/ (config and skills installed via
# `corvus install <skill>`) untouched. Pass --purge to also remove it
# after a y/N confirm.

PURGE=0
case "${1:-}" in
  --purge) PURGE=1 ;;
  "") ;;
  *) echo "Usage: $0 [--purge]" >&2; exit 2 ;;
esac

REMOVED=0
FAILED=0

remove_path() {
  local path="$1"
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    return
  fi
  if [ -w "$(dirname "$path")" ]; then
    rm -f "$path"
  elif command -v sudo >/dev/null 2>&1; then
    sudo rm -f "$path"
  else
    echo "✗ Cannot remove $path (no write permission, no sudo available)" >&2
    FAILED=$((FAILED + 1))
    return
  fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    echo "✗ Failed to remove $path (still present after rm)" >&2
    FAILED=$((FAILED + 1))
  else
    echo "✓ Removed $path"
    REMOVED=$((REMOVED + 1))
  fi
}

for path in /usr/local/bin/corvus "$HOME/.local/bin/corvus"; do
  remove_path "$path"
done

if [ "$PURGE" -eq 1 ] && [ -d "$HOME/.corvus" ]; then
  if [ ! -t 0 ]; then
    echo "✗ --purge requires an interactive terminal for confirmation" >&2
    exit 2
  fi
  echo ""
  echo "~/.corvus/ contains:"
  ls -A "$HOME/.corvus" | sed 's/^/  /'
  printf "Remove ~/.corvus/ and all installed skills? [y/N] "
  read -r ans || ans=""
  case "$ans" in
    y|Y|yes|YES)
      rm -rf "$HOME/.corvus"
      if [ -e "$HOME/.corvus" ]; then
        echo "✗ Failed to remove ~/.corvus/" >&2
        FAILED=$((FAILED + 1))
      else
        echo "✓ Removed ~/.corvus/"
        REMOVED=$((REMOVED + 1))
      fi
      ;;
    *)
      echo "Skipped ~/.corvus/"
      ;;
  esac
fi

if [ "$REMOVED" -eq 0 ] && [ "$FAILED" -eq 0 ]; then
  echo "corvus not found in /usr/local/bin or ~/.local/bin — nothing to remove"
fi

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
