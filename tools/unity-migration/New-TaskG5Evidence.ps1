[CmdletBinding()]
param([string]$PythonExecutable = "python")

& pwsh -NoProfile -File (Join-Path $PSScriptRoot "New-UnityModuleG5Evidence.ps1") `
    -Module Task -PythonExecutable $PythonExecutable
exit $LASTEXITCODE
