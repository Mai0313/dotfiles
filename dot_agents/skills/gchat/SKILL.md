---
name: gchat
description: >-
    Read and send Google Chat messages, manage spaces, and react to messages
    using a Go CLI with Stubby RPC. Use when listing spaces, reading messages,
    sending messages or DMs, reacting with emoji, searching messages, managing
    space members, scheduling meetings, uploading files, downloading attachments,
    transcribing audio or video attachments, creating spaces, or marking
    conversations as read/unread. Supports custom emoji.
    Don't use for Gmail or Google Calendar.
    IMPORTANT: All write actions (send, edit, react, delete) MUST be explicitly
    authorized by the user before execution. Never send messages or DMs
    without the user's explicit permission.
---

# gchat

Read and send Google Chat messages from the command line via Stubby RPC.

> [!CAUTION] **All write actions (sending messages, DMs, reactions) MUST be
> explicitly authorized by the user before execution.** Never invoke write
> operations autonomously — always confirm the target space, recipient, and
> content with the user first. Read-only operations (`list-spaces`,
> `list-messages`, `get-direct-messages`) are safe to run without explicit
> permission.

> [!IMPORTANT] **Unattended mode (`AGY_UNATTENDED`)**: When the environment
> variable `AGY_UNATTENDED` is set (to any non-empty value), all write commands
> (`send-message`, `send-direct-message`, `edit-message`, `delete-message`,
> `create-reaction`, `upload-file`) are **hard-blocked** at the CLI level and
> will return an error. This prevents autonomous agents from sending messages
> without human oversight. Read-only operations remain available.

## Prerequisites

Uses LOAS/GaiaMint credentials via Stubby RPC. No additional setup needed when
running from Cloudtop.

