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

# Client visual metadata is independent from server operation costs and attributes.
$equipmentVisuals = Get-Content -LiteralPath (Join-Path $Root 'unitydata\export\client\visuals\equipment-icons.json') -Raw -Encoding UTF8 | ConvertFrom-Json
# Equipment reminders and operation UI share the active server's formal configuration.
foreach ($table in @('equip','equip_qianghua','equip_jinglian','equip_juexing','equip_shenzhu','fabao','fabao_qianghua','fabao_jinglian','quality','item','hecheng')) {
    $inputRows = @(Get-Content -LiteralPath (Join-Path $Root "unitydata\export\server\generated\json_server\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
    $activeRows = @(Get-Content -LiteralPath (Join-Path $Root "unityserver\config\json\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
    if (($inputRows | ConvertTo-Json -Depth 32 -Compress) -cne ($activeRows | ConvertTo-Json -Depth 32 -Compress)) {
        throw "Formal equipment table differs from the active Unity server: $table"
    }
    if ($table -in @('equip', 'fabao')) {
        $visualById = @{}
        foreach ($visual in $equipmentVisuals.$table) {
            if ($visualById.ContainsKey([int]$visual.id)) { throw "Duplicate $table visual ID: $($visual.id)" }
            $visualById[[int]$visual.id] = [string]$visual.pic
        }
        foreach ($row in $inputRows) {
            # Preserve established client identities; newly added server-only IDs keep their source key.
            if (-not $visualById.ContainsKey([int]$row.id)) { continue }
            $row.pic = $visualById[[int]$row.id]
            # 615-617 are refine materials, not selectable equipment/treasure icons.
            if ([int]$row.id -in @(615, 616, 617)) { continue }
            $token = [string]$row.pic
            $itemPath = Join-Path $Root "unityclient\Assets\Art\Icons\Items\$token.png"
            $faBaoPath = Join-Path $Root "unityclient\Assets\Art\Icons\FaBao\$token.png"
            if (-not (Test-Path -LiteralPath $itemPath) -and
                ($table -ne 'fabao' -or -not (Test-Path -LiteralPath $faBaoPath))) {
                throw "Missing formal $table icon: id=$($row.id), pic=$token"
            }
        }
    }
    Write-Utf8IfChanged -Path (Join-Path $source "Configs\$table.json") -Content (($inputRows | ConvertTo-Json -Depth 32 -Compress) + "`n")
}

# Formation costs come from the current-level server row, including learning at level zero.
$formationRows = @(Get-Content -LiteralPath (Join-Path $Root 'unitydata\export\server\generated\json_server\zhenfa_level.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Sort-Object id,level | Select-Object id,level,cost)
$formationActive = @(Get-Content -LiteralPath (Join-Path $Root 'unityserver\config\json\zhenfa_level.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Sort-Object id,level | Select-Object id,level,cost)
if (($formationRows | ConvertTo-Json -Depth 12 -Compress) -cne ($formationActive | ConvertTo-Json -Depth 12 -Compress)) {
    throw 'Formal formation costs differ from the active Unity server.'
}
Write-Utf8IfChanged -Path (Join-Path $source 'Configs\formation-level.json') -Content (($formationRows | ConvertTo-Json -Depth 12) + "`n")

# Hero leveling must use the same formal experience thresholds as the Unity server.
# Legacy World/exp_dat contains the old Cocos curve and remains for its other consumers.
$heroExpInput = Join-Path $Root 'unitydata\export\server\generated\json_server\exp.json'
$heroExpBaseline = Join-Path $Root 'unityserver\config\json\exp.json'
$heroExpRows = @(Get-Content -LiteralPath $heroExpInput -Raw -Encoding UTF8 | ConvertFrom-Json)
$heroExpActive = @(Get-Content -LiteralPath $heroExpBaseline -Raw -Encoding UTF8 | ConvertFrom-Json)
$heroExpData = @($heroExpRows | Sort-Object level | Select-Object level, exp_hero)
$heroExpActiveData = @($heroExpActive | Sort-Object level | Select-Object level, exp_hero)
if (($heroExpData | ConvertTo-Json -Compress) -cne ($heroExpActiveData | ConvertTo-Json -Compress)) {
    throw 'Formal hero experience input differs from the active Unity server.'
}
$heroExpLevels = [System.Collections.Generic.HashSet[int]]::new()
foreach ($row in $heroExpData) {
    if ([int]$row.level -le 0 -or [long]$row.exp_hero -lt 0 -or -not $heroExpLevels.Add([int]$row.level)) {
        throw 'Invalid or duplicate formal hero experience level.'
    }
}
Write-Utf8IfChanged -Path (Join-Path $source 'Configs\hero-level-exp.json') -Content (($heroExpData | ConvertTo-Json -Depth 4) + "`n")

$heroBreakTables = @{}
foreach ($table in @('break','quality','hero')) {
    $inputRows = @(Get-Content -LiteralPath (Join-Path $Root "unitydata\export\server\generated\json_server\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
    $activeRows = @(Get-Content -LiteralPath (Join-Path $Root "unityserver\config\json\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
    $columns = switch ($table) {
        'break' { @('break_level','level','attr','cost') }
        'quality' { @('quality','break_ratio') }
        'hero' { @('id','quality') }
    }
    $projected = @($inputRows | Sort-Object $columns[0] | Select-Object -Property $columns)
    $active = @($activeRows | Sort-Object $columns[0] | Select-Object -Property $columns)
    if (($projected | ConvertTo-Json -Depth 12 -Compress) -cne ($active | ConvertTo-Json -Depth 12 -Compress)) {
        throw "Formal hero breakthrough table differs from active Unity server: $table"
    }
    $heroBreakTables[$table] = $projected
}
$heroBreakContent = [ordered]@{ levels=$heroBreakTables['break']; qualities=$heroBreakTables['quality']; heroes=$heroBreakTables['hero'] }
Write-Utf8IfChanged -Path (Join-Path $source 'Configs\hero-break.json') -Content (($heroBreakContent | ConvertTo-Json -Depth 12) + "`n")

$heroStarTables = @{}
foreach ($table in @('star','hero')) {
    $inputRows = @(Get-Content -LiteralPath (Join-Path $Root "unitydata\export\server\generated\json_server\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
    $activeRows = @(Get-Content -LiteralPath (Join-Path $Root "unityserver\config\json\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
    $columns = if ($table -eq 'star') { @('star','cost') } else { @('id','quality','itemId') }
    $projected = @($inputRows | Sort-Object $columns[0] | Select-Object -Property $columns)
    $active = @($activeRows | Sort-Object $columns[0] | Select-Object -Property $columns)
    if (($projected | ConvertTo-Json -Depth 12 -Compress) -cne ($active | ConvertTo-Json -Depth 12 -Compress)) {
        throw "Formal hero star table differs from active Unity server: $table"
    }
    $heroStarTables[$table] = $projected
}
$heroStarContent = [ordered]@{ stars=$heroStarTables['star']; heroes=$heroStarTables['hero'] }
Write-Utf8IfChanged -Path (Join-Path $source 'Configs\hero-star.json') -Content (($heroStarContent | ConvertTo-Json -Depth 12) + "`n")

$cultivationColumns = @('level','name','level_need','cost_type','cost_xiulian','attr')
$cultivationRows = @(Get-Content -LiteralPath (Join-Path $Root 'unitydata\export\server\authoritative\json\xiulian.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Sort-Object level | Select-Object -Property $cultivationColumns)
$cultivationActive = @(Get-Content -LiteralPath (Join-Path $Root 'unityserver\config\json\xiulian.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Sort-Object level | Select-Object -Property $cultivationColumns)
if (($cultivationRows | ConvertTo-Json -Depth 12 -Compress) -cne ($cultivationActive | ConvertTo-Json -Depth 12 -Compress)) {
    throw 'Formal hero cultivation snapshot differs from the active Unity server.'
}
$cultivationParameters = @(Get-Content -LiteralPath (Join-Path $Root 'unitydata\export\server\generated\json_server\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Where-Object name -in 'xiulian_cost','xiulian_attr' | Sort-Object name | Select-Object name,type,value)
$cultivationParametersActive = @(Get-Content -LiteralPath (Join-Path $Root 'unityserver\config\json\config.json') -Raw -Encoding UTF8 | ConvertFrom-Json | Where-Object name -in 'xiulian_cost','xiulian_attr' | Sort-Object name | Select-Object name,type,value)
if (($cultivationParameters | ConvertTo-Json -Compress) -cne ($cultivationParametersActive | ConvertTo-Json -Compress)) {
    throw 'Formal hero cultivation parameters differ from the active Unity server.'
}
$cultivationItem = [int]($cultivationParameters | Where-Object name -eq 'xiulian_cost').value
$cultivationUnitsText = [string]($cultivationParameters | Where-Object name -eq 'xiulian_attr').value
$cultivationUnitsText = $cultivationUnitsText.Trim()
if (-not $cultivationUnitsText.StartsWith('[[')) { $cultivationUnitsText = '[' + $cultivationUnitsText + ']' }
$cultivationUnits = @($cultivationUnitsText | ConvertFrom-Json)
$cultivationContent = [ordered]@{ trainingItemId=$cultivationItem; attributeUnits=$cultivationUnits; levels=$cultivationRows }
Write-Utf8IfChanged -Path (Join-Path $source 'Configs\hero-cultivation.json') -Content (($cultivationContent | ConvertTo-Json -Depth 12) + "`n")

# HeroBook already consumes these four formal JSON sources; reject silent drift.
foreach ($table in @('handbook','star','quality','hero')) {
    $sortKey = switch ($table) { 'star' { 'star' } 'quality' { 'quality' } default { 'id' } }
    $bookSource = @(Get-Content -LiteralPath (Join-Path $source "Configs\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json | Sort-Object $sortKey)
    $bookActive = @(Get-Content -LiteralPath (Join-Path $Root "unityserver\config\json\$table.json") -Raw -Encoding UTF8 | ConvertFrom-Json | Sort-Object $sortKey)
    if (($bookSource | ConvertTo-Json -Depth 16 -Compress) -cne ($bookActive | ConvertTo-Json -Depth 16 -Compress)) {
        throw "Formal HeroBook source differs from active Unity server: $table"
    }
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
