[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/unity-validation/mail-sqlite-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Mail fixture only accepts Application.persistentDataPath/LocalServer/projectx.db."
}
if ($UserId -ne 7200057 -or $RoleId -ne 1000003) {
    throw "Mail SQLite fixture identity must remain 7200057/1000003."
}
$running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before Mail SQLite fixture $Action." }

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\database-backups\mail-sqlite-fixture-backup.bak"
& python -X utf8 (Join-Path $PSScriptRoot "Invoke-MailSqliteFixture.py") `
    --action $Action --database $DatabasePath --backup $backup --evidence $evidence `
    --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "Mail SQLite fixture adapter failed: $Action" }
