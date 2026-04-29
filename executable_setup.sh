#!/bin/bash

# Exit on error
set -e

IS_MAC=$([[ "$OSTYPE" == "darwin"* ]] && echo true || echo false)

echo "Updating system and installing prerequisites..."
if [ "$IS_MAC" = true ]; then
    # Install Homebrew if not present
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh vim wget git curl
else
    sudo apt-get update
    sudo apt-get install -y zsh vim wget fontconfig git curl
fi

echo "Setting up VS Code apt repository..."
if [ "$IS_MAC" = false ]; then
    if [ ! -f /usr/share/keyrings/microsoft.gpg ]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
        rm -f /tmp/microsoft.gpg
    fi
    if [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
        sudo tee /etc/apt/sources.list.d/vscode.sources > /dev/null <<VSCODE
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
VSCODE
        sudo apt-get update
    fi
fi

echo "Updating font cache (font files managed by chezmoi)..."
if [ "$IS_MAC" = false ]; then
    fc-cache -fv
fi

echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed, skipping."
fi

echo "Installing Powerlevel10k and Zsh plugins..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

echo "Installing Neovim..."
if ! command -v nvim &>/dev/null; then
    if [ "$IS_MAC" = true ]; then
        brew install neovim
    else
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt-get update
        sudo apt-get install -y neovim
    fi
else
    echo "Neovim already installed, skipping."
fi

echo "Installing Neovim dependencies (ripgrep, fd-find, lazygit)..."
if [ "$IS_MAC" = true ]; then
    brew install ripgrep fd lazygit
else
    sudo apt-get install -y ripgrep fd-find
    # lazygit needs to be installed from GitHub release
    if ! command -v lazygit &>/dev/null; then
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        mkdir -p "$HOME/.local/bin"
        install /tmp/lazygit "$HOME/.local/bin"
        rm -f /tmp/lazygit /tmp/lazygit.tar.gz
    fi
fi

echo "Setting up LazyVim..."
if [ ! -d "$HOME/.config/nvim" ]; then
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    rm -rf "$HOME/.config/nvim/.git"
else
    echo "Neovim config already exists, skipping."
fi

echo "Setting default shell to Zsh..."
if [ "$IS_MAC" = true ]; then
    # macOS defaults to zsh, but ensure it's set correctly
    chsh -s /bin/zsh
else
    sudo chsh -s $(which zsh) $(whoami)
fi

echo "================================================="
echo "Setup complete! Please log out and log back in, or run 'exec zsh' to apply."
echo "Powerlevel10k configuration wizard will start automatically on first Zsh launch."
echo "================================================="
