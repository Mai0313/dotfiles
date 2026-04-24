# gdocs — Agent E2E Test Plan

## Prerequisites

**Read `SKILL.md` first** to understand available commands, flags, and expected
behavior.

Prefer the pre-built binary:

```bash
GDOCS=/google/bin/releases/gemini-agents-gdocs/gdocs
```

Or build from source:

```bash
blaze build //learning/gemini/agents/clis/gdocs:gdocs
GDOCS=blaze-bin/learning/gemini/agents/clis/gdocs/gdocs
```

--------------------------------------------------------------------------------

## Test 1: Pre-built binary available

```bash
/google/bin/releases/gemini-agents-gdocs/gdocs --help
```

**Verify:** Help output is shown (binary exists and runs).

--------------------------------------------------------------------------------

## Test 1b: CLI builds from source

```bash
blaze build //learning/gemini/agents/clis/gdocs:gdocs
```

**Verify:** Build succeeds (exit code 0).

--------------------------------------------------------------------------------

## Test 2: Unit tests pass

```bash
blaze test //learning/gemini/agents/clis/gdocs:gdocs_test
```

**Verify:** All tests pass (exit code 0).

--------------------------------------------------------------------------------

## Test 3: Help output

```bash
$GDOCS --help
```

**Verify:**

-   Output lists available subcommands
-   Commands include `read`, `create`, `append`, `format-text`, `batch`,
    `create-tab`, `delete-tab`, `rename-tab`, `read-tab`

--------------------------------------------------------------------------------

## Test 4: Create a new document

**Prompt:** "Create a new Google Doc called 'Test Document'."

**Verify:**

-   Document is created and ID is returned
-   Confirmation includes the document title

--------------------------------------------------------------------------------

## Test 5: Write and read content

**Prompt:** "Add the text 'Hello from the CLI' to that document, then show me
its contents."

**Verify:**

-   Text appears in the document content
-   Read output contains 'Hello from the CLI'

--------------------------------------------------------------------------------

## Test 6: Find and replace text

**Prompt:** "Replace the word 'Hello' with 'Hi' in that document."

**Verify:**

-   Replacement succeeds
-   Reading the document shows 'Hi from the CLI'

--------------------------------------------------------------------------------

## Test 7: Add a heading

**Prompt:** "Add a level 2 heading 'Section Title' to that document."

**Verify:**

-   Command succeeds without error

--------------------------------------------------------------------------------

## Test 8: Add and list comments

**Prompt:** "Add a comment saying 'This is a test comment' to that document,
then show me all comments on it."

**Verify:**

-   Comment is added successfully
-   Comment list includes the test comment

--------------------------------------------------------------------------------

## Test 9: Get document info

**Prompt:** "Show me the metadata and information about that document."

**Verify:**

-   Output includes document title, ID, and revision info

--------------------------------------------------------------------------------

## Test 10: Export document

**Prompt:** "Export that document as a PDF file."

**Verify:**

-   PDF file is created successfully
-   File size is non-zero

--------------------------------------------------------------------------------

## Test 11: JSON output format

**Prompt:** "Show me the metadata about that document in JSON format."

**Verify:**

-   Output is valid JSON
-   Contains document title and ID

--------------------------------------------------------------------------------

## Test 12: Comment lifecycle

**Prompt:** "Add a comment, list all comments, then resolve the comment."

**Verify:**

-   Comment is added with comment ID returned
-   Comment appears in list-comments output
-   Comment is resolved successfully

--------------------------------------------------------------------------------

## Test 13: Import markdown

**Prompt:** "Create a new document from this markdown content:
'# Heading\n\nParagraph text'"

**Verify:**

-   New document is created from markdown
-   Document content includes the heading and paragraph

--------------------------------------------------------------------------------

## Test 14: Batch operations - styled document

**Prompt:** "Create a new document and apply this batch JSON to it."

```json
[
  {"op":"set-default-style","font_family":"Google Sans","font_size":11,"text_color":"#202124"},
  {"op":"heading","text":"Test Heading","level":"1","font_size":24,"text_color":"#1a73e8"},
  {"op":"append","text":"Body text with styling","bold":true},
  {"op":"bullet-list","text":"First item"},
  {"op":"numbered-list","text":"Step one"},
  {"op":"horizontal-rule"},
  {"op":"page-break"},
  {"op":"link","text":"Google","url":"https://google.com","text_color":"#1a73e8"},
  {"op":"rich-text","runs":[{"text":"Bold part ","bold":true},{"text":"normal part"}]}
]
```

**Verify:**

-   Batch executes without error
-   Output reports all operations executed
-   Export to PNG shows styled content

--------------------------------------------------------------------------------

## Test 15: Insert and style a table

**Prompt:** "Create a table with headers and styling."

