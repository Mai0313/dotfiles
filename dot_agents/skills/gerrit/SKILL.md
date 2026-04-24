---
name: gerrit
description: >-
  Interact with Gerrit Code Review. View CL diffs, metadata, comments,
  post review comments, search for changes, and manage reviewers/CCs.
  Use when working with Gerrit-hosted code reviews (Android, Chromium,
  Fuchsia, etc.) rather than Critique/Piper CLs.
---

# Gerrit

Interact with Gerrit using the `gerrit` CLI. View full diffs, CL metadata,
comments, list files, search changes, manage reviewers, and post review
comments.

> [!IMPORTANT]
>
> **MANDATORY: Multi-Host Context** Unlike Critique, which is a central system,
> **Gerrit has multiple hosts**. To list, query, or interact with an issue or
> CL, you *must* know and provide the correct `--host` parameter.

## Identifying metadata

If inside a git repo:

*   Identify the host: Use `git --no-pager config --get remote.origin.url` as
    `host`.
*   Identify the change: Use `git --no-pager log -n1` and use the `Change-ID`
    tag in the commit message as `change`.

## CLI Usage

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GERRIT=/google/bin/releases/gemini-agents-gerrit/gerrit
```

Alternatively, install via apt:

```bash
sudo glinux-add-repo -b gemini-agents-gerrit stable
sudo apt update && sudo apt install -y gemini-agents-gerrit
```

If you modify the CLI source code, build from source:

```bash
blaze build //learning/gemini/agents/clis/gerrit:gerrit
GERRIT=blaze-bin/learning/gemini/agents/clis/gerrit/gerrit
```

### View CL metadata

```bash
$GERRIT info --change=12345 --host=https://android-review.googlesource.com
```

### View CL diff

```bash
$GERRIT diff --change=12345 --host=https://android-review.googlesource.com

# For a specific revision/patchset
$GERRIT diff --change=12345 --revision=2 --host=https://android-review.googlesource.com
```

### List files in a change

```bash
$GERRIT files --change=12345 --host=https://android-review.googlesource.com
```

### Fetch static analysis findings for a Gerrit change

Fetch static analysis findings (e.g. Lint, AyeAye) for a Gerrit change. By
default, only actionable findings for the latest patchset are shown.

-   `--change`: The numeric change ID or the full Change-Id string.
-   `--host`: The Gerrit host URL.
-   `--all`: (Optional) Include non-actionable findings.
-   `--patchset`: (Optional) Filter by a specific patchset number.

Example:

```bash
$GERRIT findings --change=12345 --host=https://android-review.googlesource.com
# For a specific patchset
$GERRIT findings --change=12345 --patchset=2 --host=https://android-review.googlesource.com
```

> [!NOTE]
>
> This command fetches actionable findings from the internal Findings API. It is
> useful for identifying lint errors or other automated check failures
> associated with the change.

### View all comments

```bash
$GERRIT comments list --change=12345 --host=https://android-review.googlesource.com
```

> [!NOTE]
>
> Output iterates flat components grouped by file paths sorted by line numbers,
> but natively indents descendants to render threaded conversation hierarchies
> recursively.

### Post a draft comment

```bash
$GERRIT comments post \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --file=path/to/file.py \
  --line=10 \
  --message="Consider refactoring this block"

# Ranged inline comment (spans specific characters)
$GERRIT comments post \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --file=path/to/file.py \
  --start-line=10 --start-char=5 \
  --end-line=15 --end-char=10 \
  --message="Consider refactoring this block"
```

NOTE: This will post a *draft* comment to the CL. It will not be visible to
other users until it is published.

### Reply to a comment

```bash
$GERRIT comments reply \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --comment-id=a1b2c3d4 \
  --message="Done."

# Reply and mark thread as resolved
$GERRIT comments reply \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --comment-id=a1b2c3d4 \
  --message="Fixed." \
  --resolve

# Reply and mark thread as unresolved
$GERRIT comments reply \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --comment-id=a1b2c3d4 \
  --message="Fixed." \
  --resolve=false
```

NOTE: This will post a *draft* reply to the CL. It will not be visible to other
users until it is published.

### Publish comments

```bash
$GERRIT comments publish --change=12345 --host=https://android-review.googlesource.com

# Publish and add a review message
$GERRIT comments publish \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --message="Looks good to me!" \
  --notify=true

# Publish comments and add a Code-Review +1 label
$GERRIT comments publish \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --message="LGTM" \
  --lgtm

# Publish comments and add a Code-Review -1 label if there's a major issue
$GERRIT comments publish \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --message="There are major issues." \
  --reject
```

> [!CAUTION]
>
> This is a write action which MUST be explicitly authorized by the user before
> execution.

### List change messages

```bash
$GERRIT messages list --change=12345 --host=https://android-review.googlesource.com

# Filter by author
$GERRIT messages list --change=12345 --user=Prow_Bot_V2 --host=https://android-review.googlesource.com
```

### Post a change message

```bash
$GERRIT messages post --change=12345 --message="Great work!" --host=https://android-review.googlesource.com
```

### Manage Reviewers and CCs

```bash
$GERRIT reviewers add \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --reviewer=user1,user2 \
  --cc=user3 \
  --mdb=group1

