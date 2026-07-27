[CmdletBinding()]
param(
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300
)

& pwsh -NoProfile -File (Join-Path $PSScriptRoot "Run-UnityFixedAccountValidation.ps1") `
    -Module Task -UserId $UserId -RoleId $RoleId -RunnerTimeoutSeconds $RunnerTimeoutSeconds
exit $LASTEXITCODE
