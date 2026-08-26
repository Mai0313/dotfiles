# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles repo (`Mai0313/dotfiles`). Deploys shell configs, IDE settings, fonts, and bootstraps the dev toolchain (oh-my-zsh, Powerlevel10k, plugins, LazyVim, OS packages) across personal machines, Google Cloudtop (work), Roam laptops, and GitHub Codespaces.

Bootstrap has the same two entry points on every platform, each pair sharing one body under `.chezmoitemplates/`:

- **chezmoi-driven** (`run_onchange_after_setup.sh.tmpl` / `.ps1.tmpl` under `.chezmoiscripts/`) — runs automatically as part of `chezmoi apply`, gated by OS.
- **manual** (`executable_setup.sh.tmpl` → `~/setup.sh`, `setup.ps1.tmpl` → `~/setup.ps1`) — deployed to home for opt-in manual execution; `.chezmoiignore` deploys only the one matching the OS.

Windows has no bash, so its pair shares `setup-body.ps1` rather than `setup-body.sh`. That body installs the global npm CLIs and the `windows` winget packages, links the agent skills the way §10 of the *nix body does (with junctions, which need no Developer Mode), and has no counterpart to the remaining *nix-only sections.

## Common Commands

```bash
chezmoi diff          # Preview changes before applying
chezmoi apply         # Apply source state to $HOME (deploys files + may run setup script)
chezmoi re-add        # Sync local edits back to source directory
chezmoi add ~/.file   # Start tracking a new file
chezmoi forget ~/.file # Stop tracking a file (removes it from the source dir, keeps $HOME copy)
chezmoi cd            # cd into this source directory
chezmoi init --force  # Re-evaluate .chezmoi.toml.tmpl (e.g., after adding new data keys)
```

Tracking changes must go through chezmoi, never by hand-creating or `rm`-ing files in the source directory: use `chezmoi add` to start tracking and `chezmoi forget` to stop. `forget` leaves the deployed copy in `$HOME` alone; `chezmoi destroy` removes both.

After editing templates, validate with `chezmoi execute-template < file.tmpl` or `chezmoi diff` to verify output.

## Architecture

### Chezmoi Naming Conventions

- `dot_*` -> files with leading `.` (e.g., `dot_zshrc` -> `~/.zshrc`)
- `executable_*` -> deployed with execute permission (e.g., `executable_cleanup.sh` -> `~/cleanup.sh`)
- `private_*` -> deployed with `0600` permission (no group/other read)
- `.tmpl` suffix -> processed as Go templates with chezmoi data
- `.chezmoitemplates/<name>` -> shared template fragments included with `{{ template "<name>" . }}`

