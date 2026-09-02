param([string]$Root = "", [string]$LuaExecutable = "")

$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }
function Assert-Build([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$masterPath = Join-Path $Root 'server/config/json/hero_build_profile.json'
$unityPath = Join-Path $Root 'unityclient/Assets/ProjectX/Resources/Configs/hero_build_profile.json'
Assert-Build ((Get-FileHash $masterPath).Hash -eq (Get-FileHash $unityPath).Hash) 'Build profile JSON copies differ.'
$profiles = @(Get-Content -Raw -Encoding UTF8 $masterPath | ConvertFrom-Json)
$roles = @(Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'server/config/json/hero_skill_role.json') | ConvertFrom-Json)
$affixes = @(Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'server/config/json/equipment_affix.json') | ConvertFrom-Json)
$tags = @('SHIELD','HEAL','GUARD','COUNTER','CRIT','COMBO','BREAK','CONTROL','DOT','DEBUFF','DEATH','TACTIC')
$expectedHeroes = @(10,11,12,13,14,15,16,17,23,31,34,60)
Assert-Build ($profiles.Count -eq 24) 'Expected 24 A/B build profiles.'
Assert-Build (@($profiles.id | Sort-Object -Unique).Count -eq 24) 'Build profile IDs must be unique.'
foreach ($heroId in $expectedHeroes) {
    $pair = @($profiles | Where-Object hero_id -eq $heroId | Sort-Object id)
    $role = $roles | Where-Object hero_id -eq $heroId
    Assert-Build ($pair.Count -eq 2 -and ($pair.branch -join ',') -eq 'A,B') "Hero $heroId needs exactly A/B profiles."
    Assert-Build ($pair[0].name -eq $role.build_a -and $pair[1].name -eq $role.build_b) "Hero $heroId build names drifted."
    Assert-Build (($pair[0].core_affixes -join ',') -ne ($pair[1].core_affixes -join ',')) "Hero $heroId A/B recommendations must differ."
}
foreach ($profile in $profiles) {
    Assert-Build ($expectedHeroes -contains $profile.hero_id) "Unexpected first-batch hero $($profile.hero_id)."
    Assert-Build (@($profile.core_affixes).Count -ge 2) "Profile $($profile.id) needs core affixes."
    Assert-Build (@($profile.core_affixes | Sort-Object -Unique).Count -eq @($profile.core_affixes).Count) 'Duplicate core affix.'
    foreach ($key in $profile.core_affixes) { Assert-Build ($affixes.key -contains $key) "Unknown core affix $key." }
    foreach ($tag in $profile.support_tags) { Assert-Build ($tags -contains $tag) "Unknown support tag $tag." }
    Assert-Build (-not [string]::IsNullOrWhiteSpace($profile.strategy_hint)) 'Missing strategy guidance.'
}

