param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$CleanOutput,
    [switch]$OnlyWorldBoxRewards
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $Root 'unitydata\export\client\source'
$destination = Join-Path $Root 'unityclient\Assets\ProjectX\Resources\ProjectXData'

# Box previews must use the same Unity Excel export as the running Unity server.
$rewardInput = Join-Path $Root 'unitydata\export\server\generated\json_server\reward_fixed.json'
$rewardBaseline = Join-Path $Root 'unityserver\config\json\reward_fixed.json'
$rewardRows = @(Get-Content -LiteralPath $rewardInput -Raw -Encoding UTF8 | ConvertFrom-Json)
$baselineRows = @(Get-Content -LiteralPath $rewardBaseline -Raw -Encoding UTF8 | ConvertFrom-Json)
$generatedRewards = @($rewardRows | Sort-Object ID) | ConvertTo-Json -Depth 16 -Compress
$activeRewards = @($baselineRows | Sort-Object ID) | ConvertTo-Json -Depth 16 -Compress
if ($generatedRewards -cne $activeRewards) {
    throw 'World box reward export differs from the Unity server configuration. Export Unity server data first.'
}
$rewardLines = [System.Collections.Generic.List[string]]::new()
$rewardLines.Add('reward_fixed_dat = {')
$rewardIds = [System.Collections.Generic.HashSet[int]]::new()
foreach ($row in ($rewardRows | Sort-Object ID)) {
    if ([int]$row.ID -le 0 -or -not $rewardIds.Add([int]$row.ID)) { throw 'Invalid or duplicate box reward ID.' }
    $triples = @($row.reward | ForEach-Object {
        if ($_.Count -ne 3) { throw ('Invalid reward triple in box {0}.' -f $row.ID) }
        '{{{0},{1},{2}}}' -f [int]$_[0], [int]$_[1], [int]$_[2]
    })
    $rewardLines.Add(('    {{ ID = {0}, reward = {{{1}}} }},' -f $row.ID, ($triples -join ',')))
}
$rewardLines.Add('}')
$rewardContent = ($rewardLines -join "`n") + "`n"
$rewardRelative = 'World\reward_fixed_dat.txt'
$rewardSourcePath = Join-Path $source $rewardRelative
[System.IO.File]::WriteAllText($rewardSourcePath, $rewardContent, [System.Text.UTF8Encoding]::new($false))
if ($OnlyWorldBoxRewards) {
    $rewardTargetPath = Join-Path $destination $rewardRelative
    [System.IO.File]::WriteAllText($rewardTargetPath, $rewardContent, [System.Text.UTF8Encoding]::new($false))
    Write-Output ('World box rewards exported: {0} records.' -f $rewardRows.Count)
    return
}

if (-not (Test-Path -LiteralPath $source)) {
    throw "Unity client data source is missing: $source"
}

if ($CleanOutput -and (Test-Path -LiteralPath $destination)) {
    Get-ChildItem -LiteralPath $destination -Force | Remove-Item -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $destination | Out-Null

Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object {
    $_.Extension -notin @('.meta')
} | ForEach-Object {
    $relative = $_.FullName.Substring($source.Length).TrimStart('\', '/')
    $target = Join-Path $destination $relative
    $targetDirectory = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}

$sourceFiles = @(Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object { $_.Extension -notin @('.meta') })
$targetFiles = @(Get-ChildItem -LiteralPath $destination -Recurse -File | Where-Object { $_.Extension -notin @('.meta') })

if ($sourceFiles.Count -ne $targetFiles.Count) {
    throw "Unity client data export count mismatch: source=$($sourceFiles.Count), target=$($targetFiles.Count)."
}

Write-Output ("Unity client data exported: {0} files -> {1}" -f $sourceFiles.Count, $destination)
