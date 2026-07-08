#!/bin/bash
set -euo pipefail

# ─── ANSI Helpers (Standard 16-color palette only) ───────────────────────────
R="\033[0m"         # Reset
B="\033[1m"         # Bold
D="\033[2m"         # Dim
I="\033[3m"         # Italic

FG_RED="\033[31m"
FG_GREEN="\033[32m"
FG_YELLOW="\033[33m"
FG_BLUE="\033[34m"
FG_MAGENTA="\033[35m"
FG_CYAN="\033[36m"
FG_WHITE="\033[37m"

FG_GRAY="\033[90m"
FG_BRIGHT_RED="\033[91m"
FG_BRIGHT_GREEN="\033[92m"
FG_BRIGHT_YELLOW="\033[93m"
FG_BRIGHT_BLUE="\033[94m"
FG_BRIGHT_MAGENTA="\033[95m"
FG_BRIGHT_CYAN="\033[96m"
FG_BRIGHT_WHITE="\033[97m"

# ─── Parse JSON from stdin (single jq pass for performance) ───────────────────
DATA="$(
  jq -r '
    (.cwd // .workspace.current_dir // ""),
    (.model.display_name // .model.id // ""),
    (.plan_tier // ""),
    (.vcs.type // ""),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.context_window.used_percentage // 0),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 0),
    (.agent.name? // (if (.agent | type) == "string" then .agent else "" end)),
    (.agent_state // "idle"),
    (.terminal_width // 80)
  ' 2>/dev/null || true
)"
# Empty/invalid stdin yields no jq output; fall back to defaults.
[ -z "$DATA" ] && DATA=$'\n\n\n\n\nfalse\n0\n0\n0\n0\n\nidle\n80'
{
  read -r CWD
  read -r MODEL
  read -r PLAN
  read -r VCS_TYPE
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r USED_PCT
  read -r IN_TOK
  read -r OUT_TOK
  read -r CTX_SIZE
  read -r AGENT
  read -r STATE
  read -r COLS
} <<< "$DATA"

# Defensive defaults (empty stdin leaves these blank).
: "${COLS:=80}"; [[ "$COLS" =~ ^[0-9]+$ ]] || COLS=80
: "${USED_PCT:=0}"; : "${STATE:=idle}"
[[ "${IN_TOK:-}"  =~ ^[0-9]+$ ]] || IN_TOK=0
[[ "${OUT_TOK:-}" =~ ^[0-9]+$ ]] || OUT_TOK=0
[[ "${CTX_SIZE:-}" =~ ^[0-9]+$ ]] || CTX_SIZE=0

SEP="${FG_GRAY} · ${R}"

# ─── Helpers ─────────────────────────────────────────────────────────────────
fmt_tokens() {
  local n=${1:-0}
  if [ "$n" -ge 1000000 ]; then
    local whole=$((n / 1000000)) frac=$(((n % 1000000) / 100000))
    if [ "$frac" -eq 0 ]; then echo "${whole}M"; else echo "${whole}.${frac}M"; fi
  elif [ "$n" -ge 1000 ]; then
    echo "$((n / 1000))K"
  else
    echo "$n"
  fi
}

# ─── cwd ─────────────────────────────────────────────────────────────────────
CWD_DISP="$CWD"
case "$CWD_DISP" in
  "$HOME")   CWD_DISP="~" ;;
  "$HOME"/*) CWD_DISP="~${CWD_DISP#"$HOME"}" ;;
esac
# Truncate long paths to the last two components (Claude Code style).
MAXP=$((COLS / 3)); [ "$MAXP" -lt 16 ] && MAXP=16
if [ "${#CWD_DISP}" -gt "$MAXP" ] && [ "$CWD_DISP" != "~" ]; then
  base="${CWD_DISP##*/}"
  parent="${CWD_DISP%/*}"; parent="${parent##*/}"
  [ -n "$parent" ] && CWD_DISP="…/${parent}/${base}" || CWD_DISP="…/${base}"
fi
CWD_SEG="${FG_BRIGHT_BLUE}${B}${CWD_DISP}${R}"

# ─── model ───────────────────────────────────────────────────────────────────
MODEL_SEG=""
[ -n "$MODEL" ] && MODEL_SEG="${FG_BRIGHT_MAGENTA}${MODEL}${R}"

# ─── plan_tier ───────────────────────────────────────────────────────────────
PLAN_SEG=""
[ -n "$PLAN" ] && PLAN_SEG="${FG_CYAN}${PLAN}${R}"

# ─── vcs ─────────────────────────────────────────────────────────────────────
VCS_SEG=""
if [ -n "$VCS_BRANCH" ]; then
  if [ "$VCS_DIRTY" = "true" ]; then
    VCS_SEG="${FG_GRAY}⎇ ${FG_BRIGHT_YELLOW}${VCS_BRANCH}${FG_BRIGHT_RED}*${R}"
  else
    VCS_SEG="${FG_GRAY}⎇ ${FG_BRIGHT_GREEN}${VCS_BRANCH}${R}"
  fi
fi

# ─── context_window (compact, Claude Code style) ─────────────────────────────
PCT_INT=${USED_PCT%.*}; PCT_INT=${PCT_INT:-0}
PCT_FMT=$(LC_NUMERIC=C printf "%.0f" "$USED_PCT")

# Single filling-circle glyph acts as a mini gauge.
if   [ "$PCT_INT" -lt 13 ]; then GLYPH="○"
elif [ "$PCT_INT" -lt 38 ]; then GLYPH="◔"
elif [ "$PCT_INT" -lt 63 ]; then GLYPH="◑"
elif [ "$PCT_INT" -lt 88 ]; then GLYPH="◕"
else                             GLYPH="●"
fi

if   [ "$PCT_INT" -ge 90 ]; then CTX_COLOR="$FG_BRIGHT_RED"
elif [ "$PCT_INT" -ge 60 ]; then CTX_COLOR="$FG_BRIGHT_YELLOW"
else                             CTX_COLOR="$FG_BRIGHT_GREEN"
fi

USED_TOK=$((IN_TOK + OUT_TOK))
CTX_SEG="${CTX_COLOR}${GLYPH} ${PCT_FMT}%${R}"
CTX_SEG_FULL="${CTX_SEG}${FG_GRAY} $(fmt_tokens "$USED_TOK")/$(fmt_tokens "$CTX_SIZE")${R}"

# ─── agent (state dot + profile name) ────────────────────────────────────────
case "$STATE" in
  idle)         DOT="${FG_BRIGHT_GREEN}"   ; LABEL="ready" ;;
  thinking)     DOT="${FG_BRIGHT_YELLOW}"  ; LABEL="thinking" ;;
  working)      DOT="${FG_BRIGHT_CYAN}"    ; LABEL="working" ;;
  tool_use)     DOT="${FG_BRIGHT_MAGENTA}" ; LABEL="tool" ;;
  initializing) DOT="${FG_BRIGHT_BLUE}"    ; LABEL="init" ;;
  *)            DOT="${FG_WHITE}"          ; LABEL="$STATE" ;;
esac
[ -n "$AGENT" ] && LABEL="$AGENT"
AGENT_SEG="${DOT}●${R} ${FG_GRAY}${LABEL}${R}"

# ─── Assemble ────────────────────────────────────────────────────────────────
join() {
  local out="" seg
  for seg in "$@"; do
    [ -z "$seg" ] && continue
    if [ -z "$out" ]; then out="$seg"; else out="${out}${SEP}${seg}"; fi
  done
  printf '%s' "$out"
}

if [ "$COLS" -ge 110 ]; then
  # Wide: everything, context with token counts.
  echo -e "$(join "$CWD_SEG" "$MODEL_SEG" "$PLAN_SEG" "$VCS_SEG" "$CTX_SEG_FULL" "$AGENT_SEG")"
elif [ "$COLS" -ge 70 ]; then
  # Medium: everything, context compact.
  echo -e "$(join "$CWD_SEG" "$MODEL_SEG" "$PLAN_SEG" "$VCS_SEG" "$CTX_SEG" "$AGENT_SEG")"
else
  # Narrow: drop plan_tier and model to keep essentials.
  echo -e "$(join "$CWD_SEG" "$VCS_SEG" "$CTX_SEG" "$AGENT_SEG")"
fi
