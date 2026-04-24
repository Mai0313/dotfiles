# gdrive — Agent E2E Test Plan

## Prerequisites

**Read `SKILL.md` first** to understand available commands, flags, and expected
behavior.

Prefer the pre-built binary:

```bash
GDRIVE=/google/bin/releases/gemini-agents-gdrive/gdrive
```

Or build from source:

```bash
blaze build //learning/gemini/agents/clis/gdrive:gdrive
GDRIVE=blaze-bin/learning/gemini/agents/clis/gdrive/gdrive
```

--------------------------------------------------------------------------------

## Test 1: Pre-built binary available

```bash
/google/bin/releases/gemini-agents-gdrive/gdrive --help
```

**Verify:** Help output is shown (binary exists and runs).

--------------------------------------------------------------------------------

## Test 1b: CLI builds from source

```bash
blaze build //learning/gemini/agents/clis/gdrive:gdrive
```

**Verify:** Build succeeds (exit code 0).

--------------------------------------------------------------------------------

## Test 2: Unit tests pass

```bash
blaze test //learning/gemini/agents/clis/gdrive:gdrive_test
```

**Verify:** All tests pass (exit code 0).

--------------------------------------------------------------------------------

## Test 3: Help output

```bash
$GDRIVE --help
```

**Verify:**

-   Output lists available subcommands
-   Commands include `ls`, `search`, `upload`, `download`

--------------------------------------------------------------------------------

## Test 4: List files in Drive

**Prompt:** "Show me the files in my Google Drive root folder."

**Verify:**

-   Output lists files with names, types, and IDs
-   At least one file or folder is shown

--------------------------------------------------------------------------------

## Test 5: Search for files

**Prompt:** "Search my Google Drive for files containing 'test'."

**Verify:**

-   Output lists matching files with names and IDs

--------------------------------------------------------------------------------

## Test 6: Check storage quota

**Prompt:** "How much Google Drive storage am I using?"

**Verify:**

-   Output shows usage and total quota

--------------------------------------------------------------------------------

## Test 7: Create a folder and upload

**Prompt:** "Create a new folder called 'CLI Test Folder' in my Drive, then
upload a small test file into it."

**Verify:**

-   Folder is created with ID
-   File appears in the folder listing

--------------------------------------------------------------------------------

## Test 8: View file permissions

**Prompt:** "Show me who has access to that folder."

**Verify:**

-   Output lists at least the owner with permission role

--------------------------------------------------------------------------------

## Test 9: Trash and restore

**Prompt:** "Move that test folder to the trash, then restore it."

**Verify:**

-   Trash succeeds without error
-   Untrash restores the folder

--------------------------------------------------------------------------------

## Test 10: Recent and starred files

**Prompt:** "Show me my 5 most recently modified files."

**Verify:**

-   Output lists files sorted by modification date
