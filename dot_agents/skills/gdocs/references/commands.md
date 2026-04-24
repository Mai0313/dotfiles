# Full List of Commands

This reference file contains the complete list of commands available in the
`gdocs` skill.

| Command                  | Description                                       |
| ------------------------ | ------------------------------------------------- |
| `read`                   | Read document content (supports `--tab`)          |
| `info`                   | Get document info                                 |
| `create`                 | Create document                                   |
| `copy`                   | Copy document                                     |
| `append`                 | Append text (supports `--tab`)                    |
| `insert`                 | Insert text at position (supports `--tab`)        |
| `replace`                | Find and replace                                  |
| `heading`                | Insert heading (supports `--tab`)                 |
| `delete`                 | Delete content range                              |
| `delete-doc`             | Delete a Google Doc permanently                   |
| `format-text`            | Format text range (`--start/--end`, `--text`,     |
:                          : `--url`)                                          :
| `format-paragraph`       | Format paragraph style (headings)                 |
| `bullets`                | Apply bullet list                                 |
| `insert-table`           | Insert a table (`--index` or `--after "text"`)    |
| `insert-page-break`      | Insert page break                                 |
| `insert-image`           | Insert image by URL                               |
| `insert-image-from-file` | Insert local image                                |
| `import-md`              | Import markdown                                   |
| `parse-md`               | Parse markdown into internal JSON blocks with     |
:                          : fingerprints                                      :
| `pull`                   | Pull Google Doc content into local Markdown file  |
| `sync`                   | Synchronize a local markdown file with a Google   |
:                          : Doc (3-way merge)                                 :
| `create-from-template`   | Create from template                              |
| `add-comment`            | Add comment (`--quote` to anchor to text)         |
| `list-comments`          | List comments and replies                         |
| `reply-comment`          | Reply to an existing comment                      |
| `resolve-comment`        | Resolve comment                                   |
| `list-revisions`         | List revisions                                    |
| `diff-revisions`         | Diff two revisions                                |
| `export`                 | Export to PDF/DOCX/TXT/PNG (use built binary)     |
| `share`                  | Share document                                    |
| `permissions`            | List permissions                                  |
| `word-count`             | Count words/chars (supports `--tab`)              |
| `toc`                    | Extract table of contents (supports `--tab`)      |
| `list-tabs`              | List document tabs                                |
| `create-tab`             | Create a new tab (supports `--parent`)            |
| `delete-tab`             | Delete a tab (requires `--confirm`)               |
| `rename-tab`             | Rename a tab                                      |
| `read-tab`               | Read a specific tab's text                        |
| `move-tab`               | Move a tab (supports `--parent`, `--root`)        |
| `footnotes`              | Extract footnotes                                 |
| `style`                  | Show document style                               |
| `suggestions`            | List suggestions                                  |
| `list-images`            | List inline images                                |
| `extract-tables`         | Extract tables as CSV (supports `--tab`)          |
| `extract-links`          | Extract all links (supports `--tab`)              |
| `batch`                  | Execute batch operations (`--after`, `--before`,  |
:                          : `--replace-all`, `--tab`, `--index`)              :
| `structure`              | Show document structure with numbered elements    |
:                          : (supports `--tab`, `--json`, `-v`)                :
| `sed`                    | Sed-style operations: substitution, delete,       |
:                          : append, insert, transliterate, table cell,        :
:                          : positional (`-e`, `-f`, `-i`, addressing)         :
| `clear`                  | Clear all document content (requires `--confirm`) |
| `write`                  | Write/overwrite document from file (`--file`,     |
:                          : `--clear`)                                        :
| `update-table`           | Find table by headers and replace data rows       |
| `merge-cells`            | Merge table cells (`--table`, `--row`, `--col`,   |
:                          : `--row-span`, `--col-span`)                       :
| `unmerge-cells`          | Unmerge previously merged table cells             |
| `add-column`             | Insert a column into a table (`--left` for left)  |
| `delete-column`          | Delete a column from a table                      |
| `add-row`                | Insert a row into a table (`--above` for above)   |
| `delete-row`             | Delete a row from a table                         |
| `replace-image`          | Replace an inline image by object ID              |
| `pageless`               | Make a document pageless                          |
