#!/usr/bin/env bash
# cli/lib/commands/install.sh — Interactive + direct + recipe + global install

cmd_install() {
    ensure_registry

    local global_mode=0
    local recipe=""
    local skills=()
    local auto_deps
    auto_deps=$(global_config_get "auto_deps" "true")

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --global|-g)
                global_mode=1
                shift
                ;;
            --recipe|-r)
                recipe="$2"
                shift 2
                ;;
            --no-deps)
                auto_deps="false"
                shift
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                skills+=("$1")
                shift
                ;;
        esac
    done

    # Recipe mode
    if [[ -n "$recipe" ]]; then
        install_recipe "$recipe" "$global_mode"
        return
    fi

    # Interactive mode (no skills specified)
    if [[ ${#skills[@]} -eq 0 ]]; then
        install_interactive "$global_mode"
        return
    fi

    # Direct install mode
    install_skills "${skills[@]}" "$global_mode" "$auto_deps"
}

# Install specific skills
install_skills() {
    local global_mode auto_deps
    local skills=()

    # Collect all args except last two (global_mode, auto_deps)
    while [[ $# -gt 2 ]]; do
        skills+=("$1")
        shift
    done
    global_mode="$1"
    auto_deps="$2"

    # Validate all skills exist
    for skill in "${skills[@]}"; do
        if ! registry_skill_exists "$skill"; then
            die "Skill not found: $skill. Run 'ravencito search $skill' to find similar skills."
        fi
    done

    # Resolve dependencies if enabled
    local all_skills=()
    if [[ "$auto_deps" == "true" ]]; then
        for skill in "${skills[@]}"; do
            local deps
            deps=$(registry_resolve_deps "$skill")
            for dep in $deps; do
                # Add if not already in list
                local found=0
                for existing in "${all_skills[@]+"${all_skills[@]}"}"; do
                    if [[ "$existing" == "$dep" ]]; then
                        found=1
                        break
                    fi
                done
                if [[ "$found" -eq 0 ]]; then
                    all_skills+=("$dep")
                fi
            done
        done
    else
        all_skills=("${skills[@]}")
    fi

    # Prompt for install dir early (before showing summary) if project mode
    if [[ "$global_mode" -eq 0 ]]; then
        local _install_dir
        _install_dir=$(ensure_install_dir)
    fi

    # Show what will be installed
    printf "\n${WHITE}Skills to install:${NC}\n"
    for skill in "${all_skills[@]}"; do
        local version
        version=$(registry_skill_version "$skill")
        local is_dep=" ${DIM}(dependency)${NC}"
        for requested in "${skills[@]}"; do
            if [[ "$requested" == "$skill" ]]; then
                is_dep=""
                break
            fi
        done
        printf "  ${CYAN}%s${NC} v%s%b\n" "$skill" "$version" "$is_dep"
    done
    echo ""

    if [[ "$global_mode" -eq 1 ]]; then
        install_global "${all_skills[@]}"
    else
        install_project "${all_skills[@]}"
    fi
}

# Install skills globally
install_global() {
    local skills=("$@")
    ensure_config_dir

    local current_list
    current_list=$(get_global_skills)

    for skill in "${skills[@]}"; do
        local version
        version=$(registry_skill_version "$skill")
        current_list=$(skill_list_upsert "$current_list" "$skill" "$version")
        success "$(skill_name "$skill") added to global skills"
    done

    global_config_set "global_skills" "$current_list"
    echo ""
    success "Global skills updated! These skills apply to all your projects."
}

# Install skills to current project
install_project() {
    local skills=("$@")

    # Ensure install directory is configured
    local install_dir
    install_dir=$(ensure_install_dir)

    local project_root
    project_root=$(find_project_root)
    local target_dir="${project_root}/${install_dir}"

    # Create target directory
    mkdir -p "$target_dir"

    local current_list
    current_list=$(get_project_skills)

    for skill in "${skills[@]}"; do
        local version source_rel source_dir
        version=$(registry_skill_version "$skill")
        source_rel=$(registry_skill_source "$skill")
        source_dir="${RAVENCITO_DIR}/repo/${source_rel#./}"

        if [[ ! -d "$source_dir" ]]; then
            warn "Source not found for $(skill_name "$skill"), skipping"
            continue
        fi

        local skill_target="${target_dir}/${skill}"

        # Remove existing version if present
        if [[ -d "$skill_target" ]]; then
            rm -rf "$skill_target"
        fi

        # Copy skill files
        mkdir -p "$skill_target"

        # Copy SKILL.md
        if [[ -f "${source_dir}/SKILL.md" ]]; then
            cp "${source_dir}/SKILL.md" "$skill_target/"
        fi

        # Copy rules/
        if [[ -d "${source_dir}/rules" ]]; then
            cp -r "${source_dir}/rules" "$skill_target/"
        fi

        # Copy references/
        if [[ -d "${source_dir}/references" ]]; then
            cp -r "${source_dir}/references" "$skill_target/"
        fi

        # Copy scripts/
        if [[ -d "${source_dir}/scripts" ]]; then
            cp -r "${source_dir}/scripts" "$skill_target/"
        fi

        # Copy assets/
        if [[ -d "${source_dir}/assets" ]]; then
            cp -r "${source_dir}/assets" "$skill_target/"
        fi

        current_list=$(skill_list_upsert "$current_list" "$skill" "$version")
        success "$(skill_name "$skill") v${version} installed to ${install_dir}/${skill}/"
    done

    project_config_set "skills" "$current_list"
    echo ""
    success "Skills installed! ravencito is ready to help."
}

# Install from a recipe file
install_recipe() {
    local recipe_name="$1" global_mode="$2"
    local recipe_file="${RAVENCITO_DIR}/repo/cli/recipes/${recipe_name}.txt"

    if [[ ! -f "$recipe_file" ]]; then
        die "Recipe not found: $recipe_name. Available recipes:"
        ls "${RAVENCITO_DIR}/repo/cli/recipes/" 2>/dev/null | sed 's/\.txt$//'
        exit 1
    fi

    info "Installing recipe: ${recipe_name}"

    local skills=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ -z "$line" || "$line" == \#* ]] && continue
        skills+=("$line")
    done < "$recipe_file"

    if [[ ${#skills[@]} -eq 0 ]]; then
        die "Recipe is empty: $recipe_name"
    fi

    printf "${DIM}Skills in recipe:${NC} %s\n" "${skills[*]}"
    echo ""

    install_skills "${skills[@]}" "$global_mode" "true"
}

# Interactive install (TUI)
install_interactive() {
    local global_mode="$1"

    # Source TUI components
    if has_cmd fzf; then
        source "${SCRIPT_DIR}/lib/tui/picker.sh"
        local selected
        selected=$(tui_skill_picker)
    else
        source "${SCRIPT_DIR}/lib/tui/fallback.sh"
        local selected
        selected=$(tui_fallback_picker)
    fi

    if [[ -z "$selected" ]]; then
        info "No skills selected."
        return
    fi

    # Convert newline-separated list to array
    local skills=()
    while IFS= read -r skill; do
        [[ -n "$skill" ]] && skills+=("$skill")
    done <<< "$selected"

    install_skills "${skills[@]}" "$global_mode" "true"
}
