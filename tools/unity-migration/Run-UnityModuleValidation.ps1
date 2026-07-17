[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [uint32]$UserId = 0,
    [string]$ManifestPath = "",
    [string]$UnityExecutable = "",
    [switch]$NoStartServices,
    [switch]$KeepServices,
    [switch]$SkipPythonTests,
    [switch]$SkipScreenshotCheck,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifestEntry = Import-UnityMigrationManifest -Root $root -ManifestPath $ManifestPath
$manifest = $manifestEntry.Value
$matches = @($manifest.modules | Where-Object { $_.key -ieq $Module })
if ($matches.Count -ne 1) {
    throw "Module '$Module' was not found exactly once in $($manifestEntry.Path)."
}
$moduleConfig = $matches[0]
if (@($moduleConfig.validationFlags).Count -eq 0 -and $moduleConfig.key -ne "Bag") {
    throw "Module '$($moduleConfig.key)' has no runnable validation flag yet."
}

if (-not $UnityExecutable) { $UnityExecutable = [string]$manifest.unityExecutable }
$unityExe = Resolve-UnityMigrationPath -Root $root -Path $UnityExecutable
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$resultPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
$logDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)
$moduleKey = [string]$moduleConfig.key
$logPath = Join-Path $logDirectory ("unity-{0}-validation.log" -f $moduleKey.ToLowerInvariant())
$summaryDirectory = Join-Path $root ".local\unity-validation"
$summaryPath = Join-Path $summaryDirectory ("{0}-latest.json" -f $moduleKey.ToLowerInvariant())

$effectiveUserId = $UserId
$friendPeerUserIds = @()
$friendTargetRoleId = 0
$friendPeerRoleIds = @()
if ($effectiveUserId -eq 0) {
    if ([bool]$moduleConfig.mutatesServer) {
        if (-not $DryRun) {
            $effectiveUserId = New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
        }
    }
    else {
        $effectiveUserId = 1
    }
}
if ($moduleConfig.key -ieq "Friend" -and -not $DryRun) {
    if ($UserId -ne 0) { throw "Friend validation currently requires an auto-allocated isolated user; omit -UserId." }
    $friendPeerUserIds = @(
        New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
        New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
    )
}
$userArgument = if ($DryRun -and $effectiveUserId -eq 0) { "-projectXUserId=<auto-isolated>" } else { "-projectXUserId=$effectiveUserId" }
$unityArguments = @(
    "-batchMode",
    "-projectPath", $unityProject,
    "-executeMethod", [string]$manifest.executeMethod,
    "-projectXAutomation",
    $userArgument
)
$unityArguments += @($moduleConfig.validationFlags)
$unityArguments += @("-logFile", $logPath)

Write-Host "Unity module validation"
Write-Host "Module: $moduleKey ($($moduleConfig.displayName))"
Write-Host "Mutation: $([bool]$moduleConfig.mutatesServer)"
Write-Host "UserId: $(if ($effectiveUserId -eq 0) { '<auto-isolated>' } else { $effectiveUserId })"
Write-Host "Unity: $unityExe"
Write-Host "Arguments: $($unityArguments -join ' ')"

if ($DryRun) {
    Write-Host "DryRun passed: no process, result, screenshot or user-id state was changed."
    exit 0
}
if (-not (Test-Path -LiteralPath $unityExe -PathType Leaf)) { throw "Unity executable not found: $unityExe" }
if (-not (Test-Path -LiteralPath $unityProject -PathType Container)) { throw "Unity project not found: $unityProject" }

$existingUnity = @(Get-Process Unity -ErrorAction SilentlyContinue)
if ($existingUnity.Count -gt 0) {
    $details = ($existingUnity | ForEach-Object { "pid=$($_.Id) path=$($_.Path)" }) -join "; "
    throw "Unity is already running; close it before module validation. $details"
}
$existingCocos = @(Get-Process ProjectX -ErrorAction SilentlyContinue)
if ($existingCocos.Count -gt 0) {
    throw "Cocos ProjectX.exe is running. Unity validation refuses to keep both clients resident."
}

$beforeProcesses = @(Get-UnityMigrationWorkspaceProcesses -Root $root)
$beforeIds = @($beforeProcesses | ForEach-Object { [int]$_.ProcessId })
$startedIds = New-Object System.Collections.Generic.List[int]
$runStartedUtc = [DateTime]::UtcNow
$result = $null
$failure = $null

function Assert-WorkspaceListener {
    param([int]$Port, [string]$ExpectedName)
    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $listener) { return $false }
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)" -ErrorAction SilentlyContinue
    $rootPattern = [Regex]::Escape([System.IO.Path]::GetFullPath($root))
    $processName = if ($process) { [string]$process.Name } else { "unknown" }
    if (-not $process -or $process.Name -ne $ExpectedName -or
        -not (($process.ExecutablePath -match $rootPattern) -or ($process.CommandLine -match $rootPattern))) {
        throw "Port $Port is occupied by a non-workspace process (pid=$($listener.OwningProcess), name=$processName)."
    }
    return $true
}

