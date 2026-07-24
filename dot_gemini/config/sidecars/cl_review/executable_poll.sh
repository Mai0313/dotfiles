#!/bin/bash
# Dev-only poller: NOT used by the Jetski sidecar (gerrit watch does its own
# polling in production). Run manually + a Claude Code Monitor on events.log
# when developing on a machine without a Jetski LS. Runtime output goes to
# ~/automation/cl_review (events.log, .poll_snapshot, poll.err), not this dir.
set -u
BASE="$HOME/automation/cl_review"
GERRIT=/google/bin/releases/gemini-agents-gerrit/gerrit
HOST=https://googleplex-polygon-android-review.git.corp.google.com
QUERY="status:open reviewer:weichenglee -owner:weichenglee -is:wip"
INTERVAL=30

check() {
  local snap hash prev
  if ! snap=$("$GERRIT" search --host "$HOST" --query "$QUERY" --limit 100 2>>"$BASE/poll.err"); then
    echo "$(date -Is) query failed" >> "$BASE/poll.err"
    return 0
  fi
  hash=$(printf '%s' "$snap" | sha256sum | cut -d' ' -f1)
  prev=$(cat "$BASE/.poll_snapshot" 2>/dev/null || true)
  if [ "$hash" != "$prev" ]; then
    printf '%s' "$hash" > "$BASE/.poll_snapshot"
    echo "$(date -Is) gerrit snapshot changed" >> "$BASE/events.log"
  fi
}

if [ "${1:-}" = "--once" ]; then check; exit 0; fi
while true; do check; sleep "$INTERVAL"; done
