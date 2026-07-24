#!/bin/bash
# Jetski (Antigravity) CLI status line — styled to match ~/.claude/statusline-command.sh
# Segments: cwd · model · mode · branch · context · quota
# The CLI pipes a JSON payload to stdin on every state change; see
# go/jetski-cli-statusline for the field list.
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
BR_RED='\033[91m'
SEP=" ${DIM}·${RESET} "

# Build a 5-segment mini bar, e.g. ▰▰▱▱▱ (ceil: any usage shows a block)
mini_bar() {
    local pct=$1 filled i bar=""
    filled=$(( (pct + 19) / 20 ))
    (( filled > 5 )) && filled=5
    (( filled < 0 )) && filled=0
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

# Single jq pass for all fields. The quota block mirrors the g3doc sample:
# match the active model's bucket, fall back to gemini-pro, then any gemini-*.
{
  read -r DIR
  read -r MODEL
  read -r MODE
  read -r BRANCH
  read -r DIRTY
  read -r PCT_RAW
  read -r Q_USED
  read -r Q_RESET
  read -r Q_LABEL
} <<< "$(jq -r '
    (.model.id // "") as $mid
    | (if $mid != "" then
         ($mid | split("-")) as $mp
         | (.quota // {} | to_entries
            | map(.key as $k | ($k | split("-")) as $kp | select(($kp - $mp) | length == 0))
            | .[0]?)
       else null end) as $matched
    | (if $matched != null then $matched
       elif (.quota."gemini-pro" // null) != null then {key: "gemini-pro", value: .quota."gemini-pro"}
       else (.quota // {} | to_entries | map(select(.key | startswith("gemini-"))) | .[0]?)
       end) as $q
    | (.cwd // .workspace.current_dir // ""),
      (.model.display_name // .model.id // ""),
      (if (.execution_mode // "default") == "default" then "" else (.execution_mode // "") end),
      (.vcs.branch // ""),
      (.vcs.dirty // false),
      (.context_window.used_percentage // ""),
      (if ($q.value.remaining_fraction // null) == null then "" else ((1 - $q.value.remaining_fraction) * 100) end),
      ($q.value.reset_in_seconds // ""),
      (if $q == null then "" else ($q.key | ltrimstr("gemini-")) end)
  ' <<< "$input" 2>/dev/null)"

# Directory: shorten $HOME to ~
SHORT_DIR="${DIR/#"$HOME"/\~}"

# Execution mode (analogous to Claude's reasoning-effort slot); only when non-default
MODE_PART=""
if [ -n "$MODE" ]; then
    MODE_UPPER=$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')
    MODE_PART="${BR_YELLOW}${MODE_UPPER}${RESET}"
fi

# Branch segment with dirty marker
BRANCH_PART=""
if [ -n "$BRANCH" ]; then
    if [ "$DIRTY" = "true" ]; then
        BRANCH_PART="${GREEN}${BRANCH}${BR_YELLOW}*${RESET}"
    else
        BRANCH_PART="${GREEN}${BRANCH}${RESET}"
    fi
fi

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

# Quota window: mirror Claude's rate-limit bar. The bar fills by USED quota,
# turning red as it nears the limit (jq already gave us the used percentage).
QUOTA_PART=""
if [ -n "$Q_USED" ]; then
    USED=$(printf '%.0f' "$Q_USED")
    if   [ "$USED" -ge 90 ]; then Q_C="$BR_RED"
    elif [ "$USED" -ge 70 ]; then Q_C="$BR_YELLOW"
    else                          Q_C="$GREEN"
    fi
    [ -n "$Q_LABEL" ] && QUOTA_PART="${DIM}${Q_LABEL}${RESET} "
    QUOTA_PART="${QUOTA_PART}${Q_C}$(mini_bar "$USED") ${USED}%${RESET}"
    if [ -n "$Q_RESET" ] && [ "$Q_RESET" -gt 0 ] 2>/dev/null; then
        QUOTA_PART="${QUOTA_PART} ${DIM}↻$(fmt_left "$Q_RESET")${RESET}"
    fi
fi

# Assemble: cwd · model · mode · branch · context · quota
LINE=""
add() { [ -z "$1" ] && return; [ -z "$LINE" ] && LINE="$1" || LINE="${LINE}${SEP}$1"; }
[ -n "$SHORT_DIR" ] && add "${CYAN}${SHORT_DIR}${RESET}"
[ -n "$MODEL" ]     && add "${MODEL_C}${MODEL}${RESET}"
add "$MODE_PART"
add "$BRANCH_PART"
add "$CTX_PART"
add "$QUOTA_PART"

printf '%b\n' "$LINE"
