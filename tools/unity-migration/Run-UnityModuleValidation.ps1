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
    [ValidateSet("Full", "Preflight", "VisualReplay")][string]$ValidationMode = "Full",
    [string[]]$ExtraFlags = @(),
    [string[]]$ValidationFlagsOverride = @(),
    [string]$PythonExecutable = "",
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300,
    [ValidateRange(120, 3600)][int]$UnityTimeoutSeconds = 1800,
    [ValidateRange(60, 900)][int]$UnityNoProgressTimeoutSeconds = 300,
    [ValidateRange(10, 120)][int]$HeartbeatSeconds = 30,
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
$scenarioEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/validation-scenarios.json"
$scenario = Get-UnityMigrationScenario -Root $root -ModuleKey ([string]$moduleConfig.key)
$fixtureEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/validation-fixtures.json"
if ($null -eq $scenario) { throw "Module '$($moduleConfig.key)' has no central validation scenario." }
$workflowPolicy = Assert-UnityMigrationWorkflowPolicy -Root $root
$fixtureMatches = @($fixtureEntry.Value.profiles | Where-Object { $_.key -ieq ([string]$scenario.fixture) })
if ($fixtureMatches.Count -ne 1) { throw "Scenario '$($scenario.key)' fixture '$($scenario.fixture)' was not found exactly once." }
$fixture = $fixtureMatches[0]
$scenarioArtifacts = @($scenario.artifacts)
$immutableEvidenceRoots = @($scenarioEntry.Value.artifactPolicy.immutableRoots | ForEach-Object { [string]$_ })
$requiredGate = [string](Get-UnityMigrationPropertyValue -Object $scenario -Name "requiredGate" -Default "")
if ($requiredGate) { Assert-UnityMigrationGatePrerequisite -Root $root -ModuleKey ([string]$moduleConfig.key) -RequiredGate $requiredGate }
if ([bool]$fixture.mutatesServer -ne [bool]$moduleConfig.mutatesServer) {
    throw "Scenario '$($scenario.key)' fixture mutation mode disagrees with module manifest."
}
$validationDataProperty = $moduleConfig.PSObject.Properties["validationData"]
$moduleValidationData = if ($null -ne $validationDataProperty) { $validationDataProperty.Value } else { $null }
if (@($scenario.flags).Count -eq 0 -and $moduleConfig.key -ne "Bag") {
    throw "Module '$($moduleConfig.key)' has no runnable validation flag yet."
}

if (-not $UnityExecutable) { $UnityExecutable = [string]$manifest.unityExecutable }
$unityExe = Resolve-UnityMigrationPath -Root $root -Path $UnityExecutable
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$pwshExecutable = Get-UnityMigrationPowerShellExecutable
$pythonExe = if ($SkipPythonTests) { "" } else {
    Get-UnityMigrationPythonExecutable -ExplicitPath $PythonExecutable -Root $root
}
$resultPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
$logDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)
$moduleKey = [string]$moduleConfig.key
$logPath = Join-Path $logDirectory ("unity-{0}-validation.log" -f $moduleKey.ToLowerInvariant())
$summaryDirectory = Join-Path $root ".local\unity-validation"
$summaryPath = Join-Path $summaryDirectory ("{0}-latest.json" -f $moduleKey.ToLowerInvariant())
$progressPath = Join-Path $summaryDirectory ("{0}-progress.json" -f $moduleKey.ToLowerInvariant())
$visualReplayPath = Join-Path $summaryDirectory ("{0}-visual-replay-latest.json" -f $moduleKey.ToLowerInvariant())
$timingPath = Join-Path $summaryDirectory ("{0}-timings-latest.json" -f $moduleKey.ToLowerInvariant())

