# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

One-liner to set up a new machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply https://github.com/mai0313/dotfiles.git
```

### GitHub Codespaces

1. Go to [GitHub Settings > Codespaces](https://github.com/settings/codespaces)
2. Set **Dotfiles repository** to `mai0313/dotfiles`
3. Check **Automatically install dotfiles**

New codespaces will be configured automatically.

## Environment Detection

The config template computes a single `is_work` flag from the FQDN; container
and OS differences are handled at runtime by the setup script.

| Environment | Detection | `is_work` |
|---|---|---|
| Cloudtop (gLinux) | `*.c.googlers.com` / `*.corp.google.com` | `true` |
| Roam (work macOS) | `*.roam.internal` | `true` |
| Personal / Codespaces / containers | default | `false` |

## Daily Usage

```bash
chezmoi diff          # Check what changed between local and source
chezmoi apply         # Apply source state to local files
chezmoi re-add        # Sync local changes back to source directory
chezmoi add ~/.file   # Start tracking a new file
chezmoi forget ~/.file # Stop tracking a file (keeps the local copy)
chezmoi update        # Pull from remote + apply (for other machines)
```

Tracking is always managed through chezmoi: `chezmoi add` to start tracking a
file, `chezmoi forget` to stop. `forget` only removes the file from the source
directory, the copy in `$HOME` stays untouched. Use `chezmoi destroy` if you
also want the local copy gone.

### First-time setup on a new machine

`chezmoi apply` handles everything: it deploys dotfiles, clones external
dependencies (oh-my-zsh, powerlevel10k, plugins, ADB keys on work), and
runs the bootstrap script in `.chezmoiscripts/` to install OS packages,
set zsh as default shell, and seed LazyVim.

The one-liner above (`chezmoi init --apply`) covers fresh machines and
Codespaces. Already-initialized machines pick up future changes via
`chezmoi update`.

The bootstrap script auto-runs on the first `chezmoi apply` and re-runs only
when its content changes, for example when you edit `.chezmoidata/packages.yaml`.
Each section is idempotent, so a re-run just installs what changed.

`~/setup.sh` is also deployed (Linux/macOS only) as a manual entry point with
the identical body. Run it yourself to bootstrap without invoking chezmoi.

### Cleanup

`~/cleanup.sh` is an ad-hoc utility (not run automatically) for clearing
stray hidden caches like `.ipython`, `.dotnet`, `.pki`. Use as needed.
