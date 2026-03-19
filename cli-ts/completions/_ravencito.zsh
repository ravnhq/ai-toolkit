#compdef ravencito

_ravencito() {
    local -a commands
    commands=(
        'help:Show banner and help'
        'install:Install skills by name, recipe, or globally'
        'update:Pull latest and update installed skills'
        'list:Browse available skills by category'
        'search:Search skills by keyword or tag'
        'info:Preview skill details'
        'status:Show installed vs latest versions'
        'remove:Uninstall a skill'
        'sync:Sync team skills from .ravencitorc'
        'doctor:Health check'
        'shower-thought:Random shower thought from Dave'
        'shower-thoughts:Random shower thought from Dave'
        'completions:Print shell completion setup instructions'
    )

    local -a global_opts
    global_opts=(
        '--help[Show help]'
        '-h[Show help]'
        '--version[Show version]'
        '-v[Show version]'
        '--logo[Show full-size ravencito art]'
    )

    _arguments -C \
        '1:command:->command' \
        '*::arg:->args' \
        $global_opts

    case "$state" in
        command)
            _describe 'ravencito command' commands
            ;;
        args)
            case "$words[1]" in
                install)
                    _arguments \
                        '--global[Install as global defaults]' \
                        '-g[Install as global defaults]' \
                        '--claude[Target Claude Code (.claude/rules)]' \
                        '--cursor[Target Cursor (.cursor/rules)]' \
                        '--codex[Target Codex (.codex/rules)]' \
                        '--global-claude[Install to ~/.claude/rules]' \
                        '--global-cursor[Install to ~/.cursor/rules]' \
                        '--global-codex[Install to ~/.codex/rules]' \
                        '--recipe[Install a predefined recipe]:recipe:_ravencito_recipes' \
                        '-r[Install a predefined recipe]:recipe:_ravencito_recipes' \
                        '--no-deps[Skip dependency resolution]' \
                        '*:skill:_ravencito_skills'
                    ;;
                remove)
                    _arguments \
                        '--global[Remove from global skills]' \
                        '-g[Remove from global skills]' \
                        '*:skill:_ravencito_installed_skills'
                    ;;
                search|info)
                    _arguments '*:skill:_ravencito_skills'
                    ;;
                list)
                    local -a categories
                    categories=(universal platform framework design assistant)
                    _describe 'category' categories
                    ;;
                completions)
                    _arguments \
                        '--shell[Shell type (zsh, bash, or fish)]:shell:(zsh bash fish)' \
                        '-s[Shell type (zsh, bash, or fish)]:shell:(zsh bash fish)'
                    ;;
            esac
            ;;
    esac
}

_ravencito_skills() {
    local -a skills
    local cache_file="${HOME}/.ravencito/repo/marketplace.json"
    if [[ -f "$cache_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            skills=($(jq -r '.skills[].name' "$cache_file" 2>/dev/null))
        fi
    fi
    _describe 'skill' skills
}

_ravencito_installed_skills() {
    local -a skills
    local rc_file=".ravencitorc"
    if [[ -f "$rc_file" ]]; then
        local list
        list=$(grep "^skills=" "$rc_file" 2>/dev/null | cut -d'=' -f2-)
        if [[ -n "$list" ]]; then
            skills=(${(s:,:)list//:[0-9]*/})
        fi
    fi
    _describe 'installed skill' skills
}

_ravencito_recipes() {
    local -a recipes
    local recipe_dir="${HOME}/.ravencito/repo/cli/recipes"
    if [[ -d "$recipe_dir" ]]; then
        recipes=(${recipe_dir}/*.txt(:t:r))
    fi
    _describe 'recipe' recipes
}

_ravencito "$@"
