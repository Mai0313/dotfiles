#!/bin/bash
# Dev-only poller: NOT used by the Jetski sidecar (production uses cron watch
# + the agent diffing state itself). Run manually + a Claude Code Monitor on
# events.log when developing on a machine without a Jetski LS. Runtime output
# goes to ~/automation/bug_triage, not this dir.
set -u
BASE="$HOME/automation/bug_triage"
ISSUES=/google/bin/releases/issues-cli/issues
INTERVAL=60

check() {
  local a b snap hash prev
  if ! a=$("$ISSUES" readonly search --query "assignee:weichenglee status:open" --limit 500 --fields "id,modified_time" 2>>"$BASE/poll.err"); then
    echo "$(date -Is) weichenglee query failed" >> "$BASE/poll.err"
    return 0
  fi
  if ! b=$("$ISSUES" readonly search --query "assignee:kurthuang status:open" --limit 500 --fields "id,modified_time" 2>>"$BASE/poll.err"); then
    echo "$(date -Is) kurthuang query failed" >> "$BASE/poll.err"
    return 0
  fi
  snap=$(printf '%s\n%s' "$a" "$b" | grep -E '^(Issue ID|Modified Time)' | paste - - | sort)
  hash=$(printf '%s' "$snap" | sha256sum | cut -d' ' -f1)
  prev=$(cat "$BASE/.poll_snapshot" 2>/dev/null || true)
  if [ "$hash" != "$prev" ]; then
    printf '%s' "$hash" > "$BASE/.poll_snapshot"
    echo "$(date -Is) buganizer snapshot changed" >> "$BASE/events.log"
  fi
}

if [ "${1:-}" = "--once" ]; then check; exit 0; fi
while true; do check; sleep "$INTERVAL"; done
