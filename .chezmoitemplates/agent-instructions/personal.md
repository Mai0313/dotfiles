## GitHub Development Flow

These rules only apply to repositories hosted on GitHub.

- Read `gh-dev-flow` before starting development work on one. It owns the whole path from a task landing to the change being merged, down to the branch name, the draft PR and how it merges, and it only loads if something makes it, so this line is what tells you to.
- The shape of a big change: plan -> check the plan holds up -> branch -> write it -> review -> act on what the review found -> draft PR -> CI green -> mark ready -> merge. A small change skips all of that and just gets made. `gh-dev-flow` owns what each step involves; this line is only the order.
