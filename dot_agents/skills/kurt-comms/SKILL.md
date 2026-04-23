---
name: kurt-comms
description: >
  Draft concise, expert-to-expert messages to colleague Kurt on firmware work
  (TF-A, RF-A, TFTF, BL31, bootloader, gpar CLs). Use this skill whenever the user
  wants to tell Kurt something, ask Kurt a question, propose a solution to Kurt,
  send Kurt a status update, or write a final report for Kurt. Triggers on phrases
  like "問 Kurt", "跟 Kurt 講", "寫個訊息給 Kurt", "Kurt 那邊回報", "report to Kurt",
  "ask Kurt about", or any situation where the user is preparing outgoing communication
  directed at Kurt. Also use when the user is drafting a Kurt-facing summary even if
  they do not explicitly name the skill.
---

# Kurt Communication Skill

Kurt is a senior firmware expert. TF-A, RF-A, TFTF, bootloader, BL31, EL3 and the surrounding boot flow are his day job. Treat every message to him as one professional talking to another professional, like two engineers at a whiteboard, not a status report to a manager.

## Core mindset

**Brevity is respect for Kurt's time.** He does not need you to explain what TF-A is, where bl31 sits in the boot flow, or what context save/restore does. These are his territory. Messages to him should read like a commit message header: tight, landing the point in a sentence or two, with details held back until he asks.

**Conclusion first, context second.** The first thing Kurt wants to know is "what do you want / what happened / is it fixed". Not "let me walk you through how I debugged this". Put the what and the outcome in the opening line; put the how in a follow-up line; leave the debugging journey out entirely unless he asks.

**Cite CLs and files, do not re-describe code.** Kurt will open gpar himself. Pasting a chunk of your diff into the message does not help him, it just makes the message longer. A CL number is enough.

## Language policy for the output

Even though this file is in English, the **generated message to Kurt is written in Traditional Chinese with English technical terms mixed in naturally**, because that is how the user actually communicates at work.

- **Base language**: Traditional Chinese (zh-TW)
- **Technical terms stay in English, always**: register, bit, offset, cache, cluster, core, commit, branch, patchset, CL, hook, trap, SMC, HVC, EL3 / EL2 / EL1, context, stack, symbol, linker, GIC, MMU, TLB, BL31, BL33, DRAM, SRAM, suspend, resume, boot flow, and similar. Never translate these into Chinese.
- **No em dashes or en dashes** (no `—`, no inline ` - ` as a separator). Use periods, commas, or the Chinese enumeration comma `、` instead.
- **Conversational engineer tone**, not LLM prose. Good: `這 bug 是 bl31 suspend 前沒 flush cache`. Bad: `這個缺陷的根本原因在於 bl31 在進入 suspend 狀態之前未執行 cache flush 操作`.
- **No pleasantries**. Skip `不好意思打擾`, `謝謝你的時間`, `辛苦了` and similar filler. Kurt does not read them and they dilute the signal.

## Citing gpar CLs in the message

When writing to Kurt, just give the CL number. He will open it in gpar himself. Do not paste the URL, do not summarise what the CL does unless he asks.

**Conventions:**
- Basic: `gpar/1735812`
- Specific patchset: `gpar/1735812 ps4`
- Specific commit (rare, usually unnecessary): append the first 7 characters of the commit hash.

**If Kurt actually needs to fetch a CL himself, he already knows how:**
```bash
# find which project the CL lives in
repo forall -c 'git ls-remote polygon_android "refs/changes/*/<CL>/*" 2>/dev/null | grep -q <CL> && echo $REPO_PATH'
# fetch and view
git fetch polygon_android refs/changes/XX/<CL>/<PS>
git show FETCH_HEAD
```
**Do not paste this snippet into the message to Kurt.** This is his daily workflow. Including it would read as talking down to him. Only mention the fetch command if he specifically asks how to grab a CL.

## The three scenarios

Almost every message to Kurt fits one of these three shapes. Identify the scenario first, then fill in the skeleton.

### Scenario 1: Proposing a solution

**Three beats**: the problem in one sentence, the intended fix, what you want Kurt to confirm.

Skeleton:
```
[problem symptom, one sentence, include the platform]

打算改 [file/module] 的 [what]，做法大概是 [one sentence]。
CL: gpar/xxxxx

[specific thing you want Kurt's take on]
```