## Quick Start

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GCHAT=/google/bin/releases/gemini-agents-gchat/gchat
```

Alternatively, install via apt (the `gchat` binary will be available directly on
PATH):

```bash
sudo glinux-add-repo -b gemini-agents-gchat stable
sudo apt update && sudo apt install -y gemini-agents-gchat
```

Use `--version` to check the build date. To verify the exact build CL: `binfs ls
/google/bin/releases/gemini-agents-gchat`.

If you modify the CLI source code, build from source:

```bash
blaze build //learning/gemini/agents/clis/gchat:gchat
GCHAT=blaze-bin/learning/gemini/agents/clis/gchat/gchat
```

## Recipes

**Browse spaces and messages:**

```bash
$GCHAT list-spaces
$GCHAT get-space SPACE_ID
$GCHAT list-members SPACE_ID
$GCHAT list-messages --space SPACE_ID --max 10
$GCHAT list-messages --space SPACE_ID --max 10 --hours 24
$GCHAT list-messages --space SPACE_ID --max 5 --order DESC
$GCHAT list-messages-by-thread --space SPACE_ID
$GCHAT read-thread --space SPACE_ID --thread THREAD
$GCHAT get-message --space SPACE_ID --thread THREAD --message MSG_ID
$GCHAT get-direct-messages --username user@google.com --max 20
$GCHAT search-messages --space_ids SPACE1,SPACE2 --query "keyword"
$GCHAT search-messages --query "from:me test"
$GCHAT search-messages --query "has:file keyword"
$GCHAT search-messages --query "before:2024-01-01 keyword"
```

**Send messages:**

```bash
$GCHAT send-message --space SPACE_ID --text "Hello!"
$GCHAT send-message --space SPACE_ID --text "Reply" --thread THREAD
$GCHAT send-message --space SPACE_ID --text "Quoted reply" --respond_to "THREAD_ID.MSG_SUFFIX"
$GCHAT send-direct-message --usernames user@google.com --text "Hey!"
$GCHAT edit-message --space SPACE_ID --message MSG_ID --text "Updated"
$GCHAT delete-message --space SPACE_ID --message MSG_ID
```

**Upload files as attachments:**

```bash
$GCHAT upload-file --space SPACE_ID --file /path/to/image.png
$GCHAT upload-file --space SPACE_ID --file /path/to/doc.pdf --text "Here's the report"
$GCHAT upload-file --space SPACE_ID --file /path/to/file.txt --thread THREAD_NAME
```

> [!NOTE] The `upload-file` command uses the Chat API REST endpoint
> (`media.upload`) with SSO OAuth credentials. It uploads the file directly as
> an inline attachment (up to 200 MB). Run `gcert` if you get auth errors.

> [!TIP] The `--file` flag accepts any filesystem path — it does NOT need to be
> inside the CitC workspace. CitC has a ~1 MB limit on binary files, so **never
> copy large images/files into CitC**. Instead, point `--file` directly at the
> original location (e.g. `~/image.png`, an artifacts dir, or
> `/tmp/generated.png`).

**Reactions (supports custom emoji):**

```bash
$GCHAT create-reaction --space SPACE_ID --message MSG_ID --emoji "👍"
$GCHAT create-reaction --space SPACE_ID --message MSG_ID --emoji ":custom-emoji:"
$GCHAT list-reactions --space SPACE_ID --message MSG_ID
$GCHAT delete-reaction --name "spaces/SPACE/messages/MSG/reactions/REACTION"
```

**Space management:**

```bash
$GCHAT create-space --display-name "My Space"
$GCHAT update-space --space SPACE_ID --display-name "New Name"
$GCHAT add-member --space SPACE_ID --user USER_ID
$GCHAT remove-member --space SPACE_ID --member MEMBER_ID
```

**Sections:**

```bash
$GCHAT list-sections
$GCHAT list-sections --json
$GCHAT create-section --display-name "My Projects"
$GCHAT update-section --section users/me/sections/SECTION_ID --display-name "Renamed"
$GCHAT delete-section --section users/me/sections/SECTION_ID
$GCHAT position-section --section users/me/sections/SECTION_ID --position 1
$GCHAT list-section-items --section users/me/sections/SECTION_ID
$GCHAT list-section-items --section users/me/sections/SECTION_ID --json
$GCHAT move-section-item --item users/me/sections/SRC/items/ITEM --target users/me/sections/DST
```

**Install a Chat app:**

```bash
$GCHAT install-app --project-number <GCP_PROJECT_NUMBER>
```

**Download attachments:**

```bash
$GCHAT download-attachment --space SPACE_ID --message THREAD.MSG --output /tmp/file.png
$GCHAT download-attachment --space SPACE_ID --message THREAD.MSG --output /tmp/file.png --index 1
```

**Transcribe audio/video attachments:**

When a user sends an audio or video message in Chat, use this two-step workflow
to download and transcribe it:

```bash
# Step 1: Download the attachment
$GCHAT download-attachment --space SPACE_ID --message THREAD.MSG --output /tmp/audio_message.ogg

# Step 2: Build the gmeet CLI first
blaze build //learning/gemini/agents/clis/gmeet
GMEET=blaze-bin/learning/gemini/agents/clis/gmeet/gmeet

# Step 3: Transcribe using gmeet (requires GEMINI_API_KEY)
$GMEET transcribe /tmp/audio_message.ogg
```

> [!TIP] The `gmeet transcribe` command supports WAV, OGG, MP3, FLAC, M4A, and
> WebM formats. Use `--json` for structured output or `--prompt` for a custom
> instruction (e.g., `--prompt "Summarize this voice message"`).

To identify which messages have audio/video attachments, use `--json` output and
look for attachments with `content_type` starting with `audio/` or `video/`:

```bash
$GCHAT list-messages --space SPACE_ID --max 10 --json | \
  jq '.[] | select(.attachments[]?.content_type | startswith("audio") or startswith("video"))'
