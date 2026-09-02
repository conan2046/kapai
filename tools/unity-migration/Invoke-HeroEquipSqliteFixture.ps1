[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "SetupG5Visual", "AssertG5Visual", "CaptureMutationHash", "AssertMutationReloginHash", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/ui-fidelity/HeroEquip/unity/g5-current/hero-equip-sqlite-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\hero-equip-sqlite-fixture-backup.db"
$running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before HeroEquip SQLite fixture $Action." }
$python = (Get-Command python -ErrorAction Stop).Source
& $python (Join-Path $PSScriptRoot "Invoke-HeroEquipSqliteFixture.py") `
    --action $Action --database $DatabasePath --backup $backup --evidence $evidence `
    --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "HeroEquip SQLite fixture adapter failed: $Action" }
