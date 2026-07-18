[CmdletBinding()]
param(
    [string]$ManifestPath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifestEntry = Import-UnityMigrationManifest -Root $root -ManifestPath $ManifestPath
$manifest = $manifestEntry.Value
$unityExe = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityExecutable)
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$scenePath = Join-Path $unityProject "Assets\ProjectX\Scenes\Bootstrap.unity"
$logDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)

if (-not (Test-Path -LiteralPath $unityExe -PathType Leaf)) { throw "Unity executable not found: $unityExe" }
if (-not (Test-Path -LiteralPath $scenePath -PathType Leaf)) { throw "Bootstrap scene not found: $scenePath" }
if (@(Get-Process Unity -ErrorAction SilentlyContinue).Count -gt 0) {
    throw "Unity is already running; close it before the Bootstrap idempotence test."
}
[System.IO.Directory]::CreateDirectory($logDirectory) | Out-Null

$hashes = New-Object System.Collections.Generic.List[string]
for ($attempt = 1; $attempt -le 2; $attempt++) {
    $logPath = Join-Path $logDirectory ("bootstrap-idempotence-{0}.log" -f $attempt)
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
    $process = Start-Process -FilePath $unityExe -ArgumentList @(
        "-batchMode", "-quit", "-projectPath", $unityProject,
        "-executeMethod", "ProjectX.Editor.BootstrapSceneBuilder.BuildBatch",
        "-logFile", $logPath
    ) -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Unity Bootstrap attempt $attempt failed with exit code $($process.ExitCode); see $logPath" }
    $log = Get-Content -Raw -Encoding UTF8 -LiteralPath $logPath
    if ($log -notmatch 'Bootstrap scene (semantic signature unchanged; rebuild skipped|rebuilt and set as build index 0)') {
        throw "Unity Bootstrap attempt $attempt did not report a build decision; see $logPath"
    }
    if ($log -match 'error CS\d+|Exception:|Compilation failed|Aborting batchmode') {
        throw "Unity Bootstrap attempt $attempt contains a serious error; see $logPath"
    }
    $hashes.Add((Get-FileHash -Algorithm SHA256 -LiteralPath $scenePath).Hash)
}

if ($hashes[0] -ne $hashes[1]) {
    throw "Bootstrap scene is not idempotent: first=$($hashes[0]) second=$($hashes[1])"
}
Write-Host "Bootstrap scene idempotence passed: SHA256=$($hashes[0])"
