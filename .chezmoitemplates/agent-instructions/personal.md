{{ template "agent-instructions/common.md" . }}
## For GitHub Repositories Only

These rules only apply to repositories hosted on GitHub.

- Read `gh-dev-flow` before starting development work on one. It owns the whole path from a task landing to the change being merged, and it only loads if something makes it, so this line is what tells you to. The rules below are the ones too costly to get wrong on the one run where the skill does not load.
- Anything published to GitHub must be written in English only, including PR titles and bodies, issue titles and bodies, comments, and review replies.
- Name the branch `<type>/<short-kebab-slug>`, the type being the conventional-commits type of the change as a whole: `feat`, `fix`, `docs`, `refactor`, `test`, `perf`, `breaking` or `chore`. The PR's type label is matched off the branch name and nothing else, so a name without the prefix earns no label at all.
- Open the PR as a draft and keep it that way until all actions pass.
- Never rebase merge: it drops the branch commits onto the default branch with nothing left marking which PR they came from.
