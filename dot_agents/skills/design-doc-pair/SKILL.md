---
name: design-doc-pair
description: >
  Generate a pair of firmware architecture design documents (internal + external)
  for TF-A, RF-A, TFTF, BL31, bootloader, or related Pixel firmware work. The
  internal doc is written in Traditional Chinese for discussion with Kurt and
  contains a detailed implementation plan; the external doc is written in English
  for cross-team architectural alignment and stays at the interface/design level.
  Two markdown files are produced, named <short_name>.internal.md and
  <short_name>.external.md. Use this skill whenever the user wants to draft a
  design doc, flesh out an architecture from a fragment of Kurt's idea, prepare
  an RFC, get ahead of Kurt on design work, or align with another team on
  firmware architecture. Triggers on phrases like "幫我寫個 design doc",
  "幫 Kurt 想個架構", "準備架構對齊文件", "搶先把方案想好", "寫個 RFC",
  "draft a design doc", "write up the architecture for Kurt", or any situation
  where a fragmented idea needs to be turned into a pair of polished docs.
---

# Firmware Design Doc Pair

Turn a fragment of an idea (usually from Kurt, sometimes from the user themselves) into two coordinated design documents: one internal doc in Traditional Chinese for Kurt's review, one external doc in English for cross-team alignment. The goal is to produce docs that read as though the user — a peer-level engineer on TF-A / RF-A / TFTF — architected the proposal, not summarised someone else's.

## Why this skill exists

The user's working context: Kurt is the senior firmware expert on the team. He frequently starts with a partial idea — a sentence in chat, a concern raised in a review, a handful of bullet points — and expects it to grow into a real design. The user's goal is to be the one who fleshes it out first, so when Kurt reads the proposal he sees architecture-level thinking, not just a transcription of what he already said.

Two audiences, two docs:

- **Internal doc (`<short_name>.internal.md`)**: written for Kurt. Traditional Chinese with English technical terms, because that is how Kurt and the user actually talk. Contains the detailed implementation plan — which files to touch, which patches to land in what order, which corners are risky. Kurt needs this level of detail to evaluate whether the approach is sound and to catch mistakes early.

- **External doc (`<short_name>.external.md`)**: written for the rest of the organisation — SoC team, kernel team, platform team, other firmware components. English, because cross-team audiences are not all Traditional-Chinese readers, and because the TF-A / Arm world uses English as lingua franca. Stays at the architecture and interface level. Implementation details are suppressed; what matters here is what the change looks like from the outside, which invariants it preserves, and what downstream teams need to adjust.

Neither doc stands alone. The internal doc is the one the team builds from; the external doc is the one other teams sign off on. Produce both in the same pass so they tell the same story at the right altitude.

## Inputs

The user will give some mix of:

- A snippet of Kurt's thoughts (from chat, review comments, a meeting)
- Their own extensions and suspicions
- A link or CL number to adjacent code
- Platform context (deepspace, spacecraft, ripcurrent, etc.)
- Which component is involved (TF-A, RF-A, TFTF, BL31, specific PSCI / GIC / EL3 handler)

If the fragment is too thin to design from — e.g. `Kurt 說 context save 怪怪的`, with no follow-up — ask one tight clarifying question before drafting. Something like `你知道他是指 normal-world → secure-world transition 的 save，還是 suspend 路徑上的? 先鎖定一下 scope`. Never ask more than two rounds of questions; if the user cannot narrow it further, just state the assumptions at the top of the internal doc and move on.

## Workflow

### Step 1. Understand the architecture being proposed

Read the user's input and form a concrete picture:

- What is the current behaviour or structure?
- What is the proposed change?
- Why is it being proposed now (bug, performance, upstream alignment, new SoC)?
- Which layers of the boot flow or runtime are affected (BL1 / BL2 / BL31 / BL33, EL3 / EL2 / EL1, normal / secure world)?

If Kurt's fragment only gestures at the problem, extend it. That is the point of this skill. Propose the obvious next step, and flag it as `*proposed*` so the user can see which parts came from Kurt and which came from the expansion.

### Step 2. Coin the short name

The short name is the filename stem for both docs. It should be:

- **Short**: 2-4 words, joined by underscores. Long names like `bl31_platform_specific_context_save_optimization` are bad.
- **Descriptive of the architecture, not the bug**: `power_state_steering` is good; `fix_suspend_crash` is bad. The doc is about the design, not the incident.
- **Lowercase with underscores**: matches how other firmware filenames are written.

Good examples: `power_state_steering`, `lazy_context_save`, `gic_redistributor_restore`, `bl31_dram_split`, `secure_interrupt_routing`, `el2_hypervisor_stub`.

