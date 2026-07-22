# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles repo (`mai0313/dotfiles`). Deploys shell configs, IDE settings, fonts, and bootstraps the dev toolchain (oh-my-zsh, Powerlevel10k, plugins, LazyVim, OS packages) across personal machines, Google Cloudtop (work), Roam laptops, and GitHub Codespaces.

Bootstrap has two entry points that share the same body via `.chezmoitemplates/setup-body.sh`:

- **chezmoi-driven** (`.chezmoiscripts/run_onchange_after_setup.sh.tmpl`) — runs automatically as part of `chezmoi apply`, gated by OS.
- **manual** (`executable_setup.sh.tmpl` → `~/setup.sh`) — deployed to home for opt-in manual execution; not deployed on Windows.

Windows has no bash, so it does not share this body. A separate `.chezmoiscripts/run_onchange_after_setup.ps1.tmpl` runs on Windows only: it installs the global npm CLIs, but skips the *nix-only setup.

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

**Layer 1 — chezmoi data (`.chezmoi.toml.tmpl`).** Computed at `chezmoi init` time and emitted to `~/.config/chezmoi/chezmoi.toml`. It computes exactly one value (`is_work`); anything that only affects what the setup script does is detected at runtime in the bash body instead, so it stays out of chezmoi data.

The only key under `[data]`:

| Variable | Default | Condition / Use |
|---|---|---|
| `is_work` | `false` | FQDN ends with `.c.googlers.com`, `.corp.google.com`, or `.roam.internal`. Corp Linux (gLinux/cloudtop) is `is_work && linux`; roam is `is_work && darwin`. |

OS detection comes from chezmoi built-ins: `eq .chezmoi.os "linux"` / `"darwin"` / `"windows"`, and `.chezmoi.osRelease.id` for distro variants. There is no precomputed `osid`; the built-ins already cover it.

**Note**: `.chezmoi.toml.tmpl` runs at `chezmoi init`, not at every `chezmoi apply`, so editing it needs `chezmoi init --force` once to regenerate `~/.config/chezmoi/chezmoi.toml`.

**Current consumers of `is_work`:**
- `.chezmoiignore` — gates `.gemini/GEMINI.md`. Also gates non-Windows files (`.zshrc`, `.zshenv`, `.zprofile`, `.bashrc`, `.p10k.zsh`, `cleanup.sh`, `setup.sh`, `.config/alacritty`) when `chezmoi.os == "windows"`.
- `.chezmoiexternal.toml.tmpl` — gates `adb-keys/security` (sso git-repo); gates oh-my-zsh + plugins on `chezmoi.os != "windows"`.
- `.chezmoitemplates/setup-body.sh` — §1 routes VS Code (corp Linux → google3, else Microsoft repo), §6 skips global npm on work macOS, §7 gates the ADB pontisd restart. Container and OS gating inside the body is runtime, not chezmoi data.

Inspect the current value with `chezmoi data | grep is_work`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) do their own `case` match (on `$(hostname -f 2>/dev/null || hostname)`) against the same FQDN patterns to toggle env-specific blocks (aliases, env vars). **All live gating for these mixed-content files happens here, not in chezmoi templates.**

