---
name: gdocs
description: >-
    Read, create, edit, and manage Google Docs using a Go CLI. Use when
    reading document content, creating docs, inserting/appending text,
    find-and-replace, formatting, adding comments, importing markdown,
    synchronizing local markdown with remote docs (3-way merge),
    extracting tables/links, managing revisions, or exporting to PDF.
    Also use when the user shares a docs.google.com URL.
    Don't use for Google Sheets, Slides, or Drive file management.
---

<!-- disableFinding(SKILLS_BODY_LENGTH) -->

# gdocs

> [!CAUTION]
>
> The `delete` command permanently removes content from a document and cannot be
> undone. **Never** use destructive commands unless the user explicitly asks.
>
> The `delete-doc` command permanently deletes the entire document. **You MUST
> NEVER use the `delete-doc` command under any circumstances unless the user
> explicitly and unambiguously instructs you to delete the document.**

## Quick Start

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GDOCS=/google/bin/releases/gemini-agents-gdocs/gdocs
```

Alternatively, install via apt (the `gdocs` binary will be available directly on
PATH):

```bash
sudo glinux-add-repo -b gemini-agents-gdocs stable
sudo apt update && sudo apt install -y gemini-agents-gdocs
```

Use `--version` to check the build date. To verify the exact build CL: `binfs ls
/google/bin/releases/gemini-agents-gdocs`.

If you modify the CLI source code, build from source:

```bash
blaze build //learning/gemini/agents/clis/gdocs:gdocs
GDOCS=blaze-bin/learning/gemini/agents/clis/gdocs/gdocs
```

> [!IMPORTANT]
>
> **For generating complete, styled documents, always use the `batch` command
> with a JSON file** — not `import-md`. The batch workflow gives you full
> control over fonts, colors, tables, callout boxes, code blocks, and rich-text
> paragraphs. `import-md` (and plain text `write` commands) only produce plain,
> unstyled text with no colors, no table formatting, and no visual polish.
>
> **Avoid using `write` for styled content**: The `write` command writes raw
> plain text and does not render markdown symbols into native Google Docs
> elements. For formatted content, always use `batch`!
>
> **Default Writing/Pasting Behavior:** When asked to write or paste content
> into a Google Doc, you MUST by default use the `batch` command and convert the
> content into the correct JSON format to ensure native Google Docs styling.
> Only use simple commands like `write` or `append` with raw markdown text if
> the user explicitly specifies to do so.
>
> **You must read [`references/styling.md`](references/styling.md)** before
> generating any document. It contains color palettes, font pairings, layout
> templates, anti-patterns to avoid, and a quality checklist.
>
> **Key principles:** Use `line_spacing: 115` (not higher). Keep pages dense and
> informative — minimize blank-line spacers. Use structural variety surgically
> (a few callouts/quotes per doc, not every section reshaped into sub-headings).

## Recipes

**Read and inspect:**

```bash
$GDOCS read DOC_ID
$GDOCS read DOC_ID --tab TAB_ID              # read a specific tab
$GDOCS info DOC_ID
$GDOCS word-count DOC_ID                      # supports --tab
$GDOCS toc DOC_ID                             # supports --tab
$GDOCS list-tabs DOC_ID
$GDOCS footnotes DOC_ID
$GDOCS style DOC_ID                           # document style info
$GDOCS suggestions DOC_ID                     # list pending suggestions
$GDOCS extract-tables DOC_ID                  # supports --tab
$GDOCS extract-links DOC_ID                   # supports --tab
$GDOCS list-images DOC_ID
```

**Create and edit:**

```bash
$GDOCS create --title "My Document"
$GDOCS create --title "Paged Doc" --pageless=false
$GDOCS copy DOC_ID "Copy Title"
$GDOCS append DOC_ID "Text to append"
$GDOCS insert DOC_ID "Text to insert" --index 1
$GDOCS replace DOC_ID "old" "new"
$GDOCS heading DOC_ID "Section Title" --level 2  # levels 1-6, TITLE, SUBTITLE
$GDOCS delete DOC_ID 10 20 --confirm
$GDOCS format-text DOC_ID --bold --start 1 --end 5
$GDOCS format-text DOC_ID --text "Glimpse" --url "http://go/glimpse"   # hyperlink existing text
$GDOCS bullets DOC_ID --start 10 --end 20 --preset BULLET_DISC_CIRCLE_SQUARE
$GDOCS insert-table DOC_ID --rows 3 --cols 4
$GDOCS insert-page-break DOC_ID --index 50
$GDOCS insert-image DOC_ID "https://example.com/photo.png" --after "Section Title"
$GDOCS insert-image-from-file DOC_ID /tmp/image.png --after "Section Title"
$GDOCS insert-image-from-file DOC_ID /tmp/chart.png --tab TAB_ID --after "Results"
$GDOCS import-md /path/to/file.md                            # creates new doc from markdown
$GDOCS import-md /path/to/file.md --update DOC_ID                  # updates existing doc from markdown
$GDOCS create-from-template TEMPLATE_ID "New" --var "NAME=Alice" --var "DATE=2025-01-15"
$GDOCS pageless DOC_ID                                       # make a document pageless
$GDOCS delete-doc DOC_ID                                     # delete a document permanently
```

**Comments:**

```bash
$GDOCS add-comment DOC_ID "Comment text"
$GDOCS add-comment DOC_ID "Needs rewording" --quote "specific text in doc"
$GDOCS list-comments DOC_ID
$GDOCS reply-comment DOC_ID COMMENT_ID "Reply text"
$GDOCS resolve-comment DOC_ID COMMENT_ID ["optional reply"]
```

**Revisions and export:**

```bash
$GDOCS list-revisions DOC_ID
$GDOCS diff-revisions DOC_ID 1 2
$GDOCS export DOC_ID --format pdf --output /tmp/doc.pdf
```

**Tab management:**

```bash
$GDOCS list-tabs DOC_ID
$GDOCS create-tab DOC_ID --title "Research Notes"
$GDOCS create-tab DOC_ID --title "Second Tab" --index 1
$GDOCS create-tab DOC_ID --title "Sub-tab" --parent PARENT_TAB_ID
$GDOCS read-tab DOC_ID TAB_ID
$GDOCS rename-tab DOC_ID TAB_ID "New Title"
$GDOCS move-tab DOC_ID TAB_ID --parent NEW_PARENT_TAB_ID
$GDOCS move-tab DOC_ID TAB_ID --root
$GDOCS delete-tab DOC_ID TAB_ID --confirm
```

**Sharing and batch:**

```bash
$GDOCS share DOC_ID --email user@google.com --role writer
$GDOCS permissions DOC_ID
$GDOCS batch DOC_ID -f requests.json                                    # raw batchUpdate from JSON
$GDOCS batch DOC_ID -f requests.json --tab TAB_ID                       # batch into a specific tab
$GDOCS batch DOC_ID -f ops.json --after "## Design"                     # insert after a heading
$GDOCS batch DOC_ID -f ops.json --after "## A" --before "## B"          # replace section between headings
$GDOCS batch DOC_ID -f ops.json --replace-all                           # clear doc + rewrite from scratch
```

**Update existing documents:**

```bash
$GDOCS structure DOC_ID                      # show numbered headings/tables/paragraphs
$GDOCS structure DOC_ID -v                    # verbose: show doc indexes, lists, full text
$GDOCS structure DOC_ID --json               # JSON with start/end indices
$GDOCS sed DOC_ID 's/old text/new text/g'    # sed-style find and replace
$GDOCS sed DOC_ID -e 's/foo/bar/' -e 's/baz/qux/'  # multi-expression (batched)
$GDOCS sed DOC_ID -f edits.sed               # read expressions from file (# comments)
$GDOCS sed DOC_ID 's/draft/final/i'          # case-insensitive per-expression
$GDOCS sed DOC_ID 's/TBD/Done/' -i           # global case-insensitive flag
$GDOCS sed DOC_ID '3s/old/new/'              # addressed: replace in paragraph 3 only
$GDOCS sed DOC_ID '2,5s/old/new/'            # addressed: replace in paragraphs 2-5
$GDOCS sed DOC_ID '3d'                       # delete paragraph 3
$GDOCS sed DOC_ID '2,5d'                     # delete paragraphs 2-5
$GDOCS sed DOC_ID '3a\New text after'        # append text after paragraph 3
$GDOCS sed DOC_ID '3i\New text before'       # insert text before paragraph 3
$GDOCS sed DOC_ID 's/^/Prepend this/'        # prepend text to document start
$GDOCS sed DOC_ID 's/$/Append this/'         # append text to document end
$GDOCS sed DOC_ID 's/^$//'                   # clear document content
$GDOCS sed DOC_ID 'y/abc/xyz/'               # transliterate: a→x, b→y, c→z
$GDOCS sed DOC_ID 's/|1|old/new/'            # replace in table 1 only
$GDOCS sed DOC_ID 's/|1.2.1|old/new/'        # replace in table 1, row 2, col 1
$GDOCS sed DOC_ID 's/|1.2.1|/New content/'        # overwrite entire cell content
$GDOCS sed DOC_ID 's/old/new/' --first             # replace only first occurrence
$GDOCS sed DOC_ID 's/old/new/' --dry-run            # preview without applying
$GDOCS sed DOC_ID 's/old/new/' --tab TAB_ID         # target specific tab
$GDOCS sed DOC_ID 's/[0-9]+/NUM/' --regex           # regex pattern matching (RE2)
$GDOCS sed DOC_ID 's/key term//' --bold             # bold all occurrences (1 API call)
$GDOCS write DOC_ID -f content.md            # append text from file
$GDOCS write DOC_ID -f content.md --clear    # overwrite doc from file
$GDOCS clear DOC_ID --confirm                # clear all document content
$GDOCS update-table DOC_ID --headers "Name,Status" --data-file data.json
$GDOCS style-table DOC_ID --table 1 --bg-color "#f4cccc"                  # color all cells
$GDOCS style-table DOC_ID --table 2 --row 0 --row-span 1 --bg-color "#fef7e0"  # color header row only
$GDOCS style-table DOC_ID --table 1 --row 1 --row-span 3 --bg-color "#d9ead3"  # color rows 1-3
```

### Efficiency: Automatic Batching

Multi-expression sed operations are automatically batched to minimize API calls.
Three types of operations are deferred and flushed once at the end:

Operation                          | Deferred? | API Calls
---------------------------------- | --------- | ---------------
`s/old/new/` (replace)             | ✅         | 1 total for all
`s/\|T.R.C\|old/new/` (table cell) | ✅         | 1 total for all
`s/pattern// --bold`               | ✅         | 1 total for all