```

**Read state:**

```bash
$GCHAT mark-unread --space SPACE_ID
$GCHAT mark-unread --username user@google.com
$GCHAT mark-unread --space SPACE_ID --message MSG_ID
$GCHAT mark-read --space SPACE_ID
$GCHAT mark-read --username user@google.com
$GCHAT mark-read --space SPACE_ID --message MSG_ID
$GCHAT get-read-state users/me/spaces/SPACE_ID/spaceReadState
$GCHAT get-thread-read-state users/me/spaces/SPACE_ID/threads/THREAD_ID/threadReadState
```

**Check unread messages across all spaces:**

```bash
$GCHAT inbox-report
$GCHAT inbox-report --json
$GCHAT inbox-report --hours 8
$GCHAT inbox-report --preview 3
$GCHAT inbox-report --output /tmp/unread.md
```

> [!NOTE] `inbox-report --json` returns an array of objects with these fields:
> `space_id`, `display_name`, `space_type`, `last_read_time`,
> `last_message_time`, and `preview[]` (each item has `create_time`, `text`,
> `sender.display_name`). Use `--hours N` to restrict results to spaces that
> received a message in the last N hours (default 0 = all unread spaces).

**List @mentions across all spaces:**

```bash
$GCHAT list-mentions
$GCHAT list-mentions --hours 24
$GCHAT list-mentions --max 20
$GCHAT list-mentions --json
$GCHAT list-mentions --output /tmp/mentions.md
```

**Notification settings:**

```bash
$GCHAT get-notification-setting users/me/spaces/SPACE_ID/spaceNotificationSetting
$GCHAT update-notification-setting users/me/spaces/SPACE_ID/spaceNotificationSetting --mute MUTED
$GCHAT update-notification-setting users/me/spaces/SPACE_ID/spaceNotificationSetting --mute UNMUTED
```

**Custom emojis:**

```bash
$GCHAT list-custom-emojis
$GCHAT get-custom-emoji customEmojis/:my-emoji:
$GCHAT create-custom-emoji --name :my-emoji: --file image.png
$GCHAT delete-custom-emoji customEmojis/:my-emoji:
```

**Member management:**

```bash
$GCHAT get-member spaces/SPACE_ID/members/MEMBER_ID
$GCHAT update-member spaces/SPACE_ID/members/MEMBER_ID --role ROLE_MANAGER
```

**Space events:**

```bash
$GCHAT get-space-event spaces/SPACE_ID/spaceEvents/EVENT_ID
$GCHAT list-space-events spaces/SPACE_ID --filter 'eventTypes:"google.workspace.chat.message.v1.created"'
```

**Search:**

```bash
$GCHAT search-spaces 'customer = "customers/my_customer" AND space_type = "SPACE"'
```

**Watch for new messages (polling-based):**

```bash
$GCHAT watch --space SPACE_ID
$GCHAT watch --space SPACE_ID --interval 10
$GCHAT subscribe --space SPACE_ID --command cat
$GCHAT subscribe --space SPACE_ID --command ./process.sh --interval 10
```

**Bot configuration**

```bash
$GCHAT get-bot-config PROJECT_NUMBER
$GCHAT set-bot-name PROJECT_NUMBER "New Bot Name"
$GCHAT set-bot-avatar PROJECT_NUMBER "https://url.to/your/avatar.png"
```

## Sharing Drive Files

When requested to share a Google Drive file in a Chat space using
`send-message`, you **MUST** ensure the space members have access to the file.

**Shortcut for Named Spaces:** You can use the `share-doc` command to
automatically grant access to a document for a named Chat space (type `SPACE`).
`bash $GCHAT share-doc SPACE_ID DOC_ID` *Note: This command automatically
resolves the space's roster email and calls `gdrive share` for you. It does NOT
currently support DMs or Group Chats.*

For manual sharing or DMs, follow the native Google Chat "ACL fixer" workflow:

1.  **Ask for Permission:** Explicitly ask the user if they want you to share
    the Drive file with the space members and update the file's ACLs.
2.  **Verify Sharing Permissions:** Run `$GDRIVE permissions FILE_ID`.
    *   First, check if the user requesting this action has `writer` or `owner`
        role in the output. If they only have `reader` or `commenter` access, do
        NOT attempt to share the file. Inform them that they do not have
        sufficient permissions to share the file, and **proceed directly to Step
        6** to send the message anyway.
3.  **Determine Space Type:** Run `$GCHAT get-space SPACE_ID` and check the
    `space_type`.
4.  **Resolve Targets & Check Existing Access:**
    *   If `space_type` is `SPACE` (a named room):
        *   Run `$GCHAT get-space-email spaces/SPACE_ID` to get the
            `roster_email`.
        *   The target is the single `roster_email`.
    *   If `space_type` is `GROUP_CHAT` (unnamed DM) or `DIRECT_MESSAGE` (1:1
        DM):
        *   Run `$GCHAT list-members spaces/SPACE_ID`.
        *   For each human member, extract the numeric `<id>` from the
            `users/<id>` member name.
        *   Run `/google/bin/releases/gemini-agents-gcontacts/gcontacts get <id>
            --json`. Look at the returned JSON under `person.email[0].value` to
            find their email address. Do NOT run `gcontacts search`. You must
            use `get` with the numeric ID.
        *   The targets are the individual member emails.
    *   **Crucial:** Look at the `$GDRIVE permissions FILE_ID` output you
        fetched earlier to see if the resolved target(s) already have access. If
        all expected targets are listed, skip step 5.
5.  **Grant Access:** Use your `$GDRIVE share` skill with the resolved target(s)
    to grant access. **You MUST pass `--notify=false` to avoid spamming members,
    and use `--role commenter` by default (unless the user explicitly asked to
    make them an editor/writer).**
6.  **Send Message:** Finally, send the chat message with the Drive link.

## CLI Reference

### Read Commands

Command                   | Required Flags                     | Optional Flags                                               | Description
------------------------- | ---------------------------------- | ------------------------------------------------------------ | -----------
`list-spaces`             |                                    | `--filter-type`, `--query`                                   | List all accessible spaces
`get-space`               | `SPACE_ID` (positional)            |                                                              | Get details for a space
`get-space-email`         | `SPACE_ID` (positional)            |                                                              | Get space roster email
`list-members`            | `SPACE_ID` (positional)            |                                                              | List members of a space
`list-messages`           | `--space`                          | `--max` (25), `--order`, `--hours` (720)                     | List recent messages
`list-messages-by-thread` | `--space`                          | `--max` (100), `--hours` (720)                               | List messages grouped by thread
`read-thread`             | `--space`, `--thread`              |                                                              | Read all messages in a thread
`get-message`             | `--space`, `--thread`, `--message` |                                                              | Get a single message by ID
`get-direct-messages`     | `--username`                       | `--max` (25)                                                 | Get direct messages by email or LDAP
`search-messages`         | `--query` or `--queries`           | `--space_ids`, `--max` (100)                                 | Server-side search via SearchMessagesV2
`inbox-report`            |                                    | `--workers` (20), `--preview` (1), `--hours` (0), `--output` | Show all spaces with unread messages
`list-mentions`           |                                    | `--max` (50), `--hours` (168), `--output`                    | Search for @mentions of the current user

### Write Commands

| Command               | Required Flags   | Optional Flags    | Description   |
| --------------------- | ---------------- | ----------------- | ------------- |
| `send-message`        | `--space`,       | `--thread`,       | Send a        |
:                       : `--text`         : `--respond_to`,   : message,      :
:                       :                  : `--markdown`      : optionally to :
:                       :                  :                   : a thread or   :
:                       :                  :                   : as a quote    :
| `send-direct-message` | `--usernames`,   | `--thread`        | Send a direct |
:                       : `--text`         :                   : message (1\:1 :
:                       :                  :                   : or group)     :
| `edit-message`        | `--space`,       |                   | Edit an       |
:                       : `--message`,     :                   : existing      :
:                       : `--text`         :                   : message       :
| `delete-message`      | `--space`,       |                   | Delete a      |
:                       : `--message`      :                   : message       :
| `upload-file`         | `--space`,       | `--text`,         | Upload a file |
:                       : `--file`         : `--thread`        : to a space    :
| `create-reaction`     | `--space`,       |                   | Add an emoji  |
:                       : `--message`,     :                   : reaction      :
:                       : `--emoji`        :                   :               :
| `list-reactions`      | `--space`,       |                   | List          |
:                       : `--message`      :                   : reactions on  :
:                       :                  :                   : a message     :
| `delete-reaction`     | `--name`         |                   | Delete a      |
:                       :                  :                   : reaction by   :
:                       :                  :                   : resource name :
| `create-space`        | `--display-name` |                   | Create a new  |
:                       :                  :                   : named space   :
| `update-space`        | `--space`        | `--display-name`, | Update space  |
:                       :                  : `--description`   : metadata      :
| `add-member`          | `--space`,       |                   | Add a user to |
:                       : `--user`         :                   : a space       :
| `remove-member`       | `--space`,       |                   | Remove a      |
:                       : `--member`       :                   : member from a :
:                       :                  :                   : space         :
| `share-doc`           | `SPACE_ID`,      |                   | Share a       |
:                       : `DOC_ID`         :                   : Google Doc    :
:                       : (positional)     :                   : with a named  :
:                       :                  :                   : space         :
| `download-attachment` | `--space`,       | `--index` (0)     | Download a    |
:                       : `--message`,     :                   : file          :
:                       : `--output`       :                   : attachment    :
:                       :                  :                   : via           :
:                       :                  :                   : ByteStream    :
| `mark-unread`         | `--space` or     | `--message`       | Mark a space  |
:                       : `--username`     :                   : or DM as      :
:                       :                  :                   : unread, or    :
:                       :                  :                   : from a        :
:                       :                  :                   : specific      :
:                       :                  :                   : message       :
| `mark-read`           | `--space` or     | `--message`       | Mark a space  |
:                       : `--username`     :                   : or DM as      :
:                       :                  :                   : read, or up   :
:                       :                  :                   : to a specific :
:                       :                  :                   : message       :
| `install-app`         | `--project-      |                   | Install a     |
:                       : number`          :                   : Chat app by   :
:                       :                  :                   : creating a DM :
:                       :                  :                   : with the bot  :
| `list-sections`       |                  |                   | List Chat     |
:                       :                  :                   : sections      :
| `create-section`      | `--display-name` |                   | Create a      |
:                       :                  :                   : custom        :
:                       :                  :                   : section       :
| `delete-section`      | `--section`      |                   | Delete a      |
:                       :                  :                   : custom        :
:                       :                  :                   : section       :
| `update-section`      | `--section`,     |                   | Rename a      |
:                       : `--display-name` :                   : custom        :
:                       :                  :                   : section       :
| `position-section`    | `--section`,     |                   | Reposition a  |
:                       : `--position`     :                   : section       :
| `list-section-items`  | `--section`      |                   | List spaces   |
:                       :                  :                   : in a section  :
| `move-section-item`   | `--item`,        |                   | Move a space  |
:                       : `--target`       :                   : to a          :
:                       :                  :                   : different     :
:                       :                  :                   : section       :
| `get-read-state`      | NAME (arg)       |                   | Get unread    |
:                       :                  :                   : state for a   :
:                       :                  :                   : space         :
| `get-thread-read-     | NAME (arg)       |                   | Get unread    |
: state`                :                  :                   : state for a   :
:                       :                  :                   : thread        :
| `get-notification-    | NAME (arg)       |                   | Get           |
: setting`              :                  :                   : notification  :
:                       :                  :                   : setting       :
| `update-notification- | NAME (arg),      |                   | Mute/unmute a |
: setting`              : `--mute`         :                   : space         :
| `list-custom-emojis`  |                  |                   | List all      |
:                       :                  :                   : custom emojis :
| `get-custom-emoji`    | NAME (arg)       |                   | Get a custom  |
:                       :                  :                   : emoji         :
| `create-custom-emoji` | `--name`,        |                   | Create a      |
:                       : `--file`         :                   : custom emoji  :
| `delete-custom-emoji` | NAME (arg)       |                   | Delete a      |
:                       :                  :                   : custom emoji  :
| `get-member`          | NAME (arg)       |                   | Get member    |
:                       :                  :                   : details       :
| `update-member`       | NAME (arg),      |                   | Change member |
:                       : `--role`         :                   : role          :
| `get-space-event`     | NAME (arg)       |                   | Get a space   |
:                       :                  :                   : event         :
| `list-space-events`   | SPACE (arg),     |                   | List space    |
:                       : `--filter`       :                   : events        :
| `search-spaces`       | QUERY (arg)      |                   | Search spaces |
:                       :                  :                   : (admin only)  :
| `watch`               | `--space`        | `--interval` (5)  | Poll a space  |
:                       :                  :                   : for new       :
:                       :                  :                   : messages      :
| `subscribe`           | `--space`,       | `--interval` (5)  | Run a command |
:                       : `--command`      :                   : on each new   :
:                       :                  :                   : message       :

All commands support `--json` for structured JSON output.

## Search Operators

The `search-messages` command supports standard Google Chat search operators in
the `--query` string:

*   **Users**: `from:me`, `from:user@google.com`, `at:me` (mentions you),
    `at:user@google.com`
*   **Attachments**: `has:file`, `has:doc`, `has:sheet`, `has:slide`, `has:pdf`,
    `has:video`, `has:image`
*   **URLs**: `has:url`
*   **Type**: `is:dm` (Direct Messages), `is:room` (Spaces)
*   **Read State**: `is:unread`
*   **Time Filters**: `before:YYYY-MM-DD`, `after:YYYY-MM-DD`, `older_than:2d`,
    `newer_than:1y`

Example: `$GCHAT search-messages --query "from:me has:url newer_than:7d"`

## Chat URL Structure

Chat URLs follow the pattern:

```
https://chat.google.com/room/SPACE_ID/THREAD_ID/MSG_SUFFIX
```

| URL Component          | CLI Usage                                         |
| ---------------------- | ------------------------------------------------- |
| `SPACE_ID`             | `--space SPACE_ID`                                |
| `THREAD_ID`            | `--thread THREAD_ID`                              |
| `THREAD_ID/MSG_SUFFIX` | `--message THREAD_ID.MSG_SUFFIX` or `--respond_to |
:                        : THREAD_ID.MSG_SUFFIX`                             :

**Example:** To respond to
`chat.google.com/room/AAAAkKaAVtY/2MLjLSl3rqA/USphHaWk4jk`:

```bash
$GCHAT send-message \
    --space AAAAkKaAVtY \
    --text "<response>" \
    --respond_to "2MLjLSl3rqA.USphHaWk4jk"
