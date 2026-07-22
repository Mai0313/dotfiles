#!/bin/bash
# Per-subagent status line shown on each row of the agent panel.
# Claude Code pipes one JSON payload containing .columns and .tasks[], and
# expects JSONL back: one {"id","content"} object per row. Runs every 5s with a
# 5s timeout, so keep it to a single jq pass.
#
# Layout is a fixed-width table so rows line up vertically:
#   mark name(14) elapsed(6) bar+pct(10) trend(1) tokens(6) model(12) effort(6) label
# Everything before the label is 63 columns wide; the label gets the rest.
#
# .tasks[] fields: id name type status description label startTime model effort
#                  contextWindowSize tokenCount tokenSamples cwd
input=$(cat)

printf '%s' "$input" | jq -c --argjson now "$(date +%s)" '
def sgr($c): "\u001b[" + $c + "m";
def paint($c): sgr($c) + . + sgr("0");

def spaces($n): if $n > 0 then ([range(0; $n)] | map(" ") | join("")) else "" end;
def pad($n): .[0:$n] | . + spaces($n - length);
def lpad($n): .[0:$n] | spaces($n - length) + .;

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

# 34 -> "▰▰▱▱▱" (ceil: any usage shows a block)
def bar5:
  (((. + 19) / 20) | floor) as $n
  | (if $n > 5 then 5 elif $n < 0 then 0 else $n end) as $n
  | [range(0; 5)] | map(if . < $n then "▰" else "▱" end) | join("");

def pctcolor: if . >= 80 then "31" elif . >= 50 then "33" else "32" end;

# Drop the "claude-" prefix and the trailing date stamp: they cost width and
# say nothing. "claude-haiku-4-5-20251001" -> "haiku-4-5"
def shortmodel: sub("^claude-"; "") | sub("-[0-9]{8}$"; "");

# Only mark terminal states; running rows already have a spinner.
def mark:
  { completed: ("✓" | paint("32")),
    failed:    ("✗" | paint("31")),
    killed:    ("⊘" | paint("31")),
    paused:    ("⏸" | paint("33")) }[.] // empty;

((.columns // 120) - 63) as $room
| (.tasks // [])[]
| . as $t
| ($t.tokenCount // 0) as $tok
| ($t.contextWindowSize // 0) as $win
| (if $win > 0 then (($tok * 100 / $win) | floor) else -1 end) as $pct
| [
    ($t.status | mark),
    (($t.name // "?") | pad(14) | paint("1;35")),
    ((if ($t.startTime // 0) > 0 then ($t.startTime | elapsed) else "" end) | lpad(6) | paint("2")),
    (if $pct >= 0
     then (($pct | bar5) + " " + ($pct | tostring | lpad(3)) + "%") | paint($pct | pctcolor)
     else spaces(10) end)
    + (if ($t.tokenSamples | length) >= 2 and ($t.tokenSamples[-1] > $t.tokenSamples[0])
       then ("▲" | paint("2")) else " " end),
    ((if $tok > 0 then ($tok | human) else "" end) | lpad(6) | paint("2")),
    (($t.model // "") | shortmodel | pad(12) | paint("36")),
    (($t.effort // "") | tostring | pad(6) | paint("33")),
    (($t.label // $t.description // "")[0:(if $room > 20 then $room else 20 end)] | paint("2"))
  ]
| join(" ")
| { id: $t.id, content: . }
' 2>/dev/null || true
