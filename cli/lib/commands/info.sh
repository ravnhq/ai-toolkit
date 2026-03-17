#!/usr/bin/env bash
# cli/lib/commands/info.sh — Preview skill details before installing

cmd_info() {
    if [[ $# -eq 0 ]]; then
        die "Usage: ravencito info <skill-name>"
    fi

    local name="$1"
    ensure_registry

    if ! registry_skill_exists "$name"; then
        error "Skill not found: $name"
        echo ""
        info "Did you mean one of these?"
        registry_search "$name" | head -5 | while IFS= read -r match; do
            printf "  ${CYAN}%s${NC}\n" "$match"
        done
        exit 1
    fi

    echo ""
    printf "${WHITE}Skill Details${NC}\n"
    printf "${DIM}─────────────────────────────────────────${NC}\n"
    registry_skill_info "$name"
    echo ""

    # Show dependency chain
    local deps
    deps=$(registry_resolve_deps "$name")
    local dep_count
    dep_count=$(echo "$deps" | wc -w | tr -d ' ')
    if [[ "$dep_count" -gt 1 ]]; then
        printf "${WHITE}Dependency Chain:${NC}\n"
        local first=1
        for dep in $deps; do
            if [[ "$first" -eq 1 ]]; then
                printf "  ${DIM}%s${NC}" "$dep"
                first=0
            else
                printf " ${DIM}→${NC} ${CYAN}%s${NC}" "$dep"
            fi
        done
        echo ""
        echo ""
    fi

    # Show rules if source exists
    local source_rel source_dir
    source_rel=$(registry_skill_source "$name")
    source_dir="${RAVENCITO_DIR}/repo/${source_rel#./}"

    if [[ -d "${source_dir}/rules" ]]; then
        local rule_files
        rule_files=$(find "${source_dir}/rules" -name "*.md" -not -name "_*" 2>/dev/null | sort)
        if [[ -n "$rule_files" ]]; then
            local rule_count
            rule_count=$(echo "$rule_files" | wc -l | tr -d ' ')
            printf "${WHITE}Rules${NC} ${DIM}(%s)${NC}:\n" "$rule_count"
            while IFS= read -r rule_file; do
                local rule_name
                rule_name=$(basename "$rule_file" .md)
                local rule_title
                rule_title=$(grep "^title:" "$rule_file" 2>/dev/null | head -1 | sed 's/^title: *//')
                if [[ -n "$rule_title" ]]; then
                    printf "  ${CYAN}%-35s${NC} %s\n" "$rule_name" "$rule_title"
                else
                    printf "  ${CYAN}%s${NC}\n" "$rule_name"
                fi
            done <<< "$rule_files"
            echo ""
        fi
    fi

    printf "${WHITE}Install:${NC}\n"
    printf "  ravencito install %s\n" "$name"
    printf "  ravencito install --global %s\n" "$name"
    echo ""
}
