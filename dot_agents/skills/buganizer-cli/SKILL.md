---
name: buganizer-cli
description: >
  Interacts with Google's Buganizer and TaskFlow systems. Provides capabilities
  to search bugs and components, render issue details, add comments,
  create new issues, and update issue metadata via the CLI.
---

# Buganizer CLI Skill

This skill allows agents to manage the lifecycle of issues in Buganizer and
components in TaskFlow. It provides a suite of commands to search for
information, communicate via comments, initialize new work items, and maintain
existing ones.

> [!CAUTION] **Write actions (create, update, comment, attachments, hotlists,
> star, vote, subscribe) MUST be explicitly authorized.** Never invoke them
> autonomously. Read-only commands (`render`, `search`, `list-*`, `get-*`) are
> safe to auto-run.

## When to use this skill

-   Use this when you need to find existing bugs or feature requests related to
    a specific topic or component.
-   Use this when you need to identify the correct Component ID for filing a new
    issue.
-   Use this to read the details, status, and history of a specific issue.
-   Use this to provide updates or feedback on an issue by adding a comment.
-   Use this to file a new bug or feature request with specific metadata like
    priority, severity, and assignee.
-   Use this to update existing issue fields like title, status, priority, or
    custom fields.
-   Use this to manage issue relationships such as duplicates, blocking issues,
    and parent/child links.

## How to use it

By default, use the pre-built binary (available on all gLinux machines):

```bash
ISSUES=/google/bin/releases/issues-cli/issues
```

If you modify the CLI source code, you must build from source. Use this snippet
to automatically detect and use your local binary if changes are present:

```bash
# Set the default path
ISSUES=/google/bin/releases/issues-cli/issues

# Check for local changes in the CLI source or its dependencies
CHECK_PATHS=(
  "devtools/buganizer/cli"
  "java/com/google/devtools/buganizer/mcp/service"
)

LOCAL_CHANGES=false
for path in "${CHECK_PATHS[@]}"; do
  if [[ -d "$path" ]] && g4 pending "$path/..." 2>/dev/null | grep -qE " - (edit|add|delete|move|unopened edit|edit/integrate)"; then
    LOCAL_CHANGES=true
    echo "Local changes detected in $path."
    break
  fi
done

if [ "$LOCAL_CHANGES" = true ]; then
  echo "Building local binary..."
  blaze build //devtools/buganizer/cli:issues
  ISSUES="blaze-bin/devtools/buganizer/cli/issues"
fi

```

All interactions are then performed using the `$ISSUES` command.

**Policy note:** When running commands, prefer to use the full binary path
directly (e.g. `/google/bin/releases/issues-cli/issues search ...`) rather than
shell variable expansion, as this increases the chance that the command will be
accepted by the user.

### 1. Search for Issues

Search for bugs matching a query. `$ISSUES search --query "<SEARCH_QUERY>"
[--limit <MAX_RESULTS>] [--verbose]`

-   **query**: The standard Buganizer search syntax.
-   **limit**: Default is 10.

See skills/issue_search/SKILL.md for more details on how use this command.

### 2. Search for Components

Find components to ensure work is filed in the correct location. `$ISSUES
search-components --query "<COMPONENT_NAME>" [--include_description]`

-   **include_description**: Includes the component's description in the output.

### 3. View Issue Details (Render)

Render the full details of a specific issue. `$ISSUES render --issue_id <ID>
[--verbose]`

-   **issue_id**: The numeric Buganizer ID. The `issue_id` flag cannot be
    repeated.

### 4. Add a Comment

Post a new comment to an existing issue. `$ISSUES comment --issue_id <ID>
--comment "<MESSAGE>"`

-   **comment**: The text or markdown to add as a comment.

### 5. Create a New Issue

