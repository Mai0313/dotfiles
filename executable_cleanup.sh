#!/bin/bash

# --- Basic Clean ---
# Remove unnecessary hidden configs and temp files.
# Intentionally NOT touching: .gnupg (GPG keys), .cache (p10k cache regenerates slowly).
rm -rf $HOME/.ipython $HOME/.astropy $HOME/.dbclient $HOME/.dotnet $HOME/.rpmdb $HOME/.w3m $HOME/.pki
rm -rf $HOME/tmp $HOME/.claude.json.backup

# # --- Claude ---
# # Keep config.json and all settings*.json files
# if [ -d "$HOME/.claude" ]; then
#     find "$HOME/.claude" -mindepth 1 -maxdepth 1 \
#         ! -name "config.json" \
#         ! -name "settings*.json" \
#         -exec rm -rf {} +
# fi

# # --- Codex ---
# # Remove everything except config.toml and auth.json
# if [ -d "$HOME/.codex" ]; then
#     find "$HOME/.codex" -mindepth 1 -maxdepth 1 ! -name "config.toml" ! -name "auth.json" -exec rm -rf {} +
# fi

# # --- Gemini ---
# if [ -d "$HOME/.gemini/.git" ]; then
#     echo "Cleaning .gemini using Git..."
#     cd "$HOME/.gemini"
#     # Make sure the files you want to keep are tracked by git
#     # git add .  <-- skip if you've already added them manually
#     git clean -fdx
#     cd - > /dev/null
# fi
