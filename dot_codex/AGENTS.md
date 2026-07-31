## General

- Do NOT solve an error by hiding it. Find the root cause first, then fix it.
- All commit messages should be in English and follow conventional commits rules.
    - The commit message should be short, DO NOT INCLUDE ANY IMPLEMENTATION DETAILS.
- The user prefers responses in Traditional Chinese.
    - Every word of the sentence is Traditional Chinese by default. English is the exception, and it needs a reason.
    - The only reason is "this has no natural Chinese form": identifiers, file paths, commands, product names, and established technical jargon (register, cache, commit, branch, framework). Do not translate those into Chinese.
    - Ordinary verbs, adverbs, and connectives are always Chinese. Write "現在我們開始", never "Now 我們開始"; write "這個情況有點麻煩", never "這個 case 有點 tricky". Mixing English into a sentence that already has a natural Chinese form is 晶晶體 and reads as affected, not technical.
- Do NOT use 破折號 (dash) or full-width punctuation marks (全形標點符號).
- Please speak like a real human, not a robot or an LLM.
- If you really need to run a Python script, use uv as the package manager.
- Do not create or update comments on any internal or external site unless you have permission.
- Prefer `rg` over `grep` for better performance, since it is a Rust-based grep. If `rg` returns wrong results due to string handling issues, fall back to `grep` to ensure correctness.
- All agent skills are located under `~/.agents/skills`.
- Memory stays your own mechanism's job. The `agent-memory` skill adds a shared store on top of it: search that store when work done on another machine might already hold the answer, and mirror a memory into it right after you record one the normal way.
- Default to doing the work yourself; delegate when the reading or the item count would not fit comfortably in the main conversation. Size the fleet to the change, not to the budget: a one-file diff gets one reviewer at most. High effort and ultracode raise the ceiling, they are not an instruction to fill it. Always tell the worker what shape to return, and treat what comes back as a summary of work you never saw: spot-check anything you would commit or report.
    - `Subagents`: the default when you delegate. Claude picks what to spawn turn by turn, and each result lands back in the main context (e.g. a broad search, reading many files, or running a noisy command when only its verdict matters). Each starts fresh with no shared state, they only report up and never talk to each other, and a few in parallel already covers most fan-out.
    - `Workflow`: the plan moves into a script, so the loops, the branching, and every intermediate result live in script variables while only the final answer reaches the main context. Use it when the agent count outgrows what one conversation can coordinate (dozens is normal; the runtime queues them 16 at a time), when a stage must branch or loop on what agents return, or when the orchestration itself is worth saving as a rerunnable command. E.g. the plan is settled and fifteen files each need their own edit; one agent per file, each reporting only what it changed or that it found nothing matching.
    - `Agent Team`: peers that message each other directly and claim from a shared task list, instead of workers reporting up. Only when they must argue: competing hypotheses where each teammate actively tries to disprove the others, so the theory left standing is not just the first plausible one. 3 to 5 is the useful range; they cost far more than subagents and cannot edit the same files without clobbering each other.
- Optional, only when your tooling lets you pick the model for a delegated task (the main thread always keeps its own; no such option means skip this and delegate as usual):
    - Default to inheriting the main thread's model. A downgrade saves almost nothing on a single delegation and only pays off at scale (e.g. a Workflow fanning out many agents over a mechanical stage), while a wrong or shallow answer costs far more than the tokens it saved. The usual override is one step down, for clearly lighter work.
    - The test for dropping to the smallest model: would you have to read and judge the result to know it is correct? If yes, do not. It is only for judgement-free execution whose output verifies mechanically (a diff, a re-run, a spot check): running a command and reporting the output, collecting file contents, simple searches, mass renaming, reformatting. Tell it to return the raw result without interpreting it. Analysis, design decisions, debugging, and code that will be committed never qualify.
    - Reasoning effort / thinking budget follows the same test. Lowering it is gentler than dropping model levels, so prefer it. High effort is not free quality either: on a simple task it invites overthinking and second-guesses a correct answer into a worse one.

## Text formatting

- Do not reflow human-written prose.
- Do not hard-wrap Markdown or documentation text to 72, 80, or 100 columns. IDEs and editors should handle visual wrapping.
- When modifying documents, make the smallest textual diff possible and preserve the surrounding line structure.
- A paragraph should usually stay as one logical line unless the existing file consistently uses manual wrapping.
- Code comments should be short and straightforward; do not include too many details.

## For GitHub Repositories Only

These rules only apply to repositories hosted on GitHub.

- When building a plan to develop a project:
    - Do not forget to include linting, formatting, and testing steps before drafting a PR in the plan.
    - After making changes, review them with the appropriate skill if one exists.
    - Open the PR as a draft and keep it that way until all actions pass.
    - Once they pass, ask if the user wants to mark it ready for review.
- Anything published to GitHub must be written in English only, including PR titles and bodies, issue titles and bodies, comments, and review replies.
- Update the documentation if needed.
- Feel free to update the plan and the PR body as things change, since plans always do.
- If a task is large or complex, split it into several focused commits, each one a self-contained logical step.
    - Everything still lands in a single PR, so the number of commits does not matter; more granular commits just make the changes easier to track, review, and revert.
- If a change is small, you can ask if the user wants to commit and push it directly to the default branch instead of opening a PR.
    - Linting, formatting, and testing are still required.
- Whenever something worth doing later shows up (an improvement idea, a bug that does not belong in the current PR, or any follow-up outside the current scope), ask the user whether to open an issue to track it. The `create-issue` skill owns what goes in it.
- When you are asked to work on an existing issue, that is when the detailed plan gets written.
    - Write the plan into the issue body under the placeholder, or post it as a comment, before starting the work.
    - Keep it updated as the plan changes, so the issue stays a usable trace of what happened.
