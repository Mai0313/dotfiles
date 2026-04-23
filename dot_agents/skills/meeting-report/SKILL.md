---
name: meeting-report
description: >
  Generate a STAR-format weekly meeting report from a technical document (e.g., REPORT.md, design doc, CL summary).
  Use this skill whenever the user asks for a meeting report, weekly update, status update, STAR report,
  or wants to summarize their work for a team sync, 1:1, standup, or weekly review.
  Also trigger when the user says things like "help me prepare for my weekly", "summarize this for the meeting",
  or "turn this into a report".
---

# Meeting Report Generator (Narrative STAR)

Turn technical source documents into a meeting report that reads like a short story: start with the background, ease the audience into the problem, then walk them through what was done and how it turned out. STAR (Situation, Task, Action, Result) still provides the skeleton, but the reader should never feel they are reading four separate sections.

## Why narrative instead of section headers?

Most weekly meeting audiences are mixed. Some attendees live in the same codebase as the presenter; others only vaguely know what RF-A, TF-A, or TFTF are. A rigid "Situation / Task / Action / Result" layout forces everyone to parse the same structure, and it tends to bury the context the non-expert listener needs right up front.

Telling it as a story fixes that. You open with the landscape — what the component is, why anyone cares — then gradually tighten the focus onto the specific problem, the decision that was made, the concrete work, and finally the outcome. The STAR beats are still there, just stitched into paragraphs rather than stamped on as headings. A reader who stops halfway still leaves with a coherent picture, not an orphaned section.

## Workflow

### Step 1: Find the source document

The source document drives the entire report, so picking the right one matters more than any other step. The priority order is:

1. **Whatever the user points at in the current turn.** If they mention a file path, paste content inline, reference a CL number, link to a design doc, or say things like "base it on what I just pushed" — that is the source. Use it without second-guessing.
2. **Context the user has already given in the conversation.** Scroll back for earlier mentions of a working document, a CL they have been iterating on, or a doc they previously asked you to read.
3. **`REPORT.md` in the current working directory** as a fallback default, but only if nothing above applies. Many repos use a different filename (`WEEKLY.md`, `status.md`, `notes/<date>.md`, a doc inside `docs/`, etc.), so do not hard-code the name. If `REPORT.md` does not exist, glob for likely candidates (`*.md` files modified recently, files in a `notes/` or `reports/` folder) before falling back to asking.
4. **Recent git activity.** If there is still no document, the user's recent commits, in-flight CLs, or branch diff against main may be the real source of truth for the week.

If after all of that the source is still ambiguous, ask the user directly: "Which document (or CL / commit range) should I base the report on?" Do not guess silently — picking the wrong source wastes more of their time than a single clarifying question.

#### Checking gpar (Gerrit) CLs

Local git log only shows merged commits. In-flight work often lives in gpar CLs that haven't landed yet. If the user mentions a CL number, or you suspect relevant work is in a pending CL, fetch it:

**1. Find which project contains the CL:**
```bash
repo forall -c 'git ls-remote polygon_android "refs/changes/*/<CL_NUMBER>/*" 2>/dev/null | grep -q <CL_NUMBER> && echo $REPO_PATH'
```

**2. Find the latest patchset:**
```bash
cd <project_path>
git ls-remote polygon_android "refs/changes/*/<CL_NUMBER>/*"
# Pick the ref with the highest patchset number (e.g., refs/changes/12/1735812/4)
```

**3. Fetch and read:**
```bash
git fetch polygon_android <ref>
git show FETCH_HEAD --stat   # Summary of changed files
git show FETCH_HEAD          # Full diff with commit message
```

The commit message from `git show FETCH_HEAD` is often a good source for the narrative — it usually captures what changed and why. If the CL has multiple patchsets, the latest one reflects the final state.

When multiple CLs contribute to the same report, fetch each one and synthesize them. Group by theme, not by CL number.

### Step 2: Gather context

Understanding who is presenting and to whom shapes how much background the story needs. Check:
- **User context**: role, team, seniority (from memory or CLAUDE.md)
- **Project context**: bug IDs, initiative names, stakeholders
- **Audience**: is this a team standup where everyone lives in the same code, or a cross-team review where half the room has never touched bootloader work?

Default assumption: **someone in the room doesn't know RF-A / TF-A / TFTF well.** Write so that person can still follow. Those who already know the territory will skim the opening sentences and land on the details; those who don't will actually understand why the work matters.

### Step 3: Extract STAR beats (but don't label them yet)

Read the source document and mentally tag content against the four beats:

| Beat | What to extract | Where to find it |
|---------|----------------|-----------------|
| **Situation** | The landscape and the problem that motivated the work | Problem statements, background sections, "why" paragraphs |
| **Task** | What was assigned or decided upon | Design proposals, assigned work, goals |
| **Action** | What was actually done, ordered by significance | Implementation details, code changes, decisions made |
| **Result** | Outcomes, metrics, status, next steps | Test results, benchmarks, open issues, TODOs |

