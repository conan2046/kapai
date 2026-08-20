[CmdletBinding()]
param(
    [string]$ManifestPath = "",
    [ValidateRange(120, 1800)][int]$UnityTimeoutSeconds = 600,
    [ValidateRange(10, 120)][int]$HeartbeatSeconds = 30
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifestEntry = Import-UnityMigrationManifest -Root $root -ManifestPath $ManifestPath
$manifest = $manifestEntry.Value
$unityExe = Resolve-UnityMigrationUnityExecutable -Root $root -Manifest $manifest
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$scenePath = Join-Path $unityProject "Assets\ProjectX\Scenes\Bootstrap.unity"
$logDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)
$summaryPath = Join-Path $root ".local\unity-validation\bootstrap-idempotence-latest.json"
$progressPath = Join-Path $root ".local\unity-validation\bootstrap-idempotence-progress.json"

if (-not (Test-Path -LiteralPath $unityExe -PathType Leaf)) { throw "Unity executable not found: $unityExe" }
if (-not (Test-Path -LiteralPath $scenePath -PathType Leaf)) { throw "Bootstrap scene not found: $scenePath" }
$unityProjectPatterns = @(
    [regex]::Escape($unityProject),
    [regex]::Escape(($unityProject -replace '\\', '/'))
)
$existingProjectUnity = @(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object {
    $commandLine = [string]$_.CommandLine
    @($unityProjectPatterns | Where-Object { $commandLine -match $_ }).Count -gt 0
})
if ($existingProjectUnity.Count -gt 0) {
    $details = ($existingProjectUnity | ForEach-Object { "PID=$($_.ProcessId) $($_.CommandLine)" }) -join '; '
    throw "Unity is already running for project '$unityProject'; close it before the Bootstrap idempotence test. $details"
}
[System.IO.Directory]::CreateDirectory($logDirectory) | Out-Null

$hashes = New-Object System.Collections.Generic.List[string]
$decisions = New-Object System.Collections.Generic.List[string]
for ($attempt = 1; $attempt -le 2; $attempt++) {
    $logPath = Join-Path $logDirectory ("bootstrap-idempotence-{0}.log" -f $attempt)
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
    $process = Start-Process -FilePath $unityExe -ArgumentList @(
        "-batchMode", "-quit", "-projectPath", $unityProject,
        "-executeMethod", "ProjectX.Editor.BootstrapSceneBuilder.BuildBatch",
        "-logFile", $logPath
    ) -WindowStyle Hidden -PassThru
    $startedUtc = [DateTime]::UtcNow
    $nextHeartbeatUtc = $startedUtc.AddSeconds($HeartbeatSeconds)
    Write-UnityMigrationProgress -Path $progressPath -Module "Bootstrap" -Phase "attempt-$attempt-running" `
        -ProcessId ([int]$process.Id) -Detail "method=BootstrapSceneBuilder.BuildBatch"
    while (-not $process.HasExited) {
        Start-Sleep -Seconds 1
        $process.Refresh()
        $nowUtc = [DateTime]::UtcNow
        if ($nowUtc -ge $nextHeartbeatUtc) {
            $logBytes = if (Test-Path -LiteralPath $logPath) { (Get-Item -LiteralPath $logPath).Length } else { 0 }
            $detail = "attempt=$attempt/2; elapsed=$([int]($nowUtc - $startedUtc).TotalSeconds)s; logBytes=$logBytes"
            Write-Host "Bootstrap heartbeat: $detail"
            Write-UnityMigrationProgress -Path $progressPath -Module "Bootstrap" -Phase "attempt-$attempt-running" `
                -ProcessId ([int]$process.Id) -Detail $detail
            $nextHeartbeatUtc = $nowUtc.AddSeconds($HeartbeatSeconds)
        }
        if (($nowUtc - $startedUtc).TotalSeconds -ge $UnityTimeoutSeconds) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            throw "Unity Bootstrap attempt $attempt exceeded $UnityTimeoutSeconds seconds; see $logPath"
        }
    }
    if ($process.ExitCode -ne 0) { throw "Unity Bootstrap attempt $attempt failed with exit code $($process.ExitCode); see $logPath" }
    $log = Get-Content -Raw -Encoding UTF8 -LiteralPath $logPath
    $decisionMatch = [regex]::Match($log, 'Bootstrap scene (semantic signature unchanged; rebuild skipped|rebuilt and set as build index 0)')
    if (-not $decisionMatch.Success) {
        throw "Unity Bootstrap attempt $attempt did not report a build decision; see $logPath"
    }
    if ($log -match 'error CS\d+|Exception:|Compilation failed|Aborting batchmode') {
        throw "Unity Bootstrap attempt $attempt contains a serious error; see $logPath"
    }
    $decisions.Add($decisionMatch.Groups[1].Value)
    $hashes.Add((Get-FileHash -Algorithm SHA256 -LiteralPath $scenePath).Hash)
}

if ($hashes[0] -ne $hashes[1]) {
    throw "Bootstrap scene is not idempotent: first=$($hashes[0]) second=$($hashes[1])"
}
$summary = [ordered]@{
    success = $true
    method = "ProjectX.Editor.BootstrapSceneBuilder.BuildBatch"
    attempts = 2
    hashes = $hashes.ToArray()
    decisions = $decisions.ToArray()
    logs = @(
        "build/ui-migration/bootstrap-idempotence-1.log",
        "build/ui-migration/bootstrap-idempotence-2.log"
    )
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}
Write-UnityMigrationUtf8 -Path $summaryPath -Content (($summary | ConvertTo-Json -Depth 5) + "`n")
Write-UnityMigrationProgress -Path $progressPath -Module "Bootstrap" -Phase "passed" `
    -Detail "method=BuildBatch; sha256=$($hashes[0])"
Write-Host "Bootstrap scene idempotence passed: SHA256=$($hashes[0])"
