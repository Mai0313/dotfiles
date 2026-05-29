## General

- Do NOT solve the error by hiding it, you should find the root cause first then solve it.
- All commit messages should be in English and follow conventional commits rules.
    - The commit message should be short, DO NOT INCLUADE ANY IMPLEMENT DETAILS.
- The user prefers responses in Traditional Chinese.
    - CRITICAL: DO NOT translate technical terms, computer science jargon, hardware terminology, or variable names into Chinese. Keep them in their original English form.
    - Examples of terms to keep in English: bit, register, cache, assembly, cluster, core, offset, commit, branch, patchset, framework, etc.
    - It is preferred to mix English technical terms naturally into the Traditional Chinese sentences (e.g., "這個 register 的 bit 偏移量..." instead of "這個暫存器的位元偏移量...").
    - Please speak like a real human, not a robot or LLM model.
    - Do NOT use 破折號 (dash)
- Commit messages must be in English.
- If you really need to run a Python script, you can use uv as a package management tool.
- Do not create or update any comment on internal site or external site only if you got the permission.
- Update all the documents if needed.
- You can use `rg` instead of `grep` for better performance, this package is a rusted grep.
- You can use `subagent` or `Agent Team` to run multiple tasks in the same time if you need for speeding up.
- For those project on Github
    - When building a plan to develop a project hosted on GitHub, do not forget to include linting, formatting, and testing steps before draft a PR in the plan.
        - The PR should be kept as draft before all actions are passed.
        - After all actions are passed, you can change the PR to ready to review.
    - Do not forget to create a draft PR as part of the plan; the PR body must be written in English.
    - Feel free to modify the PR body if needed since plan always changes.
    - Feel free to add or adjust additional information in the plan when needed.

## Text formatting

- Do not reflow human-written prose.
- Do not hard-wrap Markdown or documentation text to 72, 80, or 100 columns. IDEs and editors should handle visual wrapping.
- When modifying documents, make the smallest textual diff possible and preserve the surrounding line structure.
- A paragraph should usually stay as one logical line unless the existing file consistently uses manual wrapping.