```

Use `list-spaces` to find space IDs programmatically. For DMs, use
`get-direct-messages --username user@google.com`.

## Message Formatting

By default, Google Chat does **not** use standard Markdown for text messages.
Use the following specific syntax:

*   **Bold**: `*text*`
*   **Italic**: `_text_`
*   **Strikethrough**: `~text~`
*   **Inline Code**: `` `text` ``
*   **Code Block**: ` ``text`` `
*   **Links**: `<https://example.com|Display Text>` or plain
    `https://example.com`
*   **User Mentions**: `<users/user_id>` or `<users/emailAlias@google.com>` or
    `<users/all>`

To send messages using standard CommonMark markdown, use the `--markdown` flag
with `send-message`. Note that this feature is currently `UNDER_DEVELOPMENT`.

## Rich Content in Messages

Google Chat messages may include rich content beyond plain text, such as linked
resources (e.g. Drive files), file attachments, and interactive cards. The CLI
extracts this content into structured JSON fields on the message object (with
`--json`):

*   **`attachments`**: Array of `{name, content_name, content_type, source,
    drive_file_id, download_uri}`. Files attached to the message (images, audio,
    documents). Use `drive_file_id` to interact with the file via the `gdrive`
    skill.
*   **`annotations`**: Array of `{type, uri}`. Rich links embedded in the
    message text (e.g. Drive file smart chips). The `type` field (e.g.
    `DRIVE_FILE`) is included when available.
