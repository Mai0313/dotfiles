#!/usr/bin/env bash
set -euo pipefail

# Detect container-like environments (Docker/Podman, Dev Container, Codespaces).
in_container() {
    [ -f /.dockerenv ] || [ -f /run/.containerenv ] || [ -n "${CODESPACES:-}" ] || [ -n "${REMOTE_CONTAINERS:-}" ] || [ -n "${DEVCONTAINER:-}" ]
}

# ---------- 1. OS packages ----------
{{ if eq .chezmoi.os "darwin" -}}
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew install {{ range .packages.darwin }}{{ . }} {{ end }}

{{ if .is_work -}}
# Corp-only macOS packages distributed via Mule (go/mule).
if command -v mule >/dev/null 2>&1 || [ -x /usr/local/bin/mule ]; then
    sudo mule install {{ range .packages.work_darwin }}{{ . }} {{ end }}
fi
{{- end }}

{{ else if eq .chezmoi.os "linux" -}}
sudo apt-get update
sudo apt-get install -y {{ range .packages.linux }}{{ . }} {{ end }}

{{ if .is_work -}}
# In this linux branch, is_work means a corp workstation (roam is macOS).
# The corp apt repos authenticate with the machine certificate, so these need
# no LOAS cert and run before anything that does. Some packages land in the
# delayed-install queue instead of being applied right away, so flush it after.
sudo apt-get install -y {{ range .packages.work_linux }}{{ . }} {{ end }}
sudo install-delayed-packages -u

# Corp Linux (gLinux) gets VS Code from google3, not the Microsoft apt repo.
# The installer reads the google3 depot, which needs a LOAS cert; `|| true`
# keeps a gcert failure (usual under a non-interactive apply) from killing the
# rest of setup. It installs code, bugged and vscode-google3 itself, so keep
# those out of work_linux.
if ! gcertstatus --quiet --check_remaining=1h 2>/dev/null; then
    gcert --nocorpssh --noprodssh || true
fi
/google/src/files/head/depot/google3/devtools/editors/vscode/install_vscode_for_google3.sh
{{- else -}}
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
{{- end }}

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
# Skipped in containers: the image controls the shell, chsh can hang
# non-interactively, and the change does not survive a rebuild.
ZSH_PATH="$(command -v zsh || true)"
if ! in_container && [ -n "$ZSH_PATH" ] && [ "${SHELL:-}" != "$ZSH_PATH" ]; then
    {{ if eq .chezmoi.os "darwin" -}}
    chsh -s /bin/zsh
    {{- else }}
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
    {{- end }}
fi

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

# ---------- 6. Global npm CLIs ----------
# node/npm are on PATH now (nvm loaded above). List lives in packages.yaml.
# Skipped on work macOS.
{{ if not (and .is_work (eq .chezmoi.os "darwin")) -}}
if command -v npm >/dev/null 2>&1; then
    npm install -g {{ range .packages.npm_global }}{{ . }} {{ end }}
fi
{{- end }}

# ---------- 7. uv (Python package manager) ----------
# Installs to ~/.local/bin, already on PATH in the shell configs.
# UV_NO_MODIFY_PATH keeps the installer from appending source lines to the
# chezmoi-managed ~/.zshenv / ~/.bashrc.
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
fi

# ---------- 8. Work-only: ADB systemd environment + pontisd ----------
# The pontisd package itself is installed in section 1; this only points it at
# the ADB vendor keys and restarts it.
{{ if and .is_work (eq .chezmoi.os "linux") -}}
KEYS_DIR="$HOME/adb-keys/security/adb"
if [ -d "$KEYS_DIR" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl --user set-environment ADB_VENDOR_KEYS="$KEYS_DIR" || true
    systemctl --user daemon-reload || true
    systemctl --user restart pontisd 2>/dev/null || true
fi
{{- end }}

# ---------- 9. Input method: fcitx5 (Chinese) ----------
{{ if eq .chezmoi.os "linux" -}}
if ! in_container; then
    sudo apt-get install -y {{ range .packages.im_linux }}{{ . }} {{ end }}
    sudo apt-get remove -y ibus-chewing || true
    echo "run_im fcitx5" > "$HOME/.xinputrc"
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]" || true
    fi
    if command -v gnome-extensions >/dev/null 2>&1; then
        gnome-extensions enable kimpanel@kde.org 2>/dev/null || true
    fi
fi
{{- end }}
