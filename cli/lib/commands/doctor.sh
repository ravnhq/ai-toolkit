#!/usr/bin/env bash
# cli/lib/commands/doctor.sh — Health check

cmd_doctor() {
    printf "\n${WHITE}ravencito doctor${NC}\n\n"

    local issues=0

    # Check ravencito installation
    _check "ravencito directory" "[[ -d '$RAVENCITO_DIR' ]]" || issues=$((issues + 1))
    _check "Repository cache" "[[ -d '${RAVENCITO_DIR}/repo/.git' ]]" || issues=$((issues + 1))
    _check "Config file" "[[ -f '${RAVENCITO_DIR}/config' ]]" || issues=$((issues + 1))
    _check "marketplace.json" "[[ -f '${RAVENCITO_DIR}/repo/marketplace.json' ]]" || issues=$((issues + 1))

    # Check dependencies
    echo ""
    printf "${WHITE}Dependencies${NC}\n"
    _check_cmd "git"
    _check_cmd "bash"
    _check_cmd_optional "jq" "JSON parsing (preferred)"
    _check_cmd_optional "python3" "JSON parsing (fallback)"
    _check_cmd_optional "fzf" "Interactive TUI"

    # Check JSON parsing availability
    if ! has_cmd jq && ! has_cmd python3; then
        warn "No JSON parser available (need jq or python3)"
        issues=$((issues + 1))
    fi

    # Check project context
    echo ""
    printf "${WHITE}Project${NC}\n"
    local project_root
    project_root=$(find_project_root)

    local rc_file="${project_root}/${RAVENCITORC}"
    if [[ -f "$rc_file" ]]; then
        success ".ravencitorc found at ${rc_file}"

        local install_dir
        install_dir=$(config_get "$rc_file" "install_dir" "")
        if [[ -n "$install_dir" ]]; then
            local target="${project_root}/${install_dir}"
            if [[ -d "$target" ]]; then
                success "Install directory exists: ${install_dir}"

                # Check for orphaned skills (in dir but not in config)
                local skill_list
                skill_list=$(config_get "$rc_file" "skills" "")
                local dir_skills config_skills

                dir_skills=$(ls -1 "$target" 2>/dev/null || true)
                if [[ -n "$dir_skills" && -n "$skill_list" ]]; then
                    while IFS= read -r dir_skill; do
                        [[ -z "$dir_skill" ]] && continue
                        if ! echo "$skill_list" | tr ',' '\n' | grep -q "^${dir_skill}:"; then
                            warn "Orphaned skill directory: ${install_dir}/${dir_skill}"
                            issues=$((issues + 1))
                        fi
                    done <<< "$dir_skills"
                fi
            else
                warn "Install directory missing: ${install_dir}"
                issues=$((issues + 1))
            fi
        fi

        # Check skill versions
        local skills
        skills=$(config_get "$rc_file" "skills" "")
        if [[ -n "$skills" ]]; then
            local IFS=','
            for entry in $skills; do
                local name="${entry%%:*}"
                if ! registry_skill_exists "$name" 2>/dev/null; then
                    warn "Skill '${name}' not found in registry"
                    issues=$((issues + 1))
                fi
            done
        fi
    else
        printf "  ${DIM}No .ravencitorc in current project${NC}\n"
    fi

    # Summary
    echo ""
    if [[ "$issues" -eq 0 ]]; then
        success "All checks passed! ravencito is healthy."
    else
        warn "${issues} issue(s) found. Run 'ravencito update' to fix most issues."
    fi
    echo ""
}

# Check helper
_check() {
    local label="$1" test="$2"
    if eval "$test" 2>/dev/null; then
        success "$label"
        return 0
    else
        warn "$label — missing"
        return 1
    fi
}

_check_cmd() {
    local cmd="$1"
    if has_cmd "$cmd"; then
        local ver
        ver=$("$cmd" --version 2>/dev/null | head -1 || echo "found")
        success "${cmd}: ${ver}"
    else
        warn "${cmd}: not found"
    fi
}

_check_cmd_optional() {
    local cmd="$1" desc="$2"
    if has_cmd "$cmd"; then
        success "${cmd}: found (${desc})"
    else
        printf "  ${DIM}%s: not found (%s)${NC}\n" "$cmd" "$desc"
    fi
}
