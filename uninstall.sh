#!/usr/bin/env bash
set -euo pipefail

# Removes the corvus binary from the locations install.sh writes to.
# Does NOT touch skills installed via `corvus install <skill>` — manage those
# with `corvus uninstall <skill>` before running this if you want them gone.

REMOVED=0
for path in /usr/local/bin/corvus "$HOME/.local/bin/corvus"; do
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ -w "$(dirname "$path")" ]; then
      rm -f "$path"
      echo "✓ Removed $path"
      REMOVED=$((REMOVED + 1))
    elif command -v sudo >/dev/null 2>&1; then
      sudo rm -f "$path"
      echo "✓ Removed $path"
      REMOVED=$((REMOVED + 1))
    else
      echo "✗ Cannot remove $path (no write permission, no sudo available)" >&2
    fi
  fi
done

if [ "$REMOVED" -eq 0 ]; then
  echo "corvus not found in /usr/local/bin or ~/.local/bin — nothing to remove"
fi
