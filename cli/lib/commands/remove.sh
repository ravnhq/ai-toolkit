#!/usr/bin/env bash
# cli/lib/commands/remove.sh — Uninstall a skill

cmd_remove() {
    if [[ $# -eq 0 ]]; then
        die "Usage: ravencito remove <skill-name> [--global]"
    fi

    local global_mode=0
    local skills=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --global|-g) global_mode=1; shift ;;
            -*) die "Unknown option: $1" ;;
            *) skills+=("$1"); shift ;;
        esac
    done

    if [[ ${#skills[@]} -eq 0 ]]; then
        die "No skill name provided."
    fi

    for skill in "${skills[@]}"; do
        if [[ "$global_mode" -eq 1 ]]; then
            _remove_global "$skill"
        else
            _remove_project "$skill"
        fi
    done
}

_remove_global() {
    local name="$1"
    local current_list
    current_list=$(get_global_skills)

    if ! echo "$current_list" | tr ',' '\n' | grep -q "^${name}:"; then
        warn "$(skill_name "$name") is not in global skills."
        return
    fi

    local new_list
    new_list=$(skill_list_remove "$current_list" "$name")
    global_config_set "global_skills" "$new_list"
    success "Removed $(skill_name "$name") from global skills."
}

_remove_project() {
    local name="$1"
    local project_root
    project_root=$(find_project_root)

    local current_list
    current_list=$(get_project_skills)

    if ! echo "$current_list" | tr ',' '\n' | grep -q "^${name}:"; then
        warn "$(skill_name "$name") is not installed in this project."
        return
    fi

    # Remove files
    local install_dir
    install_dir=$(project_config_get "install_dir" "")
    if [[ -n "$install_dir" ]]; then
        local skill_dir="${project_root}/${install_dir}/${name}"
        if [[ -d "$skill_dir" ]]; then
            rm -rf "$skill_dir"
        fi
    fi

    # Update config
    local new_list
    new_list=$(skill_list_remove "$current_list" "$name")
    project_config_set "skills" "$new_list"
    success "Removed $(skill_name "$name") from project."
}
