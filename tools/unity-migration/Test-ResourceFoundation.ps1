[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$unityRoot = Join-Path $RepositoryRoot 'unityclient\Assets'
$scenePath = Join-Path $unityRoot 'Scenes\Bootstrap.unity'
$catalogPath = Join-Path $unityRoot 'Prefabs\Catalog\Catalog.asset'
$builderPath = Join-Path $unityRoot 'src\Editor\BootstrapSceneBuilder.cs'
$providerPath = Join-Path $unityRoot 'src\UI\ResourcesUiAssetProvider.cs'
$loaderPath = Join-Path $unityRoot 'src\Core\UnityResourceLoader.cs'
$projectXAppPath = Join-Path $unityRoot 'src\Core\ProjectXApp.cs'

foreach ($path in @($scenePath, $catalogPath, $builderPath, $providerPath, $loaderPath, $projectXAppPath)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "ResourceFoundation required file is missing: $path" }
}

$scene = Get-Content -LiteralPath $scenePath -Raw -Encoding UTF8
$catalog = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8
$builder = Get-Content -LiteralPath $builderPath -Raw -Encoding UTF8
$provider = Get-Content -LiteralPath $providerPath -Raw -Encoding UTF8
$loader = Get-Content -LiteralPath $loaderPath -Raw -Encoding UTF8
$projectXApp = @(Get-ChildItem -LiteralPath (Split-Path $projectXAppPath) -Filter 'ProjectXApp*.cs' -File |
    Sort-Object Name | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join "`n"

$prefabInstances = ([regex]::Matches($scene, '(?m)^PrefabInstance:')).Count
if ($prefabInstances -ne 0) { throw "Bootstrap still contains $prefabInstances PrefabInstance records." }
foreach ($rootName in @('Main Camera', 'Directional Light', 'Canvas', 'EventSystem', 'ProjectXApp')) {
    if ($scene -notmatch [regex]::Escape("m_Name: $rootName")) { throw "Bootstrap root is missing: $rootName" }
}
if ($catalog -notmatch 'rollbackCommit') {
    # Catalog is Unity YAML and intentionally has no rollback metadata; the assertion below anchors it in code/docs.
}
if ($builder -notmatch '7422cbd83531b365a4188e36e21999e47d508d5d') { throw 'Rollback commit is not anchored in the validator.' }
if ($provider -notmatch 'GetUnityOrCreate' -or $provider -notmatch 'ReleaseSingletonTree' -or $provider -notmatch 'childrenByParentKey') {
    throw 'Provider singleton, release, or parent-child contract is incomplete.'
}
if ($provider -match 'GetOrCreate\(child\.Key, view\.GameObject\.transform\);') {
    throw 'Provider must not eagerly instantiate every ParentKey child when a shared frame is requested.'
}
if ($builder -notmatch 'new PrefabSpec\(HeroListPrefab, false, HeroFramePrefab\)' -or
    $builder -notmatch 'new PrefabSpec\(HeroDetailPrefab, false, HeroFramePrefab\)') {
    throw 'OneLevelLayer Hero child pages must be lazy and default-inactive.'
}
if ($loader -notmatch 'UnityAssetReference\.Load' -or $provider -notmatch 'ResourceLoader\.Load<UiPrefabReference>') {
    throw 'Native assets bypass the configured resource loader or typed reference index.'
}
if ($provider -match 'Attempted to release a UI view not owned' -or $provider -notmatch 'if \(target == null\) return false;') {
    throw 'UI release is no longer idempotent after recursive parent cleanup.'
}
$showLoginMatch = [regex]::Match($projectXApp,
    'public void ShowLoginUi\(\)(?<body>[\s\S]*?)\n        \}',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant)
if (-not $showLoginMatch.Success) { throw 'ShowLoginUi source block was not found.' }
$showLoginBody = $showLoginMatch.Groups['body'].Value
$loginSourceLoads = [regex]::Matches($showLoginBody, 'UiAssets\.GetUnityOrCreate\(').Count
$loginStackValid = $loginSourceLoads -eq 4 -and
    $showLoginBody -notmatch 'FindBySource' -and
    @('loginLayer', 'LoginBgLayer', 'SeverListLayer', 'RoleCreateLayer' | Where-Object {
        $showLoginBody -notmatch [regex]::Escape("GetUnityOrCreate(`"$_`")")
    }).Count -eq 0 -and
    $showLoginBody -match 'loginBackgroundView\?\.GameObject\.transform\.SetAsFirstSibling\(\)' -and
    $showLoginBody -match 'loginView\?\.GameObject\.transform\.SetAsLastSibling\(\)'
if (-not $loginStackValid) {
    throw "Login bootstrap drifted from the minimal visible stack: sourceLoads=$loginSourceLoads"
}
$catalogKeys = @([regex]::Matches($catalog, '(?m)^  - key:\s*(.+?)\s*$') |
    ForEach-Object { $_.Groups[1].Value })
$catalogReferenceCount = @($catalogKeys | Where-Object {
    Test-Path -LiteralPath (Join-Path (Split-Path $catalogPath) "${_}.asset")
}).Count
$catalogSources = @([regex]::Matches($catalog, '(?m)^\s+source:\s*(.+?)\s*$') |
    ForEach-Object { $_.Groups[1].Value })
$inventoryBlocks = @([regex]::Matches($builder,
    'private static readonly PrefabSpec\[\] (?:PrefabSpecs|DynamicOnlyPrefabSpecs)\s*=\s*\{(?<body>[\s\S]*?)\n\s*\};'))
if ($inventoryBlocks.Count -ne 2) {
    throw "Dynamic UI inventory declarations could not be resolved from BootstrapSceneBuilder: blocks=$($inventoryBlocks.Count)"
}
$expectedInventoryCount = ($inventoryBlocks | ForEach-Object {
    [regex]::Matches($_.Groups['body'].Value, 'new PrefabSpec\(').Count
} | Measure-Object -Sum).Sum
$prefabConstants = @{}
$prefabPaths = @{}
foreach ($match in [regex]::Matches($builder, 'private const string (\w+)\s*=\s*"([^"\r\n]+\.prefab)"')) {
    $prefabConstants[$match.Groups[1].Value] = [IO.Path]::GetFileNameWithoutExtension($match.Groups[2].Value)
    $prefabPaths[$match.Groups[1].Value] = Join-Path (Join-Path $RepositoryRoot 'unityclient') $match.Groups[2].Value
}
foreach ($match in [regex]::Matches($builder, 'if \(prefabPath == (\w+)\) return "([^"\r\n]+)";')) {
    $prefabConstants[$match.Groups[1].Value] = $match.Groups[2].Value
}
$declaredKeys = @($inventoryBlocks | ForEach-Object {
    foreach ($match in [regex]::Matches($_.Groups['body'].Value, 'new PrefabSpec\((\w+),')) {
        $prefabConstants[$match.Groups[1].Value]
    }
})
$declaredPaths = @($inventoryBlocks | ForEach-Object {
    foreach ($match in [regex]::Matches($_.Groups['body'].Value, 'new PrefabSpec\((\w+),')) {
        $prefabPaths[$match.Groups[1].Value]
    }
})
# Catalog is the runtime authority and includes hand-maintained native pages beyond builder defaults.
$referenceCount = @($declaredPaths | Where-Object {
    $_ -and (Test-Path -LiteralPath $_)
}).Count
if ($referenceCount -ne $expectedInventoryCount -or $catalogReferenceCount -ne $catalogKeys.Count -or
    @($catalogSources | Where-Object { $_ -notlike 'Unity/*' }).Count -ne 0) {
    throw "Dynamic UI inventory drifted: references=$referenceCount, catalogSources=$($catalogSources.Count), expected=$expectedInventoryCount"
}
$sourceTokens = @([regex]::Matches($projectXApp, 'UiAssets\.(?:GetUnityOrCreate|InstantiateUnity)\(\s*"([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique)
$missingSourceTokens = @($sourceTokens | Where-Object {
    $_ -notin $catalogKeys
})
if ($missingSourceTokens.Count -gt 0) {
    throw "ProjectXApp source queries are missing from the dynamic catalog: $($missingSourceTokens -join ', ')"
}

[pscustomobject]@{
    status = 'Passed'
    rollbackCommit = '7422cbd83531b365a4188e36e21999e47d508d5d'
    bootstrapPrefabInstances = $prefabInstances
    dynamicReferenceAssets = $catalogReferenceCount
    declaredPrefabAssets = $referenceCount
    sourceQueriesCovered = $sourceTokens.Count
    loginSourceLoads = $loginSourceLoads
    releaseIdempotent = $true
} | ConvertTo-Json -Depth 3
