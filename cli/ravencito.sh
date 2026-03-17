#!/usr/bin/env bash
# ravencito — AI Skills Manager
# Main entry point / dispatcher

set -euo pipefail

# Resolve script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export RAVENCITO_DIR="${HOME}/.ravencito"
export RAVENCITO_VERSION="1.0.0"

# Source core libraries
source "${SCRIPT_DIR}/lib/core/utils.sh"
source "${SCRIPT_DIR}/lib/core/config.sh"
source "${SCRIPT_DIR}/lib/core/registry.sh"
source "${SCRIPT_DIR}/lib/core/updater.sh"

# Usage / help
show_help() {
    printf "${WHITE}ravencito${NC} — AI Skills Manager (v${RAVENCITO_VERSION})\n\n"
    printf "${WHITE}Usage:${NC}\n"
    printf "  ravencito                          Interactive skill picker (TUI)\n"
    printf "  ravencito install <skills...>      Install skills to current project\n"
    printf "  ravencito install --global <s...>  Install as global defaults\n"
    printf "  ravencito install --recipe <name>  Install a predefined stack recipe\n"
    printf "  ravencito update                   Pull latest + update installed skills\n"
    printf "  ravencito list                     Browse available skills by category\n"
    printf "  ravencito search <query>           Search skills by keyword or tag\n"
    printf "  ravencito info <skill>             Preview skill details\n"
    printf "  ravencito status                   Show installed vs latest versions\n"
    printf "  ravencito remove <skill>           Uninstall a skill\n"
    printf "  ravencito sync                     Sync team skills from .ravencitorc\n"
    printf "  ravencito doctor                   Health check\n"
    printf "  ravencito shower-thought           Random shower thought from Dave\n"
    printf "  ravencito help                     Show this banner + help\n"
    printf "\n"
    printf "${WHITE}Options:${NC}\n"
    printf "  --help, -h                         Show this help\n"
    printf "  --version, -v                      Show version\n"
    printf "  --logo                             Show full-size ravencito art\n"
    printf "\n"
}

# Main dispatcher
main() {
    # Ensure config dir exists
    ensure_config_dir

    # Handle flags that can appear anywhere
    case "${1:-}" in
        --help|-h)
            show_banner
            show_help
            exit 0
            ;;
        --version|-v)
            echo "ravencito v${RAVENCITO_VERSION}"
            exit 0
            ;;
        --logo)
            show_logo
            exit 0
            ;;
    esac

    # No args → interactive TUI skill picker
    if [[ $# -eq 0 ]]; then
        # Auto-update check
        auto_update_check
        source "${SCRIPT_DIR}/lib/commands/install.sh"
        cmd_install
        exit 0
    fi

    # Auto-update check (silent, non-blocking for commands)
    auto_update_check

    # Dispatch command
    local cmd="$1"
    shift

    case "$cmd" in
        help)
            show_banner
            show_help
            ;;
        install)
            source "${SCRIPT_DIR}/lib/commands/install.sh"
            cmd_install "$@"
            ;;
        update)
            source "${SCRIPT_DIR}/lib/commands/update.sh"
            cmd_update "$@"
            ;;
        list)
            source "${SCRIPT_DIR}/lib/commands/list.sh"
            cmd_list "$@"
            ;;
        search)
            source "${SCRIPT_DIR}/lib/commands/search.sh"
            cmd_search "$@"
            ;;
        info)
            source "${SCRIPT_DIR}/lib/commands/info.sh"
            cmd_info "$@"
            ;;
        status)
            source "${SCRIPT_DIR}/lib/commands/status.sh"
            cmd_status "$@"
            ;;
        remove)
            source "${SCRIPT_DIR}/lib/commands/remove.sh"
            cmd_remove "$@"
            ;;
        sync)
            source "${SCRIPT_DIR}/lib/commands/sync.sh"
            cmd_sync "$@"
            ;;
        doctor)
            source "${SCRIPT_DIR}/lib/commands/doctor.sh"
            cmd_doctor "$@"
            ;;
        shower-thought|shower-thoughts)
            source "${SCRIPT_DIR}/lib/commands/shower-thought.sh"
            cmd_shower_thought "$@"
            ;;
        *)
            error "Unknown command: $cmd"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