**Special files and the `.tmpl` suffix.** `.chezmoiignore`, `.chezmoiremove`, and `.chezmoiexternal.<format>` are *always* interpreted as templates, with or without a `.tmpl` suffix. This repo deliberately names them without it (`.chezmoiexternal.toml`, not `.chezmoiexternal.toml.tmpl`) so editors recognize the format and keep syntax highlighting. **Future-agent guidance: do NOT "fix" these by adding `.tmpl` back** — it changes nothing functionally and only breaks editor support. Note that both names can coexist and chezmoi reads both, so renaming must use `git mv`, never a copy. By contrast `.chezmoidata.<format>`, `.chezmoiroot`, and `.chezmoiversion` are never templates (Go template syntax in them is taken literally, or fails to parse), and `.chezmoi.<format>.tmpl` requires the suffix.

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
- `.chezmoiignore` — gates `.local/bin/kgrep`, `.local/bin/linux-kernel-mount`, `.local/bin/automation-mount` and the two `.config/systemd/user/*-sshfs.service` units off unless `is_work && linux`; `.config/environment.d/adb.conf` + `setup_adb.sh` off unless `is_work`; and `.chrome-remote-desktop-session` off unless `linux && not is_work`. The OS gates in the same file are independent of `is_work`: Windows drops the whole *nix set (`.zshrc`, `.zshenv`, `.zprofile`, `.profile`, `.bashrc`, `.p10k.zsh`, `cleanup.sh`, `setup.sh`, `.xinputrc`, `.config/{alacritty,environment.d,systemd,fcitx5,btop,htop,goobuntu-backups,uv,pip}`, `.local/share/fonts`, `.local/bin/{list_devices,toggle-display}`), non-Windows drops `Documents`, `AppData` + `setup.ps1`, and non-Linux drops `.config/environment.d/im.conf`.
- `.chezmoiexternal.toml` — gates `adb-keys/security` (sso git-repo); gates oh-my-zsh + plugins on `chezmoi.os != "windows"` and the two CLI binaries on `chezmoi.os == "linux"`, neither of which depends on `is_work`.
- `.chezmoitemplates/setup-body.sh` — §1 gates the corp-only apt packages, §2 routes VS Code (corp Linux → google3, else Microsoft repo), §8 skips global npm on work macOS, §11 gates the ADB pontisd restart. Container and OS gating inside the body is runtime, not chezmoi data.
- The seven agent instruction templates — pick between the work and personal body. See Shared Agent Instruction Files.

Inspect the current value with `chezmoi data | grep is_work`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) do their own `case` match (on `$(hostname -f 2>/dev/null || hostname)`) against the same FQDN patterns to toggle env-specific blocks (aliases, env vars). **All live gating for these mixed-content files happens here, not in chezmoi templates.**