**Why runtime, not template, for shell configs?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping `dot_zshrc` / `dot_bashrc` as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` without hand-patching the source tree. This rule applies because these files mix universal and env-specific content in the same file — runtime gating is the only option.

**Future-agent guidance: do NOT "refactor" the `dot_zshrc` / `dot_bashrc` runtime `case` blocks into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again.

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.corp.google.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus `dot_zshrc` and `dot_bashrc` (Layer 2). If the pattern ever changes, grep for `c.googlers.com`, `corp.google.com`, and `roam.internal` to find every occurrence.

### Key Files

- `.chezmoi.toml.tmpl` — chezmoi config. Computes the single `is_work` flag from the FQDN and pins `sourceDir`. See Layer 1 above.
- `.chezmoiexternal.toml.tmpl` — declarative external dependencies (oh-my-zsh, p10k, zsh plugins, `.agents` skills repo, work-only ADB security repo). All `type = "git-repo"`; the four non-Windows externals pin `--depth=1` clone and `--ff-only` pull, while `.agents` and `adb-keys/security` use plain full clones/pulls.
- `.chezmoidata/packages.yaml` — declarative OS package lists (darwin / linux) plus a cross-platform `npm_global` list of global npm CLIs, consumed by `.chezmoitemplates/setup-body.sh` (*nix) and `.chezmoiscripts/run_onchange_after_setup.ps1.tmpl` (Windows). Adding a package: edit the YAML and run `chezmoi apply` — `run_onchange` sees the changed content and re-runs setup.
- `.chezmoitemplates/setup-body.sh` — shared bash body used by both bootstrap entry points. Contains: OS packages, font cache refresh, chsh, LazyVim install, nvm + node LTS, global npm CLIs, work-only ADB pontisd setup, IBus input method. Each section is internally idempotent.
- `.chezmoiscripts/run_onchange_after_setup.sh.tmpl` — chezmoi-driven entry. Thin wrapper around `setup-body.sh`, gated by OS. Runs at `chezmoi apply` when rendered content changes.
- `.chezmoiscripts/run_onchange_after_setup.ps1.tmpl` — Windows-only chezmoi-driven entry (PowerShell). Installs the `npm_global` CLIs (skips if npm absent). Does not share `setup-body.sh` (no bash on Windows). Renders empty on non-Windows so chezmoi skips it.
- `executable_setup.sh.tmpl` — manual entry, deployed to `~/setup.sh`. Same body, no gates (user runs it intentionally). Not deployed on Windows (`.chezmoiignore`).
- `.chezmoiignore` — keeps `install.sh`, READMEs, `CLAUDE.md` from being deployed; OS- and env-gated exclusions.
- `dot_zshrc` / `dot_bashrc` — shell configs. Plain (non-`.tmpl`) so `chezmoi re-add` works.
- `dot_zshenv` / `dot_zprofile` — zsh startup hooks, currently comment-only placeholders. `.zshenv` is read by every zsh (scripts included), `.zprofile` only by login shells, before `.zshrc`. Also plain files so `re-add` works.
- `dot_p10k.zsh` — Powerlevel10k prompt theme (lean style, NerdFont).
- `dot_claude/`, `dot_gemini/`, `dot_codex/`, `dot_copilot/`, `dot_grok/`, `dot_config/opencode/`, `dot_local/share/crush/`, `private_dot_hermes/` — per-tool agent/IDE config. Each ships a settings file (`settings.json` / `config.toml` / `opencode.json` / `private_crush.json` / `private_config.toml`) plus a shared instruction file (`CLAUDE.md` / `GEMINI.md` / `AGENTS.md` / `copilot-instructions.md` / `SOUL.md`) carrying the same coding-guideline body; `dot_claude` and `dot_gemini` also ship a statusline script.
- `dot_config/*` — terminal and CLI tool configs (`alacritty.toml`, `btop`, `fastfetch`, `htop`, `neofetch`, `pip.conf`, `uv.toml`, git `ignore`).
- `dot_local/share/fonts/meslo/` — MesloLGS NF (NerdFont) TTFs used by the p10k prompt.
- `dot_local/bin/` — work-Linux-only helpers for the sshfs-mounted kernel tree at `~/linux_kernel`: `linux-kernel-mount` (mount/umount/remount/status, plus a `daemon` mode for the systemd user service) and `kgrep` (runs ripgrep on the remote host instead of pulling file contents over the mount). Host and paths are overridable via `LINUX_KERNEL_HOST` / `LINUX_KERNEL_REMOTE_DIR` / `LINUX_KERNEL_LOCAL_DIR`. Ignored unless `is_work && linux`.
- `executable_cleanup.sh` — ad-hoc cleanup utility (NOT auto-run; deployed as `~/cleanup.sh` for manual use).
- `install.sh` — Codespace bootstrap one-liner; runs `chezmoi init --apply`. Not deployed to `$HOME`.

### Shell Config Structure

Both `dot_zshrc` and `dot_bashrc` cover the same ground, with a few zsh-only pieces called out:
1. PATH extensions (`.local/bin`, Go, Cargo, Miniconda, Neovim, OpenOCD)
2. NVM loading — zsh lazy-loads via the oh-my-zsh `nvm` plugin (`zstyle ':omz:plugins:nvm' lazy yes`); bash sources `~/.nvm/nvm.sh` eagerly
3. Common aliases (`cc='claude'`, `cop='copilot'`, `cod='codex'`)
4. Runtime-gated environment blocks — three FQDN `case` arms: work (`*.c.googlers.com|*.corp.google.com|*.roam.internal` → `sshping`, `ADB_VENDOR_KEYS`, `CORP_SSH_HELPER_OVERRIDES`), roam-only (`*.roam.internal` → `agy`, `jetski-cli`), and Cloudtop (`*.c.googlers.com|*.corp.google.com` → sources `g4d` + `dc_setup.sh`, plus `gemini`/`agy`/`jetski`/`flash`/`recovery`/`listd`/`fetch`/`duckie` aliases). No-op on personal machines.
5. Editor selection (zsh only: vim over SSH, nvim locally)

zsh additionally loads oh-my-zsh (theme `powerlevel10k`, plugins `git`/`dotenv`/`nvm`/`zsh-autosuggestions`/`zsh-syntax-highlighting`); bash does not.

### Bootstrap Architecture

Two entry points share `.chezmoitemplates/setup-body.sh`. The body opens with an `in_container` helper (`/.dockerenv`, `/run/.containerenv`, `CODESPACES` / `REMOTE_CONTAINERS` / `DEVCONTAINER`) and has eight idempotent sections:

1. **OS packages** — apt + VS Code + Neovim release + lazygit GitHub release on Linux; brew on darwin. Package list lives in `.chezmoidata/packages.yaml`. VS Code install path forks on `is_work`: corp Linux (gLinux) runs `gcert` (only when the LOAS cert expired) then the google3 installer, everyone else adds the public Microsoft apt repo.
2. **Font cache refresh** — `fc-cache -f` (Linux only).
3. **Default shell** — `chsh -s zsh`, skipped in containers (`in_container`): the image controls the shell and `chsh` can hang non-interactively.
4. **LazyVim starter** — `git clone` into `~/.config/nvim` only if absent. Deliberately a script clone (not a chezmoi external) because LazyVim is meant to be customized after first install — an external would re-pull and clobber user edits.
5. **nvm + default LTS** — installs nvm into `~/.nvm` (mac/linux) via the official installer if absent, then `nvm install --lts` and `nvm alias default 'lts/*'`. Runs with `PROFILE=/dev/null` so the installer does not append source lines to the chezmoi-managed `~/.zshrc` / `~/.bashrc` (those already load `~/.nvm`).
6. **Global npm CLIs** — `npm install -g` over the `npm_global` list in `packages.yaml`. Runs right after nvm so node/npm are on PATH. Installs latest (no version pins); npm re-install is a no-op when already current, so re-runs are cheap. Gated by `{{ if not (and .is_work (eq .chezmoi.os "darwin")) }}` — work macOS (Roam laptops) still gets nvm + node LTS from section 5, but no global CLIs.
7. **Work-only ADB systemd env + pontisd restart** — gated by `{{ if and .is_work (eq .chezmoi.os "linux") }}`, renders to nothing elsewhere.
8. **Input method (IBus)** — installs IBus + Chewing and writes `~/.xinputrc` (Linux only, skipped in containers).

#### Entry point 1: chezmoi-driven (`.chezmoiscripts/run_onchange_after_setup.sh.tmpl`)

Auto-runs as part of `chezmoi apply`. Wrapped in:

```
{{- if ne .chezmoi.os "windows" -}}
{{ template "setup-body.sh" . }}
{{- end -}}
```

`run_onchange_` re-runs the script whenever its rendered content changes — editing `packages.yaml` or switching OS / work env. It runs once on a fresh machine and stays quiet afterwards; each body section is idempotent, so a re-run only installs what changed. There is no `is_setup` flag or sentinel: `run_onchange` alone gives the run-once, re-run-on-change behavior.

#### Entry point 2: manual (`executable_setup.sh.tmpl` → `~/setup.sh`)

Always deployed (except Windows). Contains only `{{ template "setup-body.sh" . }}`. Run it yourself to bootstrap (or re-bootstrap) a machine without invoking chezmoi.

#### Entry point 3: Windows (`.chezmoiscripts/run_onchange_after_setup.ps1.tmpl`)

Windows-only, PowerShell. Cannot share `setup-body.sh` (no bash), so it only installs the `npm_global` CLIs (skipped with a message if npm is not on PATH — node/npm are assumed pre-installed). Wrapped in `{{ if eq .chezmoi.os "windows" }}`, so it renders empty (and chezmoi skips it) on macOS/Linux. Windows PowerShell 5.1 compatible.

#### Why share via `.chezmoitemplates`?

The chezmoi-driven and manual paths must stay byte-identical. Putting body in `.chezmoitemplates/setup-body.sh` and including from both entries prevents drift. Verify with:

```bash
diff <(chezmoi execute-template < .chezmoiscripts/run_onchange_after_setup.sh.tmpl) \
     <(chezmoi execute-template < executable_setup.sh.tmpl)
# Expected: no output (identical) on non-Windows.
```

#### Shebang trim caveat

The chezmoi-driven script gate uses `{{- if ... -}}` (with both `-`) so the body's `#!/usr/bin/env bash` lands on line 1 of the rendered file. A leading newline causes `fork/exec` to fail with `exec format error` because the kernel doesn't see `#!` at byte 0. Always check `chezmoi execute-template < <script>.tmpl | head -c 2` returns `#!` after editing the gate.

### Externals (`.chezmoiexternal.toml.tmpl`)

| Path | URL | Refresh | Condition |
|---|---|---|---|
| `.agents` | `Mai0313/skills` (GitHub) | 1h | always |
| `.oh-my-zsh` | `ohmyzsh/ohmyzsh` (GitHub) | 24h | non-Windows |
| `.oh-my-zsh/custom/themes/powerlevel10k` | `romkatv/powerlevel10k` | 24h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-autosuggestions` | `zsh-users/zsh-autosuggestions` | 24h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-syntax-highlighting` | `zsh-users/zsh-syntax-highlighting` | 24h | non-Windows |
| `adb-keys/security` | `sso://googleplex-android/.../security` | 1h | `is_work` |

All are `type = "git-repo"`. The four non-Windows externals (oh-my-zsh, p10k, and the two zsh plugins) pin `--depth=1` clone and `--ff-only` pull; `.agents` and `adb-keys/security` use plain full clones/pulls. Pulling on chezmoi's schedule is compatible with oh-my-zsh's own `git pull`-based self-update — no need to disable oh-my-zsh auto-update. Externals refresh independently of the setup script's `run_onchange_` hash.
