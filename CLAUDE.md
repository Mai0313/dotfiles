# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles repo (`Mai0313/dotfiles`). Deploys shell configs, IDE settings, fonts, and bootstraps the dev toolchain (oh-my-zsh, Powerlevel10k, plugins, LazyVim, OS packages) across personal machines, Google Cloudtop (work), Roam laptops, and GitHub Codespaces.

Bootstrap has two entry points that share the same body via `.chezmoitemplates/setup-body.sh`:

- **chezmoi-driven** (`.chezmoiscripts/run_onchange_after_setup.sh.tmpl`) — runs automatically as part of `chezmoi apply`, gated by OS.
- **manual** (`executable_setup.sh.tmpl` → `~/setup.sh`) — deployed to home for opt-in manual execution; not deployed on Windows.

Windows has no bash, so it does not share this body. A separate `.chezmoiscripts/run_onchange_after_setup.ps1.tmpl` runs on Windows only: it installs the global npm CLIs and fastfetch, but skips the *nix-only setup.

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
- `.chezmoiignore` — gates `.local/bin/kgrep`, `.local/bin/linux-kernel-mount`, `.local/bin/automation-mount` and the two `.config/systemd/user/*-sshfs.service` units off unless `is_work && linux`; `.config/environment.d/adb.conf` + `setup_adb.sh` off unless `is_work`; and `.chrome-remote-desktop-session` off unless `linux && not is_work`. The OS gates in the same file are independent of `is_work`: Windows drops the whole *nix set (`.zshrc`, `.zshenv`, `.zprofile`, `.profile`, `.bashrc`, `.p10k.zsh`, `cleanup.sh`, `setup.sh`, `.xinputrc`, `.config/{alacritty,environment.d,systemd,fcitx5,btop,htop,neofetch,goobuntu-backups,uv,pip}`, `.local/share/fonts`, `.local/bin/{list_devices,toggle-display}`), non-Windows drops `Documents` + `AppData`, and non-Linux drops `.config/environment.d/im.conf`.
- `.chezmoiexternal.toml` — gates `adb-keys/security` (sso git-repo); gates oh-my-zsh + plugins on `chezmoi.os != "windows"`.
- `.chezmoitemplates/setup-body.sh` — §1 gates the corp-only apt packages, §2 routes VS Code (corp Linux → google3, else Microsoft repo), §9 skips global npm on work macOS, §12 gates the ADB pontisd restart. Container and OS gating inside the body is runtime, not chezmoi data.

Inspect the current value with `chezmoi data | grep is_work`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) do their own `case` match (on `$(hostname -f 2>/dev/null || hostname)`) against the same FQDN patterns to toggle env-specific blocks (aliases, env vars). **All live gating for these mixed-content files happens here, not in chezmoi templates.**

