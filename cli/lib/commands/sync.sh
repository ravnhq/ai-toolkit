#!/usr/bin/env bash
# cli/lib/commands/sync.sh — Team sync from shared .ravencitorc

cmd_sync() {
    ensure_registry

    local project_root
    project_root=$(find_project_root)
    local rc_file="${project_root}/${RAVENCITORC}"

    if [[ ! -f "$rc_file" ]]; then
        die "No .ravencitorc found in project. Nothing to sync."
    fi

    printf "\n${WHITE}Syncing skills from .ravencitorc${NC}\n\n"

    local install_dir
    install_dir=$(config_get "$rc_file" "install_dir" "")

    if [[ -z "$install_dir" ]]; then
        die ".ravencitorc is missing install_dir. Run 'ravencito install' first."
    fi

    local skill_list
    skill_list=$(config_get "$rc_file" "skills" "")

    if [[ -z "$skill_list" ]]; then
        info "No skills listed in .ravencitorc."
        return
    fi

    local target_dir="${project_root}/${install_dir}"
    mkdir -p "$target_dir"

    local installed=0 skipped=0

    local IFS=','
    for entry in $skill_list; do
        local name="${entry%%:*}"
        local version="${entry#*:}"
        local skill_target="${target_dir}/${name}"

        # Check if already installed at correct version
        if [[ -d "$skill_target" ]]; then
            skipped=$((skipped + 1))
            printf "  ${DIM}%s v%s (already installed)${NC}\n" "$name" "$version"
            continue
        fi

        local source_rel source_dir
        source_rel=$(registry_skill_source "$name" 2>/dev/null || echo "")

        if [[ -z "$source_rel" ]]; then
            warn "$(skill_name "$name"): not found in registry, skipping"
            continue
        fi

        source_dir="${RAVENCITO_DIR}/repo/${source_rel#./}"

        if [[ ! -d "$source_dir" ]]; then
            warn "$(skill_name "$name"): source missing, skipping"
            continue
        fi

        mkdir -p "$skill_target"
        [[ -f "${source_dir}/SKILL.md" ]] && cp "${source_dir}/SKILL.md" "$skill_target/"
        [[ -d "${source_dir}/rules" ]] && cp -r "${source_dir}/rules" "$skill_target/"
        [[ -d "${source_dir}/references" ]] && cp -r "${source_dir}/references" "$skill_target/"
        [[ -d "${source_dir}/scripts" ]] && cp -r "${source_dir}/scripts" "$skill_target/"
        [[ -d "${source_dir}/assets" ]] && cp -r "${source_dir}/assets" "$skill_target/"

        success "$(skill_name "$name") v${version} installed"
        installed=$((installed + 1))
    done

    echo ""
    success "Sync complete: ${installed} installed, ${skipped} already up to date."
    echo ""
}
