[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$passed = 0
$commonSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "UnityMigration.Common.ps1") -Raw -Encoding UTF8
$gameplayFixtureSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Invoke-GameplayFixedAccountFixture.ps1") -Raw -Encoding UTF8
$fixedAccountRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityFixedAccountValidation.ps1") -Raw -Encoding UTF8
$moduleRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityModuleValidation.ps1") -Raw -Encoding UTF8

function Assert-ToolchainTest {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) { throw $Message }
    $script:passed++
}

Assert-ToolchainTest (
    $commonSource.Contains('$expectedControls.Count -gt 0 -and $actualControls.Count -eq 0') -and
    $commonSource.Contains('Runtime control coverage mismatch: expected=$($expectedControls.Count) actual=0')
) "Runtime coverage validation can regress to a Compare-Object null-binding error for empty actual controls."

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
Assert-ToolchainTest (
    $gameplayFixtureSource.Contains('configMutationCount=0') -and
    -not $gameplayFixtureSource.Contains('Set-PreserveLevelUserId') -and
    -not $gameplayFixtureSource.Contains('server\config\config') -and
    $gameplayFixtureSource.Contains('.local\gameplay-server-validation') -and
    $gameplayFixtureSource.Contains('local_preserve_level_user_id') -and
    $gameplayFixtureSource.Contains('local_preserve_balance_user_id') -and
    $gameplayFixtureSource.Contains('AssertReloginHash') -and
    $gameplayFixtureSource.Contains('postLoginHash')
) "Gameplay no-server fixture again mutates the protected C++ server config."
Assert-ToolchainTest (
    $fixedAccountRunnerSource.Contains('-Object $fixed -Name "requiredHydratedRoots" -Default @()') -and
    -not $fixedAccountRunnerSource.Contains('$fixed.requiredHydratedRoots | ForEach-Object') -and
    $fixedAccountRunnerSource.Contains('-Object $contracts -Name "fixedAccountDefaults" -Default $null') -and
    $fixedAccountRunnerSource.Contains('$globalRequiredHydratedRoots + $moduleRequiredHydratedRoots') -and
    $fixedAccountRunnerSource.Contains('-Name "requiredHydratedUiDocuments" -Default @()') -and
    $fixedAccountRunnerSource.Contains('Get-FixedUiDocumentAssetPaths') -and
    $fixedAccountRunnerSource.Contains('$fontAssetPath') -and
    $fixedAccountRunnerSource.Contains("'.ttf', '.otf'") -and
    $fixedAccountRunnerSource.Contains('Required UI document asset is missing:')
) "Fixed-account runner no longer supports optional hydrated roots plus recursive UI image/font dependencies."
Assert-ToolchainTest (
    $commonSource.Contains('function Get-UnityMigrationRuntimeRoots') -and
    $commonSource.Contains('function Test-UnityMigrationWorkspaceMySqlOwnership') -and
    $fixedAccountRunnerSource.Contains('Test-UnityMigrationWorkspaceMySqlOwnership -Root $root -ProcessId $mysqlListenerPid') -and
    $moduleRunnerSource.Contains('Test-UnityMigrationWorkspaceMySqlOwnership -Root $root -ProcessId $listenerPid')
) "Unity validation runners no longer recognize a command-line-proven workspace-local MySQL owned by the primary checkout from a Git worktree."

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

$rootCauseRules = (Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/root-cause-rules.json").Value
Assert-ToolchainTest (
    [int]$rootCauseRules.schemaVersion -eq 1 -and @($rootCauseRules.rules).Count -ge 6
) "Central root-cause rule registry is missing or undersized."
foreach ($rule in @($rootCauseRules.rules)) {
    Assert-ToolchainTest (
        [string]$rule.ruleId -match '^RC-' -and
        [string]$rule.requiredAction -and
        @($rule.rootCausePatterns).Count -gt 0
    ) "Root-cause rule is incomplete: $($rule.ruleId)"
    foreach ($pattern in @($rule.rootCausePatterns)) {
        try { [void][regex]::new([string]$pattern) }
        catch { throw "Root-cause rule '$($rule.ruleId)' has invalid regex '$pattern': $($_.Exception.Message)" }
    }
}
$moduleScaffoldSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "New-UnityMigrationModule.ps1") -Raw -Encoding UTF8
$gateSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Invoke-UnityMigrationGate.ps1") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $commonSource.Contains('function New-UnityMigrationG0Draft') -and
    $commonSource.Contains('function Assert-UnityMigrationG0Draft') -and
    -not $commonSource.Contains('$matches = New-Object System.Collections.Generic.List[object]') -and
    $moduleScaffoldSource.Contains('Export-CocosCurrentInventory.py') -and
    $moduleScaffoldSource.Contains('Get-ProtocolEvidence.ps1')
) "Future-module G0 draft no longer composes current inventory and protocol evidence."
Assert-ToolchainTest (
    $gateSource.Contains('[switch]$StartTiming') -and
    $gateSource.Contains('Historical gates were not backfilled') -and
    $commonSource.Contains('historicalBackfill = $false') -and
    $commonSource.Contains('machineTimingReports')
) "Future-only gate timing or retrospective timing separation was removed."

$manifest = (Import-UnityMigrationManifest -Root $root).Value
$unityExecutable = Resolve-UnityMigrationUnityExecutable -Root $root -Manifest $manifest
Assert-ToolchainTest (Test-Path -LiteralPath $unityExecutable -PathType Leaf) `
    "Portable Unity executable resolution did not return an existing editor."
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
$hardGateSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Test-UnityMigrationHardGates.ps1") `
    -Raw -Encoding UTF8
$commonSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "UnityMigration.Common.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $hardGateSource.Contains("Scenario '`$(`$scenario.key)' contains duplicate capture states.") -and
    -not $hardGateSource.Contains('-MinimumCaptureStates `$captureStates.Count') -and
    -not $commonSource.Contains('[int]$MinimumCaptureStates')
) "Hard gates again conflate independent capture-state and control denominators."
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
$invalidWorkflowPolicy.sequence.requireEarlyUserPlayAfterG3BeforeG4 = $false
$workflowFailures = @(Get-UnityMigrationWorkflowPolicyFailures -Policy $invalidWorkflowPolicy)
Assert-ToolchainTest (
    @($workflowFailures | Where-Object { $_ -like "*maximumAttemptsPerTarget*" }).Count -eq 1
) "Repeated Cocos target attempts were not rejected by workflow policy."
Assert-ToolchainTest (
    @($workflowFailures | Where-Object { $_ -like "*runtimeValidationMode*batch-only*" }).Count -eq 1
) "Non-batch Unity runtime validation was not rejected by workflow policy."
Assert-ToolchainTest (
    @($workflowFailures | Where-Object { $_ -like "*requireEarlyUserPlayAfterG3BeforeG4*" }).Count -eq 1
) "Missing post-G3 early user Play checkpoint was not rejected by workflow policy."
$validEarlyUserPlay = [pscustomobject]@{
    schemaVersion = 1
    module = "Sample"
    checkpoint = "post-g3-early-play"
    userParticipated = $true
    testedUtc = "2026-08-22T12:00:00+08:00"
    entryPath = "主界面→功能入口"
    result = "feedback-captured"
    feedback = @([pscustomobject]@{
        id = "EARLY-001"; summary = "返回层级错误"; severity = "blocking"; status = "resolved"
    })
    agentRecheck = [pscustomobject]@{ completed = $true; evidence = @("build/ui-migration/bootstrap-app-result.json") }
}
Assert-ToolchainTest (
    @(Get-UnityMigrationEarlyUserPlayFailures -Record $validEarlyUserPlay -ExpectedModule "Sample").Count -eq 0
) "Valid post-G3 early user Play evidence was rejected."
$invalidEarlyUserPlay = $validEarlyUserPlay | ConvertTo-Json -Depth 8 | ConvertFrom-Json
$invalidEarlyUserPlay.feedback[0].status = "pending"
Assert-ToolchainTest (
    @(Get-UnityMigrationEarlyUserPlayFailures -Record $invalidEarlyUserPlay -ExpectedModule "Sample" |
        Where-Object { $_ -like "*must be resolved before G4*" }).Count -eq 1
) "Unresolved blocking early user feedback did not block G4."
$networkScenario = [pscustomobject]@{
    flags = @("-projectXSampleValidation")
    networkValidation = [pscustomobject]@{ disableAutoReconnect = $true; showReconnectDialog = $true }
}
$networkFlags = @(Get-UnityMigrationScenarioRuntimeFlags -Scenario $networkScenario)
Assert-ToolchainTest (
    $networkFlags -contains "-projectXSampleValidation" -and
    $networkFlags -contains "-projectXScenarioManagedReconnect"
) "Scenario network capability did not produce the generic managed-reconnect runtime flag."
$bootstrapRunnerSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $bootstrapRunnerSource.Contains('bool scenarioManagedReconnect = Array.IndexOf(Environment.GetCommandLineArgs(), "-projectXScenarioManagedReconnect") >= 0;') -and
    $bootstrapRunnerSource.Contains('reconnectValidation || manualReconnectValidation || scenarioManagedReconnect')
) "Bootstrap runner no longer honors the generic scenario-managed reconnect flag."
$bagRunnerSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs") -Raw -Encoding UTF8
$bagControllerSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/Resources/Lua/Bag/BagController.lua.txt") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $bagRunnerSource.Contains('if (invoked && HasCommandLineFlag("-projectXBagG4Validation"))') -and
    $bagRunnerSource.Contains('MarkValidationControl("BAG-01-MAIN-ENTRY");') -and
    $bagRunnerSource.Contains('MarkValidationControl("BAG-04-LIST-ITEM");') -and
    $bagRunnerSource.Contains('MarkValidationControl(controlId);') -and
    -not $bagRunnerSource.Contains('foreach (string control in bagControls) MarkValidationControl(control);')
) "Bag coverage no longer records only controls reached through real entry, item and bound-control callbacks."
$bagSemanticKeys = @(
    "bag-current-main-entry", "bag-authoritative-full-and-incremental", "bag-duplicate-slot-aggregation",
    "bag-type-dispatch", "bag-direct-use-authority", "bag-random-equipment-box-authority",
    "bag-random-equipment-box-feedback", "bag-random-equipment-box-config-family",
    "bag-batch-use-bounds", "bag-choice-use-authority",
    "bag-source-route-boundary", "bag-disabled-excluded-target", "bag-selection-scroll-refresh",
    "bag-network-recovery", "bag-account-isolation", "bag-fixture-exact-restore", "bag-control-matrix-26"
)
Assert-ToolchainTest (
    @($bagSemanticKeys | Where-Object { -not $bagRunnerSource.Contains("RecordValidationSemantic(`"$_`"") }).Count -eq 0
) "Bag runtime no longer records every required semantic at its asserted business checkpoint."
$bagEvidenceContract = @((Get-Content -LiteralPath `
    (Join-Path $root "tools/unity-migration/module-evidence-contracts.json") -Raw -Encoding UTF8 |
    ConvertFrom-Json).modules | Where-Object { $_.module -eq "Bag" })[0]
Assert-ToolchainTest (
    $bagEvidenceContract.fixedAccount.skipPostValidationFixtureAssert -eq $true
) "Bag fixed-account runner again requires the pristine Setup package after authoritative item consumption."
$fixedAccountRunnerSource = Get-Content -LiteralPath `
    (Join-Path $root "tools/unity-migration/Run-UnityFixedAccountValidation.ps1") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $fixedAccountRunnerSource.Contains('[string]$ServerExecutable = ""') -and
    $fixedAccountRunnerSource.Contains('$serverStartParameters.ExePath = $resolvedServerExecutable') -and
    $fixedAccountRunnerSource.Contains('Explicit fixed-account server executable is missing:') -and
    $fixedAccountRunnerSource.Contains('[switch]$G3RuntimeOnly') -and
    $fixedAccountRunnerSource.Contains('validationMode = "g3-runtime"') -and
    @($bagEvidenceContract.fixedAccount.g3ValidationFlags) -contains '-projectXBagG3Validation' -and
    $fixedAccountRunnerSource.Contains('Required Unity assets are unresolved Git LFS pointers:') -and
    $fixedAccountRunnerSource.Contains('function Wait-FixedRuntimeRelease') -and
    $fixedAccountRunnerSource.Contains('[IO.FileShare]::None') -and
    $fixedAccountRunnerSource.Contains('Fixed-account runtime did not release processes/SQLite before restore:') -and
    $fixedAccountRunnerSource.Contains('try { Invoke-FixedAdapter "AssertReloginHash" }') -and
    @($bagEvidenceContract.fixedAccount.requiredHydratedRoots).Count -eq 6 -and
    @($bagEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/res/res/UI' -and
    @($bagEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/Sliced' -and
    @($bagEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/Marked' -and
    @($bagEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/res/xiaokaiSJ2.ttf'
) "Independent-worktree regression: fixed-account runner cannot use an explicit read-only server runtime binary."
$bagSqliteAdapterSource = Get-Content -LiteralPath `
    (Join-Path $root "tools/unity-migration/Invoke-BagSqliteFixture.py") -Raw -Encoding UTF8
$bagCocosAdapterSource = Get-Content -LiteralPath `
    (Join-Path $root "tools/unity-migration/Invoke-BagCocosFixture.ps1") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $bagSqliteAdapterSource.Contains('"packageSha256": hashlib.sha256(role[0].encode("ascii")).hexdigest()') -and
    $bagSqliteAdapterSource.Contains('elif args.action == "AssertReloginHash":') -and
    $bagSqliteAdapterSource.Contains('remove_sqlite_sidecars(database)') -and
    $bagSqliteAdapterSource.Contains('for suffix in ("-wal", "-shm")') -and
    $bagSqliteAdapterSource.Contains('current["packageSha256"] != expected["packageSha256"]') -and
    $bagSqliteAdapterSource.Contains('FIXTURE_SPIRIT = 50') -and
    $bagSqliteAdapterSource.Contains('while position < len(data):') -and
    $bagSqliteAdapterSource.Contains('if len(records) >= 500:') -and
    $bagSqliteAdapterSource.Contains('while len(records) < 500:') -and
    $bagSqliteAdapterSource.Contains('(1112, 2), (1111, 3), (1114, 3)') -and
    $bagSqliteAdapterSource.Contains('(3201, 1)') -and
    $bagCocosAdapterSource.Contains('@(1112, 2), @(1111, 3), @(1114, 3)') -and
    $bagCocosAdapterSource.Contains('@(3201, 1)') -and
    $bagCocosAdapterSource.Contains('1111=3;1114=3;3201=1') -and
    $bagSqliteAdapterSource.Contains('UPDATE role_info SET package=?,user_spirit=? WHERE id=?') -and
    $bagSqliteAdapterSource.Contains('SPIRIT_FULL = 100') -and
    $bagSqliteAdapterSource.Contains('SPIRIT_REGEN_SECONDS = 360') -and
    $bagSqliteAdapterSource.Contains('def relogin_spirit_matches(expected, current):') -and
    $bagSqliteAdapterSource.Contains('or not spirit_matches') -and
    $bagSqliteAdapterSource.Contains('postLoginBusinessStateVerified') -and
    $bagSqliteAdapterSource.Contains('postLoginSpiritOracle')
) "Bag SQLite relogin regression: package or deterministic stamina business state is no longer prepared and restored."
Assert-ToolchainTest (
    $bagRunnerSource.Contains('if (!SelectBagItem(1111) || !InvokeBagControl("BAG-07-USE") || !IsBagGiftOpen)') -and
    -not $bagRunnerSource.Contains('SelectBagItem(1114)') -and
    $bagRunnerSource.Contains('InvokeBagControl("BAG-15-GIFT-ADD-ONE");') -and
    $bagRunnerSource.Contains('BagModalQuantity != 2') -and
    $bagRunnerSource.Contains('bagG4InitialGiftQuantity - 2') -and
    $bagRunnerSource.Contains('bagG4InitialRewardQuantity + 2') -and
    $bagRunnerSource.Contains('bagUseRewardFilterItemId = item.ItemType == 6') -and
    $bagRunnerSource.Contains('bagFlowPresenter?.SelectedChoiceId ?? 0') -and
    $bagRunnerSource.Contains('if (bagUseRewardFilterItemId > 0 && itemId != bagUseRewardFilterItemId) return;') -and
    $bagRunnerSource.Contains('ValidateVisibleRewards("开启获得", expectedChoicePopup, out choicePopupDetail)') -and
    $bagRunnerSource.Contains('Bag G4 selectable gift reward popup did not close through EventSystem.') -and
    $bagRunnerSource.Contains('rendered complete 开启获得 name/quantity, and closed through EventSystem')
) "Bag choice acceptance regression: item1111 quantity3 no longer consumes two, receives reward4621, and proves the authoritative reward popup through real controls."
Assert-ToolchainTest (
    $bagRunnerSource.Contains('if (!SelectBagItem(1001)) { Fail("Bag G5 scrolled state could not select the frozen high recruit ticket 1001."); yield break; }') -and
    $bagRunnerSource.IndexOf('SelectBagItem(1001)', [System.StringComparison]::Ordinal) -lt
        $bagRunnerSource.IndexOf('InvokeBagControl("BAG-05-LIST-SCROLL")', [System.StringComparison]::Ordinal)
) "Bag G5 scrolled-state regression: Cocos and Unity no longer freeze the same selected business ID before scrolling."
Assert-ToolchainTest (
    $bagRunnerSource.Contains('if (!SelectBagItem(500))') -and
    $bagRunnerSource.Contains('Bag G4 could not restore batch item 500 after the frozen scrolled-state capture.') -and
    $bagRunnerSource.IndexOf('Bag G4 could not restore batch item 500 after the frozen scrolled-state capture.', [System.StringComparison]::Ordinal) -lt
        $bagRunnerSource.IndexOf('if (!InvokeBagControl("BAG-07-USE") || !IsBagInputOpen)', [System.StringComparison]::Ordinal)
) "Bag click-state regression: the visual scrolled-state selection leaked into the real batch-use control."
Assert-ToolchainTest (
    $bagRunnerSource.Contains('bool preserveBagForScenario = HasCommandLineFlag("-projectXBagG4Validation") && IsBagOpen;') -and
    $bagRunnerSource.Contains('case "BAG-01-ENTRY": artifactName = "bootstrap-bag.png";') -and
    $bagRunnerSource.Contains('ShowToast("重新连接成功", 2f);') -and
    $bagRunnerSource.Contains('if (!bagInitialG5DisconnectCaptured)') -and
    $bagRunnerSource.Contains('WaitForBagTransientOverlayToSettle("BAG-01-ENTRY")') -and
    $bagRunnerSource.Contains('initialReenter.onClick.Invoke();') -and
    $bagRunnerSource.Contains('CaptureBagG5Evidence("BAG-01-PERSISTENCE-REENTER")') -and
    $bagRunnerSource.Contains('CaptureBagG5Evidence("BAG-01-PERSISTENCE-RECONNECT")') -and
    $bagRunnerSource.Contains('CaptureBagG5Evidence("BAG-01-DISCONNECTED")') -and
    $bagRunnerSource.Contains('CaptureBagG5Evidence("BAG-01-PERSISTENCE-DISCONNECTED")') -and
    $bagRunnerSource.Contains('mainHudPresenter?.HasVisibleSystemChatSummary == true') -and
    -not $bagRunnerSource.Contains('if (!bagInitialG5ReconnectCaptured)') -and
    $bagRunnerSource.Contains('case "BAG-20-EQUIPMENT-SOURCE": artifactName = "bootstrap-bag-source.png";')
) "Bag G5 capture no longer keeps normal states before the first reconnect or preserves the distinct final disconnect/reconnect states."
Assert-ToolchainTest (
    $bagRunnerSource.Contains('StartCoroutine(RunBagG4DirectUseRoutine());') -and
    $bagRunnerSource.Contains('private IEnumerator RunBagG4DirectUseRoutine()') -and
    $bagRunnerSource.Contains('yield return null;') -and
    $bagRunnerSource.Contains('InvokeBagInputDigit(1)') -and
    $bagRunnerSource.Contains('BagModalQuantity != 1') -and
    $bagRunnerSource.Contains('if (bagG4DirectUseScheduled) return true;') -and
    $bagRunnerSource.Contains('bagG4DirectUseScheduled = true;') -and
    $bagRunnerSource.Contains('InvokeBagControl("BAG-10-INPUT-CONFIRM")') -and
    $bagRunnerSource.Contains('injected direct-use item did not confirm quantity one through EnterNumLayer')
) "Bag G4 injected direct-use regression: Lua packet callback again re-enters synchronously or quantity two stalls in EnterNumLayer."
Assert-ToolchainTest (
    $bagRunnerSource.Contains('if (!InvokeEventSystemClick(itemControl))') -and
    $bagRunnerSource.Contains('if (!InvokeEventSystemClick(bagPresenter?.UseControl))') -and
    $bagRunnerSource.Contains('InvokeEventSystemClick(bagFlowPresenter?.GetInputDigitControl(1))') -and
    $bagRunnerSource.Contains('InvokeEventSystemClick(bagFlowPresenter?.InputConfirmControl)') -and
    $bagRunnerSource.Contains('box {boxItemId} did not confirm quantity one through the real EventSystem control')
) "Bag G4 equipment-box regression: quantity-two boxes bypass or omit the real EventSystem quantity-one flow."
Assert-ToolchainTest (
    $bagControllerSource.Contains('elseif M.g4Stage == "await_direct_consume" and slot == M.validationSlot then') -and
    -not [regex]::IsMatch($bagControllerSource,
        'await_direct_consume" and slot == M\.validationSlot then\s*M\.onUse\(',
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
) "Bag G4 direct-use regression: the authoritative /15 callback consumes item3201 a second time instead of sorting and reloading."
$bagFlowSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/UI/BagFlowPresenter.cs") -Raw -Encoding UTF8
$bagPresenterSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/UI/BagPresenter.cs") -Raw -Encoding UTF8
$bagRewardSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/UI/RewardPresenter.cs") -Raw -Encoding UTF8
$bagStoreSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/Data/BagStore.cs") -Raw -Encoding UTF8
$bootstrapIdempotenceSource = Get-Content -LiteralPath `
    (Join-Path $root "tools/unity-migration/Test-BootstrapSceneIdempotence.ps1") -Raw -Encoding UTF8
$gameErrorSource = Get-Content -LiteralPath `
    (Join-Path $root "unityclient/Assets/ProjectX/src/UI/GameErrorPresenter.cs") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $bagRunnerSource.Contains('bagFlowPresenter?.SelectedChoiceId != 4621') -and
    $bagRunnerSource.Contains('bagFlowPresenter.SourceChoiceId != 4621') -and
    $bagRunnerSource.Contains('frozen gift1111 choice0 fragment4621') -and
    -not $bagRunnerSource.Contains('SelectBagItem(1112);') -and
    $bagFlowSource.Contains('public int SelectedChoiceId => selectedChoice?.Id ?? 0;') -and
    $bagFlowSource.Contains('public int SourceChoiceId => sourceChoice?.Id ?? 0;')
) "Bag G5 business-ID regression: SOURCE and EQUIPMENT-INFO no longer preserve gift1111 choice0 fragment4621."
Assert-ToolchainTest (
    $bagPresenterSource.Contains('public int SelectedItemId => store.Items.FirstOrDefault(item => item.Slot == selectedSlot).ItemId;') -and
    $bagRunnerSource.Contains('bagPresenter?.SelectedItemId != boxItemId') -and
    $bagRunnerSource.IndexOf('bagPresenter?.SelectedItemId != boxItemId', [System.StringComparison]::Ordinal) -lt
        $bagRunnerSource.IndexOf('yield return CaptureBagG5Evidence(prefix + "-BEFORE");', [System.StringComparison]::Ordinal)
) "Bag G5 box BEFORE regression: evidence is captured before the requested box business ID settles."
Assert-ToolchainTest (
    $bagFlowSource.Contains('importedToggle.SetIsOnWithoutNotify(false)') -and
    $bagFlowSource.Contains('toggle.SetIsOnWithoutNotify(selected)') -and
    $bagFlowSource.Contains('string suffix = id > 9 ?') -and
    $bagFlowSource.Contains('name.resizeTextForBestFit = true;') -and
    $bagFlowSource.Contains('mask.color = new Color(0f, 0f, 0f, 0.95f);')
) "Bag G5 modal rendering no longer synchronizes gift selection, preserves full names, or darkens equipment stacking like Cocos."
Assert-ToolchainTest (
    $bagFlowSource.Contains('dragSurface.raycastTarget = true;') -and
    $bagRunnerSource.Contains('InvokeEventSystemHorizontalDrag(giftScroll)') -and
    $bagRunnerSource.Contains('giftScroll.content.rect.width <= giftScroll.viewport.rect.width + 1f') -and
    $bagRunnerSource.Contains('gift list accepted callbacks but did not move horizontally') -and
    $bagRunnerSource.Contains('EventSystem.current.RaycastAll(data, hits);')
) "Bag gift-scroll regression: the eight-choice viewport no longer proves a raycastable surface, real EventSystem drag, overflow, and visible horizontal movement."
Assert-ToolchainTest (
    $gameErrorSource.Contains('message.text.StartsWith("无法连接服务器", StringComparison.Ordinal)')
) "Connection failure confirmation no longer preserves the Cocos top-left message layout."
Assert-ToolchainTest (
    $bagStoreSource.Contains('LuaPrioritySort(visible, 0, visible.Count - 1);') -and
    $bagStoreSource.Contains('while (items[++left].SortPriority < pivot.SortPriority)') -and
    -not $bagStoreSource.Contains('.ThenBy(item => item.ItemId)')
) "Bag equal-priority ordering no longer follows the source Lua 5.1 table.sort permutation."
Assert-ToolchainTest (
    -not $bagRewardSource.Contains('NormalizeItemListLayout') -and
    -not $bagRewardSource.Contains('Require("ItemList").GetComponent<RectTransform>()') -and
    $bagRewardSource.Contains('ValidateVisibleRewards("') -eq $false -and
    $bagRewardSource.Contains('public bool ValidateVisibleRewards(') -and
    $bagRunnerSource.Contains('ValidateVisibleRewards("开启获得"') -and
    $bagRunnerSource.Contains('InvokeEventSystemClick(itemControl)') -and
    $bagRunnerSource.Contains('GetLocalUserId() != 1 || validationRoleIdSnapshot != 1000001') -and
    $bagRunnerSource.Contains('g5-20260824')
) "Bag random-box regression: imported reward layout is overwritten, fixed identity drifted, or 512/513/514 no longer use EventSystem and complete popup assertions."
Assert-ToolchainTest (
    $bootstrapIdempotenceSource.Contains('ILPostProcessorException|IOException:.*Assembly-CSharp|sharing violation|being used by another process') -and
    -not $bootstrapIdempotenceSource.Contains("'error CS\d+|Exception:|Compilation failed|Aborting batchmode'")
) "Bootstrap idempotence again treats Unity's recovered lingering-ILPP cleanup exception as a fatal build error."
$validCocosPreflight = [pscustomobject]@{
    module = "Sample"; tool = "computer-use@openai-bundled"
    targetProcess = "ProjectX.exe"; targetWindow = "Cocos Simulator"
    transportReady = $true; windowListed = $true; inputReady = $true
    captureContract = [pscustomobject]@{
        mode = "window-client-crop-no-scale"; clientX = 1; clientY = 26
        width = 1334; height = 750; noScale = $true
    }
}
Assert-ToolchainTest (
    @(Get-UnityMigrationCocosPreflightFailures -Evidence $validCocosPreflight -Module "Sample").Count -eq 0
) "Valid Computer Use transport/window/input preflight and no-scale client crop were rejected."
$invalidCocosPreflight = $validCocosPreflight | ConvertTo-Json -Depth 5 | ConvertFrom-Json
$invalidCocosPreflight.inputReady = $false
$invalidCocosPreflight.captureContract.clientY = 0
Assert-ToolchainTest (
    @(Get-UnityMigrationCocosPreflightFailures -Evidence $invalidCocosPreflight -Module "Sample").Count -eq 2
) "Incomplete Computer Use input preflight or wrong Cocos client crop was not rejected."

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
Assert-ToolchainTest (
    (Get-UnityMigrationEffectiveRootCause -FailedRecord $operationLedger.records[0] `
        -ResolutionRecords @($operationLedger.records[1])) -eq "observe fresh state"
) "Retrospective did not replace pending-diagnosis with the resolved effective root cause."
$ledgerTestPath = ".local/unity-validation/toolchain-operation-ledger-$([Guid]::NewGuid().ToString('N')).json"
try {
    $failedWrite = Add-UnityMigrationOperationRecord -Root $root -Module "ToolchainSample" -Gate G0 `
        -Tool "test" -Operation "fail" -Outcome Failed -ErrorMessage "failure" -RootCause "known" -Path $ledgerTestPath
    $textOnlyRejected = $false
    try {
        Add-UnityMigrationOperationRecord -Root $root -Module "ToolchainSample" -Gate G0 `
            -Tool "test" -Operation "resolve" -Outcome Resolved `
            -RelatedRecordId ([string]$failedWrite.Record.recordId) -Resolution "fixed" `
            -IterationAction "retest" -IterationEvidence @("text-only evidence") -Path $ledgerTestPath | Out-Null
    }
    catch { $textOnlyRejected = $_.Exception.Message -like "*every -IterationEvidence item*existing file*" }
    Assert-ToolchainTest $textOnlyRejected "Resolved operation accepted text-only iteration evidence instead of rejecting it immediately."
    Add-UnityMigrationOperationRecord -Root $root -Module "ToolchainSample" -Gate G0 `
        -Tool "test" -Operation "resolve" -Outcome Resolved `
        -RelatedRecordId ([string]$failedWrite.Record.recordId) -Resolution "fixed" `
        -IterationAction "retest" -IterationEvidence @("tools/unity-migration/Test-UnityMigrationToolchain.ps1") `
        -Path $ledgerTestPath | Out-Null
    Assert-ToolchainTest $true "File-backed resolution could not be written."
}
finally {
    $resolvedLedgerTestPath = Resolve-UnityMigrationPath -Root $root -Path $ledgerTestPath
    if (Test-Path -LiteralPath $resolvedLedgerTestPath) { Remove-Item -LiteralPath $resolvedLedgerTestPath -Force }
}
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
    @($bagEvidenceContract.g5.allowedDuplicateGroups).Count -eq 1 -and
    @($bagEvidenceContract.g5.allowedDuplicateGroups[0].ids) -contains 'BAG-POPULATED' -and
    @($bagEvidenceContract.g5.allowedDuplicateGroups[0].ids) -contains 'BAG-REENTER' -and
    @($bagEvidenceContract.fixedAccount.artifactCopies | Where-Object {
        $_.source -like '*BAG-01-PERSISTENCE-RECONNECT.png' -and $_.destination -like '*BAG-RECONNECTED.png'
    }).Count -eq 1
) "Bag G5 contract again reuses the populated bitmap for reconnect without declaring the proven reenter equivalence."
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
    $gateSource.Contains('Completing G1 requires -$($required[0])') -and
    $gateSource.Contains("Assert-UnityMigrationCocosBaseline") -and
    $gateSource.Contains("Completing G4 requires -SummaryPath") -and
    $gateSource.Contains("Assert-UnityMigrationSourceAudit") -and
    $gateSource.Contains("Test-UnityModuleG5Preflight.ps1") -and
    $gateSource.Contains("New-UnityMigrationRetrospective")
) "G1/G2/G4/G5/G6 workflow or automatic retrospective enforcement disappeared from the migration gate."
Assert-ToolchainTest (
    $gateSource.Contains("pendingDiagnosisCount") -and
    $commonSource.Contains("effectiveRootCause") -and
    $commonSource.Contains("require every -IterationEvidence item to resolve to an existing file")
) "G6 no longer requires effective diagnoses and file-backed resolution evidence."
Assert-ToolchainTest (
    $hardGateSource.Contains("G6 Computer Use runtime must be stopped after Cocos evidence") -and
    $hardGateSource.Contains("OpenAI\\Codex\\runtimes\\cua_node")
) "G6 no longer rejects a residual Computer Use runtime after native Cocos evidence collection."
Assert-ToolchainTest (
    $hardGateSource.Contains('Assert-UnityMigrationModuleWorkflowContract -Root $root -ModuleConfig $moduleConfig -Scenario $scenario -Phase G0') -and
    $hardGateSource.Contains('claims G2 passed with incomplete source audit') -and
    $hardGateSource.Contains('Assert-UnityMigrationModuleWorkflowContract -Root $root -ModuleConfig $moduleConfig -Scenario $scenario -Phase G3') -and
    $hardGateSource.Contains('Assert-UnityMigrationControlMatrix -Root $root -ModuleKey')
) "Hard-gate preflight no longer rejects stale G2/G3/G6 completion claims with weak workflow, source-audit or control contracts."
$gameplayMatrix = (Import-UnityMigrationJson -Root $root `
    -Path "docs/unityclient/matrices/GAMEPLAY_CONTROLS.json").Value
$allEvidenceContracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$gameplayEvidenceContract = @($allEvidenceContracts.modules |
    Where-Object { $_.module -eq "Gameplay" })[0]
$gameplayScenario = Get-UnityMigrationScenario -Root $root -ModuleKey "Gameplay"
$gameplayScenarioControlCount = Assert-UnityMigrationScenarioStateCoverage -Root $root -ModuleKey "Gameplay" `
    -Path "docs/unityclient/matrices/GAMEPLAY_CONTROLS.json" -Scenario $gameplayScenario
Assert-ToolchainTest (
    [int]$gameplayMatrix.hardGateVersion -eq 3 -and
    @($gameplayMatrix.controls | Where-Object {
        (Get-UnityMigrationControlVerificationKind -Matrix $gameplayMatrix -Control $_) -eq 'direct-control'
    }).Count -eq 8 -and
    $gameplayScenarioControlCount -eq 5 -and
    $commonSource.Contains('manualAcceptanceCurrent') -and
    $commonSource.Contains('must keep realEntryClick=false') -and
    @($gameplayMatrix.controls | Where-Object {
        (Get-UnityMigrationControlVerificationKind -Matrix $gameplayMatrix -Control $_) -eq 'scenario-state' -and
        $_.realEntryClick -ne $false
    }).Count -eq 0
) "Gameplay lifecycle/state entries again require fake realEntryClick=true or drifted from the registered batch capture-state contract."
Assert-ToolchainTest (
    @($allEvidenceContracts.fixedAccountDefaults.requiredHydratedRoots).Count -eq 1 -and
    @($allEvidenceContracts.fixedAccountDefaults.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX' -and
    @($gameplayEvidenceContract.fixedAccount.g3ValidationFlags).Count -eq 1 -and
    @($gameplayEvidenceContract.fixedAccount.g3ValidationFlags) -contains '-projectXGameplayValidation' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedRoots).Count -eq 4 -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/Resources/ProjectXStartup' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/Resources/GameplayIcons' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/res/res/UI/ui_login' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedRoots) -contains
        'unityclient/Assets/ProjectX/Resources/RoleBust/5_touxiang.png' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments).Count -eq 9 -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/Login/LoginBgLayer.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/Login/loginLayer.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/Login/SeverListLayer.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/Login/RoleCreateLayer.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/common/UImainLayer_new.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/common/UImain_cloudLayer.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/ChatLayer.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/shop/shop_bg.json' -and
    @($gameplayEvidenceContract.fixedAccount.requiredHydratedUiDocuments) -contains
        'unityclient/Assets/ProjectX/res/csd/UnityMigration/documents/common/ActivityLayer.json' -and
    [string]$gameplayEvidenceContract.fixedAccount.serverConfigDirectory -eq
        '.local/gameplay-server-validation'
) "Global or Gameplay fixed-account contract no longer declares complete Unity art hydration plus the canonical Gameplay runtime flag."
$invalidScenarioState = [pscustomobject]@{ captureStates = @('registered-state') }
$invalidScenarioRejected = $false
try {
    Assert-UnityMigrationScenarioStateCoverage -Root $root -ModuleKey "Gameplay" `
        -Path "docs/unityclient/matrices/GAMEPLAY_CONTROLS.json" -Scenario $invalidScenarioState | Out-Null
}
catch {
    $invalidScenarioRejected = $_.Exception.Message -like "*references unregistered capture state*"
}
Assert-ToolchainTest $invalidScenarioRejected `
    "Scenario-state verification no longer rejects capture states missing from the canonical batch scenario."
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
    $projectXAppSource.Contains('bagEquipmentInfoView = bagEquipmentInfoView ?? services.UiRouter.FindBySource("zhuangbeiyangcheng/zhuangbeiInfo")') -and
    $projectXAppSource.Contains('?? UiPrefabLoader.Load("HeroEquipmentDetail", GetDynamicUiRoot());') -and
    $projectXAppSource.Contains('capturingBagUseRewards = item.ItemType == 5 || item.ItemType == 6;')
) "Bag lost its dynamic equipment-detail surface or post-open reward feedback for random/selectable boxes."
Assert-ToolchainTest (
    $projectXAppSource.Contains('public void SendUntracked(LegacyTcpMessage message)') -and
    $playerHudTempActivitySource.Contains('do not initiate /222 op4 or op89-91 from the Steam HUD') -and
    -not $playerHudTempActivitySource.Contains('Bridge:SendUntracked(discount)') -and
    $projectXAppSource.Contains('if (CurrentAppState == AppState.Disconnected) return;') -and
    $projectXAppSource.Contains('services.ProtocolRegistry.ClearPending();') -and
    $networkServiceSource.Contains('public void Disconnect(string reason = "Disconnected by client.")') -and
    $networkServiceSource.Contains('Disconnected?.Invoke(reason);') -and
    $projectXAppSource.Contains('services.Network.Disconnect("PlayerHud deliberate disconnect")')
) "PlayerHud optional silent activity queries or idempotent deliberate-disconnect cleanup regressed."

$mainHudPresenterSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/UI/MainHudPresenter.cs" -PathType Leaf) -Raw -Encoding UTF8
$cocosUiBindingSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/UI/Migration/CocosUiBinding.cs" -PathType Leaf) -Raw -Encoding UTF8
$uiRouterSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/UI/UiRouter.cs" -PathType Leaf) -Raw -Encoding UTF8
$firstPlayableLoopSource = Get-Content -LiteralPath `
    (Resolve-UnityMigrationExistingPath -Root $root `
        -Path "unityclient/Assets/ProjectX/src/LuaRuntime/FirstPlayableLoopBridge.cs" -PathType Leaf) -Raw -Encoding UTF8
Assert-ToolchainTest (
    $projectXAppSource.Contains('public const string RankingPath = "Layer/Main_UI/ButtonGroup1/btn_paihangbang";') -and
    $projectXAppSource.Contains('public const string DrawPath = "Layer/Main_UI/ButtonGroup1/btn_zhaomu";') -and
    $projectXAppSource.Contains('public const string GameplayPath = "Layer/Main_UI/ButtonGroup1/btn_wanfa";') -and
    $cocosUiBindingSource.Contains('Transform hierarchyTarget = transform.Find(cocosPath);') -and
    $cocosUiBindingSource.Contains('cocosPath.StartsWith("Layer/", StringComparison.Ordinal)') -and
    $cocosUiBindingSource.Contains('transform.Find(cocosPath.Substring("Layer/".Length))') -and
    $uiRouterSource.Contains('public const string MainHudSourceToken = "common/UImainLayer_new";') -and
    $projectXAppSource.Contains('FindBySource(UiRouter.MainHudSourceToken, true)') -and
    -not $projectXAppSource.Contains('FindBySource("UImainLayer", true)') -and
    $firstPlayableLoopSource.Contains('FindBySource(UiRouter.MainHudSourceToken, true)') -and
    -not $firstPlayableLoopSource.Contains('FindBySource("UImainLayer", true)')
) "Unity-authored ButtonGroup1 controls no longer resolve through their current hierarchy paths."
foreach ($steamHiddenCommercialPath in @(
    'Layer/Main_UI/ButtonGroup4/btn_Qiri',
    'Layer/Main_UI/ButtonGroup4/btn_shouchong',
    'Layer/Main_UI/ButtonGroup1/btn_chongzhi',
    'Layer/Main_UI/ButtonGroup8/btn_Zhekou1',
    'Layer/Main_UI/ButtonGroup8/btn_Zhekou2',
    'Layer/Main_UI/ButtonGroup8/btn_Zhekou3'
)) {
    Assert-ToolchainTest ($projectXAppSource.Contains('"' + $steamHiddenCommercialPath + '"')) `
        "Steam HUD no longer hides excluded commercial entry $steamHiddenCommercialPath."
}
Assert-ToolchainTest (
    $projectXAppSource.Contains('mainHudPresenter?.SetDiscountEntriesEnabled(false);') -and
    $mainHudPresenterSource.Contains('discountEntriesEnabled && available && seconds > 0') -and
    $projectXAppSource.Contains('HasCommandLineFlag("-projectXSteamHudExclusionAcceptance")') -and
    $projectXAppSource.Contains('[SteamHudExclusionAcceptance] PASS hidden=')
) "An authoritative /222 push can reopen Steam-excluded discount entries."
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
    $projectXAppSource.Contains('hudShopSubmenuOrigin = CalculateShopSubmenuPosition(rect);') -and
    $projectXAppSource.Contains('RectTransformUtility.CalculateRelativeRectTransformBounds(parent, button)') -and
    $projectXAppSource.Contains('LayoutRebuilder.ForceRebuildLayoutImmediate(buttonGroup)') -and
    $projectXAppSource.Contains('AnimateHudSubmenu(rect, hudShopSubmenuOrigin - new Vector2(0f, 24f), 24f)') -and
    $projectXAppSource.Contains('AnimateHudSubmenu(rect, hudWearSubmenuOrigin, 112f)') -and
    $projectXAppSource.Contains('"HudSubmenuDismissOverlay", typeof(RectTransform), typeof(Image), typeof(Button)') -and
    $projectXAppSource.Contains('overlayButton.onClick.AddListener(HideHudSubmenus);') -and
    $projectXAppSource.Contains('submenu.SetAsLastSibling();') -and
    $projectXAppSource.Contains('if (graphic != null && !graphic.enabled)') -and
    $projectXAppSource.Contains('target.Find("RuntimeHitArea")') -and
    $projectXAppSource.Contains('HUD wear submenu did not collapse through the blank-area overlay.') -and
    $projectXAppSource.Contains('HUD shop submenu did not collapse through the blank-area overlay.') -and
    $projectXAppSource.Contains('while (IsToastVisible && Time.realtimeSinceStartup < toastDeadline)') -and
    $projectXAppSource.Contains('mainHudPresenter?.BeginReconnectChatSummary();') -and
    $projectXAppSource.Contains('mainHudPresenter.VisibleRedDotCount < 7') -and
    $projectXAppSource.Contains('hud-commercial-entries-excluded') -and
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
    $fixedRunnerSource.Contains('$requiredGate = if ($DataPreflightOnly -or $PreflightOnly -or $G3RuntimeOnly) { "G2" } else { "G3" }') -and
    $fixedRunnerSource.Contains('$workflowPhase = if ($DataPreflightOnly) { "G0" } else { "G3" }') -and
    $fixedRunnerSource.Contains('$failureGate = if ($DataPreflightOnly -or $PreflightOnly -or $G3RuntimeOnly) { "G3" } else { "G6" }') -and
    $fixedRunnerSource.Contains('if (-not $DataPreflightOnly)') -and
    $fixedRunnerSource.Contains('$startServerScript = Join-Path $root "tools/local/Start-Server.ps1"') -and
    $fixedRunnerSource.Contains('$serverStartParameters = @{ WaitSeconds = 60 }') -and
    ([regex]::Matches($fixedRunnerSource, '& \$startServerScript @serverStartParameters').Count -eq 4) -and
    -not $fixedRunnerSource.Contains('& $pwshExecutable -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1")')
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
Assert-ToolchainTest (
    $scaffoldSource.Contains('[uint32]$FixedUserId') -and
    $scaffoldSource.Contains('validation-fixtures.json') -and
    $scaffoldSource.Contains('module-evidence-contracts.json') -and
    $scaffoldSource.Contains('Register validation fixture atomically')
) "New module scaffolding no longer atomically freezes identity, fixture profile and evidence contract."

$cocosEvidenceSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Invoke-UnityMigrationCocosEvidence.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $cocosEvidenceSource.Contains('RecordTransportPreflight') -and
    $cocosEvidenceSource.Contains('StartFixedClient') -and
    $cocosEvidenceSource.Contains('-LocalUserId $userId') -and
    $cocosEvidenceSource.Contains('FreezeG1Baseline') -and
    $cocosEvidenceSource.Contains('window-client-crop-no-scale')
) "Central Cocos lifecycle no longer preflights Computer Use, proves fixed identity or freezes the reusable G1 baseline."
Assert-ToolchainTest (
    $g5PreflightSource.Contains('Assert-UnityMigrationCocosBaseline') -and
    $g5PreflightSource.Contains('cocosBaselineReused') -and
    $g5PreflightSource.Contains('cocosBaselineInputs')
) "G5 no longer reuses and fingerprint-validates the G1 Cocos baseline by default."

$startClientSource = Get-Content -LiteralPath (Join-Path $root "tools/local/Start-Client.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $startClientSource.Contains('$PSNativeCommandUseErrorActionPreference = $false') -and
    $startClientSource.Contains('$copyExitCode = $LASTEXITCODE') -and
    $startClientSource.Contains('if ($copyExitCode -gt 1)') -and
    $startClientSource.Contains('$global:LASTEXITCODE = 0')
) "Start-Client no longer accepts XCOPY exit code 1 when the simulator files are already current."

$clientWindowSource = Get-Content -LiteralPath (Join-Path $root "tools/local/Invoke-ClientWindow.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $clientWindowSource.Contains('public static bool ActivateWindow(IntPtr hWnd)') -and
    $clientWindowSource.Contains('AttachThreadInput(currentThread, targetThread, true)') -and
    $clientWindowSource.Contains('return GetForegroundWindow() == hWnd;') -and
    $clientWindowSource.Contains('throw "ProjectX did not become the foreground window; input was not sent"') -and
    $clientWindowSource.Contains('ActivationSucceeded = $activationSucceeded')
) "Invoke-ClientWindow no longer verifies exact ProjectX foreground activation before real input."

$fengShenStoryFixtureSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Invoke-FengShenStoryCocosFixture.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $fengShenStoryFixtureSource.Contains('($UserId -eq 7200260 -and $RoleId -eq 1000119)') -and
    $fengShenStoryFixtureSource.Contains('($UserId -eq 705213 -and $RoleId -eq 1000006)') -and
    $fengShenStoryFixtureSource.Contains('"LockedEntry" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]0; nodeId = [uint32]40011; roleLevel = 1 } }') -and
    $fengShenStoryFixtureSource.Contains('FengShenStory live fixture role level mismatch.')
) "FengShenStory locked-entry fixture no longer freezes and verifies the dedicated level-1 identity."
Assert-ToolchainTest (
    $fengShenStoryFixtureSource.Contains('$existing[0] -eq "1`t$State"') -and
    $fengShenStoryFixtureSource.Contains('$sourceColumn = if ($reapplyLiveState) { "r.guan_qia" } else { "f.backup_guan_qia" }')
) "FengShenStory same-state reapply no longer preserves the original restore snapshot."
Assert-ToolchainTest (
    $fengShenStoryFixtureSource.Contains('[string]$State = "LaterEndChapter"') -and
    $fengShenStoryFixtureSource.Contains('"LaterEndChapter" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]6; nodeId = [uint32]40074; petLevel = [uint16]100 } }')
) "FengShenStory fixed runner no longer uses one real later-chapter end-stage state for arrows, three-state stages and op26."
Assert-ToolchainTest (
    $fengShenStoryFixtureSource.Contains('-UserId 705213 -RoleId 1000006 -EvidencePath $isolationEvidencePath') -and
    $fengShenStoryFixtureSource.Contains('if ($LASTEXITCODE -ne 0) { throw "FengShenStory isolation fixture action failed: $Action" }')
) "FengShenStory primary fixture lifecycle no longer snapshots, patches, restores and cleans its isolation account."
$fengShenStoryRunnerSource = Get-Content -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs") `
    -Raw -Encoding UTF8
