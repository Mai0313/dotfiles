# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

One-liner to set up a new machine:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply Mai0313/dotfiles
```

### GitHub Codespaces

1. Go to [GitHub Settings > Codespaces](https://github.com/settings/codespaces)
2. Set **Dotfiles repository** to `Mai0313/dotfiles`
3. Check **Automatically install dotfiles**

New codespaces will be configured automatically.

### Claude Code cloud

Put the one-liner in the cloud environment's setup script, after
`export CLAUDE_CODE_REMOTE=true`: the environment's own variables are not set
yet while that script runs. `.agents` is a private repo, so the script also has
to give git a token that can read it.

## Environment Detection

The config template computes three flags at `chezmoi init`; OS differences come
from chezmoi's built-ins. Containers skip the VS Code install and the default
shell change. A cloud session also skips the OS packages, neovim, node and the
npm CLIs, and the zsh plugins, which leaves little beyond the dotfiles and the
agent skills.

| Environment | Detection | Flag |
|---|---|---|
| Cloudtop (gLinux) | `*.c.googlers.com` / `*.corp.google.com` | `is_work` |
| Roam (work macOS) | `*.roam.internal` | `is_work` |
| Codespaces / devcontainers / containers | `CODESPACES`, `REMOTE_CONTAINERS`, `DEVCONTAINER`, `/.dockerenv`, `/run/.containerenv` | `is_container` |
| Claude Code cloud | `CLAUDE_CODE_REMOTE=true` | `is_cloud` |
| Personal | default | none |

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

`~/.local/bin/setup` is also deployed (Linux/macOS only) as a manual entry
point with the identical body. Run it yourself to bootstrap without invoking
chezmoi. Windows gets `~/.local/bin/setup.ps1` the same way.

### Some Useful Examples

SSH Login (one time effort)

```bash
ssh-keygen -t ed25519
ssh-copy-id xxx@host.example.com
```

Example for migrating Cloudtop

```bash
sudo glinux-updater && sudo apt update && sudo apt upgrade && sudo apt install gh && BROWSER=false gh auth login
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" init --apply Mai0313/dotfiles
ctop migrate --allow_cloudtop_source --shortname=<cloudtop_name> --skip_create --exclude_files=linux_kernel/
```
