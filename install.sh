#!/usr/bin/env bash
set -euo pipefail

REPO="ravnhq/ai-toolkit"
TAG="cli-latest"
INSTALL_DIR="/usr/local/bin"

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported arch: $ARCH"; exit 1 ;;
esac

BINARY="corvus-${OS}-${ARCH}"
URL="https://github.com/${REPO}/releases/download/${TAG}/${BINARY}"

echo "Downloading ${BINARY}..."
TMP=$(mktemp)
curl -fsSL "$URL" -o "$TMP"
chmod +x "$TMP"

if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP" "${INSTALL_DIR}/corvus"
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  sudo mv "$TMP" "${INSTALL_DIR}/corvus"
else
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  mv "$TMP" "${INSTALL_DIR}/corvus"
  echo "  Note: add ~/.local/bin to your PATH if not already present"
fi

echo "✓ Installed to ${INSTALL_DIR}/corvus"
echo "  Run: corvus --version"
