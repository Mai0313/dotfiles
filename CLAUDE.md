# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles repo (`mai0313/dotfiles`). Deploys shell configs, IDE settings, fonts, and bootstraps the dev toolchain (oh-my-zsh, Powerlevel10k, plugins, LazyVim, OS packages) across personal machines, Google Cloudtop (work), Roam laptops, and GitHub Codespaces.

`chezmoi apply` is the single entry point — it deploys files, syncs externals, and runs the setup scripts in `.chezmoiscripts/`. There is no separate `setup.sh` to run manually.

## Common Commands

```bash
chezmoi diff          # Preview changes before applying
chezmoi apply         # Apply source state to $HOME (deploys files + runs scripts)
chezmoi re-add        # Sync local edits back to source directory
chezmoi add ~/.file   # Start managing a new file
chezmoi cd            # cd into this source directory
```

After editing templates, validate with `chezmoi execute-template < file.tmpl` or `chezmoi diff` to verify output.

## Architecture

### Chezmoi Naming Conventions

- `dot_*` -> files with leading `.` (e.g., `dot_zshrc` -> `~/.zshrc`)
- `executable_*` -> deployed with execute permission (e.g., `executable_cleanup.sh` -> `~/cleanup.sh`)
- `private_*` -> deployed with `0600` permission (no group/other read)
- `.tmpl` suffix -> processed as Go templates with chezmoi data

### Environment Detection

**This repo detects the environment in two layers for two different purposes. Do not consolidate them without understanding why.**

**Layer 1 — chezmoi data (`.chezmoi.toml.tmpl`).** Defines three variables at `chezmoi apply` time:

| Variable | Condition |
|---|---|
| `is_work` | FQDN ends with `.c.googlers.com` or `.roam.internal` |
| `is_cloudtop` | FQDN ends with `.c.googlers.com` |
| `is_codespace` | env `CODESPACES=true` |

OS detection comes from chezmoi built-ins: `eq .chezmoi.os "linux"` / `"darwin"` / `"windows"`.

**Current consumers:**
- `.chezmoiignore` — gates `.gemini/GEMINI.md` on `is_work || is_cloudtop` (it's the same content as `~/.claude/CLAUDE.md` on those machines, deduplicated). Also gates Linux-only files (`.zshrc`, `.bashrc`, `.p10k.zsh`, `cleanup.sh`) when `chezmoi.os == "windows"`.
- `.chezmoiexternal.toml.tmpl` — gates `adb-keys/security` (sso git-repo) on `is_work || is_cloudtop`; gates oh-my-zsh + plugins on `chezmoi.os != "windows"`.
- `.chezmoiscripts/run_onchange_after_40-configure-adb-pontis.sh.tmpl` — entire script body wrapped in `{{ if .is_work }}` so it renders to empty (chezmoi skips empty scripts) on personal machines.
- `.chezmoiscripts/run_once_after_20-set-default-shell.sh.tmpl` — skipped on Codespaces (shell controlled by dev container).

Inspect current values with `chezmoi data | grep -E 'is_|"os"'`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) do their own `case "$(hostname -f)"` match on the same FQDN patterns to toggle env-specific blocks (aliases, env vars). **All live gating for these mixed-content files happens here, not in chezmoi templates.**

