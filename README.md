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

### Edit a dotfile

```bash
# Edit and apply in one step
chezmoi edit --apply ~/.zshrc

# Or edit first, review, then apply
chezmoi edit ~/.zshrc
chezmoi diff          # Preview what will change
chezmoi apply         # Apply changes
```

> **Important:** Do not edit `~/.zshrc` (or other managed files) directly — `chezmoi apply` will overwrite your changes. Always use `chezmoi edit`.

### Add a new file

```bash
chezmoi add ~/.some_config
```

If the file needs per-machine customization, add it as a template:

```bash
chezmoi add --template ~/.some_config
```

### Remove a managed file

```bash
chezmoi forget ~/.some_config   # Stop managing (keeps the file)
chezmoi destroy ~/.some_config  # Stop managing and delete the file
```

### Check status

```bash
chezmoi status    # Show which files differ from source
chezmoi diff      # Show detailed diff
chezmoi managed   # List all managed files
chezmoi data      # Show template data (is_work, is_codespace, etc.)
```

### Push changes to GitHub

```bash
chezmoi cd                          # Enter source directory
git add -A && git commit -m "..."   # Commit
git push                            # Push
exit                                # Back to previous directory
```

### Pull changes from GitHub (on another machine)

```bash
chezmoi update    # = git pull + chezmoi apply
```

Or review before applying:

```bash
chezmoi git pull
chezmoi diff      # Review changes
chezmoi apply     # Apply if looks good
```

### First-time setup on a new machine

After `chezmoi apply` deploys the dotfiles, run the setup scripts manually:

```bash
~/setup.sh          # Install zsh, oh-my-zsh, powerlevel10k, fonts
~/setup_adb.sh      # (Cloudtop only) Clone ADB vendor keys
```
