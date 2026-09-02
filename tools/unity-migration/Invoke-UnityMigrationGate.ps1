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
    [string]$EarlyUserPlayPath = "",
    [string]$SummaryPath = "",
    [switch]$StartTiming,
    [switch]$Complete,
    [switch]$InvalidateFrom,
    [string]$InvalidationReason = "",
    [string]$RegistryPath = "tools/unity-migration/migration-gates.json"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$gateInvocationTiming = Start-UnityMigrationTiming
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

if ($InvalidateFrom) {
    if ($StartTiming -or $Complete) {
        throw "-InvalidateFrom cannot be combined with -StartTiming or -Complete."
    }
    if (-not $InvalidationReason.Trim()) {
        throw "-InvalidateFrom requires -InvalidationReason."
    }

    $invalidatedUtc = [DateTime]::UtcNow.ToString("O")
    if ($null -eq $record.PSObject.Properties["gateEvidence"]) {
        $record | Add-Member -NotePropertyName gateEvidence -NotePropertyValue ([pscustomobject]@{})
    }
    if ($null -eq $record.PSObject.Properties["gateInvalidations"]) {
        $record | Add-Member -NotePropertyName gateInvalidations -NotePropertyValue ([pscustomobject]@{})
    }
    if ($null -eq $record.PSObject.Properties["gateTimings"]) {
        $record | Add-Member -NotePropertyName gateTimings -NotePropertyValue ([pscustomobject]@{})
    }

    $invalidated = New-Object System.Collections.Generic.List[string]
    for ($index = $gateNumber; $index -le 6; $index++) {
        $targetGate = "G$index"
        $previousState = [string](Get-UnityMigrationPropertyValue -Object $record.gates -Name $targetGate -Default "pending")
        $previousEvidence = @()
        if ($null -ne $record.gateEvidence.PSObject.Properties[$targetGate]) {
            $previousEvidence = @($record.gateEvidence.$targetGate)
        }
        $record.gates | Add-Member -Force -NotePropertyName $targetGate -NotePropertyValue "pending"
        $record.gateEvidence | Add-Member -Force -NotePropertyName $targetGate -NotePropertyValue @()
        $record.gateInvalidations | Add-Member -Force -NotePropertyName $targetGate -NotePropertyValue ([pscustomobject][ordered]@{
            invalidatedUtc = $invalidatedUtc
            previousState = $previousState
            previousEvidence = $previousEvidence
            reason = $InvalidationReason
        })
        $record.gateTimings | Add-Member -Force -NotePropertyName $targetGate -NotePropertyValue ([pscustomobject][ordered]@{
            startedUtc = $invalidatedUtc
            startSource = "invalidation"
        })
        $invalidated.Add($targetGate)
    }

    $record | Add-Member -Force -NotePropertyName updatedUtc -NotePropertyValue $invalidatedUtc
    Write-UnityMigrationUtf8 -Path $entry.Path -Content (($entry.Value | ConvertTo-Json -Depth 14) + "`n")
    Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $Gate -Category Gate `
        -Tool "tools/unity-migration/Invoke-UnityMigrationGate.ps1" -Operation "invalidate-from-$Gate" `
        -Outcome Passed -Evidence @($RegistryPath) | Out-Null
    Write-Host "$Module invalidated $($invalidated -join ',') from ${Gate}: $InvalidationReason"
    exit 0
}

if ($gateNumber -gt 0) {
    Assert-UnityMigrationGatePrerequisite -Root $root -ModuleKey $Module -RequiredGate ("G{0}" -f ($gateNumber - 1))
}

