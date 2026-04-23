---
name: buganizer-summarizer
description: Fetches details and comments of a Buganizer issue (e.g. b/123456) and writes a comprehensive summary into a markdown file (e.g. ./b_123456.md). Use when asked to summarize a bug or extract bug information into a file.
---

# Buganizer Issue Summarizer

This skill extracts detailed information from a Buganizer issue and saves it as a structured markdown file in the current directory. This is typically used to hand off context to other agents.

## Workflow

1. **Identify Bug ID:** Extract the numerical bug ID from the user's prompt (e.g., `494448613` from `b/494448613`).
2. **Fetch Bug Details:**
   - Use the `mcp_Buganizer_render_issue` tool to retrieve the bug's title, description, status, priority, and all comments. Ensure you fetch the data comprehensively.
   - You can also use `mcp_Production_get_buganizer_issue` if more details are needed, but `mcp_Buganizer_render_issue` with no fields specified retrieves all default fields.
3. **Format the Information:**
   - Create a markdown document containing all retrieved details.
   - Structure the document with clear headings: Title, Metadata (Status, Priority, Assignee, Reporter), Description, and Comments.
   - Include **all** comments, keeping their chronology clear.
   - **CRITICAL:** If any reproduction steps (how to reproduce) are mentioned in the description or any of the comments, ensure they are prominently captured and not omitted.
   - **CRITICAL:** DO NOT draw conclusions, diagnose the issue, or offer fixes. Your ONLY task is to organize and extract the information verbatim or functionally equivalent. Avoid omitting details to save space. The goal is to provide maximum context.
4. **Save to File:**
   - Use the `write_file` tool to save the formatted markdown content.
   - The file name MUST follow the format `./b_<bug_id>.md` (e.g., `./b_494448613.md`) and be saved in the current directory.
5. **Acknowledge:** Briefly notify the user that the file has been created.
