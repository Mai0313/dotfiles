# gsheets — Agent E2E Test Plan

## Prerequisites

**Read `SKILL.md` first** to understand available commands, flags, and expected
behavior.

Prefer the pre-built binary:

```bash
GSHEETS=/google/bin/releases/gemini-agents-gsheets/gsheets
```

Or build from source:

```bash
blaze build //learning/gemini/agents/clis/gsheets:gsheets
GSHEETS=blaze-bin/learning/gemini/agents/clis/gsheets/gsheets
```

--------------------------------------------------------------------------------

## Test 1: Pre-built binary available

```bash
/google/bin/releases/gemini-agents-gsheets/gsheets --help
```

**Verify:** Help output is shown (binary exists and runs).

--------------------------------------------------------------------------------

## Test 1b: CLI builds from source

```bash
blaze build //learning/gemini/agents/clis/gsheets:gsheets
```

**Verify:** Build succeeds (exit code 0).

--------------------------------------------------------------------------------

## Test 2: Unit tests pass

```bash
blaze test //learning/gemini/agents/clis/gsheets:gsheets_test
```

**Verify:** All tests pass (exit code 0).

--------------------------------------------------------------------------------

## Test 3: Help output

```bash
$GSHEETS --help
```

**Verify:**

-   Output lists available subcommands
-   Commands include `read`, `write`, `create`, `format`

--------------------------------------------------------------------------------

## Test 4: Create a new spreadsheet

**Prompt:** "Create a new Google Sheets spreadsheet called 'Test Sheet'."

**Verify:**

-   Spreadsheet is created and ID is returned

--------------------------------------------------------------------------------

## Test 5: Write and read data

**Prompt:** "Write a table with headers Name, Age, City and two rows
(Alice/30/NYC and Bob/25/LA) to that spreadsheet, then read it back."

**Verify:**

-   Data is written to the sheet
-   Read output shows the 3 rows (header + 2 data)

--------------------------------------------------------------------------------

## Test 6: Append a row

**Prompt:** "Add another row with Charlie/35/Chicago to that spreadsheet."

**Verify:**

-   Row is appended
-   Reading all data shows 4 rows now

--------------------------------------------------------------------------------

## Test 7: Manage sheets

**Prompt:** "Add a new sheet tab called 'Extra' to the spreadsheet, then list
all sheet tabs."

**Verify:**

-   New sheet is created
-   List shows both the original sheet and 'Extra'

--------------------------------------------------------------------------------

## Test 8: Format cells

**Prompt:** "Make the header row of that spreadsheet bold."

**Verify:**

-   Formatting command succeeds without error

--------------------------------------------------------------------------------

## Test 9: Sort data

**Prompt:** "Sort the data in that spreadsheet by the Age column."

**Verify:**

-   Sort command succeeds without error

--------------------------------------------------------------------------------

## Test 10: Export to CSV

**Prompt:** "Export that spreadsheet as a CSV file."

**Verify:**

-   CSV file is created with the spreadsheet data

--------------------------------------------------------------------------------

## Test 11: Add a chart

**Prompt:** "Add a bar chart to the spreadsheet based on the Age data."

**Verify:**

-   Chart is created with the specified title
-   Chart ID is returned

--------------------------------------------------------------------------------

## Test 12: Conditional formatting

**Prompt:** "Highlight cells in the Age column that are greater than 28."

**Verify:**

-   Conditional format rule is applied without error

--------------------------------------------------------------------------------

## Test 13: JSON output

```bash
$GSHEETS info SHEET_ID --json
```

**Verify:**

-   Output is valid JSON
-   Contains spreadsheet title and sheet names

--------------------------------------------------------------------------------

## Test 14: Find and replace

**Prompt:** "Find all cells containing 'NYC' and replace with 'New York'."

**Verify:**

-   Replacement count is returned
-   Reading data shows 'New York' instead of 'NYC'
