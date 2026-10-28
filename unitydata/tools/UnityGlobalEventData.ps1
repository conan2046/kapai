# Public conditions are maintained once; daily tasks only reference an event ID.
function Convert-EventInteger($Raw,[string]$Name,[long]$Min=0,[long]$Max=2147483647) {
    if([string]$Raw -notmatch '^[0-9]+$'){throw "Expected event integer: $Name=$Raw"}
    $n=[long]$Raw;if($n -lt $Min -or $n -gt $Max){throw "Event integer outside range: $Name=$Raw"};return $n
}
function Get-UnityGlobalEventData([string]$Root) {
    $supported=@(1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,20,21,25,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,54,55,56,57,59,60,1002,1003,1004,1005,1006,1007,1008,1010)
    $events=[Collections.Generic.List[object]]::new();$allIds=@{};$byId=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/event_config.xlsx') -SheetName event -RejectFormulas)){
        $id=Convert-EventInteger $r.id 'event.id' 1
        if($allIds.ContainsKey($id)){throw "Duplicate event ID $id"};$allIds[$id]=$true
        $enabled=Convert-EventInteger $r.enabled "event $id enabled" 0 1
        if(-not $enabled){continue}
        $e=[ordered]@{id=$id;name=[string]$r.name}
        foreach($k in @('type','num','param1','param2','count_start','cycle')){$e[$k]=Convert-EventInteger $r[$k] "event $id $k"}
        $e.enabled=1
        if($e.type -notin $supported -or $e.num -lt 1 -or $e.param2 -ne 0 -and $e.type -notin @(1006,1008) -or ($e.type -eq 1006 -and $e.param2 -gt 5) -or ($e.type -eq 1008 -and $e.param2 -gt 4) -or $e.cycle -gt 1 -or $e.count_start -notin @(1,2,3) -or
            ($e.count_start -eq 1 -and -not ($e.type -in @(30,1006,1008) -or ($e.type -eq 40 -and $e.num -eq 1))) -or
             (($e.cycle -eq 1) -ne ($e.count_start -eq 3))){throw "Unsupported enabled event contract: $id"}
        $events.Add($e);$byId[$id]=$e
    }
    if(-not $events.Count){throw 'Global event table has no enabled conditions.'}
    $tasks=[Collections.Generic.List[object]]::new();$taskIds=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/daily.xlsx') -SheetName Sheet1 -RejectFormulas)){
        if($r.Contains('condition')){throw 'daily.condition is retired; maintain event_id.'}
        $id=Convert-EventInteger $r.id 'daily.id' 1 65535
        if($taskIds.ContainsKey($id)){throw "Duplicate task $id"};$taskIds[$id]=$true
        $eid=Convert-EventInteger $r.event_id "daily $id event_id" 1
        if(-not $byId.ContainsKey($eid)){throw "Task $id references missing/disabled event $eid"}
        $t=[ordered]@{id=$id;type=(Convert-EventInteger $r.type "daily $id type");daily=[int]($byId[$eid].cycle -eq 1);
            level=(Convert-EventInteger $r.level "daily $id level");show=(Convert-EventInteger $r.show "daily $id show");des=[string]$r.des;event_id=$eid}
        $raw=[string]$r.reward
        try{$reward=ConvertFrom-Json -InputObject $raw -AsHashtable -NoEnumerate}
        catch{$reward=ConvertFrom-Json -InputObject ('['+$raw+']') -AsHashtable -NoEnumerate}
        if($reward -isnot [array]){throw "Invalid reward array task $id"}
        if($reward.Count -and $reward[0] -isnot [Collections.IList]){$reward=,@($reward)}
        foreach($a in $reward){
            if($a.Count -ne 3){throw "Invalid reward tuple task $id"}
            foreach($n in $a){if($n -isnot [int] -and $n -isnot [long] -or $n -lt 0){throw "Invalid reward value task $id"}}
        }
        $t.reward=$reward;$t.jump=Convert-EventInteger $r.jump "daily $id jump"
        $tasks.Add($t)
    }
    if(-not $tasks.Count){throw 'Daily task source is empty.'}
    foreach($t in $tasks){if($t.show -gt 0 -and -not $taskIds.ContainsKey($t.show)){throw "Unknown task predecessor $($t.show)"}}
    return @{events=$events.ToArray();tasks=$tasks.ToArray()}
}
function Add-UnityGlobalEventWrites($Data) {
    foreach($entry in @(@('event',$Data.events),@('daily',$Data.tasks))){
        $name=$entry[0]+'.json';$content=(Json @($entry[1]))+"`n"
        if($Mode -in @('Server','Both')){
            Add-Write ('unitydata/export/server/generated/json_server/'+$name) $content $null
            if($ApplyRuntime){Add-Write ('unityserver/config/json/'+$name) $content $null}
        }
        if($Mode -in @('Client','Both')){
            Add-Write ('unitydata/export/client/source/Configs/'+$name) $content $null
            if($ApplyRuntime){Add-Write ('unityclient/Assets/Resources/ProjectXData/Configs/'+$name) $content $null}
        }
    }
    if($Mode -in @('Client','Both')){
        # Deprecated presentation snapshot remains a generated ID-only projection,
        # preserving its GUID while eliminating its independent condition arrays.
        $projection=@(foreach($t in $Data.tasks){[ordered]@{id=$t.id;type=$t.type;daily=$t.daily;show=$t.show;des=$t.des;event_id=$t.event_id;jump=$t.jump}})
        $content=(Json @{items=$projection})+"`n"
        Add-Write 'unitydata/export/client/source/Tasks/daily_tasks.json' $content $null
        if($ApplyRuntime){Add-Write 'unityclient/Assets/Resources/ProjectXData/Tasks/daily_tasks.json' $content $null}
    }
}