File a new issue with complete metadata. `$ISSUES create --title "<TITLE>"
--description "<DESC>" --component_id <ID> \ [--assignee <LDAP>] [--priority
<P0-P4>] [--severity <S0-S4>] \ [--type <TYPE>] [--cc <LDAP1,LDAP2>] \ [--status
<STATUS>] [--hotlists <ID1,ID2>]`

-   **Required**: `title`, `description`, and `component_id`.
-   **Priority/Severity**: Use standard enums (e.g., `P1`, `S2`).
-   **Status**: Use standard enums (e.g., `NEW`, `ASSIGNED`, `ACCEPTED`).
-   **Hotlists**: Comma-separated list of hotlist IDs.

### 6. Update Existing Issues

Modify existing issues using specialized sub-commands. All `update` commands
follow the pattern: `$ISSUES update <SUBCOMMAND> --issue_id <ID> [FLAGS]`

-   **title**: `$ISSUES update title --issue_id <ID> --title "<NEW_TITLE>"`
-   **status**: `$ISSUES update status --issue_id <ID> --status "<STATUS>"`
    (e.g., `ASSIGNED`, `FIXED`, `WON'T_FIX`)
-   **priority**: `$ISSUES update priority --issue_id <ID> --priority "<P0-P4>"`
-   **assign-to-self**: `$ISSUES update assign-to-self --issue_id <ID>`
-   **safe-reassign**: `$ISSUES update safe-reassign --issue_id <ID> --assignee
    <LDAP_OR_EMAIL>`
-   **safe-change-verifier**: `$ISSUES update safe-change-verifier --issue_id
    <ID> --verifier <LDAP>`
-   **safe-move**: `$ISSUES update safe-move --issue_id <ID>
    --target_component_id <ID>`
-   **safe-cc**: `$ISSUES update safe-cc --issue_id <ID> --cc_user
    <LDAP_OR_EMAIL>`
-   **safe-un-cc**: `$ISSUES update safe-un-cc --issue_id <ID> --cc_user
    <LDAP_OR_EMAIL>`
-   **verify-as-self**: `$ISSUES update verify-as-self --issue_id <ID>`
-   **duplicate**: `$ISSUES update duplicate --issue_id <ID> --target_id <ID>`
    or `unmark-duplicate`
-   **hotlist**: `$ISSUES update add-hotlist --issue_id <ID> --hotlist_id <ID>`
    or `remove-hotlist`
-   **blocking**: `$ISSUES update blocked-by --issue_id <ID> --target_ids
    <ID1,ID2>` (also `unmark-blocked-by`, `blocking`, `unmark-blocking`)
-   **parent**: `$ISSUES update parent --issue_id <ID> --parent_id <ID>` (also
    `remove-parent`)
-   **custom-field**: `$ISSUES update custom-field --issue_id <ID> --field_id
    <ID> --value "<VAL>"`
-   **edit-comment**: `$ISSUES update edit-comment --issue_id <ID> --comment_num
    <N> --text "<STR>"`
-   **description**: `$ISSUES update description --issue_id <ID> --text "<STR>"`
-   **status-update**: `$ISSUES update status-update --issue_id <ID> --text
    "<STR>"`
-   **severity**: `$ISSUES update severity --issue_id <ID> --severity "<S0-S4>"`
-   **type**: `$ISSUES update type --issue_id <ID> --type "<TYPE>"` (e.g.,
    `BUG`, `FEATURE_REQUEST`, `CUSTOMER_ISSUE`)
-   **effort**: `$ISSUES update effort --issue_id <ID> --effort "<EFFORT>"`
    (e.g. Story points (1, 2, etc.) or T-shirt sizes (`XS`, `S`, `M`, `L`,
    `XL`))
-   **add-changelist**: `$ISSUES update add-changelist --issue_id <ID>
    --changelist "<CHANGELIST>"`

### 7. Look Up Metadata

Retrieve details about components, hotlists, templates, and custom fields by ID.

