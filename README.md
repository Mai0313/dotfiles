# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

One-liner to set up a new machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/mai0313/dotfiles.git
```

### GitHub Codespaces

1. Go to [GitHub Settings > Codespaces](https://github.com/settings/codespaces)
2. Set **Dotfiles repository** to `mai0313/dotfiles`
3. Check **Automatically install dotfiles**

New codespaces will be configured automatically.

## Environment Detection

The config template automatically detects the environment:

| Environment | Detection | `is_work` | `is_cloudtop` | `is_codespace` |
|---|---|---|---|---|
| Cloudtop | `*.c.googlers.com` | `true` | `true` | `false` |
| Roam (work) | `*.roam.internal` | `true` | `false` | `false` |
| GitHub Codespaces | `CODESPACES=true` | `false` | `false` | `true` |
| Personal | default | `false` | `false` | `false` |

## Daily Usage

```bash
chezmoi diff          # Check what changed between local and source
chezmoi apply         # Apply source state to local files
chezmoi re-add        # Sync local changes back to source directory
chezmoi add ~/.file   # Start managing a new file
chezmoi update        # Pull from remote + apply (for other machines)
```

### First-time setup on a new machine

After `chezmoi apply` deploys the dotfiles, run the setup scripts manually:

```bash
~/setup.sh          # Install zsh, oh-my-zsh, powerlevel10k, fonts
~/setup_adb.sh      # (Work: Cloudtop + Roam) Clone ADB vendor keys
~/install_skills.sh # (Cloudtop only) Install Agent Skills from google3
```
