#!/usr/bin/env bash
set -euo pipefail

# ---------- 1. OS packages ----------
{{ if eq .chezmoi.os "darwin" -}}
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew install {{ range .packages.darwin }}{{ . }} {{ end }}

{{ else if eq .chezmoi.os "linux" -}}
sudo apt-get update
sudo apt-get install -y {{ range .packages.linux }}{{ . }} {{ end }}

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

# Default Ubuntu nvim is too old for LazyVim, install from PPA.
if ! command -v nvim >/dev/null 2>&1; then
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update
    sudo apt-get install -y neovim
fi

# lazygit has no apt package on Debian/Ubuntu, fetch from GitHub release.
if ! command -v lazygit >/dev/null 2>&1; then
    case "$(uname -m)" in
        x86_64)  LAZYGIT_ARCH=x86_64 ;;
        aarch64) LAZYGIT_ARCH=arm64 ;;
        armv7l)  LAZYGIT_ARCH=armv6 ;;
        *) echo "Unsupported arch for lazygit: $(uname -m), skipping"; LAZYGIT_ARCH= ;;
    esac
    if [ -n "$LAZYGIT_ARCH" ]; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        mkdir -p "$HOME/.local/bin"
        install /tmp/lazygit "$HOME/.local/bin"
        rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    fi
fi
{{- end }}

# ---------- 2. Refresh font cache ----------
{{ if eq .chezmoi.os "linux" -}}
if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f >/dev/null
fi
{{- end }}

# ---------- 3. Set zsh as default shell ----------
{{ if not .is_codespace -}}
ZSH_PATH="$(command -v zsh || true)"
if [ -n "$ZSH_PATH" ] && [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    {{ if eq .chezmoi.os "darwin" -}}
    chsh -s /bin/zsh
    {{- else }}
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
    {{- end }}
fi
{{- end }}

# ---------- 4. LazyVim starter ----------
NVIM_DIR="$HOME/.config/nvim"
if [ ! -d "$NVIM_DIR" ]; then
    git clone https://github.com/LazyVim/starter "$NVIM_DIR"
    rm -rf "$NVIM_DIR/.git"
fi

# ---------- 5. Work-only: ADB systemd environment + pontisd ----------
{{ if and .is_work (eq .chezmoi.os "linux") -}}
KEYS_DIR="$HOME/adb-keys/security/adb"
if [ -d "$KEYS_DIR" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl --user set-environment ADB_VENDOR_KEYS="$KEYS_DIR" || true
    systemctl --user daemon-reload || true
    systemctl --user restart pontisd 2>/dev/null || true
fi
{{- end }}

# ---------- 6. Mark bootstrap as complete ----------
# Read by .chezmoi.toml.tmpl on subsequent `chezmoi init --force` so is_setup
# stays true without manual intervention. Delete this file to force re-run.
SENTINEL="{{ joinPath .chezmoi.cacheDir "bootstrap-done" }}"
mkdir -p "$(dirname "$SENTINEL")"
touch "$SENTINEL"
