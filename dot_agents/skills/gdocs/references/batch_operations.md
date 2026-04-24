# Batch Operations

The `batch` command is the **recommended way to generate documents**. It
executes multiple styled operations in a single API call, producing professional
output with full control over formatting. Always prefer `batch` over `import-md`
or individual CLI commands.

Pass a JSON array of operations via `--file (-f)`. Before writing batch JSON,
**read [styling.md](styling.md)** for templates, color palettes, font pairings,
and anti-patterns.

Op                  | Required Fields      | Optional Fields                                                                                                                                                                                                                                                                                                                                                                                 | Description
------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -----------
`set-default-style` | —                    | `font_family`, `font_size`, `text_color`, `alignment`, `line_spacing`, `space_above`, `space_below`                                                                                                                                                                                                                                                                                             | Set defaults for subsequent ops (no API call — acts as a macro)
`append`            | `text`               | `bold`, `italic`, `underline`, `strikethrough`, `font_family`, `font_size`, `text_color`, `alignment`, `paragraph_bg_color`, `indent_start`, `indent_end`                                                                                                                                                                                                                                       | Append styled text
`heading`           | `text`, `level`      | `bold`, `italic`, `font_family`, `font_size`, `text_color`, `alignment`, `space_above`, `space_below`                                                                                                                                                                                                                                                                                           | Insert heading (1-6, TITLE, SUBTITLE)
`replace`           | `find`, `text`       | —                                                                                                                                                                                                                                                                                                                                                                                               | Find and replace text
`bullet-list`       | `text`               | `bullet_preset`, `bold`, `italic`, `font_size`, `text_color`                                                                                                                                                                                                                                                                                                                                    | Insert bullet item
`numbered-list`     | `text`               | `bullet_preset`, `bold`, `italic`, `font_size`, `text_color`                                                                                                                                                                                                                                                                                                                                    | Insert numbered item
`insert-table`      | —                    | `rows`, `cols`, `table_data`, `table_header_bold`, `table_header_bg_color`, `table_header_text_color`, `table_font_family`, `table_font_size`, `table_cell_colors`, `table_cell_text_colors`, `table_cell_bold`, `table_cell_urls`, `table_col_widths`, `table_border_color`, `table_border_width`, `table_cell_images`, `table_cell_image_width`, `table_cell_image_height`, `table_rich_data` | Insert table (with data, styled headers, per-cell colors/text/bold/URL, images, column widths, borders, rich text formatting)
`horizontal-rule`   | —                    | —                                                                                                                                                                                                                                                                                                                                                                                               | Insert visual separator
`page-break`        | —                    | —                                                                                                                                                                                                                                                                                                                                                                                               | Insert page break (**no-op in pageless mode** — docs are pageless by default; use `--pageless=false` on `create` if you need page breaks)
`link`              | `text`, `url`        | `bold`, `italic`, `font_size`, `text_color`                                                                                                                                                                                                                                                                                                                                                     | Insert hyperlinked text
`insert-image`      | `image_uri` or `url` | `image_width`, `image_height`                                                                                                                                                                                                                                                                                                                                                                   | Insert inline image
`rich-text`         | `runs`               | `bold`, `italic`, `underline`, `strikethrough`, `font_family`, `font_size`, `text_color`, `background_color`, `bullet_preset`, `alignment`, `paragraph_bg_color`, `indent_start`, `indent_end`                                                                                                                                                                                                  | Multi-style paragraph (bold + normal + code in one line). Styling applied to the parent op is inherited by all runs. Runs support person smart chips (email), date chips (date, date_format, time_zone_id), inline images (image_url, image_width, image_height), and styled text (text, bold, italic, font_family, font_size, text_color, background_color, url).
`style-table`       | `bg_color`           | `table_num`, `row`, `row_span`, `col`, `col_span`                                                                                                                                                                                                                                                                                                                                               | Style cells of an existing table (background color)

IMPORTANT: When using `rich-text` and applying bold styling to a run (e.g.,
`{"text": "bold part", "bold": true}`), the bold style may leak into subsequent
runs or paragraphs if not explicitly turned off. To prevent this, always specify
`"bold": false` on all runs that should *not* be bold.

### Styling Fields

Any text operation supports inline styling:

| Field                | Type   | Example         | Effect                     |
| -------------------- | ------ | --------------- | -------------------------- |
| `bold`               | bool   | `true`          | Bold text                  |
| `italic`             | bool   | `true`          | Italic text                |
| `underline`          | bool   | `true`          | Underline text             |
| `strikethrough`      | bool   | `true`          | Strikethrough              |
| `font_family`        | string | `"Google Sans"` | Font family                |
| `font_size`          | float  | `14`            | Font size (pt)             |
| `text_color`         | hex    | `"#1a73e8"`     | Text color                 |
| `background_color`   | hex    | `"#e8f0fe"`     | Text highlight color       |
| `alignment`          | string | `"CENTER"`      | Paragraph alignment        |
| `space_above`        | float  | `12`            | Space above paragraph (pt) |
| `space_below`        | float  | `6`             | Space below paragraph (pt) |
| `line_spacing`       | float  | `115`           | Line spacing (100=single)  |
| `paragraph_bg_color` | hex    | `"#fef7e0"`     | Paragraph shading          |
:                      :        :                 : (full-width background)    :
| `indent_start`       | float  | `36`            | Left indent in points      |
| `indent_end`         | float  | `36`            | Right indent in points     |

