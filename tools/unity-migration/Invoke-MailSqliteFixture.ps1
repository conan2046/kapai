[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/unity-validation/mail-sqlite-fixture-snapshot.json",
    [string]$DatabasePath = "",
    [switch]$AllowUnityEditorForDataPreflight
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
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
$runningClients = @(Get-Process kapai, ProjectX -ErrorAction SilentlyContinue)
if ($runningClients.Count -gt 0) {
    throw "Stop kapai.exe and ProjectX.exe before Mail SQLite fixture $Action."
}
$unityProcesses = @(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" -ErrorAction Stop)
if ($AllowUnityEditorForDataPreflight -and
    $Action -notin @("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")) {
    throw "-AllowUnityEditorForDataPreflight is restricted to the Mail data-preflight fixture lifecycle."
}
if ($AllowUnityEditorForDataPreflight) {
    $interactiveEditors = @(Get-UnityMigrationInteractiveUnityEditors -Processes $unityProcesses)
    $editorCommands = @($interactiveEditors | ForEach-Object { [string]$_.CommandLine })
    $unityProjectPath = [IO.Path]::GetFullPath((Join-Path $root "unityclient"))
    $quotedProjectPath = '-projectPath "' + $unityProjectPath + '"'
    $plainProjectPath = '-projectPath ' + $unityProjectPath
    if ($interactiveEditors.Count -ne 1 -or $editorCommands.Count -ne 1 -or
        ($editorCommands[0].IndexOf($quotedProjectPath, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
         $editorCommands[0].IndexOf($plainProjectPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) -or
        $editorCommands[0] -match '(^|\s)-batchmode(\s|$)') {
        throw "-AllowUnityEditorForDataPreflight requires the one interactive Unity Editor for this exact project."
    }
}
elseif ($unityProcesses.Count -gt 0) {
    throw "Stop Unity.exe before Mail SQLite fixture $Action."
}
$normalizedDatabasePath = [IO.Path]::GetFullPath($DatabasePath)
foreach ($unityProcess in $unityProcesses) {
    $commandLine = [string]$unityProcess.CommandLine
    if ($commandLine.IndexOf($normalizedDatabasePath, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Unity Editor pid=$($unityProcess.ProcessId) is using the Mail SQLite fixture database."
    }
}

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\database-backups\mail-sqlite-fixture-backup.bak"
& python -X utf8 (Join-Path $PSScriptRoot "Invoke-MailSqliteFixture.py") `
    --action $Action --database $DatabasePath --backup $backup --evidence $evidence `
    --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "Mail SQLite fixture adapter failed: $Action" }
