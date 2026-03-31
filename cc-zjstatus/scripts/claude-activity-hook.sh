#!/bin/bash
# Hook script to capture Claude Code current activity
# Handles multiple hook events with clean, color-coded status output

STATE_DIR="/tmp/claude-zellij-status"
ZELLIJ_SESSION="${ZELLIJ_SESSION_NAME:-}"

# Exit if not in Zellij
[ -z "$ZELLIJ_SESSION" ] && exit 0

STATE_FILE="${STATE_DIR}/${ZELLIJ_SESSION}.json"
mkdir -p "$STATE_DIR"

# Read JSON from stdin
INPUT=$(cat)

# Parse hook event and related fields (with error handling)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null || echo "")
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")

# Use session_id as state key (ZELLIJ_PANE_ID is unreliable in hook subprocesses)
ZELLIJ_PANE="${SESSION_ID}"

# Exit if we couldn't parse the input
[ -z "$HOOK_EVENT" ] && exit 0

# Short session ID (6 chars) as default display name
SHORT_SESSION="${SESSION_ID: -6}"

# Project name for state tracking
PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "?")

# =============================================================================
# AUTO-NAME: Generate display name from first user prompt
# =============================================================================
DISPLAY_NAME=""
NAMED=false

# Check existing state for this session
if [ -f "$STATE_FILE" ]; then
    EXISTING_NAMED=$(jq -r --arg pane "$ZELLIJ_PANE" '.[$pane].named // false' "$STATE_FILE" 2>/dev/null || echo "false")
    EXISTING_DISPLAY=$(jq -r --arg pane "$ZELLIJ_PANE" '.[$pane].display_name // ""' "$STATE_FILE" 2>/dev/null || echo "")
fi

# On UserPromptSubmit, generate a slug from the prompt (only once)
if [ "$HOOK_EVENT" = "UserPromptSubmit" ] && [ "$EXISTING_NAMED" != "true" ]; then
    USER_PROMPT=$(echo "$INPUT" | jq -r '.prompt // .user_prompt // ""' 2>/dev/null || echo "")
    if [ -n "$USER_PROMPT" ]; then
        # Use Haiku to generate a concise session name from the prompt
        DISPLAY_NAME=$(claude -p "Generate a short 2-4 word kebab-case label for this task. Reply with ONLY the label, nothing else. Examples: 'fix-auth-bug', 'add-api-tests', 'refactor-db-layer', 'setup-ci-pipeline'. Task: ${USER_PROMPT}" --model haiku 2>/dev/null | tr -d '[:space:]' | cut -c1-20)
        # Fallback to simple slug if Haiku fails
        if [ -z "$DISPLAY_NAME" ]; then
            DISPLAY_NAME=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '\n' | head -3 | tr '\n' '-' | sed 's/-$//' | cut -c1-20)
        fi
        if [ -n "$DISPLAY_NAME" ]; then
            NAMED=true
        fi
    fi
fi

# Keep existing display_name if already named from prompt
if [ -z "$DISPLAY_NAME" ] && [ "$EXISTING_NAMED" = "true" ] && [ -n "$EXISTING_DISPLAY" ]; then
    DISPLAY_NAME="$EXISTING_DISPLAY"
    NAMED=true
fi

# Fallback to short session ID
[ -z "$DISPLAY_NAME" ] && DISPLAY_NAME="$SHORT_SESSION"

# =============================================================================
# COLOR SCHEME
# =============================================================================
C_GREEN="#2ecc40"
C_YELLOW="#ffdc00"
C_BLUE="#0074d9"
C_AQUA="#4166F5"
C_RED="#ff4136"
C_ORANGE="#ff851b"
C_PURPLE="#b10dc9"
C_GRAY="#666666"
C_DIM="#444444"