$fengShenStoryPresenterSource = Get-Content -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/UI/FengShenStoryPresenter.cs") `
    -Raw -Encoding UTF8
$fengShenStoryStoreSource = Get-Content -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/Data/FengShenStoryStore.cs") `
    -Raw -Encoding UTF8
$fixedAccountRunnerSource = Get-Content -LiteralPath (Join-Path $root "tools/unity-migration/Run-UnityFixedAccountValidation.ps1") `
    -Raw -Encoding UTF8
$evidenceContracts = Get-Content -LiteralPath (Join-Path $root "tools/unity-migration/module-evidence-contracts.json") `
    -Raw -Encoding UTF8 | ConvertFrom-Json
$fengShenStoryEvidenceContract = @($evidenceContracts.modules | Where-Object { $_.module -eq "FengShenStory" })[0]
Assert-ToolchainTest (
    -not $fengShenStoryRunnerSource.Contains('foreach (string control in allControls) MarkValidationControl(control);') -and
    $fengShenStoryRunnerSource.Contains('fengShenStoryPresenter.InvokeRewardIcon(0)') -and
    $fengShenStoryRunnerSource.Contains('fengShenStoryPresenter.InvokeClosedBox()') -and
    $fengShenStoryRunnerSource.Contains('fengShenStoryPresenter.InvokeOpenedBox()') -and
    $fengShenStoryPresenterSource.Contains('public bool InvokeSourceIcon()')
) "FengShenStory validation regressed to synthetic control marking or direct modal calls instead of actual bound controls."
Assert-ToolchainTest (
    $fengShenStoryStoreSource.Contains('(4000 + chapter) * 10 + level') -and
    $fengShenStoryStoreSource.Contains('SelectedChapter = CurrentChapter;') -and
    $fengShenStoryPresenterSource.Contains('public bool InvokeFight() => InvokeVisible(fightButton);') -and
    $fengShenStoryPresenterSource.Contains('public bool InvokeFormation() => InvokeVisible(formationButton);') -and
    $fengShenStoryRunnerSource.Contains('services.Options.ScenarioManagedReconnect') -and
    -not $fengShenStoryRunnerSource.Contains('|| services.Options.FengShenStoryValidation') -and
    $fengShenStoryRunnerSource.Contains('services.Network.State == NetworkState.Disconnected || services.Network.State == NetworkState.Faulted') -and
    $fengShenStoryRunnerSource.Contains('Reconnect();') -and
    $fengShenStoryRunnerSource.Contains('FengShenStory re-entry did not settle its fresh op24 before disconnect.') -and
    $fengShenStoryRunnerSource.Contains('services.Network.Disconnect("FengShenStory deliberate disconnect")')
) "FengShenStory regressed from raw 400xx node identity or real visible fight/formation button invocation."
Assert-ToolchainTest (
    [regex]::IsMatch($fixedAccountRunnerSource,
        'else\s*\{\s*Invoke-FixedAdapter "Restore"\s*Invoke-FixedAdapter "AssertRestored"\s*Invoke-FixedAdapter "Cleanup"')
) "Fixed-account validation failure path can clean an applied fixture without first restoring the account snapshot."
$heroEquipFixtureSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Invoke-HeroEquipFixture.ps1") `
    -Raw -Encoding UTF8
