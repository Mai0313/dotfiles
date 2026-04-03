#!/bin/bash

# 遇到錯誤即停止執行
set -e

echo "更新系統並安裝必備套件..."
# 加上 sudo 以便一般使用者可以執行，並補上 git 與 curl 確保後續指令正常
sudo apt-get update
sudo apt-get install -y zsh vim wget fontconfig git curl

echo "下載並安裝 MesloLGS NF 字體..."
FONT_DIR="$HOME/.local/share/fonts/meslo"
mkdir -p "$FONT_DIR"

# 下載字體到指定目錄
wget -qO "$FONT_DIR/MesloLGS NF Regular.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Regular.ttf"
wget -qO "$FONT_DIR/MesloLGS NF Bold.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold.ttf"
wget -qO "$FONT_DIR/MesloLGS NF Italic.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Italic.ttf"
wget -qO "$FONT_DIR/MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/dotfiles-public/raw/master/.local/share/fonts/NerdFonts/MesloLGS%20NF%20Bold%20Italic.ttf"

# 更新字體快取
fc-cache -fv

echo "安裝 Oh My Zsh..."
# 使用 RUNZSH=no 避免安裝後自動進入 zsh 而中斷腳本
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh 已安裝，跳過此步驟。"
fi

echo "下載 Powerlevel10k 與 Zsh 擴充套件..."
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# 如果資料夾不存在才 Clone，避免重複執行腳本時報錯
[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
[ ! -d "$ZSH_CUSTOM/plugins/zsh-z" ] && git clone --depth=1 https://github.com/agkozak/zsh-z "$ZSH_CUSTOM/plugins/zsh-z"

echo "配置 .zshrc..."
# 替換主題
sed -i 's|^ZSH_THEME=.*$|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
# 替換外掛
sed -i 's|^plugins=(.*)$|plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-z)|' "$HOME/.zshrc"
# 取消註解 ZSH_CUSTOM
sed -i 's|^# ZSH_CUSTOM=.*$|ZSH_CUSTOM=$HOME/.oh-my-zsh/custom|' "$HOME/.zshrc"

# 設定 PATH (如果 .zshrc 中沒有則新增)
if ! grep -q "export PATH=\$HOME/bin:\$HOME/.local/bin:/usr/local/bin:\$PATH" "$HOME/.zshrc"; then
    echo 'export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH' >> "$HOME/.zshrc"
fi

echo "設定預設 Shell 為 Zsh..."
sudo chsh -s $(which zsh) $(whoami)

echo "================================================="
echo "✅ 安裝完成！請登出並重新登入，或執行 'exec zsh' 來啟動設定。"
echo "進入 Zsh 後，Powerlevel10k 設定精靈會自動啟動。"
echo "================================================="
