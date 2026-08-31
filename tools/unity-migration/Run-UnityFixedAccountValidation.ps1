[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [uint32]$UserId = 0,
    [uint32]$RoleId = 0,
    [string]$PythonExecutable = "",
    [string]$ServerExecutable = "",
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300,
    [switch]$PreflightOnly,
    [switch]$DataPreflightOnly,
    [switch]$G3RuntimeOnly,
    [switch]$G5VisualOnly
)

$ErrorActionPreference = "Stop"
if (@(@($PreflightOnly, $DataPreflightOnly, $G3RuntimeOnly, $G5VisualOnly) | Where-Object { $_ }).Count -gt 1) {
    throw "-PreflightOnly, -DataPreflightOnly, -G3RuntimeOnly and -G5VisualOnly are mutually exclusive."
}
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifest = (Import-UnityMigrationManifest -Root $root).Value
$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$moduleConfig = @($manifest.modules | Where-Object { $_.key -ieq $Module })
$contract = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($moduleConfig.Count -ne 1) {
    throw "Module '$Module' was not found exactly once in the migration manifest."
}
$moduleConfig = $moduleConfig[0]
if ([bool](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "migrationExcluded" -Default $false)) {
    throw "Module '$($moduleConfig.key)' is excluded from the Steam migration scope: $([string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name 'exclusionReason' -Default 'platform policy'))."
}
if ($contract.Count -ne 1 -or $null -eq $contract[0].fixedAccount) {
    throw "Module '$Module' has no unique fixed-account evidence contract."
}
$contract = $contract[0]
$fixed = $contract.fixedAccount
$g3ValidationFlags = @((Get-UnityMigrationPropertyValue -Object $fixed -Name "g3ValidationFlags" -Default @()) |
    ForEach-Object { [string]$_ })
$extraFlags = @((Get-UnityMigrationPropertyValue -Object $fixed -Name "extraFlags" -Default @()) |
    ForEach-Object { [string]$_ })
$postValidationAdapterAction = [string](Get-UnityMigrationPropertyValue `
    -Object $fixed -Name "postValidationAdapterAction" -Default "AssertSetup")
$dataBackend = [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "dataBackend" -Default "mysql")
if ($dataBackend -notin @("mysql", "sqlite")) { throw "Unsupported fixed-account data backend: $dataBackend" }
$mutationReloginOracle = Get-UnityMigrationPropertyValue -Object $fixed -Name "mutationReloginOracle" -Default $null
$serverConfigDirectoryValue = [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "serverConfigDirectory" -Default "")
$serverStartParameters = @{ WaitSeconds = 60 }
if ($ServerExecutable) {
    $resolvedServerExecutable = [IO.Path]::GetFullPath($ServerExecutable)
    if (-not (Test-Path -LiteralPath $resolvedServerExecutable -PathType Leaf)) {
        throw "Explicit fixed-account server executable is missing: $resolvedServerExecutable"
    }
    $serverStartParameters.ExePath = $resolvedServerExecutable
}
if ($serverConfigDirectoryValue) {
    $serverStartParameters.ConfigDirectory = Resolve-UnityMigrationPath -Root $root -Path $serverConfigDirectoryValue
}
$fixedSqlitePath = ""
if ($dataBackend -eq "sqlite") {
    $sqliteRelative = [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "sqlitePath" -Default "")
    $sqliteSchemaValue = [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "sqliteSchema" -Default "")
    if (-not $sqliteRelative -or -not $sqliteSchemaValue) { throw "SQLite fixed-account contract requires sqlitePath and sqliteSchema." }
    $fixedSqlitePath = if ([IO.Path]::IsPathRooted($sqliteRelative)) { $sqliteRelative } else { Join-Path $env:USERPROFILE $sqliteRelative }
    $serverStartParameters.SqlitePath = [IO.Path]::GetFullPath($fixedSqlitePath)
    $serverStartParameters.SqliteSchemaPath = Resolve-UnityMigrationPath -Root $root -Path $sqliteSchemaValue
}
$contractFailures = @(Get-UnityMigrationFixedAccountContractFailures `
    -Root $root -Module ([string]$moduleConfig.key) -FixedAccount $fixed)
