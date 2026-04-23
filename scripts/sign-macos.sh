#!/usr/bin/env bash
# Usage: scripts/sign-macos.sh <path-to-binary>
#
# Strips Bun's malformed LC_CODE_SIGNATURE stub and applies an ad-hoc signature
# so Apple Silicon will exec the binary without a Developer ID cert.
#
# NOTE: install.sh inlines an equivalent block (it runs via curl|bash with no
# repo checkout). Keep the two in sync.
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-binary>" >&2
  exit 2
fi

target="$1"
if [ ! -f "$target" ]; then
  echo "sign-macos.sh: no such file: $target" >&2
  exit 1
fi

xattr -c "$target" 2>/dev/null || true
codesign --remove-signature "$target" 2>/dev/null || true
codesign --force --sign - "$target"
