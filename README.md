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

| Environment | Detection | `is_work` | `is_codespace` |
|---|---|---|---|
| Cloudtop | `*.c.googlers.com` | `true` | `false` |
| GitHub Codespaces | `CODESPACES=true` | `false` | `true` |
| Personal | default | `false` | `false` |

## Daily Usage

```bash
chezmoi edit --apply ~/.zshrc   # Edit and apply a dotfile
chezmoi add ~/.some_config      # Add a new file to chezmoi
chezmoi update                  # Pull latest changes and apply
chezmoi diff                    # Preview pending changes
chezmoi cd                      # Enter source directory (git repo)
```
