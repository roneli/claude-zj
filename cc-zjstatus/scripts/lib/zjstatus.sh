#!/bin/bash
# Zellij zjstatus communication
# Sourced by handler scripts after common.sh
# Requires: STATE_FILE, ZELLIJ_SESSION

# Build combined status string from state and send to zjstatus
zjstatus_refresh() {
    [ ! -f "$STATE_FILE" ] && return
    local sessions=""
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [ -n "$sessions" ] && sessions="${sessions}  "
        sessions="${sessions}${line}"
    done < <(jq -r '
        to_entries | sort_by(.key)[] |
        "#[fg=\(.value.color)]\(.value.symbol) #[fg=#4166F5]\(.value.display_name // .value.project)" +
        (if .value.context_pct then " #[fg=\(.value.ctx_color // "#2ecc40")]\(.value.context_pct)%" else "" end)
    ' "$STATE_FILE" 2>/dev/null)

    zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::pipe::pipe_status::${sessions}" 2>/dev/null || true
}

# Send a notification to zjstatus
zjstatus_notify() {
    local msg="$1"
    zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::notify::${msg}" 2>/dev/null || true
}
