---
name: gdrive
description: >-
    List, search, upload, download, update, and manage Google Drive files and
    folders using a Go CLI. Use when listing files, searching Drive, downloading
    or uploading files, updating file content in-place, creating folders,
    creating shortcuts, moving/copying/renaming files, sharing, managing permissions, viewing
    revisions, exporting Google files, or getting file URLs. Don't use for
    editing Docs/Sheets/Slides content (use those specific skills instead).
    Also use when the user shares a drive.google.com URL.
---

# gdrive

> [!CAUTION]
>
> The `empty-trash` and `delete` commands permanently remove files and cannot be
> undone. **Never** use destructive commands unless the user explicitly asks.

## CLI

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GDRIVE=/google/bin/releases/gemini-agents-gdrive/gdrive
```

Alternatively, install via apt (the `gdrive` binary will be available directly
on PATH):

```bash
sudo glinux-add-repo -b gemini-agents-gdrive stable
sudo apt update && sudo apt install -y gemini-agents-gdrive
```

If you need to build from source:

```bash
blaze build //learning/gemini/agents/clis/gdrive:gdrive
GDRIVE=blaze-bin/learning/gemini/agents/clis/gdrive/gdrive
```

> [!CAUTION]
>
> The `empty-trash` command permanently deletes **all** trashed files and cannot
> be undone. Only run it with explicit user approval.

> [!IMPORTANT]
>
> **Efficiency Guidelines**:
>
> -   Answer general or conceptual questions about Drive commands (e.g., "Is
>     empty-trash reversible?") directly using the details in this `SKILL.md`
>     file.
>
> -   Do **NOT** call tools (e.g., `code_search`, `view_file`, `list_dir`) to
>     inspect source code or documentation unless the prompt specifically asks
>     to inspect file content or implementation details.
>
> -   **Ignore Workspace Context**: Ignore workspace-specific context (e.g.,
>     CitC workspace name, pending changes, CL numbers in path) when answering.
>     Focus solely on the prompt.

## Recipes

**Browse and search:**

```bash
$GDRIVE ls                                # list root
$GDRIVE ls FOLDER_ID --max 50
$GDRIVE ls --trashed                      # list trashed items
$GDRIVE search --name-contains "quarterly report"
$GDRIVE search --parent-id FOLDER_ID --modified-after 2024-01-01T00:00:00Z --type spreadsheet
$GDRIVE search --name-contains "quarterly report" --include-trashed # search trashed items
$GDRIVE recent --max 10
$GDRIVE starred
$GDRIVE info FILE_ID
$GDRIVE url FILE_ID                       # print web URL
$GDRIVE tree FOLDER_ID                    # recursive folder tree
```

**Exact Name Matching for Native Files:** Omit file extensions when searching
for native Google Workspace files (Docs, Sheets, Slides) via exact match.
Execute `$GDRIVE search --name-exact "Q3 Budget"` instead of appending
artificial extensions like `"Q3 Budget.gsheet"`. Include extensions only when
searching exact names of binary uploads (e.g., `report.pdf`).

**File operations:**

```bash
$GDRIVE download FILE_ID --out /tmp/file.pdf
$GDRIVE upload /tmp/file.txt --parent FOLDER_ID
$GDRIVE update FILE_ID /tmp/updated_notebook.ipynb  # replace content, keep ID/link/permissions
$GDRIVE mkdir "New Folder" --parent FOLDER_ID
$GDRIVE create-shortcut FILE_ID FOLDER_ID  # shortcut inherits original file name
$GDRIVE cp FILE_ID "Copy of File"
$GDRIVE mv FILE_ID NEW_PARENT_ID
$GDRIVE rename FILE_ID "New Name"
$GDRIVE export FILE_ID /tmp/doc.pdf --format pdf   # export Google files
$GDRIVE trash FILE_ID
$GDRIVE untrash FILE_ID
$GDRIVE empty-trash --confirm
```

**Sharing and permissions:**

```bash
$GDRIVE share FILE_ID --email user@google.com --role writer
$GDRIVE share FILE_ID --email user@google.com --role reader --notify=false
$GDRIVE permissions FILE_ID
$GDRIVE remove-permission FILE_ID PERMISSION_ID
$GDRIVE audit-permissions FOLDER_ID        # recursive permission audit
```

**Other:**

```bash
$GDRIVE quota
$GDRIVE revisions FILE_ID
$GDRIVE shared-drives
$GDRIVE comments FILE_ID
$GDRIVE comments FILE_ID --add "Nice work!"
$GDRIVE comments FILE_ID --add "Done" --reply_to COMMENT_ID
$GDRIVE batch -f ops.json
```

## Commands

| Command             | Description                                       |
| ------------------- | ------------------------------------------------- |
| `ls`                | List files (supports `--trashed`)                 |
| `search`            | Search files (supports `--trashed`)               |
| `info`              | Get file info                                     |
| `url`               | Print web URL                                     |
| `download`          | Download file                                     |
| `upload`            | Upload file                                       |
| `update`            | Update file content in-place (preserves ID, link, |
:                     : permissions)                                      :
| `mkdir`             | Create folder                                     |
| `create-shortcut`   | Create a shortcut to a file in a folder           |
| `cp`                | Copy file                                         |
| `mv`                | Move file                                         |
| `rename`            | Rename file                                       |
| `export`            | Export Google file                                |
| `trash`             | Trash file                                        |
| `untrash`           | Restore file                                      |
| `empty-trash`       | Empty trash                                       |
| `share`             | Share file (`--notify=false` to suppress email)   |
| `permissions`       | List permissions                                  |
| `remove-permission` | Remove permission                                 |
| `audit-permissions` | Recursive permission audit                        |
| `recent`            | Recent files                                      |
| `starred`           | Starred files                                     |
| `quota`             | Show quota                                        |
| `revisions`         | List file revisions                               |
| `shared-drives`     | List shared drives                                |
| `tree`              | Display folder tree                               |
| `comments`          | List/add/reply to comments                        |
| `batch`             | Execute batch ops                                 |

## Global Flags

-   `--json` — output as JSON (works with all read commands)

## Reporting Issues

Report bugs or improvements for this skill at
[Agent Skill: gdrive](http://b/hotlists/8078139). See the `skill_issue` skill
for instructions on filing and triaging skill bugs.
