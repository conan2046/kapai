[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [uint32]$UserId = 0,
    [uint32]$RoleId = 0,
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300,
    [switch]$PreflightOnly,
    [switch]$DataPreflightOnly
)

$ErrorActionPreference = "Stop"
if ($PreflightOnly -and $DataPreflightOnly) {
    throw "-PreflightOnly and -DataPreflightOnly are mutually exclusive."
}
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifest = (Import-UnityMigrationManifest -Root $root).Value
$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$moduleConfig = @($manifest.modules | Where-Object { $_.key -ieq $Module })
$contract = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($moduleConfig.Count -ne 1 -or $contract.Count -ne 1 -or $null -eq $contract[0].fixedAccount) {
    throw "Module '$Module' has no unique fixed-account evidence contract."
}
$moduleConfig = $moduleConfig[0]
$contract = $contract[0]
$fixed = $contract.fixedAccount
$contractFailures = @(Get-UnityMigrationFixedAccountContractFailures `
    -Root $root -Module ([string]$moduleConfig.key) -FixedAccount $fixed)
if ($contractFailures.Count -gt 0) {
    throw ($contractFailures -join [Environment]::NewLine)
}
$scenario = Get-UnityMigrationScenario -Root $root -ModuleKey ([string]$moduleConfig.key)
if ($null -eq $scenario) { throw "Module '$Module' has no validation scenario." }
if ($UserId -eq 0) { $UserId = [uint32]$fixed.userId }
if ($RoleId -eq 0) { $RoleId = [uint32]$fixed.roleId }
$pwshExecutable = Get-UnityMigrationPowerShellExecutable
$adapter = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.adapter)
$snapshot = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.snapshot)
$resultPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
$resultEvidence = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.resultEvidence)
$dataEvidencePath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-data-preflight-latest.json"
$dataPreflightFingerprint = Get-UnityMigrationDataPreflightFingerprint -Root $root -FixedAccount $fixed
$logPath = Join-Path (Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)) `
    "unity-$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account.log"
$unityExecutable = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityExecutable)
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$timingPath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-timings-latest.json"
$timings = [ordered]@{}
$overallTiming = Start-UnityMigrationTiming
$runStatus = "failed"
$fixtureCreated = $false
$validationPassed = $false
$startedMySqlIds = New-Object System.Collections.Generic.List[int]
$hadPreviousResult = -not $PreflightOnly -and -not $DataPreflightOnly -and
    (Test-Path -LiteralPath $resultPath -PathType Leaf)
$previousResultContent = if ($hadPreviousResult) {
    Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8
} else { "" }

