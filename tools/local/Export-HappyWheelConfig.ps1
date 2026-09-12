[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$settingsPath = Join-Path $Root 'server\config\source\happywheel-settings.csv'
$rewardsPath = Join-Path $Root 'server\config\source\happywheel-rewards.csv'
$jsonPath = Join-Path $Root 'server\config\json\happywheel.json'
$seedPath = Join-Path $Root 'server\sql\sqlite\seeds\happywheel.sql'
$schemaPath = Join-Path $Root 'server\sql\sqlite\001_initial_schema.sql'
$beginMarker = '-- BEGIN GENERATED HAPPYWHEEL SEED'
$endMarker = '-- END GENERATED HAPPYWHEEL SEED'

$settingsRows = @(Import-Csv -LiteralPath $settingsPath -Encoding UTF8)
$rewards = @(Import-Csv -LiteralPath $rewardsPath -Encoding UTF8)
if ($settingsRows.Count -ne 1) { throw 'happywheel-settings.csv must contain exactly one data row.' }
$settings = $settingsRows[0]

$requiredPositive = @(
    'reward_type','cost_item_id','single_draw_count','single_key_cost','multi_draw_count',
    'multi_key_cost','score_per_draw','score_ext32_idx','daily_reset_ext32_idx',
    'history_limit','display_slot_count'
)
foreach ($field in $requiredPositive) {
    if ([int]$settings.$field -le 0) { throw "HappyWheel setting '$field' must be positive." }
}
if ([int]$settings.enabled -ne 1) { throw 'HappyWheel must be enabled for the permanent gameplay entry.' }
if ([int]$settings.history_limit -gt 50) { throw 'HappyWheel history_limit cannot exceed 50.' }
if ([string]::IsNullOrWhiteSpace($settings.insufficient_tip)) { throw 'insufficient_tip is required.' }
if ($rewards.Count -ne [int]$settings.display_slot_count) {
    throw "Reward row count $($rewards.Count) does not match display_slot_count $($settings.display_slot_count)."
}

$ids = @{}
$weightTotal = 0
foreach ($reward in $rewards) {
    $id = [int]$reward.id
    if ($ids.ContainsKey($id)) { throw "Duplicate HappyWheel reward id: $id" }
    $ids[$id] = $true
    if ([int]$reward.type -ne [int]$settings.reward_type) { throw "Reward $id has an unexpected type." }
    if ([int]$reward.award -le 0 -or [int]$reward.num -le 0 -or [int]$reward.rate -le 0) {
        throw "Reward $id requires positive award, num and rate."
    }
    if ([int]$reward.isShow -ne 1) { throw "Reward $id must be visible." }
    $weightTotal += [int]$reward.rate
}
if ($weightTotal -ne 10000) { throw "HappyWheel reward weights must total 10000; actual=$weightTotal." }

$expectedCostItem = [int]$settings.cost_item_id
foreach ($relativePath in @(
    'server\config\json\shop.json',
    'unityclient\Assets\ProjectX\Resources\Configs\shop.json'
)) {
    $path = Join-Path $Root $relativePath
    $shopRows = @(Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json)
    $keyRows = @($shopRows | Where-Object { [int]$_.id -eq 1018 })
    if ($keyRows.Count -ne 1 -or [int]$keyRows[0].itemid[0] -ne $expectedCostItem) {
        throw "$relativePath must sell HappyWheel cost item $expectedCostItem in row 1018."
    }
}
foreach ($relativePath in @(
    'server\config\json\item.json',
    'unityclient\Assets\ProjectX\Resources\Configs\item.json'
)) {
    $path = Join-Path $Root $relativePath
    $itemRows = @(Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json)
    $keyItems = @($itemRows | Where-Object { [int]$_.id -eq $expectedCostItem })
    if ($keyItems.Count -ne 1 -or [string]$keyItems[0].item_from -ne '来源：商城' -or
        [int]$keyItems[0].use_jump -ne 13) {
        throw "$relativePath must define HappyWheel cost item $expectedCostItem as a shop-sourced item."
    }
}

$jsonObject = [ordered]@{
    enabled = [int]$settings.enabled
    reward_type = [int]$settings.reward_type
    cost_item_id = [int]$settings.cost_item_id
    single_draw_count = [int]$settings.single_draw_count
    single_key_cost = [int]$settings.single_key_cost
    multi_draw_count = [int]$settings.multi_draw_count
    multi_key_cost = [int]$settings.multi_key_cost
    score_per_draw = [int]$settings.score_per_draw
    score_ext32_idx = [int]$settings.score_ext32_idx
    daily_reset_ext32_idx = [int]$settings.daily_reset_ext32_idx
    history_limit = [int]$settings.history_limit
    display_slot_count = [int]$settings.display_slot_count
    insufficient_tip = $settings.insufficient_tip
}
$json = ConvertTo-Json @($jsonObject) -Compress

$sqlRows = @($rewards | ForEach-Object {
    "($([int]$_.id),$([int]$_.type),$([int]$_.award),$([int]$_.num),$([int]$_.petQt),$([int]$_.petQtLv),$([int]$_.rate),$([int]$_.isJinPin),$([int]$_.isShow),'$([int]$_.notice)')"
})
$sql = @"
$beginMarker
INSERT INTO zha_dan_info (id,type,award,num,petQt,petQtLv,rate,isJinPin,isShow,notice) VALUES
$($sqlRows -join ",`n")
ON CONFLICT(id) DO UPDATE SET
  type=excluded.type, award=excluded.award, num=excluded.num,
  petQt=excluded.petQt, petQtLv=excluded.petQtLv, rate=excluded.rate,
  isJinPin=excluded.isJinPin, isShow=excluded.isShow, notice=excluded.notice;
$endMarker
"@

if ($ValidateOnly) {
    $currentJson = (Get-Content -Raw -Encoding UTF8 -LiteralPath $jsonPath).Trim()
    if ($currentJson -ne $json) { throw 'server/config/json/happywheel.json is stale. Run exporter.' }
    $currentSeed = (Get-Content -Raw -Encoding UTF8 -LiteralPath $seedPath).Trim()
    if ($currentSeed -ne $sql.Trim()) { throw 'SQLite HappyWheel seed is stale. Run exporter.' }
    $schema = Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaPath
    if (-not $schema.Contains($sql.Trim())) { throw 'SQLite initial schema does not contain the generated HappyWheel seed.' }
    Write-Host "HappyWheel config valid: rewards=$($rewards.Count), weight=$weightTotal, key=$($settings.cost_item_id)."
    return
}

$seedDirectory = Split-Path -Parent $seedPath
if (-not (Test-Path -LiteralPath $seedDirectory)) { New-Item -ItemType Directory -Path $seedDirectory | Out-Null }
Set-Content -LiteralPath $jsonPath -Encoding UTF8 -NoNewline -Value $json
Set-Content -LiteralPath $seedPath -Encoding UTF8 -Value $sql.TrimEnd()

$schema = Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaPath
$pattern = '(?s)' + [regex]::Escape($beginMarker) + '.*?' + [regex]::Escape($endMarker)
if ([regex]::IsMatch($schema, $pattern)) {
    $schema = [regex]::Replace($schema, $pattern, $sql.Trim())
} else {
    $schema = $schema.TrimEnd() + "`r`n`r`n" + $sql.Trim() + "`r`n"
}
Set-Content -LiteralPath $schemaPath -Encoding UTF8 -NoNewline -Value $schema
Write-Host "HappyWheel config exported: rewards=$($rewards.Count), weight=$weightTotal, key=$($settings.cost_item_id)."
