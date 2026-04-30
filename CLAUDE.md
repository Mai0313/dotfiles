# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles repo (`mai0313/dotfiles`). Deploys shell configs, IDE settings, fonts, and bootstraps the dev toolchain (oh-my-zsh, Powerlevel10k, plugins, LazyVim, OS packages) across personal machines, Google Cloudtop (work), Roam laptops, and GitHub Codespaces.

Bootstrap has two entry points that share the same body via `.chezmoitemplates/setup-body.sh`:

- **chezmoi-driven** (`.chezmoiscripts/run_onchange_after_setup.sh.tmpl`) — runs automatically as part of `chezmoi apply`, gated by `is_setup` flag and OS.
- **manual** (`executable_setup.sh.tmpl` → `~/setup.sh`) — deployed to home for opt-in manual execution; not deployed on Windows.

## Common Commands

```bash
chezmoi diff          # Preview changes before applying
chezmoi apply         # Apply source state to $HOME (deploys files + may run setup script)
chezmoi re-add        # Sync local edits back to source directory
chezmoi add ~/.file   # Start managing a new file
chezmoi cd            # cd into this source directory
chezmoi init --force  # Re-evaluate .chezmoi.toml.tmpl (e.g., after adding new data keys)
```

After editing templates, validate with `chezmoi execute-template < file.tmpl` or `chezmoi diff` to verify output.

## Architecture

### Chezmoi Naming Conventions

- `dot_*` -> files with leading `.` (e.g., `dot_zshrc` -> `~/.zshrc`)
- `executable_*` -> deployed with execute permission (e.g., `executable_cleanup.sh` -> `~/cleanup.sh`)
- `private_*` -> deployed with `0600` permission (no group/other read)
- `.tmpl` suffix -> processed as Go templates with chezmoi data
- `.chezmoitemplates/<name>` -> shared template fragments included with `{{ template "<name>" . }}`

### Environment Detection

**This repo detects the environment in two layers for two different purposes. Do not consolidate them without understanding why.**

**Layer 1 — chezmoi data (`.chezmoi.toml.tmpl`).** Defines four variables at `chezmoi init` time:

| Variable | Default | Condition / Use |
|---|---|---|
| `is_work` | `false` | FQDN ends with `.c.googlers.com` or `.roam.internal` |
| `is_cloudtop` | `false` | FQDN ends with `.c.googlers.com` |
| `is_codespace` | `false` | env `CODESPACES=true` |
| `is_setup` | `false` | User-controlled. Set to `true` in `~/.config/chezmoi/chezmoi.toml` after first successful bootstrap to skip the chezmoi-driven setup script on subsequent applies. Flip back to `false` to re-run (e.g., after editing `.chezmoidata/packages.yaml`). |

OS detection comes from chezmoi built-ins: `eq .chezmoi.os "linux"` / `"darwin"` / `"windows"`.

**Note**: `.chezmoi.toml.tmpl` runs at `chezmoi init`, not at every `chezmoi apply`. Adding a new data key (like `is_setup`) requires `chezmoi init --force` once to regenerate `~/.config/chezmoi/chezmoi.toml`. Templates that read `is_setup` use `index . "is_setup"` (rather than `.is_setup`) so missing keys default to nil → `not nil` → treated as `false` → setup runs. This keeps the change backward-compatible without forcing a re-init.

**Current consumers of Layer 1 vars:**
- `.chezmoiignore` — gates `.gemini/GEMINI.md` on `is_work || is_cloudtop`. Also gates Linux-only files (`.zshrc`, `.bashrc`, `.p10k.zsh`, `cleanup.sh`, `setup.sh`) when `chezmoi.os == "windows"`.
- `.chezmoiexternal.toml.tmpl` — gates `adb-keys/security` (sso git-repo) on `is_work || is_cloudtop`; gates oh-my-zsh + plugins on `chezmoi.os != "windows"`.
- `.chezmoiscripts/run_onchange_after_setup.sh.tmpl` — outer gate `{{ if and (ne .chezmoi.os "windows") (not (index . "is_setup")) }}`. Inner sections additionally gate by `is_work` (ADB pontis), `is_codespace` (chsh skip), `chezmoi.os` (apt vs brew vs fc-cache).
- `.chezmoitemplates/setup-body.sh` — inherits all Layer 1 vars when included.

Inspect current values with `chezmoi data | grep -E 'is_|"os"'`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) do their own `case "$(hostname -f)"` match on the same FQDN patterns to toggle env-specific blocks (aliases, env vars). **All live gating for these mixed-content files happens here, not in chezmoi templates.**