These beats drive the flow of the narrative — they are **not** section headers in the output. Keep them in your head while writing so every beat gets its moment, in order, without ever announcing itself.

### Step 4: Write the report as a narrative

The finished report should read as a short piece of prose. Think of it as three to five paragraphs that gradually zoom in:

1. **Open with the landscape.** One or two sentences that orient a non-expert. What subsystem are we in? What does it do at a high level? This is where you spend a moment demystifying acronyms like RF-A or TFTF for anyone who needs it.
2. **Narrow onto the problem.** Slide from "here is the component" into "here is what was wrong with it, or what was missing." This is the Situation, told as context rather than as a labelled block.
3. **State the goal.** A sentence or two on what was agreed / assigned — the Task, phrased as a natural next step from the problem.
4. **Walk through the work.** The Action beat. This is the densest part; use a short bulleted list **inside** the paragraph flow if there are three or more distinct changes, each with a bold lead-in and a short explanation. If there are only one or two changes, keep them in prose.
5. **Close with the outcome.** The Result beat: what landed, what the numbers say, what is still open. End with a forward-looking sentence (next step, open question, or follow-up CL) so the audience knows where things go next.

#### Structural template

```
## Weekly Update — [Topic Title]

**Bug:** b/[bug-id]  (if applicable)

[Opening paragraph: landscape + problem. Assume the reader may not know the subsystem.
Define acronyms briefly on first use, e.g. "RF-A (the Rust rewrite of TF-A, which is the
EL3 firmware running before the kernel)". Then describe what was off or missing.]

[Transition paragraph: what was decided or assigned, phrased as the natural response to
the problem above. Keep it to 1–2 sentences.]

[Action paragraph(s): what was actually done. If there are several distinct pieces of
work, use an inline bulleted list — each bullet a bold headline plus a sentence of
explanation. Order by architectural significance, not chronology.]

[Closing paragraph: results, metrics, current status, and what comes next. If there are
benchmark numbers, a small table is fine here, but keep the prose wrapped around it so
the story does not break.]
```

#### Progressive depth inside the narrative

The story should be readable at three different zoom levels:

- **Opening sentence of each paragraph** — a non-technical reader can follow just these and still understand the arc.
- **Full paragraphs** — a teammate who knows the area gets the full picture.
- **Inline bullets and tables** — a reviewer who wants specifics (function names, numbers, CL links) can drill into those.

This is how you get "progressive depth" without chopping the report into headed sections.

#### Tone

- Write like you are explaining to a colleague over coffee, not filing a formal report.
- Prefer short, declarative sentences. Don't stack clauses.
- No LLM filler ("It's worth noting that…", "In conclusion…"). No hype words ("impressive", "challenging").
- When you introduce a piece of jargon, give it a quick gloss the first time, then just use the term.
- Stay neutral on difficulty — describe what happened, not how hard it was.

#### Length target

One page, roughly 300–450 words. If the source material is huge, cut ruthlessly. The meeting report is a pointer into the detailed doc, not a replacement for it.

### Step 5: Audience-aware suggestions

After the report, optionally add a brief note such as:
- "If the audience is entirely non-technical, drop the inline bullets and keep just the paragraphs."
- "If presenting to leadership, consider moving the closing paragraph (results + next steps) to the top."

This lets the user adapt on the fly without rewriting from scratch.

## Language rules

These rules apply when the user works in a zh-TW environment (check CLAUDE.md or user memory):

- Write the narrative body in Traditional Chinese (zh-TW).
- Keep ALL technical terms in English: register, lock, cache, benchmark, commit, cluster, sibling, RF-A, TF-A, TFTF, BL31, etc.
- Mix naturally: "在 OSI mode 下，lock scope 縮減為……" not "在作業系統初始化模式下，鎖定範圍縮減為……".
- Bug references, file names, function names, and CL numbers always stay in English.
- Do NOT use 破折號 (em-dash / en-dash) in zh-TW prose. Use commas, periods, or parentheses to break up clauses instead.
- When you gloss an acronym for a non-expert audience, keep the acronym in English and put the short explanation in zh-TW, e.g. "RF-A（TF-A 的 Rust 改寫版本，負責在 kernel 起來之前跑在 EL3 的 firmware）".

If the user's environment is English-only, write everything in English.

## What NOT to do

- Don't print "Situation / Task / Action / Result" as section headings. The beats stay invisible; the story carries them.
- Don't repeat the entire source document — the report is a summary, not a copy.
- Don't add technical details that aren't in the source — the report should be traceable.
- Don't use LLM-style filler or hype language.
- Don't add emoji unless the user explicitly asks.
- Don't editorialize on whether the work was "impressive" or "challenging" — just state what happened.
- Don't dump raw jargon on the reader without a one-phrase gloss the first time it appears.