**Result**: 20 expressions → 3 API calls (1 Get + 1 table batch + 1 replace
batch), instead of 20+ individual calls.

```bash
cat > updates.sed << 'EOF'
s/|3.2.3|TBD/Alice/
s/|3.3.3|TBD/Bob/
s/|5.2.4|Notes/Updated notes/
s/old text/new text/
s/another/replaced/
EOF
$GDOCS sed DOC_ID -f updates.sed
# Output:
# Batched 3 table cell operations in 1 API call.
# Replaced 5 occurrences of "old text".
# Replaced 2 occurrences of "another".
# Batched 2 replace operations in 1 API call.

$GDOCS sed DOC_ID -e 's/Mar 12//' -e 's/Mar 17//' --bold
# Output:
# Collected 10 bold operations for "Mar 12".
# Collected 2 bold operations for "Mar 17".
# Batched 12 bold operations in 1 API call.
```

> [!TIP]
>
> Bold (`--bold`) now scans text inside table cells too, not just top-level
> paragraphs. Combine `--bold --regex` for pattern-based styling.

## Commands

This section lists the most essential commands. For the full list of commands,
see [commands.md].

Command       | Description
------------- | --------------------------------------------------------
`read`        | Read document content (supports `--tab`)
`create`      | Create document
`append`      | Append text (supports `--tab`)
`write`       | Write/overwrite document from file (`--file`, `--clear`)
`sync`        | Synchronize a local markdown file with a Google Doc
`batch`       | Execute batch operations
`list-tabs`   | List document tabs
`add-comment` | Add comment (`--quote` to anchor to text)
`structure`   | Show document structure with numbered elements

