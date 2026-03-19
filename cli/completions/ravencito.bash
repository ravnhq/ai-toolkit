#!/usr/bin/env bash
# Bash completion for ravencito

_ravencito() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="help install update list search info status remove sync doctor shower-thought shower-thoughts completions"

    # First argument: command
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands --help --version --logo" -- "$cur"))
        return 0
    fi

    local cmd="${COMP_WORDS[1]}"

    case "$cmd" in
        install)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--global -g --claude --cursor --codex --global-claude --global-cursor --global-codex --recipe -r --no-deps" -- "$cur"))
            elif [[ "$prev" == "--recipe" || "$prev" == "-r" ]]; then
                local recipe_dir="${HOME}/.ravencito/repo/cli/recipes"
                if [[ -d "$recipe_dir" ]]; then
                    local recipes
                    recipes=$(ls "$recipe_dir" 2>/dev/null | sed 's/\.txt$//')
                    COMPREPLY=($(compgen -W "$recipes" -- "$cur"))
                fi
            else
                _ravencito_complete_skills
            fi
            ;;
        remove)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--global -g" -- "$cur"))
            else
                _ravencito_complete_installed
            fi
            ;;
        search|info)
            _ravencito_complete_skills
            ;;
        list)
            COMPREPLY=($(compgen -W "universal platform framework design assistant" -- "$cur"))
            ;;
        completions)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--shell -s" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "zsh bash fish" -- "$cur"))
            fi
            ;;
    esac
}

_ravencito_complete_skills() {
    local cache_file="${HOME}/.ravencito/repo/marketplace.json"
    if [[ -f "$cache_file" ]] && command -v jq >/dev/null 2>&1; then
        local skills
        skills=$(jq -r '.skills[].name' "$cache_file" 2>/dev/null)
        COMPREPLY=($(compgen -W "$skills" -- "$cur"))
    fi
}

_ravencito_complete_installed() {
    local rc_file=".ravencitorc"
    if [[ -f "$rc_file" ]]; then
        local list skills
        list=$(grep "^skills=" "$rc_file" 2>/dev/null | cut -d'=' -f2-)
        skills=$(echo "$list" | tr ',' '\n' | cut -d':' -f1)
        COMPREPLY=($(compgen -W "$skills" -- "$cur"))
    fi
}

complete -F _ravencito ravencito
