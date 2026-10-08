[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("DataPreflightOnly", "Setup", "AssertSetup", "Restore", "AssertRestored", "AssertReloginHash", "Cleanup", "AssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/unity-validation/rolelevelup-sqlite-fixture-snapshot.json",
    [string]$DatabasePath = "",
    [switch]$AllowIdleUnityEditor
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
$DatabasePath = [IO.Path]::GetFullPath($DatabasePath)
if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "RoleLevelUp fixture only accepts Application.persistentDataPath/LocalServer/projectx.db."
}
if ($UserId -ne 7200057 -or $RoleId -ne 1000003) {
    throw "RoleLevelUp fixture identity must remain 7200057/1000003."
}

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\database-backups\rolelevelup-sqlite-fixture-backup.db"
$python = Join-Path $PSScriptRoot "Invoke-RoleLevelUpSqliteFixture.py"

$runningRuntime = @(Get-Process kapai, ProjectX -ErrorAction SilentlyContinue)
$runningUnity = @(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'")
$interactiveUnity = @($runningUnity | Where-Object {
    $_.CommandLine -and
        $_.CommandLine -match '(?i)(^|\s)-projectPath\s+"?E:\\neiwang_kapai\\Game\\unityclient(?:"|\s|$)' -and
        $_.CommandLine -notmatch '(?i)(^|\s)-batchmode(\s|$)'
})
$port8711 = @(Get-NetTCPConnection -State Listen -LocalPort 8711 -ErrorAction SilentlyContinue)
if ($runningRuntime.Count -gt 0 -or $port8711.Count -gt 0) {
    throw "Stop kapai.exe/ProjectX.exe and release port 8711 before RoleLevelUp fixture $Action."
}
if ($runningUnity.Count -gt 0 -and (-not $AllowIdleUnityEditor -or $interactiveUnity.Count -ne 1 -or $runningUnity.Count -ne 1)) {
    throw "RoleLevelUp fixture requires no Unity process, or -AllowIdleUnityEditor with the single interactive E-drive Editor."
}

if ($Action -eq "DataPreflightOnly" -and ($runningUnity.Count -gt 0 -and $interactiveUnity.Count -ne 1)) {
    throw "RoleLevelUp DataPreflightOnly could not identify the E-drive interactive Unity Editor."
}

$arguments = @(
    "--action", $Action,
    "--database", $DatabasePath,
    "--backup", $backup,
    "--evidence", $evidence,
    "--user-id", [string]$UserId,
    "--role-id", [string]$RoleId
)
& python -X utf8 $python @arguments
if ($LASTEXITCODE -ne 0) { throw "RoleLevelUp SQLite fixture adapter failed: $Action" }
