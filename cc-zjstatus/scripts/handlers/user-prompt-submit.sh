#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/zjstatus.sh"

# Generate display name from first user prompt (only if none exists yet)
USER_PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // ""' 2>/dev/null || echo "")
EXISTING_NAME=$(state_get_field "$ZELLIJ_PANE" "display_name")

if [ -z "$EXISTING_NAME" ] && [ -n "$USER_PROMPT" ]; then
    # Instant slug for immediate display
    SLUG=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | \
        awk '{for(i=1;i<=3&&i<=NF;i++) printf "%s-",$i}' | sed 's/-$//' | cut -c1-15)
    [ -z "$SLUG" ] && SLUG="$PROJECT_NAME"
    DISPLAY_NAME="$SLUG"

    # Fire async naming in background (completely detached)
    nohup "${SCRIPT_DIR}/../async-name.sh" \
        "$ZELLIJ_PANE" "$STATE_FILE" "$ZELLIJ_SESSION" "$USER_PROMPT" \
        </dev/null &>/dev/null &
fi

EXISTING_CTX_PCT=$(state_get_field "$ZELLIJ_PANE" "context_pct")
EXISTING_CTX_COLOR=$(state_get_field "$ZELLIJ_PANE" "ctx_color")

state_set_activity "$ZELLIJ_PANE" "$PROJECT_NAME" "$DISPLAY_NAME" \
    "start" "$C_YELLOW" "●" "$SHORT_SESSION" "$SESSION_ID" \
    false "$EXISTING_CTX_PCT" "$EXISTING_CTX_COLOR"

zjstatus_refresh
