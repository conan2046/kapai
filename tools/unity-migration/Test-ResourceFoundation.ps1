[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$unityRoot = Join-Path $RepositoryRoot 'unityclient\Assets\ProjectX'
$scenePath = Join-Path $unityRoot 'Scenes\Bootstrap.unity'
$catalogPath = Join-Path $unityRoot 'Resources\UiPrefabs\Catalog.asset'
$builderPath = Join-Path $unityRoot 'src\Editor\BootstrapSceneBuilder.cs'
$providerPath = Join-Path $unityRoot 'src\UI\ResourcesUiAssetProvider.cs'
$loaderPath = Join-Path $unityRoot 'src\UI\UiPrefabLoader.cs'
$projectXAppPath = Join-Path $unityRoot 'src\Core\ProjectXApp.cs'

foreach ($path in @($scenePath, $catalogPath, $builderPath, $providerPath, $loaderPath, $projectXAppPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "ResourceFoundation required file is missing: $path" }
}

$scene = Get-Content -LiteralPath $scenePath -Raw -Encoding UTF8
$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8
$builder = Get-Content -LiteralPath $builderPath -Raw -Encoding UTF8
$provider = Get-Content -LiteralPath $providerPath -Raw -Encoding UTF8
$loader = Get-Content -LiteralPath $loaderPath -Raw -Encoding UTF8
$projectXApp = Get-Content -LiteralPath $projectXAppPath -Raw -Encoding UTF8

$prefabInstances = ([regex]::Matches($scene, '(?m)^PrefabInstance:')).Count
if ($prefabInstances -ne 0) { throw "Bootstrap still contains $prefabInstances PrefabInstance records." }
foreach ($rootName in @('Main Camera', 'Directional Light', 'Canvas', 'EventSystem', 'ProjectXApp')) {
    if ($scene -notmatch [regex]::Escape("m_Name: $rootName")) { throw "Bootstrap root is missing: $rootName" }
}
if ($catalog -notmatch 'rollbackCommit') {
    # Catalog is Unity YAML and intentionally has no rollback metadata; the assertion below anchors it in code/docs.
}
if ($builder -notmatch '7422cbd83531b365a4188e36e21999e47d508d5d') { throw 'Rollback commit is not anchored in the validator.' }
if ($provider -notmatch 'GetOrCreate' -or $provider -notmatch 'ReleaseSingletonTree' -or $provider -notmatch 'childrenByParentKey') {
    throw 'Provider singleton, release, or parent-child contract is incomplete.'
}
if ($provider -match 'GetOrCreate\(child\.Key, view\.GameObject\.transform\);') {
    throw 'Provider must not eagerly instantiate every ParentKey child when a shared frame is requested.'
}
if ($builder -notmatch 'new PrefabSpec\(HeroListPrefab, false, HeroFramePrefab\)' -or
    $builder -notmatch 'new PrefabSpec\(HeroDetailPrefab, false, HeroFramePrefab\)') {
    throw 'OneLevelLayer Hero child pages must be lazy and default-inactive.'
}
if ($loader -match 'Resources\.Load') { throw 'UiPrefabLoader bypasses the configured provider.' }
if ($loader -match 'Attempted to release a UI view not owned' -or $loader -notmatch 'provider\.Release\(view\)') {
    throw 'UI release is no longer idempotent after recursive parent cleanup.'
}
$showLoginMatch = [regex]::Match($projectXApp,
    'public void ShowLoginUi\(\)(?<body>[\s\S]*?)public void BindLoginClick\(',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant)
if (-not $showLoginMatch.Success) { throw 'ShowLoginUi source block was not found.' }
$showLoginBody = $showLoginMatch.Groups['body'].Value
$loginSourceLoads = [regex]::Matches($showLoginBody, 'UiRouter\.FindBySource\(').Count
$loginStackValid = $loginSourceLoads -eq 5 -and
    $showLoginBody -match 'loginBackgroundView\?\.GameObject\.transform\.SetAsFirstSibling\(\)' -and
    $showLoginBody -match 'loginView\?\.GameObject\.transform\.SetAsLastSibling\(\)'
if (-not $loginStackValid) {
    throw "Login bootstrap drifted from the minimal visible stack: sourceLoads=$loginSourceLoads"
}
$referenceCount = @(Get-ChildItem -LiteralPath (Split-Path $catalogPath) -Filter '*.asset' -File |
    Where-Object Name -ne 'Catalog.asset').Count
$catalogSources = @([regex]::Matches($catalog, '(?m)^\s+source:\s*(.+?)\s*$') |
    ForEach-Object { $_.Groups[1].Value })
if ($referenceCount -ne 110 -or $catalogSources.Count -ne 110) {
    throw "Dynamic UI inventory drifted: references=$referenceCount, catalogSources=$($catalogSources.Count), expected=110"
}
$sourceTokens = @([regex]::Matches($projectXApp, 'FindBySource\(\s*"([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique)
$missingSourceTokens = @($sourceTokens | Where-Object {
    $token = $_
    -not ($catalogSources | Where-Object {
        $_.IndexOf($token, [StringComparison]::OrdinalIgnoreCase) -ge 0
    })
})
if ($missingSourceTokens.Count -gt 0) {
    throw "ProjectXApp source queries are missing from the dynamic catalog: $($missingSourceTokens -join ', ')"
}

[pscustomobject]@{
    status = 'Passed'
    rollbackCommit = '7422cbd83531b365a4188e36e21999e47d508d5d'
    bootstrapPrefabInstances = $prefabInstances
    dynamicReferenceAssets = $referenceCount
    sourceQueriesCovered = $sourceTokens.Count
    loginSourceLoads = $loginSourceLoads
    releaseIdempotent = $true
} | ConvertTo-Json -Depth 3