# Compile and execute the production C# scorer without opening Unity.
$scorerPath = Join-Path $Root 'unityclient/Assets/ProjectX/src/Data/HeroBuildRecommendation.cs'
if (-not ('ProjectX.Data.HeroBuildRecommendation' -as [type])) { Add-Type -Path $scorerPath }
$typed = [ProjectX.Data.HeroBuildProfile[]]@($profiles | ForEach-Object {
    $profile = [ProjectX.Data.HeroBuildProfile]::new()
    $profile.id = $_.id; $profile.hero_id = $_.hero_id; $profile.hero_name = $_.hero_name
    $profile.branch = $_.branch; $profile.name = $_.name
    $profile.core_affixes = $_.core_affixes; $profile.support_tags = $_.support_tags
    $profile.strategy_hint = $_.strategy_hint
    $profile
})
$keys = @($tags | ForEach-Object { $tag = $_; 1..4 | ForEach-Object { '{0}-{1:00}' -f $tag, $_ } }) + @('', 'NOPE-01', 'heal-01', 'HEAL')
$expected = [System.Collections.Generic.List[string]]::new()
foreach ($profile in $typed) {
    $expected.Add((@('P', $profile.id, $profile.hero_id, $profile.hero_name, $profile.branch, $profile.name,
        ($profile.core_affixes -join ','), ($profile.support_tags -join ','), $profile.strategy_hint) -join "`t"))
    foreach ($key in $keys) {
        $score = [ProjectX.Data.HeroBuildRecommendation]::Score($profile, $key)
        $tag = if ($key -cmatch '^([A-Z]+)-') { $Matches[1] } else { '' }
        $reference = if ($profile.core_affixes -ccontains $key) { 100 } elseif ($tag -and $profile.support_tags -ccontains $tag) { 60 } else { 0 }
        Assert-Build ($score -eq $reference) "Incorrect score profile=$($profile.id), key=$key."
        $expected.Add("S`t$($profile.id)`t$key`t$score")
    }
}
foreach ($key in $keys) {
    $ranked = [ProjectX.Data.HeroBuildRecommendation]::Rank($typed, $key)
    $referenceRank = @($typed | Where-Object { [ProjectX.Data.HeroBuildRecommendation]::Score($_, $key) -gt 0 } |
        Sort-Object @{Expression = { [ProjectX.Data.HeroBuildRecommendation]::Score($_, $key) }; Descending = $true}, id)
    Assert-Build (($ranked.id -join ',') -ceq ($referenceRank.id -join ',')) "Unstable or incorrect recommendation rank: $key."
    $expected.Add("R`t$key`t$(($ranked.id) -join ',')")
    foreach ($heroId in @(@(0) + $expectedHeroes + @(999))) {
        $description = [ProjectX.Data.HeroBuildRecommendation]::Describe($typed, $heroId, $key).Replace("`n", '\n')
        $expected.Add("D`t$heroId`t$key`t$description")
    }
}
Assert-Build ([ProjectX.Data.HeroBuildRecommendation]::Score($null, 'HEAL-01') -eq 0) 'Null profile must not match.'
Assert-Build ([ProjectX.Data.HeroBuildRecommendation]::Score($typed[0], $null) -eq 0) 'Null key must not match.'

if (-not $LuaExecutable) {
    $command = Get-Command luajit,lua -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $LuaExecutable = $command.Source }
}
Assert-Build ($LuaExecutable -and (Test-Path -LiteralPath $LuaExecutable)) 'Pass -LuaExecutable with a working Lua 5.1/LuaJIT executable.'
$outputDir = Join-Path $Root '.local'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$outputPath = Join-Path $outputDir 'hero-build-s8-lua-parity.log'
Push-Location $Root
try {
    & $LuaExecutable 'tools/local/tests/hero_build_recommendation.lua' > $outputPath
    Assert-Build ($LASTEXITCODE -eq 0) "Lua build recommendation tests failed; see $outputPath."
} finally { Pop-Location }
$actual = @(Get-Content -Encoding UTF8 $outputPath)
Assert-Build ($actual.Count -eq $expected.Count) "Lua/C# output line counts differ: $($actual.Count)/$($expected.Count)."
for ($index = 0; $index -lt $expected.Count; $index++) {
    Assert-Build ($actual[$index] -ceq $expected[$index]) "Lua/C# parity mismatch at line $($index + 1); see $outputPath."
}

# The UI must use display formation positions, never the helper's first-hero fallback.
$cocos = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'client/ProjectX/src/View/PetEquip/EquipInfoUI.lua')
$app = Get-Content -Raw -Encoding UTF8 (Join-Path $Root 'unityclient/Assets/ProjectX/src/Core/ProjectXApp.cs')
Assert-Build ($cocos.Contains('LRoleDataMgr.Pet.ShowPosList') -and $cocos.Contains('HeroBuildRecommendation.Describe')) 'Cocos build guidance/context is missing.'
Assert-Build ($app.Contains('services.Formation.DisplayHeroes[position - 1]')) 'Unity equipment build context must use display formation.'
Write-Host "PASS S8 builds: heroes=12, profiles=24, scoreCases=$($typed.Count * $keys.Count), parityLines=$($expected.Count), cocosUiCases=5, GUI=deferred"
