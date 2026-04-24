---
name: gsheets
description: >-
    Read, write, format, and manage Google Sheets using a Go CLI. Use when
    reading spreadsheet data, writing cells, creating sheets, formatting,
    sorting, merging, inserting/deleting rows and columns, adding charts,
    find-and-replace, importing CSV, creating pivot tables, or exporting.
    Also use when the user shares a sheets.google.com or
    docs.google.com/spreadsheets URL.
    Don't use for Google Docs, Slides, or general Drive file management.
---

# gsheets

> [!CAUTION]
>
> The `delete-sheet`, `delete-rows`, and `clear` commands permanently remove
> data. **Never** use destructive commands unless the user explicitly asks.

## CLI

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GSHEETS=/google/bin/releases/gemini-agents-gsheets/gsheets
```

Alternatively, install via apt (the `gsheets` binary will be available directly
on PATH):

```bash
sudo glinux-add-repo -b gemini-agents-gsheets stable
sudo apt update && sudo apt install -y gemini-agents-gsheets
```

If you need to build from source:

```bash
blaze build //learning/gemini/agents/clis/gsheets:gsheets
GSHEETS=blaze-bin/learning/gemini/agents/clis/gsheets/gsheets
```

## Recipes

**Read data:**

```bash
$GSHEETS read SPREADSHEET_ID "Sheet1!A1:D10"
$GSHEETS read-all SPREADSHEET_ID
$GSHEETS info SPREADSHEET_ID
$GSHEETS list-sheets SPREADSHEET_ID
$GSHEETS named-ranges SPREADSHEET_ID
```

**Write data:**

```bash
$GSHEETS write SPREADSHEET_ID "Sheet1!A1:B2" "Name,Age|Alice,30"
$GSHEETS write SPREADSHEET_ID "Sheet1!A1:B2" $'Name,Age\nAlice,30'
$GSHEETS write SPREADSHEET_ID "Sheet1!A1" "Value with\, a comma"
$GSHEETS append SPREADSHEET_ID "Sheet1!A1" "Bob,25"
$GSHEETS clear SPREADSHEET_ID "Sheet1!A1:D10"
$GSHEETS import-csv SPREADSHEET_ID /path/to/data.csv
$GSHEETS find-replace SPREADSHEET_ID --find "old" --replace "new"
$GSHEETS notes SPREADSHEET_ID "Sheet1!A1" "This is a note"
```

**Create and copy:**

```bash
$GSHEETS create --title "New Spreadsheet"
$GSHEETS copy-spreadsheet SPREADSHEET_ID "Copy Title"
$GSHEETS add-sheet SPREADSHEET_ID --title "Sheet2"
$GSHEETS delete-sheet SPREADSHEET_ID --sheet-id 1
$GSHEETS rename-sheet SPREADSHEET_ID --sheet-id 0 --title "Main"
$GSHEETS copy-sheet SPREADSHEET_ID --sheet-id 0 --dest OTHER_SPREADSHEET_ID
$GSHEETS create-from-template TEMPLATE_ID --title "New" --replacements "{{NAME}}=Alice"
```

**Formatting:**

```bash
$GSHEETS format SPREADSHEET_ID --sheet-id 0 --start-row 0 --end-row 1 --start-col 0 --end-col 5 --bold --align CENTER --bg-color #00FF00
$GSHEETS set-col-width SPREADSHEET_ID --sheet-id 0 --start-col 0 --end-col 1 --pixels 200
$GSHEETS autosize SPREADSHEET_ID --sheet-id 0 --start-col 0 --end-col 5
$GSHEETS merge SPREADSHEET_ID --sheet-id 0 --start-row 0 --end-row 1 --start-col 0 --end-col 3
$GSHEETS unmerge SPREADSHEET_ID --sheet-id 0 --start-row 0 --end-row 1 --start-col 0 --end-col 3
$GSHEETS freeze SPREADSHEET_ID --sheet-id 0 --rows 1 --cols 1
$GSHEETS borders SPREADSHEET_ID --sheet-id 0 --style SOLID --color "#000000"
$GSHEETS conditional-format SPREADSHEET_ID --sheet-id 0 --start-row 0 --end-row 100 --start-col 0 --end-col 1 --condition NUMBER_GREATER --value "90" --color "#00FF00"
```

**Rows, columns, and data operations:**

```bash
$GSHEETS sort SPREADSHEET_ID --sheet-id 0 --col 0              # --asc is default, omit for descending
$GSHEETS insert-rows SPREADSHEET_ID --sheet-id 0 --start 5 --count 5
$GSHEETS delete-rows SPREADSHEET_ID --sheet-id 0 --start 5 --end 10
$GSHEETS insert-cols SPREADSHEET_ID --sheet-id 0 --start 2 --end 4
$GSHEETS delete-cols SPREADSHEET_ID --sheet-id 0 --start 2 --end 4
$GSHEETS copy-paste SPREADSHEET_ID --sheet-id 0 --start-row 0 --end-row 5 --start-col 0 --end-col 2 --dest-row 0 --dest-col 3
$GSHEETS auto-fill SPREADSHEET_ID --sheet-id 0 --start-row 0 --end-row 10 --start-col 0 --end-col 1 --source-end-row 3
$GSHEETS formula-fill SPREADSHEET_ID --source "Sheet1!C1" --dest "Sheet1!C1:C10"
$GSHEETS data-validation SPREADSHEET_ID "Sheet1!B1:B10" --values "Yes,No,Maybe"
$GSHEETS protect SPREADSHEET_ID "Sheet1!A1:D1" --sheet-id 0
```

**Charts, pivots, and export:**

```bash
$GSHEETS add-chart SPREADSHEET_ID --sheet-id 0 --chart-type BAR --start-row 0 --end-row 10 --start-col 0 --end-col 2 --title "Sales"
$GSHEETS export-chart SPREADSHEET_ID --chart-id 1 --output /tmp/chart.png
$GSHEETS filter-view SPREADSHEET_ID --sheet-id 0 --range "Sheet1!A1:D10"
$GSHEETS pivot SPREADSHEET_ID --source "Sheet1!A1:D100" --sheet-id 0
$GSHEETS export SPREADSHEET_ID /tmp/export.csv --format csv
$GSHEETS export SPREADSHEET_ID /tmp/page1.png --format png --page 1
$GSHEETS share SPREADSHEET_ID --email user@google.com --role writer
$GSHEETS batch SPREADSHEET_ID requests.json
```

## Commands

Command                | Description
---------------------- | --------------------------------------------------
`read`                 | Read range
`read-all`             | Read all sheets
`write`                | Write to range
`append`               | Append rows
`clear`                | Clear range
`info`                 | Spreadsheet info
`create`               | Create spreadsheet
`copy-spreadsheet`     | Copy entire spreadsheet
`list-sheets`          | List sheets
`add-sheet`            | Add sheet
`delete-sheet`         | Delete sheet
`rename-sheet`         | Rename sheet
`copy-sheet`           | Copy sheet to another spreadsheet
`format`               | Format range
`set-col-width`        | Set column width
`autosize`             | Auto-resize columns
`merge`                | Merge cells
`unmerge`              | Unmerge cells
`sort`                 | Sort range
`freeze`               | Freeze rows/cols
`borders`              | Set cell borders
`conditional-format`   | Add conditional formatting
`insert-rows`          | Insert rows
`delete-rows`          | Delete rows
`insert-cols`          | Insert columns
`delete-cols`          | Delete columns
`copy-paste`           | Copy-paste range
`auto-fill`            | Auto-fill range
`formula-fill`         | Fill formula across range
`find-replace`         | Find and replace
`notes`                | Get/set cell notes
`named-ranges`         | List named ranges
`import-csv`           | Import CSV file
`data-validation`      | Add data validation
`protect`              | Protect range
`add-chart`            | Add a chart
`export-chart`         | Export chart as image
`filter-view`          | Create filter view
`pivot`                | Create pivot table
`export`               | Export spreadsheet (csv, xlsx, pdf, ods, tsv, png)
`share`                | Share spreadsheet
`create-from-template` | Create from template
`batch`                | Execute raw batchUpdate

## Tips

-   The `format` command uses `--sheet-id`, `--start-row/--end-row`,
    `--start-col/--end-col` (not A1 range notation)
-   The `notes` command takes range and note text as positional arguments (not
    --set flag)
-   Avoid spaces in sheet names when used in range notation; if unavoidable,
    wrap in single quotes: `"'My Sheet'!A1:B5"`
-   Chart types: `BAR`, `LINE`, `AREA` work reliably; `PIE` is listed but not
    supported by the API
-   Use `--json` on read commands to get machine-parseable output
-   Use `--value-render-option FORMULA` on the `read` command to retrieve the
    underlying cell formulas instead of the evaluated values.
-   `export` supports `csv`, `xlsx`, `pdf`, `ods`, `tsv`, and `png` formats
-   Both `|` and `\n` (newline) work as row delimiters in `write` and `append`
    commands. Use `|` for inline values and `$'\n'` for multi-row shell input
-   To include a comma inside a cell value, escape it with a backslash: `\,`
-   **Recommended workflow:** Use `export SPREADSHEET_ID page.png --format png
    --page N` to export a specific page as an image, review it visually, then
    iterate on edits

## Global Flags

-   `--json` — output as JSON (works with all read commands)

## Reporting Issues

Report bugs or improvements for this skill at
[Agent Skill: gsheets](http://b/hotlists/8078480). See the `skill_issue` skill
for instructions on filing and triaging skill bugs.
