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

**Currently no `.tmpl` file consumes these variables.** They are kept as a reserved hook so that if a future config file needs to branch at template-render time (e.g. a per-environment `settings.json`), `{{ if .is_work }}` will just work without rebuilding detection logic. You can inspect the current values with `chezmoi data | grep is_`.

**Layer 2 — runtime shell gating (actual behavior).** Shell configs (`dot_zshrc`, `dot_bashrc`) and setup scripts (`executable_setup_adb.sh`, `executable_install_skills.sh`) each do their own `case "$(hostname -f)"` match on the same FQDN patterns. **All live gating happens here, not in chezmoi templates.**

**Why runtime, not template?** `chezmoi re-add` cannot reverse-merge local edits back into Go template syntax. Keeping these four files as plain (non-`.tmpl`) scripts means the user can edit them in `$HOME` and sync back with `chezmoi re-add ~/.zshrc` (etc.) without hand-patching the source tree.

**Future-agent guidance: do NOT "refactor" the runtime `case` blocks back into `{{ if .is_work }}` templates.** This conversion was made deliberately; reversing it would break the `re-add` workflow. If you think a `.tmpl` would be cleaner, you are missing the workflow constraint — read this section again.

**Known duplication.** The FQDN pattern `*.c.googlers.com|*.roam.internal` appears in `.chezmoi.toml.tmpl` (Layer 1) plus the four shell files (Layer 2). If the pattern ever changes, grep for both `c.googlers.com` and `roam.internal` to find every occurrence.

### Key Files

- `.chezmoi.toml.tmpl` - chezmoi config, defines template variables
- `dot_zshrc` / `dot_bashrc` - shell configs (Zsh primary, Bash mirror). Environment-specific blocks gate themselves at runtime via `case "$(hostname -f)"`, so the files stay plain (non-template) and `chezmoi re-add` works after local edits.
- `dot_p10k.zsh` - Powerlevel10k prompt theme (lean style, NerdFont)
- `dot_claude/settings.json` - Claude Code settings
- `dot_gemini/settings.json` - Google Gemini settings
- `executable_setup.sh` - main setup script (oh-my-zsh, p10k, neovim, fonts)
- `executable_setup_adb.sh` - ADB vendor key setup; self-gates at runtime via FQDN check (work-only; no-op elsewhere). Kept as plain script (not `.tmpl`) so `chezmoi re-add` works after local edits.
- `executable_install_skills.sh` - Agent Skills installer from google3; self-gates at runtime via FQDN check (work/Cloudtop-only). Same `.tmpl`-free rationale as above.
- `executable_cleanup.sh` - removes temp/cache dirs, preserves key config files
- `.chezmoiignore` - prevents `install.sh` and READMEs from being deployed to `$HOME`

### Shell Config Structure

Both `dot_zshrc` and `dot_bashrc` share the same pattern:
1. PATH extensions (Go, Rust, Cargo, Miniconda, Neovim)
2. NVM lazy loading
3. Common aliases (`cc='claude'`)
4. Runtime-gated environment block — FQDN `case` matching `*.c.googlers.com|*.roam.internal` (work: ADB_VENDOR_KEYS) and `*.c.googlers.com` (Cloudtop: `gemini`, `jetski-cli` aliases). No-op on personal machines.
5. Editor selection (vim over SSH, nvim locally)

### Setup Scripts

Scripts are deployed as `~/setup.sh`, `~/setup_adb.sh`, `~/install_skills.sh`, `~/cleanup.sh`. They are **not** chezmoi hooks - they must be run manually after `chezmoi apply` on first-time setup. `setup.sh` handles both macOS (brew) and Linux (apt).