$heroEquipEvidenceContract = @($evidenceContracts.modules | Where-Object { $_.module -eq "HeroEquip" })[0]
Assert-ToolchainTest (
    $heroEquipFixtureSource.Contains('"AddUserFragments"') -and
    $heroEquipFixtureSource.Contains('Add-HeroEquipUserFragments') -and
    $heroEquipFixtureSource.Contains('originalPackage=$originalPackage') -and
    $heroEquipFixtureSource.Contains('"RestoreUserFragments"')
) "HeroEquip local user fragment seeding is no longer additive and recoverable."
Assert-ToolchainTest (
    $fixedAccountRunnerSource.Contains('mutationReloginOracle') -and
    $fixedAccountRunnerSource.Contains('Invoke-FixedAdapter $captureAction') -and
    $fixedAccountRunnerSource.Contains('Invoke-FixedAdapter $assertAction') -and
    $fixedAccountRunnerSource.Contains('Invoke-FixedAdapter "AssertReloginHash"') -and
    $heroEquipFixtureSource.Contains('"CaptureMutationHash"') -and
    $heroEquipFixtureSource.Contains('"AssertMutationReloginHash"') -and
    [string]$heroEquipEvidenceContract.fixedAccount.mutationReloginOracle.semanticAssertionId -eq
        'bag-currency-mission-mysql-relogin-restored' -and
    [string]$heroEquipEvidenceContract.fixedAccount.sqlitePersistenceOracle.semanticAssertionId -eq
        'equipment-sqlite-runtime-restart-restored' -and
    $fixedAccountRunnerSource.Contains('Fixed-account SQLite HeroEquip runtime/restart semantics did not pass.')
) "HeroEquip fixed-account runner no longer proves the mutated database across relogin before restoring the original snapshot."
Assert-ToolchainTest (
    [uint32]$fengShenStoryEvidenceContract.fixedAccount.terminalUserId -eq 7200057 -and
    [uint32]$fengShenStoryEvidenceContract.fixedAccount.terminalRoleId -eq 1000115 -and
    @($fengShenStoryEvidenceContract.fixedAccount.extraFlags) -contains '-projectXFengShenStoryIsolationUserId=705213'
) "FengShenStory evidence contract no longer expects the restored primary terminal identity while retaining the isolation-account run flag."

$startServerSource = Get-Content -LiteralPath (Join-Path $root "tools/local/Start-Server.ps1") -Raw -Encoding UTF8
$staminaFixtureSource = Get-Content -LiteralPath (Join-Path $root "tools/unity-migration/Invoke-StaminaClaimCocosFixture.ps1") -Raw -Encoding UTF8
$staminaRunnerSource = Get-Content -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs") -Raw -Encoding UTF8
$staminaControllerSource = Get-Content -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/Resources/Lua/StaminaClaim/StaminaClaimController.lua.txt") -Raw -Encoding UTF8
$staminaFrameSource = Get-Content -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/UI/WelfareActivityFramePresenter.cs") -Raw -Encoding UTF8
$serverPackDealSource = Get-Content -LiteralPath (Join-Path $root "server/src/pack_deal.cpp") -Raw -Encoding UTF8
$staminaEvidenceContract = @($evidenceContracts.modules | Where-Object { $_.module -eq "StaminaClaim" })[0]
Assert-ToolchainTest (
    $startServerSource.Contains('[string]$ConfigDirectory') -and
    $startServerSource.Contains('[IO.Path]::IsPathRooted($ConfigDirectory)') -and
    $fixedAccountRunnerSource.Contains('serverConfigDirectory') -and
    $fixedAccountRunnerSource.Contains('$serverStartParameters.ConfigDirectory =') -and
    $fixedAccountRunnerSource.Contains('@serverStartParameters')
) "Fixed-account runner no longer supports an isolated module server configuration directory."
Assert-ToolchainTest (
    $staminaFixtureSource.Contains('[string]$State = "Mixed"') -and
    $staminaFixtureSource.Contains('"time":[0,1]') -and
    $staminaFixtureSource.Contains('"time":[0,2400]') -and
    $staminaFixtureSource.Contains('-UserId 705213 -RoleId 1000006') -and
    $staminaFixtureSource.Contains('-UserId 7200260 -RoleId 1000119') -and
    $staminaFixtureSource.Contains('AssertReloginHash')
) "StaminaClaim fixture no longer creates the mixed three-slot clock or reversible auxiliary-account states."
Assert-ToolchainTest (
    -not $staminaRunnerSource.Contains('foreach (string control in controls) MarkValidationControl(control);') -and
    $staminaRunnerSource.Contains('RequestStaminaClaim(2, false)') -and
    $staminaRunnerSource.Contains('stamina-three-slot-single-use') -and
    $staminaRunnerSource.Contains('services.Options.ScenarioManagedReconnect') -and
    -not $staminaRunnerSource.Contains('|| services.Options.StaminaClaimValidation)') -and
    $staminaControllerSource.Contains('message:WriteByte(3)') -and
    $staminaControllerSource.Contains('Bridge:CompleteStaminaClaimRequest')
) "StaminaClaim validation regressed to read-only or synthetic control coverage instead of real op=3 interactions."
Assert-ToolchainTest (
    $staminaFrameSource.Contains('TitleName")?.transform, "福利"') -and
    $staminaFrameSource.Contains('$"{currencies.Stamina}/100"') -and
    $staminaFrameSource.Contains('FormatHeaderCurrency(currencies.Gold)')
) "StaminaClaim welfare frame regressed from the Cocos title or compact header currency formatting."
Assert-ToolchainTest (
    $serverPackDealSource.Contains('YB = std::max(YB, localTestTongBao);') -and
    $serverPackDealSource.Contains('bangYB = std::max(bangYB, localTestBdTongBao);')
) "Local-test currency floors again replace exact fixture balances in the in-memory login session."
Assert-ToolchainTest (
    [uint32]$staminaEvidenceContract.fixedAccount.terminalUserId -eq 7200057 -and
    [uint32]$staminaEvidenceContract.fixedAccount.terminalRoleId -eq 1000115 -and
    [string]$staminaEvidenceContract.fixedAccount.serverConfigDirectory -eq '.local/staminaclaim-server-validation' -and
    @($staminaEvidenceContract.fixedAccount.extraFlags) -contains '-projectXStaminaClaimIsolationUserId=705213' -and
    @($staminaEvidenceContract.fixedAccount.extraFlags) -contains '-projectXStaminaClaimOverCapUserId=7200260'
) "StaminaClaim evidence contract no longer freezes the mixed-clock server config, two auxiliary identities and primary terminal identity."

