# item.xlsx owns maintained records; the legacy snapshot is fallback for IDs absent from Excel.
function Read-UnityItemArray([string]$Raw,[bool]$Nested) {
    if([string]::IsNullOrWhiteSpace($Raw)){return ,@()}
    try{$v=ConvertFrom-Json -InputObject $Raw -NoEnumerate -AsHashtable}
    catch{$v=ConvertFrom-Json -InputObject ('['+$Raw+']') -NoEnumerate -AsHashtable}
    if($v -isnot [array]){throw 'Item array field must contain a JSON array.'}
    if($Nested -and $v.Count -and $v[0] -isnot [Collections.IList]){$v=,@($v)}
    return ,$v
}
function Get-UnityItemRows([string]$Root) {
    $baseline=Join-Path $Root 'unitydata/export/server/authoritative/json/item.json'
    $items=[ordered]@{}
    foreach($row in @(Get-Content -LiteralPath $baseline -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable)){
        $id=[string]$row.id
        if($id -notmatch '^[1-9]\d*$' -or $items.Contains($id)){throw "Invalid/duplicate legacy item ID: $id"}
        if(-not $row.ContainsKey('max_stack')){$row.max_stack=65000}
        $null=Assert-UnityItemStackLimit $row.max_stack
        $items[$id]=$row
    }
    $seen=@{}
    foreach($r in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/item.xlsx') -RejectFormulas)){
        if(-not @($r.Values | Where-Object { [string]$_ -ne '' }).Count){continue}
        $id=[string]$r.id
        if($id -notmatch '^[1-9]\d*$' -or $seen.ContainsKey($id)){throw "Invalid/duplicate formal item ID: $id"}
        $seen[$id]=$true;$record=[ordered]@{}
        foreach($key in @('id','name','des','pic','quality','type','use_type','sub_value','limit_lv','limit_time','sell','sort_priority','jiage','item_from','item_source','script','use_jump','max_stack')){
            if($key -in @('name','des','item_from','item_source')){$record[$key]=[string]$r[$key]}
            elseif($key -in @('sub_value','limit_time')){$record[$key]=Read-UnityItemArray ([string]$r[$key]) ($key -eq 'sub_value')}
            elseif($key -eq 'max_stack'){$record[$key]=Assert-UnityItemStackLimit $r[$key]}
            else{
                $raw=[string]$r[$key]
                if([string]::IsNullOrWhiteSpace($raw) -and $key -in @('use_jump','script','sell','jiage','sort_priority','limit_lv')){$raw='0'}
                if($raw -notmatch '^\d+$'){throw "Invalid item integer: $id.$key=$raw"}
                $record[$key]=[long]::Parse($raw,[Globalization.CultureInfo]::InvariantCulture)
            }
        }
        if([string]::IsNullOrWhiteSpace($record.name)){throw "Missing formal item name: $id"}
        $items[$id]=$record
    }
    if(-not $seen.Count){throw 'Formal item table is empty.'}
    return ,@($items.Values)
}
function Get-UnityItemSignature([string]$Text) {
    $rows=ConvertFrom-Json -InputObject $Text -AsHashtable -NoEnumerate
    $canonical=@(foreach($r in @($rows | Sort-Object { [long]$_['id'] })){
        $v=[ordered]@{};foreach($key in @($r.Keys | Sort-Object)){$v[$key]=$r[$key]};$v
    })
    return ConvertTo-Json -InputObject $canonical -Depth 64 -Compress
}
function Add-UnityItemWrites($Rows) {
    $content=(ConvertTo-Json -InputObject @($Rows) -Depth 64 -Compress)+[Environment]::NewLine
    $signature=Get-UnityItemSignature $content
    $targets=@()
    if($Mode -in @('Server','Both')){
        $targets+='unitydata/export/server/generated/json_server/item.json'
        if($ApplyRuntime){$targets+='unityserver/config/json/item.json'}
    }
    if($Mode -in @('Client','Both')){
        $targets+='unitydata/export/client/source/Configs/item.json'
        if($ApplyRuntime){$targets+='unityclient/Assets/Resources/ProjectXData/Configs/item.json'}
    }
    foreach($rel in $targets){
        $path=Join-Path $Root $rel;$value=$content
        if(Test-Path -LiteralPath $path){
            $old=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8)
            try{if((Get-UnityItemSignature $old) -ceq $signature){$value=$old}}catch{}
        }
        Add-Write $rel $value $path
    }
}
