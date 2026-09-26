#!/bin/bash
# Per-subagent status line shown on each row of the agent panel.
# Claude Code pipes one JSON payload containing .columns and .tasks[], and
# expects JSONL back: one {"id","content"} object per row. Runs every 5s with a
# 5s timeout, so keep the per-task sidecar reads to bash builtins.
#
# Layout is a fixed-width table so rows line up vertically, columns 3 apart:
#   mark name(22) elapsed(6) bar+pct(10) model[/effort]
# The label/description is deliberately left out: what a subagent is doing is
# the main agent's problem, this panel only answers how far along it is.
# There is no cost anywhere in this payload, per task or per session.
#
# .tasks[] fields: id name type status description label startTime model effort
#                  contextWindowSize tokenCount tokenSamples cwd
# .name is set only when the Agent call passed one, .type is always
# "local_agent", and .effort is the agent definition's frontmatter rather than
# what was sent; the payload has no session effort either. The subagent type
# and the effort actually sent come from the sidecars Claude Code writes
# beside the session transcript: agentType from agent-<id>.meta.json, and the
# effort from the first assistant line of agent-<id>.jsonl, which records none
# on a model that takes none (Haiku 4.5).
# The last payload is kept in ~/.claude/logs for reference; stderr is dropped
# so a missing dir can't fail the render.
mkdir -p "$HOME/.claude/logs" 2>/dev/null
input=$(tee "$HOME/.claude/logs/subagent_statusline_payload.json" 2>/dev/null)

role_re='"agentType":"([^"]+)"'
effort_re='"effort":"([a-z]+)","perTurnEffort"'
side=
while IFS=$'\t' read -r id base; do
    role= effort= line= n=0
    [ -r "$base.meta.json" ] && IFS= read -r line < "$base.meta.json"
    [[ $line =~ $role_re ]] && role=${BASH_REMATCH[1]}
    [ -r "$base.jsonl" ] && while (( n++ < 64 )) && IFS= read -r line; do
        [[ $line == *'"type":"assistant"'* ]] || continue
        [[ $line =~ $effort_re ]] && effort=${BASH_REMATCH[1]}
        break
    done < "$base.jsonl"
    side+="$id"$'\t'"$role"$'\t'"$effort"$'\n'
done < <(printf '%s' "$input" | jq -r '
    (.transcript_path // "" | rtrimstr(".jsonl")) as $dir
    | .tasks[]? | "\(.id)\t\($dir)/subagents/agent-\(.id)"' 2>/dev/null)

printf '%s' "$input" | jq -c --argjson now "$(date +%s)" --arg side "$side" '
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

# id -> [agentType, effort sent], "" where the sidecar had none
($side | split("\n") | map(select(. != "") | split("\t") | { key: .[0], value: .[1:] })
 | from_entries) as $side
| (.tasks // [])[]
| . as $t
| ($side[$t.id] // ["", ""]) as [$role, $sent]
| ($t.tokenCount // 0) as $tok
| ($t.contextWindowSize // 0) as $win
| (if $win > 0 then (($tok * 100 / $win) | floor) else -1 end) as $pct
# Bright when the agent definition pins the effort, dimmed otherwise.
| { v: $sent, c: (if ($t.effort // "") != "" then "33" else "2;33" end) } as $eff
| (($t.model // "") | shortmodel) as $model
| (($t.status // "") | mark) as $m
| [
    (($t.name // (($role | select(. != "")) // "agent" | sub("^[^:]+:"; ""))) | pad(22) | paint("1;35")),
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