$effectiveUserId = $UserId
$friendPeerUserIds = @()
$friendTargetRoleId = 0
$friendPeerRoleIds = @()
$teamPeerUserId = 0
$teamTargetRoleId = 0
$teamPeerRoleId = 0
$validationDataApplied = $false
$validationDataVariables = $null
if ($effectiveUserId -eq 0) {
    if ([bool]$moduleConfig.mutatesServer) {
        if (-not $DryRun -and $ValidationMode -eq "Full") {
            $effectiveUserId = New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
        }
    }
    else {
        $effectiveUserId = 1
    }
}
if ($moduleConfig.key -ieq "Friend" -and -not $DryRun -and $ValidationMode -eq "Full") {
    if ($UserId -ne 0) { throw "Friend validation currently requires an auto-allocated isolated user; omit -UserId." }
    $friendPeerUserIds = @(
        New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
        New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
    )
}
if ($moduleConfig.key -ieq "Team" -and -not $DryRun -and $ValidationMode -eq "Full") {
    if ($UserId -ne 0) { throw "Team validation requires auto-allocated isolated users; omit -UserId." }
    $teamPeerUserId = New-UnityMigrationUserId -Root $root -StartAt ([int]$manifest.isolatedUserIdStart)
}
$userArgument = if (($DryRun -or $ValidationMode -eq "Preflight") -and $effectiveUserId -eq 0) {
    "-projectXUserId=<auto-isolated>"
} else { "-projectXUserId=$effectiveUserId" }
$unityArguments = @(
    "-batchMode",
    "-projectPath", $unityProject,
    "-executeMethod", [string]$manifest.executeMethod,
    "-projectXAutomation",
    $userArgument
)
$unityArguments += $(if (@($ValidationFlagsOverride).Count -gt 0) { @($ValidationFlagsOverride) } else { @($scenario.flags) })
$unityArguments += "-projectXValidationScenario=$($scenario.key)"
$unityArguments += "-projectXRunnerTimeoutSeconds=$RunnerTimeoutSeconds"
$unityArguments += @($ExtraFlags)
if ($null -ne $moduleValidationData) {
    $unityArguments += @($moduleValidationData.unityFlags)
}
$unityArguments += @("-logFile", $logPath)

Write-Host "Unity module validation"
Write-Host "Module: $moduleKey ($($moduleConfig.displayName))"
Write-Host "Scenario: $($scenario.key)"
Write-Host "Fixture: $($fixture.key) (cleanup=$($fixture.cleanup))"
Write-Host "Mutation: $([bool]$moduleConfig.mutatesServer)"
Write-Host "UserId: $(if ($effectiveUserId -eq 0) { '<auto-isolated>' } else { $effectiveUserId })"
Write-Host "Unity: $unityExe"
Write-Host "PowerShell: $pwshExecutable"
if ($pythonExe) { Write-Host "Python: $pythonExe" }
Write-Host "Arguments: $($unityArguments -join ' ')"
if (-not (Test-Path -LiteralPath $unityExe -PathType Leaf)) { throw "Unity executable not found: $unityExe" }
if (-not (Test-Path -LiteralPath $unityProject -PathType Container)) { throw "Unity project not found: $unityProject" }
& $pwshExecutable -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityMigrationHardGates.ps1") `
    -Module $moduleKey -Phase Preflight -ManifestPath $manifestEntry.Path
