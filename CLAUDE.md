# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chezmoi-managed dotfiles repo (`mai0313/dotfiles`). Deploys shell configs, IDE settings, fonts, and setup scripts to `$HOME` across personal machines, Google Cloudtop (work), and GitHub Codespaces.

## Common Commands

```bash
chezmoi diff          # Preview changes before applying
chezmoi apply         # Apply source state to $HOME
chezmoi re-add        # Sync local edits back to source directory
chezmoi add ~/.file   # Start managing a new file
chezmoi cd            # cd into this source directory
```

After editing templates, validate with `chezmoi execute-template < file.tmpl` or `chezmoi diff` to verify output.

## Architecture

### Chezmoi Naming Conventions

- `dot_*` -> files with leading `.` (e.g., `dot_zshrc` -> `~/.zshrc`)
- `executable_*` -> deployed with execute permission (e.g., `executable_setup.sh` -> `~/setup.sh`)
- `empty_*` -> creates empty files (e.g., `empty_dot_zshenv` -> `~/.zshenv`)
- `.tmpl` suffix -> processed as Go templates with chezmoi data

### Environment Detection

**This repo detects the environment in two layers for two different purposes. Do not consolidate them without understanding why.**

**Layer 1 — chezmoi data (`.chezmoi.toml.tmpl`).** Defines three variables at `chezmoi apply` time:

| Variable | Condition |
|---|---|
| `is_work` | FQDN ends with `.c.googlers.com` or `.roam.internal` |
| `is_cloudtop` | FQDN ends with `.c.googlers.com` |
| `is_codespace` | env `CODESPACES=true` |

**Current consumers:** `.chezmoiignore` (templated by chezmoi automatically) gates whole files/directories at deploy time — `executable_install_skills.sh` on `is_cloudtop`, `executable_setup_adb.sh` on `is_work`. The variables remain available for any future per-environment branching (e.g. a per-environment `settings.json`). Inspect current values with `chezmoi data | grep is_`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) do their own `case "$(hostname -f)"` match on the same FQDN patterns to toggle env-specific blocks (aliases, env vars). **All live gating for these mixed-content files happens here, not in chezmoi templates.**

**Why runtime, not template, for shell configs?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping `dot_zshrc` / `dot_bashrc` as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` without hand-patching the source tree. This rule applies because these files mix universal and env-specific content in the same file — runtime gating is the only option.

**Why `.chezmoiignore` for setup scripts?** `executable_setup_adb.sh` and `executable_install_skills.sh` are entirely env-specific (no universal content), so the cleanest gate is at the deploy layer: include the file or don't, based on env. This does NOT violate the `re-add` rule — the file content stays plain bash, so `chezmoi re-add` still works on machines where the file IS deployed (work / Cloudtop). On machines where it's ignored, the file isn't deployed in the first place, so re-add is a no-op there.

**Future-agent guidance: do NOT "refactor" the `dot_zshrc` / `dot_bashrc` runtime `case` blocks into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again. (For the two setup scripts, gating moved from runtime to `.chezmoiignore` because they have no universal content to preserve.)

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus `dot_zshrc` and `dot_bashrc` (Layer 2). If the pattern ever changes, grep for both `c.googlers.com` and `roam.internal` to find every occurrence.

### Key Files

- `.chezmoi.toml.tmpl` - chezmoi config, defines template variables
- `dot_zshrc` / `dot_bashrc` - shell configs (Zsh primary, Bash mirror). Environment-specific blocks gate themselves at runtime via `case "$(hostname -f)"`, so the files stay plain (non-template) and `chezmoi re-add` works after local edits.
- `dot_p10k.zsh` - Powerlevel10k prompt theme (lean style, NerdFont)
- `dot_claude/settings.json` - Claude Code settings
- `dot_gemini/settings.json` - Google Gemini settings
- `executable_setup.sh` - main setup script (oh-my-zsh, p10k, neovim, fonts)
- `executable_setup_adb.sh` - ADB vendor key setup. Work-only (`is_work`) via `.chezmoiignore`; not deployed on personal machines. Plain bash (no `.tmpl`) so `chezmoi re-add` works after local edits on work machines.
- `executable_install_skills.sh` - Agent Skills installer from google3. Cloudtop-only (`is_cloudtop`) via `.chezmoiignore`. Same `.tmpl`-free rationale.
- `executable_cleanup.sh` - removes temp/cache dirs, preserves key config files
- `.chezmoiignore` - prevents `install.sh`, READMEs, and `CLAUDE.md` from being deployed to `$HOME`. Also gates env-specific files via templated conditionals: `install_skills.sh` on `is_cloudtop`, `setup_adb.sh` on `is_work`. Chezmoi treats `.chezmoiignore` as a template by default.

### Shell Config Structure

Both `dot_zshrc` and `dot_bashrc` share the same pattern:
1. PATH extensions (Go, Rust, Cargo, Miniconda, Neovim)
2. NVM lazy loading
3. Common aliases (`cc='claude'`)
4. Runtime-gated environment block — FQDN `case` matching `*.c.googlers.com|*.roam.internal` (work: ADB_VENDOR_KEYS) and `*.c.googlers.com` (Cloudtop: `gemini`, `jetski-cli`, `flash`, `recovery`, `listd` aliases). No-op on personal machines.
5. Editor selection (vim over SSH, nvim locally)

### Setup Scripts

Scripts are deployed as `~/setup.sh`, `~/setup_adb.sh`, `~/install_skills.sh`, `~/cleanup.sh`. They are **not** chezmoi hooks - they must be run manually after `chezmoi apply` on first-time setup. `setup.sh` handles both macOS (brew) and Linux (apt).

Deployment per environment (via `.chezmoiignore`):

| Script | Personal | Roam (work) | Cloudtop |
|---|---|---|---|
| `setup.sh`, `cleanup.sh` | ✅ | ✅ | ✅ |
| `setup_adb.sh` | ❌ | ✅ | ✅ |
| `install_skills.sh` | ❌ | ❌ | ✅ |

**Migrating a machine that previously had everything deployed:** chezmoi does not delete files that newly become ignored. After this gating change, manually `rm` the now-orphaned scripts on affected machines:
- Personal: `rm -f ~/setup_adb.sh ~/install_skills.sh`
- Roam: `rm -f ~/install_skills.sh`
- Cloudtop: nothing to remove.
