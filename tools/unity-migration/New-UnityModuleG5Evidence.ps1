[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [string]$PythonExecutable = "python"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
& (Join-Path $PSScriptRoot "Test-UnityModuleG5Preflight.ps1") -Module $Module -RequireInputs
$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$contract = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($contract.Count -ne 1 -or $null -eq $contract[0].g5) {
    throw "Module '$Module' has no unique G5 evidence contract."
}
$fixed = Get-UnityMigrationPropertyValue -Object $contract[0] -Name "fixedAccount" -Default $null
$g5 = $contract[0].g5
$cocosDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.cocosDirectory)
$unityDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.unityDirectory)
$compareDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.compareDirectory)
$comparisonScript = Join-Path $root "tools/unity-migration/New-UiFidelityComparison.py"
$contactScript = Join-Path $root "tools/unity-migration/New-UiFidelityContactSheet.py"
[IO.Directory]::CreateDirectory($compareDirectory) | Out-Null

$supplementalPairs = @(Get-UnityMigrationPropertyValue -Object $g5 `
    -Name "supplementalReferencePairs" -Default @())
$comparisonPairs = @(
    foreach ($pair in @($g5.pairs)) {
        [pscustomobject]@{
            id = [string]$pair.id
            cocosPath = Join-Path $cocosDirectory ([string]$pair.cocos)
            unityPath = Join-Path $unityDirectory ([string]$pair.unity)
            referenceKind = "current-fixed-identity"
            currentReachable = $true
            currentUnreachableReason = ""
        }
    }
    foreach ($pair in $supplementalPairs) {
        [pscustomobject]@{
            id = [string]$pair.id
            cocosPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$pair.cocosPath)
            unityPath = Join-Path $unityDirectory ([string]$pair.unity)
            referenceKind = [string]$pair.referenceKind
            currentReachable = $false
            currentUnreachableReason = [string]$pair.currentUnreachableReason
        }
    }
)
$pairIds = @($comparisonPairs | ForEach-Object { [string]$_.id })
if ($pairIds.Count -eq 0 -or @($pairIds | Sort-Object -Unique).Count -ne $pairIds.Count) {
    throw "Module '$Module' G5 pairs are empty or contain duplicate ids."
}
$reports = foreach ($pair in $comparisonPairs) {
    $cocos = [string]$pair.cocosPath
    $unity = [string]$pair.unityPath
    foreach ($path in @($cocos, $unity)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing G5 evidence: $path" }
    }
    & $PythonExecutable $comparisonScript --cocos $cocos --unity $unity `
        --output $compareDirectory --name ([string]$pair.id) | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "G5 comparison failed: $($pair.id)" }
    $report = Get-Content -LiteralPath (Join-Path $compareDirectory "$($pair.id)-report.json") `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$report.size[0] -ne [int]$g5.width -or [int]$report.size[1] -ne [int]$g5.height) {
        throw "G5 comparison has wrong native size: $($pair.id)"
    }
    $report | Add-Member -NotePropertyName cocosSha256 `
        -NotePropertyValue (Get-FileHash -Algorithm SHA256 -LiteralPath $cocos).Hash
    $report | Add-Member -NotePropertyName unitySha256 `
        -NotePropertyValue (Get-FileHash -Algorithm SHA256 -LiteralPath $unity).Hash
    $report | Add-Member -NotePropertyName referenceKind -NotePropertyValue ([string]$pair.referenceKind)
    $report | Add-Member -NotePropertyName currentReachable -NotePropertyValue ([bool]$pair.currentReachable)
    if (-not [bool]$pair.currentReachable) {
        $report | Add-Member -NotePropertyName currentUnreachableReason `
            -NotePropertyValue ([string]$pair.currentUnreachableReason)
    }
    $report
}
$git = "C:/Program Files/Git/cmd/git.exe"
$sourceCommit = (& $git -C $root rev-parse HEAD).Trim()
$summaryUserId = if ($null -ne $fixed) { [uint32]$fixed.userId } else {
    [uint32](Get-UnityMigrationPropertyValue -Object $g5.identity -Name "primaryUserId" -Default 0)
}
$summaryRoleId = if ($null -ne $fixed) { [uint32]$fixed.roleId } else {
    [uint32](Get-UnityMigrationPropertyValue -Object $g5.identity -Name "primaryRoleId" -Default 0)
}
if ($summaryUserId -eq 0 -or $summaryRoleId -eq 0) {
    throw "Module '$Module' G5 evidence contract has no authoritative primary identity."
}
$summary = [ordered]@{
    schemaVersion = 2
    module = [string]$contract[0].module
    userId = $summaryUserId
    roleId = $summaryRoleId
    sourceCommit = $sourceCommit
    stateCount = $reports.Count
    currentStateCount = @($comparisonPairs | Where-Object currentReachable).Count
    supplementalStateCount = @($comparisonPairs | Where-Object { -not $_.currentReachable }).Count
    imageSize = @{ width = [int]$g5.width; height = [int]$g5.height }
    states = $reports
    generatedUtc = [DateTime]::UtcNow.ToString("O")
}
Write-UnityMigrationUtf8 -Path (Join-Path $compareDirectory "report.json") `
    -Content (($summary | ConvertTo-Json -Depth 10) + "`n")
& $PythonExecutable $contactScript --input $compareDirectory --output $compareDirectory `
    --per-page 6 --columns 2 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "G5 contact sheet generation failed." }
Write-Host "G5 evidence generated: module=$Module states=$($reports.Count) report=$(Join-Path $compareDirectory 'report.json')"