If the architecture does not yet have a name in Kurt's message, coin one. Show it in your first response so the user can push back before both docs get generated with the wrong name.

### Step 3. Confirm the output location

Output path is not fixed — ask the user. Something like `要存在哪? 例如 ./docs/design/ 或 cwd`. Once they answer, write both files atomically. If the user says `./docs/design/`, create the directory if it does not exist, then write `<path>/<short_name>.internal.md` and `<path>/<short_name>.external.md`.

### Step 4. Draft the internal doc, then the external doc

Draft the internal doc first. It is the more detailed one, and writing it forces you to commit to specific files, functions, and sequences. The external doc is then derivable from the internal doc by suppressing implementation details and translating into English.

Do **not** machine-translate the internal doc into English for the external. They are different documents with different audiences and different altitude. Write each fresh against its own skeleton.

### Step 5. Tell the user what was produced

After writing, report the two paths and a one-line summary of what is in each. Do not paste the full doc contents back into the chat. The user will open the files.

## Internal doc structure

Write in Traditional Chinese. Keep English technical terms (TF-A, BL31, EL3, PSCI, GIC, SMC, HVC, cache, register, cluster, core, offset, suspend, resume, context, etc.) in English. No em dashes (`—`) or en dashes. Use periods, commas, or `、`.

Use this skeleton, adapted from the TF-A upstream RFC style:

```markdown
# <Architecture Name> (Internal Design Doc)

**Status**: Draft / For review with Kurt
**Author**: <user's name, pull from env if available, otherwise leave as `TBD`>
**Last updated**: <today's date, YYYY-MM-DD>
**Target**: <platforms, e.g. deepspace / spacecraft>
**Component**: <TF-A / RF-A / TFTF / BL31 / ...>

## TL;DR

三到五句話說明: 現況是什麼、為什麼要改、打算怎麼改、誰受影響。第一句話要讓 Kurt
一眼看懂主題, 不要繞彎子。

## Background

簡短描述目前 code 裡的行為。引用具體 file path 或 function name (例如
`plat/google/common/psci/gs_psci_suspend.c` 的 `plat_suspend_finisher`), 不要大段
貼 code。Kurt 自己會打開檔案看。

如果這個設計是為了修某個 bug, 給一行 symptom + 觸發條件。如果是為了 upstream
對齊, 點一下是哪個 upstream commit 或 feature。

## Motivation

為什麼現在做。這段是要讓 Kurt 同意這件事值得投入時間, 不只是 nice-to-have。
最多三個 bullet:
- 具體的 pain point (race condition、performance 問題、upstream drift)
- 哪個 platform 上會踩到
- 不做的 cost (bug 會繼續復發、future platform 會更難接)

## Proposed Design

這是 doc 的核心。寫法要像在跟 Kurt 白板討論, 不是寫給外人看。

先給一張 high-level 的 flow (可以用 ASCII diagram, 或條列式 sequence), 標出哪幾步
是新的。然後針對每一步說明:

1. **改動點**: 明確指出 file / function / struct field
2. **為什麼這樣改**: 一句話的 rationale
3. **跟現有 code 的銜接**: 有沒有既有的 helper 可以重用

如果設計裡有 invariant (例如某個 lock 必須在某個階段被 hold 住、某個 cache line
必須在某個 barrier 之前 flush), 明確寫出來。這些東西 Kurt 會特別看。

### Alternatives considered

列 1-2 個被你否決的替代方案, 以及否決的原因。這一段不是為了湊篇幅, 是為了讓 Kurt
知道你有想過才選這條路。如果他之前在 chat 裡有提到某個方向但你沒採用, 一定要列
出來並解釋。

## Implementation plan

這段是 internal doc 獨有的。拆成 patch-level 的步驟:

- **Patch 1**: <一句話描述>, 動 `<file list>`, 預期 CL size <small/medium/large>
- **Patch 2**: ...
- ...

順序要合理: 先鋪 infrastructure (新 helper、新 API), 再切換 call site, 最後清掉
舊路徑。如果某幾個 patch 可以獨立 land (不依賴後面), 標出來, Kurt 通常會想先 merge
那些。

如果會動到 TFTF test, 另開一條 bullet 說 test 怎麼改 / 怎麼新增。

## Testing strategy

具體到 test binary / test case 層級:

- 既有的哪個 TFTF test 會 cover (`tftf/tests/<path>`)
- 需不需要新的 test case? 如果要, 大概做什麼
- manual test 要不要跑? (例如 S3 suspend/resume 要手動)
- 哪個 platform 一定要測過 (deepspace 必測, spacecraft 可選等)

## Risks and open questions

用 bullet 列出仍不確定的點。這是給 Kurt 回覆時聚焦用的, 不是你沒做功課的藉口。好
的 open question 是具體的:

- ❌ `這樣會不會有問題?` (太模糊)
- ✅ `gic_cpuif_enable 在 plat_mmu_setup 之前呼叫, 會不會跟目前的 per-core
  redistributor init 打架? 這塊我沒在 spacecraft 上跑過 S3。`

## Discussion points for Kurt

最後留 2-3 個具體問題。每個都應該能用 yes/no 或 A/B 回答, 不要開放式。例如:

- `想確認 rollout 順序, 先上 deepspace 還是兩個 platform 一起?`
- `Patch 3 要不要拆成兩個? 一個純 refactor 一個行為改動。`
- `我打算 target tf-a-main, 不走 pixel-lts。你覺得有需要 backport 嗎?`
```

