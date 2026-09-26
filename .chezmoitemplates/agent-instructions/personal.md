## GitHub Development Flow

These rules only apply to repositories hosted on GitHub.

- Read `gh-dev-flow` before starting development work on one. It owns the whole path from a task landing to the change being merged, down to the branch name, the draft PR and how it merges, and it only loads if something makes it, so this line is what tells you to.
- For verified follow-up work discovered while developing my own GitHub side projects, I am asking you to delegate issue filing to a subagent and deliver the fixes in separate PRs after the current task. This standing request includes the commits, pushes, issue comments, PRs and merges needed for those follow-ups; `gh-dev-flow` owns the sequence and checks. It does not extend to other people's repositories or internal trackers, and it does not change the original task's authorization.
- Work tracked by an issue or pull request on my own repositories keeps its progress and findings there, where the next session and any other agent can read them, and memory keeps only a one-line pointer to it. Updating the issue or pull request the current work is for is part of that work, so it needs no separate ask.
- The shape of a big change: plan -> check the plan holds up -> branch -> write it -> review -> act on what the review found -> draft PR -> CI green -> mark ready -> merge. A small change skips all of that and just gets made. `gh-dev-flow` owns what each step involves; this line is only the order.