if ($contractFailures.Count -gt 0) {
    throw ($contractFailures -join [Environment]::NewLine)
}
$unhydratedLfsPointers = New-Object System.Collections.Generic.List[string]
$requiredHydratedFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
$requiredHydratedFilePaths = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$fixedAccountDefaults = Get-UnityMigrationPropertyValue -Object $contracts -Name "fixedAccountDefaults" -Default $null
$globalRequiredHydratedRoots = @(Get-UnityMigrationPropertyValue `
    -Object $fixedAccountDefaults -Name "requiredHydratedRoots" -Default @())
$moduleRequiredHydratedRoots = @(Get-UnityMigrationPropertyValue `
    -Object $fixed -Name "requiredHydratedRoots" -Default @())
$requiredHydratedRoots = @($globalRequiredHydratedRoots + $moduleRequiredHydratedRoots |
    ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
foreach ($requiredHydratedRoot in @($requiredHydratedRoots | ForEach-Object { [string]$_ })) {
    $hydratedPath = Resolve-UnityMigrationPath -Root $root -Path $requiredHydratedRoot
    if (-not (Test-Path -LiteralPath $hydratedPath)) {
        throw "Required hydrated asset root is missing: $requiredHydratedRoot"
    }
    $hydratedFiles = if (Test-Path -LiteralPath $hydratedPath -PathType Leaf) {
        @(Get-Item -LiteralPath $hydratedPath)
    } else {
        @(Get-ChildItem -LiteralPath $hydratedPath -Recurse -File |
            Where-Object { $_.Extension -in @('.png', '.jpg', '.jpeg', '.ttf', '.otf') })
    }
    foreach ($hydratedFile in $hydratedFiles) {
        if ($requiredHydratedFilePaths.Add($hydratedFile.FullName)) {
            $requiredHydratedFiles.Add($hydratedFile)
        }
    }
}
$requiredHydratedUiDocuments = @(Get-UnityMigrationPropertyValue `
    -Object $fixed -Name "requiredHydratedUiDocuments" -Default @())
function Get-FixedUiDocumentAssetPaths {
    param([object]$Node)
    $fontAssetPath = [string](Get-UnityMigrationPropertyValue -Object $Node -Name "fontAssetPath" -Default "")
    if ($fontAssetPath -and [IO.Path]::GetExtension($fontAssetPath) -in @('.ttf', '.otf')) {
        $fontAssetPath
    }
    foreach ($resource in @(Get-UnityMigrationPropertyValue -Object $Node -Name "resources" -Default @())) {
        $assetPath = [string](Get-UnityMigrationPropertyValue -Object $resource -Name "assetPath" -Default "")
        if ($assetPath -and [IO.Path]::GetExtension($assetPath) -in @('.png', '.jpg', '.jpeg', '.ttf', '.otf')) {
            $assetPath
        }
    }
    foreach ($child in @(Get-UnityMigrationPropertyValue -Object $Node -Name "children" -Default @())) {
        Get-FixedUiDocumentAssetPaths -Node $child
    }
}
foreach ($requiredHydratedUiDocument in @($requiredHydratedUiDocuments | ForEach-Object { [string]$_ })) {
    $documentPath = Resolve-UnityMigrationPath -Root $root -Path $requiredHydratedUiDocument
    if (-not (Test-Path -LiteralPath $documentPath -PathType Leaf)) {
        throw "Required hydrated UI document is missing: $requiredHydratedUiDocument"
    }
    $document = Get-Content -Raw -LiteralPath $documentPath -Encoding UTF8 | ConvertFrom-Json
    foreach ($unityAssetPath in @(Get-FixedUiDocumentAssetPaths -Node $document.root | Sort-Object -Unique)) {
        $repoAssetPath = if ($unityAssetPath.StartsWith('Assets/', [StringComparison]::OrdinalIgnoreCase)) {
            "unityclient/$unityAssetPath"
        } else {
            $unityAssetPath
        }
        $hydratedPath = Resolve-UnityMigrationPath -Root $root -Path $repoAssetPath
        if (-not (Test-Path -LiteralPath $hydratedPath -PathType Leaf)) {
            throw "Required UI document asset is missing: document=$requiredHydratedUiDocument asset=$unityAssetPath"
        }
        $hydratedFile = Get-Item -LiteralPath $hydratedPath
        if ($requiredHydratedFilePaths.Add($hydratedFile.FullName)) {
            $requiredHydratedFiles.Add($hydratedFile)
        }
    }
}
foreach ($hydratedFile in $requiredHydratedFiles) {
    if ($hydratedFile.Length -le 512 -and
        (Get-Content -LiteralPath $hydratedFile.FullName -Encoding ASCII -TotalCount 1) `
            -eq 'version https://git-lfs.github.com/spec/v1') {
        $unhydratedLfsPointers.Add($hydratedFile.FullName)
    }
}
if ($unhydratedLfsPointers.Count -gt 0) {
    throw "Required Unity assets are unresolved Git LFS pointers: count=$($unhydratedLfsPointers.Count); first=$($unhydratedLfsPointers[0])"
}
$scenario = Get-UnityMigrationScenario -Root $root -ModuleKey ([string]$moduleConfig.key)
if ($null -eq $scenario) { throw "Module '$Module' has no validation scenario." }
$scenarioRuntimeFlags = @(Get-UnityMigrationScenarioRuntimeFlags -Scenario $scenario)
$workflowPolicy = Assert-UnityMigrationWorkflowPolicy -Root $root
$requiredGate = if ($G5VisualOnly) { "G4" } elseif ($DataPreflightOnly -or $PreflightOnly -or $G3RuntimeOnly) { "G2" } else { "G3" }
$workflowPhase = if ($DataPreflightOnly) { "G0" } else { "G3" }
Assert-UnityMigrationGatePrerequisite -Root $root -ModuleKey ([string]$moduleConfig.key) -RequiredGate $requiredGate
Assert-UnityMigrationModuleWorkflowContract -Root $root -ModuleConfig $moduleConfig `
    -Scenario $scenario -Phase $workflowPhase | Out-Null
if ($UserId -eq 0) { $UserId = [uint32]$fixed.userId }
if ($RoleId -eq 0) { $RoleId = [uint32]$fixed.roleId }
$pwshExecutable = Get-UnityMigrationPowerShellExecutable
$pythonExecutable = Get-UnityMigrationPythonExecutable -ExplicitPath $PythonExecutable -Root $root
$adapter = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.adapter)
$startServerScript = Join-Path $root "tools/local/Start-Server.ps1"
$snapshotValue = if ($G5VisualOnly) {
    [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "g5VisualSnapshot" -Default "")
} else { [string]$fixed.snapshot }
if ($G5VisualOnly -and -not $snapshotValue) { throw "Fixed-account G5 visual mode requires g5VisualSnapshot." }
$snapshot = Resolve-UnityMigrationPath -Root $root -Path $snapshotValue
$resultPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
$resultEvidence = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.resultEvidence)
$dataEvidencePath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-data-preflight-latest.json"
$dataPreflightFingerprint = Get-UnityMigrationDataPreflightFingerprint -Root $root -FixedAccount $fixed
$logPath = Join-Path (Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)) `
    "unity-$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account.log"
