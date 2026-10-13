[CmdletBinding()]
param([string]$Root=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Test-UnityDongFuTables.ps1')
$schema=Get-Content (Join-Path $PSScriptRoot 'dongfu-schema.json') -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
$tables=@{}
foreach($table in $schema.tables){
    $name=$table.name
    $server=Join-Path $Root "unityserver/config/json/$name.json"
    $client=Join-Path $Root "unityclient/Assets/Resources/ProjectXData/Configs/$name.json"
    if([IO.File]::ReadAllText($server) -cne [IO.File]::ReadAllText($client)){throw "DongFu client/server drift: $name"}
    $tables[$name]=Get-Content $server -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -NoEnumerate
    $keys=@($tables[$name][0].Keys | Sort-Object)
    $expected=@($table.fields.key | Sort-Object)
    if(($keys -join ',') -ne ($expected -join ',')){throw "DongFu field loss: $name"}
}
Test-UnityDongFuTables $tables $Root
$cases=0
function Reject-DongFuCase([string]$Name,[scriptblock]$Edit,$Baseline=$tables){
    $copy=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $Baseline -Depth 64) -AsHashtable
    & $Edit $copy
    $rejected=$false
    try{Test-UnityDongFuTables $copy $Root}catch{$rejected=$true}
    if(-not $rejected){throw "DongFu invalid configuration accepted: $Name"}
    $script:cases++
}
Reject-DongFuCase 'zero duration' {param($x) $x.dongfu_recipe[0].duration_seconds=0}
Reject-DongFuCase 'invalid target' {param($x) $x.dongfu_spirit_root_level[0].target_positions=@(6)}
Reject-DongFuCase 'duplicate spirit positions' {param($x) $x.dongfu_spirit_root_level[0].target_positions=@(1,1)}
Reject-DongFuCase 'missing spirit positions for attributes' {param($x) $x.dongfu_spirit_root_level[0].target_positions=@();$x.dongfu_spirit_root_level[0].combat_attributes=,@(1,1)}
Reject-DongFuCase 'legacy spirit scope' {param($x) $x.dongfu_spirit_root_level[0].target_positions='lineup'}
Reject-DongFuCase 'zero remaining time' {param($x) $x.dongfu_spirit_root_level[0].growth_reduction_bp=10000}
Reject-DongFuCase 'duplicate book members' {param($x) $x.dongfu_book_set[0].book_ids=@(1,1)}
Reject-DongFuCase 'invalid resource pair' {param($x) $x.dongfu_recipe[0].cost_items=@(@(1,0))}
Reject-DongFuCase 'unmapped seed' {param($x) $x.dongfu_crop[0].enabled=1; $x.dongfu_crop[0].seed_item_id=0}
Reject-DongFuCase 'unmapped active book' {param($x) $x.dongfu_book[0].enabled=1}
Reject-DongFuCase 'duplicate resource cost' {param($x) $x.dongfu_recipe[0].cost_items=@(@(1,2),@(1,3))}
Reject-DongFuCase 'invalid garden stage threshold' {param($x) $x.dongfu_crop[0].enabled=1; $x.dongfu_crop[0].seed_item_id=41012; $x.dongfu_building[0].enabled=1; $x.dongfu_crop[0].outputs=,@(11012,1); $x.dongfu_crop[0].middle_progress_bp=10000}
Reject-DongFuCase 'incomplete garden plot set' {param($x) $x.dongfu_garden_plot[0].enabled=0}
Reject-DongFuCase 'unmapped spirit battle attribute' {param($x) $x.dongfu_spirit_level[0].enabled=1; $x.dongfu_spirit_root_level[0].combat_attributes=,@(34,1)}
# Isolated formal-table fixtures: grade lookup ignores record-ID spacing.
$spiritTables=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $tables -Depth 64) -AsHashtable
$spiritTables.dongfu_building=@($spiritTables.dongfu_building | Where-Object { $_.function_type -ne 'spirit' })
$building=$spiritTables.dongfu_building[0].Clone();$building.id=99;$building.function_type='spirit';$building.open_level=1;$building.enabled=1;$spiritTables.dongfu_building+=,$building
$spiritTables.dongfu_spirit_level=@(
 @{id=100;level=0;storage=180;cost_items=@(@(60000,1),@(60001,1));spirit_per_second=1;enabled=1}
 @{id=200;level=1;storage=396;cost_items=,@(60000,1);spirit_per_second=3;enabled=1}
 @{id=300;level=2;storage=648;cost_items=@();spirit_per_second=7;enabled=1}
)
$rootRows=@(foreach($level in 0..10){
 $attributes=@();if($level){$attributes=,@(1,$level)}
 $positions=@(2,4);if($level%2){$positions=@(1,3,5)}
 @{id=1000+$level*7;root_type=1;level=$level;name="品阶$level";spirit_cost=$(if($level -lt 10){@(60054,1)}else{$null});cost_items=@();growth_reduction_bp=$level*50;yield_bonus_bp=$level*20;combat_attributes=$attributes;target_positions=$positions;enabled=1}
})
foreach($type in 2..5){$rootRows+=@{id=4000+$type;root_type=$type;level=0;name='初始';spirit_cost=$null;cost_items=@();growth_reduction_bp=0;yield_bonus_bp=0;combat_attributes=@();target_positions=@();enabled=1}}
$spiritTables.dongfu_spirit_root_level=$rootRows
Test-UnityDongFuTables $spiritTables $Root
Reject-DongFuCase 'missing array next grade' {param($x) $x.dongfu_spirit_level[2].cost_items=,@(60000,1)} $spiritTables
Reject-DongFuCase 'maximum array followed by grade' {param($x) $x.dongfu_spirit_level[0].cost_items=@()} $spiritTables
Reject-DongFuCase 'unsupported spirit currency' {param($x) $x.dongfu_spirit_level[0].cost_items=,@(60002,1)} $spiritTables
Reject-DongFuCase 'disconnected array grades' {param($x) $x.dongfu_spirit_level[1].level=3} $spiritTables
Reject-DongFuCase 'wrong root element' {param($x) $x.dongfu_spirit_root_level[0].root_type=6} $spiritTables
Reject-DongFuCase 'missing root next grade' {param($x) $x.dongfu_spirit_root_level[1].level=99} $spiritTables
Reject-DongFuCase 'maximum root followed by grade' {param($x) $x.dongfu_spirit_root_level[0].spirit_cost=$null} $spiritTables
Reject-DongFuCase 'invalid spirit resource' {param($x) $x.dongfu_spirit_root_level[0].spirit_cost=@(60000,1)} $spiritTables
Reject-DongFuCase 'duplicate root spirit charge' {param($x) $x.dongfu_spirit_root_level[0].cost_items=,@(60054,1)} $spiritTables
Reject-DongFuCase 'blank root name' {param($x) $x.dongfu_spirit_root_level[0].name=''} $spiritTables
Reject-DongFuCase 'decreasing storage' {param($x) $x.dongfu_spirit_level[2].storage=0} $spiritTables
Reject-DongFuCase 'summed root growth over cap' {param($x) $x.dongfu_spirit_root_level[10].growth_reduction_bp=9000;$x.dongfu_spirit_root_level[11].growth_reduction_bp=2000} $spiritTables
Reject-DongFuCase 'summed position attributes overflow' {param($x) $x.dongfu_spirit_root_level[0].combat_attributes=,@(1,[int]::MaxValue);$x.dongfu_spirit_root_level[0].target_positions=@(1)} $spiritTables
Reject-DongFuCase 'active unsupported battle attribute' {param($x) $x.dongfu_spirit_root_level[1].combat_attributes=,@(34,1)} $spiritTables
$spiritTables.dongfu_spirit_root_level[0].spirit_cost=@(60054,[long]9007199254740993)
Test-UnityDongFuTables $spiritTables $Root
$spiritTables.dongfu_spirit_root_level[0].spirit_cost=@(60054,0)
Test-UnityDongFuTables $spiritTables $Root # filled zero remains upgradeable
$copy=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $tables -Depth 64) -AsHashtable
$copy.dongfu_recipe[0].cost_items=,@(1,[long]1099511627776)
Test-UnityDongFuTables $copy $Root
Write-Output "DongFu: $($schema.tables.Count) identical tables; auto grades, blank maxima, zero costs, 64-bit resources passed; $cases invalid cases rejected. No runtime save changes."
