#region vscode python
#version: 0.1.1

if (-not $env:VSCODE_PYTHON_AUTOACTIVATE_GUARD) {

    $env:VSCODE_PYTHON_AUTOACTIVATE_GUARD = '1'

    if (($env:TERM_PROGRAM -eq 'vscode') -and ($null -ne $env:VSCODE_PYTHON_PWSH_ACTIVATE)) {

        try {

            Invoke-Expression $env:VSCODE_PYTHON_PWSH_ACTIVATE

        } catch {

            $psVersion = $PSVersionTable.PSVersion.Major

            Write-Error "Failed to activate Python environment (PowerShell $psVersion): $_" -ErrorAction Continue

        }

    }

}
#endregion vscode python