$protocolSmokeSource = Get-Content -LiteralPath (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") -Raw -Encoding UTF8
$protocolCompareSource = Get-Content -LiteralPath (Join-Path $root "tools/local/Compare-ProtocolSmokeReports.ps1") -Raw -Encoding UTF8
$protocolCoverageSource = Get-Content -LiteralPath (Join-Path $root "tools/local/Export-ProtocolCoverage.ps1") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $serverPackDealSource.Contains('if(op == 57)') -and
    $serverPackDealSource.Contains('pUser->AddExp(experience, false, false);') -and
    $serverPackDealSource.Contains('local_test')
) "PlayerHud S5 level-up fixture no longer invokes the production AddExp path behind local_test op57."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$PlayerHudParity') -and
    $protocolSmokeSource.Contains("('playerhud_levelup', 13, u8(57) + u32(1))") -and
    $protocolSmokeSource.Contains("'newLevel': struct.unpack('<H', body[17:19])[0]") -and
    $protocolSmokeSource.Contains("'playerHudParity': {")
) "PlayerHud S5 smoke no longer freezes the real trigger, uint16 new-level wire layout, and structured report."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$playerHudParityRequested') -and
    $protocolCompareSource.Contains('PlayerHud = $playerHudParity') -and
    $protocolCompareSource.Contains('$playerHudParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates PlayerHud semantic equality."
Assert-ToolchainTest (
    $protocolCoverageSource.Contains("226 = @('playerhud_levelup-push')")
) "Steam coverage no longer maps the local level-up trigger to the passive /226 server push."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$HeroParity') -and
    $protocolSmokeSource.Contains('[switch]$HeroRestartVerify') -and
    $protocolSmokeSource.Contains("('hero_add_pet_64', 13, u8(55) + u16(64))") -and
    $protocolSmokeSource.Contains("final_formation['combat'][0:2] != [57, 64]") -and
    $protocolSmokeSource.Contains("final_formation['members'][0:2] != [64, 57]") -and
    $protocolSmokeSource.Contains("'heroParity': {")
) "Hero S5 smoke no longer freezes the production award/formation flow, combat/member distinction, restart mode, and structured report."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$heroParityRequested') -and
    $protocolCompareSource.Contains('Hero = $heroParity') -and
    $protocolCompareSource.Contains('$heroParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates Hero runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$HeroEquipParity') -and
    $protocolSmokeSource.Contains('[switch]$HeroEquipRestartVerify') -and
    $protocolSmokeSource.Contains("('heroequip_add_equip1001', 13, u8(53) + u8(1) + u16(1001))") -and
    $protocolSmokeSource.Contains("('heroequip_add_fabao1001', 13, u8(53) + u8(2) + u16(1001))") -and
    $protocolSmokeSource.Contains("sum(1 for response in owned_responses if response.get('protocol') == 70) < 5") -and
    $protocolSmokeSource.Contains("'heroEquipParity': {")
) "HeroEquip S5 smoke no longer freezes the production add/wear/strengthen/takeoff lifecycle, /70 closure, restart mode, and structured report."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$heroEquipParityRequested') -and
    $protocolCompareSource.Contains('HeroEquip = $heroEquipParity') -and
    $protocolCompareSource.Contains('$heroEquipParity.status -eq "Passed"') -and
    $protocolCompareSource.Contains('ConvertTo-Json -Depth 30')
) "SQLite/MySQL report comparison no longer gates deep HeroEquip runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$MailParity') -and
    $protocolSmokeSource.Contains('[switch]$MailRestartVerify') -and
    $protocolSmokeSource.Contains("('mail_create_fixture', 13, u8(54))") -and
    $protocolSmokeSource.Contains("('mail_claim_reward', 128, b'')") -and
    $protocolSmokeSource.Contains("('mail_read_plain', 128, b'')") -and
    $protocolSmokeSource.Contains("final_list.get('count') != 12") -and
    $protocolSmokeSource.Contains("'mailParity': {")
) "Mail S5 smoke no longer freezes the production list/claim/read/repeat/restart lifecycle and structured report."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$mailParityRequested') -and
    $protocolCompareSource.Contains('Mail = $mailParity') -and
    $protocolCompareSource.Contains('$mailParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates Mail runtime and restart semantic equality."
Assert-ToolchainTest (
    $serverPackDealSource.Contains('const uint32 fixtureBaseTime = (uint32)(GetSysTime() / 86400 * 86400 + 43200);') -and
    $serverPackDealSource.Contains('fixtureBaseTime - index') -and
    $serverPackDealSource.Contains('? "Unity mail validation long body\n"')
) "Local-only Mail fixture no longer freezes deterministic expiry and backend-neutral real newline content."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$ShopParity') -and
    $protocolSmokeSource.Contains('[switch]$ShopRestartVerify') -and
    $protocolSmokeSource.Contains("('shop_buy_1001_one', 221, u8(2) + u8(1) + u16(1001) + u16(1) + u8(0))") -and
    $protocolSmokeSource.Contains("('shop_buy_insufficient_1015', 221, u8(2) + u8(1) + u16(1015) + u16(200) + u8(0))") -and
    $protocolSmokeSource.Contains("('shop_refresh_disabled', 221, u8(3) + u8(1))") -and
    $protocolSmokeSource.Contains("'shopParity': {")
) "Shop S5 smoke no longer freezes list/purchase/count/rejection/disabled-refresh/restart semantics and structured evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$shopParityRequested') -and
    $protocolCompareSource.Contains('Shop = $shopParity') -and
    $protocolCompareSource.Contains('$shopParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates Shop runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$GameplayShopsParity') -and
    $protocolSmokeSource.Contains('[switch]$GameplayShopsRestartVerify') -and
    $protocolSmokeSource.Contains('gameplay_shop_types = (2, 3, 4, 5, 6, 7, 8, 23, 25, 26, 27, 28)') -and
    $protocolSmokeSource.Contains("('gameplay_shop_buy_type28_28001_x25', 221") -and
    $protocolSmokeSource.Contains("('gameplay_shop_rebuy_soldout_type28', 221") -and
    $protocolSmokeSource.Contains("('gameplay_shop_buy_insufficient_type3', 221") -and
    $protocolSmokeSource.Contains("'gameplayShopsParity': {")
) "GameplayShops S5 smoke no longer freezes all retained types, type2 refresh, type28 sold-out purchase, rejection, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$gameplayShopsParityRequested') -and
    $protocolCompareSource.Contains('GameplayShops = $gameplayShopsParity') -and
    $protocolCompareSource.Contains('$gameplayShopsParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates GameplayShops runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$WorldParity') -and
    $protocolSmokeSource.Contains('[switch]$WorldRestartVerify') -and
    $protocolSmokeSource.Contains("('world_fight_10001', 320") -and
    $protocolSmokeSource.Contains("('world_claim_normal_10000', 320") -and
    $protocolSmokeSource.Contains("('world_claim_star_20011', 320") -and
    $protocolSmokeSource.Contains("('world_sweep_10001', 320") -and
    $protocolSmokeSource.Contains("('world_reset_10001', 320") -and
    $protocolSmokeSource.Contains("'worldParity': {")
) "World S5 smoke no longer freezes production fight, chest, sweep, reset, rejection, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$worldParityRequested') -and
    $protocolCompareSource.Contains('World = $worldParity') -and
    $protocolCompareSource.Contains('$worldParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates World runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$DrawParity') -and
    $protocolSmokeSource.Contains('[switch]$DrawRestartVerify') -and
    $protocolSmokeSource.Contains("('draw_high_free_single', 224") -and
    $protocolSmokeSource.Contains("('draw_add_high_tickets', 13, u8(50)") -and
    $protocolSmokeSource.Contains("('draw_high_ten', 224") -and
    $protocolSmokeSource.Contains("('draw_high_ten_insufficient', 224") -and
    $protocolSmokeSource.Contains("'drawParity': {")
) "Draw S5 smoke no longer freezes deterministic free draw, ticket-funded ten draw, rejection, hero ownership, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$drawParityRequested') -and
    $protocolCompareSource.Contains('Draw = $drawParity') -and
    $protocolCompareSource.Contains('$drawParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates Draw runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$GameplayParity') -and
    $protocolSmokeSource.Contains('[switch]$GameplayRestartVerify') -and
    $protocolSmokeSource.Contains("('gameplay_arena_hotpoint', 65, u8(1) + u16(101))") -and
    $protocolSmokeSource.Contains("('gameplay_xunbao_hotpoint', 65, u8(1) + u16(103))") -and
    $protocolSmokeSource.Contains("('gameplay_restart_arena_hotpoint', 65, u8(1) + u16(101))") -and
    $protocolSmokeSource.Contains("'gameplayParity': {")
) "Gameplay S5 smoke no longer freezes Steam-owned shared hot-point queries, repeat lifecycle, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$gameplayParityRequested') -and
    $protocolCompareSource.Contains('Gameplay = $gameplayParity') -and
    $protocolCompareSource.Contains('$gameplayParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates Gameplay runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$YouLiParity') -and
    $protocolSmokeSource.Contains('[switch]$YouLiRestartVerify') -and
    $protocolSmokeSource.Contains("('youli_initial_info', 335, u8(1))") -and
    $protocolSmokeSource.Contains("('youli_repeat_info', 335, u8(1))") -and
    $protocolSmokeSource.Contains("('youli_restart_info', 335, u8(1))") -and
    $protocolSmokeSource.Contains("'youLiParity': {")
) "YouLi S5 smoke no longer freezes authoritative empty-state query, repeat lifecycle, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$youLiParityRequested') -and
    $protocolCompareSource.Contains('YouLi = $youLiParity') -and
    $protocolCompareSource.Contains('$youLiParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates YouLi runtime and restart semantic equality."
$youLiScenario = Get-UnityMigrationScenario -Root $root -ModuleKey "YouLi"
$youLiSourceContracts = @($youLiScenario.sourceContracts)
$youLiLuaContract = @($youLiSourceContracts | Where-Object {
    [string]$_.path -eq 'unityclient/Assets/ProjectX/Resources/Lua/Gameplay/YouLiController.lua.txt'
})[0]
$youLiAppContract = @($youLiSourceContracts | Where-Object {
    [string]$_.path -eq 'unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs'
})[0]
$youLiPresenterContract = @($youLiSourceContracts | Where-Object {
    [string]$_.path -eq 'unityclient/Assets/ProjectX/src/UI/YouLiPresenter.cs'
})[0]
Assert-ToolchainTest (
    @($youLiLuaContract.contains) -contains 'function M.startBatch' -and
    @($youLiAppContract.contains) -contains 'StartAllYouLi' -and
    @($youLiAppContract.contains) -contains 'onYouLiStartBatch' -and
    @($youLiPresenterContract.contains) -contains 'Action startAll' -and
    @($youLiPresenterContract.contains) -contains 'oneKeyStart = Bind(Find(root, "Btn_youli"), startAll)' -and
    @($youLiPresenterContract.contains) -notcontains 'StartFirstAvailable'
) "YouLi source contract no longer follows the authoritative one-key batch dispatch chain."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$FengShenStoryParity') -and
    $protocolSmokeSource.Contains('[switch]$FengShenStoryRestartVerify') -and
    $protocolSmokeSource.Contains("('fengshen_story_raise_pets', 13, u8(58) + u16(100))") -and
    $protocolSmokeSource.Contains("('fengshen_story_initial_info', 320, u8(24))") -and
    $protocolSmokeSource.Contains("('fengshen_story_challenge', 320, u8(25))") -and
    $protocolSmokeSource.Contains("('fengshen_story_restart_info', 320, u8(24))") -and
    $protocolSmokeSource.Contains("'fengShenStoryParity': {")
) "FengShenStory S5 smoke no longer freezes op24 state, production op25/op10 challenge settlement, rewards, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$fengShenStoryParityRequested') -and
    $protocolCompareSource.Contains('FengShenStory = $fengShenStoryParity') -and
    $protocolCompareSource.Contains('$fengShenStoryParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates FengShenStory runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$ArenaParity') -and
    $protocolSmokeSource.Contains('[switch]$ArenaRestartVerify') -and
    $protocolSmokeSource.Contains("('arena_initial_list', 161, u8(0) + u8(1))") -and
    $protocolSmokeSource.Contains("('arena_fight_dynamic_robot', 161, b'')") -and
    $protocolSmokeSource.Contains("('arena_flush_rank_snapshot', 13, u8(59))") -and
    $protocolSmokeSource.Contains("('arena_restart_list', 161, u8(0) + u8(1))") -and
    $protocolSmokeSource.Contains("'arenaParity': {")
) "Arena S5 smoke no longer freezes authoritative rank list, real robot replay, attempt consumption, rank advance, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$arenaParityRequested') -and
    $protocolCompareSource.Contains('Arena = $arenaParity') -and
    $protocolCompareSource.Contains('$arenaParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates Arena runtime and restart semantic equality."
Assert-ToolchainTest (
    $protocolSmokeSource.Contains('[switch]$XunBaoParity') -and
    $protocolSmokeSource.Contains('[switch]$XunBaoRestartVerify') -and
    $protocolSmokeSource.Contains("('xunbao_initial_info', 319, u8(31))") -and
    $protocolSmokeSource.Contains("('xunbao_repeat_info', 319, u8(31))") -and
    $protocolSmokeSource.Contains("('xunbao_restart_info', 319, u8(31))") -and
    $protocolSmokeSource.Contains("'xunBaoParity': {")
) "XunBao S5 smoke no longer freezes authoritative op31 count/recovery byte state, repeat lifecycle, and restart evidence."
Assert-ToolchainTest (
    $protocolCompareSource.Contains('$xunBaoParityRequested') -and
    $protocolCompareSource.Contains('XunBao = $xunBaoParity') -and
    $protocolCompareSource.Contains('$xunBaoParity.status -eq "Passed"')
) "SQLite/MySQL report comparison no longer gates XunBao runtime and restart semantic equality."

$localServerSupervisorSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/Core/LocalServerSupervisor.cs") -Raw -Encoding UTF8
$projectXAppSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs") -Raw -Encoding UTF8
$localServerProbeSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/Editor/LocalServerSupervisorProbe.cs") -Raw -Encoding UTF8
$editorServerBuildGuardSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/Editor/EditorLocalServerBuildGuard.cs") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $localServerSupervisorSource.Contains('Application.streamingAssetsPath, "ProjectXServer"') -and
    $localServerSupervisorSource.Contains('Application.persistentDataPath, "LocalServer"') -and
    $localServerSupervisorSource.Contains('if (options.HasFlag("-projectXExternalServer")) return false;') -and
    $localServerSupervisorSource.Contains('return !Application.isEditor || !Application.isBatchMode;') -and
    $localServerSupervisorSource.Contains('Path.Combine(repositoryRoot, "build", "server-win", "Debug")') -and
    $localServerSupervisorSource.Contains('Path.Combine(repositoryRoot, "server", "config")') -and
    $localServerSupervisorSource.Contains('Path.Combine(repositoryRoot, "server", "sql", "sqlite", "001_initial_schema.sql")')
) "S6 supervisor no longer isolates immutable packaged assets from the writable player database or the external-server validation path."
Assert-ToolchainTest (
    $projectXAppSource.IndexOf('StartCoroutine(PrepareLocalServerThenInitialize(launchOptions))', [StringComparison]::Ordinal) -ge 0 -and
    $projectXAppSource.IndexOf('StartCoroutine(PrepareLocalServerThenInitialize(launchOptions))', [StringComparison]::Ordinal) `
        -lt $projectXAppSource.IndexOf('services = new GameServices(this, launchOptions);', [StringComparison]::Ordinal)
) "S6 local-server preparation no longer occurs before GameServices construction and network initialization."
Assert-ToolchainTest (
    $localServerSupervisorSource.Contains('端口 {port} 已被其他程序占用') -and
    $localServerSupervisorSource.Contains('秒内未监听 127.0.0.1:{port}') -and
    $localServerSupervisorSource.Contains('运行中异常退出') -and
    $localServerSupervisorSource.Contains('ReadyAdopted')
) "S6 supervisor no longer exposes explicit port-conflict, timeout, crash, and duplicate-start adoption states."
Assert-ToolchainTest (
    $localServerProbeSource.Contains('maximumConcurrentKapai == 1') -and
    $localServerProbeSource.Contains('ReadyAdopted') -and
    $localServerProbeSource.Contains('crashOwner.State == LocalServerState.Failed') -and
    $localServerProbeSource.Contains('string runId = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff")') -and
    $localServerProbeSource.Contains('File.Copy(ownedDatabase, crashDatabase, true)') -and
    $localServerProbeSource.Contains('report.residualKapai == 0')
) "S6 probe no longer gates duplicate-process prevention, crash detection, and residual-zero cleanup."
Assert-ToolchainTest (
    $editorServerBuildGuardSource.Contains('PlayModeStateChange.ExitingEditMode') -and
    $editorServerBuildGuardSource.Contains('Application.isBatchMode') -and
    $editorServerBuildGuardSource.Contains('Build-Server.ps1') -and
    $editorServerBuildGuardSource.Contains('EditorApplication.isPlaying = false') -and
    $editorServerBuildGuardSource.Contains('-projectXExternalServer') -and
    $editorServerBuildGuardSource.Contains('File.GetLastWriteTimeUtc(input) > builtAt')
) "Editor Play no longer auto-builds a missing/stale SQLite server or cancels Play on build failure."
$steamBuildSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/Editor/SteamWindowsBuild.cs") -Raw -Encoding UTF8
$serverMainSource = Get-Content -LiteralPath (Join-Path $root "server/src/main.cpp") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $serverMainSource.Contains('const char *listenIp = localTest ? "127.0.0.1" : NULL;') -and
    $serverMainSource.Contains('database.Query("PRAGMA integrity_check")')
) "S7 server no longer binds local_test to loopback or rejects a failed SQLite integrity check."
Assert-ToolchainTest (
    $serverMainSource.Contains('WaitForLocalShutdownCommand') -and
    $serverMainSource.Contains('SigHandler(SIGTERM);') -and
    $localServerSupervisorSource.Contains('process.StandardInput.WriteLine("shutdown")') -and
    $localServerSupervisorSource.Contains('GracefulShutdownCompleted = process.WaitForExit(10000)')
) "S7 lifecycle no longer requests production save/shutdown before force-kill fallback."
Assert-ToolchainTest (
    $localServerSupervisorSource.Contains('Path.Combine(dataRoot, "Logs")') -and
    $localServerSupervisorSource.Contains('Path.Combine(dataRoot, "Backups")') -and
    $localServerSupervisorSource.Contains('RetainNewest(backupsDirectory, "projectx-*.db", 3)')
) "S7 player data no longer writes rotating logs and pre-start backups below persistentDataPath."
Assert-ToolchainTest (
    $steamBuildSource.Contains('BuildTarget.StandaloneWindows64') -and
    $steamBuildSource.Contains('clientEntry = "ProjectX.exe"') -and
    $steamBuildSource.Contains('RemoveDoNotShipArtifacts(outputDirectory);') -and
    $steamBuildSource.Contains('ValidateReleaseTree(outputDirectory);') -and
    $steamBuildSource.Contains('Directory.GetFiles(outputDirectory, "*", SearchOption.AllDirectories)') -and
    $steamBuildSource.Contains('!string.Equals(Path.GetFullPath(file), Path.GetFullPath(manifestPath)') -and
    $steamBuildSource.Contains('"mysqld.exe", "pwsh.exe", "powershell.exe"') -and
    $steamBuildSource.Contains('steam-package-manifest.json')
) "S7 Steam builder no longer freezes the full Windows x64 release tree, removes DoNotShip artifacts, rejects development dependencies, or hashes every Depot file."
Assert-ToolchainTest (
    $localServerSupervisorSource.Contains('new Semaphore(1, 1, "Local\\Xuancai.ProjectX.LocalServer.8711")') -and
    $localServerSupervisorSource.Contains('leaseHeld = ownershipLease.WaitOne(0)') -and
    $localServerSupervisorSource.Contains('RecoveredOrphanProcess = true') -and
    $localServerSupervisorSource.Contains('RecoverOrphan(matching)')
) "S8 supervisor no longer owns startup through a crash-safe named lease or replaces an orphaned packaged server."
Assert-ToolchainTest (
    $steamBuildSource.Contains('ProjectX_Data/StreamingAssets/ProjectXServer') -or
    ($steamBuildSource.Contains('"ProjectXServer"') -and
     $steamBuildSource.Contains('steam-package-manifest.json') -and
     $steamBuildSource.Contains('Path.GetRelativePath'))
) "S8 Steam package no longer keeps runtime dependencies under the immutable single-entry application tree with a verifiable file manifest."
Assert-ToolchainTest (
    $serverPackDealSource.Contains('static bool RepairLocalRoleNullFields(CDatabaseSql *pDb, uint32 roleId)') -and
    $serverPackDealSource.Contains('"zhenfa", "package", "title", "hots", "bitset", "save_val", "bank_item"') -and
    $serverPackDealSource.Contains('"state", "exp", "money", "qianneng", "chat_channel", "chat_time", "admin", "login_time"') -and
    ([regex]::Matches($serverPackDealSource, 'RepairLocalRoleNullFields\(pDb, roleId\)').Count -ge 2)
) "S8 local role creation no longer normalizes nullable role_info fields for both the default account and explicit role creation paths."
Assert-ToolchainTest (
    $projectXAppSource.Contains('autoInvoke || HasCommandLineFlag("-projectXS8StartupAcceptance")') -and
    $projectXAppSource.Contains('StartCoroutine(InvokeButtonNextFrame(button))')
) "S8 packaged startup acceptance no longer invokes the same bound enter-game Button used by a normal player."

$manifestForWorkflow = (Import-UnityMigrationManifest -Root $root).Value
$worldModule = @($manifestForWorkflow.modules | Where-Object { $_.key -eq "World" }) | Select-Object -First 1
$worldScenario = Get-UnityMigrationScenario -Root $root -ModuleKey "World"
Assert-ToolchainTest (
    $null -ne (Assert-UnityMigrationModuleWorkflowContract -Root $root `
        -ModuleConfig $worldModule -Scenario $worldScenario -Phase G3)
) "The completed World module no longer satisfies the hardened G3 workflow contract."

