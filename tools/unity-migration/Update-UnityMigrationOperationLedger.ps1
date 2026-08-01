[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [Parameter(Mandatory = $true)][ValidatePattern('^G[0-6]$')][string]$Gate,
    [Parameter(Mandatory = $true)][string]$Tool,
    [Parameter(Mandatory = $true)][string]$Operation,
    [Parameter(Mandatory = $true)][ValidateSet("Passed", "Failed", "Blocked", "Resolved")][string]$Outcome,
    [ValidateSet("General", "CocosAutomation", "UnityBatch", "Gate")][string]$Category = "General",
    [string]$ErrorMessage = "",
    [string]$RootCause = "",
    [string]$RelatedRecordId = "",
    [string]$Resolution = "",
    [string]$IterationAction = "",
    [string[]]$IterationEvidence = @(),
    [string[]]$Evidence = @(),
    [string]$TargetId = "",
    [string]$CapturePath = "",
    [int]$Width = 0,
    [int]$Height = 0,
    [string]$OperationLedgerPath = "",
    [string]$CocosAutomationLedgerPath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot

if ($Category -eq "CocosAutomation" -and $Outcome -eq "Passed") {
    if ($Tool -ne "computer-use@openai-bundled") {
        throw "Passed Cocos automation must use computer-use@openai-bundled."
    }
    if (-not $TargetId -or -not $CapturePath -or $Width -ne 1334 -or $Height -ne 750) {
        throw "Passed Cocos automation requires TargetId, CapturePath and 1334x750 dimensions."
    }
    $resolvedCapture = Resolve-UnityMigrationPath -Root $root -Path $CapturePath
    if (-not (Test-Path -LiteralPath $resolvedCapture -PathType Leaf)) {
        throw "Cocos window capture is missing: $CapturePath"
    }
    if (-not $CocosAutomationLedgerPath) {
        $CocosAutomationLedgerPath = ".local/unity-validation/$($Module.ToLowerInvariant())-cocos-automation-ledger.json"
    }
    $resolvedCocosLedger = Resolve-UnityMigrationPath -Root $root -Path $CocosAutomationLedgerPath
    if (Test-Path -LiteralPath $resolvedCocosLedger -PathType Leaf) {
        $cocosLedger = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolvedCocosLedger | ConvertFrom-Json
        $identityFailures = @(Get-UnityMigrationCocosAutomationLedgerFailures -Ledger $cocosLedger `
            -ExpectedModule $Module)
        if (@($identityFailures | Where-Object { $_ -notlike "*has no attempts*" }).Count -gt 0) {
            throw "Existing Cocos automation ledger is invalid: $($identityFailures -join '; ')"
        }
        if (@($cocosLedger.attempts | Where-Object { [string]$_.targetId -ieq $TargetId }).Count -gt 0) {
            throw "Cocos target '$TargetId' already has accepted evidence. Diagnose instead of overwriting it."
        }
    }
    else {
        $cocosLedger = [pscustomobject][ordered]@{
            schemaVersion = 1
            module = $Module
            workflowPolicyVersion = 1
            tool = "computer-use@openai-bundled"
            requestedAppReference = "plugin://computer-use@openai-bundled?app=com.adspower.global"
            targetProcess = "ProjectX.exe"
            targetWindow = "Cocos Simulator"
            approvalMode = "routine-project-actions-preapproved"
            attempts = @()
        }
    }
}

$recordResult = Add-UnityMigrationOperationRecord -Root $root -Module $Module -Gate $Gate `
    -Tool $Tool -Operation $Operation -Outcome $Outcome -Category $Category `
    -ErrorMessage $ErrorMessage -RootCause $RootCause -RelatedRecordId $RelatedRecordId `
    -Resolution $Resolution -IterationAction $IterationAction -IterationEvidence $IterationEvidence `
    -Evidence $Evidence -TargetId $TargetId -Path $OperationLedgerPath

if ($Category -eq "CocosAutomation" -and $Outcome -eq "Passed") {
    $attempt = [pscustomobject][ordered]@{
        targetId = $TargetId
        attemptNumber = 1
        desktopCapture = $false
        capturePath = $CapturePath
        width = $Width
        height = $Height
        operationRecordId = [string]$recordResult.Record.recordId
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    $cocosLedger.attempts = @($cocosLedger.attempts) + @($attempt)
    Write-UnityMigrationUtf8 -Path $resolvedCocosLedger -Content (($cocosLedger | ConvertTo-Json -Depth 12) + "`n")
    Write-Host "Cocos evidence ledger: $resolvedCocosLedger"
}

Write-Host "Operation record: $($recordResult.Record.recordId) outcome=$Outcome"
Write-Host "Operation ledger: $($recordResult.Path)"