**Why runtime, not template, for shell configs?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping `dot_zshrc` / `dot_bashrc` as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` without hand-patching the source tree. This rule applies because these files mix universal and env-specific content in the same file — runtime gating is the only option.

**Future-agent guidance: do NOT "refactor" the `dot_zshrc` / `dot_bashrc` runtime `case` blocks into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again.

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus `dot_zshrc` and `dot_bashrc` (Layer 2). If the pattern ever changes, grep for both `c.googlers.com` and `roam.internal` to find every occurrence.

### Key Files

- `.chezmoi.toml.tmpl` — chezmoi config, defines `is_setup` / `is_work` / `is_cloudtop` / `is_codespace`.
- `.chezmoiexternal.toml.tmpl` — declarative external dependencies (oh-my-zsh, p10k, zsh plugins, `.agents` skills repo, work-only ADB security repo). All `type = "git-repo"` with `--depth=1` and `--ff-only` pull.
- `.chezmoidata/packages.yaml` — declarative OS package lists (darwin / linux), consumed by `.chezmoitemplates/setup-body.sh`. Adding a package = edit YAML and `chezmoi apply` (after flipping `is_setup` back to `false`).
- `.chezmoitemplates/setup-body.sh` — shared bash body used by both bootstrap entry points. Contains: OS packages, font cache refresh, chsh, LazyVim install, work-only ADB pontisd setup. Each section is internally idempotent.
- `.chezmoiscripts/run_onchange_after_setup.sh.tmpl` — chezmoi-driven entry. Thin wrapper around `setup-body.sh`, gated by `is_setup` and OS. Runs at `chezmoi apply` when rendered content changes.
- `executable_setup.sh.tmpl` — manual entry, deployed to `~/setup.sh`. Same body, no gates (user runs it intentionally). Not deployed on Windows (`.chezmoiignore`).
- `.chezmoiignore` — keeps `install.sh`, READMEs, `CLAUDE.md` from being deployed; OS- and env-gated exclusions.
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

### Bootstrap Architecture

Two entry points share `.chezmoitemplates/setup-body.sh`. The body has five idempotent sections:

1. **OS packages** — apt + VS Code repo + Neovim PPA + lazygit GitHub release on Linux; brew on darwin. Package list lives in `.chezmoidata/packages.yaml`.
2. **Font cache refresh** — `fc-cache -f` (Linux only).
3. **Default shell** — `chsh -s zsh` (skipped on Codespaces because dev container controls the shell).
4. **LazyVim starter** — `git clone` into `~/.config/nvim` only if absent. Deliberately a script clone (not a chezmoi external) because LazyVim is meant to be customized after first install — an external would re-pull and clobber user edits.
5. **Work-only ADB systemd env + pontisd restart** — gated by `{{ if and .is_work (eq .chezmoi.os "linux") }}`, renders to nothing elsewhere.

#### Entry point 1: chezmoi-driven (`.chezmoiscripts/run_onchange_after_setup.sh.tmpl`)

Auto-runs as part of `chezmoi apply`. Wrapped in:

```
{{ if and (ne .chezmoi.os "windows") (not (index . "is_setup")) }}
{{ template "setup-body.sh" . }}
{{ end }}
```

`run_onchange_` triggers re-run whenever rendered content changes (packages.yaml edits, switching OS/work/codespace env). Each body section is idempotent so re-runs are harmless.

#### Entry point 2: manual (`executable_setup.sh.tmpl` → `~/setup.sh`)

Always deployed (except Windows). Contains only `{{ template "setup-body.sh" . }}` — no `is_setup` gate, since user runs it intentionally. Useful when you want to bootstrap on a machine where `is_setup=true` is set, or to re-run only the script portion without invoking chezmoi.

#### Why share via `.chezmoitemplates`?

The chezmoi-driven and manual paths must stay byte-identical. Putting body in `.chezmoitemplates/setup-body.sh` and including from both entries prevents drift. Verify with:

```bash
diff <(chezmoi execute-template < .chezmoiscripts/run_onchange_after_setup.sh.tmpl) \
     <(chezmoi execute-template < executable_setup.sh.tmpl)
# Expected: no output (identical) when is_setup is false/missing on non-Windows
```

#### `is_setup` flag workflow

1. First-time apply: `is_setup` missing or `false` → setup runs, installs everything.
2. After successful bootstrap, edit `~/.config/chezmoi/chezmoi.toml`:
   ```toml
   [data]
       is_setup = true
   ```
3. Subsequent `chezmoi apply` skips the chezmoi-driven setup. `~/setup.sh` is still deployed and can be run manually.
4. To re-run after adding a package: flip `is_setup = false`, `chezmoi apply`, flip back to `true`.

#### Shebang trim caveat

The chezmoi-driven script gate uses `{{- if ... -}}` (with both `-`) so the body's `#!/usr/bin/env bash` lands on line 1 of the rendered file. A leading newline causes `fork/exec` to fail with `exec format error` because the kernel doesn't see `#!` at byte 0. Always check `chezmoi execute-template < <script>.tmpl | head -c 2` returns `#!` after editing the gate.

### Externals (`.chezmoiexternal.toml.tmpl`)

| Path | URL | Refresh | Condition |
|---|---|---|---|
| `.agents` | `Mai0313/skills` (GitHub) | 12h | always |
| `.oh-my-zsh` | `ohmyzsh/ohmyzsh` (GitHub) | 12h | non-Windows |
| `.oh-my-zsh/custom/themes/powerlevel10k` | `romkatv/powerlevel10k` | 12h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-autosuggestions` | `zsh-users/zsh-autosuggestions` | 12h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-syntax-highlighting` | `zsh-users/zsh-syntax-highlighting` | 12h | non-Windows |
| `adb-keys/security` | `sso://googleplex-android/.../security` | 12h | `is_work \|\| is_cloudtop` |

All use `type = "git-repo"` with `--depth=1` and `--ff-only`. Pulling on chezmoi's schedule is compatible with oh-my-zsh's own `git pull`-based self-update — no need to disable oh-my-zsh auto-update. Externals refresh independently of the setup script's `run_onchange_` hash.
