#!/bin/bash
# State file operations with flock-based locking
# Sourced by handler scripts after common.sh
# Requires: STATE_FILE

# Read and validate state file, echo JSON (defaults to {})
state_read() {
    if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
        echo "{}"
        return
    fi
    local content
    content=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")
    if ! echo "$content" | jq empty 2>/dev/null; then
        echo "{}"
        return
    fi
    echo "$content"
}

# Update a pane's state under flock
# Usage: state_update_pane "$ZELLIJ_PANE" --arg key val ... 'jq_expression'
# The jq expression receives $pane as the pane key
state_update_pane() {
    local pane="$1"; shift
    (
        flock -w 2 200 || return 1
        local current
        current=$(state_read)
        local tmp
        tmp=$(mktemp)
        echo "$current" | jq --arg pane "$pane" "$@" > "$tmp" 2>/dev/null
        if [ -s "$tmp" ]; then
            mv "$tmp" "$STATE_FILE"
        else
            rm -f "$tmp"
        fi
    ) 200>"${STATE_FILE}.lock"
}

# Delete a pane from state under flock
state_delete_pane() {
    local pane="$1"
    (
        flock -w 2 200 || return 1
        local current
        current=$(state_read)
        local tmp
        tmp=$(mktemp)
        echo "$current" | jq --arg pane "$pane" 'del(.[$pane])' > "$tmp" 2>/dev/null
        if [ -s "$tmp" ]; then
            mv "$tmp" "$STATE_FILE"
        else
            rm -f "$tmp"
        fi
    ) 200>"${STATE_FILE}.lock"
}

# Update pane activity with standard fields
# Usage: state_set_activity PANE PROJECT DISPLAY_NAME ACTIVITY COLOR SYMBOL SHORT_SESSION SESSION_ID DONE [CTX_PCT CTX_COLOR]
state_set_activity() {
    local pane="$1" project="$2" display_name="$3" activity="$4" color="$5"
    local symbol="$6" short_session="$7" session="$8" done="$9"
    local ctx_pct="${10:-}" ctx_color="${11:-}"
    local ts
    ts=$(date +%s)

    state_update_pane "$pane" \
        --arg project "$project" \
        --arg display_name "$display_name" \
        --arg activity "$activity" \
        --arg color "$color" \
        --arg symbol "$symbol" \
        --arg ts "$ts" \
        --arg short_session "$short_session" \
        --arg session "$session" \
        --arg ctx_pct "$ctx_pct" \
        --arg ctx_color "$ctx_color" \
        --argjson done "$done" \
        '.[$pane] = {
            project: $project,
            display_name: $display_name,
            activity: $activity,
            color: $color,
            symbol: $symbol,
            timestamp: ($ts | tonumber),
            short_session: $short_session,
            session_id: $session,
            context_pct: (if $ctx_pct == "" then null else $ctx_pct end),
            ctx_color: (if $ctx_color == "" then null else $ctx_color end),
            done: $done
        }'
}

# Read a single field for a pane (no lock needed - snapshot read)
state_get_field() {
    local pane="$1"
    local field="$2"
    if [ -f "$STATE_FILE" ]; then
        jq -r --arg pane "$pane" --arg field "$field" '.[$pane][$field] // ""' "$STATE_FILE" 2>/dev/null || echo ""
    else
        echo ""
    fi
}
