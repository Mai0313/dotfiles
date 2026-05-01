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

**Layer 1 — chezmoi data (`.chezmoi.toml.tmpl`).** Computed at `chezmoi init` time and emitted to `~/.config/chezmoi/chezmoi.toml`. The template intentionally pre-computes a wide superset (CPU, chassis, distro / kernel / macOS / Windows fields) so future templates can reference any of them without forcing a re-init — even if today only a handful are consumed.

Top-level booleans + identifiers under `[data]`:

| Variable | Default | Condition / Use |
|---|---|---|
| `is_setup` | `false` | Auto-managed via sentinel file. `setup-body.sh` touches `{{ .chezmoi.cacheDir }}/bootstrap-done` after a successful run; the template flips `is_setup` to `true` whenever the sentinel exists. To force a re-run: delete the sentinel, then `chezmoi init --force && chezmoi apply`. No manual `chezmoi.toml` edits required in normal flow. |
| `is_work` | `false` | FQDN ends with `.c.googlers.com` or `.roam.internal` |
| `is_cloudtop` | `false` | FQDN ends with `.c.googlers.com` |
| `is_codespace` | `false` | env `CODESPACES=true` |
| `is_devcontainer` | `false` | env `REMOTE_CONTAINERS` or `DEVCONTAINER` set (VS Code Dev Containers) |
| `is_container` | `false` | `/.dockerenv` or `/run/.containerenv` exists (generic Docker / Podman) |
| `is_wsl` | `false` | Linux + `/proc/sys/kernel/osrelease` contains `microsoft` |
| `is_ssh` | `false` | env `SSH_CONNECTION` / `SSH_CLIENT` / `SSH_TTY` set |
| `is_ci` | `false` | env `CI=true` or `GITHUB_ACTIONS` set |
| `osid` | `"linux-<id>"` / `"darwin"` / `"windows"` | Combined OS+distro identifier (e.g. `linux-ubuntu`, `linux-debian`) for clean `eq` comparisons |
| `chassis` | `"desktop"` | `hostnamectl --json=short \| mustFromJson` on Linux; `system_profiler SPHardwareDataType` on darwin (presence of `MacBook` → laptop); `Get-CimInstance Win32_Battery` count via `pwsh.exe` on Windows. Overridden to `"container"` / `"vm"` when `is_container` / `is_wsl` are true. Tracks [chezmoi general docs](https://www.chezmoi.io/user-guide/machines/general/). |

Nested namespaces (always emitted, with empty strings / zero on irrelevant OSes — safe to reference unconditionally):

- `[data.cpu]` — `cores` (physical) / `threads` (logical). darwin: `sysctl hw.physicalcpu_max` / `hw.logicalcpu_max`. linux: `lscpu --online --parse` (deduped by socket+core for physical, raw row count for logical), with `nproc` fallback if `lscpu` is missing. windows: `Get-CimInstance Win32_Processor` via `pwsh.exe`. Implementation tracks the patterns in [chezmoi general docs](https://www.chezmoi.io/user-guide/machines/general/).
- `[data.linux]` — `distro_id`, `distro_id_like`, `distro_version_id`, `distro_version_codename`, `distro_pretty_name`, `kernel_release`, `kernel_ostype` (sourced from `.chezmoi.osRelease` and `.chezmoi.kernel`)
- `[data.darwin]` — `computer_name` (`scutil --get ComputerName`), `build_version` / `product_version` (`sw_vers`), `model` (`sysctl hw.model`)
- `[data.windows]` — `product_name`, `display_version`, `current_build`, `edition_id` (sourced from `.chezmoi.windowsVersion` registry data)

OS detection comes from chezmoi built-ins: `eq .chezmoi.os "linux"` / `"darwin"` / `"windows"`. For Linux distro variants prefer `eq .osid "linux-debian"` over chained `hasKey` checks.

**Note**: `.chezmoi.toml.tmpl` runs at `chezmoi init`, not at every `chezmoi apply`. Adding a new data key (like `is_setup`) requires `chezmoi init --force` once to regenerate `~/.config/chezmoi/chezmoi.toml`. Templates that read `is_setup` use `index . "is_setup"` (rather than `.is_setup`) so missing keys default to nil → `not nil` → treated as `false` → setup runs. This keeps the change backward-compatible without forcing a re-init. New keys added later should use the same `index . "<key>"` pattern when used by a template that may run before the user re-inits.

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

- `.chezmoi.toml.tmpl` — chezmoi config, defines top-level flags (`is_setup` / `is_work` / `is_cloudtop` / `is_codespace` / `is_devcontainer` / `is_container` / `is_wsl` / `is_ssh` / `is_ci`), identifiers (`osid`, `chassis`), and nested `[data.cpu]` / `[data.linux]` / `[data.darwin]` / `[data.windows]` sections. See Layer 1 table above for the full schema.
- `.chezmoiexternal.toml.tmpl` — declarative external dependencies (oh-my-zsh, p10k, zsh plugins, `.agents` skills repo, work-only ADB security repo). All `type = "git-repo"` with `--depth=1` and `--ff-only` pull.
- `.chezmoidata/packages.yaml` — declarative OS package lists (darwin / linux), consumed by `.chezmoitemplates/setup-body.sh`. Adding a package: edit YAML, delete the bootstrap sentinel (`rm ~/.cache/chezmoi/bootstrap-done`), `chezmoi init --force`, then `chezmoi apply`. Setup re-runs and recreates the sentinel.
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

#### `is_setup` sentinel workflow

`is_setup` is auto-managed via a sentinel file. The source of truth is the existence of `{{ .chezmoi.cacheDir }}/bootstrap-done` (resolves to `~/.cache/chezmoi/bootstrap-done` on Linux/macOS).

1. **First-time apply on a fresh machine**: no sentinel → `is_setup = false` → `run_onchange_after_setup.sh.tmpl` renders the full body and runs. The last line of `setup-body.sh` (section 6) `touch`es the sentinel.
2. **Subsequent `chezmoi apply` on the same machine**: sentinel still present → `is_setup` would render `true` if you `chezmoi init --force`, but on plain `apply` the saved `chezmoi.toml` is reused as-is and the script body's hash is unchanged → no rerun. Either way, no spurious bootstrap.
3. **`chezmoi init --force` after editing `.chezmoi.toml.tmpl` / adding new data keys**: sentinel exists → `is_setup = true` is preserved automatically. **No manual flip required** (this is the whole reason the sentinel design exists).
4. **Force re-run** (e.g., after adding a package to `.chezmoidata/packages.yaml`): `rm "$(chezmoi cache-path 2>/dev/null || echo $HOME/.cache/chezmoi)/bootstrap-done" && chezmoi init --force && chezmoi apply`. Setup re-runs, recreates the sentinel automatically.

Trade-off: if `~/.cache/` is wiped (some users do this aggressively), the next `chezmoi init` would set `is_setup = false` and the next `apply` would re-run the bootstrap. Each section of `setup-body.sh` is idempotent so this is harmless, just slow once.

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
