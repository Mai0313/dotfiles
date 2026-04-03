#!/bin/bash

# 遇到錯誤即停止執行
set -e

IS_MAC=$([[ "$OSTYPE" == "darwin"* ]] && echo true || echo false)

echo "更新系統並安裝必備套件..."
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

echo "設定 VS Code apt 套件源..."
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

echo "下載並安裝 MesloLGS NF 字體..."
if [ "$IS_MAC" = true ]; then
    FONT_DIR="$HOME/Library/Fonts"
else
    FONT_DIR="$HOME/.local/share/fonts/meslo"
fi
mkdir -p "$FONT_DIR"

wget -qO "$FONT_DIR/MesloLGS NF Regular.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf"
wget -qO "$FONT_DIR/MesloLGS NF Bold.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf"
wget -qO "$FONT_DIR/MesloLGS NF Italic.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf"
wget -qO "$FONT_DIR/MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf"

# macOS 不需要 fc-cache，放入 ~/Library/Fonts 即可自動載入
if [ "$IS_MAC" = false ]; then
    fc-cache -fv
fi

echo "安裝 Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh 已安裝，跳過此步驟。"
fi

echo "下載 Powerlevel10k 與 Zsh 擴充套件..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-z" ] && git clone --depth=1 https://github.com/agkozak/zsh-z "$ZSH_CUSTOM/plugins/zsh-z"

echo "配置 .zshrc..."
if [ "$IS_MAC" = true ]; then
    sed -i '' 's|^ZSH_THEME=.*$|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
    sed -i '' 's|^plugins=(.*)$|plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)|' "$HOME/.zshrc"
    sed -i '' 's|^# ZSH_CUSTOM=.*$|ZSH_CUSTOM=$HOME/.oh-my-zsh/custom|' "$HOME/.zshrc"
else
    sed -i 's|^ZSH_THEME=.*$|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
    sed -i 's|^plugins=(.*)$|plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)|' "$HOME/.zshrc"
    sed -i 's|^# ZSH_CUSTOM=.*$|ZSH_CUSTOM=$HOME/.oh-my-zsh/custom|' "$HOME/.zshrc"
fi

if ! grep -q "export PATH=\$HOME/bin:\$HOME/.local/bin:/usr/local/bin:\$PATH" "$HOME/.zshrc"; then
    echo 'export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH' >> "$HOME/.zshrc"
fi

echo "設定預設 Shell 為 Zsh..."
if [ "$IS_MAC" = true ]; then
    # macOS 已預設 zsh，但確保設定正確
    chsh -s /bin/zsh
else
    sudo chsh -s $(which zsh) $(whoami)
fi

echo "================================================="
echo "✅ 安裝完成！請登出並重新登入，或執行 'exec zsh' 來啟動設定。"
echo "進入 Zsh 後，Powerlevel10k 設定精靈會自動啟動。"
echo "================================================="
