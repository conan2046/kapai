function Assert-UnityItemStackLimit($Value) {
    if("$Value" -notmatch '^\d+$' -or [long]$Value -lt 1 -or [long]$Value -gt 65000) {
        throw 'item.max_stack must be an integer in 1..65000.'
    }
    return [int]$Value
}

function Get-UnityItemStackLimits([string]$Root) {
    $limits=@{}
    foreach($row in (Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/item.xlsx'))) {
        $id=[string]$row.id
        if($limits.ContainsKey($id)){throw "Duplicate item ID for max_stack: $id"}
        $limits[$id]=Assert-UnityItemStackLimit $row.max_stack
    }
    return $limits
}
