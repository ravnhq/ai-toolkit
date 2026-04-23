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

# On Apple Silicon the kernel refuses to exec unsigned arm64 Mach-Os
# (the user sees a "can't verify developer / Apple ID" dialog). Bun's
# --compile output ships with a malformed LC_CODE_SIGNATURE stub, so a
# plain `codesign --sign -` fails with "invalid or unsupported format".
# Strip the stub first, then ad-hoc sign.
if [ "$(uname -s)" = "Darwin" ]; then
  xattr -c "$TMP" 2>/dev/null || true
  codesign --remove-signature "$TMP" 2>/dev/null || true
  if ! codesign --force --sign - "$TMP" 2>/dev/null; then
    echo "Warning: ad-hoc codesign failed. If 'corvus' is killed on launch, run:" >&2
    echo "  codesign --remove-signature \"\$(command -v corvus)\" && codesign --force --sign - \"\$(command -v corvus)\"" >&2
  fi
fi

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