# =============================================================================
# SYMBOLS — map hook event to activity, color, symbol
# =============================================================================
case "$HOOK_EVENT" in
    PreToolUse)
        case "$TOOL_NAME" in
            WebSearch)       ACTIVITY="search"; COLOR="$C_BLUE";   SYMBOL="◍" ;;
            WebFetch)        ACTIVITY="fetch";  COLOR="$C_BLUE";   SYMBOL="↓" ;;
            Task|Agent)      ACTIVITY="agent";  COLOR="$C_PURPLE"; SYMBOL="▶" ;;
            Bash)            ACTIVITY="bash";   COLOR="$C_ORANGE"; SYMBOL="⚡" ;;
            Read)            ACTIVITY="read";   COLOR="$C_BLUE";   SYMBOL="◔" ;;
            Write)           ACTIVITY="write";  COLOR="$C_AQUA";   SYMBOL="✎" ;;
            Edit)            ACTIVITY="edit";   COLOR="$C_AQUA";   SYMBOL="✎" ;;
            Glob|Grep)       ACTIVITY="find";   COLOR="$C_BLUE";   SYMBOL="◎" ;;
            Skill)           ACTIVITY="skill";  COLOR="$C_PURPLE"; SYMBOL="★" ;;
            TodoWrite|TaskCreate|TaskUpdate) ACTIVITY="plan"; COLOR="$C_YELLOW"; SYMBOL="◫" ;;
            AskUserQuestion) ACTIVITY="ask?";   COLOR="$C_RED";    SYMBOL="?" ;;
            mcp__*)          ACTIVITY="mcp";    COLOR="$C_PURPLE"; SYMBOL="◈" ;;
            *)               ACTIVITY="work";   COLOR="$C_YELLOW"; SYMBOL="●" ;;
        esac
        DONE=false
        ;;
    PostToolUse)
        ACTIVITY="think"; COLOR="$C_GRAY"; SYMBOL="◐"; DONE=false ;;
    Notification)
        if [ -f "$STATE_FILE" ]; then
            EXISTING_DONE=$(jq -r --arg pane "$ZELLIJ_PANE" '.[$pane].done // false' "$STATE_FILE" 2>/dev/null || echo "false")
            if [ "$EXISTING_DONE" = "true" ]; then
                zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::notify::${DISPLAY_NAME} ! notification" 2>/dev/null || true
                exit 0
            fi
        fi
        ACTIVITY="!"; COLOR="$C_RED"; SYMBOL="!"; DONE=false ;;
    UserPromptSubmit)
        ACTIVITY="start"; COLOR="$C_YELLOW"; SYMBOL="●"; DONE=false ;;
    PermissionRequest)
        ACTIVITY="perm?"; COLOR="$C_RED"; SYMBOL="⚠"; DONE=false ;;
    Stop)
        ACTIVITY="done"; COLOR="$C_GREEN"; SYMBOL="✓"; DONE=true ;;
    SubagentStop)
        ACTIVITY="agent✓"; COLOR="$C_GREEN"; SYMBOL="▷"; DONE=false ;;
    SessionStart)
        ACTIVITY="init"; COLOR="$C_BLUE"; SYMBOL="◆"; DONE=false ;;
    SessionEnd)
        # Remove session from state
        if [ -f "$STATE_FILE" ]; then
            TMP_FILE=$(mktemp)
            jq --arg pane "$ZELLIJ_PANE" 'del(.[$pane])' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE"
            rm -f "$TMP_FILE"
        fi
        # Update zjstatus with remaining sessions
        if [ -f "$STATE_FILE" ] && [ -s "$STATE_FILE" ]; then
            SESSIONS=""
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                [ -n "$SESSIONS" ] && SESSIONS="${SESSIONS} #[fg=#444444]│ "
                SESSIONS="${SESSIONS}${line}"
            done < <(jq -r '
                to_entries | sort_by(.key)[] |
                "#[fg=\(.value.color)]\(.value.symbol) #[fg=#cdd6f4]\(.value.display_name)"
            ' "$STATE_FILE" 2>/dev/null)
            if [ -z "$SESSIONS" ]; then
                zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::pipe::pipe_status::" 2>/dev/null || true
            else
                zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::pipe::pipe_status::${SESSIONS}" 2>/dev/null || true
            fi
        else
            zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::pipe::pipe_status::" 2>/dev/null || true
        fi
        exit 0
        ;;
    *)
        ACTIVITY="..."; COLOR="$C_GRAY"; SYMBOL="○"; DONE=false ;;
