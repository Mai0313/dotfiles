## General

- Do NOT solve the error by hiding it, you should find the root cause first then solve it.
- All commit messages should be in English and follow conventional commits rules.
    - The commit message should be short, DO NOT INCLUADE ANY IMPLEMENT DETAILS.
- The user prefers responses in Traditional Chinese.
    - Write natural Traditional Chinese sentences. Do NOT deliberately mix English words into sentences when a natural Chinese expression exists.
    - However, when technical terms, computer science jargon, hardware terminology, or variable names come up, keep them in their original English form instead of translating them into Chinese (e.g., register, cache, commit, branch, framework).
- Do NOT use 破折號 (dash) and full-width punctuation marks (全形標點符號)
- Please speak like a real human, not a robot or LLM model.
- Commit messages must be in English.
- If you really need to run a Python script, you can use uv as a package management tool.
- Do not create or update any comment on internal site or external site only if you got the permission.
- Prefer `rg` over `grep` for better performance, since it is a rust based grep. If `rg` returns wrong results due to string handling issues, fall back to `grep` to ensure correctness.
- You can create/use `Subagents` / `Agent Team` / `Workflow` to run multiple tasks at the same time for better performance. Pick one based on how the work needs to be coordinated:
    - `Subagents`: use for a single independent fire-and-forget task where you only need the final result back (e.g. a broad search or reading many files). Each call starts fresh with its own context and shares no state with others.
    - `Agent Team`: use when several named agents must collaborate and exchange information dynamically, coordinating back and forth via `SendMessage` while keeping their context alive. The model decides the flow at runtime.
    - `Workflow`: use for large-scale, repeatable, or multi-stage work where the control flow (loops, fan-out, pipelines) should be deterministic and defined in code rather than improvised by the model. Prefer it over plain `Subagents` whenever there are multiple stages or many items.

## Text formatting

- Do not reflow human-written prose.
- Do not hard-wrap Markdown or documentation text to 72, 80, or 100 columns. IDEs and editors should handle visual wrapping.
- When modifying documents, make the smallest textual diff possible and preserve the surrounding line structure.
- A paragraph should usually stay as one logical line unless the existing file consistently uses manual wrapping.
- Code comments should be short and straightforward; do not include too many details.

## For Github Repository Only

These rules are only applied to those repository hosted on Github

- When building a plan to develop a project hosted on GitHub
    - Do not forget to include linting, formatting, and testing steps before draft a PR in the plan.
    - After making changes, you can use the appropriate skill on your own to review them if skill exists.
    - The PR should be kept as draft before all actions are passed.
    - After all actions are passed, you can ask if user wants to change the PR to ready for review.
- Update all the documents if needed.
- Do not forget to create a draft PR as part of the plan; the PR body must be written in English.
- Feel free to modify the PR body if needed since plan always changes.
- Feel free to add or adjust additional information in the plan when needed.
- If a change is small, you can ask if the user wants to commit and push it directly to default branch instead of opening a PR.
    - linting, formatting, and testing steps are still required even if the change is small.
