# gcalendar — Agent E2E Test Plan

## Prerequisites

**Read `SKILL.md` first** to understand available commands, flags, and expected
behavior.

Prefer the pre-built binary:

```bash
GCAL=/google/bin/releases/gemini-agents-gcalendar/gcalendar
```

Or build from source:

```bash
blaze build //learning/gemini/agents/clis/gcalendar:gcalendar
GCAL=blaze-bin/learning/gemini/agents/clis/gcalendar/gcalendar
```

--------------------------------------------------------------------------------

## Test 1: Pre-built binary available

```bash
/google/bin/releases/gemini-agents-gcalendar/gcalendar --help
```

**Verify:** Help output is shown (binary exists and runs).

--------------------------------------------------------------------------------

## Test 1b: CLI builds from source

```bash
blaze build //learning/gemini/agents/clis/gcalendar:gcalendar
```

**Verify:** Build succeeds (exit code 0).

--------------------------------------------------------------------------------

## Test 2: Unit tests pass

```bash
blaze test //learning/gemini/agents/clis/gcalendar:gcalendar_test
```

**Verify:** All tests pass (exit code 0).

--------------------------------------------------------------------------------

## Test 3: Help output

```bash
$GCAL --help
```

**Verify:**

-   Output lists available subcommands
-   Commands include `events`, `today`, `search`, `create`

--------------------------------------------------------------------------------

## Test 4: Show today's schedule

**Prompt:** "What's on my calendar for today?"

**Verify:**

-   Output shows today's events with titles and times
-   Or a message indicating no events

--------------------------------------------------------------------------------

## Test 5: List upcoming events

**Prompt:** "Show me my next 5 upcoming calendar events."

**Verify:**

-   Output lists up to 5 events with title, date, and time
-   Events are in chronological order

--------------------------------------------------------------------------------

## Test 5b: Filter events by date

**Prompt:** "Show me my calendar events for 2026-03-10."

**Verify:**

-   Agent uses `$GCAL events --date 2026-03-10`
-   Output shows only events on that specific date

--------------------------------------------------------------------------------

## Test 5c: Filter events by time range

**Prompt:** "Show me my calendar events on March 10 between 9am and noon."

**Verify:**

-   Agent uses `--start` and `--end` flags with RFC3339 times
-   Output shows only events within the requested range

--------------------------------------------------------------------------------

## Test 6: Search for events

**Prompt:** "Find any calendar events related to 'meeting' on my calendar."

**Verify:**

-   Matching events are shown with titles containing the search term

--------------------------------------------------------------------------------

## Test 7: List my calendars

**Prompt:** "Which calendars do I have access to?"

**Verify:**

-   Output lists at least one calendar with name and ID

--------------------------------------------------------------------------------

## Test 8: Check availability

**Prompt:** "Am I free for the next 4 hours? Check my availability."

**Verify:**

-   Output shows free/busy time slots for the requested period

--------------------------------------------------------------------------------

## Test 9: Create and delete an event

**Prompt:** "Create a test event called 'CLI Test' starting in 1 hour and
lasting 30 minutes, then delete it."

**Verify:**

-   Event is created with confirmation and ID
-   Event is deleted successfully

--------------------------------------------------------------------------------

## Test 10: Create a recurring event

**Prompt:** "Create a weekly standup event called 'Team Standup' every Monday,
Wednesday, and Friday at 9am, lasting 30 minutes."

**Verify:**

-   Event is created with summary and ID
-   Link to event is printed

--------------------------------------------------------------------------------

## Test 11: Focus time

**Prompt:** "Block off 2 hours of focus time on my calendar right now."

**Verify:**

-   Focus time event is created
-   Output shows the time range and event ID

--------------------------------------------------------------------------------

## Test 12: Update an event

**Prompt:** "Change the title of my next event to 'Renamed Event'."

**Verify:**

-   Event is updated with the new summary
-   Confirmation is printed

--------------------------------------------------------------------------------

## Test 13: Check for scheduling conflicts

**Prompt:** "Do I have any scheduling conflicts today?"

**Verify:**

-   Output indicates conflicts found or no conflicts
-   If conflicts exist, overlapping events are listed

--------------------------------------------------------------------------------

## Test 14: Find next free slot

**Prompt:** "When is my next free 1-hour slot?"

**Verify:**

-   Output shows a free time range in RFC3339 format

--------------------------------------------------------------------------------

## Test 15: Show working hours and timezone

**Prompt:** "What timezone is my calendar set to?"

**Verify:**

-   Output shows calendar settings including timezone

--------------------------------------------------------------------------------

## Test 16: Create event with --gvc

**Prompt:** "Create a 30-minute test event called 'GVC Create' with a
Google Meet link."

**Verify:**

-   Event is created with confirmation and ID
-   Opening the event in Calendar shows a Google Meet link

--------------------------------------------------------------------------------

## Test 17: Create event without --gvc

**Prompt:** "Create a 30-minute test event called 'No GVC' without a
video conference."

**Verify:**

-   Event is created with confirmation and ID
-   Opening the event in Calendar shows no conferencing

--------------------------------------------------------------------------------

## Test 18: Add Google Meet to existing event via update

**Prompt:** "Add a Google Meet link to event ID [ID from Test 17]."

**Verify:**

-   Event is updated successfully
-   Opening the event in Calendar now shows a Google Meet link

--------------------------------------------------------------------------------

## Test 19: Create recurring event with --gvc

**Prompt:** "Create a weekly Monday 30-minute standup called 'GVC
Recurring' with a Google Meet link."

**Verify:**

-   Recurring event is created with confirmation and ID
-   Opening an instance in Calendar shows a Google Meet link