**Why runtime, not template, for shell configs?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping `dot_zshrc` / `dot_bashrc` as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` without hand-patching the source tree. This rule applies because these files mix universal and env-specific content in the same file — runtime gating is the only option.

**Future-agent guidance: do NOT "refactor" the `dot_zshrc` / `dot_bashrc` runtime `case` blocks into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again.

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.corp.google.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus `dot_zshrc` and `dot_bashrc` (Layer 2). If the pattern ever changes, grep for `c.googlers.com`, `corp.google.com`, and `roam.internal` to find every occurrence.

### Machine Specs

Five machines run this source state, three corp and two personal. One row each; `TBD` means not recorded yet, not "none".

| Machine | Env | CPU | RAM | Storage | GPU | OS | Measured |
|---|---|---|---|---|---|---|---|
| `weichenglee-dell7875lin.ntc.corp.google.com` (desktop) | `is_work && linux` | AMD Ryzen Threadripper PRO 7985WX, 64C / 128T | 250 GiB + 221 GiB swap | KIOXIA XG10d SED 2 TB NVMe (single drive, LVM root ~1.6 TB) | AMD Radeon PRO W6400 (Navi 24) | Debian rodete, kernel 7.1.6 | 2026-08-17 |
| `wei0313.c.googlers.com` (Cloudtop VM, `asia-east1-a`) | `is_work && linux` | AMD EPYC 7B13, 2 sockets × 32C / 128T, KVM guest | 236 GiB + 229 GiB swap | 8 TB PD_SSD, network-backed (LVM root 7.7 TB) | none (headless, virtio only) | Debian rodete, kernel 7.1.6 | 2026-08-26 |
| `weichenglee-mac.roam.internal` (Roam laptop, MacBook Pro Mac16,7) | `is_work && darwin` | Apple M4 Pro, 14C (10P + 4E) | 48 GiB unified memory | Apple SSD AP0512Z 512 GB NVMe (APFS root ~460 GiB) | Apple M4 Pro (20-core GPU, integrated) | macOS 26.6.2 (build 25G83), kernel 25.6.0 | 2026-08-20 |
| `WEI` (Home desktop, ASUS ROG MAXIMUS Z790 HERO) | `not is_work` | Intel Core i9-13900K, 24C (8P + 16E) / 32T | 48 GiB (2 × 24 GB DDR5-4200) + 3 GiB pagefile | 7 drives, ~8.3 TB total — NVMe: Samsung 990 PRO 2 TB (`C:`), 980 PRO 2 TB, Lexar NM1090 PRO 2 TB, Samsung 970 PRO 512 GB; SATA: Samsung 860 EVO 500 GB, Crucial BX500 1 TB, WD10EZEX 1 TB HDD | NVIDIA GeForce RTX 5090, 32 GB VRAM (driver 610.88) | Windows 11 Pro 25H2, build 26200.9168 | 2026-08-18 |
| `mai0313` (Home workstation, ASUS ROG MAXIMUS XI HERO (WI-FI)) | `not is_work` | Intel Core i9-9900K, 8C / 16T | 62 GiB + 2 GiB swapfile | 2 drives, ~2.4 TB total — NVMe: Lexar NM620 2 TB (root), Intel 600p 512 GB (`/mnt/nfs`) | Intel UHD Graphics 630 (integrated, CoffeeLake-S GT2), no discrete GPU | Ubuntu 24.04.4 LTS (noble), kernel 6.8.0-136 | 2026-08-18 |

### Key Files

Only the files whose purpose is not obvious from opening them. Everything else in the tree is what it looks like.

| Path | Note |
|---|---|
| `.chezmoi.toml.tmpl` | The only chezmoi data. See Environment Detection Layer 1. |
| `.chezmoidata/packages.yaml` | Package lists per OS. Editing it re-triggers setup, because `run_onchange` hashes rendered content. |
| `.chezmoitemplates/setup-body.sh` | The *nix bootstrap body. See Bootstrap Architecture. |
| `.chezmoitemplates/setup-body.ps1` | The Windows bootstrap body, shared by that platform's two entry points the same way. |
| `.chezmoitemplates/agent-instructions/` | **The only copies of the agent guidelines**, split `common.md` / `personal.md` / `work.md`. Edit here, never the seven deployed files. See Shared Agent Instruction Files. |
| `.chezmoiversion` | `2.40.0`, the oldest release verified against this source state. An older chezmoi aborts rather than silently degrading. Raise it only when the repo starts using a newer feature. |
| `dot_zshrc` / `dot_bashrc` / `dot_zshenv` / `dot_zprofile` | Plain, non-`.tmpl`, so `chezmoi re-add` works. See Environment Detection Layer 2 before changing that. |
| `private_dot_profile` | Byte-identical to Debian's `/etc/skel/.profile`. Tracked anyway, so `~/.local/bin` lands on PATH regardless of what a distro's skel contains. |
| `dot_claude/`, `dot_codex/`, `dot_copilot/`, `dot_grok/`, `dot_config/opencode/`, `dot_local/share/crush/`, `dot_dsh/`, `dot_pi/`, `private_dot_hermes/` | Per-tool agent config: a settings file each, plus an instruction file that only includes the shared body. Gemini's equivalent is not here, it is the `.gemini` external. |
| `dot_local/bin/` | Five scripts under two different gates: `kgrep`, `linux-kernel-mount`, `automation-mount` need `is_work && linux`; `list_devices` and `toggle-display` are corp tools but only gated off Windows, so they land on personal machines too. |
| `install.sh` | Codespace one-liner. Not deployed to `$HOME`. |

Five couplings that break quietly if you touch one side only:

- **`AppData/Roaming/{pip,uv}` are byte-identical copies of `dot_config/{pip,uv}`.** Windows reads them from AppData, so `.chezmoiignore` drops the `.config` pair there and ships these instead. Editing one side means editing the other.
- **fcitx5 wiring lives in three files** because nothing covers both sessions: `.xinputrc` and `environment.d/im.conf` drive the physical session, and the Chrome Remote Desktop session reads neither, so `.chrome-remote-desktop-session` repeats the `GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` trio itself. That last one deploys on personal Linux only; corp Linux goes through goobuntu's `switch-graphical-session` instead.
- **chezmoi deploys the `dot_config/systemd/user/` units but cannot enable them.** The `default.target.wants/` symlinks are systemd state, not dotfiles, so a fresh machine still needs `systemctl --user enable --now linux-kernel-sshfs automation-sshfs` once.
- **The cloudtop hostname is a default in three scripts, not something a shell can export.** `kgrep`, `linux-kernel-mount` and `automation-mount` all read `${CLOUDTOP_HOST:-<host>}`, but the two `*-sshfs.service` units run the mount scripts from the systemd user manager, which never sees a `.zshrc` export. Exporting `CLOUDTOP_HOST` therefore moves `kgrep` alone and leaves the mounts on the old machine, which is the one failure that puts two different trees under one path without erroring. Moving to a new cloudtop means editing all three defaults, then `systemctl --user restart linux-kernel-sshfs automation-sshfs`.
- **alacritty is deliberately not installed by the bootstrap.** The tracked config uses the `[general] import` form, which needs ≥ 0.14, and noble's apt candidate is 0.13.2 — a `packages.yaml` entry would deploy a config the binary rejects. Installed by hand into `~/.local/bin`.

### Shared Agent Instruction Files

Every agent CLI reads a different filename, but they must all get the same instructions. **The body lives in `.chezmoitemplates/agent-instructions/` and nowhere else. Edit it there — the seven deployed copies are one-line templates that include it, so they cannot drift.**

Three body files in that directory, because corp and personal machines need different tails:

| Body | Contents | Used when |
|---|---|---|
| `common.md` | `## General`, `## Self-improvement` | included by both variants, never selected directly |
| `personal.md` | common + `## For GitHub Repositories Only` | `not is_work` |
| `work.md` | common + the corp sections (gpar, Critique, Buganizer, Android Build, devices, TF-A / RF-A, TFTF) | `is_work` |

