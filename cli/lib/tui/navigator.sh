#!/usr/bin/env bash
# cli/lib/tui/navigator.sh — Folder navigation (project + skill browser)

# Navigate directories to select a target project folder
# Returns the selected directory path
tui_navigate_projects() {
    local start_dir="${1:-$HOME}"

    if has_cmd fzf; then
        local selected
        selected=$(find "$start_dir" -maxdepth 3 -type d -name ".git" 2>/dev/null | \
            sed 's|/.git$||' | sort | \
            fzf --prompt "Select project> " \
                --header "Navigate to a project directory" \
                --preview "ls -la {}" \
                --preview-window "right:40%:wrap" \
            2>/dev/null)
        echo "$selected"
    else
        _fallback_dir_picker "$start_dir"
    fi
}

# Browse skills by category with fzf
tui_browse_by_category() {
    ensure_registry

    # First: pick a category
    local categories
    categories=$(registry_categories)

    local category
    category=$(echo "$categories" | \
        awk '{printf "%s (%s skills)\n", $1, $2}' | \
        fzf --prompt "Category> " \
            --header "Select a skill category" \
            --no-multi \
        2>/dev/null | \
        awk '{print $1}')

    [[ -z "$category" ]] && return

    # Then: pick skills from that category
    local skills
    skills=$(registry_skills_by_category "$category")

    local skill_data=""
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        local desc
        desc=$(registry_skill_field "$name" "description")
        skill_data+="${name}\t${desc}\n"
    done <<< "$skills"

    echo -e "$skill_data" | column -t -s $'\t' | \
        fzf --multi \
            --prompt "Skills (${category})> " \
            --header "TAB to select · ENTER to confirm" \
        2>/dev/null | \
        awk '{print $1}'
}

# Fallback directory picker without fzf
_fallback_dir_picker() {
    local dir="$1"
    echo "$dir"
}
