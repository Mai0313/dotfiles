## General

- Do NOT solve an error by hiding it. Find the root cause first, then fix it.
- All commit messages should be in English and follow conventional commits rules.
    - The commit message should be short, DO NOT INCLUDE ANY IMPLEMENTATION DETAILS.
- The user prefers responses in Traditional Chinese.
    - Write natural Traditional Chinese sentences. Do NOT deliberately mix English words into sentences when a natural Chinese expression exists.
    - However, when technical terms, computer science jargon, hardware terminology, or variable names come up, keep them in their original English form instead of translating them into Chinese (e.g., register, cache, commit, branch, framework).
- Do NOT use 破折號 (dash) or full-width punctuation marks (全形標點符號).
- Please speak like a real human, not a robot or an LLM.
- If you really need to run a Python script, use uv as the package manager.
- Do not create or update comments on any internal or external site unless you have permission.
- Prefer `rg` over `grep` for better performance, since it is a Rust-based grep. If `rg` returns wrong results due to string handling issues, fall back to `grep` to ensure correctness.
- You can create/use `Subagents` / `Agent Team` / `Workflow` to run multiple tasks at the same time for better performance. Pick one based on how the work needs to be coordinated:
    - `Subagents`: use for a single independent fire-and-forget task where you only need the final result back (e.g. a broad search or reading many files). Each call starts fresh with its own context and shares no state with others.
    - `Agent Team`: use when several named agents must collaborate and exchange information dynamically, coordinating back and forth via `SendMessage` while keeping their context alive. The model decides the flow at runtime.
    - `Workflow`: use for large-scale, repeatable, or multi-stage work where the control flow (loops, fan-out, pipelines) should be deterministic and defined in code rather than improvised by the model. Prefer it over plain `Subagents` whenever there are multiple stages or many items.
- Optional, only when your tooling offers it: when you delegate a task you may also pick which model runs it, for example a smaller and faster one. This applies to the delegated task only; the main thread keeps its own model. If there is no way to select a model, ignore this and delegate as usual.
    - Think of the available models as a ladder from most to least capable, and default to one step down. When unsure how heavy a task is, stay on the default model: a wrong or shallow answer costs far more than the tokens it saved.
    - Only jump several steps down, to the smallest and fastest model, when you are certain the task is pure execution with no judgement in it: running a command and reporting what it printed, collecting file contents, simple searches, mass renaming, or reformatting. Tell it to return the raw result without interpreting it. Analysis, design decisions, debugging, and code that will be committed never qualify.
    - If your tooling exposes reasoning effort or thinking budget, with or without a model choice, apply the same judgement there. Lowering it is gentler than dropping several model levels, so prefer it. High effort is not free quality either: on a simple task it invites overthinking, and a correct answer gets second-guessed into a worse one.

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
    - Keep the PR as a draft until all actions pass.
    - Once they pass, ask if the user wants to mark it ready for review.
- Anything published to GitHub must be written in English only, including PR titles and bodies, issue titles and bodies, comments, and review replies.
- Update the documentation if needed.
- Do not forget to create a draft PR as part of the plan.
- Feel free to update the plan and the PR body as things change, since plans always do.
- If a task is large or complex, split it into several focused commits, each one a self-contained logical step.
    - Everything still lands in a single PR, so the number of commits does not matter; more granular commits just make the changes easier to track, review, and revert.
- If a change is small, you can ask if the user wants to commit and push it directly to the default branch instead of opening a PR.
    - Linting, formatting, and testing are still required.
- Whenever something worth doing later shows up (an improvement idea, a bug that does not belong in the current PR, or any follow-up outside the current scope), ask the user whether to open an issue to track it.
    - A new issue captures the idea and the requirement only: what was observed, why it matters, what the desired outcome is.
    - Do not write the design or the implementation plan into a new issue. Leave a `## Plan` section with `TBD` as a placeholder.
    - The reason is context pollution: a plan drafted in the middle of another task carries that task's assumptions and biases whoever picks the issue up later. Keep that freedom for them.
- When you are asked to work on an existing issue, that is when the detailed plan gets written.
    - Write the plan into the issue body under the placeholder, or post it as a comment, before starting the work.
    - Keep it updated as the plan changes, so the issue stays a usable trace of what happened.