if ($LASTEXITCODE -ne 0) { throw "Unity migration hard-gate preflight failed with exit code $LASTEXITCODE" }
$sourceContractFingerprint = Assert-UnityMigrationSourceContracts -Root $root -Scenario $scenario
Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "preflight-passed" `
    -Detail "scenario=$($scenario.key); source=$sourceContractFingerprint; user=$(if ($effectiveUserId -eq 0) { '<auto-isolated>' } else { $effectiveUserId })"

if ($DryRun -or $ValidationMode -eq "Preflight") {
    Write-Host "$(if ($DryRun) { 'Dry-run' } else { 'Preflight' }) passed: no process, result, screenshot or user-id state was changed."
    exit 0
}
if ($ValidationMode -eq "VisualReplay") {
    $visualResults = Assert-UnityMigrationVisualArtifacts -Root $root -Scenario $scenario -ImmutableRoots $immutableEvidenceRoots
    $visualReplay = [ordered]@{
        success = $true
        mode = "visual-replay"
        limitation = "Structural replay only; it does not replace fresh G5 Cocos/Unity evidence."
        module = $moduleKey
        scenario = [string]$scenario.key
        sourceContractFingerprint = $sourceContractFingerprint
        screenshots = @($visualResults)
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $visualReplayPath -Content (($visualReplay | ConvertTo-Json -Depth 8) + "`n")
    Write-Host "Visual replay passed: $visualReplayPath"
    exit 0
}
$existingUnity = @(Get-Process Unity -ErrorAction SilentlyContinue)
$unityProjectPatterns = @(
    [regex]::Escape($unityProject),
    [regex]::Escape(($unityProject -replace '\\', '/'))
)
$existingProjectUnity = @()
try {
    $existingProjectUnity = @(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" -ErrorAction Stop | Where-Object {
        $commandLine = [string]$_.CommandLine
        @($unityProjectPatterns | Where-Object { $commandLine -match $_ }).Count -gt 0
    })
}
catch {
    if ($existingUnity.Count -gt 0) {
        throw "Unity is running, but this session cannot inspect its project command line. Close Unity before module validation."
    }
}
if ($existingProjectUnity.Count -gt 0) {
    $details = ($existingProjectUnity | ForEach-Object { "pid=$($_.ProcessId)" }) -join "; "
    throw "Unity is already running for project '$unityProject'; close it before module validation. $details"
}
$beforeUnityIds = @($existingUnity | ForEach-Object { [int]$_.Id })
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
$teamPeerProcess = $null
$timings = [ordered]@{}
$overallTiming = Start-UnityMigrationTiming
$activeTimingName = ""
$activeTiming = $null
$runStatus = "failed"

function Assert-WorkspaceListener {
    param([int]$Port, [string]$ExpectedName)
    $listenerPid = Get-UnityMigrationTcpListenerPid -Port $Port
    if ($null -eq $listenerPid) { return $false }
    $process = Get-Process -Id $listenerPid -ErrorAction SilentlyContinue
    $rootPattern = [Regex]::Escape([System.IO.Path]::GetFullPath($root))
    $processName = if ($process) { "$($process.ProcessName).exe" } else { "unknown" }
    $pathMatchesWorkspace = $process -and $process.Path -match $rootPattern
    $workspaceMySql = $ExpectedName -eq "mysqld.exe" -and
        (Test-Path -LiteralPath (Join-Path $root ".local\mysql-local.ini") -PathType Leaf)
    if (-not $process -or $processName -ne $ExpectedName -or (-not $pathMatchesWorkspace -and -not $workspaceMySql)) {
        throw "Port $Port is occupied by a non-workspace process (pid=$listenerPid, name=$processName)."
    }
    return $true
}

function Record-NewWorkspaceProcesses {
    foreach ($process in @(Get-UnityMigrationWorkspaceProcesses -Root $root)) {
        $id = [int]$process.ProcessId
        if ($id -notin $beforeIds -and -not $startedIds.Contains($id)) { $startedIds.Add($id) }
    }
}

