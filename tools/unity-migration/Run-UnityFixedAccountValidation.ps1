[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [uint32]$UserId = 0,
    [uint32]$RoleId = 0,
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300,
    [switch]$PreflightOnly,
    [switch]$DataPreflightOnly,
    [switch]$VisualOnly
)

$ErrorActionPreference = "Stop"
if (@($PreflightOnly, $DataPreflightOnly, $VisualOnly | Where-Object { $_ }).Count -gt 1) {
    throw "-PreflightOnly, -DataPreflightOnly and -VisualOnly are mutually exclusive."
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
$pythonExecutable = Get-UnityMigrationPythonExecutable
$adapter = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.adapter)
$snapshot = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.snapshot)
$resultPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
$visualValidationFlags = @(
    Get-UnityMigrationPropertyValue -Object $fixed -Name "visualValidationFlags" -Default @() |
        ForEach-Object { [string]$_ }
)
$visualOnlyArtifacts = [bool](
    Get-UnityMigrationPropertyValue -Object $fixed -Name "visualOnlyArtifacts" -Default $false
)
if ($VisualOnly -and $visualValidationFlags.Count -eq 0) {
    throw "Module '$Module' has no fixedAccount.visualValidationFlags contract."
}
$resultEvidenceContract = if ($VisualOnly) {
    [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "visualResultEvidence" -Default "")
} else {
    [string]$fixed.resultEvidence
}
if ([string]::IsNullOrWhiteSpace($resultEvidenceContract)) {
    throw "Module '$Module' has no result evidence path for the selected validation mode."
}
$resultEvidence = Resolve-UnityMigrationPath -Root $root -Path $resultEvidenceContract
$dataEvidencePath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-data-preflight-latest.json"
$dataPreflightFingerprint = Get-UnityMigrationDataPreflightFingerprint -Root $root -FixedAccount $fixed
$sourceContractFingerprint = Assert-UnityMigrationSourceContracts -Root $root -Scenario $scenario
$g5ContractFingerprint = Get-UnityMigrationG5ContractFingerprint -Contract $contract
$logPath = Join-Path (Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)) `
    "unity-$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account$(if ($VisualOnly) { '-visual' } else { '' }).log"
$unityExecutable = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityExecutable)
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$timingPath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account$(if ($VisualOnly) { '-visual' } else { '' })-timings-latest.json"
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

    if (-not $PreflightOnly -and -not $DataPreflightOnly) {
        if (-not (Test-Path -LiteralPath $dataEvidencePath -PathType Leaf)) {
            throw "Fixed-account data preflight evidence is missing. Run with -DataPreflightOnly before full validation: $dataEvidencePath"
        }
        $dataEvidence = Get-Content -LiteralPath $dataEvidencePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $dataEvidenceFailures = @(Get-UnityMigrationDataPreflightEvidenceFailures `
            -Evidence $dataEvidence -ExpectedFingerprint $dataPreflightFingerprint `
            -ExpectedUserId $UserId -ExpectedRoleId $RoleId `
            -ExpectedSourceContractFingerprint $sourceContractFingerprint `
            -ExpectedG5ContractFingerprint $g5ContractFingerprint)
        if ($dataEvidenceFailures.Count -gt 0) {
            throw "Fixed-account data preflight evidence is stale or incomplete: $($dataEvidenceFailures -join '; '). Rerun -DataPreflightOnly before full validation."
        }
    }
    if (-not $DataPreflightOnly) {
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
                & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
                    -UserId $UserId -PythonExecutable $pythonExecutable
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
                sourceContractFingerprint = $sourceContractFingerprint
                g5ContractFingerprint = $g5ContractFingerprint
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
        $validationFlags = if ($VisualOnly) {
            @($visualValidationFlags)
        } else {
            @($scenario.flags | ForEach-Object { [string]$_ })
        }
        $arguments = @(
            "-batchMode",
            "-projectPath", $unityProject,
            "-executeMethod", ([string]$manifest.executeMethod),
            "-projectXAutomation",
            "-projectXUserId=$UserId",
            "-projectXValidationScenario=$($scenario.key)",
            "-projectXRunnerTimeoutSeconds=$RunnerTimeoutSeconds",
            "-logFile", $logPath
        ) + $validationFlags `
          + @($fixed.extraFlags | ForEach-Object { [string]$_ })
        $unityTiming = Start-UnityMigrationTiming
        try {
            $processRun = Invoke-UnityMigrationProcess -Executable $unityExecutable -Arguments $arguments `
                -Module ([string]$moduleConfig.key) -Phase "fixed-account-validation" `
                -LogPath $logPath -ResultPath $resultPath `
                -ProgressPath (Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-progress.json") `
                -TimeoutSeconds ($RunnerTimeoutSeconds + 180) -NoProgressTimeoutSeconds ($RunnerTimeoutSeconds + 90)
            if ($processRun.exitCode -ne 0) {
                throw "Unity fixed-account process failed; exit=$($processRun.exitCode); log=$logPath"
            }
            $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not [bool]$result.success -or [string]$result.status -notlike "COMPLETE:*") {
                throw "Unity fixed-account validation failed: $($result.status)"
            }
            $runnerUserId = [uint32](
                Get-UnityMigrationPropertyValue -Object $fixed -Name "terminalUserId" -Default $UserId
            )
            $runnerRoleId = [uint32](
                Get-UnityMigrationPropertyValue -Object $fixed -Name "terminalRoleId" -Default $RoleId
            )
            Assert-UnityMigrationRunnerIdentity -Result $result -ScenarioKey ([string]$scenario.key) `
                -ExpectedUserId $runnerUserId
            if ([uint32]$result.roleId -ne $runnerRoleId) {
                throw "Unity fixed-account role mismatch: expected=$runnerRoleId actual=$($result.roleId)"
            }
            $coverage = if ($VisualOnly) {
                [pscustomobject]@{
                    validatedControlIds = @()
                    passedSemanticAssertions = @()
                    failedSemanticAssertions = @()
                }
            } else {
                Assert-UnityMigrationRunnerCoverage -Root $root -Result $result -Scenario $scenario `
                    -ControlMatrix ([string]$moduleConfig.controlMatrix)
            }
            if (-not [bool]$fixed.skipPostValidationFixtureAssert) {
                Invoke-FixedAdapter "AssertSetup"
            }
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "unityValidation" -Timing $unityTiming
        }
        $artifactTiming = Start-UnityMigrationTiming
        try {
            $screenshots = New-Object System.Collections.Generic.List[object]
            Add-Type -AssemblyName System.Drawing
            if (-not $VisualOnly -and $visualOnlyArtifacts) {
                $visualSummaryPath = Join-Path $root `
                    ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-visual-latest.json"
                if (-not (Test-Path -LiteralPath $visualSummaryPath -PathType Leaf)) {
                    throw "Fixed-account full validation requires a current visual-only summary: $visualSummaryPath"
                }
                $visualSummary = Get-Content -LiteralPath $visualSummaryPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if (-not [bool]$visualSummary.success -or
                    [uint32]$visualSummary.userId -ne $UserId -or
                    [uint32]$visualSummary.roleId -ne $RoleId -or
                    [string]$visualSummary.sourceContractFingerprint -ne $sourceContractFingerprint -or
                    [string]$visualSummary.g5ContractFingerprint -ne $g5ContractFingerprint) {
                    throw "Fixed-account visual-only summary does not match the current identity and source/G5 contracts."
                }
                $visualScreenshots = @($visualSummary.screenshots)
                if ($visualScreenshots.Count -ne @($fixed.artifactCopies).Count) {
                    throw "Fixed-account visual-only screenshot count does not match the artifact contract."
                }
                foreach ($visualScreenshot in $visualScreenshots) {
                    $visualPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$visualScreenshot.path)
                    if (-not (Test-Path -LiteralPath $visualPath -PathType Leaf) -or
                        (Get-FileHash -Algorithm SHA256 -LiteralPath $visualPath).Hash -ne
                            [string]$visualScreenshot.sha256) {
                        throw "Fixed-account visual-only screenshot is missing or stale: $($visualScreenshot.path)"
                    }
                    $screenshots.Add($visualScreenshot)
                }
            }
            $artifactCopies = if (-not $VisualOnly -and $visualOnlyArtifacts) {
                @()
            } else {
                @($fixed.artifactCopies)
            }
            foreach ($copy in $artifactCopies) {
                $source = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.source)
                $destination = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.destination)
                if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                    throw "Fixed-account artifact is missing: $source"
                }
                [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
                Copy-Item -LiteralPath $source -Destination $destination -Force
                $image = [System.Drawing.Image]::FromFile($destination)
                try {
                    if ($image.Width -ne 1334 -or $image.Height -ne 750) {
                        throw "Fixed-account artifact has wrong size: $($copy.destination) ($($image.Width)x$($image.Height))"
                    }
                }
                finally { $image.Dispose() }
                $item = Get-Item -LiteralPath $destination
                $screenshots.Add([pscustomobject]@{
                    path = [string]$copy.destination
                    width = 1334
                    height = 750
                    bytes = [long]$item.Length
                    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
                })
            }
            $duplicateHashes = @($screenshots | Group-Object sha256 | Where-Object Count -gt 1)
            if ($duplicateHashes.Count -gt 0) {
                throw "Fixed-account artifact capture contains duplicate screenshot content."
            }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($resultEvidence)) | Out-Null
            Copy-Item -LiteralPath $resultPath -Destination $resultEvidence -Force
            $summary = [ordered]@{
                schemaVersion = 1
                success = $true
                module = [string]$moduleConfig.key
                scenario = [string]$scenario.key
                validationMode = $(if ($VisualOnly) { "fixed-account-visual-only" } else { "fixed-account" })
                fixture = [string]$scenario.fixture
                userId = $UserId
                roleId = $RoleId
                status = [string]$result.status
                screenWidth = [int]$result.screenWidth
                screenHeight = [int]$result.screenHeight
                captureStates = $(if ($VisualOnly) {
                    @($contract.g5.pairs | ForEach-Object { [string]$_.id })
                } else {
                    @($scenario.captureStates | ForEach-Object { [string]$_ })
                })
                screenshots = @($screenshots.ToArray())
                validatedControlIds = @($coverage.validatedControlIds)
                passedSemanticAssertions = @($coverage.passedSemanticAssertions)
                failedSemanticAssertions = @($coverage.failedSemanticAssertions)
                snapshot = [string]$fixed.snapshot
                resultEvidence = $resultEvidenceContract
                resultSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resultEvidence).Hash
                sourceContractFingerprint = $sourceContractFingerprint
                g5ContractFingerprint = $g5ContractFingerprint
                dataPreflightEvidence = [IO.Path]::GetRelativePath($root, $dataEvidencePath).Replace('\', '/')
                unityProcess = $processRun
                checkedUtc = [DateTime]::UtcNow.ToString("O")
            }
            $fixedSummaryPath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account$(if ($VisualOnly) { '-visual' } else { '' })-latest.json"
            Write-UnityMigrationUtf8 -Path $fixedSummaryPath -Content (($summary | ConvertTo-Json -Depth 10) + "`n")
            if (-not $VisualOnly) {
                $standardSummaryPath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-latest.json"
                Write-UnityMigrationUtf8 -Path $standardSummaryPath -Content (($summary | ConvertTo-Json -Depth 10) + "`n")
            }
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
            & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
                -UserId $UserId -PythonExecutable $pythonExecutable
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
    Write-Host "Fixed-account $(if ($VisualOnly) { 'visual-only ' } else { '' })validation passed and restored: module=$Module userId=$UserId roleId=$RoleId"
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
        mode = $(if ($PreflightOnly) { "compile-preflight" } elseif ($DataPreflightOnly) { "data-preflight" } elseif ($VisualOnly) { "visual-only" } else { "full" })
        status = $runStatus
        timings = $timings
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $timingPath -Content (($timingReport | ConvertTo-Json -Depth 8) + "`n")
}
