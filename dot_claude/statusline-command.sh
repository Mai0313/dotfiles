#!/usr/bin/env bash
# Claude Code statusLine command
# Mirrors the Powerlevel10k lean prompt style: user@host  dir  model  context%

input=$(cat)

user=$(whoami)
host=$(hostname -s)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
if [ -n "$cwd" ]; then
  short_cwd="${cwd/#$home/~}"
else
  short_cwd="~"
fi

# Build parts
parts=""

# user@host in cyan
parts+=$(printf '\033[36m%s@%s\033[0m' "$user" "$host")

# separator + dir in yellow
parts+=$(printf '  \033[33m%s\033[0m' "$short_cwd")

# model in magenta
if [ -n "$model" ]; then
  parts+=$(printf '  \033[35m%s\033[0m' "$model")
fi

# context usage in green/red depending on remaining
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    parts+=$(printf '  \033[31mctx:%s%%\033[0m' "$used_int")
  else
    parts+=$(printf '  \033[32mctx:%s%%\033[0m' "$used_int")
  fi
fi

printf '%s' "$parts"
