#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"
source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/state.sh"
source "${LIB_DIR}/zjstatus.sh"

# Remove this pane from state
state_delete_pane "$ZELLIJ_PANE"

# Refresh display (shows remaining sessions, or clears if none left)
zjstatus_refresh
