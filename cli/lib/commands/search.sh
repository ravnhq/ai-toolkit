#!/usr/bin/env bash
# cli/lib/commands/search.sh — Search skills by keyword/tag

cmd_search() {
    if [[ $# -eq 0 ]]; then
        die "Usage: ravencito search <query>"
    fi

    local query="$1"
    ensure_registry

    local results
    results=$(registry_search "$query")

    if [[ -z "$results" ]]; then
        warn "No skills found matching '$query'"
        echo ""
        info "Try broader terms or run 'ravencito list' to see all skills."
        return
    fi

    local count
    count=$(echo "$results" | wc -l | tr -d ' ')
    printf "\n${WHITE}Search results for '${query}'${NC} ${DIM}(%s found)${NC}\n\n" "$count"

    while IFS= read -r skill_name; do
        [[ -z "$skill_name" ]] && continue
        local desc category
        desc=$(registry_skill_field "$skill_name" "description")
        category=$(registry_skill_field "$skill_name" "category")

        printf "  ${CYAN}%-30s${NC} ${DIM}[%s]${NC}\n" "$skill_name" "$category"
        printf "    ${DIM}%s${NC}\n" "$desc"
    done <<< "$results"
    echo ""
}