### Internal-doc tone rules

- Conclusion first. TL;DR 在最前面, 不要把讀者繞到最後才給答案。
- Concrete over generic. 具體到 file / function / register bit, 不要寫 `相關模組` `某個 handler` 這種模糊字眼。
- 不要解釋 Kurt 已經知道的東西 (TF-A 是什麼、BL31 跟 BL33 的分工、EL3 是什麼)。
- 不要用 `不好意思`、`辛苦了`、`麻煩你` 這類客套。
- No em dashes. 句子之間用句號、逗號、或 `、`。

## External doc structure

Write in English. No Chinese. Expand acronyms on first use (`TF-A (Trusted Firmware-A)`, `BL31`, `EL3`) because not everyone on the other teams lives inside this codebase.

Use this skeleton, also modelled on the TF-A upstream RFC style:

```markdown
# <Architecture Name> (Design Proposal)

**Status**: Draft / For cross-team review
**Author**: <user>
**Last updated**: <YYYY-MM-DD>
**Affected components**: <TF-A / BL31 / kernel-facing ABI / ...>
**Affected platforms**: <deepspace, spacecraft, ...>

## Summary

Two or three sentences. State the architectural change in terms another team
can evaluate: what moves, what contract is preserved, what contract changes.

## Motivation

Why this needs to happen now, framed in terms other teams care about:
- Bug class being eliminated, or upstream gap being closed
- Platforms affected and the user-visible symptom
- What breaks or degrades if the change is deferred

Keep this section short (a paragraph or a tight bullet list). Cross-team
readers will decide in 30 seconds whether this is relevant to them; make
that decision easy.

## Current architecture

Describe the relevant slice of the current boot or runtime flow at the
*component* level, not the function level. A diagram helps:

```
BL2 ──► BL31 ──► BL33 (kernel)
          │
          └─► PSCI handler ──► platform suspend hook
```

Point at the piece that is changing, and note which invariants / ABIs
cross between components today.

## Proposed architecture

High-level description of the change. Again, component-level, not
function-level. A second diagram showing the new flow is usually worth
including.

Call out:
- Which component-to-component interfaces shift (even if the change is
  internal, ABIs like PSCI, SMCCC, handoff structures matter to sibling
  teams and should be explicitly listed as "unchanged" when that is the
  case).
- Any new constraint placed on neighbouring components (e.g. "kernel must
  no longer rely on BL31 clearing X before handoff").
- What the normal-world-visible behaviour change is, if any.

## Alternatives considered

Short list (1-3) of other approaches and why they were not chosen. This is
how cross-team reviewers confirm you have surveyed the space. Keep each
alternative to 2-3 sentences.

## Cross-team impact

A table makes this scannable:

| Team / Component | Impact | Action required |
|------------------|--------|-----------------|
| Kernel           | ...    | ...             |
| SoC firmware     | ...    | ...             |
| TFTF             | ...    | ...             |

Include even rows where the answer is "no impact" if that team might
reasonably wonder. Absence in the table reads as "unknown", which
invites pushback.

## Open questions

Questions still being worked, framed for cross-team input. Unlike the
internal doc's open questions (which are implementation-flavoured), these
should be questions only other teams can answer. For example:
- Does the kernel rely on <current-behaviour-X> in any driver?
- Are there downstream vendors on this SoC that assume <Y>?

## Out of scope

One paragraph or a short bullet list clarifying what this proposal does
*not* change. Prevents reviewers from getting stuck on unrelated concerns.
```

### External-doc tone rules

- No implementation detail. File paths, function names, struct layouts — all belong in the internal doc, not here.
- No colloquial voice. This is a design review document, not a chat message. Keep it precise but not pompous.
- Expand acronyms on first use. `TF-A`, `BL31`, `EL3`, `PSCI`, `SMCCC` — spell them out once. Assume the reader is a firmware-adjacent engineer who knows the shape of the world but not the inside of this codebase.
- Surface contracts explicitly. The single most useful thing this doc does for other teams is tell them exactly which of their assumptions are still valid.

