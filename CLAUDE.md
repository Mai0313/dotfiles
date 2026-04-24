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

- `dot_*` -> files with leading `.` (e.g., `dot_zshrc.tmpl` -> `~/.zshrc`)
- `executable_*` -> deployed with execute permission (e.g., `executable_setup.sh` -> `~/setup.sh`)
- `empty_*` -> creates empty files (e.g., `empty_dot_zshenv` -> `~/.zshenv`)
- `.tmpl` suffix -> processed as Go templates with chezmoi data

### Environment Detection (`.chezmoi.toml.tmpl`)

Template variables set based on hostname/env:

| Variable | Condition | Use |
|---|---|---|
| `is_work` | hostname `*.c.googlers.com` or `*.roam.internal` | ADB keys, work aliases |
| `is_cloudtop` | hostname `*.c.googlers.com` | Gemini CLI alias (Cloudtop only) |
| `is_codespace` | env `CODESPACES=true` | Codespaces-specific config |

Used in templates as `{{- if .is_work }}...{{- end }}`.

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