*   **`cards`**: Array of `{title, subtitle, sections}`. Structured card
    messages (often sent by bots). Each section has `{header, widgets}` where
    `widgets` is an array of extracted text strings.

For example, a bot message with a card appears in JSON as:

```json
{
  "text": "",
  "cards": [{
    "title": "Build Status",
    "subtitle": "Project X",
    "sections": [{
      "header": "Results",
      "widgets": ["PASSED: 42 tests", "FAILED: 2 tests"]
    }]
  }]
}
```

All three fields use `omitempty`, so they are absent when there is no rich
content.

## Custom Emoji

Custom emoji use `:emoji-name:` shortcode syntax in message text. Names must be
lowercase alphanumeric with hyphens/underscores. Standard unicode emoji (😀, 👍)
work directly without special syntax.

```bash
$GCHAT send-message --space SPACE_ID \
  --text "Nice work :party-parrot:"
$GCHAT create-reaction --space SPACE_ID \
  --message MSG_ID --emoji ":cat-clap:"
```

## Adding Members to Spaces

> [!IMPORTANT] The `CreateMembership` API is **not callable via LOAS/Stubby** —
> both the Chat API and Dynamite Frontend RpcSecurityPolicies block LOAS for
> membership mutations. Adding members requires user-assisted steps.

