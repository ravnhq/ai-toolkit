---
title: Distribute as Single Binary
impact: LOW
tags: distribution, installation, packaging
---

## Distribute as Single Binary

When the language supports it (Go, Rust, Zig), compile to a single self-contained binary. This simplifies installation, updates, and uninstallation dramatically.

**Incorrect (scattered files, complex installation):**

```bash
# Multiple files scattered across system
mycli install
# Installing to:
#   /usr/local/bin/mycli
#   /usr/local/lib/mycli/core.so
#   /usr/local/lib/mycli/plugins/*.so
#   /usr/local/share/mycli/templates/
#   /usr/local/share/doc/mycli/
#   /etc/mycli/config.yaml
#   ~/.mycli/cache/
# Installation complete (20 files across 6 directories)

# Uninstall is manual and error-prone
# User asks: Which files do I remove?
# Easy to leave behind debris in system
# Package manager helps but adds complexity

# Partial installs cause "missing shared library" errors
# Dependency hell: requires libfoo.so.3.2.1
```

**Correct (single binary, clean installation):**

```bash
# Single binary - download and run
curl -L https://github.com/user/mycli/releases/latest/download/mycli-linux-amd64 -o mycli
chmod +x mycli
sudo mv mycli /usr/local/bin/
# Done - one file, works immediately

# Or even simpler - run directly
curl -L https://github.com/user/mycli/releases/latest/download/mycli-linux-amd64 -o /tmp/mycli
chmod +x /tmp/mycli
/tmp/mycli --help  # Works without "installing"

# Uninstall is trivial
sudo rm /usr/local/bin/mycli
# Optional: clean up user config
rm -rf ~/.config/mycli

# Update is atomic - just replace the file
curl -L https://github.com/user/mycli/releases/latest/download/mycli-linux-amd64 -o mycli-new
chmod +x mycli-new
sudo mv mycli-new /usr/local/bin/mycli
# No "restart required" or stale files
```

**Distribution by language:**

**Go (best for single binary):**
```bash
# Produces truly standalone binary
go build -ldflags="-s -w" -o mycli main.go
# No runtime dependencies
# Works on same OS/arch without any installed packages
```

**Rust (best for single binary):**
```bash
# Static linking by default
cargo build --release
# Binary in target/release/mycli
# No runtime dependencies (unless you explicitly add them)
```

**Python (requires runtime, but can bundle):**
```bash
# Option 1: pipx (isolated environment)
pipx install mycli  # Best for Python CLIs

# Option 2: PyInstaller (single file, includes Python runtime)
pyinstaller --onefile mycli.py
# Creates 50MB+ binary with embedded Python

# Option 3: pip global install (avoid this)
pip install mycli  # Pollutes system Python
```

**Node.js (requires runtime):**
```bash
# Option 1: npx (no install, slower startup)
npx mycli command

# Option 2: npm global install
npm install -g mycli  # Installs to node_modules

# Option 3: pkg (bundle Node.js runtime)
pkg mycli.js --output mycli
# Creates ~50MB binary with embedded Node.js
```

**Single binary benefits:**

- **No dependency hell**: Everything bundled, no version conflicts
- **Trivial installation**: Download, chmod, mv - works everywhere
- **Atomic updates**: Replace file = updated, no stale files
- **Easy uninstall**: Remove one file, optionally clean config
- **Portable**: Copy binary between machines with same OS/arch
- **No runtime required**: User doesn't need Go/Rust/etc installed
- **Reduced support burden**: No "I have wrong version of libX" issues

**When single binary isn't possible:**

For Python/Node.js/Ruby where runtime is required:
1. Use language-specific package managers (pipx, npm, gem)
2. Document required runtime version clearly
3. Consider bundling runtime (PyInstaller, pkg) for simpler UX
4. Provide Docker image as alternative
5. Still keep config/data files minimal

**Why it matters:**

Single binaries eliminate dependency hell, version conflicts, and incomplete installations. Users can download and run immediately without setting up runtimes or package managers. Uninstallation is one command. Updates are atomic. This reduces support burden significantly.

Reference: [clig.dev - Distribution](https://clig.dev/#distribution)
