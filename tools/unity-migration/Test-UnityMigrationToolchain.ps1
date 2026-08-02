[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$passed = 0

function Assert-ToolchainTest {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) { throw $Message }
    $script:passed++
}

$valid = [pscustomobject]@{
    userId = 7200057
    roleId = 1000115
    adapter = "tools/unity-migration/Invoke-ShopCocosFixture.ps1"
    snapshot = ".local/test/snapshot.json"
    resultEvidence = ".local/test/result.json"
    reloginRequired = $true
    extraFlags = @()
    skipPostValidationFixtureAssert = $false
    dataPreflight = [pscustomobject]@{
        requiresLogin = $false
        requirements = @(
            [pscustomobject]@{ id = "sample-data"; description = "deterministic sample data" }
        )
    }
    artifactCopies = @()
}
$validFailures = @(Get-UnityMigrationFixedAccountContractFailures `
    -Root $root -Module "Valid" -FixedAccount $valid)
Assert-ToolchainTest ($validFailures.Count -eq 0) "Valid fixed-account contract was rejected: $($validFailures -join '; ')"

$missing = [pscustomobject]@{
    userId = 1
    roleId = 2
    adapter = "tools/unity-migration/Invoke-ShopCocosFixture.ps1"
}
$missingFailures = @(Get-UnityMigrationFixedAccountContractFailures `
    -Root $root -Module "Missing" -FixedAccount $missing)
foreach ($field in @(
    "snapshot", "resultEvidence", "reloginRequired", "extraFlags",
    "skipPostValidationFixtureAssert", "artifactCopies", "dataPreflight"
)) {
    Assert-ToolchainTest (
        @($missingFailures | Where-Object { $_ -like "*missing required field '$field'.*" }).Count -eq 1
    ) "Missing fixed-account field was not rejected: $field"
}

$invalid = [pscustomobject]@{
    userId = 1
    roleId = 2
    adapter = "tools/unity-migration/Invoke-ShopCocosFixture.ps1"
    snapshot = ".local/test/snapshot.json"
    resultEvidence = ".local/test/result.json"
    reloginRequired = "yes"
    extraFlags = @("")
    skipPostValidationFixtureAssert = 0
    dataPreflight = [pscustomobject]@{
        requiresLogin = "yes"
        requirements = @(
            [pscustomobject]@{ id = "duplicate"; description = "first" },
            [pscustomobject]@{ id = "duplicate"; description = "second" }
        )
    }
    artifactCopies = @(
        [pscustomobject]@{ source = "a"; destination = "same" },
        [pscustomobject]@{ source = "b"; destination = "same" }
    )
}
$invalidFailures = @(Get-UnityMigrationFixedAccountContractFailures `
    -Root $root -Module "Invalid" -FixedAccount $invalid)
Assert-ToolchainTest (
    @($invalidFailures | Where-Object { $_ -like "*reloginRequired*boolean*" }).Count -eq 1
) "Non-boolean reloginRequired was not rejected."
Assert-ToolchainTest (
    @($invalidFailures | Where-Object { $_ -like "*skipPostValidationFixtureAssert*boolean*" }).Count -eq 1
) "Non-boolean skipPostValidationFixtureAssert was not rejected."
Assert-ToolchainTest (
    @($invalidFailures | Where-Object { $_ -like "*extraFlags contains an empty value*" }).Count -eq 1
) "Empty extraFlags value was not rejected."
Assert-ToolchainTest (
    @($invalidFailures | Where-Object { $_ -like "*duplicate destinations*" }).Count -eq 1
) "Duplicate artifact destination was not rejected."
Assert-ToolchainTest (
    @($invalidFailures | Where-Object { $_ -like "*dataPreflight.requiresLogin*boolean*" }).Count -eq 1
) "Non-boolean dataPreflight.requiresLogin was not rejected."
Assert-ToolchainTest (
    @($invalidFailures | Where-Object { $_ -like "*duplicate requirement ids*" }).Count -eq 1
) "Duplicate data requirement id was not rejected."

$pwshExecutable = Get-UnityMigrationPowerShellExecutable
$pythonExecutable = Get-UnityMigrationPythonExecutable
Assert-ToolchainTest (Test-Path -LiteralPath $pwshExecutable -PathType Leaf) "PowerShell executable resolution failed."
Assert-ToolchainTest (Test-Path -LiteralPath $pythonExecutable -PathType Leaf) "Python executable resolution failed."
$shellRoute = Get-UnityMigrationShellRoute -Root $root
Assert-ToolchainTest (
    [string]$shellRoute.brokerWorkdirMode -eq "omit" -and
    [string]$shellRoute.root -eq [IO.Path]::GetFullPath($root) -and
    [string]$shellRoute.powerShellPrelude -eq "Set-Location -LiteralPath '$([IO.Path]::GetFullPath($root))'"
) "Shell route no longer enforces literal in-process workspace selection without a broker workdir argument."

$resolvedBootstrapRunner = Resolve-UnityMigrationExistingPath -Root $root `
    -Path "unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs" -PathType Leaf
Assert-ToolchainTest (
    $resolvedBootstrapRunner -eq [IO.Path]::GetFullPath((Join-Path $root "unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs"))
) "Existing migration source path resolution failed."
$unresolvedMigrationPathRejected = $false
try {
    Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/Tests/Runtime/BootstrapAppRunner.cs" -PathType Leaf | Out-Null
}
catch {
    $unresolvedMigrationPathRejected = $_.Exception.Message -like `
        "Unity migration path was not resolved to an existing Leaf path:*Resolve it through the manifest, matrix, rg --files, or source references before use.*"
}
Assert-ToolchainTest $unresolvedMigrationPathRejected `
    "Unresolved source paths no longer fail with the manifest/matrix/rg discovery contract."

$rootCommand = "dotnet Unity.ILPP.Runner.dll --project `"$root\unityclient`""
Assert-ToolchainTest (
    Test-UnityMigrationCommandLineReferencesRoot -CommandLine $rootCommand -Root $root
) "Project-related dotnet command line was not detected."
Assert-ToolchainTest (
    -not (Test-UnityMigrationCommandLineReferencesRoot `
        -CommandLine "dotnet C:\other\project\worker.dll" -Root $root)
) "Unrelated dotnet command line was incorrectly detected."

