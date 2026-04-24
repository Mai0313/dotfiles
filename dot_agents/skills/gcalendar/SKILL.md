---
name: gcalendar
description: >-
    View, create, and manage Google Calendar events using a Go CLI. Use when
    listing events, checking today's schedule,
    creating/updating/deleting events,
    RSVPing, checking free/busy, finding conflicts, creating focus time,
    quick-adding events from text, or importing ICS files.
    Also use when the user shares a calendar.google.com URL.
    Don't use for Google Chat, Gmail, or Tasks.
---

# gcalendar

## CLI

Prefer using the pre-built binary (available on all gLinux machines):

```bash
GCAL=/google/bin/releases/gemini-agents-gcalendar/gcalendar
```

Alternatively, install via apt (the `gcalendar` binary will be available
directly on PATH):

```bash
sudo glinux-add-repo -b gemini-agents-gcalendar stable
sudo apt update && sudo apt install -y gemini-agents-gcalendar
```

If you need to build from source:

```bash
blaze build //learning/gemini/agents/clis/gcalendar:gcalendar
GCAL=blaze-bin/learning/gemini/agents/clis/gcalendar/gcalendar
```

## Recipes

**View events:**

> [!TIP]
>
> When listing events, use `--max 50` to avoid omitting late afternoon events.
> Use `--json` to prevent visual truncation in terminal table output.

```bash
$GCAL events --max 5
$GCAL events --date 2024-03-15 --max 50 --json
$GCAL events --start 2024-03-01T09:00:00Z --end 2024-03-01T17:00:00Z
$GCAL today --json
$GCAL today --timezone America/Los_Angeles --json
$GCAL search "standup" --max 10
$GCAL get EVENT_ID
$GCAL recurring "Standup" --start 2024-03-01T09:00:00Z --end 2024-03-01T09:30:00Z --rrule "FREQ=WEEKLY;BYDAY=MO,WE,FR"
$GCAL instances EVENT_ID                  # instances of recurring event
$GCAL conflicts --days 7                  # find schedule conflicts
```

**Create and modify:**

```bash
$GCAL create --summary "Team Sync" --start 2025-01-15T10:00:00Z --end 2025-01-15T11:00:00Z --attendee a@g.com --attendee b@g.com
$GCAL create --summary "Private 1:1" --start 2025-01-15T14:00:00Z --end 2025-01-15T15:00:00Z --visibility private
$GCAL create --summary "Design Review" --start 2025-01-15T10:00:00Z --end 2025-01-15T11:00:00Z --gvc
$GCAL quick-add "Lunch at noon tomorrow"
$GCAL focus-time "Deep Work" --duration 2h
$GCAL update EVENT_ID --summary "New Title" --start 2025-01-15T14:00:00Z
$GCAL update EVENT_ID --description "Flight details and confirmation code"
$GCAL update EVENT_ID --attendee alice@google.com --attendee bob@google.com
$GCAL update EVENT_ID --remove-attendee bob@google.com
$GCAL update EVENT_ID --visibility public
$GCAL delete EVENT_ID
$GCAL rsvp EVENT_ID --status accepted     # accepted|declined|tentative
$GCAL move EVENT_ID --to OTHER_CAL_ID
$GCAL import-ics /path/to/event.ics --cal primary
```

**Calendar info:**

```bash
$GCAL calendars                           # list all calendars
$GCAL colors                              # available colors
$GCAL acl --cal primary                   # access control list
$GCAL freebusy --email user@google.com    # check availability
$GCAL next-free --duration 30m --after 2025-01-15T09:00:00Z
$GCAL working-hours
```

## Commands

Command         | Description
--------------- | ------------------------
`events`        | List upcoming events
`today`         | Show today's events
`search`        | Search events
`get`           | Get event details
`create`        | Create event
`quick-add`     | Quick-add from text
`focus-time`    | Create focus time event
`update`        | Update event
`delete`        | Delete event
`rsvp`          | RSVP to event
`move`          | Move event to calendar
`import-ics`    | Import ICS file
`instances`     | List recurring instances
`recurring`     | Create recurring event
`conflicts`     | Find conflicting events
`calendars`     | List calendars
`colors`        | List calendar colors
`acl`           | List calendar ACL
`freebusy`      | Check availability
`next-free`     | Find next free slot
`working-hours` | Show working hours

## Global Flags

-   `--json` — output as JSON (works with all read commands)
-   `--timezone` — override timezone (e.g., `America/Los_Angeles`). If not
    specified, the skill auto-detects your timezone from your Google Calendar
    settings.

## Create / Update Flags

Flag                | Description
------------------- | ----------------------------------------------------
`--summary`         | Event title
`--description`     | Event description (multi-line supported)
`--location`        | Event location
`--start`           | Start time (RFC3339)
`--end`             | End time (RFC3339)
`--attendee`        | Attendee email (repeat for multiple)
`--remove-attendee` | Remove attendee (`update` only, repeat for multiple)
`--visibility`      | `default`, `public`, `private`, or `confidential`
`--gvc`             | Add Google Meet video conference
`--modify`          | Allow guests to modify the event
`--cal`             | Calendar ID (default `primary`)

## Reporting Issues

Report bugs or improvements for this skill at
[Agent Skill: gcalendar](http://b/hotlists/8077895). See the `skill_issue` skill
for instructions on filing and triaging skill bugs.
