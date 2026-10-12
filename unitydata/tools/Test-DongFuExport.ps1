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
function Reject-DongFuCase([string]$Name,[scriptblock]$Edit){
    $copy=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $tables -Depth 64) -AsHashtable
    & $Edit $copy
    $rejected=$false
    try{Test-UnityDongFuTables $copy $Root}catch{$rejected=$true}
    if(-not $rejected){throw "DongFu invalid configuration accepted: $Name"}
    $script:cases++
}
Reject-DongFuCase 'zero duration' {param($x) $x.dongfu_recipe[0].duration_seconds=0}
Reject-DongFuCase 'invalid target' {param($x) $x.dongfu_spirit_level[0].target_scope='player'}
Reject-DongFuCase 'zero remaining time' {param($x) $x.dongfu_spirit_level[0].growth_reduction_bp=10000}
Reject-DongFuCase 'duplicate book members' {param($x) $x.dongfu_book_set[0].book_ids=@(1,1)}
Reject-DongFuCase 'invalid resource pair' {param($x) $x.dongfu_recipe[0].cost_items=@(@(1,0))}
Reject-DongFuCase 'unmapped seed' {param($x) $x.dongfu_crop[0].enabled=1; $x.dongfu_crop[0].seed_item_id=0}
Reject-DongFuCase 'unmapped active book' {param($x) $x.dongfu_book[0].enabled=1}
Reject-DongFuCase 'duplicate resource cost' {param($x) $x.dongfu_recipe[0].cost_items=@(@(1,2),@(1,3))}
Reject-DongFuCase 'invalid garden stage threshold' {param($x) $x.dongfu_crop[0].enabled=1; $x.dongfu_crop[0].seed_item_id=41012; $x.dongfu_building[0].enabled=1; $x.dongfu_crop[0].outputs=,@(11012,1); $x.dongfu_crop[0].middle_progress_bp=10000}
Reject-DongFuCase 'incomplete garden plot set' {param($x) $x.dongfu_garden_plot[0].enabled=0}
$copy=ConvertFrom-Json -InputObject (ConvertTo-Json -InputObject $tables -Depth 64) -AsHashtable
$copy.dongfu_recipe[0].cost_items=,@(1,[long]1099511627776)
Test-UnityDongFuTables $copy $Root
Write-Output "DongFu: $($schema.tables.Count) tables identical across client/server; field contracts passed; $cases invalid cases rejected; 64-bit quantities passed. No runtime database changes."
