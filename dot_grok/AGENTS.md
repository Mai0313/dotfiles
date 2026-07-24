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
- All agent skills are located under `~/.agents/skill`.
- You can create/use `Subagents` / `Agent Team` / `Workflow` to run multiple tasks at the same time for better performance. Delegation also protects the main thread's context: bulk reading and intermediate output stay inside each worker's own context, and only the distilled result comes back, so large scans do not blow up the main conversation. This protection only holds if the worker actually returns a distilled result, so tell it what shape to return: an agent that dumps its raw data back into the report defeats the point. Pick one based on how the work needs to be coordinated:
    - `Subagents`: use for a single independent fire-and-forget task where you only need the final result back (e.g. a broad search or reading many files). Each call starts fresh with its own context and shares no state with others.
    - `Workflow`: the default for anything multi-stage or with many items. The control flow (loops, fan-out, pipelines) is written in script code, so it is deterministic and repeatable, yet still data-driven: the script holds the shared state and can branch or loop on agent results (e.g. keep spawning finders until a round returns nothing new). Agents inside it are stateless one-shot workers that never talk to each other; the script passes data between stages.
    - `Agent Team`: use only when an agent's own accumulated context must stay alive across multiple exchanges (via `SendMessage`), because replaying a transcript to a fresh agent would be too lossy or too expensive (e.g. a multi-round design debate where each reply builds on the previous one). If every decision point can be written down as code beforehand, use `Workflow` instead; a real team need is rare.
    - Middle ground for dynamic work: run one `Workflow` per phase, then read the results on the main thread and decide how to shape the next phase. This keeps model judgement in the loop at phase granularity without needing a team.
    - The flip side of that isolation: a delegated agent's report is not ground truth. It summarizes work you never saw, so it can be wrong, incomplete, or overconfident (e.g. claiming success it never verified). Spot-check any load-bearing claim (one you would commit, report to the user, or build the next phase on) against the actual files or command output before acting on it. Verification can itself be delegated, like an independent notary: e.g. a second wave of agents prompted to refute the first wave's findings. Reserve hands-on spot-checks on the main thread for the few most load-bearing claims, otherwise the context saved by delegating gets spent right back.
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