Anything that applies everywhere goes in `common.md`. The other two hold only what their own environment needs, and `work.md` deliberately has no GitHub section: corp machines are not where that work happens.

**All three are plain markdown and must stay that way.** No `{{ }}`, no chezmoi syntax, nothing that needs rendering to be read. They do not know about each other and never include each other; assembling common + tail is the deployed template's job, below. Keeping them inert is what lets you read one as the instructions it is, and it removes the whole class of apply failures where a stray `{{` in prose gets parsed as an action.

`.chezmoitemplates` is walked recursively and a template's name is its path relative to that directory, so the subdirectory is part of the name (`agent-instructions/common.md`, not `common.md`). Nothing here is deployed to `$HOME`, so moving files around inside it is a plain `git mv` with no `chezmoi add` / `forget` involved.

| Path | Deployed to | Read by |
|---|---|---|
| `dot_claude/CLAUDE.md.tmpl` | `~/.claude/CLAUDE.md` | Claude Code |
| `dot_codex/AGENTS.md.tmpl` | `~/.codex/AGENTS.md` | Codex |
| `dot_grok/AGENTS.md.tmpl` | `~/.grok/AGENTS.md` | Grok CLI |
| `dot_config/opencode/AGENTS.md.tmpl` | `~/.config/opencode/AGENTS.md` | opencode |
| `dot_copilot/copilot-instructions.md.tmpl` | `~/.copilot/copilot-instructions.md` | GitHub Copilot CLI |
| `private_dot_hermes/SOUL.md.tmpl` | `~/.hermes/SOUL.md` | Hermes |
| `dot_pi/agent/AGENTS.md.tmpl` | `~/.pi/agent/AGENTS.md` | pi |

Each of those seven is the same two lines, and this is the only place the assembly happens:

```
{{ template "agent-instructions/common.md" . }}
{{ if .is_work }}{{ template "agent-instructions/work.md" . }}{{ else }}{{ template "agent-instructions/personal.md" . }}{{ end -}}
```

