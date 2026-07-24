# Buganizer Triage Babysitter

Supplements `~/.gemini/GEMINI.md` and the deployed skills; anything not specified here follows them. Triggered blindly by cron every 10 minutes (production) or by the dev poller, so the change detection below decides whether there is anything to do. Nothing new = one `no-op` line in `~/automation/bug_triage/run.log`, exit silently.

## Change detection

- State: `$ANTIGRAVITY_EXECUTABLE_DATA_DIR/state.json` (production) / `~/automation/bug_triage/state.json` (dev mode). Per bug: title, assignee, status (`seeded | triaged | listed`), classification, `baseline` {comment_count, modified}.
- First run ever (no state.json): seed every currently matching bug as `seeded`, notify nothing. Seeded bugs are never triaged retroactively.
- Lock: mkdir `~/automation/bug_triage/run.lock`; exists = exit silently; remove when done, also on failure.
- Query open bugs assigned to weichenglee or kurthuang: `/google/bin/releases/issues-cli/issues readonly search --query "assignee:<user> status:open" --limit 500 --fields "id,title,modified_time"`, once per assignee.
- **New** = not in state and no `~/automation/bug_triage/b_<id>/` dir (assignee search deliberately catches reassigned old bugs). **Updated** = `triaged` bug whose comment count or modified moved past `baseline`. Baseline = the values observed at fetch time during triage, never re-queried afterwards, so a comment landing mid-triage stays detectable.

## Task

Administrative tickets (GCP deletion warnings, `[Corp Chat App Approval]`, `Review ARM Errata`, `Early Errata Comms`, TaskFlow work items): one digest line, `status: listed`, nothing else.

Every other new bug (and anything you are unsure about), do the equivalent of:

> 幫我分析一下 b/<ID>, 並幫我存入 b_<ID>.md, log 可以存入 b_<ID>_logs

with these supplements:

- Work with cwd = `~/automation/bug_triage/b_<ID>/` (mkdir -p first) so the report and logs land there.
- The `bug-investigator` skill drives the analysis (GEMINI.md already mandates this for triage). If the skill is missing on this machine, log to run.log and stop; do not improvise.
- Local trees (`~/aosp`; kernel trees under `~/linux_kernel`, see GEMINI.md) are strictly read-only REFERENCE: read and grep existing files only. Never `git checkout`, `git fetch`, `repo download`, or anything else that changes a local tree's state; fetch CL contents through the gerrit CLI instead.
- Conclude with a classification: `known-issue` (canonical bug + fix CL) / `needs-ramdump` (what to request) / `new-unknown` (best lead), and record the fetch-time baseline in state.

**Updated** bugs get a delta pass: fetch only what is newer than `baseline`, follow the new evidence, append an `## Update <ISO date>` section to `b_<ID>.md`, note whether the classification changed.

## Notify

Only the Bug Babysitter space `spaces/AAQA5Go4uQw`. Never DM kurthuang.

- Analyzed bugs: one thread per bug (`--thread_key b-<ID>`): link, whose bug (你的 / Kurt 的), classification, key evidence, any SSO-gated URLs needing manual browser download; upload `b_<ID>.md` into the same thread (thread id = the part of the returned message name before the dot). Delta summaries reply into the same thread.
- Administrative lines: the shared thread `--thread_key administrative`, no attachment.
- No signature line.

## Errors

One bug fails: log to run.log, leave it out of state so the next run retries, continue with the rest. Whole run fails: log, exit silently. Auth expiry (LOAS/gcert): warn in the space at most once per 12 hours.

---
Reference: [Jetski Sidecars](https://g3doc.corp.google.com/devtools/jetski/marina/g3doc/sidecars.md)