$serverRuntimeEvidence = Get-UnityMigrationPropertyValue -Object $fixed `
    -Name "serverRuntimeEvidence" -Default $null
$unityExecutable = Resolve-UnityMigrationUnityExecutable -Root $root -Manifest $manifest
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
        $adapterArguments = @("-NoProfile", "-File", $adapter, "-Action", $Action,
            "-UserId", $UserId, "-RoleId", $RoleId, "-EvidencePath", $snapshot)
        if ($dataBackend -eq "sqlite") { $adapterArguments += @("-DatabasePath", $fixedSqlitePath) }
        & $pwshExecutable @adapterArguments
        if ($LASTEXITCODE -ne 0) { throw "Fixed-account adapter action failed: $Action" }
    }

    function Wait-FixedRuntimeRelease {
        $deadline = [DateTime]::UtcNow.AddSeconds(15)
        do {
            $runtimeProcesses = @(Get-Process Unity,kapai,ProjectX -ErrorAction SilentlyContinue)
            $databaseReleased = $true
            if ($dataBackend -eq 'sqlite' -and (Test-Path -LiteralPath $fixedSqlitePath -PathType Leaf)) {
                try {
                    $stream = [IO.File]::Open($fixedSqlitePath, [IO.FileMode]::Open,
                        [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
                    $stream.Dispose()
                }
                catch { $databaseReleased = $false }
            }
            if ($runtimeProcesses.Count -eq 0 -and $databaseReleased) { return }
            Start-Sleep -Milliseconds 250
        } while ([DateTime]::UtcNow -lt $deadline)
        throw "Fixed-account runtime did not release processes/SQLite before restore: processes=$($runtimeProcesses.Count), sqliteReleased=$databaseReleased"
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

    if (-not $PreflightOnly -and -not $DataPreflightOnly -and -not $G5VisualOnly) {
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
        if ($dataBackend -eq "mysql") {
            $mysqlListenerPid = Get-UnityMigrationTcpListenerPid -Port 3306
            if ($null -ne $mysqlListenerPid) {
                if (-not (Test-UnityMigrationWorkspaceMySqlOwnership -Root $root -ProcessId $mysqlListenerPid)) {
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
        } elseif (-not (Test-Path -LiteralPath $fixedSqlitePath -PathType Leaf)) {
            throw "Fixed-account SQLite database is missing: $fixedSqlitePath"
        }
    }
    finally {
        Complete-UnityMigrationTiming -Timings $timings -Name "mysqlReadiness" -Timing $mysqlTiming
    }

    if ($DataPreflightOnly) {
        $dataTiming = Start-UnityMigrationTiming
        try {
            if (Test-Path -LiteralPath $snapshot -PathType Leaf) {
                Remove-Item -LiteralPath $snapshot -Force
            }
            try {
                Invoke-FixedAdapter "Setup"
                $fixtureCreated = $true
            }
            catch {
                $fixtureCreated = Test-Path -LiteralPath $snapshot -PathType Leaf
                throw
            }
            if ([bool]$fixed.dataPreflight.requiresLogin) {
                & $startServerScript @serverStartParameters
                if (-not $?) { throw "Fixed-account data preflight server startup failed." }
                & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
                    -UserId $UserId -RoleId $RoleId -PythonExecutable $pythonExecutable
                if ($LASTEXITCODE -ne 0) { throw "Fixed-account data preflight login failed." }
                # kapai persists role/package data on background save threads.  Give the
                # authoritative login snapshot time to commit before the local-only hard stop;
                # otherwise AssertSetup can observe a truncated package blob.
                Start-Sleep -Seconds 5
                Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Wait-FixedRuntimeRelease
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
        $setupAction = if ($G5VisualOnly) {
            [string](Get-UnityMigrationPropertyValue -Object $fixed -Name "g5VisualSetupAction" -Default "")
        } else { "Setup" }
        if (-not $setupAction) { throw "Fixed-account G5 visual mode requires g5VisualSetupAction." }
        Invoke-FixedAdapter $setupAction
        $fixtureCreated = $true
    }
    finally {
        Complete-UnityMigrationTiming -Timings $timings -Name "fixtureSetup" -Timing $fixtureTiming
    }
    try {
        $serverTiming = Start-UnityMigrationTiming
        try {
            & $startServerScript @serverStartParameters
            if (-not $?) { throw "Fixed-account server startup failed." }
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
        ) + $(if ($G3RuntimeOnly) {
            @($g3ValidationFlags)
        } elseif ($G5VisualOnly) {
            @((Get-UnityMigrationPropertyValue -Object $fixed -Name "g5VisualValidationFlags" -Default @()) |
                ForEach-Object { [string]$_ })
        } else { @($scenarioRuntimeFlags) }) `
          + @($extraFlags)
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
            if (-not [bool]$result.success -or [string]$result.status -notlike "COMPLETE:*") {
                throw "Unity fixed-account validation failed: $($result.status)"
            }
            $runnerUserId = if ($G3RuntimeOnly -or $G5VisualOnly) { $UserId } else {
                [uint32](Get-UnityMigrationPropertyValue -Object $fixed -Name "terminalUserId" -Default $UserId)
            }
            $runnerRoleId = if ($G3RuntimeOnly -or $G5VisualOnly) { $RoleId } else {
                [uint32](Get-UnityMigrationPropertyValue -Object $fixed -Name "terminalRoleId" -Default $RoleId)
            }
            Assert-UnityMigrationRunnerIdentity -Result $result -ScenarioKey ([string]$scenario.key) -ExpectedUserId $runnerUserId
            if ([uint32]$result.roleId -ne $runnerRoleId) {
                throw "Unity fixed-account terminal role mismatch: expected=$runnerRoleId actual=$($result.roleId)"
            }
            if ($G3RuntimeOnly) {
                if ($g3ValidationFlags.Count -eq 0) {
                    throw "Fixed-account G3 runtime mode requires g3ValidationFlags."
                }
                Copy-Item -LiteralPath $resultPath -Destination $runnerCapture -Force
                if ([bool](Get-UnityMigrationPropertyValue -Object $fixed -Name "copyArtifactsInG3" -Default $false)) {
                    foreach ($copy in @($fixed.artifactCopies)) {
                        $source = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.source)
                        $destination = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.destination)
                        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                            throw "Fixed-account G3 runtime artifact is missing: $source"
                        }
                        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
                        Copy-Item -LiteralPath $source -Destination $destination -Force
                    }
                }
                $serverRuntimeEvidenceReference = ""
                $serverRuntimeEvidenceSha256 = ""
                $serverRuntimeFingerprintLines = @()
                if ($null -ne $serverRuntimeEvidence) {
                    $serverRuntimeSource = Resolve-UnityMigrationPath -Root $root -Path `
                        ([string]$serverRuntimeEvidence.source)
                    $serverRuntimeDestination = Resolve-UnityMigrationPath -Root $root -Path `
                        ([string]$serverRuntimeEvidence.destination)
                    if (-not (Test-Path -LiteralPath $serverRuntimeSource -PathType Leaf)) {
                        throw "Fixed-account server runtime evidence is missing: $serverRuntimeSource"
                    }
                    $serverRuntimeContent = Get-Content -LiteralPath $serverRuntimeSource -Raw -Encoding UTF8
                    foreach ($requiredPattern in @($serverRuntimeEvidence.requiredPatterns)) {
                        if ($serverRuntimeContent -notmatch [string]$requiredPattern) {
                            throw "Fixed-account server runtime evidence misses required pattern: $requiredPattern"
                        }
                    }
                    $fingerprintLinePattern = [string](Get-UnityMigrationPropertyValue `
                        -Object $serverRuntimeEvidence -Name "fingerprintLinePattern" -Default "")
                    if ($fingerprintLinePattern) {
                        $serverRuntimeFingerprintLines = @($serverRuntimeContent -split "`r?`n" |
                            Where-Object { $_ -match $fingerprintLinePattern })
                        if ($serverRuntimeFingerprintLines.Count -eq 0) {
                            throw "Fixed-account server runtime evidence has no fingerprint lines."
                        }
                    }
                    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($serverRuntimeDestination)) | Out-Null
                    Copy-Item -LiteralPath $serverRuntimeSource -Destination $serverRuntimeDestination -Force
                    $serverRuntimeEvidenceReference = [string]$serverRuntimeEvidence.destination
                    $serverRuntimeEvidenceSha256 = (Get-FileHash -LiteralPath $serverRuntimeDestination `
                        -Algorithm SHA256).Hash
                }
                $sourceContractFingerprint = Assert-UnityMigrationSourceContracts -Root $root -Scenario $scenario
                $g3Summary = [ordered]@{
                    schemaVersion = 1
                    success = $true
                    executionMode = "batch"
                    runner = [string]$workflowPolicy.unity.fixedAccountRunner
                    workflowPolicyVersion = [int]$workflowPolicy.version
                    module = [string]$moduleConfig.key
                    scenario = [string]$scenario.key
                    validationMode = "g3-runtime"
                    userId = $UserId
                    roleId = $RoleId
                    status = [string]$result.status
                    screenWidth = [int]$result.screenWidth
                    screenHeight = [int]$result.screenHeight
                    sourceContractFingerprint = $sourceContractFingerprint
                    dataPreflightEvidence = ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-data-preflight-latest.json"
                    serverRuntimeEvidence = $serverRuntimeEvidenceReference
                    serverRuntimeEvidenceSha256 = $serverRuntimeEvidenceSha256
                    serverRuntimeFingerprintLines = @($serverRuntimeFingerprintLines)
                    checkedUtc = [DateTime]::UtcNow.ToString("O")
                }
                Write-UnityMigrationUtf8 -Path (Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-g3-runtime-latest.json") `
                    -Content (($g3Summary | ConvertTo-Json -Depth 8) + "`n")
                $validationPassed = $true
            }
            elseif ($G5VisualOnly) {
                $g5VisualFlags = @(Get-UnityMigrationPropertyValue -Object $fixed `
                    -Name "g5VisualValidationFlags" -Default @())
                if ($g5VisualFlags.Count -eq 0) {
                    throw "Fixed-account G5 visual mode requires g5VisualValidationFlags."
                }
                Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Wait-FixedRuntimeRelease
                $assertVisualAction = [string](Get-UnityMigrationPropertyValue -Object $fixed `
                    -Name "g5VisualAssertAction" -Default "")
                if (-not $assertVisualAction) { throw "Fixed-account G5 visual mode requires g5VisualAssertAction." }
                Invoke-FixedAdapter $assertVisualAction

                $g5 = Get-UnityMigrationPropertyValue -Object $contract -Name "g5" -Default $null
                $visualCopies = New-Object System.Collections.Generic.List[object]
                foreach ($pair in @($g5.pairs)) {
                    $expectedDestination = (([string]$g5.unityDirectory).TrimEnd([char[]]@('/', '\')) `
                        + "/" + [string]$pair.unity)
                    $matches = @($fixed.artifactCopies | Where-Object {
                        [string]$_.destination -ieq $expectedDestination
                    })
                    if ($matches.Count -ne 1) {
                        throw "Fixed-account G5 visual artifact copy is not unique: $expectedDestination"
                    }
                    $visualCopies.Add($matches[0])
                }
                foreach ($copy in $visualCopies) {
                    $source = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.source)
                    $destination = Resolve-UnityMigrationPath -Root $root -Path ([string]$copy.destination)
                    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
                        throw "Fixed-account G5 visual artifact is missing: $source"
                    }
                    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
                    Copy-Item -LiteralPath $source -Destination $destination -Force
                }
                $visualSummary = [ordered]@{
                    schemaVersion = 1
                    success = $true
                    module = [string]$moduleConfig.key
                    mode = "g5-visual-fixed-identity"
                    userId = $UserId
                    roleId = $RoleId
                    status = [string]$result.status
                    stateCount = @($g5.pairs).Count
                    states = @($g5.pairs | ForEach-Object { [string]$_.id })
                    snapshot = $snapshotValue
                    checkedUtc = [DateTime]::UtcNow.ToString("O")
                }
                $visualSummaryPath = Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-g5-visual-latest.json"
                Write-UnityMigrationUtf8 -Path $visualSummaryPath `
                    -Content (($visualSummary | ConvertTo-Json -Depth 8) + "`n")
                $validationPassed = $true
            }
            else {
            if ($null -ne $mutationReloginOracle) {
                $captureAction = [string](Get-UnityMigrationPropertyValue -Object $mutationReloginOracle -Name "captureAction" -Default "")
                $assertAction = [string](Get-UnityMigrationPropertyValue -Object $mutationReloginOracle -Name "assertAction" -Default "")
                $semanticAssertionId = [string](Get-UnityMigrationPropertyValue -Object $mutationReloginOracle -Name "semanticAssertionId" -Default "")
                if ([string]::IsNullOrWhiteSpace($captureAction) -or [string]::IsNullOrWhiteSpace($assertAction) `
                    -or [string]::IsNullOrWhiteSpace($semanticAssertionId)) {
                    throw "Fixed-account mutation relogin oracle contract is incomplete."
                }
                Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Invoke-FixedAdapter $captureAction
                & $startServerScript @serverStartParameters
                if (-not $?) { throw "Fixed-account mutation-relogin server startup failed." }
                try {
                    & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
                        -UserId $UserId -RoleId $RoleId -PythonExecutable $pythonExecutable
                    if ($LASTEXITCODE -ne 0) { throw "Fixed-account mutation-relogin failed." }
                }
                finally {
                    Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 2
                }
                Invoke-FixedAdapter $assertAction
                $passed = @($result.passedSemanticAssertions | ForEach-Object { [string]$_ }) + $semanticAssertionId |
                    Sort-Object -Unique
                $failed = @($result.failedSemanticAssertions | ForEach-Object { [string]$_ } | Where-Object {
                    $_ -notlike "$semanticAssertionId*"
                })
                $result | Add-Member -Force passedSemanticAssertions $passed
                $result | Add-Member -Force failedSemanticAssertions $failed
                Write-UnityMigrationUtf8 -Path $resultPath -Content (($result | ConvertTo-Json -Depth 12) + "`n")
            }
            $sqlitePersistenceOracle = Get-UnityMigrationPropertyValue -Object $fixed -Name "sqlitePersistenceOracle" -Default $null
            if ($null -ne $sqlitePersistenceOracle) {
                $sqliteSemanticId = [string](Get-UnityMigrationPropertyValue -Object $sqlitePersistenceOracle -Name "semanticAssertionId" -Default "")
                if ([string]::IsNullOrWhiteSpace($sqliteSemanticId)) { throw "Fixed-account SQLite persistence oracle has no semanticAssertionId." }
                $sqliteArtifacts = @(
                    @("serverExecutable", "serverExecutableSha256"),
                    @("database", "databaseSha256"),
                    @("runtimeReport", "runtimeReportSha256"),
                    @("restartReport", "restartReportSha256")
                )
                foreach ($artifact in $sqliteArtifacts) {
                    $artifactPath = Resolve-UnityMigrationPath -Root $root -Path ([string](Get-UnityMigrationPropertyValue -Object $sqlitePersistenceOracle -Name $artifact[0] -Default ""))
                    $expectedHash = [string](Get-UnityMigrationPropertyValue -Object $sqlitePersistenceOracle -Name $artifact[1] -Default "")
                    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf) -or [string]::IsNullOrWhiteSpace($expectedHash)) {
                        throw "Fixed-account SQLite persistence oracle artifact is incomplete: $($artifact[0])."
                    }
                    $actualHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash
                    if ($actualHash -ne $expectedHash) { throw "Fixed-account SQLite persistence oracle hash mismatch: $($artifact[0])." }
                }
                $runtimeReportPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$sqlitePersistenceOracle.runtimeReport)
                $restartReportPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$sqlitePersistenceOracle.restartReport)
                $sqliteRuntime = Get-Content -LiteralPath $runtimeReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
                $sqliteRestart = Get-Content -LiteralPath $restartReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($sqliteRuntime.status -ne "Passed" -or $sqliteRuntime.heroEquipParity.status -ne "Passed" `
                    -or $sqliteRuntime.heroEquipParity.mode -ne "runtime" -or -not [bool]$sqliteRuntime.flags.heroEquipParity `
                    -or $sqliteRestart.status -ne "Passed" -or $sqliteRestart.heroEquipParity.status -ne "Passed" `
                    -or $sqliteRestart.heroEquipParity.mode -ne "restart" -or -not [bool]$sqliteRestart.flags.heroEquipRestartVerify) {
                    throw "Fixed-account SQLite HeroEquip runtime/restart semantics did not pass."
                }
                $databasePath = Resolve-UnityMigrationPath -Root $root -Path ([string]$sqlitePersistenceOracle.database)
                if ((Test-Path -LiteralPath "$databasePath-wal" -PathType Leaf) `
                    -or (Test-Path -LiteralPath "$databasePath-shm" -PathType Leaf)) {
                    throw "Fixed-account SQLite persistence oracle has residual WAL/SHM sidecars."
                }
                $passed = @($result.passedSemanticAssertions | ForEach-Object { [string]$_ }) + $sqliteSemanticId | Sort-Object -Unique
                $failed = @($result.failedSemanticAssertions | ForEach-Object { [string]$_ } | Where-Object { $_ -notlike "$sqliteSemanticId*" })
                $result | Add-Member -Force passedSemanticAssertions $passed
                $result | Add-Member -Force failedSemanticAssertions $failed
                Write-UnityMigrationUtf8 -Path $resultPath -Content (($result | ConvertTo-Json -Depth 12) + "`n")
            }
            Copy-Item -LiteralPath $resultPath -Destination $runnerCapture -Force
            $coverage = Assert-UnityMigrationRunnerCoverage -Root $root -Result $result -Scenario $scenario `
                -ControlMatrix ([string]$moduleConfig.controlMatrix)
            if (-not [bool]$fixed.skipPostValidationFixtureAssert) {
                if ($dataBackend -eq "sqlite") {
                    # SQLite adapters reject live readers/writers by contract. The Unity
                    # batch has exited here, but the external local server remains alive
                    # until the outer finally block unless we release it explicitly.
                    Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                    Wait-FixedRuntimeRelease
                }
                Invoke-FixedAdapter $postValidationAdapterAction
            }
            }
        }
        finally {
            Complete-UnityMigrationTiming -Timings $timings -Name "unityValidation" -Timing $unityTiming
        }
        if (-not $G3RuntimeOnly -and -not $G5VisualOnly) {
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
                executionMode = "batch"
                runner = [string]$workflowPolicy.unity.fixedAccountRunner
                workflowPolicyVersion = [int]$workflowPolicy.version
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
    }
    finally {
        $restoreTiming = Start-UnityMigrationTiming
        try {
            Get-Process Unity,kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Wait-FixedRuntimeRelease
            if ($fixtureCreated) {
                if ($validationPassed) {
                    Invoke-FixedAdapter "Restore"
                    Invoke-FixedAdapter "AssertRestored"
                }
                else {
                    Invoke-FixedAdapter "Restore"
                    Invoke-FixedAdapter "AssertRestored"
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
            & $startServerScript @serverStartParameters
            if (-not $?) { throw "Fixed-account restore-login server startup failed." }
            & $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") `
                -UserId $UserId -RoleId $RoleId -PythonExecutable $pythonExecutable
            if ($LASTEXITCODE -ne 0) { throw "Fixed-account restore-login failed." }
        }
        catch { $reloginFailure = $_ }
        finally {
            Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Wait-FixedRuntimeRelease
            if ($fixtureCreated) {
                if ($null -eq $reloginFailure) {
                    try { Invoke-FixedAdapter "AssertReloginHash" }
                    catch { $reloginFailure = $_ }
                }
                try {
                    Invoke-FixedAdapter "Restore"
                    Invoke-FixedAdapter "AssertRestored"
                }
                catch {
                    if ($null -eq $reloginFailure) { $reloginFailure = $_ }
                }
                finally {
                    try {
                        Invoke-FixedAdapter "Cleanup"
                        Invoke-FixedAdapter "AssertCleanup"
                        $fixtureCreated = $false
                    }
                    catch {
                        if ($null -eq $reloginFailure) { $reloginFailure = $_ }
                    }
                }
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
    $modeLabel = if ($G5VisualOnly) { "G5 visual" } else { "validation" }
    Write-Host "Fixed-account $modeLabel passed and restored: module=$Module userId=$UserId roleId=$RoleId"
}
catch {
    $failureGate = if ($G5VisualOnly) { "G5" } elseif ($DataPreflightOnly -or $PreflightOnly -or $G3RuntimeOnly) { "G3" } else { "G6" }
    Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $failureGate -Category UnityBatch `
        -Tool "tools/unity-migration/Run-UnityFixedAccountValidation.ps1" -Operation "fixed-account-batch-validation" `
        -Outcome Failed -ErrorMessage $_.Exception.Message -RootCause "pending-diagnosis" `
        -Evidence @($timingPath) | Out-Null
    throw
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
        mode = $(if ($PreflightOnly) { "compile-preflight" } elseif ($DataPreflightOnly) { "data-preflight" } elseif ($G3RuntimeOnly) { "g3-runtime" } elseif ($G5VisualOnly) { "g5-visual" } else { "full" })
        status = $runStatus
        timings = $timings
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $timingPath -Content (($timingReport | ConvertTo-Json -Depth 8) + "`n")
}
if ($runStatus -in @("passed", "preflight-passed", "data-preflight-passed")) {
    $successGate = if ($G5VisualOnly) { "G5" } elseif ($DataPreflightOnly -or $PreflightOnly -or $G3RuntimeOnly) { "G3" } else { "G6" }
    Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $successGate -Category UnityBatch `
        -Tool "tools/unity-migration/Run-UnityFixedAccountValidation.ps1" -Operation "fixed-account-batch-validation" `
        -Outcome Passed -Evidence @($timingPath) | Out-Null
}
