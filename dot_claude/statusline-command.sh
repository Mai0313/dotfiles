#!/bin/bash
# Read JSON data that Claude Code sends to stdin
input=$(cat)

# Directory: shorten $HOME to ~
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
SHORT_DIR=$(echo "$DIR" | sed "s|^$HOME|~|")

# Model identifier (API model id, e.g. "claude-opus-4-7[1m]")
MODEL=$(echo "$input" | jq -r '.model.id')

# Reasoning effort level (only present when the model supports it)
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')

# Git branch from git worktree field, fallback to git CLI
BRANCH=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
if [ -z "$BRANCH" ]; then
    BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi

# Context used percentage
PCT_RAW=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$PCT_RAW" ]; then
    CTX_PART="$(printf '%.0f' "$PCT_RAW")% used"
else
    CTX_PART=""
fi

# Total session cost in USD
COST_RAW=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$COST_RAW" ]; then
    COST_PART=$(printf '$%.2f' "$COST_RAW")
else
    COST_PART=""
fi

# Assemble the status line
LINE="${SHORT_DIR} · ${MODEL}"
[ -n "$EFFORT" ]    && LINE="${LINE} · ${EFFORT}"
[ -n "$BRANCH" ]    && LINE="${LINE} · ${BRANCH}"
[ -n "$CTX_PART" ]  && LINE="${LINE} · ${CTX_PART}"
[ -n "$COST_PART" ] && LINE="${LINE} · ${COST_PART}"

echo "$LINE"
