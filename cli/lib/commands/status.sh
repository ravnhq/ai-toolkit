#!/usr/bin/env bash
# cli/lib/commands/status.sh — Show installed vs latest (global + project)

cmd_status() {
    ensure_registry

    printf "\n${WHITE}Skill Status${NC}\n\n"

    # Global skills
    local global_skills
    global_skills=$(get_global_skills)

    printf "${WHITE}Global Skills${NC}"
    if [[ -z "$global_skills" ]]; then
        printf " ${DIM}(none)${NC}\n"
        info "Run 'ravencito install --global <skill>' to add global defaults."
    else
        echo ""
        _show_skill_status "$global_skills"
    fi
    echo ""

    # Project skills
    local project_root
    project_root=$(find_project_root)
    local rc_file="${project_root}/${RAVENCITORC}"

    printf "${WHITE}Project Skills${NC} ${DIM}(%s)${NC}" "$project_root"
    if [[ ! -f "$rc_file" ]]; then
        printf " ${DIM}(no .ravencitorc)${NC}\n"
        info "Run 'ravencito install <skill>' in a project to get started."
    else
        echo ""
        local project_skills
        project_skills=$(get_project_skills)
        local install_dir
        install_dir=$(project_config_get "install_dir" "")

        if [[ -n "$install_dir" ]]; then
            printf "  ${DIM}Install dir: %s${NC}\n" "$install_dir"
        fi

        if [[ -z "$project_skills" ]]; then
            info "No skills installed in this project."
        else
            _show_skill_status "$project_skills"
        fi
    fi
    echo ""
}

# Show status for a comma-separated skill list
_show_skill_status() {
    local skill_list="$1"

    printf "  ${DIM}%-30s %-10s %-10s %s${NC}\n" "SKILL" "INSTALLED" "LATEST" "STATUS"

    local IFS=','
    for entry in $skill_list; do
        local name="${entry%%:*}"
        local installed_ver="${entry#*:}"
        local latest_ver
        latest_ver=$(registry_skill_version "$name" 2>/dev/null || echo "?")

        local status_icon status_color
        if [[ "$latest_ver" == "?" ]]; then
            status_icon="?"
            status_color="$YELLOW"
        elif [[ "$installed_ver" == "$latest_ver" ]]; then
            status_icon="✓"
            status_color="$GREEN"
        else
            status_icon="↑"
            status_color="$YELLOW"
        fi

        printf "  ${CYAN}%-30s${NC} v%-9s v%-9s ${status_color}%s${NC}\n" \
            "$name" "$installed_ver" "$latest_ver" "$status_icon"
    done
}