$timings = [ordered]@{}
$timing = Start-UnityMigrationTiming
Start-Sleep -Milliseconds 20
Complete-UnityMigrationTiming -Timings $timings -Name "sample" -Timing $timing
Assert-ToolchainTest ([long]$timings.sample.durationMs -ge 1) "Timing helper did not record elapsed milliseconds."

$manifest = (Import-UnityMigrationManifest -Root $root).Value
$unityExecutable = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityExecutable)
$unityProject = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)
$fingerprintA = Get-UnityMigrationCompileFingerprint -UnityProject $unityProject -UnityExecutable $unityExecutable
$fingerprintB = Get-UnityMigrationCompileFingerprint -UnityProject $unityProject -UnityExecutable $unityExecutable
Assert-ToolchainTest ($fingerprintA -match '^[A-F0-9]{64}$') "Compile fingerprint is not SHA-256."
Assert-ToolchainTest ($fingerprintA -eq $fingerprintB) "Compile fingerprint is not deterministic."

$dataFingerprintA = Get-UnityMigrationDataPreflightFingerprint -Root $root -FixedAccount $valid
$dataFingerprintB = Get-UnityMigrationDataPreflightFingerprint -Root $root -FixedAccount $valid
Assert-ToolchainTest ($dataFingerprintA -match '^[A-F0-9]{64}$') "Data preflight fingerprint is not SHA-256."
Assert-ToolchainTest ($dataFingerprintA -eq $dataFingerprintB) "Data preflight fingerprint is not deterministic."

$g5Contract = [pscustomobject]@{
    module = "G5Sample"
    fixedAccount = $valid
    g5 = [pscustomobject]@{
        cocosDirectory = ".local/g5/cocos"; unityDirectory = ".local/g5/unity"; compareDirectory = ".local/g5/compare"
        width = 1334; height = 750
        pairs = @([pscustomobject]@{ id = "STATE"; cocos = "cocos.png"; unity = "unity.png" })
    }
}
$g5FingerprintA = Get-UnityMigrationG5ContractFingerprint -Contract $g5Contract
$g5FingerprintB = Get-UnityMigrationG5ContractFingerprint -Contract $g5Contract
Assert-ToolchainTest ($g5FingerprintA -match '^[A-F0-9]{64}$') "G5 contract fingerprint is not SHA-256."
Assert-ToolchainTest ($g5FingerprintA -eq $g5FingerprintB) "G5 contract fingerprint is not deterministic."

$duplicateSamples = @(
    [pscustomobject]@{ id = "DEFAULT"; sha256 = "same" },
    [pscustomobject]@{ id = "CORRUPT"; sha256 = "same" },
    [pscustomobject]@{ id = "MUSIC-OFF"; sha256 = "different" }
)
Assert-UnityMigrationDuplicateHashPolicy -Items $duplicateSamples -IdentifierProperty "id" `
    -HashProperty "sha256" -AllowedDuplicateGroups @([pscustomobject]@{ ids = @("DEFAULT", "CORRUPT") }) `
    -Context "Toolchain duplicate policy sample"
Assert-ToolchainTest $true "A declared visual-equivalence group was rejected."
Assert-UnityMigrationDuplicateHashPolicy -Items $duplicateSamples -IdentifierProperty "id" `
    -HashProperty "sha256" -AllowedDuplicateGroups @([pscustomobject]@{ ids = @("DEFAULT", "CORRUPT", "MUSIC-OFF") }) `
    -Context "Toolchain duplicate policy subset sample"
