# Function client projections share the realm condition in function.xlsx.
function Get-UnityFunctionOpenLevel($Row) {
    $conditions=@($Row.open_condition | Where-Object { $_.Count -eq 2 -and $_[0] -eq 1 })
    if ($conditions.Count -ne 1 -or $conditions[0][1] -lt 1) { throw "Function $($Row.function_id) requires exactly one positive realm condition." }
    return [long]$conditions[0][1]
}
function Test-UnityFunctionRows($Rows) {
    $unlockOrder=@{}; $gameplayOrder=@{}
    foreach ($r in $Rows) {
        if ($r.function_id -lt 1 -or [string]::IsNullOrWhiteSpace($r.name) -or $r.type -notin @(0,1)) { throw "Invalid Function identity/type: $($r.function_id)" }
        foreach ($pair in $r.open_condition) {
            if ($pair -isnot [array] -or $pair.Count -ne 2 -or $pair[0] -isnot [long] -or $pair[1] -isnot [long] -or $pair[0] -lt 1 -or $pair[1] -lt 0) { throw "Invalid Function condition: $($r.function_id)" }
        }
        foreach ($k in @('unlock_show_upcoming','steam_enabled','migration_ready')) { if ($r[$k] -notin @(-1,0,1)) { throw "Invalid Function flag $($r.function_id).$k" } }
        foreach ($pair in @(@('unlock_order',$unlockOrder),@('gameplay_order',$gameplayOrder))) {
            $key=$pair[0]; $seen=$pair[1]; $order=[long]$r[$key]
            if ($order -lt 0 -or ($order -gt 0 -and $seen.ContainsKey($order))) { throw "Invalid/duplicate Function order: $($key)=$order" }
            if ($order -gt 0) { $seen[$order]=$true; $null=Get-UnityFunctionOpenLevel $r }
        }
        if (($r.unlock_order -gt 0 -and [string]::IsNullOrWhiteSpace($r.unlock_name)) -or ($r.gameplay_order -gt 0 -and [string]::IsNullOrWhiteSpace($r.gameplay_name))) { throw "Missing Function client name: $($r.function_id)" }
    }
}
function Add-UnityFunctionClientWrites($Rows) {
    $unlocks=@(foreach($r in @($Rows | Where-Object unlock_order -gt 0 | Sort-Object { [long]$_['unlock_order'] })) {
        $v=[ordered]@{functionId=$r.function_id;name=$r.unlock_name;openLevel=(Get-UnityFunctionOpenLevel $r);icon=$r.unlock_icon}
        if($r.unlock_show_upcoming -ge 0){$v.showUpcoming=$r.unlock_show_upcoming -eq 1}
        $v
    })
    $gameplay=@(foreach($r in @($Rows | Where-Object gameplay_order -gt 0 | Sort-Object { [long]$_['gameplay_order'] })) {
        $v=[ordered]@{id=$r.function_id;name=$r.gameplay_name;page=$r.gameplay_page;openLevel=(Get-UnityFunctionOpenLevel $r);icon=$r.gameplay_icon;description=$r.gameplay_description;route=$r.gameplay_route}
        if($r.steam_enabled -ge 0){$v.steamEnabled=$r.steam_enabled -eq 1}
        if($r.migration_ready -ge 0){$v.migrationReady=$r.migration_ready -eq 1}
        $v
    })
    foreach($entry in @(@('function-unlocks.json',$unlocks),@('gameplay.json',$gameplay))) {
        $name=$entry[0];$rows=$entry[1];$content=(Json @($rows))+[Environment]::NewLine
        $source=Join-Path $Root ('unitydata/export/client/source/Configs/'+$name)
        if((Test-Path $source) -and (CanonicalJson ([IO.File]::ReadAllText($source,[Text.Encoding]::UTF8))) -ceq (CanonicalJson $content)){$content=[IO.File]::ReadAllText($source,[Text.Encoding]::UTF8)}
        Add-Write ('unitydata/export/client/source/Configs/'+$name) $content $source
        if($ApplyRuntime){Add-Write ('unityclient/Assets/Resources/ProjectXData/Configs/'+$name) $content $source}
    }
}
