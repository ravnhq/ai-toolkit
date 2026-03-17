#!/usr/bin/env bash
# cli/lib/commands/update.sh — Update cache + installed skills

cmd_update() {
    local repo_dir="${RAVENCITO_DIR}/repo"

    printf "\n${WHITE}Updating ravencito${NC}\n\n"

    # Update repo cache
    if [[ -d "${repo_dir}/.git" ]]; then
        info "Pulling latest changes..."
        if git -C "$repo_dir" pull --rebase origin main --quiet 2>/dev/null; then
            success "Repository updated"
        else
            warn "Could not update repository (offline?)"
        fi
    else
        die "Repository not found. Run the installer again."
    fi

    touch_last_update

    # Update project skills if in a project
    local project_root
    project_root=$(find_project_root)
    local rc_file="${project_root}/${RAVENCITORC}"

    if [[ -f "$rc_file" ]]; then
        echo ""
        info "Updating project skills..."

        local install_dir project_skills
        install_dir=$(project_config_get "install_dir" "")
        project_skills=$(get_project_skills)

        if [[ -n "$project_skills" && -n "$install_dir" ]]; then
            local target_dir="${project_root}/${install_dir}"
            local updated=0

            local IFS=','
            for entry in $project_skills; do
                local name="${entry%%:*}"
                local installed_ver="${entry#*:}"
                local latest_ver
                latest_ver=$(registry_skill_version "$name" 2>/dev/null || echo "")

                if [[ -z "$latest_ver" ]]; then
                    warn "$(skill_name "$name"): not found in registry"
                    continue
                fi

                if [[ "$installed_ver" != "$latest_ver" ]]; then
                    local source_rel source_dir skill_target
                    source_rel=$(registry_skill_source "$name")
                    source_dir="${RAVENCITO_DIR}/repo/${source_rel#./}"
                    skill_target="${target_dir}/${name}"

                    if [[ -d "$source_dir" ]]; then
                        rm -rf "$skill_target"
                        mkdir -p "$skill_target"

                        [[ -f "${source_dir}/SKILL.md" ]] && cp "${source_dir}/SKILL.md" "$skill_target/"
                        [[ -d "${source_dir}/rules" ]] && cp -r "${source_dir}/rules" "$skill_target/"
                        [[ -d "${source_dir}/references" ]] && cp -r "${source_dir}/references" "$skill_target/"
                        [[ -d "${source_dir}/scripts" ]] && cp -r "${source_dir}/scripts" "$skill_target/"
                        [[ -d "${source_dir}/assets" ]] && cp -r "${source_dir}/assets" "$skill_target/"

                        # Update version in config
                        local current_list
                        current_list=$(get_project_skills)
                        current_list=$(skill_list_upsert "$current_list" "$name" "$latest_ver")
                        project_config_set "skills" "$current_list"

                        success "$(skill_name "$name") v${installed_ver} → v${latest_ver}"
                        updated=$((updated + 1))
                    fi
                fi
            done

            if [[ "$updated" -eq 0 ]]; then
                success "All project skills are up to date!"
            else
                echo ""
                success "${updated} skill(s) updated."
            fi
        fi
    fi

    # Update global skill versions in config
    local global_skills
    global_skills=$(get_global_skills)
    if [[ -n "$global_skills" ]]; then
        echo ""
        info "Checking global skills..."
        local new_list="" g_updated=0
        local IFS=','
        for entry in $global_skills; do
            local name="${entry%%:*}"
            local installed_ver="${entry#*:}"
            local latest_ver
            latest_ver=$(registry_skill_version "$name" 2>/dev/null || echo "$installed_ver")
            new_list="${new_list:+${new_list},}${name}:${latest_ver}"
            if [[ "$installed_ver" != "$latest_ver" ]]; then
                success "$(skill_name "$name") v${installed_ver} → v${latest_ver}"
                g_updated=$((g_updated + 1))
            fi
        done
        global_config_set "global_skills" "$new_list"
        if [[ "$g_updated" -eq 0 ]]; then
            success "All global skills are up to date!"
        fi
    fi

    echo ""
}
