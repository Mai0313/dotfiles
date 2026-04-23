---
name: gmail
description: >-
    Read, search, send, and manage Gmail messages, drafts, labels, and filters
    using a Go CLI. Use when reading emails, searching inbox, sending messages,
    managing drafts, forwarding, setting vacation responder, creating filters,
    managing labels, downloading attachments, or configuring auto-forwarding.
    Also use when the user shares a mail.google.com URL.
    Don't use for Google Chat messages or Calendar invites.
    IMPORTANT: This skill can send emails as you. The agent MUST get explicit
    user authorization before sending any email.
---

# gmail

Read and send Gmail emails from the command line via the Gmail REST API.

> [!CAUTION]
>
> This skill can send emails **as you**. The agent MUST get explicit user
> authorization before sending any email. Always confirm the recipient, subject,
> and body with the user first.

> [!CAUTION]
>
> The `batch-delete` and `trash` commands permanently delete or trash emails.
> **Never** use these unless the user explicitly asks to delete/trash messages.

> [!IMPORTANT]
>
> **Unattended mode (`AGY_UNATTENDED`)**: When the environment variable
> `AGY_UNATTENDED` is set (to any non-empty value), all outbound commands
> (`send`, `send-self`, `reply`, `forward`, `send-with-attachment`,
> `send-draft`) are **hard-blocked** at the CLI level and will return an error.
> This prevents autonomous agents from sending emails without human oversight.
> Use `create-draft` to prepare emails for the human operator to review and send
> manually.

## Prerequisites

-   Corp credentials (automatic on corp machines)

## Quick Start

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GMAIL=/google/bin/releases/gemini-agents-gmail/gmail
```

Alternatively, install via apt (binary will be available on PATH):

```bash
sudo glinux-add-repo -b gemini-agents-gmail stable
sudo apt update && sudo apt install -y gemini-agents-gmail
```

Use `--version` to check build date. To verify the exact build CL: `binfs ls
/google/bin/releases/gemini-agents-gmail`.

If you modify the CLI source code, build from source:

```bash
blaze build //learning/gemini/agents/clis/gmail:gmail
GMAIL=blaze-bin/learning/gemini/agents/clis/gmail/gmail
```

## Recipes

**Search and read:**

```bash
$GMAIL search "is:unread from:boss" --max 5
$GMAIL read "is:starred" --max 3          # search + show full bodies
$GMAIL get MESSAGE_ID                     # full message by ID
$GMAIL threads "subject:review" --max 5
$GMAIL get-thread THREAD_ID
```

**Send and reply:**

```bash
$GMAIL send --to "user@google.com" --subject "Hello" --body "Hi!"
$GMAIL send --to "a@g.com" --cc "b@g.com" --bcc "c@g.com" \
  --subject "plain text email" --body "just text"
$GMAIL send --to "a@g.com" --cc "b@g.com" --bcc "c@g.com" \
  --subject "html email" --html --body "html_content"
$GMAIL send-self --subject "Reminder" --body "Buy groceries"
$GMAIL send-self --subject "Log" --html --body "<h1>Success</h1>"
$GMAIL send --to "user@google.com" --subject "Update" --body "..." \
  --from "Team Alias <team@google.com>"
$GMAIL send-with-attachment --to "user@google.com" \
  --subject "Report" --body "See attached" --file /tmp/report.pdf
$GMAIL reply --message MESSAGE_ID --body "Thanks!"
$GMAIL reply --message MESSAGE_ID --body "Thanks!" --all
$GMAIL forward MESSAGE_ID "other@google.com"
```

**Drafts:**

```bash
$GMAIL create-draft --to "user@google.com" \
  --subject "Draft" --body "..."
# Add html flag to create a html email draft instead of raw text
$GMAIL create-draft --to "user@google.com" \
  --subject "html email" --html --body "<p>html_content</p>"
$GMAIL drafts --max 10
$GMAIL get-draft DRAFT_ID
$GMAIL update-draft DRAFT_ID --body "Updated body"
$GMAIL send-draft DRAFT_ID
$GMAIL delete-draft DRAFT_ID

# Create a threaded reply draft (auto-populates from original message)
$GMAIL create-draft --message MESSAGE_ID --body "Drafting a reply"