**Why runtime, not template, for shell configs?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping `dot_zshrc` / `dot_bashrc` as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` without hand-patching the source tree. This rule applies because these files mix universal and env-specific content in the same file — runtime gating is the only option.

**Future-agent guidance: do NOT "refactor" the `dot_zshrc` / `dot_bashrc` runtime `case` blocks into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again.

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.corp.google.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus `dot_zshrc` and `dot_bashrc` (Layer 2). If the pattern ever changes, grep for `c.googlers.com`, `corp.google.com`, and `roam.internal` to find every occurrence.

### Machine Specs

Five machines run this source state, three corp and two personal. One row each; `TBD` means not recorded yet, not "none".

| Machine | Env | CPU | RAM | Storage | GPU | OS | Measured |
|---|---|---|---|---|---|---|---|
| `weichenglee-dell7875lin.ntc.corp.google.com` (desktop) | `is_work && linux` | AMD Ryzen Threadripper PRO 7985WX, 64C / 128T, 0.42–5.37 GHz | 250 GiB + 221 GiB swap | KIOXIA XG10d SED 2 TB NVMe (single drive, LVM root ~1.6 TB) | AMD Radeon PRO W6400 (Navi 24) | Debian rodete, kernel 7.1.6 | 2026-08-17 |
| `mai0313.c.googlers.com` (Cloudtop VM) | `is_work && linux` | AMD EPYC 7B13, 2 sockets × 32C / 128T, KVM guest | 236 GiB + 115 GiB swap | 8 TB PersistentDisk, network-backed (LVM root 7.8 TB) | none (headless, virtio only) | Debian rodete, kernel 6.18.14 | 2026-08-17 |
| Roam laptop | `is_work && darwin` | TBD | TBD | TBD | TBD | TBD | — |
| `WEI` (Home desktop, ASUS ROG MAXIMUS Z790 HERO) | `not is_work` | Intel Core i9-13900K, 24C (8P + 16E) / 32T, base 3.0 GHz | 48 GiB (2 × 24 GB DDR5-4200) + 3 GiB pagefile | 7 drives, ~8.3 TB total — NVMe: Samsung 990 PRO 2 TB (`C:`), 980 PRO 2 TB, Lexar NM1090 PRO 2 TB, Samsung 970 PRO 512 GB; SATA: Samsung 860 EVO 500 GB, Crucial BX500 1 TB, WD10EZEX 1 TB HDD | NVIDIA GeForce RTX 5090, 32 GB VRAM (driver 610.88) | Windows 11 Pro 25H2, build 26200.9168 | 2026-08-18 |
| `mai0313` (Home workstation, ASUS ROG MAXIMUS XI HERO (WI-FI)) | `not is_work` | Intel Core i9-9900K, 8C / 16T, 0.8–5.0 GHz | 62 GiB + 2 GiB swapfile | 2 drives, ~2.4 TB total — NVMe: Lexar NM620 2 TB (root), Intel 600p 512 GB (`/mnt/nfs`) | Intel UHD Graphics 630 (integrated, CoffeeLake-S GT2), no discrete GPU | Ubuntu 24.04.4 LTS (noble), kernel 6.8.0-136 | 2026-08-18 |

### Key Files

- `.chezmoi.toml.tmpl` — chezmoi config. Computes the single `is_work` flag from the FQDN and pins `sourceDir`. See Layer 1 above.
- `.chezmoiexternal.toml` — declarative external dependencies (oh-my-zsh, p10k, zsh plugins, `.agents` skills repo, `.gemini` config repo, work-only ADB security repo). All `type = "git-repo"`; the four non-Windows externals pin `--depth=1` clone and `--ff-only` pull, while `.agents`, `.gemini`, and `adb-keys/security` use plain full clones/pulls.
- `.chezmoidata/packages.yaml` — declarative OS package lists (darwin / linux, plus `work_darwin` for Mule packages, `work_linux` for corp apt packages: google3/Cider, Android, Pontis, and serial-console tooling) and a cross-platform `npm_global` list of global npm CLIs, consumed by `.chezmoitemplates/setup-body.sh` (*nix) and `.chezmoiscripts/run_onchange_after_setup.ps1.tmpl` (Windows). Adding a package: edit the YAML and run `chezmoi apply` — `run_onchange` sees the changed content and re-runs setup.
- `.chezmoitemplates/setup-body.sh` — shared bash body used by both bootstrap entry points. Contains a sudo system layer (OS packages, VS Code, Neovim, default shell), a no-sudo user layer (lazygit, font cache, LazyVim, nvm + node LTS, global npm CLIs, uv), and a work-only tail (ADB pontisd setup). Each section is internally idempotent.
- `.chezmoiscripts/run_onchange_after_setup.sh.tmpl` — chezmoi-driven entry. Thin wrapper around `setup-body.sh`, gated by OS. Runs at `chezmoi apply` when rendered content changes.
- `.chezmoiscripts/run_onchange_after_setup.ps1.tmpl` — Windows-only chezmoi-driven entry (PowerShell). Installs the `npm_global` CLIs (skips if npm absent) and fastfetch into `~/.local/bin`. Does not share `setup-body.sh` (no bash on Windows). Renders empty on non-Windows so chezmoi skips it.
- `executable_setup.sh.tmpl` — manual entry, deployed to `~/setup.sh`. Same body, no gates (user runs it intentionally). Not deployed on Windows (`.chezmoiignore`).
- `.chezmoiignore` — keeps `install.sh`, READMEs, `CLAUDE.md` from being deployed; OS- and env-gated exclusions.
- `.chezmoiversion` — minimum chezmoi version needed to apply this source state (`2.40.0`, the oldest release verified to handle everything here). An older chezmoi aborts with `source state requires chezmoi version ... or later` instead of silently degrading. Raise it only when the repo starts using a newer feature.
- `dot_zshrc` / `dot_bashrc` — shell configs. Plain (non-`.tmpl`) so `chezmoi re-add` works.
- `dot_zshenv` / `dot_zprofile` — zsh startup hooks, currently comment-only placeholders. `.zshenv` is read by every zsh (scripts included), `.zprofile` only by login shells, before `.zshrc`. Also plain files so `re-add` works.
- `private_dot_profile` — POSIX login-shell profile (`0600`). Currently byte-identical to the Debian `/etc/skel/.profile`; tracked so a fresh machine gets `~/.local/bin` on PATH without depending on what the distro's skel happens to contain.
- `dot_p10k.zsh` — Powerlevel10k prompt theme (lean style, NerdFont).
- `dot_claude/`, `dot_codex/`, `dot_copilot/`, `dot_grok/`, `dot_config/opencode/`, `dot_local/share/crush/`, `dot_dsh/`, `private_dot_hermes/` — per-tool agent/IDE config. Each ships a settings file (`settings.json` / `config.toml` / `opencode.json` / `private_crush.json` / `private_settings.yaml` / `private_config.toml`); most also ship a shared instruction file (`CLAUDE.md` / `AGENTS.md` / `copilot-instructions.md` / `SOUL.md`) carrying the same coding-guideline body — these must stay byte-identical, see Shared Agent Instruction Files below. `dot_claude` also ships two statusline scripts (main session and subagent). Gemini's equivalent config (`GEMINI.md`, `settings.json`, statusline, sidecars) no longer lives here — it is tracked as the `.gemini` external repo, see Externals below.
- `agent-configs.code-workspace` — VS Code workspace deployed to `~`, opening `.agents`, `.gemini` and `.local/share/chezmoi` side by side. Not ignored anywhere, so it lands on every platform.
- `dot_config/*` — terminal and CLI tool configs (`alacritty/` with its imported theme, `btop`, `htop`, `fastfetch`, `neofetch`, `pip.conf`, `uv.toml`, `fcitx5/`, `environment.d/`, `goobuntu-backups/exclude`, git `ignore`).

  **alacritty is not installed by the bootstrap, on purpose.** The tracked config uses the `[general] import` form, which needs alacritty ≥ 0.14; Ubuntu noble's apt candidate is 0.13.2 and would reject it outright, so there is no `packages.yaml` entry and no `setup-body.sh` section. The binary is installed by hand into `~/.local/bin`; like the fcitx5 note under Bootstrap Architecture, the omission is deliberate rather than an oversight.
- `dot_xinputrc` + `dot_chrome-remote-desktop-session` + `dot_config/environment.d/im.conf` — fcitx5 input-method wiring, in three places because nothing covers both sessions: `.xinputrc` (`run_im fcitx5`) and `im.conf` drive the physical session, and the Chrome Remote Desktop session reads neither, so `.chrome-remote-desktop-session` repeats the `GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` trio (plus a `DBUS_SESSION_BUS_ADDRESS`) itself. `.chezmoiignore` deploys that last one on personal Linux only — corp Linux drives its graphical session through goobuntu (`switch-graphical-session`, wrapped by `dot_local/bin/toggle-display`) instead.
- `readonly_Documents/PowerShell/` — the two pwsh profiles, deployed under `~/Documents` on Windows: `profile.ps1` (CurrentUserAllHosts — PATH, PSReadLine, agent aliases) and `Microsoft.PowerShell_profile.ps1` (CurrentUserCurrentHost, VS Code python activation). Ignored on non-Windows.
- `AppData/` — Windows-native config paths: Windows Terminal `settings.json`, `Roaming/pip/pip.ini`, `Roaming/uv/uv.toml`. **The pip and uv files are byte-identical copies of `dot_config/pip/pip.conf` and `dot_config/uv/uv.toml`** — Windows looks for them under AppData, so `.chezmoiignore` drops the `.config` pair there and ships these instead. Editing one side means editing the other. Ignored on non-Windows.
- `executable_setup_adb.sh` — corp-only, deployed as `~/setup_adb.sh`. Points `ADB_VENDOR_KEYS` at the `adb-keys/security` external and restarts the adb server / pontisd. Ignored unless `is_work`.
- `private_dot_gdu.yaml` / `private_dot_npmrc` — small single-purpose tool state (gdu colors, npm flags).
- `dot_local/share/fonts/meslo/` — MesloLGS NF (NerdFont) TTFs used by the p10k prompt.
- `dot_local/bin/` — five scripts, split across two different gates. Three are ignored unless `is_work && linux`: `linux-kernel-mount` (mount/umount/remount/status of the sshfs kernel tree at `~/linux_kernel`, plus a `daemon` mode for the systemd user service; overridable via `LINUX_KERNEL_HOST` / `LINUX_KERNEL_REMOTE_DIR` / `LINUX_KERNEL_LOCAL_DIR`), `automation-mount` (same shape for `~/automation`, with `AUTOMATION_*` overrides) and `kgrep` (runs ripgrep on the remote host instead of pulling file contents over the mount). The other two are only ignored on Windows, so they deploy on personal machines too even though they are corp tools: `list_devices` (attached Pixel boards via adb/fastboot, a fast local stand-in for flashstation's own `list_devices`) and `toggle-display` (switches the goobuntu graphical session between Chrome Remote Desktop and local HDMI).
- `dot_config/systemd/user/` — the two systemd user units that drive the `dot_local/bin/` mount helpers at login: `linux-kernel-sshfs.service` and `automation-sshfs.service`, each running its helper's `daemon` mode with `Restart=always` (corpssh certs expire, so retrying beats giving up at boot). Ignored unless `is_work && linux`. **chezmoi deploys the unit files but cannot enable them** — the `default.target.wants/` symlinks are systemd state, not dotfiles, so a fresh machine still needs `systemctl --user enable --now linux-kernel-sshfs automation-sshfs` once.
- `executable_cleanup.sh` — ad-hoc cleanup utility (NOT auto-run; deployed as `~/cleanup.sh` for manual use).
- `install.sh` — Codespace bootstrap one-liner; runs `chezmoi init --apply`. Not deployed to `$HOME`.

### Shared Agent Instruction Files

Every agent CLI reads a different filename, but they must all get the same instructions. **These six files are byte-identical copies of one body. Editing any one of them means editing all six in the same commit — never let them drift.**

| Path | Deployed to | Read by |
|---|---|---|
| `dot_claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Claude Code |
| `dot_codex/AGENTS.md` | `~/.codex/AGENTS.md` | Codex |
| `dot_grok/AGENTS.md` | `~/.grok/AGENTS.md` | Grok CLI |
| `dot_config/opencode/AGENTS.md` | `~/.config/opencode/AGENTS.md` | opencode |
| `dot_copilot/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | GitHub Copilot CLI |
| `private_dot_hermes/SOUL.md` | `~/.hermes/SOUL.md` | Hermes |

Verify after any edit — all six checksums must match:

```bash
md5sum dot_claude/CLAUDE.md dot_codex/AGENTS.md dot_grok/AGENTS.md \
       dot_config/opencode/AGENTS.md dot_copilot/copilot-instructions.md \
       private_dot_hermes/SOUL.md
```

The per-tool settings files sitting next to them (`settings.json`, `config.toml`, `opencode.json`, `private_crush.json`, `private_config.toml`) are **not** shared — each is tool-specific and unrelated to the others. `dot_local/share/crush/` ships only a settings file, no instruction file.

`~/.gemini/GEMINI.md` is a **partial** sibling: it lives in the `.gemini` external repo (not this one, see Externals below) and shares everything above `## For GitHub Repositories Only` — currently `## General` and `## Self-improvement`, byte-identical. That GitHub section is where it diverges, and stays out of it because that machine is a corp environment; below the divergence GEMINI.md carries its own corp-only sections. Changes to the shared part should be carried over there by hand; anything from `## For GitHub Repositories Only` down should not.

### Shell Config Structure

Both `dot_zshrc` and `dot_bashrc` cover the same ground, with a few zsh-only pieces called out:
1. PATH extensions (`.local/bin`, Go, Cargo, Neovim, OpenOCD)
2. NVM loading — zsh lazy-loads via the oh-my-zsh `nvm` plugin (`zstyle ':omz:plugins:nvm' lazy yes`); bash sources `~/.nvm/nvm.sh` eagerly
3. Common aliases (`cc='claude'`, `cop='copilot'`, `cod='codex'`)
4. Runtime-gated environment blocks — three FQDN `case` arms: work (`*.c.googlers.com|*.corp.google.com|*.roam.internal` → `sshping`, `ADB_VENDOR_KEYS`, `CORP_SSH_HELPER_OVERRIDES`), roam-only (`*.roam.internal` → `agy`, `jetski-cli`), and Cloudtop (`*.c.googlers.com|*.corp.google.com` → sources `g4d` + `dc_setup.sh`, plus `gemini`/`agy`/`jetski`/`flash`/`recovery`/`listd`/`fetch`/`duckie` aliases). No-op on personal machines.
5. Editor selection (zsh only: vim over SSH, nvim locally)

zsh additionally loads oh-my-zsh (theme `powerlevel10k`, plugins `git`/`dotenv`/`nvm`/`zsh-autosuggestions`/`zsh-syntax-highlighting`); bash does not.

**Windows has a third copy of the PATH list.** `readonly_Documents/PowerShell/profile.ps1` prepends seven entries. The first three are the ones from item 1 that exist on Windows too (`~/.local/bin`, `~/go/bin`, `~/.cargo/bin`); the rest of item 1 is *nix-only paths. The other four are Windows-only tool directories with no `dot_zshrc` counterpart (`~/.grok/bin`, `~/.local/bin/adb`, `~/AppData/Local/agy/bin`, `~/AppData/Local/Programs/obsidian`). Changing the PATH line in `dot_zshrc` / `dot_bashrc` means checking whether the new entry belongs there as well.

### Bootstrap Architecture

Two entry points share `.chezmoitemplates/setup-body.sh`. The body opens with an `in_container` helper (`/.dockerenv`, `/run/.containerenv`, `CODESPACES` / `REMOTE_CONTAINERS` / `DEVCONTAINER`) and runs twelve idempotent sections in three groups: a system layer (§1–4, everything that needs sudo, kept first and contiguous so one password prompt at the start covers the run), a user layer (§5–11, installs into `$HOME`, no sudo), and a work-only tail (§12).

1. **OS packages** — brew on darwin (plus corp Mule packages when `is_work`); apt-get on Linux. Package list lives in `.chezmoidata/packages.yaml`. Corp Linux (gLinux) also installs the `work_linux` packages and flushes the delayed-install queue with `install-delayed-packages -u`.

   **Nothing needing a LOAS cert may run before the apt work.** The corp apt repos authenticate with the *machine* certificate, so `apt-get` never needs `gcert` — only the google3 depot the §2 VS Code installer reads does. That is why the `work_linux` install sits in §1, ahead of it.

   **Always `apt-get`, never `apt`.** `apt` has no stable CLI interface and prints `WARNING: apt does not have a stable CLI interface` to stderr on every non-tty run, which is exactly how this script executes under `chezmoi apply`. Do not add `--update` to the installs either: §1 already ran `apt-get update`, and `--update` is (per `apt-get(8)`) merely syntactic sugar for `update && install`. A plain `install` still upgrades an already-installed package to the candidate version, so it is not needed for freshness.
2. **VS Code** (Linux only) — forks on `is_work`: corp Linux runs the google3 VS Code installer, everyone else adds the public Microsoft apt repo and installs `code`.

   The google3 installer needs a LOAS cert. `gcert` is interactive: it drives the gnubby over `ssh-agent` and fails immediately when `SSH_AUTH_SOCK` is unset, which is the normal case under a non-interactive `chezmoi apply`, and also inside tmux (go/sk-screen-tmux). Hence `gcertstatus --quiet --check_remaining=1h` guarding `gcert --nocorpssh --noprodssh || true`: refresh only below an hour, and take whatever lifetime the policy hands out — the cert just has to outlive this run, so do not put `--lifetime` back. **Never let a failing `gcert` be the last command of a list** — under `set -e` that kills the whole setup, nvm, npm and uv included.

   The installer then runs unconditionally. This is deliberate: with no cert it fails and `set -e` stops setup there, which is the intended signal to go run `gcert` and re-run, rather than having setup quietly skip VS Code. Do not reintroduce a `gcertstatus` gate around the installer.

   **The corp branch installs no VS Code package of its own.** `install_vscode_for_google3.sh` runs `sudo apt install bugged code vscode-google3` itself, behind its own idempotence check, and calls `glinux-add-repo bugged stable` to add the repo `bugged` lives in. That is why `bugged` and `vscode-google3` are *not* in `work_linux`: nothing else adds that repo, so a fresh machine would fail the `apt-get install` before the installer ever ran.
3. **Neovim** (Linux only) — official release tarball into `/opt`: distro nvim is often too old (or absent) for LazyVim, and the neovim PPA is Ubuntu-only. darwin gets neovim from brew in §1.
4. **Default shell** — `chsh -s zsh`, skipped in containers (`in_container`): the image controls the shell and `chsh` can hang non-interactively.
5. **lazygit** (Linux only) — GitHub release binary into `~/.local/bin` (no apt package on Debian/Ubuntu). darwin gets lazygit from brew in §1.
6. **Font cache refresh** — `fc-cache -f` (Linux only).
7. **LazyVim starter** — `git clone` into `~/.config/nvim` only if absent. Deliberately a script clone (not a chezmoi external) because LazyVim is meant to be customized after first install — an external would re-pull and clobber user edits.
8. **nvm + default LTS** — installs nvm into `~/.nvm` (mac/linux) via the official installer if absent, then `nvm install --lts` and `nvm alias default 'lts/*'`. Runs with `PROFILE=/dev/null` so the installer does not append source lines to the chezmoi-managed `~/.zshrc` / `~/.bashrc` (those already load `~/.nvm`).
9. **Global npm CLIs** — `npm install -g` over the `npm_global` list in `packages.yaml`. Runs right after nvm so node/npm are on PATH. Installs latest (no version pins); npm re-install is a no-op when already current, so re-runs are cheap. Gated by `{{ if not (and .is_work (eq .chezmoi.os "darwin")) }}` — work macOS (Roam laptops) still gets nvm + node LTS from §8, but no global CLIs.
10. **uv** — installs the Astral installer script if `uv` is absent. Runs with `UV_NO_MODIFY_PATH=1` so it does not append source lines to the chezmoi-managed shell configs; `~/.local/bin` (its install target) is already on PATH there.
11. **fastfetch** — GitHub release tarball into `~/.local/bin`, on Linux and darwin alike. Deliberately not a package: Ubuntu 24.04's apt has no fastfetch, so a `packages.yaml` entry would break `mai0313` under `set -e`, and brew and Debian's apt would each land a different version. Tracks `latest`, no version pin. The tarball unpacks under a `usr/bin` prefix, hence `--strip-components=3`. Windows gets the same binary from §Entry point 3.
12. **Work-only ADB systemd env + pontisd restart** — gated by `{{ if and .is_work (eq .chezmoi.os "linux") }}`, renders to nothing elsewhere.

**The input method (fcitx5) is deliberately not a section here.** It used to be the last section and was removed: installing it needs `sudo apt-get`, setup reaches that point long after the sudo timestamp has expired, and so a re-run with nothing to do still stopped to ask for a password. fcitx5 is installed and set up by hand now. `dot_config/environment.d/im.conf` (the `GTK_IM_MODULE` / `QT_IM_MODULE` / `XMODIFIERS` trio) stays tracked because it is a dotfile rather than an install step — that is not an invitation to put the packages back into `packages.yaml`.

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

Windows-only, PowerShell. Cannot share `setup-body.sh` (no bash), so it reimplements the two sections that apply: the `npm_global` CLIs (skipped with a message if npm is not on PATH — node/npm are assumed pre-installed) and fastfetch. Wrapped in `{{ if eq .chezmoi.os "windows" }}`, so it renders empty (and chezmoi skips it) on macOS/Linux. Windows PowerShell 5.1 compatible.

The fastfetch block mirrors §11 of `setup-body.sh` — same release, same `~/.local/bin` — with two Windows-only wrinkles. The zip is flat and ships `libqjs-0.dll` and `lua55.dll` next to `fastfetch.exe`, so all three are copied; dropping the DLLs leaves an exe that will not start. And the idempotence check is `Test-Path` on the exe, not `Get-Command`: `~/.local/bin` only reaches PATH through `readonly_Documents/PowerShell/profile.ps1`, which this script never loads, so a `Get-Command` check would reinstall on every run.

#### Why share via `.chezmoitemplates`?

The chezmoi-driven and manual paths must stay byte-identical. Putting body in `.chezmoitemplates/setup-body.sh` and including from both entries prevents drift. Verify with:

```bash
diff <(chezmoi execute-template < .chezmoiscripts/run_onchange_after_setup.sh.tmpl) \
     <(chezmoi execute-template < executable_setup.sh.tmpl)
# Expected: no output (identical) on non-Windows.
```

#### Shebang trim caveat

The chezmoi-driven script gate uses `{{- if ... -}}` (with both `-`) so the body's `#!/usr/bin/env bash` lands on line 1 of the rendered file. A leading newline causes `fork/exec` to fail with `exec format error` because the kernel doesn't see `#!` at byte 0. Always check `chezmoi execute-template < <script>.tmpl | head -c 2` returns `#!` after editing the gate.

### Externals (`.chezmoiexternal.toml`)

| Path | URL | Refresh | Condition |
|---|---|---|---|
| `.agents` | `Mai0313/skills` (GitHub) | 1h | always |
| `.gemini` | `Mai0313/.gemini` (GitHub) | 1h | always |
| `.oh-my-zsh` | `ohmyzsh/ohmyzsh` (GitHub) | 24h | non-Windows |
| `.oh-my-zsh/custom/themes/powerlevel10k` | `romkatv/powerlevel10k` | 24h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-autosuggestions` | `zsh-users/zsh-autosuggestions` | 24h | non-Windows |
| `.oh-my-zsh/custom/plugins/zsh-syntax-highlighting` | `zsh-users/zsh-syntax-highlighting` | 24h | non-Windows |
| `adb-keys/security` | `sso://googleplex-android/.../security` | 1h | `is_work` |

All are `type = "git-repo"`. The four non-Windows externals (oh-my-zsh, p10k, and the two zsh plugins) pin `--depth=1` clone and `--ff-only` pull; `.agents`, `.gemini`, and `adb-keys/security` use plain full clones/pulls. `.gemini` deploys the whole `~/.gemini` directory (GEMINI.md, settings, statusline, babysitter sidecars); the gemini CLI's own runtime state (oauth creds, logs, tmp) is `.gitignore`d in that repo, so it coexists with the working copy just like oh-my-zsh's cache does. Pulling on chezmoi's schedule is compatible with oh-my-zsh's own `git pull`-based self-update — no need to disable oh-my-zsh auto-update. Externals refresh independently of the setup script's `run_onchange_` hash. `refreshPeriod` does apply to `git-repo` externals (it throttles the `git pull`), even though upstream docs only mention it under `file` and `archive` — do not remove it from the entries here.