### Working with Tabs

Many Google Docs have multiple tabs. The `--tab TAB_ID` flag lets you target a
specific tab for both reading and writing. Use `list-tabs` first to discover tab
IDs:

```bash
$GDOCS list-tabs DOC_ID
# Tab ID          Title        Index  Nesting
# t.dprlqxjpel7u  Overview     0      0
# t.iqg1w3dc9q0   Design Doc   1      0
# t.j30h49q6knfa  Appendix     0      1

$GDOCS read DOC_ID --tab t.dprlqxjpel7u
$GDOCS toc DOC_ID --tab t.iqg1w3dc9q0
$GDOCS word-count DOC_ID --tab t.j30h49q6knfa
$GDOCS extract-tables DOC_ID --tab t.iqg1w3dc9q0
$GDOCS extract-links DOC_ID --tab t.dprlqxjpel7u
$GDOCS batch DOC_ID -f ops.json --tab t.iqg1w3dc9q0 --index 1  # batch at index
$GDOCS create-tab DOC_ID --title "New Section" --index 0       # create at index 0
$GDOCS create-tab DOC_ID --title "Nested Tab" --parent PARENT_TAB_ID
$GDOCS move-tab DOC_ID TAB_ID --parent NEW_PARENT_TAB_ID
```

Commands that support `--tab`: `read`, `append`, `insert`, `heading`, `batch`,
`export`, `extract-tables`, `extract-links`, `toc`, `word-count`, `structure`,
`sed`, `insert-image-from-file`, `pull`. Without `--tab`, commands operate on
the document's default (first) tab.