try {
    if (-not (Test-Path -LiteralPath $adapter -PathType Leaf)) { throw "Fixed-account adapter is missing: $adapter" }
    if (-not (Test-Path -LiteralPath $unityExecutable -PathType Leaf)) { throw "Unity executable is missing: $unityExecutable" }
    if (-not (Test-Path -LiteralPath $unityProject -PathType Container)) { throw "Unity project is missing: $unityProject" }
    if (@(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue).Count -gt 0) {
        throw "Stop kapai.exe, ProjectX.exe and Unity.exe before fixed-account validation."
    }

    function Invoke-FixedAdapter([string]$Action) {
        & $pwshExecutable -NoProfile -File $adapter -Action $Action -UserId $UserId -RoleId $RoleId -EvidencePath $snapshot
        if ($LASTEXITCODE -ne 0) { throw "Fixed-account adapter action failed: $Action" }
    }

    function Stop-OrphanUnityIlppProcess {
        if (@(Get-Process Unity -ErrorAction SilentlyContinue).Count -gt 0) { return }
        $editorDirectory = Split-Path -Parent $unityExecutable
        $ilppDotnet = Join-Path $editorDirectory "Data\NetCoreRuntime\dotnet.exe"
        $orphanIlpp = @(Get-Process dotnet -ErrorAction SilentlyContinue | Where-Object {
            $_.Path -and [IO.Path]::GetFullPath($_.Path) -ieq [IO.Path]::GetFullPath($ilppDotnet)
        })
        if ($orphanIlpp.Count -eq 0) { return }
        $orphanIlpp | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        $stillRunning = @($orphanIlpp | Where-Object { Get-Process -Id $_.Id -ErrorAction SilentlyContinue })
        if ($stillRunning.Count -gt 0) {
            throw "Unity ILPP process did not release in time: pid=$($stillRunning[0].Id)"
        }
    }

    if (-not $PreflightOnly -and -not $DataPreflightOnly) {
        if (-not (Test-Path -LiteralPath $dataEvidencePath -PathType Leaf)) {
            throw "Fixed-account data preflight evidence is missing. Run with -DataPreflightOnly before full validation: $dataEvidencePath"
        }
        $dataEvidence = Get-Content -LiteralPath $dataEvidencePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $dataEvidenceFailures = @(Get-UnityMigrationDataPreflightEvidenceFailures `
            -Evidence $dataEvidence -ExpectedFingerprint $dataPreflightFingerprint `
            -ExpectedUserId $UserId -ExpectedRoleId $RoleId)
        if ($dataEvidenceFailures.Count -gt 0) {
            throw "Fixed-account data preflight evidence is stale or incomplete: $($dataEvidenceFailures -join '; '). Rerun -DataPreflightOnly before full validation."
        }
    }
    if (-not $DataPreflightOnly) {
        Stop-OrphanUnityIlppProcess
        $compileTiming = Start-UnityMigrationTiming
        try {
            Invoke-UnityMigrationCompilePreflight -Root $root -UnityProject $unityProject `
                -UnityExecutable $unityExecutable | Out-Null
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "compilePreflight" -Timing $compileTiming
        }
    }
    if ($PreflightOnly) {
        $runStatus = "preflight-passed"
        Write-Host "Fixed-account preflight passed without changing account data: module=$Module userId=$UserId roleId=$RoleId"
        return
    }

    $mysqlTiming = Start-UnityMigrationTiming
    try {
        $mysqlListenerPid = Get-UnityMigrationTcpListenerPid -Port 3306
        if ($null -ne $mysqlListenerPid) {
            $mysqlProcess = Get-Process -Id $mysqlListenerPid -ErrorAction SilentlyContinue
            if (-not $mysqlProcess -or $mysqlProcess.ProcessName -ne "mysqld" -or
                -not (Test-Path -LiteralPath (Join-Path $root ".local/mysql-local.ini") -PathType Leaf)) {
                throw "Port 3306 is not owned by the workspace-local MySQL process."
            }
        }
        else {
            $beforeMySqlIds = @(Get-Process mysqld -ErrorAction SilentlyContinue | ForEach-Object { [int]$_.Id })
            & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Start-LocalMySql.ps1")
            if ($LASTEXITCODE -ne 0) { throw "Fixed-account MySQL startup failed." }
            foreach ($process in @(Get-Process mysqld -ErrorAction SilentlyContinue)) {
                if ([int]$process.Id -notin $beforeMySqlIds) { $startedMySqlIds.Add([int]$process.Id) }
            }
            if ($null -eq (Get-UnityMigrationTcpListenerPid -Port 3306)) {
                throw "Workspace-local MySQL did not listen on 3306."
            }
        }
    }
    finally {
        Complete-UnityMigrationTiming -Timings $timings -Name "mysqlReadiness" -Timing $mysqlTiming
    }

    if ($DataPreflightOnly) {
        $dataTiming = Start-UnityMigrationTiming
        try {
            Invoke-FixedAdapter "Setup"
            $fixtureCreated = $true
            if ([bool]$fixed.dataPreflight.requiresLogin) {
                & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
                if ($LASTEXITCODE -ne 0) { throw "Fixed-account data preflight server startup failed." }
                & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") -UserId $UserId
                if ($LASTEXITCODE -ne 0) { throw "Fixed-account data preflight login failed." }
                Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            }
            Invoke-FixedAdapter "AssertSetup"
            Invoke-FixedAdapter "Restore"
            Invoke-FixedAdapter "AssertRestored"
            Invoke-FixedAdapter "Cleanup"
            Invoke-FixedAdapter "AssertCleanup"
            $fixtureCreated = $false
            $snapshotPayload = Get-Content -LiteralPath $snapshot -Raw -Encoding UTF8 | ConvertFrom-Json
            $dataEvidence = [ordered]@{
                schemaVersion = 1
                module = $Module
                userId = $UserId
                roleId = $RoleId
                requirements = @($fixed.dataPreflight.requirements)
                requiresLogin = [bool]$fixed.dataPreflight.requiresLogin
                contractFingerprint = $dataPreflightFingerprint
                snapshotHash = [string](Get-UnityMigrationPropertyValue -Object $snapshotPayload -Name "snapshotHash" -Default "")
                setupAssert = "passed"
                restoreAssert = "passed"
                cleanupAssert = "passed"
                checkedUtc = [DateTime]::UtcNow.ToString("O")
            }
            Write-UnityMigrationUtf8 -Path $dataEvidencePath -Content (($dataEvidence | ConvertTo-Json -Depth 8) + "`n")
            $runStatus = "data-preflight-passed"
            Write-Host "Fixed-account data preflight passed and restored: module=$Module requirements=$(@($fixed.dataPreflight.requirements).Count)"
            return
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "dataPreflight" -Timing $dataTiming
        }
    }

    $fixtureTiming = Start-UnityMigrationTiming
    try {
        Invoke-FixedAdapter "Setup"
        $fixtureCreated = $true
    }
    finally {
        Complete-UnityMigrationTiming -Timings $timings -Name "fixtureSetup" -Timing $fixtureTiming
    }
    try {
        $serverTiming = Start-UnityMigrationTiming
        try {
            & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
            if ($LASTEXITCODE -ne 0) { throw "Fixed-account server startup failed." }
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "serverStartup" -Timing $serverTiming
        }
        if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath -Force }
        $arguments = @(
            "-batchMode",
            "-projectPath", $unityProject,
            "-executeMethod", ([string]$manifest.executeMethod),
            "-projectXAutomation",
            "-projectXUserId=$UserId",
            "-projectXValidationScenario=$($scenario.key)",
            "-projectXRunnerTimeoutSeconds=$RunnerTimeoutSeconds",
            "-logFile", $logPath
        ) + @($scenario.flags | ForEach-Object { [string]$_ }) `
          + @($fixed.extraFlags | ForEach-Object { [string]$_ })
        $unityTiming = Start-UnityMigrationTiming
        try {
            $process = Start-Process -FilePath $unityExecutable -ArgumentList $arguments `
                -PassThru -WindowStyle Hidden
            $process.WaitForExit()
            if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
                throw "Unity fixed-account result is missing; exit=$($process.ExitCode); log=$logPath"
            }
            $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
            # Preserve the exact runner payload before the outer lifecycle restores
            # the previous result file. This is needed to diagnose control/semantic
            # coverage failures without treating an earlier result as current evidence.
            $runnerCapture = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-runner-latest.json"
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($runnerCapture)) | Out-Null
            Copy-Item -LiteralPath $resultPath -Destination $runnerCapture -Force
            if (-not [bool]$result.success -or [string]$result.status -notlike "COMPLETE:*") {
                throw "Unity fixed-account validation failed: $($result.status)"
            }
            $runnerUserId = [uint32](Get-UnityMigrationPropertyValue -Object $fixed -Name "terminalUserId" -Default $UserId)
            $runnerRoleId = [uint32](Get-UnityMigrationPropertyValue -Object $fixed -Name "terminalRoleId" -Default $RoleId)
            Assert-UnityMigrationRunnerIdentity -Result $result -ScenarioKey ([string]$scenario.key) -ExpectedUserId $runnerUserId
            if ([uint32]$result.roleId -ne $runnerRoleId) {
                throw "Unity fixed-account terminal role mismatch: expected=$runnerRoleId actual=$($result.roleId)"
            }
            $coverage = Assert-UnityMigrationRunnerCoverage -Root $root -Result $result -Scenario $scenario `
                -ControlMatrix ([string]$moduleConfig.controlMatrix)
            if (-not [bool]$fixed.skipPostValidationFixtureAssert) {
                Invoke-FixedAdapter "AssertSetup"
            }
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "unityValidation" -Timing $unityTiming
        }
        $artifactTiming = Start-UnityMigrationTiming
        try {
            foreach ($copy in @($fixed.artifactCopies)) {
                $source = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.source)
                $destination = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.destination)
                if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                    throw "Fixed-account artifact is missing: $source"
                }
                [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
                Copy-Item -LiteralPath $source -Destination $destination -Force
            }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($resultEvidence)) | Out-Null
            Copy-Item -LiteralPath $resultPath -Destination $resultEvidence -Force
            $visualResults = Assert-UnityMigrationVisualArtifacts -Root $root -Scenario $scenario
            $sourceContractFingerprint = Assert-UnityMigrationSourceContracts -Root $root -Scenario $scenario
            $summary = [ordered]@{
                schemaVersion = 1
                success = $true
                module = [string]$moduleConfig.key
                scenario = [string]$scenario.key
                validationMode = "fixed-account"
                fixture = [string]$scenario.fixture
                userId = $UserId
                roleId = $RoleId
                terminalUserId = $runnerUserId
                terminalRoleId = $runnerRoleId
                status = [string]$result.status
                screenWidth = [int]$result.screenWidth
                screenHeight = [int]$result.screenHeight
                captureStates = @($scenario.captureStates)
                screenshots = @($visualResults)
                validatedControlIds = @($coverage.validatedControlIds)
                passedSemanticAssertions = @($coverage.passedSemanticAssertions)
                failedSemanticAssertions = @($coverage.failedSemanticAssertions)
                snapshot = [string]$fixed.snapshot
                resultEvidence = [string]$fixed.resultEvidence
                resultSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resultEvidence).Hash
                sourceContractFingerprint = $sourceContractFingerprint
                g5ContractFingerprint = Get-UnityMigrationG5ContractFingerprint -Contract $contract
                dataPreflightEvidence = ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-data-preflight-latest.json"
                checkedUtc = [DateTime]::UtcNow.ToString("O")
            }
            Write-UnityMigrationUtf8 -Path (Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-latest.json") `
                -Content (($summary | ConvertTo-Json -Depth 8) + "`n")
            $validationPassed = $true
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "artifactCapture" -Timing $artifactTiming
        }
    }
    finally {
        $restoreTiming = Start-UnityMigrationTiming
        try {
            Get-Process Unity,kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if ($fixtureCreated) {
                if ($validationPassed) {
                    Invoke-FixedAdapter "Restore"
                    Invoke-FixedAdapter "AssertRestored"
                }
                else {
                    Invoke-FixedAdapter "Cleanup"
                    Invoke-FixedAdapter "AssertCleanup"
                    $fixtureCreated = $false
                }
            }
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "fixtureRestore" -Timing $restoreTiming
        }
    }

    if ([bool]$fixed.reloginRequired) {
        $reloginTiming = Start-UnityMigrationTiming
        $reloginFailure = $null
        try {
            & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
            if ($LASTEXITCODE -ne 0) { throw "Fixed-account restore-login server startup failed." }
            & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") -UserId $UserId
            if ($LASTEXITCODE -ne 0) { throw "Fixed-account restore-login failed." }
        }
        catch { $reloginFailure = $_ }
        finally {
            Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            if ($fixtureCreated) {
                Invoke-FixedAdapter "Restore"
                Invoke-FixedAdapter "AssertRestored"
                Invoke-FixedAdapter "Cleanup"
                Invoke-FixedAdapter "AssertCleanup"
                $fixtureCreated = $false
            }
            Complete-UnityMigrationTiming -Timings $timings -Name "reloginAndCleanup" -Timing $reloginTiming
        }
        if ($null -ne $reloginFailure) { throw $reloginFailure }
    }
    elseif ($fixtureCreated) {
        $cleanupTiming = Start-UnityMigrationTiming
        try {
            Invoke-FixedAdapter "Cleanup"
            Invoke-FixedAdapter "AssertCleanup"
            $fixtureCreated = $false
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "finalCleanup" -Timing $cleanupTiming
        }
    }
    $runStatus = "passed"
    Write-Host "Fixed-account validation passed and restored: module=$Module userId=$UserId roleId=$RoleId"
}
finally {
    if ($DataPreflightOnly -and $fixtureCreated) {
        Get-Process Unity,kapai,ProjectX -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        try {
            Invoke-FixedAdapter "Restore"
            Invoke-FixedAdapter "AssertRestored"
            Invoke-FixedAdapter "Cleanup"
            Invoke-FixedAdapter "AssertCleanup"
            $fixtureCreated = $false
        }
        catch {
            Write-Warning "Data preflight emergency restore failed: $($_.Exception.Message)"
        }
    }
    foreach ($mysqlId in @($startedMySqlIds)) {
        $process = Get-Process -Id $mysqlId -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "mysqld") {
            Stop-Process -Id $mysqlId -Force -ErrorAction SilentlyContinue
        }
    }
    if (-not $PreflightOnly -and -not $DataPreflightOnly) {
        if ($hadPreviousResult) {
            Write-UnityMigrationUtf8 -Path $resultPath -Content $previousResultContent
        }
        elseif (Test-Path -LiteralPath $resultPath) {
            Remove-Item -LiteralPath $resultPath -Force
        }
    }
    Complete-UnityMigrationTiming -Timings $timings -Name "overall" -Timing $overallTiming
    $timingReport = [ordered]@{
        schemaVersion = 1
        module = $Module
        mode = $(if ($PreflightOnly) { "compile-preflight" } elseif ($DataPreflightOnly) { "data-preflight" } else { "full" })
        status = $runStatus
        timings = $timings
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $timingPath -Content (($timingReport | ConvertTo-Json -Depth 8) + "`n")
}