```json
[
  {"op":"insert-table","rows":3,"cols":3,
   "table_data":[["Name","Role","Status"],["Alice","SWE","Active"],["Bob","TPM","Done"]],
   "table_header_bold":true,"table_header_bg_color":"#e8f0fe",
   "table_header_text_color":"#1a73e8",
   "table_font_family":"Roboto","table_font_size":9,
   "table_col_widths":[150,100,80],
   "table_border_color":"#dadce0","table_border_width":0.5,
   "table_cell_colors":[["","",""],["","","#d9ead3"],["","","#f4cccc"]]}
]
```

**Verify:**

-   Table is inserted with data populated
-   Header row has blue background and bold text
-   Cell colors are applied correctly

--------------------------------------------------------------------------------

## Test 16: Format text with multiple flags

**Prompt:** "Format text in the document at range 1-10 with bold, italic,
underline, and font size 14."

```bash
$GDOCS format-text DOC_ID --start 1 --end 10 --bold --italic --underline --font-size 14
```

**Verify:**

-   Command succeeds with 'Text formatted' output

--------------------------------------------------------------------------------

## Test 17: Insert image

**Prompt:** "Insert an image into that document."

```bash
$GDOCS insert-image DOC_ID https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png
```

**Verify:**

-   Image is inserted successfully

--------------------------------------------------------------------------------

## Test 18: Tab operations

**Prompt:** "Create a new tab, create a child tab under it, list tabs, move the
child tab to root, read the tab, rename it, then delete them."

```bash
$GDOCS create-tab DOC_ID --title "Parent Tab"
$GDOCS create-tab DOC_ID --title "Child Tab" --parent PARENT_TAB_ID
$GDOCS list-tabs DOC_ID
$GDOCS move-tab DOC_ID CHILD_TAB_ID --root
$GDOCS list-tabs DOC_ID
$GDOCS read-tab DOC_ID CHILD_TAB_ID
$GDOCS rename-tab DOC_ID CHILD_TAB_ID "Renamed Tab"
$GDOCS delete-tab DOC_ID CHILD_TAB_ID --confirm
$GDOCS delete-tab DOC_ID PARENT_TAB_ID --confirm
```

**Verify:**

-   Tabs are created and IDs are returned
-   Tab appears in list-tabs output
-   Child tab appears at root level in the second list-tabs output
-   Tab content can be read
-   Tab is renamed successfully
-   Tabs are deleted successfully

--------------------------------------------------------------------------------

## Test 19: Word count and extract commands

```bash
$GDOCS word-count DOC_ID
$GDOCS extract-tables DOC_ID
$GDOCS extract-links DOC_ID   # Now extracts from tables recursively
$GDOCS list-images DOC_ID
```

**Verify:**

-   Word count returns words, characters, lines
-   Extract commands return data or empty results without error

--------------------------------------------------------------------------------

## Test 20: Share document

```bash
$GDOCS share DOC_ID --email user@google.com --role writer
$GDOCS permissions DOC_ID
```

**Verify:**

-   Share succeeds with permission ID returned
-   Permissions list includes the shared user

--------------------------------------------------------------------------------

## Test 21: Batch with tabs

**Prompt:** "Run a batch operation on a specific tab."

```bash
$GDOCS batch DOC_ID -f batch.json --tab TAB_NAME
```

**Verify:**

- Batch operations execute on the specified tab
- Output reports operations completed

--------------------------------------------------------------------------------

## Test 22: Batch with index (In-place insertion)

**Prompt:** "Insert a status heading at index 1 of the document."

```bash
$GDOCS batch DOC_ID -f status.json --index 1
```

**Verify:**

- Document starts with the content from `status.json`
- Other content is shifted forward

--------------------------------------------------------------------------------

## Test 23: Table with hyperlinks

**Prompt:** "Create a table where one cell is a hyperlink."

```json
[
  {"op":"insert-table","rows":2,"cols":2,
   "table_data":[["Item","Link"],["CL","879854378"]],
   "table_cell_urls":[["",""],["","http://cl/879854378"]],
   "table_cell_text_colors":[["",""],["","#1155cc"]]}
]
```

**Verify:**

- Table contains the link in the specified cell
- `extract-links` identifies the URL in the table

--------------------------------------------------------------------------------

## Test 24: Pull with tab

**Prompt:** "Pull the contents of tab 'tab2' from that document into a local
markdown file."

```bash
$GDOCS pull DOC_ID output.md --tab tab2
```

**Verify:**

-   Markdown file is created and contains the content of the specified tab

--------------------------------------------------------------------------------

## Test 25: Batch with date chips

**Prompt:** "Insert a date chip into the document."

```json
[
  {
    "op": "rich-text",
    "runs": [
      {"text": "Today's date: "},
      {"date": "2026-04-17T12:00:00Z"}
    ]
  }
]
```

**Verify:**

- Batch operations execute without error
- Output reports operations completed
- Document contains the date chip

--------------------------------------------------------------------------------

## Test 26: Default behavior when pasting (Use batch)

**Prompt:** "Paste this list into a new Google Doc: 1. Item A\n2. Item B"

**Verify:**

- The agent uses the `batch` command to create a styled document with a native list.
- The agent does NOT use `write` or `append` with raw markdown text unless explicitly asked.
