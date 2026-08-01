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
$operationLedger.records[1].iterationEvidence = @()
Assert-ToolchainTest (
    @(Get-UnityMigrationRetrospectiveFailures -Ledger $operationLedger).Count -eq 1
) "Failure without iteration evidence did not block retrospective completion."

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
Assert-ToolchainTest (
    $gateSource.Contains("Completing G1 requires -CocosAutomationLedgerPath") -and
    $gateSource.Contains("Completing G4 requires -SummaryPath") -and
    $gateSource.Contains("Assert-UnityMigrationSourceAudit") -and
    $gateSource.Contains("Test-UnityModuleG5Preflight.ps1") -and
    $gateSource.Contains("New-UnityMigrationRetrospective")
) "G1/G2/G4/G5/G6 workflow or automatic retrospective enforcement disappeared from the migration gate."

$moduleRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityModuleValidation.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $moduleRunnerSource.Contains('executionMode = "batch"') -and
    $moduleRunnerSource.Contains('$ValidationMode -eq "Preflight"') -and
    $moduleRunnerSource.Contains('"-projectXUserId=<auto-isolated>"')
) "Standard Unity runner no longer records batch execution or an accurate preflight account plan."

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