Adding an eighth tool means one more such file, not another copy.

Both lines are load-bearing on whitespace. `common.md` already ends in a newline, so the source newline after the first action is what produces the blank line between the last common paragraph and the tail's first heading; putting a blank line between the two template lines gives you two. The trailing `-}}` trims the source file's own final newline, so the rendered file ends exactly where the tail does.

**The bodies must stay free of Go template syntax.** Everything under `.chezmoitemplates/` is rendered, so a literal `{{` in the instructions would be parsed as an action and fail the apply. If the instructions ever need to show one, escape it (`{{ "{{" }}`).

**`chezmoi re-add` does not work on these any more** — it cannot reverse-merge a rendered file back through a template. Edit the source file in this repo and run `chezmoi apply`; that is the direction this layout is built for. Note this is the opposite call from `dot_zshrc` / `dot_bashrc` (see Environment Detection Layer 2), which stay plain files *because* they are edited in `$HOME` and synced back.

The per-tool settings files sitting next to them (`settings.json`, `config.toml`, `opencode.json`, `private_crush.json`, `private_config.toml`) are **not** shared — each is tool-specific and unrelated to the others. `dot_local/share/crush/` ships only a settings file, no instruction file.

`~/.gemini/GEMINI.md` is the **eighth** copy, and the one this repo does not deploy: it lives in the `.gemini` external repo (see Externals below), which owns it. It is byte-identical to what `work.md` renders to, because that file was seeded from it and is meant to stay that way. Nothing enforces it, so a change to `work.md` or to `common.md` has to be carried over there by hand.

### Shell Config Structure

Both `dot_zshrc` and `dot_bashrc` cover the same ground, with a few zsh-only pieces called out:
1. PATH extensions (`.local/bin`, Go, Cargo, Neovim at `~/.nvim/bin`, OpenOCD)
2. NVM loading — zsh lazy-loads via the oh-my-zsh `nvm` plugin (`zstyle ':omz:plugins:nvm' lazy yes`); bash sources `~/.nvm/nvm.sh` eagerly
3. Common aliases (`cc='claude'`, `cop='copilot'`, `cod='codex'`)
4. Runtime-gated environment blocks — four FQDN `case` arms: work (`*.c.googlers.com|*.corp.google.com|*.roam.internal` → `sshping`, `ADB_VENDOR_KEYS`, `CORP_SSH_HELPER_OVERRIDES`), Cloudtop VM only (`*.c.googlers.com` → `AUTH_REMOTE_GCERT_ARGS`, which the corp desktop must not set), roam-only (`*.roam.internal` → `agy`, `jetski-cli`), and corp Linux (`*.c.googlers.com|*.corp.google.com` → sources `g4d` + `dc_setup.sh`, plus `gemini`/`agy`/`jetski`/`flash`/`recovery`/`listd`/`fetch`/`duckie` aliases). No-op on personal machines.
5. Editor selection (zsh only: vim over SSH, nvim locally)

zsh additionally loads oh-my-zsh (theme `powerlevel10k`, plugins `git`/`dotenv`/`nvm`/`z`/`zsh-autosuggestions`/`zsh-syntax-highlighting`); bash does not. `z` is oh-my-zsh's bundled copy of `agkozak/zsh-z`, so it updates with oh-my-zsh — do not add a `custom/plugins/zsh-z` clone alongside it, and note that oh-my-zsh gitignores all of `custom/`, so anything hand-cloned there is invisible to `git status` and managed by nothing.

**Windows has a third copy of the PATH list.** `readonly_Documents/PowerShell/profile.ps1` prepends seven entries. The first three are the ones from item 1 that exist on Windows too (`~/.local/bin`, `~/go/bin`, `~/.cargo/bin`); the rest of item 1 is *nix-only paths. The other four are Windows-only tool directories with no `dot_zshrc` counterpart (`~/.grok/bin`, `~/.local/bin/adb`, `~/AppData/Local/agy/bin`, `~/AppData/Local/Programs/obsidian`). Changing the PATH line in `dot_zshrc` / `dot_bashrc` means checking whether the new entry belongs there as well.