Example output:
```
BL31 從 suspend 回來後 GIC redistributor state 沒恢復，spacecraft 上 100% 重現。

想在 psci_cpu_resume 裡 plat_mmu_setup 之前補一個 gic_cpuif_enable，跟 TF-A mainline 對齊。
CL: gpar/1735812

這樣改會不會跟我們自己的 GIC save/restore flow 打架? 你之前處理過類似的嗎?
```

Notes:
- Do not explain what GIC is, what the psci flow does, or what suspend/resume means.
- The problem line must pinpoint platform + behaviour.
- The question at the end must be concrete (`會不會打架`), not vague (`你覺得呢`).

### Scenario 2: Asking Kurt a question

**Three beats**: what you are stuck on, what you already tried, what you are asking.

Skeleton:
```
[symptom, one sentence, include the platform]

試過 [A]、[B]，[result]。
懷疑 [hypothesis]，但 [what you are unsure about]。

[specific question]
```

Example output:
```
RF-A 在 spacecraft boot 到 BL31 後 uart 輸出只印得出前半段就斷。

試過把 uart baud 改回 115200、換另一顆板子、關掉後面的 early init，都一樣。
懷疑是 uart clock 在某個 transition 被切掉，但 TF-A 同 commit 沒事。

你之前在 zuma 那邊有碰過 uart 中途失聯的情況嗎? 有沒有建議我先看哪個 clock domain?
```

Notes:
- Lead with the symptom, not your hypothesis. Kurt might read the symptom and hand you the answer directly, making the hypothesis irrelevant.
- List what you already tried, so Kurt does not waste time suggesting something you ruled out.
- The question should be narrow and answerable, not open-ended like `怎麼辦`.

### Scenario 3: Final report after completing the task

**Three beats**: what you finished, how it was verified, any follow-up.

Skeleton:
```
[task, one sentence] 做完。

改動: [one-sentence summary] (gpar/xxxxx)
驗證: [what you tested]，[result]
[follow-up / known gap / decision you need from Kurt]
```

Example output:
```
MBU BL31_DRAM layout 拆分做完了。

改動: FREE_DRAM 拆 LOW/HIGH、MFW region 拆兩塊，BL31_DRAM 固定在 0xFFE00000 (gpar/1742301)
驗證: deepspace + spacecraft 都 boot 過，TFTF 全通
S3 suspend/resume 這邊還沒測，你之前提過 TFTF 沒 cover 這塊。要不要我後續補 manual test case?
```

Notes:
- Do not narrate the journey (`我花了三天研究 layout...`). Kurt does not care.
- Always state what was verified. If something was not tested, say so explicitly; do not imply coverage you do not have.
- If a follow-up needs a decision from Kurt, give him a concrete A/B option, not an open question.

## Self-check before sending

Run through this checklist before handing the draft to the user:

1. More than 5 sentences? Cut. Three is usually enough, unless it is a final report with multiple verification items.
2. Any em/en dashes or ` - ` separators? Replace with a period, Chinese comma, or `、`.
3. Any explanation of a concept Kurt already owns (TF-A internals, GIC, EL3, PSCI, etc.)? Delete it.
4. Large log dump or code block pasted inline? Trim to the few decisive lines; point at the CL or the `ramdump stage_file` name for the rest.
5. Is the ask or question specific? If Kurt cannot answer with a yes/no or an A/B pick, rewrite.
6. Any filler pleasantries (`不好意思`, `謝謝`, `打擾了`)? Strip them.

## Output format

**Default: emit the plain message text directly into the conversation.** The user will copy-paste it into chat or a messaging tool themselves. Do not wrap it in a code block unless the content itself is code or shell commands.

Only save to a file when the user explicitly asks (`幫我存成檔案`, `寫到 XXX.md`, etc.).

## Things to never do

- **Do not prepend a preamble** like `以下是建議的訊息：` or `Here is a draft message:`. Output the message body directly.
- **Do not apologise to Kurt or say `打擾了`** inside the message. This is a work discussion between peers.
- **Do not turn the debugging journey into a story.** Kurt does not want a narrative, he wants the current state.
- **Do not use em dashes or en dashes.**
- **Do not conflate gpar with Critique.** gpar is a Gerrit instance and uses a different toolchain, but do not explain this to Kurt in the message. He already knows.
