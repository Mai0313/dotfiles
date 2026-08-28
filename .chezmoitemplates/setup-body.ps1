$ErrorActionPreference = 'Stop'

# ---------- Global npm CLIs ----------
# node/npm are assumed to be installed already (nvm-windows / winget / manual).
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g {{ range .packages.npm }}{{ . }} {{ end }}{{ if not .is_work }}{{ range .packages.home_npm }}{{ . }} {{ end }}{{ end }}
} else {
    Write-Host 'npm not found on PATH, skipping global npm CLI install.'
}

# ---------- winget packages ----------
# winget ships with Windows 11 (App Installer), so unlike scoop or choco there
# is nothing to bootstrap first. IDs live in packages.yaml.
#
# winget exits non-zero for "already installed, nothing to do" as well as for
# real failures, and $ErrorActionPreference does not cover native exit codes on
# PowerShell 5.1 anyway, so each install is checked explicitly: `winget list`
# first, and only the codes that mean a genuine failure are raised.
if (Get-Command winget -ErrorAction SilentlyContinue) {
{{- range .packages.windows }}
    winget install {{ . }} --silent --disable-interactivity `
        --accept-source-agreements --accept-package-agreements
    # 0 installed, 0x8A15002B already installed, 0x8A150061 no applicable upgrade.
    if ($LASTEXITCODE -notin 0, -1978335189, -1978335135) {
        throw "winget install {{ . }} failed with $LASTEXITCODE"
    }
{{- end }}
    $global:LASTEXITCODE = 0
} else {
    Write-Host 'winget not found on PATH, skipping package install.'
}

# ---------- Agent skills links ----------
# ~/.agents is the skills external; each agent CLI looks for the same set under
# its own path, so link rather than keep copies. Junctions, not symlinks: a
# symlink needs Developer Mode or an elevated shell, a junction needs neither
# and both ends are local directories. A real directory at the target is
# somebody else's collection and is left alone.
$skillsSrc = Join-Path $HOME '.agents\skills'
$skillsLinks = @(
    Join-Path $HOME '.claude\skills'
    Join-Path $HOME '.gemini\config\skills'
)
if (Test-Path -LiteralPath $skillsSrc -PathType Container) {
    foreach ($skillsLink in $skillsLinks) {
        $existing = Get-Item -LiteralPath $skillsLink -Force -ErrorAction SilentlyContinue
        if ($existing -and -not ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            continue
        }
        # .Delete() removes the reparse point only; Remove-Item -Recurse on a
        # junction is the one that walks into the target and deletes its files.
        if ($existing) { $existing.Delete() }
        New-Item -ItemType Directory -Path (Split-Path -Parent $skillsLink) -Force | Out-Null
        New-Item -ItemType Junction -Path $skillsLink -Target $skillsSrc | Out-Null
    }
}
