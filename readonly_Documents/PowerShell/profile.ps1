# CurrentUserAllHosts profile: applies to every host, not just ConsoleHost.

# ~/.local/bin, where setup drops binaries that come from a GitHub release
# rather than a package manager (fastfetch). Mirrors the PATH entry in
# dot_zshrc; Windows has no equivalent by default.
$env:PATH = "$HOME\.local\bin;$env:PATH"

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