$heroEquipMatrix = (Import-UnityMigrationJson -Root $root `
    -Path "docs/unityclient/matrices/HERO_EQUIPMENT_CONTROLS.json").Value
$heroEquipmentPresenterSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/UI/HeroEquipmentPresenter.cs") -Raw -Encoding UTF8
$heroEquipmentControllerSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/Resources/Lua/Hero/EquipmentController.lua.txt") -Raw -Encoding UTF8
$heroEquipmentBootstrapSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/Resources/Lua/Bootstrap.txt") -Raw -Encoding UTF8
$heroEquipmentCatalogSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/Data/EquipmentCatalog.cs") -Raw -Encoding UTF8
$virtualListSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/UI/VirtualList.cs") -Raw -Encoding UTF8
$toastPresenterSource = Get-Content -LiteralPath (Join-Path $root `
    "unityclient/Assets/ProjectX/src/UI/ToastPresenter.cs") -Raw -Encoding UTF8
$heroEquipmentServerSource = Get-Content -LiteralPath (Join-Path $root `
    "server/src/pet_equip_manage.cpp") -Raw -Encoding UTF8
$heroEquipModuleSource = Get-Content -LiteralPath (Join-Path $root `
    "docs/unityclient/modules/HERO_EQUIPMENT.md") -Raw -Encoding UTF8
