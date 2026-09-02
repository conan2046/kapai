[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/ui-fidelity/BattleMeetMonster/fixture/battle-meet-monster-fixed-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
$DatabasePath = [IO.Path]::GetFullPath($DatabasePath)
if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "BattleMeetMonster fixture only accepts Application.persistentDataPath/LocalServer/projectx.db."
}
if ($UserId -ne 7200057 -or $RoleId -ne 1000003) {
    throw "BattleMeetMonster SQLite fixture identity must remain 7200057/1000003."
}
$running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before BattleMeetMonster SQLite fixture $Action."
}

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\battle-meet-monster-sqlite-fixture-backup.db"
& python -X utf8 (Join-Path $PSScriptRoot "Invoke-BattleMeetMonsterFixture.py") `
    --action $Action --database $DatabasePath --backup $backup --evidence $evidence `
    --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "BattleMeetMonster SQLite fixture adapter failed: $Action" }
