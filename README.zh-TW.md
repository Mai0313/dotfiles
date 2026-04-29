# Dotfiles

使用 [chezmoi](https://www.chezmoi.io/) 管理。

## 快速開始

一行指令設定新機器：

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/mai0313/dotfiles.git
```

### GitHub Codespaces

1. 前往 [GitHub Settings > Codespaces](https://github.com/settings/codespaces)
2. 將 **Dotfiles repository** 設為 `mai0313/dotfiles`
3. 勾選 **Automatically install dotfiles**

新的 codespace 會自動完成設定。

## 環境偵測

config template 會自動偵測目前的環境：

| 環境 | 偵測方式 | `is_work` | `is_cloudtop` | `is_codespace` |
|---|---|---|---|---|
| Cloudtop | `*.c.googlers.com` | `true` | `true` | `false` |
| Roam (work) | `*.roam.internal` | `true` | `false` | `false` |
| GitHub Codespaces | `CODESPACES=true` | `false` | `false` | `true` |
| 個人環境 | 預設值 | `false` | `false` | `false` |

## 日常使用

```bash
chezmoi diff          # 檢查本機與 source 之間的差異
chezmoi apply         # 將 source state 套用到本機檔案
chezmoi re-add        # 將本機變更同步回 source directory
chezmoi add ~/.file   # 開始管理一個新檔案
chezmoi update        # 從 remote 拉取並套用（適用於其他機器）
```

### 新機器首次設定

`chezmoi apply` 部署完 dotfiles 後，手動執行 setup script：

```bash
~/setup.sh          # 安裝 zsh、oh-my-zsh、powerlevel10k、字型
~/setup_adb.sh      # （Work：Cloudtop + Roam）Clone ADB vendor keys
~/install_skills.sh # （僅限 Cloudtop）從 google3 安裝 Agent Skills
```
