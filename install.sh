#!/bin/bash
# Bootstrap script for GitHub Codespaces
# GitHub Codespaces will automatically run this script when "Automatically install dotfiles" is enabled
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/mai0313/dotfiles.git
