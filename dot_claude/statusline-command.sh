#!/bin/bash
# Read JSON data that Claude Code sends to stdin
input=$(cat)

# ANSI color codes
RESET='\033[0m'
DIM='\033[2;37m'           # dim gray for separators
CYAN='\033[36m'            # directory
MODEL_C='\033[1;35m'       # bold magenta for model id
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BR_YELLOW='\033[93m'
BR_RED='\033[91m'
SEP=" ${DIM}·${RESET} "

# Directory: shorten $HOME to ~
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
SHORT_DIR="${DIR/#"$HOME"/\~}"

# Model identifier (API model id, e.g. "claude-opus-4-7[1m]")
MODEL=$(echo "$input" | jq -r '.model.id')

# Reasoning effort level (only present when the model supports it)
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
case "$EFFORT" in
    low)    EFFORT_C="$GREEN" ;;
    medium) EFFORT_C="$CYAN" ;;
    high)   EFFORT_C="$YELLOW" ;;
    xhigh)  EFFORT_C="$BR_YELLOW" ;;
    max)    EFFORT_C="$BR_RED" ;;
    *)      EFFORT_C="$RESET" ;;
esac

# Git branch from git worktree field, fallback to git CLI
BRANCH=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
if [ -z "$BRANCH" ]; then
    BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi

# Context used percentage with threshold colors
PCT_RAW=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$PCT_RAW" ]; then
    PCT=$(printf '%.0f' "$PCT_RAW")
    if   [ "$PCT" -ge 90 ]; then CTX_C="$RED"
    elif [ "$PCT" -ge 70 ]; then CTX_C="$YELLOW"
    else                          CTX_C="$GREEN"
    fi
    CTX_PART="${CTX_C}${PCT}% used${RESET}"
else
    CTX_PART=""
fi

# Total session cost in USD
COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$COST_RAW" ]; then
    COST_PART="${YELLOW}$(printf '$%.2f' "$COST_RAW")${RESET}"
else
    COST_PART=""
fi

# 5-hour rate limit usage + time until reset
FIVE_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_RESET=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
RATE_PART=""
if [ -n "$FIVE_PCT" ]; then
    FIVE_INT=$(printf '%.0f' "$FIVE_PCT")
    if   [ "$FIVE_INT" -ge 90 ]; then RATE_C="$BR_RED"
    elif [ "$FIVE_INT" -ge 70 ]; then RATE_C="$BR_YELLOW"
    else                               RATE_C="$GREEN"
    fi

    RATE_PART="${RATE_C}5h: ${FIVE_INT}%${RESET}"

    if [ -n "$FIVE_RESET" ]; then
        NOW=$(date +%s)
        SECS_LEFT=$(( FIVE_RESET - NOW ))
        if [ "$SECS_LEFT" -gt 0 ]; then
            MINS=$(( SECS_LEFT / 60 ))
            HRS=$(( MINS / 60 ))
            MINS=$(( MINS % 60 ))
            if [ "$HRS" -gt 0 ]; then
                RESET_STR="${HRS}h${MINS}m"
            else
                RESET_STR="${MINS}m"
            fi
            RATE_PART="${RATE_PART} ${DIM}(resets in ${RESET_STR})${RESET}"
        fi
    fi
fi

# Assemble the status line
LINE="${CYAN}${SHORT_DIR}${RESET}${SEP}${MODEL_C}${MODEL}${RESET}"
[ -n "$EFFORT" ]    && LINE="${LINE}${SEP}${EFFORT_C}${EFFORT}${RESET}"
[ -n "$BRANCH" ]    && LINE="${LINE}${SEP}${GREEN}${BRANCH}${RESET}"
[ -n "$CTX_PART" ]  && LINE="${LINE}${SEP}${CTX_PART}"
[ -n "$COST_PART" ] && LINE="${LINE}${SEP}${COST_PART}"
[ -n "$RATE_PART" ] && LINE="${LINE}${SEP}${RATE_PART}"

printf '%b\n' "$LINE"
