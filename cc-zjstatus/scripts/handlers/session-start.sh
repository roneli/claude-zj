#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/zjstatus.sh"

state_set_activity "$ZELLIJ_PANE" "$PROJECT_NAME" "$DISPLAY_NAME" \
    "init" "$C_BLUE" "◆" "$SHORT_SESSION" "$SESSION_ID" false

zjstatus_refresh
