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

# Distro nvim is often too old (or absent) for LazyVim, and the neovim PPA is
# Ubuntu-only (breaks on Debian/glinux). Install the official release tarball to
# /opt so it matches the nvim PATH entry in dot_zshrc/dot_bashrc.
case "$(uname -m)" in
    x86_64)  NVIM_ARCH=x86_64 ;;
    aarch64) NVIM_ARCH=arm64 ;;
    *) echo "Unsupported arch for neovim: $(uname -m), skipping"; NVIM_ARCH= ;;
esac
if [ -n "$NVIM_ARCH" ] && ! command -v nvim >/dev/null 2>&1 && [ ! -x "/opt/nvim-linux-${NVIM_ARCH}/bin/nvim" ]; then
    curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
    sudo rm -rf "/opt/nvim-linux-${NVIM_ARCH}"
    sudo tar -C /opt -xzf /tmp/nvim.tar.gz
    rm -f /tmp/nvim.tar.gz
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

# ---------- 5. Node version manager (nvm) + default LTS ----------
# Shell configs already source ~/.nvm; install it here if missing.
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    NVM_VERSION=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    # PROFILE=/dev/null tells nvm's installer NOT to touch chezmoi-managed
    # ~/.zshrc / ~/.bashrc (otherwise it appends source lines and causes drift).
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | PROFILE=/dev/null bash
fi
# Load nvm into this non-interactive shell, then ensure latest LTS is default.
set +u
\. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
set -u

# ---------- 6. Work-only: ADB systemd environment + pontisd ----------
{{ if and .is_work (eq .chezmoi.os "linux") -}}
KEYS_DIR="$HOME/adb-keys/security/adb"
if [ -d "$KEYS_DIR" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl --user set-environment ADB_VENDOR_KEYS="$KEYS_DIR" || true
    systemctl --user daemon-reload || true
    systemctl --user restart pontisd 2>/dev/null || true
fi
{{- end }}

# ---------- 7. Input method: IBus (Chinese) ----------
{{ if eq .chezmoi.os "linux" -}}
sudo apt-get update
sudo apt-get install -y ibus ibus-gtk ibus-gtk3 ibus-chewing pinyin-database
echo "run_im ibus" > "$HOME/.xinputrc"
{{- end }}

# ---------- 8. Mark bootstrap as complete ----------
# Read by .chezmoi.toml.tmpl on subsequent `chezmoi init --force` so is_setup
# stays true without manual intervention. Delete this file to force re-run.
SENTINEL="{{ joinPath .chezmoi.cacheDir "bootstrap-done" }}"
mkdir -p "$(dirname "$SENTINEL")"
touch "$SENTINEL"