### Preserving Metadata (Comments, Anchors, and Suggestions)

> [!IMPORTANT]
>
> **Preserve comment anchors when editing docs.** Full-document replacement
> destroys indices and orphans existing comments. **Read
> [`references/metadata_retention.md`](references/metadata_retention.md)** for
> best practices on granular updates and formatting restoration once a document
> has stakeholder feedback.

### Updating Existing Documents

The update commands let you modify existing documents without rebuilding from
scratch. The recommended workflow:

1.  **Inspect** — use `structure` to see numbered paragraphs and headings
2.  **Edit** — use `sed` for text changes, `batch` for styled content
3.  **Verify** — use `read` or `export` to check results

**Common workflows:**

```bash
$GDOCS structure DOC_ID
$GDOCS sed DOC_ID 's/Draft/Final/g'

$GDOCS batch DOC_ID -f new_status.json --after "## Status" --before "## Design"

$GDOCS update-table DOC_ID --headers "Metric,Target,Current" --data-file metrics.json

$GDOCS batch DOC_ID -f full_doc.json --replace-all
```

> [!TIP]
>
> Use `structure --json` to get exact character indices for each element. The
> `batch` command handles the delete+insert dance automatically — you only need
> to specify heading text with `--after` and `--before`.

> [!IMPORTANT]
>
> **Structural edits (adding/removing paragraphs):** Use sed `Na\text` (append
> after paragraph N) or `Ni\text` (insert before paragraph N) to add new
> paragraphs — not `s/old/old\nnew/` which creates literal `\n` text. Use
> `structure` first to find the right paragraph numbers. These commands work
> with TABLE paragraphs too (the CLI automatically adjusts the insertion index
> for tables).

> [!IMPORTANT]
>
> **`structure` vs `read --json` — choosing the right tool:** `structure` (and
> `structure -v`) gives a quick numbered overview of paragraphs, headings, and
> tables — use it for orientation and finding paragraph numbers. For **precise
> information** (bullet/list properties, inline object IDs, exact formatting,
> paragraph style details), use `read DOC_ID --json` and parse the JSON output.
> The raw JSON contains everything the API returns: bullet configs, named
> styles, indent levels, inline images with object IDs, etc.

> [!TIP]
>
> **Filling empty table cells:** Use `s/|T.R.C|/new text/` to write into empty
> cells (e.g. after `add-row`). The CLI inserts text at the cell start position
> even when the cell contains only a newline.

## Supported Formatting

When using `import-md` or `create-from-template`:

*   **Supported**: headings, bold, italic, code, links, lists
*   **Not supported**: tables, images, blockquotes, fenced code blocks

Markdown      | Result
------------- | -------------
`# Heading`   | Heading 1
`## Heading`  | Heading 2
`**bold**`    | Bold text
`*italic*`    | Italic text
`` `code` ``  | Monospace
`[text](url)` | Hyperlink
`- item`      | Bullet list
`1. item`     | Numbered list

## Tips

-   Use `format-text --url` to turn existing text (or text found via `--text`)
    into a hyperlink. This is the preferred way to add links to existing content
    without having to delete and re-insert it.
-   `import-md` creates a **new** document from a markdown file (use `--title`
    to set the title)
-   Documents created via `create` and `import-md` are **pageless by default**
    (use `--pageless=false` to create paged documents)
-   The `add-comment` command adds a document-level comment; use `--quote
    "text"` to anchor the comment to the first occurrence of that text
