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

`chezmoi apply` handles everything: it deploys dotfiles, clones external
dependencies (oh-my-zsh, powerlevel10k, plugins, ADB keys on work), and
runs the scripts in `.chezmoiscripts/` to install OS packages, set zsh as
default shell, and bootstrap LazyVim. No manual setup script needed.

The one-liner above (`chezmoi init --apply`) covers fresh machines and
Codespaces. Already-initialized machines pick up future changes via
`chezmoi update`.

### Cleanup

`~/cleanup.sh` is an ad-hoc utility (not run automatically) for clearing
stray hidden caches like `.ipython`, `.dotnet`, `.pki`. Use as needed.
