#!/usr/bin/env bash
# cli/lib/tui/fallback.sh — select-based fallback when no fzf

# Fallback skill picker using numbered menus
# Returns newline-separated list of selected skill names
# All display output goes to /dev/tty so it doesn't get captured by $()
tui_fallback_picker() {
    ensure_registry

    echo "" > /dev/tty
    printf "${WHITE}Select skills to install${NC}\n" > /dev/tty
    printf "${DIM}(Enter numbers separated by spaces, or 'q' to cancel)${NC}\n\n" > /dev/tty

    # Show categories first
    local categories
    categories=$(registry_categories)
    local ordered_cats="universal platform framework design assistant"

    printf "${WHITE}Categories:${NC}\n" > /dev/tty
    local cat_num=1
    local cat_list=()
    for cat in $ordered_cats; do
        local count
        count=$(echo "$categories" | grep "^${cat} " | awk '{print $2}')
        [[ -z "$count" ]] && continue
        printf "  %d) %s (%s skills)\n" "$cat_num" "${cat}" "$count" > /dev/tty
        cat_list+=("$cat")
        cat_num=$((cat_num + 1))
    done
    printf "  a) All categories\n" > /dev/tty
    echo "" > /dev/tty

    printf "${WHITE}Choose category${NC}: " > /dev/tty
    read -r cat_choice < /dev/tty

    [[ "$cat_choice" == "q" ]] && return

    local selected_cat=""
    if [[ "$cat_choice" == "a" ]]; then
        selected_cat=""
    elif [[ "$cat_choice" =~ ^[0-9]+$ ]] && [[ "$cat_choice" -ge 1 ]] && [[ "$cat_choice" -le ${#cat_list[@]} ]]; then
        selected_cat="${cat_list[$((cat_choice - 1))]}"
    else
        warn "Invalid choice."
        return
    fi

    # Show skills
    echo "" > /dev/tty
    local skill_list=()
    local idx=1

    if [[ -n "$selected_cat" ]]; then
        local skills
        skills=$(registry_skills_by_category "$selected_cat")
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            local desc
            desc=$(registry_skill_field "$name" "description")
            printf "  %2d) ${CYAN}%-30s${NC} %s\n" "$idx" "$name" "$desc" > /dev/tty
            skill_list+=("$name")
            idx=$((idx + 1))
        done <<< "$skills"
    else
        local all_skills
        all_skills=$(registry_skill_names)
        while IFS= read -r name; do
            [[ -z "$name" ]] && continue
            local desc cat
            desc=$(registry_skill_field "$name" "description")
            cat=$(registry_skill_field "$name" "category")
            printf "  %2d) ${CYAN}%-30s${NC} ${DIM}[%s]${NC} %s\n" "$idx" "$name" "$cat" "$desc" > /dev/tty
            skill_list+=("$name")
            idx=$((idx + 1))
        done <<< "$all_skills"
    fi

    echo "" > /dev/tty
    printf "${WHITE}Enter skill numbers (space-separated)${NC}: " > /dev/tty
    read -r selections < /dev/tty

    [[ "$selections" == "q" || -z "$selections" ]] && return

    local result=""
    for num in $selections; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le ${#skill_list[@]} ]]; then
            local selected_name="${skill_list[$((num - 1))]}"
            result+="${selected_name}\n"
        fi
    done

    echo -e "$result"
}
