#!/usr/bin/env bash
set -euo pipefail

# One step per section. Its gate, if any, is the template line right above the
# title, and the title names it: the OS it runs on, whether it is work-only,
# and which of two contracts it follows. "always" runs on every pass and
# upgrades what is already there (package managers are idempotent). "once" is
# guarded on presence: it installs when nothing is there and never upgrades, so
# a newer version means removing the old install first. Gate lines render to
# nothing and every section ends with one blank line, so a skipped section
# leaves no trace in the rendered script.

# Detect container-like environments (Docker/Podman, Dev Container, Codespaces).
in_container() {
    [ -f /.dockerenv ] || [ -f /run/.containerenv ] || [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${DEVCONTAINER:-}" ]
}

# ============================================================================
# System layer: every step that needs sudo, kept first and contiguous so one
# password prompt at the start of a run covers all of them. New steps that
# need sudo belong in this layer, never below it.
# ============================================================================

{{ if eq .chezmoi.os "darwin" -}}
# ---------- Homebrew packages (darwin; always) ----------
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew install {{ join " " .packages.darwin }}

{{ end -}}
{{ if and .is_work (eq .chezmoi.os "darwin") -}}
# ---------- Mule packages (work darwin; always) ----------
# Corp-only macOS packages distributed via Mule (go/mule).
if command -v mule >/dev/null 2>&1 || [ -x /usr/local/bin/mule ]; then
    sudo mule install {{ join " " .packages.work_darwin }}
fi

{{ end -}}
{{ if eq .chezmoi.os "linux" -}}
# ---------- apt packages (linux; always) ----------
# On corp machines (roam is macOS, so is_work here means gLinux), first every
# apt repo work_linux needs beyond the gLinux defaults, from work_linux_repos
# in packages.yaml, so the one update below sees all of them. --batch skips
# the confirmation prompt, which nothing is there to answer under a
# non-interactive apply; a re-run finds the same content and exits 0.
{{ if .is_work -}}
{{ range .packages.work_linux_repos -}}
sudo glinux-add-repo --batch {{ . }}
{{ end -}}
{{ end -}}
sudo apt-get update
# The corp apt repos authenticate with the machine certificate, so work_linux
# needs no LOAS cert and must stay ahead of the google3 VS Code installer
# below, which does. Some of those packages land in the delayed-install queue
# instead of being applied right away, so flush it after.
sudo apt-get install -y {{ join " " .packages.linux }}{{ if .is_work }} {{ join " " .packages.work_linux }}{{ end }}
{{ if .is_work -}}
sudo install-delayed-packages -u
{{ end -}}

{{ end -}}
{{ if and .is_work (eq .chezmoi.os "linux") -}}
# ---------- VS Code from google3 (work linux; always) ----------
# Corp Linux (gLinux) gets VS Code from google3, not the Microsoft apt repo.
# code, bugged and vscode-google3 are in work_linux, which satisfies the guard
# the installer opens with, so what is left of it here is the crontab entry and
# the google3 extension symlinks -- the parts no package does for you. It reads
# the google3 depot, which needs a LOAS cert; `|| true` keeps a gcert failure
# (usual under a non-interactive apply) from killing the rest of setup.
if ! gcertstatus --quiet --check_remaining=1h 2>/dev/null; then
    gcert --nocorpssh --noprodssh || true
fi
/google/src/files/head/depot/google3/devtools/editors/vscode/install_vscode_for_google3.sh

{{ end -}}
{{ if and (not .is_work) (eq .chezmoi.os "linux") -}}
# ---------- VS Code from the Microsoft repo (personal linux; always) ----------
# The key and the repo are added once; the install sits outside those guards
# so a machine that already has the repo still gets code.
if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm -f /tmp/microsoft.gpg
fi
if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
    sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'VSCODE'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
VSCODE
    sudo apt-get update
fi
sudo apt-get install -y code

{{ end -}}
# ---------- default shell (always) ----------
# Skipped in containers: the image controls the shell, chsh can hang
# non-interactively, and the change does not survive a rebuild.
ZSH_PATH="$(command -v zsh || true)"
if ! in_container && [ -n "$ZSH_PATH" ] && [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    {{ if eq .chezmoi.os "darwin" }}chsh -s /bin/zsh{{ else }}sudo chsh -s "$ZSH_PATH" "$(whoami)"{{ end }}
fi

# ============================================================================
# User layer: everything below installs into $HOME and never needs sudo.
# ============================================================================

{{ if eq .chezmoi.os "linux" -}}
# ---------- font cache (linux; always) ----------
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null
fi

{{ end -}}
{{ if eq .chezmoi.os "linux" -}}
# ---------- neovim (linux; once) ----------
# Distro nvim is often too old (or absent) for LazyVim, and the neovim PPA is
# Ubuntu-only (breaks on Debian/glinux). Upstream's INSTALL.md unpacks to /opt,
# but the tarball is relocatable (nvim derives $VIMRUNTIME from its own path),
# so unpacking under $HOME keeps this out of the sudo layer above. Its bin/ is
# on PATH via dot_zshrc/dot_bashrc.
case "$(uname -m)" in
    x86_64)  NVIM_ARCH=x86_64 ;;
    aarch64) NVIM_ARCH=arm64 ;;
    *) echo "Unsupported arch for neovim: $(uname -m), skipping"; NVIM_ARCH= ;;
