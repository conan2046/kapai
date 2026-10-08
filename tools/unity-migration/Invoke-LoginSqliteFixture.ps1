[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/ui-fidelity/Login/unity/g5-20260801/login-fixed-fixture-snapshot.json",
    [string]$DatabasePath = "",
    [switch]$AllowUnityEditorForDataPreflight
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $root ".local\unity-validation\login-sqlite\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
$DatabasePath = [IO.Path]::GetFullPath($DatabasePath)
if ($DatabasePath -ine [IO.Path]::GetFullPath((Join-Path $root ".local\unity-validation\login-sqlite\LocalServer\projectx.db"))) {
    throw "Login Unity fixture only accepts the isolated project-local SQLite test database."
}
if ($UserId -ne 7200057 -or $RoleId -ne 1000003) {
    throw "Login Unity SQLite identity must remain 7200057/1000003 from the sanitized validation seed."
}
if ($AllowUnityEditorForDataPreflight -and
    $Action -notin @("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")) {
    throw "-AllowUnityEditorForDataPreflight is restricted to the Login data-preflight fixture lifecycle."
}
$runningClients = @(Get-Process kapai, ProjectX -ErrorAction SilentlyContinue)
if ($runningClients.Count -gt 0) {
    throw "Stop kapai.exe and ProjectX.exe before Login SQLite fixture $Action."
}
$unityProcesses = @(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" -ErrorAction Stop)
if ($AllowUnityEditorForDataPreflight) {
    $interactiveUnityEditors = @(Get-UnityMigrationInteractiveUnityEditors -Processes $unityProcesses)
    $editorCommands = @($interactiveUnityEditors | ForEach-Object { [string]$_.CommandLine })
    $projectPath = [IO.Path]::GetFullPath((Join-Path $root "unityclient"))
    $quotedProjectPath = '-projectPath "' + $projectPath + '"'
    $plainProjectPath = '-projectPath ' + $projectPath
    if ($interactiveUnityEditors.Count -ne 1 -or $editorCommands.Count -ne 1 -or
        ($editorCommands[0].IndexOf($quotedProjectPath, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
         $editorCommands[0].IndexOf($plainProjectPath, [StringComparison]::OrdinalIgnoreCase) -lt 0)) {
        throw "-AllowUnityEditorForDataPreflight requires the one interactive Unity Editor for this exact project."
    }
}
$normalizedDatabasePath = [IO.Path]::GetFullPath($DatabasePath)
foreach ($unityProcess in $unityProcesses) {
    $commandLine = [string]$unityProcess.CommandLine
    if ($commandLine.IndexOf($normalizedDatabasePath, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Unity Editor pid=$($unityProcess.ProcessId) is using the Login SQLite fixture database."
    }
}

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backup = Join-Path $root ".local\unity-validation\login-sqlite-fixture-backup"
$python = Join-Path $PSScriptRoot "Invoke-LoginSqliteFixture.py"
& python -X utf8 $python --action $Action --database $DatabasePath --backup $backup `
    --evidence $evidence --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "Login Unity SQLite fixture adapter failed: $Action" }