### Bootstrap Architecture

The *nix pair shares `.chezmoitemplates/setup-body.sh`. That body opens with an `in_container` helper (`/.dockerenv`, `/run/.containerenv`, `CODESPACES` / `REMOTE_CONTAINERS` / `DEVCONTAINER`) and runs eleven idempotent sections in three groups: a system layer (§1–3, everything that needs sudo, kept first and contiguous so one password prompt at the start covers the run), a user layer (§4–10, installs into `$HOME`, no sudo), and a work-only tail (§11).

Within those groups the order is topical: fonts before the editor that uses them, neovim next to the LazyVim starter that configures it. That ordering only works because no user-layer step needs sudo, so **a new step that needs sudo goes in §1–3, never below** — adding one lower down splits the password prompt in two and the grouping stops meaning anything.

§1 OS packages, §2 VS Code, §3 default shell | §4 font cache, §5 neovim, §6 LazyVim starter, §7 node LTS, §8 global npm CLIs, §9 uv, §10 agent skills symlinks | §11 ADB/pontisd. **Each section carries its own comment explaining itself; read the script for what a section does.** What follows is only what the script cannot tell you.

**Ordering constraints.** Nothing needing a LOAS cert may run before §1: corp apt repos authenticate with the *machine* cert, so `apt-get` never needs `gcert`, but the google3 depot §2 reads does — hence `work_linux` installs in §1, ahead of it. §8 must follow §7, which is what puts node on PATH. §7 no longer installs nvm — the `.nvm` external does — so it now depends on chezmoi having deployed externals first. That holds for both entry points: externals land with the rest of the source state, and `run_onchange_after_` scripts are named to run after it (verified with a throwaway `--destination`). The manual `~/setup.sh` inherits the same assumption harmlessly, since chezmoi is what put that file in `$HOME` to begin with.

**Corp `gcert` (§2).** It is interactive, driving the gnubby over `ssh-agent`, so it fails whenever `SSH_AUTH_SOCK` is unset — the normal case under a non-interactive apply, and inside tmux (go/sk-screen-tmux). Do not put `--lifetime` back; the cert only has to outlive this run. **Never let a failing `gcert` be the last command of a list**, or `set -e` takes nvm, npm and uv down with it. The installer after it runs unconditionally on purpose: with no cert it fails loudly, which is the intended "go run gcert and re-run" signal, so do not add a `gcertstatus` gate there.

**Always `apt-get`, never `apt`.** `apt` has no stable CLI interface and warns on every non-tty run, which is how this script always executes. Do not add `--update` either: §1 already ran `apt-get update`, and a plain `install` still upgrades to the candidate version.

**Deliberately not sections here**, and each will look like an oversight to someone who does not read this:

- **fastfetch** — a package everywhere it can be: `packages.darwin` (brew), `packages.work_linux` (the gLinux repos have it, which is why it sits in a list otherwise full of corp-only tooling), `packages.windows` (winget). The gap is personal Ubuntu: noble has no fastfetch at all, so a `packages.linux` entry would fail `apt-get` and take the run down under `set -e`. Left to the user, who installs the upstream PPA by hand until 25.04+ makes it unnecessary. **That PPA must not go into the script** — it publishes for Ubuntu series only, so `add-apt-repository` on the corp Debian machines leaves a repo with no matching series and the next `apt-get update` fails. Same reason §5 does not use the neovim PPA.
- **fcitx5** — installing it needs `sudo apt-get` from the user layer, long after the sudo timestamp expired, so a no-op re-run still stopped for a password. Installed by hand now. `dot_config/environment.d/im.conf` stays tracked because it is a dotfile, not an install step.
- **alacritty** — see its note under Key Files.

