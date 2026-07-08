#!/bin/bash
# Antigravity CLI status line — styled to match ~/.claude/statusline-command.sh
# Segments: cwd · model · plan_tier · vcs · context · agent
input=$(cat)

# ANSI color codes (same palette as the Claude Code status line)
RESET='\033[0m'
DIM='\033[2;37m'           # dim gray for separators / metadata
CYAN='\033[36m'            # directory
MODEL_C='\033[1;35m'       # bold magenta for model
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BR_YELLOW='\033[93m'
SEP=" ${DIM}·${RESET} "

# Single jq pass for all fields
{
  read -r DIR
  read -r MODEL
  read -r PLAN
  read -r BRANCH
  read -r DIRTY
  read -r PCT_RAW
  read -r AGENT
  read -r STATE
} <<< "$(echo "$input" | jq -r '
    (.cwd // .workspace.current_dir // ""),
    (.model.display_name // .model.id // ""),
    (.plan_tier // ""),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.context_window.used_percentage // ""),
    (.agent.name? // (if (.agent | type) == "string" then .agent else "" end)),
    (.agent_state // "idle")
  ' 2>/dev/null)"

# Directory: shorten $HOME to ~
SHORT_DIR="${DIR/#"$HOME"/\~}"

# Context used percentage with threshold colors
CTX_PART=""
if [ -n "$PCT_RAW" ]; then
    PCT=$(printf '%.0f' "$PCT_RAW")
    if   [ "$PCT" -ge 90 ]; then CTX_C="$RED"
    elif [ "$PCT" -ge 70 ]; then CTX_C="$YELLOW"
    else                          CTX_C="$GREEN"
    fi
    CTX_PART="${CTX_C}${PCT}% used${RESET}"
fi

# Agent: profile name (fallback to state word), colored by agent state
case "$STATE" in
    idle)         STATE_C="$DIM" ;;
    thinking)     STATE_C="$YELLOW" ;;
    working)      STATE_C="$CYAN" ;;
    tool_use)     STATE_C="$MODEL_C" ;;
    initializing) STATE_C="$BR_YELLOW" ;;
    *)            STATE_C="$RESET" ;;
esac
AGENT_LABEL="$AGENT"; [ -z "$AGENT_LABEL" ] && AGENT_LABEL="$STATE"

# Branch segment with dirty marker
BRANCH_PART=""
if [ -n "$BRANCH" ]; then
    if [ "$DIRTY" = "true" ]; then
        BRANCH_PART="${GREEN}${BRANCH}${BR_YELLOW}*${RESET}"
    else
        BRANCH_PART="${GREEN}${BRANCH}${RESET}"
    fi
fi

# Assemble: cwd · model · plan_tier · vcs · context · agent
LINE=""
add() { [ -z "$1" ] && return; [ -z "$LINE" ] && LINE="$1" || LINE="${LINE}${SEP}$1"; }
[ -n "$SHORT_DIR" ] && add "${CYAN}${SHORT_DIR}${RESET}"
[ -n "$MODEL" ]     && add "${MODEL_C}${MODEL}${RESET}"
[ -n "$PLAN" ]      && add "${DIM}${PLAN}${RESET}"
add "$BRANCH_PART"
add "$CTX_PART"
[ -n "$AGENT_LABEL" ] && add "${STATE_C}${AGENT_LABEL}${RESET}"

printf '%b\n' "$LINE"
