param([string]$Root = "")

$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$affixPath = Join-Path $Root "server\config\json\equipment_affix.json"
$rolePath = Join-Path $Root "server\config\json\hero_skill_role.json"
$petPath = Join-Path $Root "server\config\xml\pet_basic_config.xml"
$serverSkillPath = Join-Path $Root "server\config\xml\skill_basic.xml"
$unitySkillPath = Join-Path $Root "unityclient\Assets\ProjectX\Resources\Configs\skill_basic.xml"

$affixes = @(Get-Content -LiteralPath $affixPath -Raw -Encoding UTF8 | ConvertFrom-Json)
$roles = @(Get-Content -LiteralPath $rolePath -Raw -Encoding UTF8 | ConvertFrom-Json)
[xml]$pets = Get-Content -LiteralPath $petPath -Raw -Encoding UTF8
[xml]$serverSkills = Get-Content -LiteralPath $serverSkillPath -Raw -Encoding UTF8
[xml]$unitySkills = Get-Content -LiteralPath $unitySkillPath -Raw -Encoding UTF8

Assert-True ($affixes.Count -eq 48) "Expected 48 equipment affixes, got $($affixes.Count)."
Assert-True ((@($affixes.id | Sort-Object -Unique)).Count -eq 48) "Affix ids must be unique."
Assert-True ((@($affixes.key | Sort-Object -Unique)).Count -eq 48) "Affix keys must be unique."
Assert-True ((@($affixes.passive_skill_id | Sort-Object -Unique)).Count -eq 48) "Affix passive skill ids must be unique."
foreach ($affix in $affixes) {
    Assert-True ($affix.id -ge 1 -and $affix.id -le 48) "Invalid affix id: $($affix.id)."
    Assert-True ($affix.passive_skill_id -eq 5000 + $affix.id) "Affix $($affix.key) passive skill id is not 5000+id."
    Assert-True (@($affix.parts).Count -gt 0) "Affix $($affix.key) has no compatible part."
    Assert-True ((@($affix.parts | Where-Object { $_ -lt 1 -or $_ -gt 4 })).Count -eq 0) "Affix $($affix.key) has invalid part."
    Assert-True (@($affix.value1).Count -eq 3 -and @($affix.value2).Count -eq 3) "Affix $($affix.key) must define T1-T3 values."
}
$runtimeEnabled = @(1..48)
foreach ($part in 1..4) {
    $pool = @($affixes | Where-Object { $runtimeEnabled -contains [int]$_.id -and @($_.parts) -contains $part })
    Assert-True ($pool.Count -gt 0) "Runtime-enabled affix pool is empty for equipment part $part."
}

Assert-True ($roles.Count -eq 59) "Expected 59 hero skill roles, got $($roles.Count)."
Assert-True ((@($roles.hero_id | Sort-Object -Unique)).Count -eq 59) "Hero ids in role config must be unique."
$petById = @{}
foreach ($pet in @($pets.CONFIGS.CONTENT)) { $petById[[int]$pet.id] = $pet }
$serverSkillById = @{}
foreach ($skill in @($serverSkills.CONFIGS.CONTENT)) { $serverSkillById[[int]$skill.id] = $skill }
$unitySkillById = @{}
foreach ($skill in @($unitySkills.CONFIGS.CONTENT)) { $unitySkillById[[int]$skill.id] = $skill }
foreach ($role in $roles) {
    $heroId = [int]$role.hero_id
    Assert-True $petById.ContainsKey($heroId) "Hero $heroId is absent from pet_basic_config.xml."
    $activeSkills = @(([string]$petById[$heroId].skill).Split(';') | Select-Object -First 2 | ForEach-Object { [int]$_ })
    Assert-True ($activeSkills -contains [int]$role.regular_skill_id) "Hero $heroId regular skill is not one of the first two active skills."
    Assert-True ($activeSkills -contains [int]$role.tactic_skill_id) "Hero $heroId tactic skill is not one of the first two active skills."
    Assert-True $serverSkillById.ContainsKey([int]$role.regular_skill_id) "Hero $heroId regular skill is absent from skill_basic.xml."
    Assert-True $serverSkillById.ContainsKey([int]$role.tactic_skill_id) "Hero $heroId tactic skill is absent from skill_basic.xml."
    Assert-True ($role.tactic_cost -ge 20 -and $role.tactic_cost -le 100) "Hero $heroId tactic cost is outside 20-100."
}

foreach ($skillId in 5001..5048) {
    Assert-True $serverSkillById.ContainsKey($skillId) "Server affix passive skill $skillId is missing."
    Assert-True $unitySkillById.ContainsKey($skillId) "Unity affix passive skill $skillId is missing."
    Assert-True ([string]$serverSkillById[$skillId].name -eq [string]$unitySkillById[$skillId].name) "Affix skill $skillId name differs between server and Unity."
}

$serverEquip = Get-Content -LiteralPath (Join-Path $Root "server\src\pet_equip_manage.cpp") -Raw -Encoding UTF8
$serverFight = Get-Content -LiteralPath (Join-Path $Root "server\src\fight.cpp") -Raw -Encoding UTF8
$cocosProtocol = Get-Content -LiteralPath (Join-Path $Root "client\ProjectX\src\NetWork\LuaNetRecvdMsg.lua") -Raw -Encoding UTF8
$unityProtocol = Get-Content -LiteralPath (Join-Path $Root "unityclient\Assets\ProjectX\Resources\Lua\Hero\EquipmentController.lua.txt") -Raw -Encoding UTF8
Assert-True ($serverEquip.Contains("PXA1")) "Equipment save extension magic PXA1 is missing."
Assert-True ($serverEquip.Contains("SendPetEquipAffixList")) "Affix query sender is missing."
Assert-True ($serverEquip.Contains("IsEquipAffixRuntimeEnabledV1")) "Runtime affix allowlist is missing."
Assert-True ($serverFight.Contains("GetTacticCost")) "Tactic resource runtime is missing."
foreach ($hook in @(
    "OnAffixShieldLost", "OnAffixBuffRemoved", "OnAffixControlResisted",
    "OnAffixUnitDied", "ApplyAffixSummonBonus", "AddAffixHpAction"
)) {
    Assert-True ($serverFight.Contains($hook)) "Affix event hook $hook is missing."
}
Assert-True ($serverEquip.Contains("return id >= 1 && id <= 48;")) "The complete 48-affix runtime pool is not enabled."
Assert-True ($cocosProtocol.Contains("elseif op == 40 then")) "Cocos affix protocol parser is missing."
Assert-True ($unityProtocol.Contains("if op == 40 then readAffixList")) "Unity affix protocol parser is missing."

Write-Host "PASS hero-skill-affix config: roles=$($roles.Count), affixes=$($affixes.Count), runtimeEnabled=$($runtimeEnabled.Count), passiveSkills=48, clients=2"
