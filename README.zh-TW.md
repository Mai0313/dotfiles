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

`chezmoi apply` 會一條龍處理:部署 dotfiles、clone external 相依套件
(oh-my-zsh、powerlevel10k、plugins,以及 work 環境的 ADB keys),並執行
`.chezmoiscripts/` 內的 bootstrap script 安裝 OS 套件、把 zsh 設為預設
shell、bootstrap LazyVim。

上面那一行指令 (`chezmoi init --apply`) 對新機器跟 Codespaces 都適用。
已經初始化過的機器之後用 `chezmoi update` 拉取更新。

第一次 bootstrap 跑完之後,可以在 `~/.config/chezmoi/chezmoi.toml` 的
`[data]` 區塊把 `is_setup = true`,後續 apply 就會跳過自動 bootstrap。
之後如果在 `.chezmoidata/packages.yaml` 加新套件想重跑,把 flag 改回
`false` 跑一次,再改回 `true` 即可。

`~/setup.sh` 也會被部署 (僅限 Linux/macOS),作為手動執行的入口點 —
跟 chezmoi-driven 的 script 共用同一份 body,沒有 `is_setup` gate。
想單獨 bootstrap 不透過 chezmoi 時可以直接跑這支。

### Cleanup

`~/cleanup.sh` 是 ad-hoc 工具 (不會自動執行),用來清理 `.ipython`、
`.dotnet`、`.pki` 等散落的 hidden cache。要用再執行。
