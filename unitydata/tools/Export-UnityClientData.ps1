param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$CleanOutput,
    [switch]$OnlyWorldBoxRewards
)

$ErrorActionPreference = 'Stop'

$Root = [System.IO.Path]::GetFullPath($Root)
$source = Join-Path $Root 'unitydata\export\client\source'
$destination = Join-Path $Root 'unityclient\Assets\Resources\ProjectXData'

if (-not (Test-Path -LiteralPath $source -PathType Container)) {
    throw "Unity client data source is missing: $source"
}

# Keep Unity GUIDs and importer settings when regenerating data.
function Write-Utf8IfChanged([string]$Path, [string]$Content) {
    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and
        (Get-Item -LiteralPath $Path).Length -eq [System.Text.Encoding]::UTF8.GetByteCount($Content) -and
        [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) -ceq $Content) { return }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

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
Write-Utf8IfChanged -Path $rewardSourcePath -Content $rewardContent
if ($OnlyWorldBoxRewards) {
    $rewardTargetPath = Join-Path $destination $rewardRelative
    Write-Utf8IfChanged -Path $rewardTargetPath -Content $rewardContent
    if ((Get-FileHash -LiteralPath $rewardSourcePath).Hash -ne (Get-FileHash -LiteralPath $rewardTargetPath).Hash) {
        throw 'World box reward source and runtime export hashes differ.'
    }
    Write-Output ('World box rewards exported: {0} records.' -f $rewardRows.Count)
    return
}

New-Item -ItemType Directory -Force -Path $destination | Out-Null

$sourceFiles = @(Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object { $_.Extension -ne '.meta' })
$sourceByRelative = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($file in $sourceFiles) {
    $relative = $file.FullName.Substring($source.Length).TrimStart('\', '/')
    $sourceByRelative.Add($relative, $file.FullName)
}

if ($CleanOutput) {
    $resolvedDestination = [System.IO.Path]::GetFullPath($destination)
    $assetsBoundary = [System.IO.Path]::GetFullPath((Join-Path $Root 'unityclient\Assets')) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedDestination.StartsWith($assetsBoundary, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean outside Unity Assets: $resolvedDestination"
    }
    # Remove only obsolete data files; preserve existing .meta files and folders.
    $obsoleteFiles = @(Get-ChildItem -LiteralPath $resolvedDestination -Recurse -File | Where-Object {
        $_.Extension -ne '.meta' -and -not $sourceByRelative.ContainsKey($_.FullName.Substring($resolvedDestination.Length).TrimStart('\', '/'))
    })
    foreach ($file in $obsoleteFiles) { Remove-Item -LiteralPath $file.FullName -Force }
}

foreach ($file in $sourceFiles) {
    $relative = $file.FullName.Substring($source.Length).TrimStart('\', '/')
    $target = Join-Path $destination $relative
    $targetDirectory = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    if (-not (Test-Path -LiteralPath $target -PathType Leaf) -or
        (Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $target).Hash) {
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
}

$targetFiles = @(Get-ChildItem -LiteralPath $destination -Recurse -File | Where-Object { $_.Extension -ne '.meta' })

if ($sourceFiles.Count -ne $targetFiles.Count) {
    throw "Unity client data export count mismatch: source=$($sourceFiles.Count), target=$($targetFiles.Count)."
}

foreach ($file in $targetFiles) {
    $relative = $file.FullName.Substring($destination.Length).TrimStart('\', '/')
    if (-not $sourceByRelative.ContainsKey($relative) -or
        (Get-FileHash -LiteralPath $sourceByRelative[$relative]).Hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) {
        throw "Unity client data export mismatch: $relative"
    }
}

Write-Output ("Unity client data exported: {0} files -> {1}" -f $sourceFiles.Count, $destination)
