[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [switch]$RequireInputs,
    [datetime]$FreshAfterUtc = [datetime]::MinValue,
    [string]$JsonOutput = "",
    [string]$CocosBaselinePath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$matches = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($matches.Count -ne 1 -or $null -eq $matches[0].g5) {
    throw "Module '$Module' has no unique G5 evidence contract."
}
$contract = $matches[0]
$g5 = $contract.g5
$baselineInputs = @((Get-UnityMigrationPropertyValue -Object $g5 -Name "cocosBaselineInputs" -Default @()))
if ($baselineInputs.Count -eq 0) {
    throw "Module '$Module' G5 contract must freeze cocosBaselineInputs before G1."
}
$inputFingerprint = Get-UnityMigrationCocosBaselineFingerprint -Root $root -G5 $g5
$pairs = @($g5.pairs)
if ($pairs.Count -eq 0) { throw "Module '$Module' has no G5 state pairs." }
$supplementalPairs = @(Get-UnityMigrationPropertyValue -Object $g5 `
    -Name "supplementalReferencePairs" -Default @())
$ids = @($pairs | ForEach-Object { [string]$_.id })
$supplementalIds = @($supplementalPairs | ForEach-Object { [string]$_.id })
$allIds = @($ids + $supplementalIds)
$cocosNames = @($pairs | ForEach-Object { [string]$_.cocos })
$unityNames = @($pairs | ForEach-Object { [string]$_.unity })
foreach ($set in @($allIds, $cocosNames, $unityNames)) {
    if (@($set | Where-Object { -not $_ }).Count -gt 0 -or
        @($set | Sort-Object -Unique).Count -ne $set.Count) {
        throw "Module '$Module' G5 pair ids and filenames must be non-empty and unique."
    }
}
if ([int]$g5.width -ne 1334 -or [int]$g5.height -ne 750) {
    throw "Module '$Module' G5 contract must use native 1334x750."
}
$directories = @(
    [string]$g5.cocosDirectory,
    [string]$g5.unityDirectory,
    [string]$g5.compareDirectory
)
if (@($directories | Where-Object { -not $_ }).Count -gt 0 -or
    @($directories | Sort-Object -Unique).Count -ne 3) {
    throw "Module '$Module' G5 Cocos, Unity and compare directories must be non-empty and distinct."
}
$fixed = Get-UnityMigrationPropertyValue -Object $contract -Name "fixedAccount" -Default $null
if ($null -ne $fixed) {
    $copies = @($fixed.artifactCopies)
    $sources = @($copies | ForEach-Object { [string]$_.source })
    $destinations = @($copies | ForEach-Object { [string]$_.destination })
    if ($copies.Count -lt ($pairs.Count + $supplementalPairs.Count)) {
        throw "Module '$Module' fixed artifact count $($copies.Count) is smaller than total G5 state count $($pairs.Count + $supplementalPairs.Count)."
    }
    if (@($sources | Sort-Object -Unique).Count -ne $sources.Count -or
        @($destinations | Sort-Object -Unique).Count -ne $destinations.Count) {
        throw "Module '$Module' fixed-account screenshot source/destination paths must be unique."
    }
    $g5UnityDestinations = @(@($pairs + $supplementalPairs) | ForEach-Object {
        $unityDirectory = ([string]$g5.unityDirectory).TrimEnd([char[]]@('/', '\'))
        "$unityDirectory/$([string]$_.unity)"
    })
    $missingPairDestinations = @($g5UnityDestinations | Where-Object { $destinations -notcontains $_ })
    if ($missingPairDestinations.Count -gt 0) {
        throw "Module '$Module' fixed artifacts do not publish every G5 Unity input: $($missingPairDestinations -join ', ')."
    }
}
foreach ($pair in $supplementalPairs) {
    $referenceKind = [string](Get-UnityMigrationPropertyValue -Object $pair -Name "referenceKind" -Default "")
    $reason = [string](Get-UnityMigrationPropertyValue -Object $pair -Name "currentUnreachableReason" -Default "")
    $evidence = @(Get-UnityMigrationPropertyValue -Object $pair -Name "evidence" -Default @())
    if (-not [string]$pair.id -or -not [string]$pair.cocosPath -or -not [string]$pair.unity -or
        $referenceKind -ne "archived-current-unreachable" -or -not $reason -or $evidence.Count -eq 0) {
        throw "Module '$Module' supplemental G5 references require id, cocosPath, unity, archived-current-unreachable kind, reason and evidence."
    }
    foreach ($reference in $evidence) {
        $resolvedEvidence = Resolve-UnityMigrationPath -Root $root -Path ([string]$reference)
        if (-not (Test-Path -LiteralPath $resolvedEvidence -PathType Leaf)) {
            throw "Module '$Module' supplemental G5 reachability evidence is missing: $reference"
        }
    }
}

$states = New-Object System.Collections.Generic.List[object]
$hashes = New-Object System.Collections.Generic.List[object]
if ($RequireInputs) { Add-Type -AssemblyName System.Drawing }
foreach ($pair in $pairs) {
    $state = [ordered]@{ id = [string]$pair.id; inputsChecked = [bool]$RequireInputs }
    foreach ($side in @("cocos", "unity")) {
        $directory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5."${side}Directory")
        $path = Join-Path $directory ([string]$pair.$side)
        $state["${side}Path"] = [IO.Path]::GetRelativePath($root, $path).Replace('\', '/')
        if (-not $RequireInputs) { continue }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Module '$Module' G5 input is missing: $path"
        }
        $item = Get-Item -LiteralPath $path
        if ($FreshAfterUtc -ne [datetime]::MinValue -and
            $side -eq "unity" -and $item.LastWriteTimeUtc -lt $FreshAfterUtc.AddSeconds(-2)) {
            throw "Module '$Module' G5 Unity input is stale: $path"
        }
        $image = [System.Drawing.Image]::FromFile($path)
        try {
            if ($image.Width -ne [int]$g5.width -or $image.Height -ne [int]$g5.height) {
                throw "Module '$Module' G5 input has wrong size: $path ($($image.Width)x$($image.Height))"
            }
        }
        finally { $image.Dispose() }
        $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        $state["${side}Sha256"] = $sha
        if ($side -eq "unity") {
            $hashes.Add([pscustomobject]@{ id = [string]$pair.id; sha256 = $sha })
        }
    }
    $states.Add([pscustomobject]$state)
}
$supplementalStates = New-Object System.Collections.Generic.List[object]
foreach ($pair in $supplementalPairs) {
    $cocosPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$pair.cocosPath)
    $unityDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.unityDirectory)
    $unityPath = Join-Path $unityDirectory ([string]$pair.unity)
    $state = [ordered]@{
        id = [string]$pair.id
        inputsChecked = [bool]$RequireInputs
        referenceKind = [string]$pair.referenceKind
        currentReachable = $false
        currentUnreachableReason = [string]$pair.currentUnreachableReason
        cocosPath = [IO.Path]::GetRelativePath($root, $cocosPath).Replace('\', '/')
        unityPath = [IO.Path]::GetRelativePath($root, $unityPath).Replace('\', '/')
    }
    if ($RequireInputs) {
        foreach ($path in @($cocosPath, $unityPath)) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                throw "Module '$Module' supplemental G5 input is missing: $path"
            }
            $image = [System.Drawing.Image]::FromFile($path)
            try {
                if ($image.Width -ne [int]$g5.width -or $image.Height -ne [int]$g5.height) {
                    throw "Module '$Module' supplemental G5 input has wrong size: $path ($($image.Width)x$($image.Height))"
                }
            }
            finally { $image.Dispose() }
        }
        $state.cocosSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $cocosPath).Hash
        $state.unitySha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $unityPath).Hash
        $hashes.Add([pscustomobject]@{ id = [string]$pair.id; sha256 = $state.unitySha256 })
    }
    $supplementalStates.Add([pscustomobject]$state)
}
if ($RequireInputs) {
    if (-not $CocosBaselinePath) {
        $CocosBaselinePath = ".local/unity-validation/$(([string]$contract.module).ToLowerInvariant())-cocos-baseline-latest.json"
    }
    $baseline = Assert-UnityMigrationCocosBaseline -Root $root -Module $Module `
        -Path $CocosBaselinePath -RequireCurrentInputs
    $allowedDuplicateGroups = @(Get-UnityMigrationPropertyValue -Object $g5 `
        -Name "allowedDuplicateGroups" -Default @())
    Assert-UnityMigrationDuplicateHashPolicy -Items $hashes.ToArray() -IdentifierProperty "id" `
        -HashProperty "sha256" -AllowedDuplicateGroups $allowedDuplicateGroups `
        -Context "Module '$Module' G5 Unity states"
}

$result = [ordered]@{
    success = $true
    module = [string]$contract.module
    mode = $(if ($RequireInputs) { "inputs" } else { "contract" })
    contractFingerprint = Get-UnityMigrationG5ContractFingerprint -Contract $contract
    cocosBaselineInputFingerprint = $inputFingerprint
    cocosBaselineReused = [bool]$RequireInputs
    stateCount = $pairs.Count + $supplementalPairs.Count
    currentStateCount = $pairs.Count
    supplementalStateCount = $supplementalPairs.Count
    states = @($states.ToArray()) + @($supplementalStates.ToArray())
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}
if (-not $JsonOutput) {
    $JsonOutput = ".local/unity-validation/$(([string]$contract.module).ToLowerInvariant())-g5-preflight-latest.json"
}
$outputPath = Resolve-UnityMigrationPath -Root $root -Path $JsonOutput
Write-UnityMigrationUtf8 -Path $outputPath -Content (($result | ConvertTo-Json -Depth 8) + "`n")
Write-Host "G5 preflight passed: module=$Module mode=$($result.mode) states=$($pairs.Count) report=$outputPath"
