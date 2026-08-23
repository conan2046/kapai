[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "CaptureMutationHash", "AssertMutationReloginHash", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 1,
    [uint32]$RoleId = 1000001,
    [string]$EvidencePath = ".local/ui-fidelity/HeroCultivation/fixture/hero-cultivation-fixed-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }

if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "HeroCultivation fixture only accepts the Unity LocalServer projectx.db path."
}

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\hero-cultivation-sqlite-fixture-backup.db"
$python = Join-Path $PSScriptRoot "Invoke-HeroCultivationSqliteFixture.py"
$running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before HeroCultivation SQLite fixture $Action." }
& python -X utf8 $python --action $Action --database $DatabasePath --backup $backup `
    --evidence $evidence --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "HeroCultivation SQLite fixture adapter failed: $Action" }
