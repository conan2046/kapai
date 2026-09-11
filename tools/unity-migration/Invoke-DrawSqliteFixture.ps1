[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [ValidateSet("NewHero", "DuplicateFragment")][string]$Profile = "NewHero",
    [string]$EvidencePath = ".local/unity-validation/draw-sqlite-fixture-latest.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) { $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db" }
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
if (-not $DatabasePath.EndsWith("AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Draw fixture only accepts Application.persistentDataPath/LocalServer/projectx.db."
}
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\draw-sqlite-fixture-backup.db"
$running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before Draw SQLite fixture $Action." }
& python -X utf8 (Join-Path $PSScriptRoot "Invoke-DrawSqliteFixture.py") --action $Action `
    --database $DatabasePath --backup $backup --evidence $evidence --user-id $UserId --role-id $RoleId `
    --profile $Profile
if ($LASTEXITCODE -ne 0) { throw "Draw SQLite fixture adapter failed: $Action" }