**Why runtime, not template, for shell configs?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping `dot_zshrc` / `dot_bashrc` as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` without hand-patching the source tree. This rule applies because these files mix universal and env-specific content in the same file — runtime gating is the only option.

**Future-agent guidance: do NOT "refactor" the `dot_zshrc` / `dot_bashrc` runtime `case` blocks into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again.

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus `dot_zshrc` and `dot_bashrc` (Layer 2). If the pattern ever changes, grep for both `c.googlers.com` and `roam.internal` to find every occurrence.

### Key Files

- `.chezmoi.toml.tmpl` — chezmoi config, defines `is_work` / `is_cloudtop` / `is_codespace`.
- `.chezmoiexternal.toml.tmpl` — declarative external dependencies (oh-my-zsh, p10k, zsh plugins, `.agents` skills repo, work-only ADB security repo). All `type = "git-repo"` with `--depth=1` and `--ff-only` pull. oh-my-zsh self-update via `git pull` is compatible with chezmoi's own `git pull` refresh, so `DISABLE_AUTO_UPDATE` is **not** needed.
- `.chezmoidata/packages.yaml` — declarative OS package lists (darwin / linux), consumed by `install-packages.sh.tmpl`. Adding a package = edit YAML and `chezmoi apply`.
- `.chezmoiignore` — keeps `install.sh`, READMEs, `CLAUDE.md` from being deployed; OS- and env-gated exclusions.
- `.chezmoiscripts/` — see "Setup Scripts" below.
- `dot_zshrc` / `dot_bashrc` — shell configs. Plain (non-`.tmpl`) so `chezmoi re-add` works.
- `dot_p10k.zsh` — Powerlevel10k prompt theme (lean style, NerdFont).
- `dot_claude/settings.json`, `dot_gemini/settings.json`, `dot_codex/private_config.toml` — IDE / agent settings.
- `executable_cleanup.sh` — ad-hoc cleanup utility (NOT auto-run; deployed as `~/cleanup.sh` for manual use).
- `install.sh` — Codespace bootstrap one-liner; runs `chezmoi init --apply`. Not deployed to `$HOME`.

### Shell Config Structure

Both `dot_zshrc` and `dot_bashrc` share the same pattern:
1. PATH extensions (Go, Rust, Cargo, Miniconda, Neovim)
2. NVM lazy loading
3. Common aliases (`cc='claude'`, `cop='copilot'`)
4. Runtime-gated environment block — FQDN `case` matching `*.c.googlers.com|*.roam.internal` (work: `ADB_VENDOR_KEYS`) and `*.c.googlers.com` (Cloudtop: `gemini`, `jetski-cli`, `flash`, `recovery`, `listd` aliases). No-op on personal machines.
5. Editor selection (vim over SSH, nvim locally)

### Setup Scripts (`.chezmoiscripts/`)

Files in `.chezmoiscripts/` are **not** deployed to `$HOME`. They run as part of `chezmoi apply` according to their filename prefix.

There is one script: `run_onchange_after_setup.sh.tmpl`. It contains five idempotent sections:

1. OS packages — apt + VS Code repo + Neovim PPA + lazygit GitHub release on Linux; brew on darwin. Package list lives in `.chezmoidata/packages.yaml`.
2. Font cache refresh — `fc-cache -f` (Linux only).
3. Default shell — `chsh -s zsh` (skipped on Codespaces because dev container controls the shell).
4. LazyVim starter — `git clone` into `~/.config/nvim` only if absent.
5. Work-only ADB systemd env + pontisd restart — gated by `{{ if .is_work }}`, renders to nothing on personal machines.

The whole script is wrapped in `{{ if ne .chezmoi.os "windows" }}` so Windows skips it entirely.

**Why one script and not five?** Earlier iteration split this five ways (`run_once_*`, `run_onchange_before_*`, etc.) but every step is already idempotent (each guards with `if [ ! -d ... ]` / `command -v` / `if [ "$SHELL" != ... ]`), so the split bought nothing except more files. `run_onchange_` triggers a re-run whenever rendered content changes (e.g., adding a package to `packages.yaml`); steps that have already taken effect become no-ops.

**Naming format**: `run_[once_|onchange_][before_|after_]<name>.sh.tmpl`
- `run_onchange_` — re-runs when rendered content hash changes
- `run_once_` — runs once per content hash
- `before_` / `after_` — before or after files are deployed
- See <https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/> for the full ordering rules

**Empty-template skip idiom.** chezmoi treats a template that renders to whitespace/empty as "no script", so wrapping the entire body in `{{ if ... }}` is the canonical way to gate a script per environment. The Windows wrap above and the work-only ADB section are both examples.

### Externals (`.chezmoiexternal.toml.tmpl`)

| Path | URL | Refresh | Condition |
|---|---|---|---|
| `.agents` | `Mai0313/skills` (GitHub) | 12h | always |
| `.oh-my-zsh` | `ohmyzsh/ohmyzsh` (GitHub) | 12h | non-Windows |
| `.oh-my-zsh/custom/themes/powerlevel10k` | `romkatv/powerlevel10k` | 12h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-autosuggestions` | `zsh-users/zsh-autosuggestions` | 12h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-syntax-highlighting` | `zsh-users/zsh-syntax-highlighting` | 12h | non-Windows |
| `adb-keys/security` | `sso://googleplex-android/.../security` | 12h | `is_work \|\| is_cloudtop` |

All use `type = "git-repo"` with `--depth=1` and `--ff-only`. Pulling on chezmoi's schedule is compatible with oh-my-zsh's own `git pull`-based self-update — no need to disable oh-my-zsh auto-update.

### Why externals (git-repo) instead of script-based clones?

Previous design: `executable_setup.sh` did `git clone --depth=1` for each plugin, and `executable_setup_adb.sh` cloned the security repo. Drawbacks:
- Manual `~/setup.sh` step on every new machine
- No automatic refresh — plugins/oh-my-zsh stayed at first-clone version
- Logic spread across bash scripts instead of declarative TOML

Current design: chezmoi clones and refreshes them as part of `chezmoi apply`. The bash scripts are gone.

### Why `run_once_` for LazyVim instead of an external?

`type = "git-repo"` would re-pull the LazyVim starter on every refresh, overwriting user customizations to `~/.config/nvim`. The starter is meant to be cloned once and then modified. `run_once_` matches this lifecycle precisely — clones if `~/.config/nvim` is absent, otherwise no-op, regardless of upstream changes.
