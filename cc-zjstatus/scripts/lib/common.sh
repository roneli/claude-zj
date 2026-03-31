#!/bin/bash
# Shared setup: env vars, input parsing, guards
# Sourced by every handler script

STATE_DIR="/tmp/claude-zellij-status"
ZELLIJ_SESSION="${ZELLIJ_SESSION_NAME:-}"

# Exit if not in Zellij
[ -z "$ZELLIJ_SESSION" ] && exit 0

STATE_FILE="${STATE_DIR}/${ZELLIJ_SESSION}.json"
mkdir -p "$STATE_DIR"

# Read JSON from stdin
INPUT=$(cat)

# Parse hook event and related fields
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")

# Use session_id as state key (ZELLIJ_PANE_ID is unreliable in hook subprocesses)
ZELLIJ_PANE="${SESSION_ID}"

# Exit if we couldn't parse the input
[ -z "$HOOK_EVENT" ] && exit 0

# Short session ID (last 4 chars)
SHORT_SESSION="${SESSION_ID: -4}"

# Project name from cwd (fallback display name)
PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "?")
if [ ${#PROJECT_NAME} -gt 12 ]; then
    PROJECT_NAME="${PROJECT_NAME:0:6}..."
fi

# Resolve display name from state, fallback to project name
DISPLAY_NAME=""
if [ -f "$STATE_FILE" ]; then
    DISPLAY_NAME=$(jq -r --arg pane "$ZELLIJ_PANE" '.[$pane].display_name // ""' "$STATE_FILE" 2>/dev/null || echo "")
fi
[ -z "$DISPLAY_NAME" ] && DISPLAY_NAME="$PROJECT_NAME"
