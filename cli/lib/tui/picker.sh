#!/usr/bin/env bash
# cli/lib/tui/picker.sh — fzf multi-select with preview

# fzf-based skill picker with preview pane
# Returns newline-separated list of selected skill names
tui_skill_picker() {
    ensure_registry

    local preview_cmd
    preview_cmd="bash -c '
        name=\"{1}\"
        RAVENCITO_DIR=\"${RAVENCITO_DIR}\"
        MARKETPLACE=\"${RAVENCITO_DIR}/repo/marketplace.json\"
        if command -v jq >/dev/null 2>&1; then
            jq -r --arg n \"\$name\" \"
                .skills[] | select(.name == \\\$n) |
                \\\"\\(.name)\\n\\n\\(.description)\\n\\nCategory:  \\(.category)\\nExtends:   \\(.extends // \\\"—\\\")\\nVersion:   \\(.version // \\\"—\\\")\\nRules:     \\(.rules // \\\"—\\\")\\nTags:      \\(.tags | join(\\\", \\\"))\\\"
            \" \"\$MARKETPLACE\"
        else
            echo \"\$name\"
        fi
    '"

    local skill_data
    skill_data=$(registry_skill_list_formatted)

    echo "$skill_data" | \
        column -t -s $'\t' | \
        fzf --multi \
            --header "TAB to select multiple · ENTER to confirm · ESC to cancel" \
            --prompt "Select skills> " \
            --preview "$preview_cmd" \
            --preview-window "right:50%:wrap" \
            --ansi \
            --no-hscroll \
            --bind "ctrl-a:toggle-all" \
        2>/dev/null | \
        awk '{print $1}'
}
