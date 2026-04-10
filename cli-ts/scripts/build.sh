#!/usr/bin/env bash
# Build corvus CLI binaries using Bun
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="${PROJECT_DIR}/dist-bin"

mkdir -p "$DIST_DIR"

echo "Building corvus binaries..."

# Build for each platform
TARGETS=(
  "bun-darwin-arm64"
  "bun-darwin-x64"
  "bun-linux-x64"
  "bun-linux-arm64"
)

for target in "${TARGETS[@]}"; do
  platform="${target#bun-}"
  outfile="${DIST_DIR}/corvus-${platform}"
  echo "  Building ${platform}..."
  bun build "${PROJECT_DIR}/src/index.ts" \
    --compile \
    --target="$target" \
    --outfile="$outfile" 2>/dev/null
  echo "  ✓ ${outfile}"
done

echo ""
echo "✓ All binaries built in ${DIST_DIR}/"
ls -lh "$DIST_DIR"/corvus-*
