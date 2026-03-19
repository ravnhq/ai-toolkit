# Fish completions for ravencito

# Disable file completions by default
complete -c ravencito -f

# Top-level flags
complete -c ravencito -n __fish_use_subcommand -l help    -d "Show help"
complete -c ravencito -n __fish_use_subcommand -l version -d "Show version"
complete -c ravencito -n __fish_use_subcommand -l logo    -d "Show Ravencito ASCII art"

# Subcommands
complete -c ravencito -n __fish_use_subcommand -a install        -d "Install skills"
complete -c ravencito -n __fish_use_subcommand -a update         -d "Update ravencito"
complete -c ravencito -n __fish_use_subcommand -a list           -d "List available skills"
complete -c ravencito -n __fish_use_subcommand -a search         -d "Search skills"
complete -c ravencito -n __fish_use_subcommand -a info           -d "Show skill details"
complete -c ravencito -n __fish_use_subcommand -a status         -d "Show installed skills"
complete -c ravencito -n __fish_use_subcommand -a remove         -d "Remove installed skills"
complete -c ravencito -n __fish_use_subcommand -a sync           -d "Sync skills from .ravencitorc"
complete -c ravencito -n __fish_use_subcommand -a doctor         -d "Check ravencito health"
complete -c ravencito -n __fish_use_subcommand -a shower-thought  -d "Show a random shower thought"
complete -c ravencito -n __fish_use_subcommand -a shower-thoughts -d "Show a random shower thought"
complete -c ravencito -n __fish_use_subcommand -a completions    -d "Print shell completion setup"
complete -c ravencito -n __fish_use_subcommand -a help           -d "Show help"

# install flags
complete -c ravencito -n "__fish_seen_subcommand_from install" -l global        -s g -d "Install globally"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l claude        -d "Install to .claude/rules"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l cursor        -d "Install to .cursor/rules"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l codex         -d "Install to .codex/rules"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l global-claude -d "Install to global Claude rules"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l global-cursor -d "Install to global Cursor rules"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l global-codex  -d "Install to global Codex rules"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l recipe        -s r -d "Install a stack recipe"
complete -c ravencito -n "__fish_seen_subcommand_from install" -l no-deps       -d "Skip dependency resolution"

# install --recipe completions
function __ravencito_recipes
    set recipe_dir ~/.ravencito/repo/cli/recipes
    if test -d $recipe_dir
        ls $recipe_dir 2>/dev/null | sed 's/\.txt$//'
    end
end
complete -c ravencito -n "__fish_seen_subcommand_from install; and __fish_prev_arg_in --recipe -r" -a "(__ravencito_recipes)"

# remove flags
complete -c ravencito -n "__fish_seen_subcommand_from remove" -l global -s g -d "Remove from global install"

# list categories
complete -c ravencito -n "__fish_seen_subcommand_from list" -a "universal platform framework design assistant"

# completions --shell
complete -c ravencito -n "__fish_seen_subcommand_from completions" -l shell -s s -d "Shell type"
complete -c ravencito -n "__fish_seen_subcommand_from completions; and __fish_prev_arg_in --shell -s" -a "zsh bash fish"

# skill name completions (install, search, info)
function __ravencito_skills
    set cache ~/.ravencito/repo/marketplace.json
    if test -f $cache; and command -q jq
        jq -r '.skills[].name' $cache 2>/dev/null
    end
end
complete -c ravencito -n "__fish_seen_subcommand_from install search info" -a "(__ravencito_skills)"

# remove: installed skills from .ravencitorc
function __ravencito_installed
    if test -f .ravencitorc
        grep "^skills=" .ravencitorc 2>/dev/null | cut -d= -f2- | tr ',' '\n' | cut -d: -f1
    end
end
complete -c ravencito -n "__fish_seen_subcommand_from remove" -a "(__ravencito_installed)"