if ($StartTiming) {
    if ($Complete) { throw "-StartTiming and -Complete cannot be used together." }
    $current = [string](Get-UnityMigrationPropertyValue -Object $record.gates -Name $Gate -Default "pending")
    if ($current -eq "passed") { throw "Cannot start timing for completed gate $Module $Gate." }
    $now = [DateTime]::UtcNow.ToString("O")
    $record | Add-Member -Force -NotePropertyName timingPolicyVersion -NotePropertyValue 1
    if (-not [string](Get-UnityMigrationPropertyValue -Object $record -Name "timingPolicyStartedUtc" -Default "")) {
        $record | Add-Member -Force -NotePropertyName timingPolicyStartedUtc -NotePropertyValue $now
    }
    if ($null -eq $record.PSObject.Properties["gateTimings"]) {
        $record | Add-Member -NotePropertyName gateTimings -NotePropertyValue ([pscustomobject]@{})
    }
    if ($null -eq $record.gateTimings.PSObject.Properties[$Gate]) {
        $record.gateTimings | Add-Member -NotePropertyName $Gate -NotePropertyValue ([pscustomobject][ordered]@{
            startedUtc = $now
            startSource = "explicit-start"
        })
        Write-UnityMigrationUtf8 -Path $entry.Path -Content (($entry.Value | ConvertTo-Json -Depth 12) + "`n")
        Write-Host "$Module $Gate timing started at $now. Historical gates were not backfilled."
    }
    else {
        Write-Host "$Module $Gate timing already started at $($record.gateTimings.$Gate.startedUtc)."
    }
    exit 0
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
    $matrix = (Import-UnityMigrationJson -Root $root -Path $declaredMatrix).Value
    $coverage = Assert-UnityMigrationCoverageList -Root $root -ModuleKey $Module -Matrix $matrix
    $g0DraftPath = [string](Get-UnityMigrationPropertyValue -Object $moduleConfig -Name "g0Draft" -Default "")
    if ($g0DraftPath) {
        Assert-UnityMigrationG0Draft -Root $root -Module $Module -Path $g0DraftPath | Out-Null
        if (-not (Test-GateEvidenceContainsPath $g0DraftPath)) { $Evidence = @($Evidence) + @($g0DraftPath) }
    }
    Write-Host "$Module G0 scope frozen: $declaredCount controls, $($coverage.BusinessIdCount) business ids from $($coverage.SourceCount) sources."
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
    if (-not $EarlyUserPlayPath) {
        throw "Completing G4 requires -EarlyUserPlayPath from the post-G3 user Play checkpoint."
    }
    if (-not (Test-GateEvidenceContainsPath $EarlyUserPlayPath)) {
        throw "G4 Evidence must include the post-G3 early user Play record path."
    }
    $earlyPlayEntry = Import-UnityMigrationJson -Root $root -Path $EarlyUserPlayPath
    $earlyPlayFailures = @(Get-UnityMigrationEarlyUserPlayFailures -Record $earlyPlayEntry.Value -ExpectedModule $Module)
    if ($earlyPlayFailures.Count -gt 0) {
        throw "G4 early user Play checkpoint failed: $($earlyPlayFailures -join '; ')"
    }
    foreach ($recheckEvidence in @($earlyPlayEntry.Value.agentRecheck.evidence)) {
        $resolvedRecheck = Resolve-UnityMigrationPath -Root $root -Path ([string]$recheckEvidence)
        if (-not (Test-Path -LiteralPath $resolvedRecheck)) {
            throw "G4 early user Play agent recheck evidence missing: $recheckEvidence"
        }
    }
    if ((Get-UnityMigrationPropertyValue -Object $earlyPlayEntry.Value -Name "userDelegatedAgentPlay" -Default $false) -eq $true) {
        $delegation = Get-UnityMigrationPropertyValue -Object $earlyPlayEntry.Value -Name "delegation" -Default $null
        $delegationEvidence = [string](Get-UnityMigrationPropertyValue -Object $delegation -Name "evidence" -Default "")
        $resolvedDelegation = Resolve-UnityMigrationPath -Root $root -Path $delegationEvidence
        if (-not (Test-Path -LiteralPath $resolvedDelegation -PathType Leaf)) {
            throw "G4 delegated early Play authorization evidence missing: $delegationEvidence"
        }
    }
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
    if ($null -eq $record.PSObject.Properties["gateEvidence"]) {
        $record | Add-Member -NotePropertyName gateEvidence -NotePropertyValue ([pscustomobject]@{})
    }
    $record.gateEvidence | Add-Member -Force -NotePropertyName $Gate -NotePropertyValue @($Evidence)
    if ($null -eq $record.PSObject.Properties["gateRevalidations"]) {
        $record | Add-Member -NotePropertyName gateRevalidations -NotePropertyValue ([pscustomobject]@{})
    }
    $record.gateRevalidations | Add-Member -Force -NotePropertyName $Gate -NotePropertyValue ([pscustomobject][ordered]@{
        checkedUtc = [DateTime]::UtcNow.ToString("O")
        evidence = @($Evidence)
    })
    $record | Add-Member -Force -NotePropertyName updatedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
    Write-UnityMigrationUtf8 -Path $entry.Path -Content (($entry.Value | ConvertTo-Json -Depth 12) + "`n")
    Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $Gate -Category Gate `
        -Tool "tools/unity-migration/Invoke-UnityMigrationGate.ps1" -Operation "revalidate-$Gate" `
        -Outcome Passed -Evidence $Evidence | Out-Null
    Write-Host "$Module $Gate revalidated current evidence; passed status and original timing retained."
    exit 0
}

$record.gates.$Gate = "passed"
$completedUtc = [DateTime]::UtcNow
if ([int](Get-UnityMigrationPropertyValue -Object $record -Name "timingPolicyVersion" -Default 0) -ge 1) {
    if ($null -eq $record.PSObject.Properties["gateTimings"]) {
        $record | Add-Member -NotePropertyName gateTimings -NotePropertyValue ([pscustomobject]@{})
    }
    $clock = $record.gateTimings.PSObject.Properties[$Gate]
    if ($null -eq $clock) {
        $record.gateTimings | Add-Member -NotePropertyName $Gate -NotePropertyValue ([pscustomobject][ordered]@{
            startedUtc = $completedUtc.ToString("O")
            startSource = "completion-invocation"
        })
    }
    $gateClock = $record.gateTimings.$Gate
    $startedUtc = [DateTime][string]$gateClock.startedUtc
    $gateInvocationTiming.stopwatch.Stop()
    $gateClock | Add-Member -Force -NotePropertyName completedUtc -NotePropertyValue $completedUtc.ToString("O")
    $gateClock | Add-Member -Force -NotePropertyName calendarDurationMs -NotePropertyValue ([long]($completedUtc - $startedUtc).TotalMilliseconds)
    $gateClock | Add-Member -Force -NotePropertyName completionCheckDurationMs -NotePropertyValue ([long]$gateInvocationTiming.stopwatch.ElapsedMilliseconds)
    if ($gateNumber -lt 6) {
        $nextGate = "G{0}" -f ($gateNumber + 1)
        if ($null -eq $record.gateTimings.PSObject.Properties[$nextGate]) {
            $record.gateTimings | Add-Member -NotePropertyName $nextGate -NotePropertyValue ([pscustomobject][ordered]@{
                startedUtc = $completedUtc.ToString("O")
                startSource = "previous-gate-complete"
            })
        }
    }
}
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
if ($Gate -eq "G6" -and [int](Get-UnityMigrationPropertyValue -Object $record -Name "timingPolicyVersion" -Default 0) -ge 1) {
    New-UnityMigrationRetrospective -Root $root -Module $Module -RequireEvidenceFiles | Out-Null
}
Write-Host "$Module $Gate completed with $($Evidence.Count) evidence path(s)."