function Stop-ValidationProcessTree {
    param([int]$ProcessId)
    foreach ($child in @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ProcessId" -ErrorAction SilentlyContinue)) {
        Stop-ValidationProcessTree -ProcessId ([int]$child.ProcessId)
    }
    Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

try {
    $activeTimingName = "compilePreflight"
    $activeTiming = Start-UnityMigrationTiming
    Invoke-UnityMigrationCompilePreflight -Root $root -UnityProject $unityProject `
        -UnityExecutable $unityExe | Out-Null
    Complete-UnityMigrationTiming -Timings $timings -Name $activeTimingName -Timing $activeTiming
    $activeTimingName = ""
    $activeTiming = $null

    $activeTimingName = "servicesAndFixtureSetup"
    $activeTiming = Start-UnityMigrationTiming
    Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "services"
    $mysqlReady = Assert-WorkspaceListener -Port 3306 -ExpectedName "mysqld.exe"
    if (-not $mysqlReady) {
        if ($NoStartServices) { throw "MySQL is not listening on 3306 and -NoStartServices was specified." }
        & $pwshExecutable -ExecutionPolicy Bypass -File (Join-Path $root "tools/local/Start-LocalMySql.ps1")
        if ($LASTEXITCODE -ne 0) { throw "Start-LocalMySql.ps1 failed with exit code $LASTEXITCODE" }
        Record-NewWorkspaceProcesses
        if (-not (Assert-WorkspaceListener -Port 3306 -ExpectedName "mysqld.exe")) { throw "Workspace MySQL did not listen on 3306." }
    }

    $serverReady = Assert-WorkspaceListener -Port 8711 -ExpectedName "kapai.exe"
    if ($null -ne $moduleValidationData) {
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $validationDataVariables = @{
            UserId = $effectiveUserId
            Now = $now
            NowMinus60 = $now - 60
            NowPlus3600 = $now + 3600
            Module = $moduleKey
        }
        if ([bool]$moduleValidationData.setupBeforeServer) {
            if ($serverReady) { throw "$moduleKey validation data requires setupBeforeServer, but kapai.exe is already listening on 8711." }
            $validationDataApplied = $true
            Invoke-UnityMigrationValidationData -Root $root -Manifest $manifest -ModuleConfig $moduleConfig `
                -Phase setupSql -Variables $validationDataVariables
            Invoke-UnityMigrationValidationData -Root $root -Manifest $manifest -ModuleConfig $moduleConfig `
                -Phase setupAssertSql -Variables $validationDataVariables
            Write-Host "$moduleKey setup: manifest validation data applied before kapai startup."
        }
    }

    if (-not $serverReady) {
        if ($NoStartServices) { throw "kapai.exe is not listening on 8711 and -NoStartServices was specified." }
        & $pwshExecutable -ExecutionPolicy Bypass -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
        if ($LASTEXITCODE -ne 0) { throw "Start-Server.ps1 failed with exit code $LASTEXITCODE" }
        Record-NewWorkspaceProcesses
        if (-not (Assert-WorkspaceListener -Port 8711 -ExpectedName "kapai.exe")) { throw "Workspace kapai.exe did not listen on 8711." }
    }

    if ($null -ne $moduleValidationData -and -not [bool]$moduleValidationData.setupBeforeServer) {
        $validationDataApplied = $true
        Invoke-UnityMigrationValidationData -Root $root -Manifest $manifest -ModuleConfig $moduleConfig `
            -Phase setupSql -Variables $validationDataVariables
        Invoke-UnityMigrationValidationData -Root $root -Manifest $manifest -ModuleConfig $moduleConfig `
            -Phase setupAssertSql -Variables $validationDataVariables
        Write-Host "$moduleKey setup: manifest validation data applied."
    }

    if ($moduleConfig.key -ieq "Friend") {
        [System.IO.Directory]::CreateDirectory($summaryDirectory) | Out-Null
        $setupLogPath = Join-Path $summaryDirectory "friend-setup-latest.log"
        $setupLines = New-Object System.Collections.Generic.List[string]
        $targetName = "F{0:D5}" -f ($effectiveUserId % 100000)
        $targetOutput = @(& $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
            -UserId $effectiveUserId -AutoCreateRole -RoleName $targetName 2>&1)
        $targetOutput | ForEach-Object { $setupLines.Add([string]$_) }
        Write-UnityMigrationUtf8 -Path $setupLogPath -Content (($setupLines -join "`n") + "`n")
        if ($LASTEXITCODE -ne 0) { throw "Friend target role setup failed; see $setupLogPath" }
        $targetMatch = @($targetOutput | Select-String -Pattern '^created_role_id=(\d+)$' | Select-Object -Last 1)
        if ($targetMatch.Count -ne 1) { throw "Friend target role id was not reported." }
        $friendTargetRoleId = [uint32]$targetMatch[0].Matches[0].Groups[1].Value
        foreach ($peerUserId in $friendPeerUserIds) {
            $peerName = "F{0:D5}" -f ($peerUserId % 100000)
            $peerOutput = @(& $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
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
    if ($moduleConfig.key -ieq "Team") {
        [System.IO.Directory]::CreateDirectory($summaryDirectory) | Out-Null
        $setupLogPath = Join-Path $summaryDirectory "team-setup-latest.log"
        $targetName = "T{0:D5}" -f ($effectiveUserId % 100000)
        $targetOutput = @(& $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
            -UserId $effectiveUserId -AutoCreateRole -RoleName $targetName 2>&1)
        Write-UnityMigrationUtf8 -Path $setupLogPath -Content (($targetOutput -join "`n") + "`n")
        if ($LASTEXITCODE -ne 0) { throw "Team target role setup failed; see $setupLogPath" }
        $targetMatch = @($targetOutput | Select-String -Pattern '^created_role_id=(\d+)$' | Select-Object -Last 1)
        if ($targetMatch.Count -ne 1) { throw "Team target role id was not reported." }
        $teamTargetRoleId = [uint32]$targetMatch[0].Matches[0].Groups[1].Value

        $peerName = "T{0:D5}" -f ($teamPeerUserId % 100000)
        $peerOutput = @(& $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
            -UserId $teamPeerUserId -AutoCreateRole -RoleName $peerName 2>&1)
        Write-UnityMigrationUtf8 -Path $setupLogPath -Content ((@($targetOutput) + @($peerOutput) -join "`n") + "`n")
        if ($LASTEXITCODE -ne 0) { throw "Team peer role setup failed; see $setupLogPath" }
        $peerMatch = @($peerOutput | Select-String -Pattern '^created_role_id=(\d+)$' | Select-Object -Last 1)
        if ($peerMatch.Count -ne 1) { throw "Team peer role id was not reported." }
        $teamPeerRoleId = [uint32]$peerMatch[0].Matches[0].Groups[1].Value
        $unityArguments += "-projectXTeamPeerRoleId=$teamPeerRoleId"

        # The setup smoke disconnects immediately after creating/selecting the role.
        # Let the local server finish removing that socket before reconnecting the
        # same role as the persistent invitation peer, otherwise its late cleanup
        # can erase the new online-role index.
        Start-Sleep -Seconds 2

        $peerLogPath = Join-Path $summaryDirectory "team-peer-latest.log"
        $peerErrorPath = Join-Path $summaryDirectory "team-peer-latest.err.log"
        foreach ($path in @($peerLogPath, $peerErrorPath)) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force } }
        $teamPeerProcess = Start-Process -FilePath $pwshExecutable -ArgumentList @(
            "-NoProfile", "-File", (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1"),
            "-UserId", $teamPeerUserId, "-RoleId", $teamPeerRoleId,
            "-TeamPeerAcceptLeaderRoleId", $teamTargetRoleId, "-TeamPeerWaitSeconds", 600
        ) -RedirectStandardOutput $peerLogPath -RedirectStandardError $peerErrorPath -WindowStyle Hidden -PassThru
        $readyDeadline = [DateTime]::UtcNow.AddSeconds(15)
        do {
            Start-Sleep -Milliseconds 200
            if ($teamPeerProcess.HasExited) { throw "Team peer exited before becoming ready; see $peerLogPath and $peerErrorPath" }
            $peerLog = if (Test-Path -LiteralPath $peerLogPath) { Get-Content -Raw -Encoding UTF8 -LiteralPath $peerLogPath } else { "" }
        } while ($peerLog -notmatch 'team_peer_waiting=' -and [DateTime]::UtcNow -lt $readyDeadline)
        if ($peerLog -notmatch 'team_peer_waiting=') { throw "Team peer did not become ready within 15 seconds; see $peerLogPath" }
        Write-Host "Team setup: targetRole=$teamTargetRoleId peerRole=$teamPeerRoleId"
    }

    [System.IO.Directory]::CreateDirectory($logDirectory) | Out-Null
    Complete-UnityMigrationTiming -Timings $timings -Name $activeTimingName -Timing $activeTiming
    $activeTimingName = ""
    $activeTiming = $null
    if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath -Force }
    foreach ($artifact in $scenarioArtifacts) {
        $path = Assert-UnityMigrationRuntimeArtifact -Root $root -Artifact $artifact -ImmutableRoots $immutableEvidenceRoots
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }

    $attemptStart = $null
    $maxAttempts = if ([bool]$moduleConfig.mutatesServer) { 1 } else { 2 }
    $activeTimingName = "unityValidation"
    $activeTiming = Start-UnityMigrationTiming
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $attemptStart = [DateTime]::UtcNow
        Write-Host "== Unity attempt $attempt/$maxAttempts =="
        $process = Start-Process -FilePath $unityExe -ArgumentList $unityArguments -WindowStyle Hidden -PassThru
        $lastProgressUtc = $attemptStart
        $lastLogLength = -1L
        $lastCpuSeconds = 0d
        $nextHeartbeatUtc = $attemptStart.AddSeconds($HeartbeatSeconds)
        Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "unity-running" `
            -ProcessId ([int]$process.Id) -Detail "attempt=$attempt/$maxAttempts"
        while (-not $process.HasExited) {
            Start-Sleep -Seconds 1
            $process.Refresh()
            $nowUtc = [DateTime]::UtcNow
            if (Test-Path -LiteralPath $logPath -PathType Leaf) {
                $logItem = Get-Item -LiteralPath $logPath
                if ($logItem.Length -ne $lastLogLength) {
                    $lastLogLength = $logItem.Length
                    $lastProgressUtc = $nowUtc
                }
            }
            try {
                $cpuSeconds = $process.TotalProcessorTime.TotalSeconds
                if ($cpuSeconds -gt $lastCpuSeconds + 0.05d) {
                    $lastCpuSeconds = $cpuSeconds
                    $lastProgressUtc = $nowUtc
                }
            }
            catch { }
            if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
                $resultItem = Get-Item -LiteralPath $resultPath
                if ($resultItem.LastWriteTimeUtc -ge $attemptStart.AddSeconds(-2)) {
                    $lastProgressUtc = $nowUtc
                }
            }
            if ($nowUtc -ge $nextHeartbeatUtc) {
                $elapsed = [int]($nowUtc - $attemptStart).TotalSeconds
                $idle = [int]($nowUtc - $lastProgressUtc).TotalSeconds
                $detail = "attempt=$attempt/$maxAttempts; elapsed=${elapsed}s; idle=${idle}s; logBytes=$lastLogLength; cpu=$([Math]::Round($lastCpuSeconds, 1))s"
                Write-Host "Unity heartbeat: $detail"
                Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "unity-running" `
                    -ProcessId ([int]$process.Id) -Detail $detail
                $nextHeartbeatUtc = $nowUtc.AddSeconds($HeartbeatSeconds)
            }
            if (($nowUtc - $attemptStart).TotalSeconds -ge $UnityTimeoutSeconds) {
                Stop-ValidationProcessTree -ProcessId ([int]$process.Id)
                throw "Unity validation exceeded hard runtime $UnityTimeoutSeconds seconds; scenario=$($scenario.key), attempt=$attempt, log=$logPath."
            }
            if (($nowUtc - $lastProgressUtc).TotalSeconds -ge $UnityNoProgressTimeoutSeconds) {
                Stop-ValidationProcessTree -ProcessId ([int]$process.Id)
                throw "Unity validation made no observable log/CPU/result progress for $UnityNoProgressTimeoutSeconds seconds; scenario=$($scenario.key), attempt=$attempt, log=$logPath."
            }
        }
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
    Complete-UnityMigrationTiming -Timings $timings -Name $activeTimingName -Timing $activeTiming
    $activeTimingName = ""
    $activeTiming = $null

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
    Assert-UnityMigrationRunnerIdentity -Result $result -ScenarioKey ([string]$scenario.key) -ExpectedUserId $effectiveUserId
    $runtimeCoverage = Assert-UnityMigrationRunnerCoverage -Root $root -Result $result -Scenario $scenario `
        -ControlMatrix ([string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "controlMatrix" -Default ""))

    $seriousPattern = 'error CS\d+|LuaException|NullReferenceException|MissingReferenceException|Assertion failed|Fatal Error|Crash!!!'
    $serious = @(Select-String -Path $logPath -Pattern $seriousPattern -CaseSensitive:$false -ErrorAction SilentlyContinue)
    if ($serious.Count -gt 0) {
        $sample = ($serious | Select-Object -First 10 | ForEach-Object { "$($_.LineNumber):$($_.Line)" }) -join "`n"
        throw "Unity log contains serious errors:`n$sample"
    }

    $screenshotResults = @()
    $activeTimingName = "screenshotValidation"
    $activeTiming = Start-UnityMigrationTiming
    if (-not $SkipScreenshotCheck) {
        $screenshotResults = @(Assert-UnityMigrationVisualArtifacts -Root $root -Scenario $scenario `
            -ImmutableRoots $immutableEvidenceRoots -FreshAfterUtc $attemptStart)
    }
    Complete-UnityMigrationTiming -Timings $timings -Name $activeTimingName -Timing $activeTiming
    $activeTimingName = ""
    $activeTiming = $null

    if (-not $SkipPythonTests) {
        $activeTimingName = "pythonTests"
        $activeTiming = Start-UnityMigrationTiming
        Push-Location $root
        try {
            & $pythonExe -m unittest discover -s tools/ui_migration/tests -v
            if ($LASTEXITCODE -ne 0) { throw "UI migration Python tests failed with exit code $LASTEXITCODE" }
        }
        finally { Pop-Location }
        Complete-UnityMigrationTiming -Timings $timings -Name $activeTimingName -Timing $activeTiming
        $activeTimingName = ""
        $activeTiming = $null
    }

    $summary = [ordered]@{
        success = $true
        executionMode = "batch"
        runner = [string]$workflowPolicy.unity.standardRunner
        workflowPolicyVersion = [int]$workflowPolicy.version
        module = $moduleKey
        scenario = [string]$scenario.key
        fixture = [string]$fixture.key
        fixtureCleanup = [string]$fixture.cleanup
        requiredGate = $requiredGate
        captureStates = @($scenario.captureStates)
        userId = $effectiveUserId
        roleId = [uint32]$result.roleId
        screenWidth = [int]$result.screenWidth
        screenHeight = [int]$result.screenHeight
        mutatesServer = [bool]$moduleConfig.mutatesServer
        status = [string]$result.status
        validatedControlIds = @($runtimeCoverage.validatedControlIds)
        passedSemanticAssertions = @($runtimeCoverage.passedSemanticAssertions)
        failedSemanticAssertions = @($runtimeCoverage.failedSemanticAssertions)
        resultUtc = $resultUtc.ToString("O")
        screenshots = @($screenshotResults)
        sourceContractFingerprint = $sourceContractFingerprint
        log = $logPath
        startedProcessIds = @($startedIds)
        friendTargetRoleId = $friendTargetRoleId
        friendPeerRoleIds = [uint32[]]$friendPeerRoleIds
        teamTargetRoleId = $teamTargetRoleId
        teamPeerRoleId = $teamPeerRoleId
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $summaryPath -Content (($summary | ConvertTo-Json -Depth 8) + "`n")
    & $pwshExecutable -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityMigrationHardGates.ps1") `
        -Module $moduleKey -Phase PostRun -ManifestPath $manifestEntry.Path -SummaryPath $summaryPath
    if ($LASTEXITCODE -ne 0) { throw "Unity migration hard-gate post-run failed with exit code $LASTEXITCODE" }
    Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "passed" `
        -Detail "user=$effectiveUserId; role=$($result.roleId); status=$($result.status)"
    Write-Host "Validation passed: $($result.status)"
    Write-Host "Summary: $summaryPath"
    $runStatus = "passed"
}
catch {
    if ($null -ne $activeTiming -and $activeTimingName) {
        Complete-UnityMigrationTiming -Timings $timings -Name $activeTimingName -Timing $activeTiming
        $activeTimingName = ""
        $activeTiming = $null
    }
    $failure = $_
    Add-UnityMigrationOperationRecord -Root $root -Module $moduleKey -Gate G4 -Category UnityBatch `
        -Tool "tools/unity-migration/Run-UnityModuleValidation.ps1" -Operation "batch-validation" `
        -Outcome Failed -ErrorMessage $_.Exception.Message -RootCause "pending-diagnosis" `
        -Evidence @($summaryPath, $logPath, $progressPath) | Out-Null
    $summary = [ordered]@{
        success = $false
        module = $moduleKey
        scenario = [string]$scenario.key
        fixture = [string]$fixture.key
        userId = $effectiveUserId
        error = $_.Exception.Message
        startedProcessIds = @($startedIds)
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $summaryPath -Content (($summary | ConvertTo-Json -Depth 8) + "`n")
    Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "failed" -Detail $_.Exception.Message
}
finally {
    $cleanupTiming = Start-UnityMigrationTiming
    foreach ($unityProcess in @(Get-Process Unity -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $beforeUnityIds })) {
        Write-Host "Stopping Unity process started by validation: pid=$($unityProcess.Id)"
        Stop-Process -Id $unityProcess.Id -ErrorAction SilentlyContinue
    }
    if ($teamPeerProcess -and -not $teamPeerProcess.HasExited) {
        Write-Host "Stopping Team peer process pid=$($teamPeerProcess.Id)"
        Stop-ValidationProcessTree -ProcessId $teamPeerProcess.Id
    }
    if ($validationDataApplied) {
        try {
            Invoke-UnityMigrationValidationData -Root $root -Manifest $manifest -ModuleConfig $moduleConfig `
                -Phase cleanupSql -Variables $validationDataVariables
            Invoke-UnityMigrationValidationData -Root $root -Manifest $manifest -ModuleConfig $moduleConfig `
                -Phase cleanupAssertSql -Variables $validationDataVariables
            Write-Host "$moduleKey cleanup: manifest validation data removed."
        }
        catch {
            Write-Warning $_.Exception.Message
            Add-UnityMigrationOperationRecord -Root $root -Module $moduleKey -Gate G4 -Category UnityBatch `
                -Tool "tools/unity-migration/Run-UnityModuleValidation.ps1" -Operation "fixture-cleanup" `
                -Outcome Failed -ErrorMessage $_.Exception.Message -RootCause "pending-diagnosis" `
                -Evidence @($setupLogPath, $summaryPath) | Out-Null
            if (-not $failure) {
                $failure = $_
                $cleanupSummary = [ordered]@{
                    success = $false
                    module = $moduleKey
                    scenario = [string]$scenario.key
                    fixture = [string]$fixture.key
                    userId = $effectiveUserId
                    error = "Fixture cleanup assertion failed: $($_.Exception.Message)"
                    startedProcessIds = @($startedIds)
                    checkedUtc = [DateTime]::UtcNow.ToString("O")
                }
                Write-UnityMigrationUtf8 -Path $summaryPath -Content (($cleanupSummary | ConvertTo-Json -Depth 8) + "`n")
                Write-UnityMigrationProgress -Path $progressPath -Module $moduleKey -Phase "failed" `
                    -Detail $cleanupSummary.error
            }
        }
    }
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
    Complete-UnityMigrationTiming -Timings $timings -Name "cleanup" -Timing $cleanupTiming
}

Complete-UnityMigrationTiming -Timings $timings -Name "overall" -Timing $overallTiming
$timingReport = [ordered]@{
    schemaVersion = 1
    module = $moduleKey
    mode = $ValidationMode
    status = $runStatus
    timings = $timings
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}
Write-UnityMigrationUtf8 -Path $timingPath -Content (($timingReport | ConvertTo-Json -Depth 8) + "`n")
if ($failure) { throw $failure }
Add-UnityMigrationOperationRecord -Root $root -Module $moduleKey -Gate G4 -Category UnityBatch `
    -Tool "tools/unity-migration/Run-UnityModuleValidation.ps1" -Operation "batch-validation" `
    -Outcome Passed -Evidence @($summaryPath, $logPath, $progressPath) | Out-Null
exit 0
