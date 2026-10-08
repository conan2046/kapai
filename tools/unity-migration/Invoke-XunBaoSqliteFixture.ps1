[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "AssertMutated", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000003,
    [string]$EvidencePath = ".local/ui-fidelity/XunBao/fixture/xunbao-sqlite-fixture-snapshot.json",
    [string]$DatabasePath = "",
    [switch]$AllowUnityEditorForDataPreflight,
    [switch]$AllowUnityEditorForSlot01Fixture
)

# Contract id: reversible-xunbao-sqlite-fixed-account

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if ($AllowUnityEditorForDataPreflight -and $AllowUnityEditorForSlot01Fixture) {
    throw "Choose only one Unity Editor fixture scope."
}
if (($AllowUnityEditorForDataPreflight -or $AllowUnityEditorForSlot01Fixture) -and
    $Action -notin @("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")) {
    throw "-AllowUnityEditorForDataPreflight is restricted to the XunBao data-preflight fixture lifecycle."
}
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
$DatabasePath = [IO.Path]::GetFullPath($DatabasePath)
$localServerPath = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"))
$slot01Path = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\Saves\Slot01\projectx.db"))
$isLocalServer = [string]::Equals($DatabasePath, $localServerPath, [StringComparison]::OrdinalIgnoreCase)
$isSlot01 = [string]::Equals($DatabasePath, $slot01Path, [StringComparison]::OrdinalIgnoreCase)
if (-not $isLocalServer -and -not $isSlot01) {
    throw "XunBao fixture accepts only the fixed LocalServer database or the explicit isolated Saves/Slot01 database."
}
if (($isLocalServer -and ($UserId -ne 7200057 -or $RoleId -ne 1000003)) -or
    ($isSlot01 -and ($UserId -ne 9100001 -or $RoleId -ne 1000001))) {
    throw "XunBao fixture identity must match the selected fixed backend (LocalServer 7200057/1000003; Slot01 9100001/1000001)."
}
if ($isLocalServer -and $AllowUnityEditorForSlot01Fixture) {
    throw "The Slot01 Editor override cannot be used for LocalServer."
}
if (-not (Test-Path -LiteralPath $DatabasePath -PathType Leaf)) {
    throw "XunBao fixture database must already exist: $DatabasePath"
}
if ($isSlot01) {
    $metadataPath = Join-Path (Split-Path -Parent $DatabasePath) "metadata.json"
    if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
        throw "Slot01 metadata is missing; refusing to modify an unverified save."
    }
    $metadata = Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$metadata.slotId -ne 1 -or [uint32]$metadata.localUserId -ne $UserId -or
        [uint32]$metadata.roleId -ne $RoleId) {
        throw "Slot01 metadata identity does not match the XunBao fixture identity."
    }
}
$runningRuntime = @(Get-Process kapai, ProjectX -ErrorAction SilentlyContinue)
$runningUnity = @(Get-Process Unity -ErrorAction SilentlyContinue)
if ($AllowUnityEditorForDataPreflight -or $AllowUnityEditorForSlot01Fixture) {
    $unityProcessMetadata = @(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'")
    $interactiveUnityEditors = @(Get-UnityMigrationInteractiveUnityEditors -Processes $unityProcessMetadata)
    $editorCommands = @($interactiveUnityEditors | ForEach-Object { [string]$_.CommandLine })
    $projectPath = [IO.Path]::GetFullPath((Join-Path $root "unityclient"))
    $quotedProjectPath = '-projectPath "' + $projectPath + '"'
    $plainProjectPath = '-projectPath ' + $projectPath
    if ($interactiveUnityEditors.Count -ne 1 -or $editorCommands.Count -ne 1 -or
        ($editorCommands[0].IndexOf($quotedProjectPath, [StringComparison]::OrdinalIgnoreCase) -lt 0 -and
         $editorCommands[0].IndexOf($plainProjectPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) -or
        $editorCommands[0] -match '(^|\s)-batchmode(\s|$)') {
        throw "-AllowUnityEditorForDataPreflight requires the one interactive Unity Editor for this exact project."
    }
}
if ($runningRuntime.Count -gt 0 -or ($runningUnity.Count -gt 0 -and
    -not ($AllowUnityEditorForDataPreflight -or $AllowUnityEditorForSlot01Fixture))) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before XunBao SQLite fixture $Action."
}

$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backupName = if ($isSlot01) { "xunbao-slot01-sqlite-fixture-current.snapshot" } else { "xunbao-sqlite-fixture-current.snapshot" }
$backup = Join-Path $root ".local\unity-validation\$backupName"
& python -X utf8 (Join-Path $PSScriptRoot "Invoke-XunBaoSqliteFixture.py") `
    --action $Action --database $DatabasePath --backup $backup --evidence $evidence `
    --user-id $UserId --role-id $RoleId
if ($LASTEXITCODE -ne 0) { throw "XunBao SQLite fixture adapter failed: $Action" }
