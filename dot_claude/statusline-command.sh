#!/bin/bash
# Read JSON data that Claude Code sends to stdin
input=$(cat)

vct statusline ingest

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

# Build a 5-segment mini bar, e.g. ▰▰▱▱▱ (ceil: any usage shows a block)
mini_bar() {
    local pct=$1 filled i bar=""
    filled=$(( (pct + 19) / 20 ))
    (( filled > 5 )) && filled=5
    for (( i = 0; i < 5; i++ )); do
        if (( i < filled )); then bar+="▰"; else bar+="▱"; fi
    done
    printf '%s' "$bar"
}

# Humanize seconds left: 3d4h / 2h13m / 45m
fmt_left() {
    local secs=$1 mins hrs days
    mins=$(( secs / 60 )); hrs=$(( mins / 60 )); days=$(( hrs / 24 ))
    mins=$(( mins % 60 )); hrs=$(( hrs % 24 ))
    if   (( days > 0 )); then printf '%dd%dh' "$days" "$hrs"
    elif (( hrs > 0 ));  then printf '%dh%dm' "$hrs" "$mins"
    else                      printf '%dm' "$mins"
    fi
}

# Render one rate-limit window: "5h ▰▰▱▱▱ 34% ↻2h13m"
rate_part() {
    local label=$1 pct_raw=$2 resets_at=$3 pct color part
    [ -z "$pct_raw" ] && return
    pct=$(printf '%.0f' "$pct_raw")
    if   (( pct >= 90 )); then color="$BR_RED"
    elif (( pct >= 70 )); then color="$BR_YELLOW"
    else                       color="$GREEN"
    fi
    part="${DIM}${label}${RESET} ${color}$(mini_bar "$pct") ${pct}%${RESET}"
    if [ -n "$resets_at" ]; then
        local secs_left=$(( resets_at - $(date +%s) ))
        (( secs_left > 0 )) && part="${part} ${DIM}↻$(fmt_left "$secs_left")${RESET}"
    fi
    printf '%s' "$part"
}

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

# Rate limit windows: 5-hour and 7-day usage + time until reset
FIVE_PART=$(rate_part "5h" \
    "$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')" \
    "$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')")
SEVEN_PART=$(rate_part "7d" \
    "$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')" \
    "$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')")

# Assemble the status line
LINE="${CYAN}${SHORT_DIR}${RESET}${SEP}${MODEL_C}${MODEL}${RESET}"
[ -n "$EFFORT" ]     && LINE="${LINE}${SEP}${EFFORT_C}${EFFORT}${RESET}"
[ -n "$BRANCH" ]     && LINE="${LINE}${SEP}${GREEN}${BRANCH}${RESET}"
[ -n "$CTX_PART" ]   && LINE="${LINE}${SEP}${CTX_PART}"
[ -n "$COST_PART" ]  && LINE="${LINE}${SEP}${COST_PART}"
[ -n "$FIVE_PART" ]  && LINE="${LINE}${SEP}${FIVE_PART}"
[ -n "$SEVEN_PART" ] && LINE="${LINE}${SEP}${SEVEN_PART}"

printf '%b\n' "$LINE"