-   **component**: `$ISSUES get-component <COMPONENT_ID>`
-   **hotlist**: `$ISSUES get-hotlist <HOTLIST_ID>`
-   **template**: `$ISSUES get-template <TEMPLATE_ID> --component_id
    <COMPONENT_ID>`
-   **search hotlists**: `$ISSUES list-hotlists --query "<QUERY>"`
-   **list custom fields**: `$ISSUES list-custom-fields --component_id <ID>`

### 8. Hotlist Management

Create and browse hotlists.

-   **create hotlist**: `$ISSUES create-hotlist --title "<TITLE>" [--description
    "<DESC>"]`
-   **list hotlist entries**: `$ISSUES list-hotlist-entries --hotlist_id <ID>
    [--limit <N>]`

### 9. Issue History & Relationships

View an issue's change history, relationships, and batch-fetch multiple issues.

-   **list updates**: `$ISSUES list-updates --issue_id <ID> [--limit <N>]`
-   **list relationships**: `$ISSUES list-relationships --issue_id <ID>`
-   **batch get**: `$ISSUES batch-get --issue_ids <ID1,ID2,...> [--verbose]`

### 10. Bookmark groups

Browse and access bookmark groups.

-   **list bookmark groups**: `$ISSUES list-bookmark-groups --query "<QUERY>"`
-   **get bookmark group**: `$ISSUES get-bookmark-group <GROUP_ID>`

### 11. View Attachments and Enrichments

Retrieve attachments and AI-generated enrichments for an issue.

-   **attachments**: `$ISSUES list-attachments --issue_id <ID>`
-   **download-attachment**: `$ISSUES download-attachment --issue_id <ID>
    --attachment_id <ID> [--output <FILE>] [--allowed_severity <SEVERITY>]`
-   **enrichments**: `$ISSUES list-enrichments --issue_id <ID>`
-   **list attachment enrichments**: `$ISSUES list-attachment-enrichments
    <ISSUE_ID>`

### 12. Star, Vote, and Subscribe

Manage user engagement with issues.

-   **star**: `$ISSUES star-issue --issue_id <ID> --starred true` (or `false` to
    unstar)
-   **vote**: `$ISSUES vote-issue --issue_id <ID> --voted true` (or `false` to
    unvote)
-   **subscribe**: `$ISSUES subscribe-issue --issue_id <ID> --subscription
    ALL_UPDATES` (or `NO_UPDATES`)

### 13. Issue Hierarchy

Manage parent-child relationships.

-   **add child**: `$ISSUES update child --issue_id <PARENT_ID> --child_id
    <CHILD_ID>`

### 14. SLO and Hotlist Management

Update SLO deadlines and rename hotlists.

-   **update SLO end time**: `$ISSUES update slo-end-time --issue_id <ID>
    --slo_end_time <RFC3339>` (e.g., `2025-06-15T00:00:00Z`)
-   **rename hotlist**: `$ISSUES update hotlist-name --hotlist_id <ID> --name
    "<NEW_NAME>"`

### 15. Attachments

Create and retrieve attachment metadata. Use `--file` to upload file data.

-   **create attachment**: `$ISSUES create-attachment --issue_id <ID> --file
    <PATH>` (auto-detects filename and content type; override with `--filename`
    and `--content_type`)
-   **get attachment**: `$ISSUES get-attachment --issue_id <ID> --attachment_id
    <AID>`

### 16. Saved Searches and User Access

Retrieve saved searches and check user permissions.

-   **get saved search**: `$ISSUES get-saved-search --saved_search_id <ID>`
-   **get user access**: `$ISSUES get-user-access --issue_id <ID>`

## Best Practices

-   **Validate Component IDs**: Always use `search-components` before creating
    an issue to ensure the `component_id` is valid.
-   **Specific Metadata**: When creating issues, provide as much metadata as
    possible (assignee, priority, type) to ensure prompt triage.
-   **Markdown Comments**: Use markdown in comments for better readability of
    logs or code snippets.
