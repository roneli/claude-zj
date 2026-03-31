#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/zjstatus.sh"

# Don't overwrite completion status
EXISTING_DONE=$(state_get_field "$ZELLIJ_PANE" "done")
if [ "$EXISTING_DONE" = "true" ]; then
    zjstatus_notify "${DISPLAY_NAME} ! notification"
    exit 0
fi

EXISTING_CTX_PCT=$(state_get_field "$ZELLIJ_PANE" "context_pct")
EXISTING_CTX_COLOR=$(state_get_field "$ZELLIJ_PANE" "ctx_color")

state_set_activity "$ZELLIJ_PANE" "$PROJECT_NAME" "$DISPLAY_NAME" \
    "!" "$C_RED" "!" "$SHORT_SESSION" "$SESSION_ID" \
    false "$EXISTING_CTX_PCT" "$EXISTING_CTX_COLOR"

zjstatus_refresh
zjstatus_notify "${DISPLAY_NAME} ! notification"
