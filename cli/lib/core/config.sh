#!/usr/bin/env bash
# cli/lib/core/config.sh — Config read/write (global + project)

RAVENCITO_DIR="${HOME}/.ravencito"
RAVENCITO_CONFIG="${RAVENCITO_DIR}/config"
RAVENCITORC=".ravencitorc"

# Ensure global config directory exists
ensure_config_dir() {
    mkdir -p "$RAVENCITO_DIR"
}

# Read a value from an ini-style config file
# Usage: config_get <file> <key> [default]
config_get() {
    local file="$1" key="$2" default="${3:-}"
    if [[ -f "$file" ]]; then
        local value
        value=$(grep "^${key}=" "$file" 2>/dev/null | head -1 | cut -d'=' -f2-)
        echo "${value:-$default}"
    else
        echo "$default"
    fi
}

# Write a value to an ini-style config file
# Usage: config_set <file> <key> <value>
config_set() {
    local file="$1" key="$2" value="$3"
    local dir
    dir=$(dirname "$file")
    mkdir -p "$dir"

    if [[ -f "$file" ]] && grep -q "^${key}=" "$file" 2>/dev/null; then
        # Update existing key (portable sed)
        local tmp="${file}.tmp"
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" == "${key}="* ]]; then
                echo "${key}=${value}"
            else
                echo "$line"
            fi
        done < "$file" > "$tmp"
        mv "$tmp" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

# Get global config value
global_config_get() { config_get "$RAVENCITO_CONFIG" "$1" "${2:-}"; }
global_config_set() { config_set "$RAVENCITO_CONFIG" "$1" "$2"; }

# Find project root (walks up looking for .ravencitorc or .git)
find_project_root() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "${dir}/${RAVENCITORC}" ]] || [[ -d "${dir}/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    echo "$PWD"
}

# Get project config value
project_config_get() {
    local root
    root=$(find_project_root)
    config_get "${root}/${RAVENCITORC}" "$1" "${2:-}"
}

# Set project config value
project_config_set() {
    local root
    root=$(find_project_root)
    config_set "${root}/${RAVENCITORC}" "$1" "$2"
}

# Parse a skill list string into an array: "skill1:3,skill2:2" → skill entries
# Usage: parse_skill_list "skill1:3,skill2:2"
# Outputs one "name:version" per line
parse_skill_list() {
    local list="$1"
    [[ -z "$list" ]] && return
    echo "$list" | tr ',' '\n'
}

# Get skill version from a skill list
# Usage: skill_version_from_list "skill1:3,skill2:2" "skill1" → 3
skill_version_from_list() {
    local list="$1" name="$2"
    local entry
    entry=$(parse_skill_list "$list" | grep "^${name}:" | head -1)
    if [[ -n "$entry" ]]; then
        echo "${entry#*:}"
    fi
}

# Add or update a skill in a comma-separated list
# Usage: skill_list_upsert "skill1:3,skill2:2" "skill2" "5" → "skill1:3,skill2:5"
skill_list_upsert() {
    local list="$1" name="$2" version="$3"
    local result="" found=0
    local IFS=','
    for entry in $list; do
        local entry_name="${entry%%:*}"
        if [[ "$entry_name" == "$name" ]]; then
            result="${result:+${result},}${name}:${version}"
            found=1
        else
            result="${result:+${result},}${entry}"
        fi
    done
    if [[ "$found" -eq 0 ]]; then
        result="${result:+${result},}${name}:${version}"
    fi
    echo "$result"
}

# Remove a skill from a comma-separated list
skill_list_remove() {
    local list="$1" name="$2"
    local result=""
    local IFS=','
    for entry in $list; do
        local entry_name="${entry%%:*}"
        if [[ "$entry_name" != "$name" ]]; then
            result="${result:+${result},}${entry}"
        fi
    done
    echo "$result"
}

# Get the install directory for the current project
get_install_dir() {
    local dir
    dir=$(project_config_get "install_dir" "")
    if [[ -z "$dir" ]]; then
        return 1
    fi
    echo "$dir"
}

# Prompt user to pick install directory (first time)
# All prompts go to stderr so stdout is clean for the return value
prompt_install_dir() {
    echo "" >&2
    printf "${WHITE}→${NC} %s\n" "Where should skills be installed?" >&2
    echo "  1) .cursor/rules    (works with Cursor + Claude Code)" >&2
    echo "  2) .claude/rules    (Claude Code only)" >&2
    echo "  3) Custom path" >&2
    echo "" >&2
    printf "${WHITE}Choose [1-3]${NC}: " >&2
    read -r choice
    case "$choice" in
        1) echo ".cursor/rules" ;;
        2) echo ".claude/rules" ;;
        3)
            printf "${WHITE}Enter path${NC}: " >&2
            read -r custom_path
            echo "$custom_path"
            ;;
        *) echo ".cursor/rules" ;;
    esac
}

# Ensure install dir is configured for current project
ensure_install_dir() {
    local dir
    dir=$(get_install_dir 2>/dev/null) || true
    if [[ -z "$dir" ]]; then
        dir=$(prompt_install_dir)
        project_config_set "install_dir" "$dir"
    fi
    echo "$dir"
}

# Get list of global skills
get_global_skills() {
    global_config_get "global_skills" ""
}

# Get list of project skills
get_project_skills() {
    project_config_get "skills" ""
}
