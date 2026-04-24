# Diagrams in Google Docs

Use `generate_image` to create diagrams and `insert-image-from-file` to embed
them. The `--after` flag places the image after a heading or paragraph.

**Workflow:**

```bash
# 1. Generate diagram (via generate_image tool - produces square images)
# 2. Auto-crop whitespace to get a tight landscape rectangle
convert diagram.png -fuzz 5% -trim +repage -bordercolor white -border 10x10 diagram_cropped.png
# 3. Insert after a heading (use diagram.png if you skipped the crop step)
$GDOCS insert-image-from-file DOC_ID diagram_cropped.png --after "System Overview"
```

**Batch approach — create a full doc with images in two steps:**

```bash
# Step 1: Batch all text content (headings, paragraphs, bullets)
$GDOCS batch DOC_ID -f content.json --replace-all
# Step 2: Insert images one at a time using --after
$GDOCS insert-image-from-file DOC_ID levels.png --after "AI Capability"
$GDOCS insert-image-from-file DOC_ID arch.png --after "Architecture"
```

The `batch` command also supports `insert-image-from-file` as an op (pre-uploads
files to Drive, then inserts). Use `image_path` instead of `image_uri`:

```json
{"op":"insert-image-from-file","image_path":"path/to/diagram.png"}
```

> [!NOTE]
>
> For documents with many images (5+), the two-step approach (batch text, then
> individual image inserts) is more reliable than including all
> `insert-image-from-file` ops in a single batch, because temporary Drive URIs
> may expire before the batch completes.

> [!IMPORTANT]
>
> **Always crop generated diagrams.** The `generate_image` tool produces square
> (680×680) images. Diagrams only use a horizontal strip, leaving huge
> whitespace above and below. Use `convert -fuzz 5% -trim` to auto-crop to a
> tight rectangle (typically ~600×130) before inserting.

**Prompt tips for `generate_image`:**

-   Ask for "clean white background, modern flat design, suitable for a
    technical document" — this renders well in Google Docs
-   Be specific about boxes, colors, arrows, and layout direction
-   Mention "no text shadows, crisp lines" for readability at smaller sizes
-   For flowcharts: "rounded rectangles with pastel colors, arrows left to
    right"
-   For architecture: "colored boxes with icons, arrows connecting components"
