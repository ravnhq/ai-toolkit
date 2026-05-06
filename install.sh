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

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if command -v corvus >/dev/null 2>&1; then
  EXISTING=$(corvus --version 2>/dev/null | head -n1 || echo "unknown")
  echo "Replacing existing corvus (${EXISTING})..."
fi

echo "Downloading ${BINARY}..."
curl -fL --progress-bar "$URL" -o "$TMP"
chmod +x "$TMP"

# On Apple Silicon the kernel refuses to exec unsigned arm64 Mach-Os
# (the user sees a "can't verify developer / Apple ID" dialog). Bun's
# --compile output ships with a malformed LC_CODE_SIGNATURE stub, so a
# plain `codesign --sign -` fails with "invalid or unsupported format".
# Strip the stub first, then ad-hoc sign. Keep in sync with
# scripts/sign-macos.sh (the build-side copy).
if [ "$(uname -s)" = "Darwin" ]; then
  xattr -c "$TMP" 2>/dev/null || true
  codesign --remove-signature "$TMP" 2>/dev/null || true
  if ! codesign --force --sign - "$TMP" 2>/dev/null; then
    echo "Error: ad-hoc codesign failed — refusing to install an unsigned binary." >&2
    echo "       macOS would kill it on launch. Ensure command-line tools are installed:" >&2
    echo "         xcode-select --install" >&2
    exit 1
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
  case ":${PATH:-}:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
      shell_name=$(basename "${SHELL:-/bin/sh}")
      case "$shell_name" in
        zsh)  path_cmd="echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc" ;;
        bash) path_cmd="echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc" ;;
        fish) path_cmd="fish_add_path \$HOME/.local/bin" ;;
        *)    path_cmd="export PATH=\"\$HOME/.local/bin:\$PATH\"  # add to your shell rc" ;;
      esac
      echo "  Note: ~/.local/bin is not on your PATH. Add it with:"
      echo "    $path_cmd"
      ;;
  esac
fi

echo "✓ Installed to ${INSTALL_DIR}/corvus"
echo "  Run: corvus --version"
