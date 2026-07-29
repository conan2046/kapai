[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [switch]$RequireInputs,
    [datetime]$FreshAfterUtc = [datetime]::MinValue,
    [string]$JsonOutput = ""
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
$pairs = @($g5.pairs)
if ($pairs.Count -eq 0) { throw "Module '$Module' has no G5 state pairs." }
$ids = @($pairs | ForEach-Object { [string]$_.id })
$cocosNames = @($pairs | ForEach-Object { [string]$_.cocos })
$unityNames = @($pairs | ForEach-Object { [string]$_.unity })
foreach ($set in @($ids, $cocosNames, $unityNames)) {
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
$fixed = $contract.fixedAccount
if ($null -ne $fixed) {
    $copies = @($fixed.artifactCopies)
    $sources = @($copies | ForEach-Object { [string]$_.source })
    $destinations = @($copies | ForEach-Object { [string]$_.destination })
    if ($copies.Count -ne $pairs.Count) {
        throw "Module '$Module' fixed artifact count $($copies.Count) does not match G5 pair count $($pairs.Count)."
    }
    if (@($sources | Sort-Object -Unique).Count -ne $sources.Count -or
        @($destinations | Sort-Object -Unique).Count -ne $destinations.Count) {
        throw "Module '$Module' fixed-account screenshot source/destination paths must be unique."
    }
}

$states = New-Object System.Collections.Generic.List[object]
$hashes = New-Object System.Collections.Generic.List[string]
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
        if ($side -eq "unity") { $hashes.Add($sha) }
    }
    $states.Add([pscustomobject]$state)
}
if ($RequireInputs -and @($hashes | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
    throw "Module '$Module' G5 Unity states contain duplicate screenshot content; possible path overwrite or wrong page capture."
}

$result = [ordered]@{
    success = $true
    module = [string]$contract.module
    mode = $(if ($RequireInputs) { "inputs" } else { "contract" })
    contractFingerprint = Get-UnityMigrationG5ContractFingerprint -Contract $contract
    stateCount = $pairs.Count
    states = @($states.ToArray())
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}
if (-not $JsonOutput) {
    $JsonOutput = ".local/unity-validation/$(([string]$contract.module).ToLowerInvariant())-g5-preflight-latest.json"
}
$outputPath = Resolve-UnityMigrationPath -Root $root -Path $JsonOutput
Write-UnityMigrationUtf8 -Path $outputPath -Content (($result | ConvertTo-Json -Depth 8) + "`n")
Write-Host "G5 preflight passed: module=$Module mode=$($result.mode) states=$($pairs.Count) report=$outputPath"
