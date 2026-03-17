#!/usr/bin/env bash
# cli/lib/core/utils.sh — Colors, logging, platform detection, banner display

# Colors (disable if not a terminal)
if [[ -t 1 ]]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
else
    BOLD='' DIM='' RED='' GREEN='' YELLOW='' CYAN='' WHITE='' NC=''
fi

# Logging helpers
info()    { printf "${WHITE}→${NC} %s\n" "$1"; }
success() { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn()    { printf "${YELLOW}!${NC} %s\n" "$1" >&2; }
error()   { printf "${RED}✗ %s${NC}\n" "$1" >&2; }
die()     { error "$1"; exit 1; }

# Skill name highlighting
skill_name() { printf "${CYAN}%s${NC}" "$1"; }

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Check if a command exists
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# JSON parsing — jq preferred, python3 fallback
json_query() {
    local file="$1" query="$2"
    if has_cmd jq; then
        jq -r "$query" "$file"
    elif has_cmd python3; then
        python3 -c "
import json, sys
data = json.load(open('$file'))
def query(d, path):
    for p in path:
        if isinstance(d, list):
            d = d[int(p)]
        else:
            d = d[p]
    return d
result = query(data, '$query'.strip('.').split('.'))
if isinstance(result, (list, dict)):
    print(json.dumps(result))
else:
    print(result)
" 2>/dev/null
    else
        die "Either jq or python3 is required"
    fi
}

# JSON array length
json_length() {
    local file="$1" query="$2"
    if has_cmd jq; then
        jq -r "$query | length" "$file"
    elif has_cmd python3; then
        python3 -c "
import json
data = json.load(open('$1'))
parts = '$query'.strip('.').split('.')
for p in parts:
    if p: data = data[int(p)] if isinstance(data, list) else data[p]
print(len(data))
"
    fi
}

# Show compact banner from file
show_banner() {
    local banner_file="${RAVENCITO_DIR}/repo/cli/assets/banner.txt"
    if [[ -f "$banner_file" ]]; then
        printf "${CYAN}"
        cat "$banner_file"
        printf "${NC}\n"
    else
        printf "${CYAN}ravencito${NC} — AI Skills Manager\n\n"
    fi
}

# Show full logo
show_logo() {
    local logo_file="${RAVENCITO_DIR}/repo/cli/assets/logo.txt"
    if [[ -f "$logo_file" ]]; then
        printf "${CYAN}"
        cat "$logo_file"
        printf "${NC}\n"
    else
        show_banner
    fi
}

# Capitalize first letter (bash 3.2 compatible)
capitalize() {
    local str="$1"
    local first
    first=$(echo "${str:0:1}" | tr '[:lower:]' '[:upper:]')
    echo "${first}${str:1}"
}

# Prompt user with default
ask() {
    local prompt="$1" default="${2:-}"
    if [[ -n "$default" ]]; then
        printf "${WHITE}%s${NC} [%s]: " "$prompt" "$default"
    else
        printf "${WHITE}%s${NC}: " "$prompt"
    fi
    read -r REPLY
    REPLY="${REPLY:-$default}"
}

# Yes/No prompt (default Y)
confirm() {
    local prompt="${1:-Continue?}"
    printf "${WHITE}%s${NC} [Y/n] " "$prompt"
    read -r -n 1 REPLY
    echo
    [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]
}
