[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "AssertSuccess", "SetInsufficientCurrency", "AssertInsufficientCurrency", "SetSuccessCurrency", "CaptureMutationHash", "AssertMutationReloginHash", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/ui-fidelity/HeroRebirth/unity/g3/hero-rebirth-fixed-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
} elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) {
    $DatabasePath = Join-Path $root $DatabasePath
}
if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "HeroRebirth fixture only accepts Application.persistentDataPath/LocalServer/projectx.db."
}
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\hero-rebirth-sqlite-fixture-backup.db"
$python = Join-Path $PSScriptRoot "Invoke-HeroRebirthSqliteFixture.py"
$running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before HeroRebirth SQLite fixture $Action." }

& python -X utf8 $python --action $Action --database $DatabasePath --backup $backup `
    --evidence $evidence --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "HeroRebirth SQLite fixture adapter failed: $Action" }