## The "get ahead of Kurt" mindset

The user's stated goal is for Kurt to open the doc and think `this person can architect, not just implement`. The skill supports that by writing in a way that demonstrates architectural judgement. Some specifics:

1. **Take positions, do not enumerate.** A design doc that lists five options and asks Kurt to pick reads as passing the buck. Pick one, argue for it in a paragraph, and relegate the rest to `Alternatives considered`.

2. **Show awareness of neighbouring systems.** Mention GIC when the change touches interrupts. Mention MMU / TLB when it touches memory mapping. Mention PSCI when it touches power state. This is how you show systems-level thinking — by wiring the local change into the broader flow.

3. **Commit to a rollout order.** If the proposal touches multiple platforms, state which one lands first and why. Even if the answer is obvious (`start with deepspace because it reproduces the bug`), write it down — architectural sense includes understanding landing risk.

4. **Raise risks Kurt might have missed.** This is where the skill earns its keep. After drafting the design, pass over it again and ask `what breaks that Kurt did not mention?`. Common categories: suspend/resume, secondary CPU bringup, PSCI parallel paths, build variants (release vs debug), cross-platform divergence. Surface one non-obvious risk in the open-questions section.

5. **Do not be reverent about Kurt's fragment.** If something in his hint is slightly off, extend past it. Mark the extension clearly (e.g. `Kurt 提到 X, 我想延伸到 Y 因為…`) so he can see the judgement call rather than feeling overridden silently.

## Short-name conventions

- All lowercase.
- Underscores between words.
- 2-4 words. If it feels like 5, you are describing the implementation, not the architecture; re-scope the name.
- No version suffix (`_v2`, `_new`). If this is a rewrite of an older doc, the git history carries that context.
- No bug-number or CL-number in the name. The name is about the architecture; traceability goes in the doc body (`Related: b/12345, gpar/1742301`).

Rename the file only if the user pushes back on the coined name; do not rename mid-draft.

## Handling gpar / CL references in the doc

- **Internal doc**: cite `gpar/<CL>` freely, with patchset if relevant (`gpar/1735812 ps4`). Kurt will open the CL himself. Do not paste CL titles or diffs inline.
- **External doc**: cite CL numbers sparingly, and only where other teams actually need to trace the implementation. Prefer describing the change in terms of its effect, not the CL that implements it.

Do not explain how to fetch a gpar CL inside either doc. Both audiences know.

## Self-check before outputting

Run through this list before writing the files:

1. Does the internal doc have a concrete `Discussion points for Kurt` section with yes/no or A/B questions? If the questions are open-ended, rewrite.
2. Does the external doc have an explicit `Cross-team impact` table, including the `no impact` rows? If the table is missing, add it — this is the most-read section for sibling teams.
3. Is the internal doc in Traditional Chinese with English tech terms? Any full English paragraphs or any translated tech terms (e.g. `暫存器` for register, `位元` for bit) must be fixed.
4. Is the external doc entirely in English, with no Chinese leaking through? Check section headings, table contents, and diagram labels.
5. Are there em dashes (`—`) or en dashes anywhere in the internal doc? Replace.
6. Did the skill take a position on the design, or did it hedge across multiple options? A hedged internal doc fails its purpose.
7. Is there at least one non-obvious risk surfaced in the internal doc's `Risks and open questions`? If not, pass over the design one more time.
8. Does the filename use the coined `short_name` exactly, with `.internal.md` / `.external.md` suffixes?

## What this skill does not do

- It does not push to gpar, commit, or open reviews. Writing the markdown files is the full scope.
- It does not translate between the two docs. They are independently drafted against their own skeletons.
- It does not generate diagrams as images. ASCII / fenced-block diagrams only, to keep the docs diff-friendly.
- It does not replace conversation with Kurt. The docs exist to make the conversation faster; they are not a substitute for it.

## Things to avoid

- **Do not wrap the design in uncertainty**. Phrases like `可能` `也許` `不確定` `it might be that…` signal that the author has not made up their mind. If something is genuinely uncertain, put it in `Open questions`; if not, delete the hedge.
- **Do not restate Kurt's fragment as the TL;DR**. If the TL;DR could be copy-pasted from his chat message, the skill has not added value. Extend, commit, or reframe.
- **Do not introduce implementation detail into the external doc**. File paths, struct field names, patch splits — all of it belongs in internal only.
- **Do not use LLM-prose tells** (`it is worth noting that`, `in conclusion`, `let us explore`). The user is a working firmware engineer and these phrases will read as ghost-written.
- **Do not create a third doc**. Scope is exactly two files.
