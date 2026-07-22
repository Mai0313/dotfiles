#!/bin/bash
# Per-subagent status line shown on each row of the agent panel.
# Claude Code pipes one JSON payload containing .columns and .tasks[], and
# expects JSONL back: one {"id","content"} object per row. Runs every 5s with a
# 5s timeout, so keep it to a single jq pass.
#
# Layout is a fixed-width table so rows line up vertically, columns 3 apart:
#   mark name(22) elapsed(6) bar+pct(10) model[/effort]
# The label/description is deliberately left out: what a subagent is doing is
# the main agent's problem, this panel only answers how far along it is.
# A task only carries its own .effort when its agent definition pins one, so it
# falls back to the session .effort.level the subagent inherits, shown dimmed.
# There is no cost anywhere in this payload, per task or per session.
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

# Only mark terminal states; running rows already have a spinner, and that
# spinner plus its space is exactly what an empty mark leaves room for.
def mark:
  { completed: ("✓" | paint("32")),
    failed:    ("✗" | paint("31")),
    killed:    ("⊘" | paint("31")),
    paused:    ("⏸" | paint("33")) }[.] // "";

(.effort.level // "") as $inherited
| (.tasks // [])[]
| . as $t
| ($t.tokenCount // 0) as $tok
| ($t.contextWindowSize // 0) as $win
| (if $win > 0 then (($tok * 100 / $win) | floor) else -1 end) as $pct
| (if ($t.effort // "") != "" then { v: ($t.effort | tostring), c: "33" }
   else { v: $inherited, c: "2;33" } end) as $eff
| (($t.model // "") | shortmodel) as $model
| (($t.status // "") | mark) as $m
| [
    (($t.name // (($t.type // "agent") | sub("^[^:]+:"; ""))) | pad(22) | paint("1;35")),
    ((if ($t.startTime // 0) > 0 then ($t.startTime | elapsed) else "" end) | lpad(6) | paint("2")),
    (if $pct >= 0
     then (($pct | bar5) + " " + ($pct | tostring | lpad(3)) + "%") | paint($pct | pctcolor)
     else spaces(10) end),
    (($model | paint("36"))
     + (if $eff.v != "" then ((if $model != "" then "/" else "" end) + $eff.v | paint($eff.c)) else "" end))
  ]
| join("   ")
| (if ($m | length) > 0 then ($m + " " + .) else . end)
| { id: $t.id, content: . }
' 2>/dev/null || true