Assert-ToolchainTest $true "A duplicate subset inside one declared visual-equivalence group was rejected."
$unexpectedDuplicateRejected = $false
try {
    Assert-UnityMigrationDuplicateHashPolicy -Items $duplicateSamples -IdentifierProperty "id" `
        -HashProperty "sha256" -AllowedDuplicateGroups @() -Context "Toolchain duplicate policy sample"
}
catch { $unexpectedDuplicateRejected = $true }
Assert-ToolchainTest $unexpectedDuplicateRejected "An undeclared duplicate screenshot group was accepted."

$validEvidence = [pscustomobject]@{
    contractFingerprint = $dataFingerprintA
    userId = 7200057
    roleId = 1000115
    setupAssert = "passed"
    restoreAssert = "passed"
    cleanupAssert = "passed"
}
$validEvidenceFailures = @(Get-UnityMigrationDataPreflightEvidenceFailures `
    -Evidence $validEvidence -ExpectedFingerprint $dataFingerprintA `
    -ExpectedUserId 7200057 -ExpectedRoleId 1000115)
Assert-ToolchainTest ($validEvidenceFailures.Count -eq 0) "Valid data preflight evidence was rejected."
$staleEvidence = $validEvidence.PSObject.Copy()
$staleEvidence.contractFingerprint = "STALE"
$staleEvidence.cleanupAssert = "pending"
$staleEvidenceFailures = @(Get-UnityMigrationDataPreflightEvidenceFailures `
    -Evidence $staleEvidence -ExpectedFingerprint $dataFingerprintA `
    -ExpectedUserId 7200057 -ExpectedRoleId 1000115)
Assert-ToolchainTest (
    @($staleEvidenceFailures | Where-Object { $_ -eq "contract fingerprint mismatch" }).Count -eq 1
) "Stale data preflight fingerprint was not rejected."
Assert-ToolchainTest (
    @($staleEvidenceFailures | Where-Object { $_ -eq "cleanupAssert is not passed" }).Count -eq 1
) "Incomplete data preflight cleanup assertion was not rejected."

$fixedRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityFixedAccountValidation.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $fixedRunnerSource.Contains('Write-UnityMigrationUtf8 -Path $resultPath -Content $previousResultContent')
) "Fixed-account runner no longer restores the preceding isolated validation result."
Assert-ToolchainTest (
    $fixedRunnerSource.Contains('captureStates = @($scenario.captureStates)') -and
    $fixedRunnerSource.Contains('screenshots = @($visualResults)') -and
    $fixedRunnerSource.Contains('executionMode = "batch"') -and
    $fixedRunnerSource.Contains('Assert-UnityMigrationModuleWorkflowContract')
) "Fixed-account runner no longer emits the hard-gate visual summary."

$fixedIdentity = [pscustomobject]@{
    userId = 7200057; roleId = 1000115; terminalUserId = 705213; terminalRoleId = 1000006
}
$fixedSummary = [pscustomobject]@{ userId = 7200057; roleId = 1000115 }
$terminalResult = [pscustomobject]@{ userId = 705213; roleId = 1000006 }
Assert-ToolchainTest (
    @(Get-UnityMigrationSummaryIdentityFailures -Summary $fixedSummary -Result $terminalResult `
        -FixedAccount $fixedIdentity).Count -eq 0
) "Fixed-account summary and terminal isolation identity were rejected."
$wrongTerminal = [pscustomobject]@{ userId = 705214; roleId = 1000006 }
Assert-ToolchainTest (
    @(Get-UnityMigrationSummaryIdentityFailures -Summary $fixedSummary -Result $wrongTerminal `
        -FixedAccount $fixedIdentity).Count -eq 1
) "Wrong terminal isolation identity was not rejected."

$workflowPolicy = Assert-UnityMigrationWorkflowPolicy -Root $root
Assert-ToolchainTest (
    @(Get-UnityMigrationWorkflowPolicyFailures -Policy $workflowPolicy).Count -eq 0
) "Canonical workflow policy was rejected."

$invalidWorkflowPolicy = $workflowPolicy | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$invalidWorkflowPolicy.cocos.maximumAttemptsPerTarget = 2
$invalidWorkflowPolicy.unity.runtimeValidationMode = "editor-or-batch"
$workflowFailures = @(Get-UnityMigrationWorkflowPolicyFailures -Policy $invalidWorkflowPolicy)
Assert-ToolchainTest (
    @($workflowFailures | Where-Object { $_ -like "*maximumAttemptsPerTarget*" }).Count -eq 1
) "Repeated Cocos target attempts were not rejected by workflow policy."
Assert-ToolchainTest (
    @($workflowFailures | Where-Object { $_ -like "*runtimeValidationMode*batch-only*" }).Count -eq 1
) "Non-batch Unity runtime validation was not rejected by workflow policy."

$validLedger = [pscustomobject]@{
    schemaVersion = 1
    module = "Sample"
    workflowPolicyVersion = 1
    tool = "computer-use@openai-bundled"
    requestedAppReference = "plugin://computer-use@openai-bundled?app=com.adspower.global"
    targetProcess = "ProjectX.exe"
    targetWindow = "Cocos Simulator"
    approvalMode = "routine-project-actions-preapproved"
    attempts = @(
        [pscustomobject]@{
            targetId = "SAMPLE-01"; attemptNumber = 1; desktopCapture = $false
            capturePath = ".local/sample-01.png"; width = 1334; height = 750
        }
    )
}
Assert-ToolchainTest (
    @(Get-UnityMigrationCocosAutomationLedgerFailures -Ledger $validLedger `
        -ExpectedModule "Sample").Count -eq 0
) "Valid Cocos automation ledger was rejected."
$invalidLedger = $validLedger | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$invalidLedger.attempts = @($invalidLedger.attempts) + @($invalidLedger.attempts[0])
$invalidLedger.targetProcess = "com.adspower.global"
$invalidLedger.approvalMode = "ask-every-time"
$ledgerFailures = @(Get-UnityMigrationCocosAutomationLedgerFailures -Ledger $invalidLedger `
    -ExpectedModule "Sample")
Assert-ToolchainTest (
    @($ledgerFailures | Where-Object { $_ -like "*repeated target ids*" }).Count -eq 1
) "Duplicate Cocos target ids were not rejected."
Assert-ToolchainTest (
    @($ledgerFailures | Where-Object { $_ -like "*targetProcess must be ProjectX.exe*" }).Count -eq 1 -and
    @($ledgerFailures | Where-Object { $_ -like "*routine-project-actions-preapproved*" }).Count -eq 1
) "AdsPower-as-game-target or redundant routine approval was not rejected."

$operationLedger = [pscustomobject]@{
    schemaVersion = 1
    module = "Sample"
    workflowPolicyVersion = 1
    records = @(
        [pscustomobject]@{
            recordId = "failure-1"; outcome = "Failed"; error = "wrong page"
            rootCause = "stale-coordinate"; relatedRecordId = ""; resolution = ""
            iterationAction = ""; iterationEvidence = @()
        },
        [pscustomobject]@{
            recordId = "resolution-1"; outcome = "Resolved"; error = ""; rootCause = ""
            relatedRecordId = "failure-1"; resolution = "observe fresh state"
            iterationAction = "lock observe-action-refresh"; iterationEvidence = @("tools/unity-migration/validation-scenarios.json")
        }
    )
}
Assert-ToolchainTest (
    @(Get-UnityMigrationRetrospectiveFailures -Ledger $operationLedger).Count -eq 0
) "Diagnosed and iterated migration failure was rejected."
$operationLedger.records[0].rootCause = "pending-diagnosis"
$operationLedger.records[1].iterationEvidence = @(
    "runtime assertion annotation",
    "tools/unity-migration/validation-scenarios.json:1-2"
)
Assert-ToolchainTest (
    @(Get-UnityMigrationRetrospectiveFailures -Ledger $operationLedger -Root $root -RequireEvidenceFiles).Count -eq 0
) "Unique resolved diagnosis or path-with-line iteration evidence was rejected."
$resolutionAudit = @(Get-UnityMigrationOperationResolutionAudit -Ledger $operationLedger -RecordIds @("failure-1"))
Assert-ToolchainTest (
    $resolutionAudit.Count -eq 1 -and
    [string]$resolutionAudit[0].recordId -eq "failure-1" -and
    [int]$resolutionAudit[0].resolutionCount -eq 1 -and
    @($resolutionAudit[0].iterationEvidence).Count -eq 2
) "Operation resolution audit did not return the requested failure and its unique iteration record."
$operationLedger.records[1].iterationEvidence = @()
Assert-ToolchainTest (
    @(Get-UnityMigrationRetrospectiveFailures -Ledger $operationLedger).Count -eq 1
) "Failure without iteration evidence did not block retrospective completion."
$operationLedger.records = @($operationLedger.records) + @(
    [pscustomobject]@{
        recordId = "supplement-1"; outcome = "Supplemented"; error = ""; rootCause = ""
        relatedRecordId = "failure-1"; resolution = "supply durable file evidence"
        iterationAction = "bind the historical resolution to a current regression artifact"
        iterationEvidence = @("tools/unity-migration/Test-UnityMigrationToolchain.ps1")
    }
)
Assert-ToolchainTest (
    @(Get-UnityMigrationRetrospectiveFailures -Ledger $operationLedger -Root $root -RequireEvidenceFiles).Count -eq 0
) "Append-only retrospective evidence supplement did not satisfy file-backed evidence validation."

$validBatchSummary = [pscustomobject]@{
    executionMode = "batch"
    runner = [string]$workflowPolicy.unity.standardRunner
    workflowPolicyVersion = [int]$workflowPolicy.version
}
Assert-ToolchainTest (
    @(Get-UnityMigrationBatchSummaryFailures -Summary $validBatchSummary `
        -Policy $workflowPolicy).Count -eq 0
) "Canonical batch validation summary was rejected."
$invalidBatchSummary = [pscustomobject]@{
    executionMode = "mcp"
    runner = "manual-playmode"
    workflowPolicyVersion = 0
}
Assert-ToolchainTest (
    @(Get-UnityMigrationBatchSummaryFailures -Summary $invalidBatchSummary `
        -Policy $workflowPolicy).Count -eq 3
) "Non-canonical Unity validation summary was not rejected."

$validSourceAuditMatrix = [pscustomobject]@{
    sourceAudit = [pscustomobject]@{
        entryClosureComplete = $true
        protocolOwnershipComplete = $true
        configAssetClosureComplete = $true
        runtimeTransformClosureComplete = $true
        knownGaps = @(
            [pscustomobject]@{ id = "missing-item"; handling = "module-local"; evidence = "source:1" }
        )
    }
}
Assert-ToolchainTest (
    @(Get-UnityMigrationSourceAuditFailures -Matrix $validSourceAuditMatrix).Count -eq 0
) "Valid source/config/transform audit was rejected."
$invalidSourceAuditMatrix = [pscustomobject]@{
    sourceAudit = [pscustomobject]@{
        entryClosureComplete = $true
        protocolOwnershipComplete = $false
        configAssetClosureComplete = $false
        runtimeTransformClosureComplete = $true
        knownGaps = @([pscustomobject]@{ id = "missing-item"; handling = ""; evidence = "" })
    }
}
$sourceAuditFailures = @(Get-UnityMigrationSourceAuditFailures -Matrix $invalidSourceAuditMatrix)
Assert-ToolchainTest (
    @($sourceAuditFailures | Where-Object { $_ -like "*protocolOwnershipComplete*" }).Count -eq 1 -and
    @($sourceAuditFailures | Where-Object { $_ -like "*configAssetClosureComplete*" }).Count -eq 1 -and
    @($sourceAuditFailures | Where-Object { $_ -like "*requires id, handling and evidence*" }).Count -eq 1
) "Incomplete source/config/transform audit was not rejected."

$operationLedgerSource = Get-Content -LiteralPath (Join-Path $root "tools/unity-migration/Update-UnityMigrationOperationLedger.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $operationLedgerSource.Contains('computer-use@openai-bundled') -and
    $operationLedgerSource.Contains('routine-project-actions-preapproved') -and
    $operationLedgerSource.Contains('Add-UnityMigrationOperationRecord')
) "Cocos Computer Use evidence or migration operation ledger writer disappeared."

$gateSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Invoke-UnityMigrationGate.ps1") `
    -Raw -Encoding UTF8
$hardGateSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Test-UnityMigrationHardGates.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $gateSource.Contains("Completing G1 requires -CocosAutomationLedgerPath") -and
    $gateSource.Contains("Completing G4 requires -SummaryPath") -and
    $gateSource.Contains("Assert-UnityMigrationSourceAudit") -and
    $gateSource.Contains("Test-UnityModuleG5Preflight.ps1") -and
    $gateSource.Contains("New-UnityMigrationRetrospective")
) "G1/G2/G4/G5/G6 workflow or automatic retrospective enforcement disappeared from the migration gate."
Assert-ToolchainTest (
    $hardGateSource.Contains("G6 Computer Use runtime must be stopped after Cocos evidence") -and
    $hardGateSource.Contains("OpenAI\\Codex\\runtimes\\cua_node")
) "G6 no longer rejects a residual Computer Use runtime after native Cocos evidence collection."
Assert-ToolchainTest (
    (Get-UnityMigrationComputerUseRestartDisposition -ErrorMessage 'node_repl/js transport closed' `
        -Attempt 1 -RuntimeWasVerifiedStopped $true) -eq 'RetryOnceAfterVerifiedCleanup' -and
    (Get-UnityMigrationComputerUseRestartDisposition -ErrorMessage 'node_repl/js transport closed' `
        -Attempt 2 -RuntimeWasVerifiedStopped $true) -eq 'Fail' -and
    (Get-UnityMigrationComputerUseRestartDisposition -ErrorMessage 'unexpected protocol error' `
        -Attempt 1 -RuntimeWasVerifiedStopped $true) -eq 'Fail'
) "Computer Use cannot perform one bounded clean restart after its verified runtime cleanup closes the old transport."

$moduleRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityModuleValidation.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $moduleRunnerSource.Contains('executionMode = "batch"') -and
    $moduleRunnerSource.Contains('$ValidationMode -eq "Preflight"') -and
    $moduleRunnerSource.Contains('"-projectXUserId=<auto-isolated>"')
) "Standard Unity runner no longer records batch execution or an accurate preflight account plan."

$bootstrapRunnerSource = Get-Content -LiteralPath $resolvedBootstrapRunner -Raw -Encoding UTF8
Assert-ToolchainTest (
    $bootstrapRunnerSource.Contains('settingsValidation && status == "Main UI active."') -and
    $bootstrapRunnerSource.Contains('app.IsSettingsDataReady') -and
    $bootstrapRunnerSource.Contains('SessionState.GetInt(SettingsPhaseKey, 0) == 0') -and
    $bootstrapRunnerSource.Contains('app.RunSettingsValidation();') -and
    $bootstrapRunnerSource.Contains('SettingsVisualPreparedKey') -and
    $bootstrapRunnerSource.Contains('queued after stable-frame delay') -and
    $bootstrapRunnerSource.Contains('MirrorSettingsIsolationScreenshot')
) "Settings batch validation no longer starts from the authoritative Main UI ready state."
Assert-ToolchainTest (
    $bootstrapRunnerSource.Contains('status.IndexOf("请求超时", StringComparison.Ordinal) >= 0') -and
    $bootstrapRunnerSource.Contains('Terminal protocol timeout observed; finishing immediately.')
) "Batch validation no longer fails fast when a concrete protocol-timeout dialog is shown."
Assert-ToolchainTest (
    $bootstrapRunnerSource.Contains('CompletionStatusKey') -and
    $bootstrapRunnerSource.Contains('SessionState.GetBool(ScreenshotPendingKey, false)') -and
    $bootstrapRunnerSource.Contains('completedStatus.StartsWith("COMPLETE:", StringComparison.Ordinal)')
) "Batch validation no longer latches a terminal COMPLETE status during stable-frame screenshot capture."

$projectXAppSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs") -Raw -Encoding UTF8
$networkServiceSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/Network/NetworkService.cs") -Raw -Encoding UTF8
$playerHudTempActivitySource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/Resources/Lua/Activity/TempActivityController.lua.txt") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $projectXAppSource.Contains('public void SendUntracked(LegacyTcpMessage message)') -and
    $playerHudTempActivitySource.Contains('Bridge:SendUntracked(discount)') -and
    $projectXAppSource.Contains('if (CurrentAppState == AppState.Disconnected) return;') -and
    $projectXAppSource.Contains('services.ProtocolRegistry.ClearPending();') -and
    $networkServiceSource.Contains('public void Disconnect(string reason = "Disconnected by client.")') -and
    $networkServiceSource.Contains('Disconnected?.Invoke(reason);') -and
    $projectXAppSource.Contains('services.Network.Disconnect("PlayerHud deliberate disconnect")')
) "PlayerHud optional silent activity queries or idempotent deliberate-disconnect cleanup regressed."

$mainHudPresenterSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/UI/MainHudPresenter.cs" -PathType Leaf) -Raw -Encoding UTF8
$mainTaskTrackerSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/UI/MainTaskTrackerPresenter.cs" -PathType Leaf) -Raw -Encoding UTF8
Assert-ToolchainTest (
    $mainHudPresenterSource.Contains('onlineTimeRoot.SetActive(remaining > 0)') -and
    $mainHudPresenterSource.Contains('new GameObject("ItemIconLayer.csb"') -and
    $mainHudPresenterSource.Contains('chatList.gameObject.AddComponent<RectMask2D>()') -and
    $mainHudPresenterSource.Contains('SetChatControlVisible("Layer/Panel_Chat/Prompt", false);') -and
    $mainHudPresenterSource.Contains('SetChatControlVisible("Layer/Panel_Chat/btn_Set", false);') -and
    $mainHudPresenterSource.Contains('UnityEngine.Object.Instantiate(chatTemplate, chatList, false)') -and
    $mainHudPresenterSource.Contains('tagText.text = record.Channel == ChatChannel.System ? "系统" : "世界";') -and
    $mainHudPresenterSource.Contains('.Replace("[c/n]", string.Empty)') -and
    $mainHudPresenterSource.Contains('.Replace("[c/]", string.Empty)') -and
    $mainHudPresenterSource.Contains('.Replace("[/c]", string.Empty)') -and
    $mainHudPresenterSource.Contains('const float collapsedListHeight = 100.8287f;') -and
    $mainHudPresenterSource.Contains('const float expansionOffset = 115.8287f;') -and
    $mainHudPresenterSource.Contains('const float rowHeight = 58f;') -and
    $mainHudPresenterSource.Contains('powerRect.localScale = Vector3.one;') -and
    $mainHudPresenterSource.Contains('public int VisibleDiscountCount =>') -and
    $mainHudPresenterSource.Contains('public int VisibleRedDotCount =>') -and
    $mainHudPresenterSource.Contains('public string VisibleRedDotSummary =>') -and
    $mainHudPresenterSource.Contains('StableVisiblePromptPaths') -and
    $mainHudPresenterSource.Contains('serverRedDots.Any(entry => RedDotTarget(entry.Key) == target && entry.Value)') -and
    $mainHudPresenterSource.Contains('native Cocos') -and
    -not $mainHudPresenterSource.Contains('SetAllRedDots(false);') -and
    -not $mainHudPresenterSource.Contains('discountButtons[index].SetActive(false);') -and
    $mainHudPresenterSource.Contains('int visibleCount = chatExpanded ? 4 : 2;') -and
    $mainHudPresenterSource.Contains('private int chatVisibleStartIndex;') -and
    $mainHudPresenterSource.Contains('private bool systemChatSummaryVisible;') -and
    $mainHudPresenterSource.Contains('public void BeginReconnectChatSummary()') -and
    $mainHudPresenterSource.Contains('chatVisibleStartIndex = 0;') -and
    $mainHudPresenterSource.Contains('.Where(record => systemChatSummaryVisible || record.Channel != ChatChannel.System)') -and
    $mainHudPresenterSource.Contains('text.supportRichText = true;') -and
    $projectXAppSource.Contains('AnimateHudSubmenu(rect, hudShopSubmenuOrigin, -126f)') -and
    $projectXAppSource.Contains('AnimateHudSubmenu(rect, hudWearSubmenuOrigin, 112f)') -and
    $projectXAppSource.Contains('while (IsToastVisible && Time.realtimeSinceStartup < toastDeadline)') -and
    $projectXAppSource.Contains('mainHudPresenter?.BeginReconnectChatSummary();') -and
    $projectXAppSource.Contains('mainHudPresenter.VisibleRedDotCount < 12') -and
    $projectXAppSource.Contains('hud-authoritative-discounts') -and
    $projectXAppSource.Contains('hud-authoritative-red-dots') -and
    $projectXAppSource.Contains('ReconnectFromConnectionFailure, "确认", "取消", false') -and
    $projectXAppSource.Contains('mainHudPresenter?.Dispose();') -and
    $projectXAppSource.Contains('mainHudPresenter = null;') -and
    $projectXAppSource.Contains('mainTaskTracker?.Dispose();') -and
    $projectXAppSource.Contains('mainTaskTracker = null;') -and
    $projectXAppSource.Contains('!mainTaskTracker.IsAuthorityReady') -and
    $projectXAppSource.Contains('while (!services.Currencies.Has(CurrencyIds.Stamina) && Time.realtimeSinceStartup < deadline)')
) "PlayerHud native online reward, chat clipping/expansion, submenu animation, or stable-frame capture regressed."
Assert-ToolchainTest (
    $mainTaskTrackerSource.Contains('private bool serverHotPointReceived;') -and
    $mainTaskTrackerSource.Contains('public bool IsAuthorityReady => store.Count > 0 || serverHotPointReceived;') -and
    $mainTaskTrackerSource.Contains('else if (serverHotPointReceived) prompt.SetActive(serverHotPoint);') -and
    -not $mainTaskTrackerSource.Contains('prompt.SetActive(store.Count > 0 ? store.HasClaimable : serverHotPoint);')
) "PlayerHud task red-dot state can again be overwritten before /65 or TaskStore authority exists."
$currencyStoreSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/Data/CurrencyStore.cs" -PathType Leaf) -Raw -Encoding UTF8
Assert-ToolchainTest (
    $currencyStoreSource.Contains('A same-account reconnect receives /1004 again') -and
    -not $currencyStoreSource.Contains("public void Initialize(long gold, long premium, long boundPremium, uint soul, uint guildContribution)`r`n        {`r`n            values.Clear();")
) "CurrencyStore no longer preserves auxiliary authoritative currencies across same-account reconnect."

$settingsPresenterSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/UI/SettingsPresenter.cs") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $settingsPresenterSource.Contains('slider.handleRect.SetSizeWithCurrentAnchors') -and
    $settingsPresenterSource.Contains('colors.disabledColor = Color.white')
) "Settings Slider no longer repairs the imported zero-size Cocos handle or preserves its disabled visual."

$fixedRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityFixedAccountValidation.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $fixedRunnerSource.Contains('$requiredGate = if ($DataPreflightOnly -or $PreflightOnly) { "G2" } else { "G3" }') -and
    $fixedRunnerSource.Contains('$workflowPhase = if ($DataPreflightOnly) { "G0" } else { "G3" }') -and
    $fixedRunnerSource.Contains('if (-not $DataPreflightOnly)')
) "Fixed-account data/compile preflights no longer run after G2 while the full run remains gated by G3."

$commonSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "UnityMigration.Common.ps1") -Raw -Encoding UTF8
Assert-ToolchainTest (
    (Assert-UnityMigrationRgPathArgument -Path "server/src") -eq "server/src"
) "Literal rg path arguments are no longer accepted by the shared guard."
$unsafeRgRejected = $false
try { Assert-UnityMigrationRgPathArgument -Path "server/src/user.*" | Out-Null }
catch { $unsafeRgRejected = $_.Exception.Message -like "rg path arguments must be literal on Windows*" }
Assert-ToolchainTest $unsafeRgRejected "Windows wildcard rg path arguments are no longer rejected by the shared guard."
$resolvedRgPaths = @(Resolve-UnityMigrationRgPathArguments -Root $root -Paths @(
    "client/ProjectX/src/ConfigData",
    "unityclient/Assets/ProjectX/Resources/Config"
))
Assert-ToolchainTest (
    $resolvedRgPaths.Count -eq 2 -and
    @($resolvedRgPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0
) "Existing rg path lists are no longer resolved and validated before execution."
$missingRgPathRejected = $false
try {
    Resolve-UnityMigrationRgPathArguments -Root $root -Paths @(
        "client/ProjectX/src/ConfigData",
        "client/ProjectX/res/config"
    ) | Out-Null
}
catch {
    $missingRgPathRejected = $_.Exception.Message -like `
        "rg path preflight rejected 'client/ProjectX/res/config' before native rg execution.*Resolve it through the manifest, matrix, rg --files, or source references before use.*"
}
Assert-ToolchainTest $missingRgPathRejected `
    "An rg path list containing a nonexistent directory no longer fails before native rg execution."
$missingHudPrefabPathRejected = $false
try {
    Resolve-UnityMigrationRgPathArguments -Root $root -Paths @(
        "unityclient/Assets/ProjectX/Prefabs"
    ) | Out-Null
}
catch {
    $missingHudPrefabPathRejected = $_.Exception.Message -like `
        "rg path preflight rejected 'unityclient/Assets/ProjectX/Prefabs' before native rg execution.*"
}
Assert-ToolchainTest $missingHudPrefabPathRejected `
    "The repeated PlayerHud guessed-prefab path is no longer rejected by central preflight before native rg execution."
$discoveredPlayerHudPrefab = @(Find-UnityMigrationFiles -Root $root `
    -SearchRoot "unityclient/Assets/ProjectX" `
    -Pattern '[\\/]Prefabs[\\/]common[\\/]UImainLayer_new\.prefab$')
Assert-ToolchainTest (
    $discoveredPlayerHudPrefab.Count -eq 1 -and
    (Test-Path -LiteralPath $discoveredPlayerHudPrefab[0] -PathType Leaf)
) "Central file discovery no longer resolves the PlayerHud prefab from a verified root without guessed directories."
$playerHudPromptNodes = @(Find-UnityMigrationJsonNodes -Root $root `
    -JsonPath "unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/common/UImainLayer_new.json" `
    -Name "Prompt")
Assert-ToolchainTest (
    $playerHudPromptNodes.Count -gt 3 -and
    @($playerHudPromptNodes | Where-Object {
        $_.Path -match 'btn_Zhekou[1-3]/Prompt$' -and $_.Active -eq $true
    }).Count -eq 3
) "Central compiled JSON-node discovery cannot audit large imported UI IR without ConvertFrom-Json traversal."
Assert-ToolchainTest (
    $commonSource.Contains('error CS0009:.*Assembly-CSharp\.ref\.dll.*being used by another process') -and
    $commonSource.Contains('error CS2012:.*Assembly-CSharp(?:-Editor)?\.dll.*being used by another process') -and
    $commonSource.Contains('PostProcessing failed: System\.IO\.IOException:.*Library\\Bee\\artifacts.*being used by another process') -and
    $commonSource.Contains('IOException:\s*Sharing violation on path .*Library\\ScriptAssemblies\\Assembly-CSharp(?:-Editor)?\.dll') -and
    $commonSource.Contains('if ($process.ExitCode -eq 0 -and -not $transientBeeLock) { break }') -and
    $commonSource.Contains('Get-Process dotnet,bee_backend,Unity.ILPP.Trigger') -and
    $commonSource.Contains('transient-bee-lock-attempt1.log') -and
    $commonSource.Contains('retrying the same compile preflight once even if Unity recovered with exit code 0')
) "Compile preflight no longer performs the bounded same-tool retry for proven transient Unity compile/reload locks, including a recovered exit-code-zero run."
$bootstrapBuilderSource = Get-Content -Raw -Encoding UTF8 -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/Editor/BootstrapSceneBuilder.cs")
Assert-ToolchainTest (
    $bootstrapBuilderSource.Contains('NormalizeBootstrapSceneYaml();') -and
    $bootstrapBuilderSource.Contains("line.TrimEnd(' ', '\t')") -and
    $bootstrapBuilderSource.Contains('new UTF8Encoding(false)')
) "BootstrapSceneBuilder no longer normalizes generated Unity YAML trailing whitespace before idempotence and commit checks."
$resultSummaryPaths = @(
    ".local/unity-validation/toolchain-result-summary-test-a.json",
    ".local/unity-validation/toolchain-result-summary-test-b.json"
)
try {
    Write-UnityMigrationUtf8 -Path (Resolve-UnityMigrationPath -Root $root -Path $resultSummaryPaths[0]) -Content @'
{"success":true,"validatedControlIds":["A","B"],"semanticAssertions":[{"passed":true}],"screenshots":["a.png"],"seriousErrorCount":0,"fixtureResidualCount":0,"message":"ok-a"}
'@
    Write-UnityMigrationUtf8 -Path (Resolve-UnityMigrationPath -Root $root -Path $resultSummaryPaths[1]) -Content @'
{"success":false,"validatedControlIds":["C"],"passedSemanticAssertions":["one"],"failedSemanticAssertions":["two"],"screenshots":[],"seriousErrorCount":1,"fixtureResidualCount":2,"message":"bad-b"}
'@
    $resultSummaryRows = @(Get-UnityMigrationValidationResultSummaries -Root $root -ResultPaths $resultSummaryPaths)
    Assert-ToolchainTest (
        $resultSummaryRows.Count -eq 2 -and
        $resultSummaryRows[0].validatedControlCount -eq 2 -and
        $resultSummaryRows[0].failedSemanticAssertionCount -eq 0 -and
        $resultSummaryRows[1].semanticAssertionCount -eq 2 -and
        $resultSummaryRows[1].failedSemanticAssertionCount -eq 1 -and
        $resultSummaryRows[1].seriousErrorCount -eq 1 -and
        $resultSummaryRows[1].fixtureResidualCount -eq 2
    ) "Central multi-result summary no longer materializes foreach output before callers format it."
}
finally {
    foreach ($resultSummaryPath in $resultSummaryPaths) {
        $resolvedResultSummaryPath = Resolve-UnityMigrationPath -Root $root -Path $resultSummaryPath
        if (Test-Path -LiteralPath $resolvedResultSummaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $resolvedResultSummaryPath -Force
        }
    }
}
$mcpSseFixture = @'
event: message
data: {"jsonrpc":"2.0","method":"notifications/message","params":{"level":"info"}}

event: message
data: {"jsonrpc":"2.0","id":7,"result":{"contents":[{"text":"{}"}]}}

'@
$mcpSseReply = Get-UnityMigrationMcpSseMessage -Content $mcpSseFixture -Id 7
Assert-ToolchainTest (
    [int]$mcpSseReply.id -eq 7 -and
    @($mcpSseReply.result.contents).Count -eq 1
) "Unity MCP SSE parsing no longer ignores notifications that precede the matching JSON-RPC response."
Assert-ToolchainTest (
    $commonSource.Contains('function Connect-UnityMigrationMcpSession') -and
    $commonSource.Contains('function Read-UnityMigrationMcpResource') -and
    $commonSource.Contains('Mcp-Session-Id')
) "Shared Unity MCP Streamable HTTP readiness helpers are missing."

$g5PreflightSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Test-UnityModuleG5Preflight.ps1") `
    -Raw -Encoding UTF8
$g5EvidenceSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "New-UnityModuleG5Evidence.ps1") `
    -Raw -Encoding UTF8
$docsTestSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Test-UnityMigrationDocs.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $g5PreflightSource.Contains('Get-UnityMigrationPropertyValue -Object $contract -Name "fixedAccount"') -and
    $docsTestSource.Contains('Get-UnityMigrationPropertyValue -Object $contract -Name "fixedAccount"') -and
    $g5EvidenceSource.Contains('primaryUserId') -and
    $g5EvidenceSource.Contains('primaryRoleId')
) "Client-local no-server-fixture G5 contracts are no longer supported by the shared evidence tools."

$scaffoldSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "New-UnityMigrationModule.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $scaffoldSource.Contains('[switch]$IncludeImplementationSkeleton') -and
    $scaffoldSource.Contains('RequiredGate G2') -and
    $scaffoldSource.Contains('-not $IncludeImplementationSkeleton')
) "New module scaffolding can create implementation code before G2 or rewrite planning registries during implementation scaffolding."

$manifestForWorkflow = (Import-UnityMigrationManifest -Root $root).Value
$worldModule = @($manifestForWorkflow.modules | Where-Object { $_.key -eq "World" }) | Select-Object -First 1
$worldScenario = Get-UnityMigrationScenario -Root $root -ModuleKey "World"
Assert-ToolchainTest (
    $null -ne (Assert-UnityMigrationModuleWorkflowContract -Root $root `
        -ModuleConfig $worldModule -Scenario $worldScenario -Phase G3)
) "The completed World module no longer satisfies the hardened G3 workflow contract."

Write-Host "Unity migration toolchain tests passed: $passed"