### Table-Specific Fields

These fields apply only to `insert-table` operations:

Field                     | Type         | Example                    | Effect
------------------------- | ------------ | -------------------------- | ------
`table_header_bg_color`   | hex          | `"#e8f0fe"`                | Header row background
`table_header_text_color` | hex          | `"#1a73e8"`                | Header row text color
`table_header_bold`       | bool         | `true`                     | Bold header row
`table_font_family`       | string       | `"Roboto"`                 | Font for all table cells
`table_font_size`         | float        | `9`                        | Font size for table cells
`table_cell_colors`       | `[][]string` | `[[""],["#d9ead3"]]`       | Per-cell background colors (row×col, "" = no color)
`table_rich_data`         | `[][][]run`  | `[[[{"text":"A"}]]]`       | Per-cell rich text runs
`table_cell_text_colors`  | `[][]string` | `[[""],["#137333"]]`       | Per-cell text colors (row×col, "" = default)
`table_cell_bold`         | `[][]bool`   | `[[false],[true]]`         | Per-cell bold (row×col)
`table_cell_urls`         | `[][]string` | `[[""],["http://cl/..."]]` | Per-cell hyperlinks (row×col)
`table_col_widths`        | `[]float`    | `[100, 200, 168]`          | Column widths in points
`table_border_color`      | hex          | `"#dadce0"`                | Border color for all edges
`table_border_width`      | float        | `0.5`                      | Border width in points
`table_cell_images`       | `[][]string` | `[[""],["https://..."]`    | Per-cell image URLs (row×col, "" = no image)
`table_cell_image_width`  | float        | `32`                       | Image width in points (applies to all cell images)
`table_cell_image_height` | float        | `32`                       | Image height in points

> **📖 See [styling.md](styling.md)** for color palettes, font pairings, 5
> document layout templates, and anti-patterns.

### Complete Batch JSON Example

This creates a styled design doc with colored tables, callout boxes, and
blockquotes. Save as `batch.json` and run: `$GDOCS create --title "Design Doc"`
then `$GDOCS batch DOC_ID -f batch.json`

```json
[
  {"op":"set-default-style","font_family":"Google Sans","font_size":11,"text_color":"#202124","line_spacing":115},
  {"op":"heading","text":"Feature Design Doc","level":"1","font_size":28,"text_color":"#1a73e8"},
  {"op":"append","text":"Status: Draft","font_size":10,"text_color":"#1a73e8","bold":true,"paragraph_bg_color":"#e8f0fe"},
  {"op":"append","text":"Author: username  •  Created: 2026-03-06","font_size":10,"text_color":"#5f6368","italic":true},
  {"op":"horizontal-rule"},
  {"op":"heading","text":"Overview","level":"2","font_family":"Google Sans","text_color":"#1a73e8","space_above":16},
  {"op":"append","text":"Brief description of the feature..."},
  {"op":"rich-text","font_size":11,"runs":[{"text":"✅ Goal: ","bold":true,"text_color":"#137333"},{"text":"Make it easy to build and ship within 1 day","text_color":"#202124"}]},
  {"op":"rich-text","font_size":11,"runs":[{"text":"❌ Non-Goal: ","bold":true,"text_color":"#d93025"},{"text":"Replace existing frameworks","text_color":"#202124"}]},
  {"op":"append","text":"\"This approach would save us months of development time.\"","italic":true,"indent_start":36,"indent_end":36,"text_color":"#5f6368"},
  {"op":"heading","text":"📊 Comparison","level":"2","font_family":"Google Sans","text_color":"#1a73e8","space_above":16},
  {"op":"insert-table","table_data":[["Option","Speed","Cost","Risk"],["Option A","Fast","Low","Medium"],["Option B","Slow","High","Low"]],"table_header_bg_color":"#e8f0fe","table_header_text_color":"#1a73e8","table_header_bold":true,"table_font_family":"Roboto","table_font_size":9,"table_cell_colors":[[""],["#d9ead3","#d9ead3","#fff2cc"],["#f4cccc","#f4cccc","#d9ead3"]],"table_col_widths":[120,120,120,108],"table_border_color":"#dadce0","table_border_width":0.5},
  {"op":"append","text":"TLDR: Option A is recommended for most teams.","paragraph_bg_color":"#fef7e0","bold":true,"font_size":10},
  {"op":"heading","text":"❓ Open Questions","level":"2","font_family":"Google Sans","text_color":"#1a73e8","space_above":16},
  {"op":"insert-table","table_data":[["Question","Status","Owner"],["API design review","Open","Alice"],["Security review","Pending","Bob"]],"table_header_bg_color":"#fce8e6","table_header_text_color":"#d93025","table_header_bold":true,"table_font_family":"Roboto","table_font_size":9,"table_col_widths":[260,60,60],"table_border_color":"#dadce0","table_border_width":0.5},
  {"op":"append","text":"Confidential - Google Internal Only","alignment":"CENTER","font_size":8,"text_color":"#9aa0a6","italic":true}
]
```
