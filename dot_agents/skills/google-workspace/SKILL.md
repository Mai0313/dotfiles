---
name: google-workspace
description: >-
    Access Google Workspace (Docs, Sheets, Slides, Drive, Calendar, Gmail, Chat,
    Keep). Use for reading docs.google.com URLs, searching emails/calendar,
    downloading/creating files, and semantic search across Workspace corpora.
---

# Managing Google Workspace Content

Dedicated Go CLIs for each Workspace product, plus a semantic search tool (CSA
CLI) for cross-corpus queries.

## When to Use Which Tool

Use Case                               | Tool
-------------------------------------- | -----------------------------------
**Read/create/edit Google Docs**       | `gdocs` (see `gdocs` skill)
**Read/write/format Google Sheets**    | `gsheets` (see `gsheets` skill)
**Read/create/edit Google Slides**     | `gslides` (see `gslides` skill)
**Browse/download/upload Drive files** | `gdrive` (see `gdrive` skill)
**View/create/manage Calendar events** | `gcalendar` (see `gcalendar` skill)
**Semantic search** (all corpora)      | **CSA CLI** *(below)*

> [!TIP]
>
> **Start with CSA CLI** when you need to find or search for content across
> multiple corpora. Use the dedicated CLIs when you already know which specific
> file to read or edit.

> [!IMPORTANT]
>
> The examples below are a quick reference. **Read each product's dedicated
> skill** (linked in the table above) for the full command reference, all flags,
> recipes, and tips.

## Quick Reference

### Google Docs

```bash
GDOCS=/google/bin/releases/gemini-agents-gdocs/gdocs
# Read default tab ONLY (ignores ?tab= in URL)
$GDOCS read DOC_ID
# If URL resembles .../edit?tab=TAB_ID, use it for --tab:
$GDOCS read DOC_ID --tab TAB_ID
$GDOCS create --title "My Document"
$GDOCS import-md /path/to/file.md --title "Report"
```

### Google Sheets

```bash
GSHEETS=/google/bin/releases/gemini-agents-gsheets/gsheets
$GSHEETS read SPREADSHEET_ID "Sheet1!A1:D10"
$GSHEETS create --title "New Spreadsheet"
$GSHEETS import-csv SPREADSHEET_ID /path/to/data.csv
```

### Google Slides

```bash
GSLIDES=/google/bin/releases/gemini-agents-gslides/gslides
$GSLIDES read PRESENTATION_ID
$GSLIDES create --title "My Presentation"
$GSLIDES add-slide PRESENTATION_ID
```

### Google Drive

```bash
GDRIVE=/google/bin/releases/gemini-agents-gdrive/gdrive
$GDRIVE search --name-contains "quarterly report"
$GDRIVE download FILE_ID --out /tmp/file.pdf
$GDRIVE upload /tmp/file.txt --parent FOLDER_ID
```

### Google Calendar

```bash
GCAL=/google/bin/releases/gemini-agents-gcalendar/gcalendar
$GCAL today
$GCAL events --max 5
$GCAL create --title "Team Sync" --start 2025-01-15T10:00:00Z --end 2025-01-15T11:00:00Z
```

## Downloading Images

Download images from Docs/Slides using `curl` to `/tmp/agent_artifacts/`:

```bash
curl -L -o /tmp/agent_artifacts/my_image.png <YOUR_IMAGE_URL>

GDOCS=/google/bin/releases/gemini-agents-gdocs/gdocs
$GDOCS read DOC_ID | \
grep '^\[Image: ' | sed 's/^\[Image: //g;s/\]$//g' | nl | \
while read n url; do curl -L -o /tmp/agent_artifacts/doc_img_$n.png "$url"; done
```

## CSA CLI (Semantic Search Across Corpora)

**Use this tool to search and find content across Workspace.**

The CSA CLI queries the Context Service Agent (CSA) to perform semantic search
across multiple Workspace corpora simultaneously: Calendar, Chat, Drive, Gmail,
and Keep. It understands natural language queries and returns relevant results
with citations.

### Flags

Flag                                | Description                                                                                                                                      | Default
----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | -------
`--user_prompt`                     | The user prompt to send to CSA (required)                                                                                                        | -
`--user_name`                       | The full name of the user to impersonate (e.g., `Jane Doe`), as it appears in their Workspace account. **This is not the user's username/LDAP.** | `""`
`--server`                          | Server environment (`local`, `autopush`, `staging`, `prod`)                                                                                      | `prod`
`--latency_budget_seconds`          | Latency budget in seconds                                                                                                                        | `35`
`--max_output_tokens`               | Maximum number of output tokens                                                                                                                  | `25000`
`--max_implicit_context_iterations` | Max implicit context iterations                                                                                                                  | `5`
`--allowed_corpora`                 | Comma-separated corpora (`CALENDAR,CHAT,DRIVE,GMAIL,KEEP`)                                                                                       | `CALENDAR,CHAT,DRIVE,GMAIL,KEEP`
`--enable_sherlog_tracing`          | Enable Sherlog tracing                                                                                                                           | `False`
`--agent_id`                        | The CSA agent ID                                                                                                                                 | `context_service_agent`

> [!IMPORTANT]
>
> Corpora should be run combined for best results. Avoid running corpora
> individually.

<!-- mdformat off(preserve code blocks) -->
### CSA Examples

Search Gmail for emails about a topic:
```bash
/google/bin/releases/csa-cli/csa_cli.par \
  --user_prompt="Find emails about project deadlines" \
  --allowed_corpora=GMAIL
```

Search multiple corpora:
```bash
/google/bin/releases/csa-cli/csa_cli.par \
  --user_prompt="What meetings do I have with John next week?" \
  --allowed_corpora=GMAIL,CALENDAR \
  --user_name="Jane Doe"
```

Query prod server with custom latency:
```bash
/google/bin/releases/csa-cli/csa_cli.par \
  --user_prompt="Summarize my recent Drive documents" \
  --server=prod \
  --latency_budget_seconds=60
```

Save large output to a file (recommended for complex/multi-corpora queries):
```bash
/google/bin/releases/csa-cli/csa_cli.par \
  --user_prompt="Tell me everything about project X" \
  --allowed_corpora=GMAIL,DRIVE,CALENDAR,CHAT,KEEP 2>&1 | tee /tmp/csa_output_$(date +%Y%m%d_%H%M%S).txt
```
<!-- mdformat on -->

## Reporting Issues

Report bugs or improvements for this skill at [Agent Skill: google_workspace](http://b/hotlists/8078165).
See the `skill_issue` skill for instructions on filing and triaging skill bugs.