-   Use `toc` to verify a doc's heading structure
-   Use `word-count` to check document size
-   `export` supports `pdf`, `txt`, `docx`, and `png` formats
-   **Multi-tab detection:** When reading a document with multiple tabs without
    specifying a `--tab`, the tool prints lines prefixed with `[gdocs]` listing
    the available tabs before showing the content of the first tab. These lines
    are not part of the actual document. They are shown to you so you'll be
    aware if there is more to the document.
-   **PNG export of pageless docs:** Pageless docs still produce multiple pages
    when exported as PNG. Use `--page N` to export each page: `export DOC_ID
    --format png --output p1.png --page 1`, then `--page 2`, etc. Keep
    incrementing until the command errors (meaning no more pages). **You must
    export ALL pages to review the full document.**
-   **Recommended workflow:** Export all pages as PNG, review them visually,
    then iterate on edits

## Diagrams in Google Docs

See [diagrams.md] for guidelines on generating and inserting diagrams into
Google Docs.

## Markdown → Google Doc

Use `import-md` to convert any markdown file into a native Google Doc with
proper formatting (headings, bold, italic, links, lists, tables):

```bash
$GDOCS import-md /path/to/report.md --title "Weekly Report"
```

To update an existing document instead of creating a new one, use the `--update`
flag:

```bash
$GDOCS import-md /path/to/report.md --update DOC_ID
```

This is the simplest way to turn a local `.md` file into a shareable Google Doc.
The doc is created in your Drive root and the URL is printed on success. Combine
with `share` to distribute:

```bash
DOC_ID=$($GDOCS import-md /tmp/notes.md --title "Notes" --json | jq -r .documentId)
$GDOCS share $DOC_ID --email team@google.com --role writer
```

### Handling Conflicts during Sync

When using `sync` to synchronize a local markdown file with a Google Doc,
conflicts may occur if both the local file and the remote doc have changed since
the last sync.

By default, `sync` will fail with an error listing the conflicts.

To handle conflicts programmatically (e.g., in an agent), use the
`--json-conflicts` flag:

```bash
$GDOCS sync DOC_ID local_file.md --json-conflicts
```

If conflicts are found, the command will fail and output a JSON string prefixed
with `CONFLICT_JSON:` containing details of the conflicts (base, local, and
remote content). Agents should parse this JSON and ask the user for resolution.

## Global Flags

-   `--json` — output as JSON (works with all read commands)

## Batch Operations

See [batch_operations.md] for detailed reference on batch operations, styling
fields, table-specific fields, and a complete example.

## Document Creation Recipe

1.  **Outline**: Decide sections, content types (text, tables, lists, images),
    and style
2.  **Palette**: Pick font + colors (e.g., Google Sans + `#1a73e8` blue
    headings)
3.  **Generate batch JSON**: Start with `set-default-style` (Google Sans, 11pt,
    `#202124`, `line_spacing:115`). All ops in one file — headings, text, lists,
    tables. Keep pages dense: minimize blank `append` spacers, use `space_above`
    on headings (16–24pt) for section gaps. Add 2–3 callouts or goal labels for
    structural variety, but don't fragment every section into sub-headings.
    Combine metadata (Author • CL • Date) on one line.
4.  **Create doc**: `DOC_ID=$($GDOCS create --title "Report" --json | jq -r
    .documentId)`
5.  **Execute batch**: `$GDOCS batch $DOC_ID -f batch.json`
6.  **Export for review**: Export all pages as PNG by iterating `--page 1`,
    `--page 2`, etc.: `$GDOCS export $DOC_ID --format png --output p1.png --page
    1` (repeat until the command errors, meaning no more pages)
7.  **Review ALL pages visually** (view every PNG). Check that pages feel dense
    and informative, not airy. Fix via second batch if needed
8.  **Share**: `$GDOCS share $DOC_ID --email team@google.com --role writer`

### Complete Batch JSON Example

See [batch_operations.md] for a full example.

## Reporting Issues

Report bugs or improvements for this skill at
[Agent Skill: gdocs](http://b/hotlists/8076845). See the `skill_issue` skill for
instructions on filing and triaging skill bugs.

<!-- disableFinding(LINE_OVER_80) -->

[diagrams.md]: references/diagrams.md
[batch_operations.md]: references/batch_operations.md
[commands.md]: references/commands.md