# Add reviewers and mark a WIP/draft change as ready for review
$GERRIT reviewers add \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --reviewer=user1 \
  --ready

# Mark a change as ready for review without adding reviewers
$GERRIT reviewers add \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --ready

$GERRIT reviewers remove \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --reviewer=user1
```

## Attention Set in Gerrit

The Attention Set is Gerrit's feature to track "whose turn it is" to act on a
code review. A user remains in the attention set while the change requires their
review or action. Once they reply with a comment or approval, they are typically
removed from it. Within the Gerrit web UI, users in the attention set are
indicated by a bold name with an arrow icon.

### Manage Attention Set

```bash
# List who is currently in the attention set
$GERRIT attention --change=12345 --list --host=https://android-review.googlesource.com

# Add/remove users
$GERRIT attention \
  --change=12345 \
  --host=https://android-review.googlesource.com \
  --add=user1,user2 \
  --remove=user3 \
  --reason="needs review"
```

### Search for CLs

```bash
$GERRIT search --owner=johndoe@google.com --status=open --limit=5 --host=https://android-review.googlesource.com

# Use raw Gerrit queries:
$GERRIT search --query="status:open owner:johndoe@google.com" --limit=5 --host=https://android-review.googlesource.com

# Fetch changes requiring your turn (using Gerrit's Attention Set feature):
$GERRIT search --query="attention:self" --host=https://android-review.googlesource.com


```

#### Search Query Syntax

You can build your search using individual flags, or pass a raw query string via
`--query`. If both are provided, they are combined with logical AND.

**Common Query Atoms:**

*   `owner:username` - CL owner (author)
*   `reviewer:username` - CL reviewer
*   `project:name` - Affected project
*   `message:regexp` - CL description text
*   `status:open` - Pending/open CLs
*   `status:merged` - Submitted CLs
*   `mergedafter:date` - CLs merged after date (e.g. `2025-01-01`)
*   `mergedbefore:date` - CLs merged before date
*   `bug:regexp` - Associated bug ID
*   `attention:username` - Changes needing attention (e.g., `attention:self` for
    your turn)

**Date Search Flags** For convenience, you can use the built-in `--merged-after`
and `--merged-before` flags. Critique-style aliases `--submitted-after` and
`--submitted-before` map to these Gerrit merge dates:

```bash
# Find changes merged (submitted) after a date
$GERRIT search --owner=johndoe --merged-after="2025-01-01" --host=https://android-review.googlesource.com

# (Equivalent Critique style alias)
$GERRIT search --owner=johndoe --submitted-after="2025-01-01" --host=https://android-review.googlesource.com
```

### Fetch CRUAS Conversations

Fetch AI-assisted code review conversations from CRUAS for a given Gerrit
change. By default, conversations for the latest patchset of a change are shown.
You can optionally specify an older patchset.

-   `--change`: The numeric Gerrit change ID or the full Change-Id string.
-   `--host`: The Gerrit host URL (e.g. `android-review.git.corp.google.com`).
-   `--patchset`: (Optional) Filter by a specific patchset number.

Example:

```bash
$GERRIT conversations --change=12345 --host=https://android-review.googlesource.com
```

> [!NOTE]
>
> This command requires CRUAS permissions and uses your internal credentials to
> fetch data.

### Run CRUAS Code Review

Run a CRUAS code review for a Gerrit change. Use a specific capability or all
available ones.

-   `--change`: The numeric Gerrit change ID.
-   `--capability`: (Optional) The capability ID (e.g.,
    `personal-python-style-review`). If omitted, defaults to running all
    capabilities.
-   `--host`: The Gerrit host URL.

Example (specific capability):

```bash
$GERRIT review --change=12345 --capability=personal-python-style-review --host=https://android-review.googlesource.com
```

Example (all capabilities):

```bash
$GERRIT review --change=12345 --host=https://android-review.googlesource.com
```

> [!NOTE]
>
> This command calls the Gerrit backend to trigger AI reviews.

### List Available Capabilities

List available CRUAS capabilities for a given Gerrit change.

-   `--change`: The numeric Gerrit change ID.
-   `--host`: The Gerrit host URL.

Example:

```bash
$GERRIT capabilities --change=12345 --host=https://android-review.googlesource.com
```

## Common Gerrit Hosts

Different hosts might require different authentication scopes, but most common
ones are covered by standard internal credentials.

Host                   | URL
---------------------- | ----------------------------------------------------
**Android**            | `https://android-review.googlesource.com`
**Android (Internal)** | `https://googleplex-android-review.googlesource.com`
**Chromium**           | `https://chromium-review.googlesource.com`
**Chrome (Internal)**  | `https://chrome-internal-review.googlesource.com`
**Fuchsia**            | `https://fuchsia-review.googlesource.com`
**Googleplex**         | `https://googleplex-android-review.googlesource.com`
**GKE/GDC**            | `https://gke-internal-review.googlesource.com`

## Reporting Issues

Report bugs or improvements for this skill at
[Agent Skill: gerrit](http://b/hotlists/8077994). See the `skill_issue` skill
for instructions on filing and triaging skill bugs.
