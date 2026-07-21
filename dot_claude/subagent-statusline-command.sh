#!/bin/bash
# Per-subagent status line shown on each row of the agent panel.
# Claude Code pipes one JSON payload containing .columns and .tasks[], and
# expects JSONL back: one {"id","content"} object per row. Runs every 5s with a
# 5s timeout, so keep it to a single jq pass.
#
# .tasks[] fields: id name type status description label startTime model effort
#                  contextWindowSize tokenCount tokenSamples cwd
input=$(cat)

printf '%s' "$input" | jq -c --argjson now "$(date +%s)" '
def sgr($c): "\u001b[" + $c + "m";
def paint($c): sgr($c) + . + sgr("0");

# 34200 -> "34.2k", 1200000 -> "1.2M"
def human:
  if . >= 1000000 then "\(((. / 100000) | floor) / 10)M"
  elif . >= 1000 then "\(((. / 100) | floor) / 10)k"
  else "\(.)"
  end;

# epoch ms -> "45s" / "2m14s" / "1h03m"
def elapsed:
  ($now - ((. / 1000) | floor)) as $s
  | if $s <= 0 then "0s"
    elif $s < 60 then "\($s)s"
    elif $s < 3600 then "\(($s / 60) | floor)m\($s % 60)s"
    else "\(($s / 3600) | floor)h\((($s % 3600) / 60) | floor)m"
    end;

# Only mark terminal states; running rows already have a spinner.
def mark:
  { completed: ("✓" | paint("32")),
    failed:    ("✗" | paint("31")),
    killed:    ("⊘" | paint("31")),
    paused:    ("⏸" | paint("33")) }[.] // empty;

(.tasks // [])[]
| . as $t
| ($t.tokenCount // 0) as $tok
| ($t.contextWindowSize // 0) as $win
| (if $win > 0 then (($tok * 100 / $win) | floor) else -1 end) as $pct
| [
    ($t.status | mark),
    (if $t.name then ($t.name | paint("1;35")) else empty end),
    ($t.startTime | elapsed | paint("2")),
    (if $t.model then ($t.model | sub("^claude-"; "") | paint("36")) else empty end),
    (if $t.effort then ($t.effort | tostring | paint("33")) else empty end),
    (if $tok > 0 then
       (($tok | human) + (if $pct >= 0 then " \($pct)%" else "" end))
       | paint(if $pct >= 80 then "31" elif $pct >= 50 then "33" else "32" end)
       + (if ($t.tokenSamples | length) >= 2 and ($t.tokenSamples[-1] > $t.tokenSamples[0])
          then ("▲" | paint("2")) else "" end)
     else empty end),
    (($t.label // $t.description // "")[0:80] | select(length > 0) | paint("2"))
  ]
| join(" " + sgr("2") + "·" + sgr("0") + " ")
| { id: $t.id, content: . }
' 2>/dev/null || true