function Record-NewWorkspaceProcesses {
    foreach ($process in @(Get-UnityMigrationWorkspaceProcesses -Root $root)) {
        $id = [int]$process.ProcessId
        if ($id -notin $beforeIds -and -not $startedIds.Contains($id)) { $startedIds.Add($id) }
    }
}

try {
    $mysqlReady = Assert-WorkspaceListener -Port 3306 -ExpectedName "mysqld.exe"
    if (-not $mysqlReady) {
        if ($NoStartServices) { throw "MySQL is not listening on 3306 and -NoStartServices was specified." }
        & pwsh -ExecutionPolicy Bypass -File (Join-Path $root "tools/local/Start-LocalMySql.ps1")
        if ($LASTEXITCODE -ne 0) { throw "Start-LocalMySql.ps1 failed with exit code $LASTEXITCODE" }
        Record-NewWorkspaceProcesses
        if (-not (Assert-WorkspaceListener -Port 3306 -ExpectedName "mysqld.exe")) { throw "Workspace MySQL did not listen on 3306." }
    }

    $serverReady = Assert-WorkspaceListener -Port 8711 -ExpectedName "kapai.exe"
    if (-not $serverReady) {
        if ($NoStartServices) { throw "kapai.exe is not listening on 8711 and -NoStartServices was specified." }
        & pwsh -ExecutionPolicy Bypass -File (Join-Path $root "tools/local/Start-Server.ps1")
        if ($LASTEXITCODE -ne 0) { throw "Start-Server.ps1 failed with exit code $LASTEXITCODE" }
        Record-NewWorkspaceProcesses
        if (-not (Assert-WorkspaceListener -Port 8711 -ExpectedName "kapai.exe")) { throw "Workspace kapai.exe did not listen on 8711." }
    }

    if ($moduleConfig.key -ieq "Friend") {
        [System.IO.Directory]::CreateDirectory($summaryDirectory) | Out-Null
        $setupLogPath = Join-Path $summaryDirectory "friend-setup-latest.log"
        $setupLines = New-Object System.Collections.Generic.List[string]
        $targetName = "F{0:D5}" -f ($effectiveUserId % 100000)
        $targetOutput = @(& pwsh -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
            -UserId $effectiveUserId -AutoCreateRole -RoleName $targetName 2>&1)
        $targetOutput | ForEach-Object { $setupLines.Add([string]$_) }
        Write-UnityMigrationUtf8 -Path $setupLogPath -Content (($setupLines -join "`n") + "`n")
        if ($LASTEXITCODE -ne 0) { throw "Friend target role setup failed; see $setupLogPath" }
        $targetMatch = @($targetOutput | Select-String -Pattern '^created_role_id=(\d+)$' | Select-Object -Last 1)
        if ($targetMatch.Count -ne 1) { throw "Friend target role id was not reported." }
        $friendTargetRoleId = [uint32]$targetMatch[0].Matches[0].Groups[1].Value
        foreach ($peerUserId in $friendPeerUserIds) {
            $peerName = "F{0:D5}" -f ($peerUserId % 100000)
            $peerOutput = @(& pwsh -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
                -UserId $peerUserId -AutoCreateRole -RoleName $peerName -FriendApplyRoleId $friendTargetRoleId 2>&1)
            $peerOutput | ForEach-Object { $setupLines.Add([string]$_) }
            Write-UnityMigrationUtf8 -Path $setupLogPath -Content (($setupLines -join "`n") + "`n")
            if ($LASTEXITCODE -ne 0) { throw "Friend peer role setup failed for userId=$peerUserId; see $setupLogPath" }
            $peerMatch = @($peerOutput | Select-String -Pattern '^created_role_id=(\d+)$' | Select-Object -Last 1)
            if ($peerMatch.Count -ne 1) { throw "Friend peer role id was not reported for userId=$peerUserId." }
            $friendPeerRoleIds += [uint32]$peerMatch[0].Matches[0].Groups[1].Value
        }
        Write-UnityMigrationUtf8 -Path $setupLogPath -Content (($setupLines -join "`n") + "`n")
        Write-Host "Friend setup: targetRole=$friendTargetRoleId peerRoles=$($friendPeerRoleIds -join ',')"
    }

    [System.IO.Directory]::CreateDirectory($logDirectory) | Out-Null
    if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath -Force }
    foreach ($screenshot in @($moduleConfig.screenshots)) {
        $path = Resolve-UnityMigrationPath -Root $root -Path ([string]$screenshot)
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }

    $attemptStart = $null
    $maxAttempts = if ([bool]$moduleConfig.mutatesServer) { 1 } else { 2 }
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $attemptStart = [DateTime]::UtcNow
        Write-Host "== Unity attempt $attempt/$maxAttempts =="
        $process = Start-Process -FilePath $unityExe -ArgumentList $unityArguments -WindowStyle Hidden -Wait -PassThru
        if (Test-Path -LiteralPath $resultPath) {
            $item = Get-Item -LiteralPath $resultPath
            if ($item.LastWriteTimeUtc -ge $attemptStart.AddSeconds(-2)) { break }
        }
        if ($attempt -lt $maxAttempts) {
            Write-Warning "Unity exited without a fresh result, likely after script compilation; retrying once."
            continue
        }
        $retryHint = if ([bool]$moduleConfig.mutatesServer) {
            "Mutation modules are never retried automatically; rerun the command to allocate a fresh isolated user."
        } else { "No fresh result was produced." }
        throw "Unity did not produce a fresh result. Last exit code: $($process.ExitCode). $retryHint"
    }

    $result = Get-Content -Raw -Encoding UTF8 -LiteralPath $resultPath | ConvertFrom-Json
    $resultUtc = if ($result.utc -is [DateTime]) {
        ([DateTime]$result.utc).ToUniversalTime()
    }
    else {
        [DateTime]::Parse([string]$result.utc, [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind).ToUniversalTime()
    }
    if ($resultUtc -lt $attemptStart.AddSeconds(-5)) { throw "Unity result UTC is stale: $($result.utc)" }
    if (-not [bool]$result.success) { throw "Unity validation failed: $($result.status)" }
    if ([string]$result.status -notlike "COMPLETE:*") { throw "Unity result is not COMPLETE: $($result.status)" }

    $seriousPattern = 'error CS\d+|LuaException|NullReferenceException|MissingReferenceException|Assertion failed|Fatal Error|Crash!!!'
    $serious = @(Select-String -Path $logPath -Pattern $seriousPattern -CaseSensitive:$false -ErrorAction SilentlyContinue)
    if ($serious.Count -gt 0) {
        $sample = ($serious | Select-Object -First 10 | ForEach-Object { "$($_.LineNumber):$($_.Line)" }) -join "`n"
        throw "Unity log contains serious errors:`n$sample"
    }

    $screenshotResults = New-Object System.Collections.Generic.List[object]
    if (-not $SkipScreenshotCheck) {
        Add-Type -AssemblyName System.Drawing
        foreach ($screenshot in @($moduleConfig.screenshots)) {
            $path = Resolve-UnityMigrationPath -Root $root -Path ([string]$screenshot)
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Expected screenshot missing: $screenshot" }
            $item = Get-Item -LiteralPath $path
            if ($item.LastWriteTimeUtc -lt $attemptStart.AddSeconds(-2)) { throw "Screenshot is stale: $screenshot" }
            $image = [System.Drawing.Image]::FromFile($path)
            try {
                if ($image.Width -ne 1334 -or $image.Height -ne 750) {
                    throw "Screenshot has wrong size: $screenshot ($($image.Width)x$($image.Height))"
                }
                $screenshotResults.Add([pscustomobject]@{ path = [string]$screenshot; width = $image.Width; height = $image.Height })
            }
            finally { $image.Dispose() }
        }
    }

    if (-not $SkipPythonTests) {
        Push-Location $root
        try {
            & python -m unittest discover -s tools/ui_migration/tests -v
            if ($LASTEXITCODE -ne 0) { throw "UI migration Python tests failed with exit code $LASTEXITCODE" }
        }
        finally { Pop-Location }
    }

    $summary = [ordered]@{
        success = $true
        module = $moduleKey
        userId = $effectiveUserId
        mutatesServer = [bool]$moduleConfig.mutatesServer
        status = [string]$result.status
        resultUtc = $resultUtc.ToString("O")
        screenshots = $screenshotResults.ToArray()
        log = $logPath
        startedProcessIds = @($startedIds)
        friendTargetRoleId = $friendTargetRoleId
        friendPeerRoleIds = [uint32[]]$friendPeerRoleIds
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $summaryPath -Content (($summary | ConvertTo-Json -Depth 8) + "`n")
    Write-Host "Validation passed: $($result.status)"
    Write-Host "Summary: $summaryPath"
}
catch {
    $failure = $_
    $summary = [ordered]@{
        success = $false
        module = $moduleKey
        userId = $effectiveUserId
        error = $_.Exception.Message
        startedProcessIds = @($startedIds)
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $summaryPath -Content (($summary | ConvertTo-Json -Depth 8) + "`n")
}
finally {
    Record-NewWorkspaceProcesses
    if (-not $KeepServices) {
        foreach ($id in @($startedIds | Sort-Object -Descending)) {
            $process = Get-Process -Id $id -ErrorAction SilentlyContinue
            if ($process) {
                Write-Host "Stopping process started by validation: $($process.ProcessName) pid=$id"
                Stop-Process -Id $id -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($failure) { throw $failure }
exit 0
