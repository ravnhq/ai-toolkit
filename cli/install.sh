#!/usr/bin/env bash
# ravencito bootstrap installer
# Usage: curl -fsSL https://raw.githubusercontent.com/ravnhq/ai-toolkit/main/cli/install.sh | bash

set -euo pipefail

RAVENCITO_DIR="${HOME}/.ravencito"
REPO_URL="https://github.com/ravnhq/ai-toolkit.git"
REPO_DIR="${RAVENCITO_DIR}/repo"

# Colors
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

info()    { printf "${WHITE}→${NC} %s\n" "$1"; }
success() { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()    { printf "${YELLOW}!${NC} %s\n" "$1"; }
error()   { printf "${RED}✗ %s${NC}\n" "$1" >&2; exit 1; }

# Show banner
show_install_banner() {
    printf "${CYAN}"
    cat << 'BANNER'
          ▄          ▄▄▄▄▄▄▄
          ██      ▄███████████▄
        ▀▀██▀    ████████████████▄▄▄
          █▀    █████████████████████▄
               ███████████████████▀▀▀▀
              ▄██████████████████▄
              █████████████████████▄       ravencito
              ██████████████████▀▀▀        AI Skills Manager
            ▄████████████████████
          ▄███████████████████████
        ▄██████████████████████████
  ▄▄▄██████████████████████████████
BANNER
    printf "${NC}\n"
}

# Check prerequisites
check_prereqs() {
    info "Checking prerequisites..."

    if ! command -v git >/dev/null 2>&1; then
        error "git is required. Install it first: https://git-scm.com"
    fi
    success "git found"

    if ! command -v bash >/dev/null 2>&1; then
        error "bash is required"
    fi

    local bash_version
    bash_version="${BASH_VERSINFO[0]}"
    if [[ "$bash_version" -lt 3 ]]; then
        error "bash 3.2+ required (found ${BASH_VERSION})"
    fi
    success "bash ${BASH_VERSION}"

    if command -v jq >/dev/null 2>&1; then
        success "jq found (preferred JSON parser)"
    elif command -v python3 >/dev/null 2>&1; then
        success "python3 found (JSON fallback)"
    else
        error "Either jq or python3 is required for JSON parsing"
    fi

    if command -v fzf >/dev/null 2>&1; then
        success "fzf found (interactive TUI enabled)"
    else
        warn "fzf not found — interactive mode will use basic menus"
        info "Install fzf for the best experience: https://github.com/junegunn/fzf"
    fi
}

# Clone or update repo
setup_repo() {
    mkdir -p "$RAVENCITO_DIR"

    if [[ -d "$REPO_DIR" ]]; then
        info "Updating existing installation..."
        git -C "$REPO_DIR" pull --rebase origin main --quiet 2>/dev/null || true
        success "Repository updated"
    else
        info "Cloning ai-toolkit..."
        git clone --depth 1 "$REPO_URL" "$REPO_DIR" --quiet
        success "Repository cloned to ${REPO_DIR}"
    fi

    # Record update timestamp
    date +%s > "${RAVENCITO_DIR}/.last_update"
}

# Create ravencito symlink/wrapper
setup_command() {
    local bin_dir="${HOME}/.local/bin"
    mkdir -p "$bin_dir"

    local wrapper="${bin_dir}/ravencito"
    cat > "$wrapper" << EOF
#!/usr/bin/env bash
exec "${REPO_DIR}/cli/ravencito.sh" "\$@"
EOF
    chmod +x "$wrapper"
    chmod +x "${REPO_DIR}/cli/ravencito.sh"
    success "Created ravencito command at ${wrapper}"

    echo "$bin_dir"
}

# Add to PATH if needed
setup_path() {
    local bin_dir="$1"

    # Check if already in PATH
    if echo "$PATH" | tr ':' '\n' | grep -q "^${bin_dir}$"; then
        return
    fi

    info "Adding ${bin_dir} to PATH..."

    local shell_rc=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        shell_rc="${HOME}/.zshrc"
    elif [[ -f "${HOME}/.bashrc" ]]; then
        shell_rc="${HOME}/.bashrc"
    elif [[ -f "${HOME}/.bash_profile" ]]; then
        shell_rc="${HOME}/.bash_profile"
    fi

    if [[ -n "$shell_rc" ]]; then
        local path_line="export PATH=\"${bin_dir}:\$PATH\""
        if ! grep -q "ravencito" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# ravencito — AI Skills Manager" >> "$shell_rc"
            echo "$path_line" >> "$shell_rc"
            success "Added to ${shell_rc}"
        fi
    fi
}

# Install shell completions
setup_completions() {
    local completions_dir="${REPO_DIR}/cli/completions"

    # Zsh completions
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
        local zsh_comp_dir="${HOME}/.zsh/completions"
        mkdir -p "$zsh_comp_dir"
        if [[ -f "${completions_dir}/_ravencito.zsh" ]]; then
            ln -sf "${completions_dir}/_ravencito.zsh" "${zsh_comp_dir}/_ravencito"
            success "Zsh completions installed"
        fi
    fi

    # Bash completions
    if [[ -f "${completions_dir}/ravencito.bash" ]]; then
        local bash_comp_dir="${HOME}/.local/share/bash-completion/completions"
        mkdir -p "$bash_comp_dir"
        ln -sf "${completions_dir}/ravencito.bash" "${bash_comp_dir}/ravencito"
        success "Bash completions installed"
    fi
}

# Initialize default config
setup_config() {
    local config_file="${RAVENCITO_DIR}/config"
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << 'EOF'
update_check=7
auto_deps=true
global_skills=
EOF
        success "Created default config"
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

main() {
    show_install_banner
    echo ""
    info "Installing ravencito..."
    echo ""

    check_prereqs
    echo ""

    setup_repo
    setup_config
    local bin_dir
    bin_dir=$(setup_command)
    setup_path "$bin_dir"
    setup_completions
    echo ""

    printf "${GREEN}✓ ravencito installed successfully!${NC}\n\n"

    printf "${WHITE}Quick start:${NC}\n"
    printf "  ravencito                         Interactive skill picker (TUI)\n"
    printf "  ravencito list                    Browse available skills\n"
    printf "  ravencito install tech-react      Install a specific skill\n"
    echo ""

    # Offer to set up global defaults
    printf "${WHITE}Want to set up global defaults now?${NC} [y/N] "
    read -r -n 1 REPLY
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        export PATH="${bin_dir}:$PATH"
        exec ravencito install --global
    else
        info "Run 'ravencito install --global' anytime to set up defaults."
    fi

    echo ""
    warn "Restart your shell or run: source ~/.zshrc"
}

main