esac
if [ -n "$NVIM_ARCH" ] && ! command -v nvim >/dev/null 2>&1 && [ ! -x "$HOME/.nvim/bin/nvim" ]; then
    curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
    rm -rf "$HOME/.nvim"
    mkdir -p "$HOME/.nvim"
    tar -C "$HOME/.nvim" --strip-components=1 -xzf /tmp/nvim.tar.gz
    rm -f /tmp/nvim.tar.gz
fi

{{ end -}}
# ---------- LazyVim starter (once) ----------
# Deliberately a clone here rather than a chezmoi external: the starter is a
# seed you are meant to edit afterwards, and an external would re-pull on its
# refreshPeriod and clobber those edits. Dropping .git and guarding on the
# directory is what makes it a one-time seed.
NVIM_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_DIR" ]; then
    git clone https://github.com/LazyVim/starter "$NVIM_DIR"
    rm -rf "$NVIM_DIR/.git"
fi

# ---------- node LTS via nvm (always) ----------
# nvm itself is a chezmoi external, which lands before this script runs; its
# own installer is skipped entirely, which also removes the reason the old one
# needed PROFILE=/dev/null (it appends source lines to the chezmoi-managed
# ~/.zshrc / ~/.bashrc). Shell configs already source ~/.nvm.
export NVM_DIR="$HOME/.nvm"
# The number lives in .chezmoidata/node.yaml, shared with setup-body.ps1, which
# is also where the reason for pinning it is written down.
NODE_VERSION="{{ .node_version }}"
# Load nvm into this non-interactive shell, then make that version the default.
set +u
\. "$NVM_DIR/nvm.sh"
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"
set -u

{{ if not (and .is_work (eq .chezmoi.os "darwin")) -}}
# ---------- global npm CLIs (skipped on work darwin; always) ----------
# node/npm are on PATH now (nvm loaded above). Lists live in packages.yaml;
# home_npm joins in off work only.
if command -v npm >/dev/null 2>&1; then
    # The npm bundled with node LTS is usually a release or two behind, which is
    # what prints the "New version of npm available" notice on a fresh install,
    # so npm@latest heads the list.
    npm install -g {{ join " " .packages.npm }}{{ if not .is_work }} {{ join " " .packages.home_npm }}{{ end }}
fi

{{ end -}}
# ---------- uv (once) ----------
# Installs to ~/.local/bin, already on PATH in the shell configs.
# UV_NO_MODIFY_PATH keeps the installer from appending source lines to the
# chezmoi-managed ~/.zshenv / ~/.bashrc.
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
fi

# ---------- agent skills symlinks (always) ----------
# ~/.agents is the skills external; each agent CLI looks for the same set under
# its own path, so link rather than keep copies. A real directory at the target
# is somebody else's collection and is left alone.
SKILLS_SRC="$HOME/.agents/skills"
SKILLS_LINKS=(
    "$HOME/.claude/skills"
    "$HOME/.gemini/config/skills"
)
if [ -d "$SKILLS_SRC" ]; then
    for skills_link in "${SKILLS_LINKS[@]}"; do
        if [ ! -e "$skills_link" ] || [ -L "$skills_link" ]; then
            mkdir -p "$(dirname "$skills_link")"
            ln -sfn "$SKILLS_SRC" "$skills_link"
        fi
    done
fi

{{ if and .is_work (eq .chezmoi.os "linux") -}}
# ---------- pontisd (work linux; always) ----------
# The pontisd package itself comes from work_linux in the apt section; this
# only points it at the ADB vendor keys and restarts it.
KEYS_DIR="$HOME/adb-keys/security/adb"
if [ -d "$KEYS_DIR" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl --user set-environment ADB_VENDOR_KEYS="$KEYS_DIR" || true
    systemctl --user daemon-reload || true
    systemctl --user restart pontisd 2>/dev/null || true
fi

{{ end -}}
{{ if .is_work -}}
# ---------- dhub (work; once) ----------
# go/dhub-host. The team also ships a launcher envsetup.sh to source from a
# shell config, but that pulls the whole launcher in for one binary; this drops
# the same binary into ~/.local/bin, which is already on PATH. `latest` holds
# the version string, so the release path is only known after reading it.
# The launcher stays available either way, so this is the alternative rather
# than the requirement: chained with && so a failure (no credentials, no
# gcloud, bucket unreachable) skips the rest and reports instead of taking the
# run down. That tolerance is what lets roam macOS try too, where the bucket
# has a `mac` build but nothing installs gcloud.
if ! command -v dhub >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/dhub" ]; then
    DHUB_VERSION="$(gcloud storage cat gs://gchips-dta-tools/dhub/rapid/latest)" &&
        mkdir -p "$HOME/.local/bin" &&
        gcloud storage cp "gs://gchips-dta-tools/dhub/rapid/${DHUB_VERSION}/{{ if eq .chezmoi.os "darwin" }}mac{{ else }}glinux{{ end }}/dhub.par" "$HOME/.local/bin/dhub" &&
        chmod +x "$HOME/.local/bin/dhub" ||
        echo "dhub install skipped; install it by hand if needed (go/dhub-host)" >&2
fi

{{ end -}}
