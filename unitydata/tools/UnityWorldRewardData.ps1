# Formal groups replace whole compatibility groups; current runtime JSON is never an input.
function Convert-WorldInteger($Value,[string]$Context,[long]$Min=0,[long]$Max=2147483647) {
    $text=[string]$Value
    if($text -notmatch '^-?\d+$'){throw "Expected integer: $Context=$text"}
    $n=[long]::Parse($text,[Globalization.CultureInfo]::InvariantCulture)
    if($n -lt $Min -or $n -gt $Max){throw "Integer outside range: $Context=$text"}
    return $n
}
function Read-WorldAwardArray([string]$Raw,[string]$Context,[switch]$Preview) {
    if([string]::IsNullOrWhiteSpace($Raw)){if($Preview){return ,@()};throw "Empty reward row: $Context"}
    try{$items=ConvertFrom-Json -InputObject $Raw -NoEnumerate -AsHashtable}
    catch{$items=ConvertFrom-Json -InputObject ('['+$Raw+']') -NoEnumerate -AsHashtable}
    if($items -isnot [array]){throw "Expected reward array: $Context"}
    if($items.Count -and $items[0] -isnot [Collections.IList]){$items=,@($items)}
    if(-not $Preview -and -not $items.Count){throw "Empty reward row: $Context"}
    foreach($item in $items){
        $sizes=if($Preview){@(3)}else{@(3,4)}
        if($item -isnot [Collections.IList] -or $item.Count -notin $sizes){throw "Expected 3 or 4 reward values: $Context"}
        foreach($n in $item){if($n -isnot [int] -and $n -isnot [long]){throw "Reward values must be integers: $Context"};if($n -lt 0 -or $n -gt 2147483647){throw "Invalid reward value: $Context"}}
        if($item[0] -lt 1 -or ($item.Count -eq 4 -and $item[3] -lt $item[2])){throw "Invalid reward interval/type: $Context"}
    }
    return ,$items
}

# Typed battle sheets are shared maintenance inputs. Client output is a projection,
# never an input to server generation.
function Convert-WorldBattleInteger([string]$Raw,[string]$Context,[long]$Max=2147483647) {
    # Twenty retained Excel integer cells contain sub-1e-9 binary floating residue
    # (e.g. 6050.0000000000009). Restore their integer value; reject real fractions.
    if($Raw -notmatch '^-?\d+$' -and $Raw -match '^-?\d+(?:\.\d+)?(?:[Ee][+-]?\d+)?$') {
        $value=[decimal]::Parse($Raw,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture)
        $rounded=[decimal]::Round($value,0)
        if([math]::Abs($value-$rounded) -le [decimal]0.000000001){$Raw=$rounded.ToString('0',[Globalization.CultureInfo]::InvariantCulture)}
    }
    Convert-WorldInteger $Raw $Context -2147483648 $Max
}

function Read-WorldBattleSheet([string]$Root,[string]$Name) {
    $path=Join-Path $Root ('unitydata/excel/'+$Name+'.xlsx')
    $schema=@(Read-UnityVisualExcelRows $path -SheetName Sheet1 -FirstDataRow 4 -LastDataRow 4 -IgnoreCommentColumns)[0]
    $result=[Collections.Generic.List[object]]::new();$seen=@{}
    foreach($r in @(Read-UnityVisualExcelRows $path -SheetName Sheet1 -ResolveIntegerFormulas -IgnoreCommentColumns)){
        if(-not [string]$r.id){continue}
        $out=[ordered]@{}
        foreach($k in $schema.Keys) {
            $raw=[string]$r[$k]
            switch([string]$schema[$k]) {
                'int' {$out[$k]=if($raw){Convert-WorldBattleInteger $raw "$Name $($r.id).$k" $(if($k -eq 'qixue'){[long]::MaxValue}else{2147483647})}else{[long]0}}
                'string' {$out[$k]=$raw}
                {$_ -in @('array','arrays')} {
                    $items=@()
                    if($raw) {
                        try{$items=ConvertFrom-Json -InputObject $raw -NoEnumerate -AsHashtable}
                        catch{$items=ConvertFrom-Json -InputObject ('['+$raw+']') -NoEnumerate -AsHashtable}
                        if($items -isnot [array]){throw "Expected array: $Name $($r.id).$k"}
                        if($schema[$k] -eq 'arrays' -and $items.Count -and $items[0] -isnot [Collections.IList]){$items=,@($items)}
                        foreach($item in $items) {
                            if($schema[$k] -eq 'arrays' -and $item -isnot [Collections.IList]){throw "Expected nested array: $Name $($r.id).$k"}
                            foreach($n in @($item)){
                                if(($n -isnot [int] -and $n -isnot [long]) -or $n -lt -2147483648 -or $n -gt 2147483647){throw "Expected integer array: $Name $($r.id).$k"}
                            }
                        }
                    }
                    $out[$k]=$items
                }
                default {throw "Unsupported source type: $Name.$k"}
            }
        }
        if($out.id -lt 1 -or $seen.ContainsKey([string]$out.id)){throw "Invalid/duplicate $Name id: $($out.id)"}
        $seen[[string]$out.id]=$true
        $result.Add($out)
    }
    if(-not $result.Count){throw "Empty formal battle sheet: $Name"}
    return ,$result.ToArray()
}