$migrationGuideSource = Get-Content -LiteralPath (Join-Path $root `
    "docs/unityclient/MIGRATION_GUIDE.md") -Raw -Encoding UTF8
$heroEquipScenario = Get-UnityMigrationScenario -Root $root -ModuleKey "HeroEquip"
$processAcceptance = $heroEquipMatrix.processEffectivenessAcceptance
Assert-ToolchainTest (
    $null -ne $processAcceptance -and
    $processAcceptance.sampleModule -eq "HeroEquip" -and
    @($processAcceptance.preUserAgentChecks).Count -eq 3 -and
    @($processAcceptance.freshG4RequiredAssertions).Count -eq 7 -and
    $processAcceptance.scopeBoundary.Contains("法宝仅验兄弟入口、5..6槽和共享/319隔离") -and
    $processAcceptance.passCondition.Contains("最后一次相关变更后的固定账号G4全部断言通过") -and
    @($heroEquipMatrix.scope.excludedMustBeHiddenOrDisabled | Where-Object { $_ -like "法宝背包、碎片、详情、穿戴、卸下、搜索、合成、强化、炼化和重生的完整业务验收*" }).Count -eq 1
) "HeroEquip process-effectiveness sample no longer freezes pre-user checks, fresh G4 assertions, or scheme-A FaBao boundary."
Assert-ToolchainTest (
    $migrationGuideSource.Contains("明显的绑定、刷新、拖拽和生命周期错误不得留给用户首次发现") -and
    $heroEquipModuleSource.Contains("## 流程改动验收样板（2026-08-22）") -and
    $heroEquipModuleSource.Contains("Run-UnityFixedAccountValidation.ps1 -Module HeroEquip -DataPreflightOnly") -and
    $heroEquipModuleSource.Contains("Run-UnityModuleValidation.ps1 -Module HeroEquip -ValidationMode Full")
) "The central guide or HeroEquip teammate runbook no longer gates user early play behind agent self-checks."
Assert-ToolchainTest (
    @($heroEquipScenario.semanticAssertionKeys | Where-Object { $_ -in @(
        "equipment-visible-dynamic-and-lifecycle-contracts",
        "equipment-common-bag-refresh-and-drag-contracts",
        "fabao-sibling-boundary-remains-isolated") }).Count -eq 3 -and
    $projectXAppSource.Contains('RecordValidationSemantic("equipment-visible-dynamic-and-lifecycle-contracts", true') -and
    $projectXAppSource.Contains('RecordValidationSemantic("equipment-common-bag-refresh-and-drag-contracts", true') -and
    $projectXAppSource.Contains('RecordValidationSemantic("fabao-sibling-boundary-remains-isolated", faBaoUnchanged')
) "HeroEquip Full no longer reports the three process-effectiveness runtime semantics."
Assert-ToolchainTest (
    $projectXAppSource.Contains('firstButton.onClick.AddListener(ShowHeroEquipmentListTab);') -and
    $projectXAppSource.Contains('value.name.EndsWith("_StrengthRuntime", StringComparison.Ordinal)')
) "HeroEquip early-play regression: equipment/fragments reverse navigation or cultivation-tab cleanup was removed."
Assert-ToolchainTest (
    $heroEquipmentPresenterSource.Contains('public void PlayCultivationSuccess(int operation)') -and
    -not $heroEquipmentPresenterSource.Contains('ShowCultivationEffect(1);') -and
    -not $heroEquipmentPresenterSource.Contains('ShowCultivationEffect(2);') -and
    -not $heroEquipmentPresenterSource.Contains('ShowCultivationEffect(3);') -and
    -not $heroEquipmentPresenterSource.Contains('ShowCultivationEffect(effectIndex, currentLevel > 0);')
) "HeroEquip early-play regression: cultivation page rendering once again starts success effects."
Assert-ToolchainTest (
    -not $heroEquipmentPresenterSource.Contains('EnsureButtonLabel(strengthAllObject.transform') -and
    -not $heroEquipmentPresenterSource.Contains('private static void EnsureButtonLabel(') -and
    $heroEquipmentPresenterSource.Contains('.Where(value => value.FormationPosition == formationPosition)') -and
    $heroEquipmentPresenterSource.Contains('.OrderBy(value => value.Slot)')
) "HeroEquip early-play regression: one-key-strength text is recreated in code or the cultivation strip includes unequipped items."
Assert-ToolchainTest (
    $heroEquipmentBootstrapSource.Contains('function OnHeroEquipmentStrength(uid, strengthType)') -and
    $heroEquipmentBootstrapSource.Contains('EquipmentController.strengthEquipment(uid, strengthType)') -and
    $heroEquipmentServerSource.Contains('uint8 addLevel = 1;')
) "HeroEquip early-play regression: the five-strength type is dropped by the Lua bootstrap bridge."
$fragmentOpenStart = $projectXAppSource.IndexOf('private void ShowHeroEquipmentFragments()', [StringComparison]::Ordinal)
$fragmentOpenEnd = $projectXAppSource.IndexOf('private void ShowHeroEquipmentListTab()', $fragmentOpenStart, [StringComparison]::Ordinal)
$fragmentOpenSource = if ($fragmentOpenStart -ge 0 -and $fragmentOpenEnd -gt $fragmentOpenStart) {
    $projectXAppSource.Substring($fragmentOpenStart, $fragmentOpenEnd - $fragmentOpenStart)
} else { "" }
Assert-ToolchainTest (
    $fragmentOpenSource.IndexOf('heroFrameView.GameObject.transform.SetAsLastSibling();', [StringComparison]::Ordinal) -ge 0 -and
    $fragmentOpenSource.IndexOf('heroFrameView.GameObject.transform.SetAsLastSibling();', [StringComparison]::Ordinal) -lt
        $fragmentOpenSource.IndexOf('heroEquipmentFragmentView.GameObject.transform.SetAsLastSibling();', [StringComparison]::Ordinal)
) "HeroEquip early-play regression: the equipment fragment view can be covered by the outer hero frame."
Assert-ToolchainTest (
    $projectXAppSource.Contains('RenderHeroEquipmentFragmentRows(binding, fragments);') -and
    $projectXAppSource.Contains('new VirtualList<BagItemRecord[]>(viewport.gameObject') -and
    $projectXAppSource.Contains('BindHeroEquipmentFragmentRow') -and
    -not $projectXAppSource.Contains('RuntimeFragmentContent') -and
    $virtualListSource.Contains('dragSurface.raycastTarget = true;') -and
    $virtualListSource.Contains('VirtualListScrollDragRelay') -and
    $projectXAppSource.Contains('fragment bag did not reuse the common VirtualList drag contract') -and
    $projectXAppSource.Contains('fragment bag accepted drag callbacks but its content did not move') -and
    $projectXAppSource.Contains('progress.fillAmount = required > 0') -and
    $projectXAppSource.Contains('Mathf.Clamp01((float)item.Quantity / required)') -and
    -not $projectXAppSource.Contains('.ThenByDescending(item => item.ItemId)\r\n                .Take(5)')
) "HeroEquip regression: fragment rows no longer reuse the common draggable VirtualList or progress is not quantity-bound."
Assert-ToolchainTest (
    $heroEquipmentControllerSource.Contains('BagController.requestEquipmentSnapshot(function(_) end)') -and
    $projectXAppSource.Contains('services.Bag.Changed += HandleHeroEquipmentFragmentBagChanged;') -and
    $projectXAppSource.Contains('compose did not refresh the consumed fragment quantity') -and
    $projectXAppSource.Contains('left fragment progress or grid quantity stale')
) "HeroEquip regression: compose success no longer refreshes the source fragments and the visible page from authoritative bag state."
Assert-ToolchainTest (
    $heroEquipmentCatalogSource.Contains('[JsonProperty("attr_jinglian")]') -and
    $heroEquipmentCatalogSource.Contains('[JsonProperty("attr_juexing")]') -and
    $heroEquipmentCatalogSource.Contains('[JsonProperty("attr_shenzhu")]') -and
    $heroEquipmentPresenterSource.Contains('BindCultivationAttributes(') -and
    $heroEquipmentPresenterSource.Contains('public bool AreCultivationAttributesBound(int mode)') -and
    $heroEquipmentPresenterSource.Contains('player.gameObject.SetActive(false);') -and
    $heroEquipmentPresenterSource.Contains('SetStrengthAllVisible(false);') -and
    $heroEquipmentPresenterSource.Contains('private bool CanOpenCultivation(') -and
    $toastPresenterSource.Contains('root.transform.SetAsLastSibling();') -and
    $projectXAppSource.Contains('MaintainHeroEquipmentCultivationState();') -and
    $projectXAppSource.Contains('refine toast changed parent or sibling order during its visible lifetime') -and
    $projectXAppSource.Contains('awaken toast changed parent or sibling order during its visible lifetime') -and
    $projectXAppSource.Contains('shenzhu toast changed parent or sibling order during its visible lifetime')
) "HeroEquip regression: dynamic cultivation attributes, effect cleanup, tab visibility, eligibility, toast order, or exclusive lifecycle was removed."
Assert-ToolchainTest (
    $heroEquipmentPresenterSource.Contains('BindRefineMaterials(materialIds);') -and
    $heroEquipmentPresenterSource.Contains('ApplyMaterialIcon(EnsureMaterialIcon(slot.transform), material);') -and
    $heroEquipmentPresenterSource.Contains('item.Definition.DivineCostItemId') -and
    $heroEquipmentPresenterSource.Contains('bag.GetTotalQuantityByItemId(divineItemId)') -and
    $heroEquipmentPresenterSource.Contains('bool showDivineMaterial = divineItemId > 0') -and
    $heroEquipmentPresenterSource.Contains('SetActive(showDivineMaterial)') -and
    $heroEquipmentCatalogSource.Contains('public EquipmentMaterialDefinition GetItem(int itemId)')
) "HeroEquip early-play regression: refine or divine material identity/icon binding was removed."
Assert-ToolchainTest (
    $heroEquipmentControllerSource.Contains('Bridge:NotifyHeroEquipmentCultivationSuccess(4)') -and
    $heroEquipmentControllerSource.Contains('M.pendingCultivationSuccessOp = op') -and
    $heroEquipmentControllerSource.Contains('Bridge:NotifyHeroEquipmentCultivationSuccess(M.pendingCultivationSuccessOp)')
) "HeroEquip early-play regression: cultivation effects are no longer gated by successful authoritative responses."
$heroEquipCoverage = Assert-UnityMigrationCoverageList -Root $root -ModuleKey "HeroEquip" -Matrix $heroEquipMatrix
Assert-ToolchainTest (
    $heroEquipCoverage.SourceCount -eq 14 -and $heroEquipCoverage.BusinessIdCount -eq 974
) "HeroEquip G0 coverage denominator no longer reproduces 14 sources and 974 business ids."
Assert-ToolchainTest (
    @($heroEquipMatrix.controls).Count -eq 86
) "HeroEquip scheme-A control denominator no longer reproduces 86 current controls/states."

$heroCultivationPresenterSource = Get-Content -LiteralPath (
    Join-Path $root "unityclient/Assets/ProjectX/src/UI/HeroCultivationPresenter.cs") -Raw -Encoding UTF8
$imodAnimationPlayerSource = Get-Content -LiteralPath (
    Join-Path $root "unityclient/Assets/ProjectX/src/Animation/ImodAnimationPlayer.cs") -Raw -Encoding UTF8
$heroControllerSource = Get-Content -LiteralPath (
    Join-Path $root "unityclient/Assets/ProjectX/Resources/Lua/Hero/HeroController.lua.txt") -Raw -Encoding UTF8
$heroLoginSource = Get-Content -LiteralPath (
    Join-Path $root "unityclient/Assets/ProjectX/Resources/Lua/Login/LoginView.lua.txt") -Raw -Encoding UTF8
$appLaunchOptionsSource = Get-Content -LiteralPath (
    Join-Path $root "unityclient/Assets/ProjectX/src/Core/AppLaunchOptions.cs") -Raw -Encoding UTF8
Assert-ToolchainTest (
    $appLaunchOptionsSource.Contains('HeroCultivationG3Validation => HasFlag("-projectXHeroCultivationG3Validation")') -and
    $heroLoginSource.Contains('Bridge:HasCommandLineFlag("-projectXHeroCultivationG3Validation")') -and
    $heroControllerSource.Contains('Bridge:RunHeroCultivationG3Validation()') -and
    $projectXAppSource.Contains('CompleteHeroCultivationG3Validation();')
) "HeroCultivation G3 flag is no longer wired from login through formation and authoritative package/8 completion."
Assert-ToolchainTest (
    $heroCultivationPresenterSource.Contains('ValidateEarlyPlayRuntime(out string detail)') -and
    $heroCultivationPresenterSource.Contains('missing level materials:') -and
    $heroCultivationPresenterSource.Contains('retained placeholder') -and
    $heroCultivationPresenterSource.Contains('tabs=5/5')
) "HeroCultivation early-play regression: material, placeholder or five-tab runtime assertions were removed."
Assert-ToolchainTest (
    $heroCultivationPresenterSource.Contains('EventSystem.current.RaycastAll(data, hits);') -and
    $heroCultivationPresenterSource.Contains('hits[0].gameObject.GetComponentInParent<Button>() != button') -and
    $heroCultivationPresenterSource.Contains('ExecuteEvents.pointerClickHandler')
) "HeroCultivation early-play regression: tab checks no longer require real EventSystem raycast/click semantics."
Assert-ToolchainTest (
    $heroCultivationPresenterSource.Contains('right deployed switch failed') -and
    $heroCultivationPresenterSource.Contains('left deployed restore failed')
) "HeroCultivation early-play regression: deployed-hero right/left roundtrip assertion was removed."
Assert-ToolchainTest (
    $heroCultivationPresenterSource.Contains('GetItemPicture(fragmentId)') -and
    $heroCultivationPresenterSource.Contains('GetItemPicture(851)') -and
    $heroCultivationPresenterSource.Contains('star page skill/fragment icon or quality frame is missing') -and
    $heroCultivationPresenterSource.Contains('break page material icon or quality frame is missing')
) "HeroCultivation early-play regression: star skill/fragment or break-material icon mapping and runtime assertions were removed."
Assert-ToolchainTest (
    $heroCultivationPresenterSource.Contains('duplicate.name = "Button2_Runtime"') -and
    $heroCultivationPresenterSource.Contains('cultivation tab 2 did not reuse the shared Button2_Runtime slot') -and
    $heroCultivationPresenterSource.Contains('HeroLevelMaterial{value}Frame') -and
    $heroCultivationPresenterSource.Contains('HeroStarFragmentFrame') -and
    $heroCultivationPresenterSource.Contains('HeroBreakMaterialFrame') -and
    $heroCultivationPresenterSource.Contains('HeroCultivationMaterialFrame')
) "HeroCultivation early-play regression: duplicate second tab or unified material quality-frame repair was removed."
Assert-ToolchainTest (
    $heroCultivationPresenterSource.Contains('CloseTransientPopups();') -and
    $heroCultivationPresenterSource.Contains('page switch did not close transient popup') -and
    $heroCultivationPresenterSource.Contains('GetBreakTalentDescriptions') -and
    $heroCultivationPresenterSource.Contains('PopulateTalentRows')
) "HeroCultivation early-play regression: source-derived popup descriptions or page-switch cleanup was removed."
Assert-ToolchainTest (
    $imodAnimationPlayerSource.Contains('EnsureSpriteCache();') -and
    $imodAnimationPlayerSource.Contains('moduleSprites.Count == data.modules.Length') -and
    $imodAnimationPlayerSource.Contains('moduleSprites[part.module] == null')
) "Imod runtime regression: Play-mode assembly reload no longer rebuilds the generated sprite cache before rendering."

Write-Host "Unity migration toolchain tests passed: $passed"