#### Entry points

Four, in two matching pairs, each a thin wrapper: an auto one under `.chezmoiscripts/` that runs during `chezmoi apply`, and a manual one deployed to `$HOME` to run yourself. Both members of a pair include the same body and must stay byte-identical, which is the whole reason the bodies live in `.chezmoitemplates`:

```bash
diff <(chezmoi execute-template < .chezmoiscripts/run_onchange_after_setup.sh.tmpl) \
     <(chezmoi execute-template < executable_setup.sh.tmpl)   # expect no output
```

The `.ps1` pair cannot be checked that way from Linux, since the auto one renders empty off Windows. Rewrite the built-in into a data key first:

```bash
sed 's/\.chezmoi\.os/.tos/g' .chezmoiscripts/run_onchange_after_setup.ps1.tmpl > /tmp/probe.tmpl
printf 'sourceDir = "%s"\n[data]\ntos = "windows"\n' "$PWD" > /tmp/cfg.toml
diff <(chezmoi --config=/tmp/cfg.toml execute-template < /tmp/probe.tmpl) \
     <(chezmoi --config=/tmp/cfg.toml execute-template < setup.ps1.tmpl)   # expect no output
```

Note `setup.ps1.tmpl` carries no `executable_` prefix: Windows has no execute bit for chezmoi to set, and the file deploys nowhere else.

`run_onchange_` alone gives run-once-then-quiet: it re-runs only when the *rendered* content changes. There is no `is_setup` sentinel and none is needed.

**Shebang at byte 0.** The `.sh.tmpl` gate uses `{{- if ... -}}` with both dashes so `#!/usr/bin/env bash` lands on line 1. A leading newline makes `fork/exec` fail with `exec format error`. After touching the gate, check `chezmoi execute-template < <script>.tmpl | head -c 2` returns `#!`.

**Windows uses winget** rather than scoop or choco, because it ships with Windows 11 and needs no bootstrap of its own. Two things there have no bash equivalent to reason from: winget returns non-zero for "already installed" (`0x8A15002B`) as well as for real failures, and PowerShell 5.1's `$ErrorActionPreference = 'Stop'` does not cover native exit codes at all — so `$LASTEXITCODE` is tested by hand, tolerated codes are allow-listed, and it is reset at the end so a tolerated non-zero does not leak out as the script's status. **None of this is verifiable from Linux; check on `WEI` after changing that block.** Package names are matched by search (the form upstream documents); if one ever goes ambiguous, switch it to `--exact --id <PackageIdentifier>`.

### Externals (`.chezmoiexternal.toml`)

| Path | URL | Refresh | Condition |
|---|---|---|---|
| `.agents` | `Mai0313/skills` (GitHub) | 1h | always |
| `.gemini` | `Mai0313/.gemini` (GitHub) | 1h | always |
| `.oh-my-zsh` | `ohmyzsh/ohmyzsh` (GitHub) | 24h | non-Windows |
| `.oh-my-zsh/custom/themes/powerlevel10k` | `romkatv/powerlevel10k` | 24h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-autosuggestions` | `zsh-users/zsh-autosuggestions` | 24h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-syntax-highlighting` | `zsh-users/zsh-syntax-highlighting` | 24h | non-Windows |
| `.nvm` | `nvm-sh/nvm`, pinned to a tag | 168h | non-Windows |
| `adb-keys/security` | `sso://googleplex-android/.../security` | 1h | `is_work` |
| `.local/bin/gh` | `cli/cli` release | 168h | linux |
| `.local/bin/gdu` | `dundee/gdu` release | 168h | linux |

Everything except the last two is `type = "git-repo"`; oh-my-zsh, p10k and the two plugins pin `--depth=1` clone and `--ff-only` pull, `.nvm` pins a tag (below), the rest use plain full clones. `refreshPeriod` does apply to `git-repo` externals (it throttles the `git pull`) even though upstream docs only document it for `file` and `archive` — do not remove it. Pulling on chezmoi's schedule coexists with oh-my-zsh's own self-update, so leave that enabled.

