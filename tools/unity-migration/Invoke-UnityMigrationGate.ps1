[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [Parameter(Mandatory = $true)][ValidatePattern('^G[0-6]$')][string]$Gate,
    [string[]]$Evidence = @(),
    [string]$ControlMatrixPath = "",
    [string]$CocosAutomationLedgerPath = "",
    [string]$CocosPreflightPath = "",
    [string]$CocosIdentityPath = "",
    [string]$CocosBaselinePath = "",
    [string]$SummaryPath = "",
    [switch]$Complete,
    [string]$RegistryPath = "tools/unity-migration/migration-gates.json"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$entry = Import-UnityMigrationJson -Root $root -Path $RegistryPath
$matches = @($entry.Value.modules | Where-Object { $_.module -ieq $Module })
if ($matches.Count -ne 1) { throw "Module '$Module' has no unique gate record." }
$record = $matches[0]
$gateNumber = [int]$Gate.Substring(1)
$manifest = (Import-UnityMigrationManifest -Root $root).Value
$moduleMatches = @($manifest.modules | Where-Object { $_.key -ieq $Module })
if ($moduleMatches.Count -ne 1) { throw "Module '$Module' has no unique manifest entry." }
$moduleConfig = $moduleMatches[0]
$scenario = Get-UnityMigrationScenario -Root $root -ModuleKey ([string]$moduleConfig.key)
if ($null -eq $scenario) { throw "Module '$Module' has no validation scenario." }

trap {
    try {
        Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $Gate -Category Gate `
            -Tool "tools/unity-migration/Invoke-UnityMigrationGate.ps1" -Operation "complete-$Gate" `
            -Outcome Failed -ErrorMessage $_.Exception.Message -RootCause "pending-diagnosis" | Out-Null
    }
    catch { Write-Warning "Could not record gate failure: $($_.Exception.Message)" }
    throw
}

function Test-GateEvidenceContainsPath([string]$Candidate) {
    if (-not $Candidate) { return $false }
    $resolvedCandidate = Resolve-UnityMigrationPath -Root $root -Path $Candidate
    foreach ($item in $Evidence) {
        if ((Resolve-UnityMigrationPath -Root $root -Path $item) -ieq $resolvedCandidate) { return $true }
    }
    return $false
}

if ($gateNumber -gt 0) {
    Assert-UnityMigrationGatePrerequisite -Root $root -ModuleKey $Module -RequiredGate ("G{0}" -f ($gateNumber - 1))
}

foreach ($path in $Evidence) {
    $resolved = Resolve-UnityMigrationPath -Root $root -Path $path
    if (-not (Test-Path -LiteralPath $resolved)) { throw "Gate evidence missing: $path" }
}

$current = [string](Get-UnityMigrationPropertyValue -Object $record.gates -Name $Gate -Default "pending")
if (-not $Complete) {
    Write-Host "$Module $Gate=$current; prerequisites and $($Evidence.Count) evidence path(s) passed."
    exit 0
}
if ($Evidence.Count -eq 0) { throw "Completing $Gate requires at least one evidence path." }
if ($Gate -eq "G0") {
    $declaredMatrix = [string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "controlMatrix" -Default "")
    if (-not $declaredMatrix) { throw "Completing G0 requires a manifest controlMatrix." }
    $declaredCount = Assert-UnityMigrationControlMatrixDeclared -Root $root -ModuleKey $Module `
        -Path $declaredMatrix -RequireLifecycleFields
    Assert-UnityMigrationModuleWorkflowContract -Root $root -ModuleConfig $moduleConfig `
        -Scenario $scenario -Phase G0 | Out-Null
    Write-Host "$Module G0 control matrix schema frozen: $declaredCount controls."
}
if ($Gate -eq "G1") {
    if (-not $CocosAutomationLedgerPath) {
        throw "Completing G1 requires -CocosAutomationLedgerPath produced from Computer Use ProjectX/Cocos Simulator evidence."
    }
    if (-not (Test-GateEvidenceContainsPath $CocosAutomationLedgerPath)) {
        throw "G1 Evidence must include the Cocos automation ledger path."
    }
    foreach ($required in @(
        @("CocosPreflightPath", $CocosPreflightPath),
        @("CocosIdentityPath", $CocosIdentityPath),
        @("CocosBaselinePath", $CocosBaselinePath)
    )) {
        if (-not [string]$required[1]) { throw "Completing G1 requires -$($required[0])." }
        if (-not (Test-GateEvidenceContainsPath ([string]$required[1]))) {
            throw "G1 Evidence must include -$($required[0])."
        }
    }
    $attemptCount = Assert-UnityMigrationCocosAutomationLedger -Root $root -Module $Module `
        -Path $CocosAutomationLedgerPath
    $matrix = (Import-UnityMigrationJson -Root $root -Path ([string]$moduleConfig.controlMatrix)).Value
    Assert-UnityMigrationCocosPreflight -Root $root -Module $Module -Path $CocosPreflightPath | Out-Null
    Assert-UnityMigrationCocosIdentityEvidence -Root $root -Module $Module -Path $CocosIdentityPath -Matrix $matrix | Out-Null
    $baseline = Assert-UnityMigrationCocosBaseline -Root $root -Module $Module -Path $CocosBaselinePath -RequireCurrentInputs
    Write-Host "$Module G1 Cocos evidence passed: controls=$attemptCount reusableG5States=$(@($baseline.states).Count)."
}
if ($Gate -eq "G2") {
    $declaredMatrix = [string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "controlMatrix" -Default "")
    $gapCount = Assert-UnityMigrationSourceAudit -Root $root -Module $Module -MatrixPath $declaredMatrix
    Write-Host "$Module G2 source audit passed: entry/protocol/config-asset/runtime-transform closures complete; knownGaps=$gapCount."
}
if ($Gate -eq "G3") {
    Assert-UnityMigrationModuleWorkflowContract -Root $root -ModuleConfig $moduleConfig `
        -Scenario $scenario -Phase G3 | Out-Null
    Write-Host "$Module G3 workflow contract passed: batch scenario, coverage, semantics, source, visuals and fixture are frozen."
}
if ($Gate -eq "G4") {
    if (-not $SummaryPath) {
        throw "Completing G4 requires -SummaryPath from the canonical Unity batch runner."
    }
    if (-not (Test-GateEvidenceContainsPath $SummaryPath)) {
        throw "G4 Evidence must include the canonical batch summary path."
    }
    & pwsh -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityMigrationHardGates.ps1") `
        -Module $Module -Phase PostRun -SummaryPath $SummaryPath
    if ($LASTEXITCODE -ne 0) { throw "G4 batch hard-gate verification failed with exit code $LASTEXITCODE" }
}
if ($Gate -eq "G5") {
    & pwsh -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityModuleG5Preflight.ps1") `
        -Module $Module -RequireInputs
    if ($LASTEXITCODE -ne 0) { throw "G5 input preflight failed with exit code $LASTEXITCODE" }
}
if ($Gate -eq "G6") {
    if (-not $ControlMatrixPath) { throw "Completing G6 requires -ControlMatrixPath." }
    if ($SummaryPath) {
        & pwsh -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityMigrationHardGates.ps1") `
            -Module $Module -Phase G6 -SummaryPath $SummaryPath
    }
    else {
        & pwsh -NoProfile -File (Join-Path $root "tools/unity-migration/Test-UnityMigrationHardGates.ps1") `
            -Module $Module -Phase G6
    }
    if ($LASTEXITCODE -ne 0) { throw "G6 hard-gate verification failed with exit code $LASTEXITCODE" }
    $controlCount = Assert-UnityMigrationControlMatrix -Root $root -ModuleKey $Module -Path $ControlMatrixPath
    $retrospective = New-UnityMigrationRetrospective -Root $root -Module $Module -RequireEvidenceFiles
    if ([int]$retrospective.Summary.unresolvedCount -gt 0) {
        throw "G6 retrospective has unresolved failures: $($retrospective.Summary.unresolved -join '; ')"
    }
    if ([int]$retrospective.Summary.pendingDiagnosisCount -gt 0) {
        throw "G6 retrospective still contains pending effective diagnoses: $($retrospective.Summary.pendingDiagnosisCount)"
    }
    $retrospectiveRelative = [IO.Path]::GetRelativePath($root, $retrospective.Path).Replace('\', '/')
    $Evidence = @($Evidence) + @($retrospectiveRelative)
    Write-Host "$Module automatic retrospective passed: failures=$($retrospective.Summary.failedOrBlockedCount), resolved=$($retrospective.Summary.resolvedCount)."
    Write-Host "$Module control matrix passed: $controlCount/$controlCount controls complete."
}
if ($current -eq "passed") {
    Write-Host "$Module $Gate is already passed; no registry change."
    exit 0
}

$record.gates.$Gate = "passed"
$evidenceProperty = $record.PSObject.Properties["gateEvidence"]
if ($null -eq $evidenceProperty) {
    $record | Add-Member -NotePropertyName gateEvidence -NotePropertyValue ([pscustomobject]@{})
}
$record.gateEvidence | Add-Member -Force -NotePropertyName $Gate -NotePropertyValue @($Evidence)
$record | Add-Member -Force -NotePropertyName updatedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $Gate -Category Gate `
    -Tool "tools/unity-migration/Invoke-UnityMigrationGate.ps1" -Operation "complete-$Gate" `
    -Outcome Passed -Evidence $Evidence | Out-Null
Write-UnityMigrationUtf8 -Path $entry.Path -Content (($entry.Value | ConvertTo-Json -Depth 12) + "`n")
Write-Host "$Module $Gate completed with $($Evidence.Count) evidence path(s)."