function Get-UnityWorldRewardData([string]$Root) {
    $rewardRows=[Collections.Generic.List[object]]::new();$formalIds=@{};$sum=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/reward.xlsx') -SheetName Sheet1 -ResolveIntegerFormulas -IgnoreCommentColumns)){
        if(-not @($r.Values|Where-Object{[string]$_ -ne ''}).Count){continue}
        $id=Convert-WorldInteger $r.rewardid 'reward.rewardid' 1
        $mode=Convert-WorldInteger $r.drop_type "reward $id drop_type" 1 2
        $weight=Convert-WorldInteger $r.weight "reward $id weight"
        if(($mode -eq 1 -and $weight -ne 0) -or ($mode -eq 2 -and $weight -eq 0)){throw "Invalid weight for drop_type: $id"}
        $items=Read-WorldAwardArray ([string]$r.reward) "reward $id"
        $formalIds[[string]$id]=$true
        $rewardRows.Add([ordered]@{rewardid=$id;drop_type=$mode;reward=$items;weight=$weight})
    }
    if(-not $rewardRows.Count){throw 'Formal reward sheet is empty.'}
    $compatibility=0
    $compatPath=Join-Path $Root 'unitydata/export/server/authoritative/json/reward.json'
    foreach($r in @(Get-Content -LiteralPath $compatPath -Raw -Encoding UTF8|ConvertFrom-Json -AsHashtable)){
        $id=Convert-WorldInteger $r.rewardid 'compat rewardid' 1
        if($formalIds.ContainsKey([string]$id)){continue}
        $mode=if($r.ContainsKey('drop_type')){Convert-WorldInteger $r.drop_type 'compat drop_type' 1 2}else{[long]2}
        $weight=Convert-WorldInteger $r.weight 'compat weight'
        if(($mode -eq 1 -and $weight -ne 0) -or ($mode -eq 2 -and $weight -eq 0)){throw "Invalid compatibility reward weight: $id"}
        $items=Read-WorldAwardArray (ConvertTo-Json -InputObject $r.reward -Depth 16 -Compress) "compat reward $id"
        $rewardRows.Add([ordered]@{rewardid=$id;drop_type=$mode;reward=$items;weight=$weight});$compatibility++
    }
    foreach($r in $rewardRows){$key=[string]$r.rewardid;if($r.drop_type -eq 2){$sum[$key]+=$r.weight;if($sum[$key] -gt 2147483647){throw "Reward weight sum overflow: $key"}}}
    $allIds=@{};foreach($r in $rewardRows){$allIds[[string]$r.rewardid]=$true}
    $maps=[Collections.Generic.List[object]]::new();$seen=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/maplist.xlsx') -SheetName maplist -ResolveIntegerFormulas -IgnoreCommentColumns)){
        if(-not @($r.Values|Where-Object{[string]$_ -ne ''}).Count){continue}
        $v=[ordered]@{}
        foreach($k in @('ID','mapid','type','fightID','Levellimit','UnlockID','Hope','rewardID','DialogueId')){
            $max=if($k -eq 'Hope'){255}elseif($k -eq 'Levellimit'){65535}else{2147483647}
            $v[$k]=Convert-WorldInteger $r[$k] "maplist.$k" 0 $max
        }
        if($v.ID -eq 0 -or $v.mapid -eq 0 -or $v.fightID -eq 0 -or $v.type -notin @(1,2,3) -or $seen.ContainsKey([string]$v.ID)){throw "Invalid/duplicate maplist identity: $($v.ID)"}
        $seen[[string]$v.ID]=$true
        if($v.rewardID -and -not $allIds.ContainsKey([string]$v.rewardID)){throw "Missing reward group $($v.rewardID) for map $($v.ID)"}
        $v.Name=[string]$r.Name;$v.Des=[string]$r.Des
        $v.show_reward=Read-WorldAwardArray ([string]$r.show_reward) "maplist $($v.ID) preview" -Preview
        $maps.Add($v)
    }
    if(-not $maps.Count){throw 'Formal maplist sheet is empty.'}
    $fightRows=Read-WorldBattleSheet $Root 'fight_config'
    $monsterRows=Read-WorldBattleSheet $Root 'monster_boss_basic'
    $fights=@{};$monsters=@{}
    foreach($r in $fightRows){$fights[[string]$r.id]=$r}
    foreach($r in $monsterRows){$monsters[[string]$r.id]=$r}
    $chapterTypes=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/bigmap.xlsx') -SheetName bigmap -ColumnMap @{A='Id';B='MapType'})){
        if([string]$r.Id){$chapterTypes[[string]$r.Id]=Convert-WorldInteger $r.MapType 'bigmap.MapType' 1}
    }
    $mainFights=@{};$mainMonsters=@{};$missing=@{};$deferred=@{};$missingMonsters=@{}
    foreach($m in $maps) {
        if(-not $chapterTypes.ContainsKey([string]$m.mapid)){throw "Missing chapter for map $($m.ID)"}
        if($chapterTypes[[string]$m.mapid] -ne 1){
            if(-not $fights.ContainsKey([string]$m.fightID)){$deferred[[string]$m.fightID]=$true}
            continue
        }
        if(-not $fights.ContainsKey([string]$m.fightID)){$missing[[string]$m.fightID]=$true;continue}
        $f=$fights[[string]$m.fightID]
        if($f.zhenfa.Count -ne 2 -or $f.zhenfa[0] -le 0 -or $f.zhenfa[1] -le 0){throw "Invalid main dungeon formation: $($f.id)"}
        $mainFights[[string]$f.id]=[ordered]@{id=$f.id;show=$f.show}
        $roster=@($f.index1,$f.index2,$f.index3,$f.index4,$f.index5|Where-Object{$_ -gt 0})
        if(-not $roster.Count -or $f.show -le 0){throw "Empty main dungeon enemy/show: $($f.id)"}
        foreach($id in @($roster)+@($f.show)){
            if(-not $monsters.ContainsKey([string]$id)){$missingMonsters[[string]$id]=$true;continue}
            $monster=$monsters[[string]$id]
            if($monster.level -le 0 -or $monster.qixue -le 0 -or $monster.pic -le 0 -or $monster.scale -le 0){throw "Invalid main dungeon monster: $id"}
            $mainMonsters[[string]$id]=[ordered]@{id=$monster.id;pic=$monster.pic;scale=$monster.scale}
        }
    }
    # Validate references needed by main dungeon against the current formal runtime
    # skill/formation catalog. Other feature gaps are reported, not invented here.
    $skills=@{};$formations=@{}
    $skillXml=[xml][IO.File]::ReadAllText((Join-Path $Root 'unityserver/config/xml/skill_basic.xml'))
    foreach($n in $skillXml.DocumentElement.ChildNodes){if($n.NodeType -eq 'Element'){$skills[[string]$n.id]=$true}}
    $formationXml=[xml][IO.File]::ReadAllText((Join-Path $Root 'unityserver/config/xml/zhenfa_config.xml'))
    foreach($n in $formationXml.DocumentElement.ChildNodes){if($n.NodeType -eq 'Element'){$formations[[string]$n.id]=$true}}
    foreach($id in $mainFights.Keys){
        $f=$fights[$id]
        if(-not $formations.ContainsKey([string]$f.zhenfa[0])){throw "Missing main dungeon formation: $($f.zhenfa[0])"}
    }
    foreach($id in $mainMonsters.Keys){
        foreach($skill in $monsters[$id].skill_basic){
            if($skill.Count -ne 2 -or $skill[1] -le 0 -or -not $skills.ContainsKey([string]$skill[0])){throw "Missing/invalid main dungeon basic skill: monster $id"}
        }
    }
    return @{rewards=$rewardRows.ToArray();maps=$maps.ToArray();fights=$fightRows;monsters=$monsterRows;
        clientFights=@($mainFights.Values|Sort-Object { [long]$_.id });clientMonsters=@($mainMonsters.Values|Sort-Object { [long]$_.id });
        missingFightIds=@($missing.Keys|Sort-Object);missingMonsterIds=@($missingMonsters.Keys|Sort-Object);
        deferredFightIds=@($deferred.Keys|Sort-Object);compatibilityRows=$compatibility}

}
function Assert-UnityWorldRuntimeReady($Data) {
    if($Data.missingFightIds.Count -or $Data.missingMonsterIds.Count){throw "World runtime sync blocked: main dungeon missing fightIDs=$($Data.missingFightIds.Count), monsterIDs=$($Data.missingMonsterIds.Count). No runtime output written."}
}
function Convert-WorldLua($Value) {
    if($Value -is [Collections.IDictionary]){return '{'+(@(foreach($k in $Value.Keys){$k+' = '+(Convert-WorldLua $Value[$k])}) -join ',')+'}'}
    if($Value -is [Collections.IList]){return '{'+(@(foreach($x in $Value){Convert-WorldLua $x}) -join ',')+'}'}
    if($Value -is [string]){
        if($Value -match '[\x00-\x08\x0b\x0c\x0e-\x1f]'){throw 'Unsupported control character in world text'}
        return ConvertTo-Json -InputObject $Value -Compress
    }
    return [Convert]::ToString($Value,[Globalization.CultureInfo]::InvariantCulture)
}
function Add-UnityWorldRewardWrites($Data) {
    if($ApplyRuntime){Assert-UnityWorldRuntimeReady $Data}
    if($Mode -in @('Both','Server')){
        foreach($pair in @(@('reward',$Data.rewards),@('maplist',$Data.maps),@('fight_config',$Data.fights),@('monster_boss_basic',$Data.monsters))){
            $content=(Json @($pair[1]))+[Environment]::NewLine
            Add-Write ('unitydata/export/server/generated/json_server/'+$pair[0]+'.json') $content
            if($ApplyRuntime){Add-Write ('unityserver/config/json/'+$pair[0]+'.json') $content}
        }
    }
    if($Mode -in @('Both','Client')){
        $nl=[Environment]::NewLine
        foreach($pair in @(@('maplist_dat',$Data.maps),@('main_dungeon_fight_dat',$Data.clientFights),@('main_dungeon_monster_dat',$Data.clientMonsters))) {
            $content=$pair[0]+' = {'+$nl+(@(foreach($r in $pair[1]){'    '+(Convert-WorldLua $r)+','}) -join $nl)+$nl+'}'+$nl
            Add-Write ('unitydata/export/client/source/World/'+$pair[0]+'.txt') $content
            if($ApplyRuntime){Add-Write ('unityclient/Assets/Resources/ProjectXData/World/'+$pair[0]+'.txt') $content}
        }
    }
    Write-Output ("WorldRewards formalRewardRows={0}; compatibilityRows={1}; maps={2}; missingMainFightIds={3}; mainFights={4}; mainMonsters={5}; deferredOtherFightIds={6}" -f ($Data.rewards.Count-$Data.compatibilityRows),$Data.compatibilityRows,$Data.maps.Count,$Data.missingFightIds.Count,$Data.clientFights.Count,$Data.clientMonsters.Count,$Data.deferredFightIds.Count)
}