# Create a reply-all draft
$GMAIL create-draft --message MESSAGE_ID --all --body "Reply all draft"
```

**Labels and organization:**

```bash
$GMAIL labels
$GMAIL get-label LABEL_ID
$GMAIL create-label "MyLabel"
$GMAIL create-label "Parent/Child"       # Automatically creates Parent if missing
$GMAIL create-label "ColoredLabel" --bg-color red --text-color white
$GMAIL update-label LABEL_ID --bg-color "#f691b3" --text-color "#000000"
$GMAIL update-label LABEL_ID --name "New Name"
$GMAIL add-label MESSAGE_ID LABEL_ID
$GMAIL remove-label MESSAGE_ID LABEL_ID
$GMAIL delete-label LABEL_ID
$GMAIL mark-read MESSAGE_ID
$GMAIL mark-unread MESSAGE_ID
$GMAIL archive MESSAGE_ID
$GMAIL archive MESSAGE_ID1 MESSAGE_ID2   # archive multiple messages
$GMAIL archive --thread THREAD_ID        # archive all messages in a thread
$GMAIL trash MESSAGE_ID
$GMAIL thread-modify THREAD_ID --add STARRED --remove UNREAD
```

**Batch operations:**

```bash
$GMAIL batch-modify "MSG_ID1,MSG_ID2" --add-labels "LABEL1,LABEL2"
$GMAIL batch-modify "MSG_ID1,MSG_ID2" --remove-labels "LABEL1"
$GMAIL batch-delete "MSG_ID1,MSG_ID2" --confirm
```

**Filters and settings:**

```bash
$GMAIL list-filters
$GMAIL filter-create --from "news@example.com" --add-labels "LABEL_1,LABEL_2"
$GMAIL filter-update FILTER_ID --from "new_news@example.com"
$GMAIL filter-delete FILTER_ID
$GMAIL filter-search FILTER_ID
$GMAIL filter-search --from "news@example.com"
$GMAIL filter-apply FILTER_ID --dry-run
$GMAIL filter-apply --from "news@example.com" --add-labels "LABEL_1"
$GMAIL get-vacation
$GMAIL enable-vacation --subject "OOO" --body "I'm away until Monday"
$GMAIL disable-vacation
$GMAIL forwarding-addresses
$GMAIL get-autoforward
$GMAIL enable-autoforward --email "backup@google.com"
$GMAIL disable-autoforward
$GMAIL sendas
$GMAIL delegates
$GMAIL delegates --add "delegate@google.com"
$GMAIL delegates --remove "delegate@google.com"
$GMAIL history 12345
$GMAIL download-attachment MESSAGE_ID ATTACHMENT_ID /tmp/output.pdf
```

## Commands

Command                | Description
---------------------- | -------------------------------------------------------
`search`               | Search messages
`get`                  | Get full message
`read`                 | Search + read full messages
`threads`              | Search threads
`get-thread`           | Get full thread
`send`                 | Send email (supports `--from` for send-as aliases)
`send-self`            | Send an email to yourself
`reply`                | Reply to message
`forward`              | Forward a message
`send-with-attachment` | Send with file attachment
`create-draft`         | Create draft or threaded reply draft (with `--message`)
`send-draft`           | Send a draft
`get-draft`            | Get draft details
`update-draft`         | Update a draft
`delete-draft`         | Delete a draft
`labels`               | List labels
`get-label`            | Get label details
`drafts`               | List drafts
`trash`                | Trash a message
`mark-read`            | Mark as read
`mark-unread`          | Mark as unread
`download-attachment`  | Download attachment
`archive`              | Archive a message
`add-label`            | Add label to message
`remove-label`         | Remove label
`create-label`         | Create a label (supports nested labels and colors)
`update-label`         | Update a label (name or color)
`delete-label`         | Delete a label
`thread-modify`        | Modify thread labels
`batch-modify`         | Batch modify messages
`batch-delete`         | Batch delete messages
`history`              | List mailbox history
`list-filters`         | List filters
`filter-create`        | Create a filter
`filter-update`        | Update a filter (simulated via delete and recreate)
`filter-delete`        | Delete a filter
`filter-search`        | Search messages matching a filter's criteria
`filter-apply`         | Apply a filter's actions to existing conversations
`get-vacation`         | Get vacation responder status
`enable-vacation`      | Enable vacation responder
`disable-vacation`     | Disable vacation responder
`forwarding-addresses` | List forwarding addresses
`get-autoforward`      | Get auto-forwarding settings
`enable-autoforward`   | Enable auto-forwarding
`disable-autoforward`  | Disable auto-forwarding
`sendas`               | List send-as aliases
`delegates`            | List/add/remove delegates

## Gmail Search Syntax

Standard Gmail search operators work with `search`, `read`, `threads`,
`batch-modify`, and `batch-delete`:

-   `is:unread`, `is:starred`, `is:important`
-   `from:user@example.com`, `to:user@example.com`
-   `subject:keyword`
-   `after:2024/01/01`, `before:2024/12/31`
-   `has:attachment`
-   `label:LABEL_NAME`
-   `newer_than:1d`, `older_than:1w`

## Global Flags

-   `--json` — output as JSON (works with all read commands)

## Auth

Uses corp credentials with `gmail.modify` and `gmail.send` scopes via the Gmail
REST API. No OAuth tokens or API keys required.

## Reporting Issues

Report bugs at [Agent Skill: gmail](http://b/hotlists/8078359). See the
`skill_issue` skill for instructions on filing and triaging skill bugs.