esac

# =============================================================================
# UPDATE STATE FILE
# =============================================================================
TIMESTAMP=$(date +%s)

if [ ! -f "$STATE_FILE" ] || [ ! -s "$STATE_FILE" ]; then
    echo "{}" > "$STATE_FILE"
fi

CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")
if ! echo "$CURRENT_STATE" | jq empty 2>/dev/null; then
    CURRENT_STATE="{}"
    echo "{}" > "$STATE_FILE"
fi

# Preserve context data from status line script
EXISTING=$(echo "$CURRENT_STATE" | jq -r --arg pane "$ZELLIJ_PANE" '.[$pane] // {}' 2>/dev/null)
EXISTING_CTX_PCT=$(echo "$EXISTING" | jq -r '.context_pct // null' 2>/dev/null)
EXISTING_CTX_COLOR=$(echo "$EXISTING" | jq -r '.ctx_color // null' 2>/dev/null)

TMP_FILE=$(mktemp)
echo "$CURRENT_STATE" | jq \
    --arg pane "$ZELLIJ_PANE" \
    --arg project "$PROJECT_NAME" \
    --arg display_name "$DISPLAY_NAME" \
    --argjson named "$NAMED" \
    --arg activity "$ACTIVITY" \
    --arg color "$COLOR" \
    --arg symbol "$SYMBOL" \
    --arg ts "$TIMESTAMP" \
    --arg short_session "$SHORT_SESSION" \
    --arg session "$SESSION_ID" \
    --arg ctx_pct "$EXISTING_CTX_PCT" \
    --arg ctx_color "$EXISTING_CTX_COLOR" \
    --argjson done "$DONE" \
    '.[$pane] = {
        project: $project,
        display_name: $display_name,
        named: $named,
        activity: $activity,
        color: $color,
        symbol: $symbol,
        timestamp: ($ts | tonumber),
        short_session: $short_session,
        session_id: $session,
        context_pct: (if $ctx_pct == "null" then null else $ctx_pct end),
        ctx_color: (if $ctx_color == "null" then null else $ctx_color end),
        done: $done
    }' > "$TMP_FILE" 2>/dev/null

if [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$STATE_FILE"
else
    rm -f "$TMP_FILE"
fi

# =============================================================================
# BUILD STATUS BAR
# =============================================================================
# Format: symbol name │ symbol name
SESSIONS=""
while IFS= read -r line; do
    [ -z "$line" ] && continue
    [ -n "$SESSIONS" ] && SESSIONS="${SESSIONS} #[fg=#444444]│ "
    SESSIONS="${SESSIONS}${line}"
done < <(jq -r '
    to_entries | sort_by(.key)[] |
    "#[fg=\(.value.color)]\(.value.symbol) #[fg=#cdd6f4]\(.value.display_name)"
' "$STATE_FILE" 2>/dev/null)

if [ -n "$SESSIONS" ]; then
    zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::pipe::pipe_status::${SESSIONS}" 2>/dev/null || true
fi

# Notify for important events
case "$HOOK_EVENT" in
    Notification|Stop|SubagentStop|AskUserQuestion|PermissionRequest)
        zellij -s "$ZELLIJ_SESSION" pipe "zjstatus::notify::${DISPLAY_NAME} ${SYMBOL} ${ACTIVITY}" 2>/dev/null || true
        ;;
esac
