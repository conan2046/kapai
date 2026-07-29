[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [Parameter(Mandatory = $true)][ValidatePattern('^G[0-6]$')][string]$Gate,
    [string[]]$Evidence = @(),
    [string]$ControlMatrixPath = "",
    [switch]$Complete,
    [string]$RegistryPath = "tools/unity-migration/migration-gates.json"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$entry = Import-UnityMigrationJson -Root $root -Path $RegistryPath
$matches = @($entry.Value.modules | Where-Object { $_.module -ieq $Module })
if ($matches.Count -ne 1) { throw "Module '$Module' has no unique gate record." }
$record = $matches[0]
$gateNumber = [int]$Gate.Substring(1)
$manifest = (Import-UnityMigrationManifest -Root $root).Value
$moduleMatches = @($manifest.modules | Where-Object { $_.key -ieq $Module })
if ($moduleMatches.Count -ne 1) { throw "Module '$Module' has no unique manifest entry." }
$moduleConfig = $moduleMatches[0]

if ($gateNumber -gt 0) {
    Assert-UnityMigrationGatePrerequisite -Root $root -ModuleKey $Module -RequiredGate ("G{0}" -f ($gateNumber - 1))
}

foreach ($path in $Evidence) {
    $resolved = Resolve-UnityMigrationPath -Root $root -Path $path
    if (-not (Test-Path -LiteralPath $resolved)) { throw "Gate evidence missing: $path" }
}

$current = [string](Get-UnityMigrationPropertyValue -Object $record.gates -Name $Gate -Default "pending")
if (-not $Complete) {
    Write-Host "$Module $Gate=$current; prerequisites and $($Evidence.Count) evidence path(s) passed."
    exit 0
}
if ($Evidence.Count -eq 0) { throw "Completing $Gate requires at least one evidence path." }
if ($Gate -eq "G0") {
    $declaredMatrix = [string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "controlMatrix" -Default "")
    if (-not $declaredMatrix) { throw "Completing G0 requires a manifest controlMatrix." }
    $declaredCount = Assert-UnityMigrationControlMatrixDeclared -Root $root -ModuleKey $Module `
        -Path $declaredMatrix -RequireLifecycleFields
    Write-Host "$Module G0 control matrix schema frozen: $declaredCount controls."
}
if ($Gate -eq "G6") {
    if (-not $ControlMatrixPath) { throw "Completing G6 requires -ControlMatrixPath." }
    & pwsh -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityMigrationHardGates.ps1") `
        -Module $Module -Phase G6
    if ($LASTEXITCODE -ne 0) { throw "G6 hard-gate verification failed with exit code $LASTEXITCODE" }
    $controlCount = Assert-UnityMigrationControlMatrix -Root $root -ModuleKey $Module -Path $ControlMatrixPath
    Write-Host "$Module control matrix passed: $controlCount/$controlCount controls complete."
}
if ($current -eq "passed") {
    Write-Host "$Module $Gate is already passed; no registry change."
    exit 0
}

$record.gates.$Gate = "passed"
$evidenceProperty = $record.PSObject.Properties["gateEvidence"]
if ($null -eq $evidenceProperty) {
    $record | Add-Member -NotePropertyName gateEvidence -NotePropertyValue ([pscustomobject]@{})
}
$record.gateEvidence | Add-Member -Force -NotePropertyName $Gate -NotePropertyValue @($Evidence)
$record | Add-Member -Force -NotePropertyName updatedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
Write-UnityMigrationUtf8 -Path $entry.Path -Content (($entry.Value | ConvertTo-Json -Depth 12) + "`n")
Write-Host "$Module $Gate completed with $($Evidence.Count) evidence path(s)."