### Step 1: Generate the member email list

Use the CLI to resolve Gaia user IDs to email addresses:

```bash
blaze run //learning/gemini/agents/skills/gchat:resolve_space_emails -- --file /tmp/user_ids.txt > /tmp/emails.csv
```

### Step 2: Add members (user chooses method)

**Option A: "Bulk Member Manager" Chat App (recommended for large lists)**

1.  The user adds the **Bulk Member Manager** app to the target space
2.  The user sends a message with the `/addCsv` slash command and **attaches the
    CSV file** to that same message

**Option B: Browser "Add people" dialog**

1.  The user opens the target space in Google Chat (browser)
2.  Clicks the space name → "Manage members" → "Add"
3.  Pastes the comma-separated email list into the "Add people" field

## Scheduling Meetings for Space Members

To schedule a meeting with all HUMAN members of a Google Chat space:

### Step 1: Resolve attendee emails

Run the bundled script to get a comma-separated list of emails for all members
in the space:

> [!NOTE] Using `blaze run` is intentional here. The `resolve_space_emails`
> script is a workspace-level helper that glues together `gchat` and `gcontacts`
> capabilities to resolve emails.

```bash
blaze run //learning/gemini/agents/skills/gchat:resolve_space_emails -- --space SPACE_ID > /tmp/emails.csv
```

### Step 2: Create Calendar Invite

Use the `gcalendar` skill to create the event. Prompt the user for `Summary`,
`Time`, and `Location` (e.g., a GVC meeting link or room).

```bash
$GCALENDAR create \
  --summary "Meeting Title" \
  --start "2026-04-01T11:00:00-07:00" \
  --end "2026-04-01T12:00:00-07:00" \
  --location "go/meet/id" \
  --attendees "$(cat /tmp/emails.csv)"
```

### Step 3: Post Confirmation

Post a message back to the space confirming the meeting. Include the meeting
link and optionally utilize any custom emojis preferred by the user.

```bash
$GCHAT send-message \
  --space SPACE_ID \
  --text "🗓️ Meeting scheduled: <https://calendar.google.com/calendar/|Invite Sent>"
```

## Auth

Uses LOAS/GaiaMint credentials via Stubby RPC. No additional setup needed on
Cloudtop.

## Reporting Issues

Report bugs or improvements for this skill at
[Agent Skill: gchat](http://b/hotlists/8078102). See the `skill_issue` skill for
instructions on filing and triaging skill bugs.
