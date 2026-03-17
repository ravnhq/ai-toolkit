#!/usr/bin/env bash
# cli/lib/core/updater.sh — Auto-update check (oh-my-zsh style)

LAST_UPDATE_FILE="${RAVENCITO_DIR}/.last_update"
UPDATE_CHECK_DAYS=7

# Get seconds since epoch (portable)
epoch_now() {
    date +%s
}

# Check if update is needed based on timestamp
should_check_update() {
    local check_days
    check_days=$(global_config_get "update_check" "$UPDATE_CHECK_DAYS")

    if [[ "$check_days" -eq 0 ]]; then
        return 1  # Updates disabled
    fi

    if [[ ! -f "$LAST_UPDATE_FILE" ]]; then
        return 0  # Never checked
    fi

    local last_check now diff threshold
    last_check=$(cat "$LAST_UPDATE_FILE" 2>/dev/null || echo "0")
    now=$(epoch_now)
    diff=$(( now - last_check ))
    threshold=$(( check_days * 86400 ))

    [[ "$diff" -ge "$threshold" ]]
}

# Record that we just checked for updates
touch_last_update() {
    epoch_now > "$LAST_UPDATE_FILE"
}

# Check for remote updates (returns 0 if updates available)
check_remote_updates() {
    local repo_dir="${RAVENCITO_DIR}/repo"

    if [[ ! -d "${repo_dir}/.git" ]]; then
        return 1
    fi

    # Fetch silently, fail gracefully (offline)
    if ! git -C "$repo_dir" fetch origin main --quiet 2>/dev/null; then
        return 1
    fi

    local local_head remote_head
    local_head=$(git -C "$repo_dir" rev-parse HEAD 2>/dev/null)
    remote_head=$(git -C "$repo_dir" rev-parse origin/main 2>/dev/null)

    [[ "$local_head" != "$remote_head" ]]
}

# Count number of new commits on remote
count_remote_updates() {
    local repo_dir="${RAVENCITO_DIR}/repo"
    git -C "$repo_dir" rev-list HEAD..origin/main --count 2>/dev/null || echo "0"
}

# Pull latest changes
pull_updates() {
    local repo_dir="${RAVENCITO_DIR}/repo"
    git -C "$repo_dir" pull --rebase origin main --quiet 2>/dev/null
}

# Auto-update check (call on every ravencito invocation)
auto_update_check() {
    if ! should_check_update; then
        return
    fi

    if check_remote_updates; then
        local count
        count=$(count_remote_updates)
        echo ""
        printf "${YELLOW}ravencito found %s shiny new update%s!${NC}\n" "$count" "$([[ "$count" -eq 1 ]] && echo "" || echo "s")"
        if confirm "Install now?"; then
            pull_updates
            touch_last_update
            success "Updated! Restart ravencito to use the latest version."
        else
            touch_last_update
            info "Skipped. Run 'ravencito update' anytime."
        fi
        echo ""
    else
        touch_last_update
    fi
}