`gh` and `gdu` are `type = "archive-file"`: one binary lifted out of a release tarball into `~/.local/bin`. **Linux only, and only because apt is the one channel that does not keep up.** A stable Ubuntu freezes its archive at release and thereafter backports fixes into the frozen version — the `ubuntu0.24.04.3` half of `gdu 5.25.0-1ubuntu0.24.04.3` is the patch counter, and the upstream half never moves. So noble still offers gh 2.45 and gdu 5.25 against upstream's 2.97 and 5.37, while brew and winget both ship the new version within a day or two of release. darwin and windows therefore take these from `packages.yaml`, and this block exists for the platform with nowhere else to go. They are also not in `setup-body.sh`, where the `command -v` guards would install once and never upgrade.

**Adding a third: assume nothing about the naming.** `.chezmoi.arch` is `GOARCH` (`amd64` / `arm64`) and `.chezmoi.os` is `GOOS` (`linux` / `darwin` / `windows`). `gh` and `gdu` match on arch only because they are Go projects released by GoReleaser, and even then `gh` spells the OS `macOS`. Outside that toolchain nothing lines up: `btop` uses LLVM target triples and has no macOS or Windows build at all, `fastfetch` mixes both conventions (`amd64` but `aarch64`, `macos` not `darwin`). Translate with a `dict`.

**Never resolve a version through `api.github.com`, `gitHubLatestRelease` included.** Unauthenticated that API is 60/hr per source IP, and chezmoi has no token when it needs one: a shared-egress CI runner (Claude Code Cloud) arrives with the hour's quota already spent, and the 403 comes back while chezmoi is *reading this file*, so the whole apply dies before a single dotfile is written or the setup script starts. `github.com/<repo>/releases/latest` answers the same question by 302 and is not rate limited that way, which is why `gh` shells out to `curl -w '%{redirect_url}'` for its tag. Keep the probe unable to fail the render: an empty result must make the entry disappear (an external that vanishes leaves an already-installed binary alone), never abort.

**`.nvm` is the same problem solved the other way,** and it is why nvm's own installer no longer runs in `setup-body.sh` §7. That installer is a git clone plus a tag checkout, which an external already does, so the version lookup disappears rather than moving to a redirect. It pins a **release tag**, not the default branch: `nvm.sh` is sourced into every shell, and nvm releases every few months, so tracking development buys nothing. Bumping the tag is the entire maintenance, and a `~/.nvm` on an older tag fast-forwards onto the new one unattended. A tag is a detached HEAD, where a bare `git pull` refuses and takes the apply down with it, so `pull.args` names the remote and ref — `["--ff-only", "origin", "<tag>"]`, verified against a throwaway repo across both a same-tag refresh and an old-tag-to-new-tag bump. Installed node versions and the default alias sit under paths nvm gitignores (`v*`, `alias`), so neither clone nor pull touches them.

Three more that only surface when you try it. `gh` repeats its version *inside* the archive path, so it needs the number up front, where `gdu` and neovim get away with `releases/latest/download/` because their asset names carry no version. A `path` must match the archive member byte for byte, `./` prefix included, and it can differ per platform for the same tool — gh's Windows zip has no top-level directory at all. A missing build matters more than a wrong path, because a 404 fails the whole apply rather than one entry, so guard on `.chezmoi.arch` where upstream skips a build. `archive-file` extracts exactly one file, so a binary shipping beside required DLLs needs one entry per file. **Verify by applying against a throwaway `--destination`, never by reading the asset list.** And check `packages.yaml` for the same name first: an apt copy still installs, then loses to `~/.local/bin` on PATH and wastes the download — `gh` and `htop` were exactly that, and were removed.
