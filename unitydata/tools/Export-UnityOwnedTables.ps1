[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$Group = 'All',
    [ValidateSet('Both','Client','Server')][string]$Mode = 'Both',
    [bool]$ApplyRuntime = $true,
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Read-UnityVisualExcel.ps1')
. (Join-Path $PSScriptRoot 'ItemStackRules.ps1')
if($Group -eq 'ItemStacks') {
    $limits=Get-UnityItemStackLimits $Root
    $items=@(Get-Content -LiteralPath (Join-Path $Root 'unityserver/config/json/item.json') -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable)
    foreach($item in $items){$key=[string]$item.id;$item.max_stack=if($limits.ContainsKey($key)){$limits[$key]}else{65000}}
    if(-not $ValidateOnly){
        $json=(ConvertTo-Json -InputObject $items -Depth 32 -Compress)+"`n"
        foreach($path in @('unityserver/config/json/item.json','unitydata/export/server/generated/json_server/item.json','unitydata/export/server/source/authoritative/json/item.json','unityclient/Assets/Resources/ProjectXData/Configs/item.json','unitydata/export/client/source/Configs/item.json')) {
            $target=Join-Path $Root $path
            if(Test-Path -LiteralPath (Split-Path $target -Parent)){[IO.File]::WriteAllText($target,$json,[Text.UTF8Encoding]::new($false))}
        }
    }
    Write-Output "ItemStacks: $($limits.Count) formal limits exported; other frozen item fields retained."
    return
}
# Scoped append/update of garden items from the formal item workbook. Preserve the
# frozen legacy records; do not run the legacy converter across unrelated tables.
if ($Group -in @('GardenItems','SpiritItems','LibraryItems','AlchemyItems')) {
    $gardenItemIds=@{}
    if($Group -eq 'AlchemyItems') {
        foreach($recipe in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/dongfu_config.xlsx') -SheetName 'dongfu_alchemy_recipe')) {
            if([string]$recipe.enabled -ne '1'){continue}
            $gardenItemIds[[string]$recipe.learn_item_id]=$true
            $gardenItemIds[[string]$recipe.output_item_id]=$true
            foreach($pair in (ConvertFrom-Json -InputObject ([string]$recipe.cost_items) -NoEnumerate)){$gardenItemIds[[string]$pair[0]]=$true}
        }
    }
    if($Group -eq 'SpiritItems') { $gardenItemIds['60054']=$true }
    if($Group -eq 'LibraryItems') {
        foreach($book in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/dongfu_config.xlsx') -SheetName 'dongfu_book')) {
            if([string]$book.enabled -eq '1') { $gardenItemIds[[string]$book.item_id]=$true }
        }
    }
    foreach($crop in @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/dongfu_config.xlsx') 2 -SheetName 'dongfu_crop')) {
        if($Group -in @('SpiritItems','LibraryItems','AlchemyItems') -or [string]$crop.enabled -ne '1') { continue }
        $gardenItemIds[[string]$crop.seed_item_id]=$true
        $outputs=ConvertFrom-Json -InputObject ([string]$crop.outputs) -NoEnumerate
        foreach($pair in $outputs) { $gardenItemIds[[string]$pair[0]]=$true }
    }
    if(-not $gardenItemIds.Count) { throw 'No enabled garden crop item references.' }
    $sourceRows = @(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/item.xlsx'))
    $records = @(foreach ($r in $sourceRows) {
        if (-not $gardenItemIds.ContainsKey([string]$r.id)) { continue }
        $record=[ordered]@{}
        foreach($key in @('id','name','des','pic','quality','type','use_type','sub_value','limit_lv','limit_time','sell','sort_priority','jiage','item_from','item_source','script','use_jump','max_stack')) {
            if($key -in @('name','des','item_from','item_source')) { $record[$key]=[string]$r[$key] }
            elseif($key -in @('sub_value','limit_time')) {
                $cell=[string]$r[$key]
                if([string]::IsNullOrWhiteSpace($cell)){$record[$key]=@()}
                else{$record[$key]=ConvertFrom-Json -InputObject $cell -NoEnumerate}
                if($key -eq 'sub_value' -and $record[$key].Count -and $record[$key][0] -isnot [System.Collections.IList]) {
                    $record[$key]=,@($record[$key])
                }
            }
            elseif($key -eq 'max_stack'){$record[$key]=Assert-UnityItemStackLimit $r[$key]}
            else {
                $cell=[string]$r[$key]
                if([string]::IsNullOrWhiteSpace($cell) -and $key -in @('use_jump','script','sell','jiage','sort_priority','limit_lv')){$cell='0'}
                $record[$key]=[long]::Parse($cell)
            }
        }
        $record
    })
    if($records.Count -ne $gardenItemIds.Count) { throw 'Garden formal item records are missing or duplicated.' }
    $base=Join-Path $Root 'unityserver/config/json/item.json'
    $items=@(Get-Content -LiteralPath $base -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable | Where-Object { -not $gardenItemIds.ContainsKey([string]$_.id) }) + $records
    if(-not $ValidateOnly) {
        $json=(ConvertTo-Json -InputObject $items -Depth 32 -Compress)+"`n"
        foreach($path in @('unityserver/config/json/item.json','unitydata/export/server/generated/json_server/item.json','unitydata/export/server/source/authoritative/json/item.json','unityclient/Assets/Resources/ProjectXData/Configs/item.json','unitydata/export/client/source/Configs/item.json')) {
            $target=Join-Path $Root $path
            if(Test-Path -LiteralPath (Split-Path $target -Parent)) { [IO.File]::WriteAllText($target,$json,[Text.UTF8Encoding]::new($false)) }
        }
    }
    Write-Output "${Group}: $($records.Count) formal item records exported; legacy records retained."
    return
}
$manifest = Get-Content (Join-Path $PSScriptRoot 'unity-owned-tables.json') -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
$requestedDataGroup=$Group
if ($Group -eq 'DongFu' -and $Mode -eq 'Both' -and -not $ValidateOnly) {
    & $PSCommandPath -Root $Root -Group GardenItems -Mode Both
    & $PSCommandPath -Root $Root -Group SpiritItems -Mode Both
    & $PSCommandPath -Root $Root -Group LibraryItems -Mode Both
    & $PSCommandPath -Root $Root -Group AlchemyItems -Mode Both
    & $PSCommandPath -Root $Root -Group ItemStacks -Mode Both
    & $PSCommandPath -Root $Root -Group LibraryRealm -Mode Both
}
$Group=$requestedDataGroup
$groups = @($manifest.groups | Where-Object { $Group -eq 'All' -or $_.group -eq $Group })
if (-not $groups.Count) { throw "Unknown Unity data group: $Group" }
$writes = [Collections.Generic.List[object]]::new()
$deletes = [Collections.Generic.List[string]]::new()
$schemaPath = Join-Path $Root 'unityserver/sql/sqlite/001_initial_schema.sql'
$schema = [IO.File]::ReadAllText($schemaPath, [Text.Encoding]::UTF8)
$culture = [Globalization.CultureInfo]::InvariantCulture
function Json($Value) { ConvertTo-Json -InputObject $Value -Depth 64 -Compress }
function CanonicalJson([string]$Value) { Json (ConvertFrom-Json -InputObject $Value -AsHashtable -NoEnumerate) }
function Add-Write([string]$Relative, [string]$Content, [string]$Reference) {
    $bytes=[Text.UTF8Encoding]::new($false).GetBytes($Content)
    if ($Reference -and (Test-Path $Reference) -and [IO.File]::ReadAllText($Reference,[Text.Encoding]::UTF8) -ceq $Content) { $bytes=[IO.File]::ReadAllBytes($Reference) }
    $writes.Add(@{ path=(Join-Path $Root $Relative); content=$Content; bytes=$bytes })
}
function Xml-Signature([string]$Value) {
    $xml = [xml]$Value
    $rows = @($xml.DocumentElement.ChildNodes | Where-Object NodeType -eq Element | ForEach-Object {
        $attributes = [ordered]@{}
        foreach ($a in ($_.Attributes | Sort-Object Name)) { $attributes[$a.Name] = $a.Value }
        @{ name=$_.Name; attributes=$attributes }
    })
    $rootAttrs = [ordered]@{}
    foreach ($a in ($xml.DocumentElement.Attributes | Sort-Object Name)) { $rootAttrs[$a.Name]=$a.Value }
    Json @{ root=$xml.DocumentElement.Name; attributes=$rootAttrs; rows=$rows }
}
function Read-Rows($Sheet, [string]$Workbook) {
    $result = [Collections.Generic.List[object]]::new()
    $keys = @{}
    $gatedIdentities = @{}
    $dictionaries = @{}
    $dictionaryFields=@()
    if($Sheet.columnDictionaries){$dictionaryFields=@($Sheet.columnDictionaries.Keys)}
    foreach($field in $dictionaryFields) {
        $definition=$Sheet.columnDictionaries[$field]
        $isGateStatus=$Sheet.exportGate -and $field -eq $Sheet.exportGate.statusColumn
        if($Sheet.columns[$field] -ne 'string' -and -not $isGateStatus){throw "Dictionary requires a string column: $($Sheet.name).$field"}
        $dictionaryWorkbook=if($definition.workbook){Join-Path (Split-Path $Workbook -Parent) $definition.workbook}else{$Workbook}
        $map=@{};$canonical=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $columnMap=@{};$columnMap[[string]$definition.labelColumn]='label';$columnMap[[string]$definition.valueColumn]='value'
        $lastRow=if($definition.lastDataRow){[int]$definition.lastDataRow}else{1048576}
        foreach($entry in @(Read-UnityVisualExcelRows -Path $dictionaryWorkbook -SheetName $definition.sheet -ColumnMap $columnMap -FirstDataRow $definition.firstDataRow -LastDataRow $lastRow -RejectFormulas)) {
            $label=([string]$entry.label).Trim();$value=([string]$entry.value).Trim()
            if(-not $label -and -not $value){continue}
            if(-not $label -or -not $value){throw "Incomplete source dictionary $($Sheet.name).$field"}
            if($map.ContainsKey($label)){throw "Duplicate dictionary label $($Sheet.name).${field}: $label"}
            if(-not $canonical.Add($value)){throw "Duplicate dictionary value $($Sheet.name).${field}: $value"}
            $map[$label]=$value
        }
        if(-not $map.Count){throw "Empty source dictionary $($Sheet.name).$field"}
        $dictionaries[$field]=@{labels=$map;canonical=$canonical;separator=[string]$definition.separator;allowBlank=[bool]$definition.allowBlank}
    }
    function Convert-SourceLabel([string]$Field,[string]$Raw) {
        if(-not $dictionaries.ContainsKey($Field)){return $Raw}
        $dictionary=$dictionaries[$Field]
        if($dictionary.allowBlank -and [string]::IsNullOrWhiteSpace($Raw)){return ''}
        $parts=if($dictionary.separator){@($Raw -split [regex]::Escape($dictionary.separator))}else{@($Raw)}
        $translated=[Collections.Generic.List[string]]::new()
        foreach($part in $parts) {
            $label=([string]$part).Trim()
            if($dictionary.labels.ContainsKey($label)){$translated.Add($dictionary.labels[$label])}
            elseif($dictionary.canonical.Contains($label)){$translated.Add($label)}
            else{throw "Unknown source label $($Sheet.name).${Field}: $label"}
        }
        return $translated -join $dictionary.separator
    }
    $sourceSheet=if($Sheet.sourceSheet){$Sheet.sourceSheet}else{$Sheet.name}
    foreach ($r in @(Read-UnityVisualExcelRows $Workbook $Sheet.sheetIndex -SheetName $sourceSheet -RejectFormulas)) {
        if ($Sheet.kind -ne 'xml' -and -not @($r.Values | Where-Object { [string]$_ -ne '' }).Count) { continue }
        # Editorial draft rows share the maintenance sheet with live records.
        # Validate their identity/status before skipping them; never serialize
        # incomplete curves, proposed quality gates or placeholder descriptions.
        if ($Sheet.exportGate) {
            $gate=$Sheet.exportGate
            foreach($field in @($gate.column,$gate.statusColumn)+@($gate.requiredFields)) {
                if(-not $r.Contains($field) -or [string]::IsNullOrWhiteSpace([string]$r[$field])) {
                    throw "Missing gated field $($Sheet.name).$field"
                }
            }
            foreach($field in @($gate.uniqueFields)) {
                $identity="$field`:$($r[$field])"
                if($gatedIdentities.ContainsKey($identity)){throw "Duplicate gated identity $($Sheet.name).${identity}"}
                $gatedIdentities[$identity]=$true
            }
            if([string]$r.id -notmatch '^[1-9]\d*$'){throw "Invalid gated ID $($Sheet.name): $($r.id)"}
            $flag=[string]$r[$gate.column];$status=Convert-SourceLabel $gate.statusColumn ([string]$r[$gate.statusColumn])
            if($flag -notin @('0','1')){throw "Invalid export gate $($Sheet.name).$($gate.column)=$flag"}
            if($flag -eq '0') {
                if($status -notin @($gate.disabledStatuses)){throw "Invalid disabled status $($Sheet.name): $status"}
                continue
            }
            if($status -cne $gate.enabledStatus){throw "Unready row cannot be enabled $($Sheet.name): $($r.id)"}
        }
        $v = [ordered]@{}
        foreach ($k in $Sheet.columns.Keys) {
            if (-not $r.Contains($k)) { throw "Missing field $($Sheet.name).$k" }
            $raw = [string]$r[$k]
            if([string]::IsNullOrWhiteSpace($raw) -and $Sheet.blankDefaults -and $Sheet.blankDefaults.ContainsKey($k)) { $raw=[string]$Sheet.blankDefaults[$k] }
            $raw=Convert-SourceLabel $k $raw
            $v[$k] = switch ($Sheet.columns[$k]) {
                'number' {
                    if ($raw -notmatch '^-?\d+(\.\d+)?$') { throw "Invalid number $($Sheet.name).${k}=$raw" }
                    if ($Sheet.integerColumns -and $k -in $Sheet.integerColumns -and $raw -notmatch '^-?\d+$') { throw "Expected integer $($Sheet.name).$k" }
                    if ($raw -match '^-?\d+$') { [long]::Parse($raw,$culture) }
                    else { [decimal]::Parse($raw,$culture) }
                }
                'resource-cost' {
                    if([string]::IsNullOrWhiteSpace($raw)) { $null }
                    elseif($raw -match '^60054;([0-9]+)$') { ,@([long]60054,[long]::Parse($Matches[1],$culture)) }
                    else { throw "Expected 60054;quantity or blank: $($Sheet.name).$k=$raw" }
                }
                'bool' {
                    if ($raw -notin @('0','1','true','false')) { throw "Invalid boolean $($Sheet.name).$k" }
                    $raw -in @('1','true')
                }
                'json' {
                    $parsed=ConvertFrom-Json -InputObject $raw -NoEnumerate -AsHashtable
                    $jsonKind=if ($null -eq $parsed) { 'null' } elseif ($parsed -is [Collections.IDictionary]) { 'object' } elseif ($parsed -is [array]) { 'array' } else { 'scalar' }
                    if ($Sheet.jsonKinds -and $jsonKind -notin $Sheet.jsonKinds[$k]) { throw "Unexpected JSON shape $($Sheet.name).$k" }
                    ,$parsed
                }
                'string' {
                    if ($k -in @($Sheet.numericStringColumns) -and $raw -ne '' -and $raw -notmatch '^-?\d+(\.\d+)?$') { throw "Invalid numeric XML field $($Sheet.name).$k" }
                    $raw
                }
                default { throw "Unsupported type $($Sheet.columns[$k])" }
            }
        }
        $primary = if ($Sheet.primaryColumn) { $Sheet.primaryColumn } elseif ($Sheet.kind -ne 'xml' -and $v.Contains('id')) { 'id' } else { $null }
        if ($primary) {
            $id = [string]$v[$primary]
            if ($keys.ContainsKey($id)) { throw "Duplicate ID $($Sheet.name): $id" }
            $keys[$id] = $true
        }
        $result.Add($v)
    }
    if (-not $result.Count) { throw "Empty Unity table: $($Sheet.name)" }
    return ,$result.ToArray()
}
function Check-Group($Name,$Tables) {
    if ($Name -eq 'HeroCombat') {
        . (Join-Path $PSScriptRoot 'Test-UnityCombatTables.ps1')
        Test-UnityCombatTables $Tables $Root
    }
    if ($Name -eq 'DongFu') {
        . (Join-Path $PSScriptRoot 'Test-UnityDongFuTables.ps1')
        Test-UnityDongFuTables $Tables $Root
    }
    if ($Name -eq 'Fish') {
        if ($Tables.fish_settings.Count -ne 1 -or $Tables.fish_position.Count -ne 1) { throw 'Fish requires one settings and position row.' }
        $s=$Tables.fish_settings[0]; $p=$Tables.fish_position[0]
        if ($s.id -ne 1 -or $p.id -ne 1 -or $s.gold_cost -lt 1 -or $s.cycle_min_seconds -lt 1 -or
            $s.cycle_max_seconds -lt $s.cycle_min_seconds -or $s.cycle_max_seconds -gt 65535 -or
            $s.basket_capacity -lt 1 -or $s.basket_capacity -gt 9999 -or $s.fish_stack_limit -lt 1 -or $s.fish_stack_limit -gt 999 -or
            $s.auto_continue -notin @(0,1) -or $p.scene_id -ne 54 -or $p.map_id -ne 33 -or $p.fishing_shape_id -ne 2000 -or $p.flip -notin @(0,1)) {
            throw 'Fish settings violate current runtime limits/scene contract.'
        }
        $items=@{}; $seen=@{}
        foreach ($i in @(Get-Content (Join-Path $Root 'unityserver/config/json/item.json') -Raw -Encoding UTF8 | ConvertFrom-Json)) { $items[[string]$i.id]=$true }
        foreach ($r in $Tables.fish_reward) {
            if (-not $items.ContainsKey([string]$r.item_id) -or $seen.ContainsKey([string]$r.item_id) -or
                $r.weight -lt 0 -or $r.enabled -notin @(0,1) -or $r.use_reward_id -ne 0) { throw 'Invalid/duplicate Fish item, weight or reward mode.' }
            $seen[[string]$r.item_id]=$true
        }
        if (-not @($Tables.fish_reward | Where-Object { $_.enabled -eq 1 -and $_.weight -gt 0 }).Count) { throw 'Fish requires an enabled positive-weight reward.' }
    }
    if ($Name -eq 'Answer') {
        $s=$Tables['answer-settings'][0]
        if ($Tables['answer-settings'].Count -ne 1 -or $s.id -ne 1 -or $s.daily_attempt_limit -lt 1 -or $s.daily_attempt_limit -gt 255 -or $s.fallback_reward_type -ne 60000 -or $s.fallback_reward_amount -lt 1) { throw 'Invalid Answer settings.' }
        foreach ($r in $Tables.question) {
            foreach ($k in @('question','answer1','answer2','answer3','answer4')) { if ([string]::IsNullOrWhiteSpace($r[$k])) { throw "Empty question field: $k" } }
        }
    }
    if ($Name -eq 'HappyWheel') {
        $s=$Tables['happywheel-settings'][0]; $r=$Tables['happywheel-rewards']
        if ($Tables['happywheel-settings'].Count -ne 1 -or $s.enabled -notin @(0,1) -or $s.reward_type -ne 2 -or
            $r.Count -ne $s.display_slot_count -or ($r | ForEach-Object { $_['rate'] } | Measure-Object -Sum).Sum -ne 10000 -or
            $s.single_draw_count -lt 1 -or $s.multi_draw_count -lt 1 -or $s.single_key_cost -lt 1 -or $s.multi_key_cost -lt 1) { throw 'Invalid HappyWheel draw/weight contract.' }
        foreach ($row in $r) { if ($row.type -ne $s.reward_type -or $row.rate -lt 1 -or $row.num -lt 1) { throw 'Invalid HappyWheel reward.' } }
        foreach ($k in @('cost_item_id','score_per_draw','score_ext32_idx','daily_reset_ext32_idx','history_limit','display_slot_count')) {
            if ($s[$k] -le 0) { throw "Invalid HappyWheel setting: $k" }
        }
        if ($s.history_limit -gt 50 -or [string]::IsNullOrWhiteSpace($s.insufficient_tip)) { throw 'Invalid HappyWheel history/tip contract.' }
    }
}
function Sql-Value($Value,[bool]$Text) {
    if ($Text -or $Value -is [string]) { return "'"+([string]$Value).Replace("'","''")+"'" }
    return [Convert]::ToString($Value,$culture)
}
function Seed-Sql($Group,$Tables,$Seed) {
    $lines=[Collections.Generic.List[string]]::new(); $lines.Add('-- BEGIN '+$Seed.marker)
    foreach ($sheet in $Group.sheets) {
        if (-not $sheet.sql -or ($Seed.sheet -and $sheet.name -ne $Seed.sheet)) { continue }
        $sql=$sheet.sql; $rows=$Tables[$sheet.name]; $columns=@($sql.columns)
        if ($sql.delete) { $lines.Add('DELETE FROM '+$sql.table+';') }
        if ($sql.deleteWhere) { $lines.Add('DELETE FROM '+$sql.table+' WHERE '+$sql.deleteWhere+';') }
        $lines.Add('INSERT INTO '+$sql.table+' ('+($columns -join ',')+') VALUES')
        $values=@(foreach ($row in $rows) {
            $cells=@(foreach ($k in $columns) { Sql-Value $row[$k] ($k -in @($sql.textColumns)) })
            '('+($cells -join ',')+')'
        })
        $lines.Add(($values -join ",`n"))
        if ($sql.key) {
            $updates=@($columns | Where-Object { $_ -ne $sql.key } | ForEach-Object { $_+'=excluded.'+$_ })
            $lines.Add('ON CONFLICT('+$sql.key+') DO UPDATE SET '+($updates -join ',')+';')
        } else { $lines[$lines.Count-1]+=';' }
        if ($sql.sequence) {
            $max=($rows | ForEach-Object { $_['id'] } | Measure-Object -Maximum).Maximum
            if ($null -eq $max) { throw "Missing sequence maximum for $($sql.table)" }
            $lines.Add("DELETE FROM sqlite_sequence WHERE name='$($sql.table)';")
            $lines.Add("INSERT INTO sqlite_sequence(name,seq) VALUES('$($sql.table)',$max);")
        }
    }
    $lines.Add('-- END '+$Seed.marker)
    return ($lines -join "`n")+"`n"
}
foreach ($g in $groups) {
    $tables=@{}
    foreach ($s in $g.sheets) {
        $sourceWorkbook=if($s.workbook){$s.workbook}else{$g.workbook}
        $tables[$s.name]=Read-Rows $s (Join-Path $Root ('unitydata/excel/'+$sourceWorkbook))
    }
    Check-Group $g.group $tables
    foreach ($output in $g.retiredJsonOutputs) {
        if ($output -cnotmatch '^[a-z0-9_-]+\.json$' -or @($g.sheets | Where-Object { $_.output -eq $output -or $_.jsonOutput -eq $output }).Count) { throw "Invalid/in-use retired JSON output: $output" }
        if ($Mode -in @('Server','Both')) {
            $deletes.Add((Join-Path $Root ('unitydata/export/server/generated/json_server/'+$output)))
            if ($ApplyRuntime) { $deletes.Add((Join-Path $Root ('unityserver/config/json/'+$output))) }
        }
        if ($Mode -in @('Client','Both')) {
            $deletes.Add((Join-Path $Root ('unitydata/export/client/source/Configs/'+$output)))
            if ($ApplyRuntime) {
                $retiredAsset=Join-Path $Root ('unityclient/Assets/Resources/ProjectXData/Configs/'+$output)
                $deletes.Add($retiredAsset); $deletes.Add($retiredAsset+'.meta')
            }
        }
    }
    foreach ($s in $g.sheets) {
        $rows=$tables[$s.name]
        $clientRows=$rows
        if ($s.clientOnlyColumns) {
            $rows=@(foreach ($row in $rows) {
                $serverRow=[ordered]@{}
                foreach ($k in $s.columns.Keys) { if ($k -notin $s.clientOnlyColumns) { $serverRow[$k]=$row[$k] } }
                $serverRow
            })
        }
        if ($s.kind -eq 'xml') {
            $doc=[xml]('<'+$s.rootTag+'/>')
            foreach ($k in $s.rootAttributes.Keys) { $doc.DocumentElement.SetAttribute($k,[string]$s.rootAttributes[$k]) }
            foreach ($r in $rows) {
                $node=$doc.CreateElement($s.rowTag)
                foreach ($k in $s.columns.Keys) { $node.SetAttribute($k,[Convert]::ToString($r[$k],$culture)) }
                $null=$doc.DocumentElement.AppendChild($node)
            }
            $content='<?xml version="1.0" encoding="UTF-8"?>'+"`n"+$doc.OuterXml+"`n"
            $runtime='unityserver/config/xml/'+$s.output; $generated='unitydata/export/server/generated/xml/'+$s.output
            $existing=Join-Path $Root $runtime
            if ((Test-Path $existing) -and (Xml-Signature ([IO.File]::ReadAllText($existing))) -ceq (Xml-Signature $content)) { $content=[IO.File]::ReadAllText($existing) }
        } elseif ($s.kind -eq 'json') {
            $content=(Json @($rows))+"`n"; $runtime='unityserver/config/json/'+$s.output; $generated='unitydata/export/server/generated/json_server/'+$s.output
            $existing=Join-Path $Root $runtime
            if ((Test-Path $existing) -and (CanonicalJson ([IO.File]::ReadAllText($existing))) -ceq (CanonicalJson $content)) { $content=[IO.File]::ReadAllText($existing) }
        } else {
            $content=((@($rows | ForEach-Object { [pscustomobject]$_ }) | ConvertTo-Csv -NoTypeInformation) -join "`n")+"`n"
            $runtime='unityserver/config/source/'+$s.output; $generated='unitydata/export/server/generated/source/'+$s.output
            $existing=Join-Path $Root $runtime
            if ((Test-Path $existing) -and (Json @([IO.File]::ReadAllText($existing) | ConvertFrom-Csv)) -ceq (Json @($content | ConvertFrom-Csv))) { $content=[IO.File]::ReadAllText($existing) }
        }
        if ($Mode -in @('Server','Both')) {
            Add-Write $generated $content $existing
            if ($ApplyRuntime) { Add-Write $runtime $content $existing }
            if ($s.jsonOutput) {
                $json=(Json @($rows))+"`n"
                $existingJson=Join-Path $Root ('unityserver/config/json/'+$s.jsonOutput)
                if ((Test-Path $existingJson) -and (CanonicalJson ([IO.File]::ReadAllText($existingJson))) -ceq (CanonicalJson $json)) { $json=[IO.File]::ReadAllText($existingJson) }
                Add-Write ('unitydata/export/server/generated/json_server/'+$s.jsonOutput) $json $existingJson
                if ($ApplyRuntime) { Add-Write ('unityserver/config/json/'+$s.jsonOutput) $json $existingJson }
            }
        }
        if ($s.client -and $Mode -in @('Client','Both')) {
            $clientContent=$content
            $clientReference=$existing
            if ($s.clientOnlyColumns) {
                $clientContent=(Json @($clientRows))+"`n"
                $existingClient=Join-Path $Root ('unitydata/export/client/source/Configs/'+$s.output)
                $clientReference=$existingClient
                if ((Test-Path $existingClient) -and (CanonicalJson ([IO.File]::ReadAllText($existingClient))) -ceq (CanonicalJson $clientContent)) { $clientContent=[IO.File]::ReadAllText($existingClient) }
            }
            $existingClient=Join-Path $Root ('unitydata/export/client/source/Configs/'+$s.output)
            if (Test-Path $existingClient) {
                $oldClient=[IO.File]::ReadAllText($existingClient,[Text.Encoding]::UTF8)
                $same = if ($s.kind -eq 'xml') { (Xml-Signature $oldClient) -ceq (Xml-Signature $clientContent) } else { (CanonicalJson $oldClient) -ceq (CanonicalJson $clientContent) }
                if ($same) { $clientContent=$oldClient; $clientReference=$existingClient }
            }
            Add-Write ('unitydata/export/client/source/Configs/'+$s.output) $clientContent $clientReference
            if ($ApplyRuntime) { Add-Write ('unityclient/Assets/Resources/ProjectXData/Configs/'+$s.output) $clientContent $clientReference }
        }
    }
    if ($Mode -in @('Server','Both')) {
        $seeds=@(); if ($g.seed) { $seeds+=,$g.seed }; if ($g.seeds) { $seeds+=@($g.seeds) }
        foreach ($seed in $seeds) {
            $sql=Seed-Sql $g $tables $seed
            Add-Write ('unitydata/export/server/generated/sqlite/'+$seed.name) $sql
            if ($ApplyRuntime) {
                Add-Write ('unityserver/sql/sqlite/seeds/'+$seed.name) $sql
                $pattern='(?s)-- BEGIN '+[regex]::Escape($seed.marker)+'.*?-- END '+[regex]::Escape($seed.marker)
                if ([regex]::Matches($schema,$pattern).Count -ne 1) { throw "Missing/duplicate schema seed marker: $($seed.marker)" }
                $schema=[regex]::Replace($schema,$pattern,[Text.RegularExpressions.MatchEvaluator]{ param($m) $sql.TrimEnd() })
            }
        }
    }
}
if ($ApplyRuntime -and $Mode -in @('Server','Both')) { $writes.Add(@{path=$schemaPath;content=$schema}) }
if ($ValidateOnly) {
    foreach ($path in $deletes) { if (Test-Path -LiteralPath $path) { throw "Retired Unity output still exists: $path" } }
}
foreach ($w in $writes) {
    $bytes=if ($w.bytes) { $w.bytes } else { [Text.UTF8Encoding]::new($false).GetBytes($w.content) }
    if ((Test-Path $w.path) -and [Convert]::ToBase64String([IO.File]::ReadAllBytes($w.path)) -ceq [Convert]::ToBase64String($bytes)) { continue }
    if ($ValidateOnly) { throw "Unity source/output drift: $($w.path)" }
    $null=New-Item -ItemType Directory -Force -Path (Split-Path $w.path -Parent)
    [IO.File]::WriteAllBytes($w.path,$bytes)
}
if (-not $ValidateOnly) { foreach ($path in $deletes) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path } } }
Write-Output ('Unity data groups={0}; mode={1}; outputs={2}; validated={3}' -f ($groups.group -join ','),$Mode,$writes.Count,$ValidateOnly.IsPresent)
