#!/bin/bash
# Async session naming via Claude CLI
# Called in background by user-prompt-submit.sh
# Args: PANE STATE_FILE ZELLIJ_SESSION USER_PROMPT

PANE="$1"
STATE_FILE="$2"
ZELLIJ_SESSION="$3"
PROMPT="$4"

[ -z "$PANE" ] || [ -z "$STATE_FILE" ] || [ -z "$PROMPT" ] && exit 0

# Ensure claude CLI is available
command -v claude &>/dev/null || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/lib/state.sh"
source "${SCRIPT_DIR}/lib/zjstatus.sh"

# Truncate prompt to avoid sending huge text
TRUNCATED="${PROMPT:0:200}"

# Call claude CLI for a 2-3 word summary
# --plugin-dir /dev/null prevents loading any plugins/hooks (avoids ghost sessions in zjstatus)
NAME=$(claude -p "Summarize this task in 2-3 words, lowercase, hyphenated, no explanation: ${TRUNCATED}" \
    --model haiku --output-format text --max-budget-usd 0.01 --plugin-dir /dev/null 2>/dev/null | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -c 30)

# Sanitize: lowercase, strip non-alphanum/hyphens, trim edges, max 20 chars
NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | sed 's/^-//;s/-$//' | cut -c1-20)

[ -z "$NAME" ] && exit 0

# Update state file with the better name (under flock)
(
    flock -w 2 200 || exit 1
    if [ -f "$STATE_FILE" ]; then
        local_tmp=$(mktemp)
        jq --arg pane "$PANE" --arg name "$NAME" \
            'if .[$pane] then .[$pane].display_name = $name else . end' \
            "$STATE_FILE" > "$local_tmp" 2>/dev/null
        if [ -s "$local_tmp" ]; then
            mv "$local_tmp" "$STATE_FILE"
        else
            rm -f "$local_tmp"
        fi
    fi
) 200>"${STATE_FILE}.lock"

# Refresh zjstatus display to show the new name
zjstatus_refresh
