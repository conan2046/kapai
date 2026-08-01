[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [ValidateSet("Preflight", "PostRun", "G6")][string]$Phase = "Preflight",
    [string]$ManifestPath = "",
    [string]$SummaryPath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifestEntry = Import-UnityMigrationManifest -Root $root -ManifestPath $ManifestPath
$manifest = $manifestEntry.Value
$matches = @($manifest.modules | Where-Object { $_.key -ieq $Module })
if ($matches.Count -ne 1) { throw "Module '$Module' was not found exactly once." }
$moduleConfig = $matches[0]
$scenario = Get-UnityMigrationScenario -Root $root -ModuleKey ([string]$moduleConfig.key)
if ($null -eq $scenario) { throw "Module '$Module' has no validation scenario." }

Assert-UnityMigrationBootstrapContract -Root $root

$flags = @($scenario.flags | ForEach-Object { [string]$_ })
$captureStates = @($scenario.captureStates | ForEach-Object { [string]$_ })
$artifacts = @($scenario.artifacts)
if ($flags.Count -eq 0) { throw "Scenario '$($scenario.key)' has no validation flags." }
if ($captureStates.Count -eq 0) { throw "Scenario '$($scenario.key)' has no capture states." }
if (@($flags | Sort-Object -Unique).Count -ne $flags.Count) {
    throw "Scenario '$($scenario.key)' contains duplicate validation flags."
}
if (@($captureStates | Sort-Object -Unique).Count -ne $captureStates.Count) {
    throw "Scenario '$($scenario.key)' contains duplicate capture states."
}
$artifactPaths = @($artifacts | ForEach-Object { Get-UnityMigrationArtifactPath -Artifact $_ })
if (@($artifactPaths | Sort-Object -Unique).Count -ne $artifactPaths.Count) {
    throw "Scenario '$($scenario.key)' contains duplicate runtime artifacts."
}

$controlMatrix = [string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "controlMatrix" -Default "")
$requiredGate = [string](Get-UnityMigrationPropertyValue -Object $scenario -Name "requiredGate" -Default "")
if ($requiredGate -eq "G3" -and -not $controlMatrix) {
    throw "Interactive module '$Module' must declare controlMatrix before G4 validation."
}
$controlCount = 0
if ($controlMatrix) {
    $controlCount = Assert-UnityMigrationControlMatrixDeclared -Root $root -ModuleKey ([string]$moduleConfig.key) `
        -Path $controlMatrix -MinimumCaptureStates $captureStates.Count
}

if ($Phase -eq "Preflight") {
    Write-Host "Hard gates preflight passed: module=$Module scenario=$($scenario.key) controls=$controlCount captureStates=$($captureStates.Count)"
    exit 0
}

if (-not $SummaryPath) {
    $SummaryPath = ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-latest.json"
}
$resolvedSummary = Resolve-UnityMigrationPath -Root $root -Path $SummaryPath
if (-not (Test-Path -LiteralPath $resolvedSummary -PathType Leaf)) {
    throw "Validation summary is missing: $SummaryPath"
}
$summary = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolvedSummary | ConvertFrom-Json
if (-not [bool]$summary.success) { throw "Validation summary is not successful: $SummaryPath" }
$workflowPolicy = Assert-UnityMigrationWorkflowPolicy -Root $root
$batchFailures = @(Get-UnityMigrationBatchSummaryFailures -Summary $summary -Policy $workflowPolicy)
if ($batchFailures.Count -gt 0) {
    throw "Validation summary was not produced by the canonical batch workflow: $($batchFailures -join '; ')"
}
$summaryResultEvidence = [string](Get-UnityMigrationPropertyValue -Object $summary -Name "resultEvidence" -Default "")
$resultPath = if ($summaryResultEvidence) {
    Resolve-UnityMigrationPath -Root $root -Path $summaryResultEvidence
}
else {
    Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
}
if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
    throw "Unity result is missing: $resultPath"
}
$result = Get-Content -Raw -Encoding UTF8 -LiteralPath $resultPath | ConvertFrom-Json
if (-not [bool]$result.success -or [string]$result.status -notlike "COMPLETE:*") {
    throw "Unity result is not successful COMPLETE: $($result.status)"
}
$expectedUserId = [uint32](Get-UnityMigrationPropertyValue -Object $result -Name "userId" -Default 0)
Assert-UnityMigrationRunnerIdentity -Result $result -ScenarioKey ([string]$scenario.key) -ExpectedUserId $expectedUserId
$runtimeCoverage = Assert-UnityMigrationRunnerCoverage -Root $root -Result $result -Scenario $scenario `
    -ControlMatrix $controlMatrix
$contractEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/module-evidence-contracts.json"
$contractMatches = @($contractEntry.Value.modules | Where-Object { $_.module -ieq $Module })
$fixedAccount = if ($contractMatches.Count -eq 1) {
    Get-UnityMigrationPropertyValue -Object $contractMatches[0] -Name "fixedAccount" -Default $null
} else { $null }
$identityFailures = @(Get-UnityMigrationSummaryIdentityFailures -Summary $summary -Result $result `
    -FixedAccount $fixedAccount)
if ($identityFailures.Count -gt 0) {
    throw "Validation identity failed: $($identityFailures -join '; ')"
}
if (@($summary.captureStates).Count -ne $captureStates.Count -or
    (@($summary.captureStates) -join "`n") -ne ($captureStates -join "`n")) {
    throw "Validation summary captureStates do not match scenario '$($scenario.key)'."
}
if (@($summary.screenshots).Count -ne $artifacts.Count) {
    throw "Validation summary screenshot count does not match runtime artifact count."
}
if ((@($summary.validatedControlIds) -join "`n") -ne (@($runtimeCoverage.validatedControlIds) -join "`n") -or
    (@($summary.passedSemanticAssertions) -join "`n") -ne (@($runtimeCoverage.passedSemanticAssertions) -join "`n")) {
    throw "Validation summary runtime coverage does not match the Unity result."
}

if ($Phase -eq "G6") {
    if (-not $controlMatrix) { throw "G6 hard gates require a control matrix." }
    if ($IsWindows) {
        $computerUseRuntimeProcesses = @(Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            $_.Name -in @("node_repl.exe", "codex-computer-use.exe") -and
            [string]$_.CommandLine -match 'OpenAI\\Codex\\runtimes\\cua_node|computer-use-client|codex-computer-use'
        })
        if ($computerUseRuntimeProcesses.Count -gt 0) {
            $processDetails = @($computerUseRuntimeProcesses | ForEach-Object { "PID=$($_.ProcessId) Name=$($_.Name)" }) -join '; '
            throw "G6 Computer Use runtime must be stopped after Cocos evidence: $processDetails"
        }
    }
    $idempotencePath = Join-Path $root ".local\unity-validation\bootstrap-idempotence-latest.json"
    if (-not (Test-Path -LiteralPath $idempotencePath -PathType Leaf)) {
        throw "G6 hard gates require the Bootstrap idempotence summary."
    }
    $idempotence = Get-Content -Raw -Encoding UTF8 -LiteralPath $idempotencePath | ConvertFrom-Json
    $hashes = @($idempotence.hashes)
    if (-not [bool]$idempotence.success -or
        [string]$idempotence.method -ne "ProjectX.Editor.BootstrapSceneBuilder.BuildBatch" -or
        [int]$idempotence.attempts -ne 2 -or $hashes.Count -ne 2 -or $hashes[0] -ne $hashes[1]) {
        throw "G6 Bootstrap idempotence evidence is invalid or did not use BuildBatch twice."
    }
    $completeCount = Assert-UnityMigrationControlMatrix -Root $root -ModuleKey ([string]$moduleConfig.key) -Path $controlMatrix
    Write-Host "Hard gates G6 passed: module=$Module controls=$completeCount bootstrapSha256=$($hashes[0])"
    exit 0
}

Write-Host "Hard gates post-run passed: module=$Module user=$($result.userId) role=$($result.roleId) screenshots=$(@($summary.screenshots).Count)"
