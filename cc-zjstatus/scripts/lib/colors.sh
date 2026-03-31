#!/bin/bash
# Color constants and tool-to-style mapping
# Sourced by handler scripts after common.sh

# Color scheme (clrs.cc)
C_GREEN="#2ecc40"   # Done/Complete
C_YELLOW="#ffdc00"  # Active/Working
C_BLUE="#0074d9"    # Reading/Searching
C_AQUA="#4166F5"    # Project name text
C_RED="#ff4136"     # Needs attention
C_ORANGE="#ff851b"  # Bash
C_PURPLE="#b10dc9"  # Agent/Skill
C_GRAY="#666666"    # Thinking/Idle

# Map tool name to ACTIVITY, COLOR, SYMBOL
# Usage: tool_to_style "$TOOL_NAME"
tool_to_style() {
    local tool="$1"
    case "$tool" in
        WebSearch)       ACTIVITY="search"; COLOR="$C_BLUE";   SYMBOL="◍" ;;
        WebFetch)        ACTIVITY="fetch";  COLOR="$C_BLUE";   SYMBOL="↓" ;;
        Task)            ACTIVITY="agent";  COLOR="$C_PURPLE"; SYMBOL="▶" ;;
        Bash)            ACTIVITY="bash";   COLOR="$C_ORANGE"; SYMBOL="⚡" ;;
        Read)            ACTIVITY="read";   COLOR="$C_BLUE";   SYMBOL="◔" ;;
        Write)           ACTIVITY="write";  COLOR="$C_AQUA";   SYMBOL="✎" ;;
        Edit)            ACTIVITY="edit";   COLOR="$C_AQUA";   SYMBOL="✎" ;;
        Glob|Grep)       ACTIVITY="find";   COLOR="$C_BLUE";   SYMBOL="◎" ;;
        Skill)           ACTIVITY="skill";  COLOR="$C_PURPLE"; SYMBOL="★" ;;
        TodoWrite)       ACTIVITY="plan";   COLOR="$C_YELLOW"; SYMBOL="◫" ;;
        AskUserQuestion) ACTIVITY="ask?";   COLOR="$C_RED";    SYMBOL="?" ;;
        mcp__*)          ACTIVITY="mcp";    COLOR="$C_PURPLE"; SYMBOL="◈" ;;
        *)               ACTIVITY="work";   COLOR="$C_YELLOW"; SYMBOL="●" ;;
    esac
}
