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

$validEvidence = [pscustomobject]@{
    contractFingerprint = $dataFingerprintA
    sourceContractFingerprint = "SOURCE-A"
    g5ContractFingerprint = "G5-A"
    userId = 7200057
    roleId = 1000115
    setupAssert = "passed"
    restoreAssert = "passed"
    cleanupAssert = "passed"
}
$validEvidenceFailures = @(Get-UnityMigrationDataPreflightEvidenceFailures `
    -Evidence $validEvidence -ExpectedFingerprint $dataFingerprintA `
    -ExpectedUserId 7200057 -ExpectedRoleId 1000115 `
    -ExpectedSourceContractFingerprint "SOURCE-A" -ExpectedG5ContractFingerprint "G5-A")
Assert-ToolchainTest ($validEvidenceFailures.Count -eq 0) "Valid data preflight evidence was rejected."
$staleEvidence = $validEvidence.PSObject.Copy()
$staleEvidence.contractFingerprint = "STALE"
$staleEvidence.sourceContractFingerprint = "SOURCE-STALE"
$staleEvidence.g5ContractFingerprint = "G5-STALE"
$staleEvidence.cleanupAssert = "pending"
$staleEvidenceFailures = @(Get-UnityMigrationDataPreflightEvidenceFailures `
    -Evidence $staleEvidence -ExpectedFingerprint $dataFingerprintA `
    -ExpectedUserId 7200057 -ExpectedRoleId 1000115 `
    -ExpectedSourceContractFingerprint "SOURCE-A" -ExpectedG5ContractFingerprint "G5-A")
Assert-ToolchainTest (
    @($staleEvidenceFailures | Where-Object { $_ -eq "contract fingerprint mismatch" }).Count -eq 1
) "Stale data preflight fingerprint was not rejected."
Assert-ToolchainTest (
    @($staleEvidenceFailures | Where-Object { $_ -eq "cleanupAssert is not passed" }).Count -eq 1
) "Incomplete data preflight cleanup assertion was not rejected."
Assert-ToolchainTest (
    @($staleEvidenceFailures | Where-Object { $_ -eq "source contract fingerprint mismatch" }).Count -eq 1
) "Stale source contract fingerprint was not rejected."
Assert-ToolchainTest (
    @($staleEvidenceFailures | Where-Object { $_ -eq "G5 contract fingerprint mismatch" }).Count -eq 1
) "Stale G5 contract fingerprint was not rejected."

$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$gameplayContract = @($contracts.modules | Where-Object module -eq "GameplayShops")[0]
$g5FingerprintA = Get-UnityMigrationG5ContractFingerprint -Contract $gameplayContract
$g5FingerprintB = Get-UnityMigrationG5ContractFingerprint -Contract $gameplayContract
Assert-ToolchainTest ($g5FingerprintA -match '^[A-F0-9]{64}$') "G5 contract fingerprint is not SHA-256."
Assert-ToolchainTest ($g5FingerprintA -eq $g5FingerprintB) "G5 contract fingerprint is not deterministic."

$gameplayModule = @($manifest.modules | Where-Object key -eq "GameplayShops")[0]
$gameplayScenario = Get-UnityMigrationScenario -Root $root -ModuleKey "GameplayShops"
$gameplaySourceFingerprint = Assert-UnityMigrationSourceContracts -Root $root -Scenario $gameplayScenario
Assert-ToolchainTest (
    $gameplaySourceFingerprint -match '^[A-F0-9]{64}$'
) "GameplayShops G3 source contract is not frozen by a SHA-256 fingerprint."
$declaredControls = Assert-UnityMigrationControlMatrixDeclared -Root $root -ModuleKey "GameplayShops" `
    -Path ([string]$gameplayModule.controlMatrix) -RequireLifecycleFields
Assert-ToolchainTest ($declaredControls -eq 59) "G0 lifecycle matrix precheck did not validate all GameplayShops controls."

$processProbe = Invoke-UnityMigrationProcess -Executable $pwshExecutable `
    -Arguments @("-NoProfile", "-Command", "exit 0") -Module "Toolchain" -Phase "process-probe" `
    -TimeoutSeconds 30 -HeartbeatSeconds 5
Assert-ToolchainTest ($processProbe.exitCode -eq 0) "Unified process runner did not return a successful exit code."
Assert-ToolchainTest ([long]$processProbe.durationMs -ge 0) "Unified process runner did not record duration."

$fixedRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityFixedAccountValidation.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $fixedRunnerSource.Contains('Write-UnityMigrationUtf8 -Path $resultPath -Content $previousResultContent')
) "Fixed-account runner no longer restores the preceding isolated validation result."
Assert-ToolchainTest (
    $fixedRunnerSource.Contains('Write-UnityMigrationUtf8 -Path $standardSummaryPath')
) "Fixed-account runner does not emit the standard G6-compatible summary."
Assert-ToolchainTest (
    $fixedRunnerSource.Contains('Invoke-UnityMigrationProcess -Executable $unityExecutable')
) "Fixed-account runner bypasses the unified Unity process runner."

$moduleRunnerSource = Get-Content -LiteralPath (Join-Path $PSScriptRoot "Run-UnityModuleValidation.ps1") `
    -Raw -Encoding UTF8
Assert-ToolchainTest (
    $moduleRunnerSource.Contains('Invoke-UnityMigrationProcess -Executable $unityExe')
) "Module runner bypasses the unified Unity process runner."
Assert-ToolchainTest (
    $moduleRunnerSource.Contains('Remove-UnityMigrationDisposableRole')
) "Module runner does not enforce disposable-role cleanup."

Write-Host "Unity migration toolchain tests passed: $passed"
