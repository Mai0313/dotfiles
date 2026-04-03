#!/bin/bash

# --- Basic Clean ---
# 刪除不再需要的隱藏設定與暫存檔
rm -rf $HOME/.ipython $HOME/.astropy $HOME/.dbclient $HOME/.gnupg $HOME/.dotnet $HOME/.rpmdb $HOME/.w3m $HOME/.pki
rm -rf $HOME/tmp $HOME/.claude.json.backup
rm -rf $HOME/.cache

# # --- Claude ---
# # 保留 config.json 以及所有 settings 開頭的 json 檔案
# if [ -d "$HOME/.claude" ]; then
#     find "$HOME/.claude" -mindepth 1 -maxdepth 1 \
#         ! -name "config.json" \
#         ! -name "settings*.json" \
#         -exec rm -rf {} +
# fi

# --- Codex ---
# 除了 config.toml 和 auth.json，其餘全部刪除
if [ -d "$HOME/.codex" ]; then
    find "$HOME/.codex" -mindepth 1 -maxdepth 1 ! -name "config.toml" ! -name "auth.json" -exec rm -rf {} +
fi

# --- Gemini ---
if [ -d "$HOME/.gemini/.git" ]; then
    echo "正在利用 Git 清理 .gemini..."
    cd "$HOME/.gemini"
    # 確保你想要的檔案都已經在 git 追蹤名單中
    # git add .  <-- 如果你手動加過了就不用這行
    git clean -fdx
    cd - > /dev/null
fi

zsh
