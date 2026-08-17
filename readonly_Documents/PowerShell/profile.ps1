# CurrentUserAllHosts profile: applies to every host, not just ConsoleHost.

# The first three come from the dot_zshrc PATH line, the entries that exist on
# Windows too: setup drops release binaries (fastfetch) in ~/.local/bin, and Go
# and rustup use the same two paths here as on *nix. The rest are Windows-only
# tool directories. Some installers add their own user-environment entry (rustup
# does for ~/.cargo/bin), so a path may end up listed twice, which is harmless.
$env:PATH = "$HOME\.local\bin;$HOME\go\bin;$HOME\.cargo\bin;$HOME\.grok\bin;$HOME\.local\bin\adb;$HOME\AppData\Local\agy\bin;$HOME\AppData\Local\Programs\obsidian;$env:PATH"

# PSReadLine: inline history suggestions (zsh-autosuggestions equivalent) and
# prefix search on arrow keys. Not guarded by `Get-Module PSReadLine` -- the
# module loads after the profile runs, so such a check is always false here.
# -PredictionSource throws when output is redirected (e.g. `pwsh -c`).
if (-not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView
}
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Agent CLI shortcuts, mirroring the aliases in dot_zshrc.
Set-Alias cc  claude
Set-Alias cop copilot
Set-Alias cod codex
