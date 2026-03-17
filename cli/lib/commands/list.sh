#!/usr/bin/env bash
# cli/lib/commands/list.sh — Browse available skills by category

cmd_list() {
    ensure_registry

    local filter="${1:-}"

    printf "\n${WHITE}Available Skills${NC}"
    local total
    total=$(registry_skill_count)
    printf " ${DIM}(%s total)${NC}\n\n" "$total"

    local categories
    categories=$(registry_categories)

    # Category display order
    local ordered_cats="universal platform framework design assistant"

    for cat in $ordered_cats; do
        local count
        count=$(echo "$categories" | grep "^${cat} " | awk '{print $2}')
        [[ -z "$count" ]] && continue

        # Skip if filter is set and doesn't match
        if [[ -n "$filter" && "$cat" != "$filter" ]]; then
            continue
        fi

        printf "${WHITE}%s${NC} ${DIM}(%s)${NC}\n" "$(capitalize "$cat")" "$count"

        local skills
        skills=$(registry_skills_by_category "$cat")

        while IFS= read -r skill_name; do
            [[ -z "$skill_name" ]] && continue
            local desc extends version
            desc=$(registry_skill_field "$skill_name" "description")
            extends=$(registry_skill_field "$skill_name" "extends")
            version=$(registry_skill_field "$skill_name" "version")

            printf "  ${CYAN}%-30s${NC}" "$skill_name"
            if [[ -n "$extends" ]]; then
                printf " ${DIM}← %s${NC}" "$extends"
            fi
            printf "\n"
            printf "    ${DIM}%s${NC}\n" "$desc"
        done <<< "$skills"

        echo ""
    done
}
