# Metadata Retention in Google Docs

When updating collaborative documents that contain stakeholder feedback
(such as comments or suggestions), you must take precautions to avoid
destroying document indices and orphaning comment anchors.

## The Anchor Index Wipe Problem

> [!CAUTION] **Full-document replacement destroys comment anchors.**
> Using `--replace-all` (in `batch`, `import-md`, or `write`) clears
> all document indices, which orphans existing comment anchors to the
> sidebar. There is no automated way to re-link orphaned comments to
> text using current tools.

## Best Practices for Metadata Retention

1.  **Switch to Granular Updates**: As soon as a document has
    stakeholder feedback, stop using `--replace-all`. Use `sed`,
    `replace`, and `format-text` instead.
2.  **Section-Level Updates**: Use `batch` with `--after` and
    `--before` to replace a specific section without wiping the rest of
    the document. This preserves anchors in other parts of the doc.
3.  **Backup Comments**: Before performing any significant structural
    edit, run `$GDOCS list-comments DOC_ID --json > backup.json`. If
    anchors are broken, you can add replies to the orphaned comments
    referencing their original `quotedFileContent`.

## Formatting Caveats

Standard `batch` operations do not parse markdown symbols (e.g., `**`).
To restore formatting after a batch update, use:

-   `$GDOCS sed --bold`
-   `$GDOCS format-text --bold`
