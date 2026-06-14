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
- You can use `rg` instead of `grep` for better performance, this package is a rusted grep.
- You can create/use `Subagents` or `Agent Team` to run multiple tasks in the same time if you need for better performance.

## Text formatting

- Do not reflow human-written prose.
- Do not hard-wrap Markdown or documentation text to 72, 80, or 100 columns. IDEs and editors should handle visual wrapping.
- When modifying documents, make the smallest textual diff possible and preserve the surrounding line structure.
- A paragraph should usually stay as one logical line unless the existing file consistently uses manual wrapping.
- Code comments should be short and straightforward; do not include too many details.

## For Github Repository Only

These rules are only applied to those repository hosted on Github

- If the task is complicated, you can use `PlanMode` with `Subagents` or `Agent Team` to help.
- When building a plan to develop a project hosted on GitHub, do not forget to include linting, formatting, and testing steps before draft a PR in the plan.
    - The PR should be kept as draft before all actions are passed.
    - After all actions are passed, you can change the PR to ready to review.
    - After you change the PR to ready to review, please make sure copilot starts reviewing
        - Sometimes, if Github Copilot reaches its quota, it won't be able to review which is normal
- Update all the documents if needed.
- Do not forget to create a draft PR as part of the plan; the PR body must be written in English.
- Feel free to modify the PR body if needed since plan always changes.
- Feel free to add or adjust additional information in the plan when needed.
