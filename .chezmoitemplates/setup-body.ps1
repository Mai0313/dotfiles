$ErrorActionPreference = 'Stop'

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
{{ if .is_work }}
# ---------- Corp Windows packages ----------
# googet (go/googet) is the gWindows channel for corp software and ships with
# the platform. The guard is not there because it might be missing, but because
# a missing command is a terminating error under $ErrorActionPreference =
# 'Stop', which would take the skills links below down with it. `googet install`
# needs an elevated shell, and Software Center installs the same packages
# without admin. Exit codes are not allow-listed the way winget's are above and
# nothing resets $LASTEXITCODE here, so a failed install surfaces: none of this
# has been run on a corp Windows machine yet.
if (Get-Command googet -ErrorAction SilentlyContinue) {
{{- range .packages.work_windows }}
    googet -noconfirm install {{ . }}
{{- end }}
} else {
    Write-Host 'googet not found on PATH, skipping corp package install.'
}
{{ end }}
# ---------- Node LTS via nvm ----------
# nvm-windows comes from the winget list above, which is why that block has to
# stay ahead of this one. The *nix body just sources nvm.sh at this point, but
# the Windows installer only writes NVM_HOME and PATH into the registry, so a
# machine that got nvm in this same run cannot see it until a new shell starts.
# Hence the guard: a first run installs nvm and stops here, a second one after
# reopening the shell gets node and the npm CLIs below.
#
# The version lives in .chezmoidata/node.yaml, shared with setup-body.sh, which
# is also where the reason for pinning it is written down.
if (Get-Command nvm -ErrorAction SilentlyContinue) {
    nvm install {{ .node_version }}
    nvm use {{ .node_version }}
} else {
    Write-Host 'nvm not found on PATH, skipping node install. Open a new shell and re-run.'
}

# ---------- Global npm CLIs ----------
# node/npm are on PATH now (nvm ran above). List lives in packages.yaml.
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g {{ range .packages.npm }}{{ . }} {{ end }}{{ if not .is_work }}{{ range .packages.home_npm }}{{ . }} {{ end }}{{ end }}
} else {
    Write-Host 'npm not found on PATH, skipping global npm CLI install.'
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
