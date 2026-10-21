[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [string]$ServerExecutable = '',
    [string]$EvidenceDirectory = '',
    [string[]]$CaseName = @()
)
$ErrorActionPreference='Stop'
if(-not $EvidenceDirectory){$EvidenceDirectory=Join-Path $Root '.local/hero-affix-integration/export-tests'}
$null=New-Item -ItemType Directory -Force -Path $EvidenceDirectory
$fixture=Join-Path $EvidenceDirectory ('fixture-'+[Guid]::NewGuid().ToString('N'))
foreach($relative in @('unitydata/excel','unityserver/config','unityserver/sql/sqlite')){
    $null=New-Item -ItemType Directory -Force -Path (Join-Path $fixture $relative)
}
$workbook=Join-Path $Root 'unitydata/excel/hero_combat.xlsx'
$copy=Join-Path $fixture 'unitydata/excel/hero_combat.xlsx'
Copy-Item -LiteralPath $workbook -Destination $copy
foreach($name in @('fabao.xlsx','suit.xlsx','equipment_combat.xlsx')){Copy-Item -LiteralPath (Join-Path $Root "unitydata/excel/$name") -Destination (Join-Path $fixture 'unitydata/excel')}
foreach($part in @('json','xml')){
    Copy-Item -LiteralPath (Join-Path $Root "unityserver/config/$part") -Destination (Join-Path $fixture 'unityserver/config') -Recurse
}
Copy-Item -LiteralPath (Join-Path $Root 'unityserver/sql/sqlite/001_initial_schema.sql') -Destination (Join-Path $fixture 'unityserver/sql/sqlite')
$sourceHash=(Get-FileHash -LiteralPath $workbook).Hash
$equipmentHashes=@{};foreach($name in @('fabao.xlsx','suit.xlsx','equipment_combat.xlsx')){$equipmentHashes[$name]=(Get-FileHash -LiteralPath (Join-Path $Root "unitydata/excel/$name")).Hash}
function Get-CombatBinaryHash {
    # Permit an external reader/writer handle without removing the before/after
    # binary-integrity check. Fail if metadata changes during this hash read.
    $before=Get-Item -LiteralPath $ServerExecutable
    $length=$before.Length;$written=$before.LastWriteTimeUtc
    $stream=[IO.File]::Open($ServerExecutable,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    try{$hash=(Get-FileHash -InputStream $stream -Algorithm SHA256).Hash}finally{$stream.Dispose()}
    $after=Get-Item -LiteralPath $ServerExecutable
    if($length -ne $after.Length -or $written -ne $after.LastWriteTimeUtc){throw 'Binary changed while computing its hash'}
    return $hash
}
function Invoke-CombatProbeProcess {
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$ServerExecutable;$info.ArgumentList.Add('--combat-data-probe')
    $info.WorkingDirectory=Join-Path $fixture 'unityserver/config'
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.StandardOutputEncoding=[Text.UTF8Encoding]::new($false)
    $info.StandardErrorEncoding=[Text.UTF8Encoding]::new($false)
    $process=$null
    for($attempt=0;$attempt -lt 20;++$attempt){
        try{$process=[Diagnostics.Process]::Start($info);break}catch{
            $cause=$_.Exception
            while($cause.InnerException){$cause=$cause.InnerException}
            # Retry only a failed CreateProcess, never an executed assertion.
            if($cause -isnot [ComponentModel.Win32Exception] -or $cause.NativeErrorCode -notin @(32,33) -or $attempt -eq 19){throw}
            Start-Sleep -Milliseconds 250
        }
    }
    try{
        $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        if(-not $process.WaitForExit(30000)){$process.Kill();$process.WaitForExit();throw 'Combat probe timed out'}
        return @{code=$process.ExitCode;output=@(($stdout.GetAwaiter().GetResult()+"`n"+$stderr.GetAwaiter().GetResult()) -split '\r?\n');launch_retries=$attempt}
    }finally{$process.Dispose()}
}
$binaryHash=if($ServerExecutable){Get-CombatBinaryHash}else{''}
$exporter=Join-Path $PSScriptRoot 'Export-UnityOwnedTables.ps1'
$results=[Collections.Generic.List[object]]::new()
$selectedNames=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
function Save-CombatTestProgress([string]$ActiveCase='') {
    $finishedSensitivity=if($null -ne $script:sensitivity){@($script:sensitivity.ToArray())}else{@()}
    $progress=@{active_case=$ActiveCase;cases=@($results.ToArray());sensitivity=@($finishedSensitivity);source_sha256=$sourceHash;binary_sha256=$binaryHash;requested_cases=$CaseName;fixture=$fixture}
    $progress|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'progress.json') -Encoding utf8
}
function Test-CaseSelected([string]$Name) {
    if(-not $CaseName.Count){Save-CombatTestProgress $Name;return $true}
    if($Name -notin $CaseName){return $false}
    if(-not $selectedNames.Add($Name)){throw "Duplicate combat test case name: $Name"}
    Save-CombatTestProgress $Name
    return $true
}

# Deliberate corruption/sensitivity fixtures only: mutate a single XLSX cell,
# keeping all other package parts intact. Production tables are never edited.
function Reset-Fixture {
    foreach($name in @('hero_combat.xlsx','fabao.xlsx','suit.xlsx','equipment_combat.xlsx')){Copy-Item -LiteralPath (Join-Path $Root "unitydata/excel/$name") -Destination (Join-Path $fixture 'unitydata/excel') -Force}
}
function Set-FixtureCell([string]$Sheet,[string]$Column,[int]$Row,[string]$Value,[string]$WorkbookFile='hero_combat.xlsx') {
    if($Sheet -in @('equipment_affix','combat_artifact','combat_set')){$WorkbookFile='equipment_combat.xlsx'}
    # Older sensitivity cases use the original A:N affix layout. Resolve its
    # logical field against the current header after user column moves/cleanup.
    if($Sheet -eq 'equipment_affix' -and $Column -cmatch '^[A-N]$') {
        $legacyFields=@('id','key','name','parts','quality_min','passive_skill_id','event','value1','value2','duration','per_turn_limit','per_battle_limit','conflict_group','desc')
        $Column=$legacyFields[[int][char]$Column-65]
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=$null
    for($attempt=0;$attempt -lt 6;$attempt++) {
        try { $zip=[IO.Compression.ZipFile]::Open((Join-Path $fixture "unitydata/excel/$WorkbookFile"),[IO.Compression.ZipArchiveMode]::Update); break }
        catch {
            $cause=$_.Exception
            while($cause.InnerException){$cause=$cause.InnerException}
            if(($cause.HResult -band 0xffff) -notin @(32,33) -or $attempt -eq 5){throw}
            # Windows indexing/AV can briefly hold a just-copied fixture. Retry
            # only the open operation; never rerun a partially executed test.
            Start-Sleep -Milliseconds 200
        }
    }
    try {
        function Read-Part([string]$Name){
            $reader=[IO.StreamReader]::new($zip.GetEntry($Name).Open())
            try{[xml]$reader.ReadToEnd()}finally{$reader.Dispose()}
        }
        $book=Read-Part 'xl/workbook.xml'; $ns=[Xml.XmlNamespaceManager]::new($book.NameTable)
        $ns.AddNamespace('s','http://schemas.openxmlformats.org/spreadsheetml/2006/main')
        $sheetNode=@($book.SelectNodes('//s:sheet',$ns)|Where-Object name -CEQ $Sheet)[0]
        $rid=$sheetNode.GetAttribute('id','http://schemas.openxmlformats.org/officeDocument/2006/relationships')
        $rels=Read-Part 'xl/_rels/workbook.xml.rels'
        $target=[string](@($rels.Relationships.Relationship|Where-Object Id -EQ $rid)[0].Target)
        $name=if($target.StartsWith('/')){$target.TrimStart('/')}else{'xl/'+$target}
        $xml=Read-Part $name; $ns=[Xml.XmlNamespaceManager]::new($xml.NameTable)
        $ns.AddNamespace('s','http://schemas.openxmlformats.org/spreadsheetml/2006/main')
        if($Column -cnotmatch '^[A-Z]{1,3}$') {
            $shared=@()
            if($zip.GetEntry('xl/sharedStrings.xml')) {
                $strings=Read-Part 'xl/sharedStrings.xml';$stringNs=[Xml.XmlNamespaceManager]::new($strings.NameTable)
                $stringNs.AddNamespace('s',$ns.LookupNamespace('s'))
                $shared=@($strings.SelectNodes('/s:sst/s:si',$stringNs)|ForEach-Object {$_.InnerText})
            }
            $headerMatchCount=0;$resolvedColumn=''
            foreach($header in $xml.SelectNodes("//s:row[@r='1']/s:c",$ns)) {
                $kind=$header.GetAttribute('t')
                $headerValue=if($kind -eq 's'){$shared[[int]$header.SelectSingleNode('s:v',$ns).InnerText]}elseif($kind -eq 'inlineStr'){$header.SelectSingleNode('s:is',$ns).InnerText}else{$header.SelectSingleNode('s:v',$ns).InnerText}
                if($headerValue -ceq $Column){$headerMatchCount++;$resolvedColumn=$header.GetAttribute('r') -replace '\d+$',''}
            }
            if($headerMatchCount -ne 1){throw "Missing or ambiguous fixture formal column: $Sheet $Column"}
            $Column=$resolvedColumn
        }
        $cell=$xml.SelectSingleNode("//s:c[@r='$Column$Row']",$ns)
        if(-not $cell){throw "Missing fixture cell: $Sheet $Column$Row"}
        $cell.RemoveAll(); $cell.SetAttribute('r',"$Column$Row");$cell.SetAttribute('t','inlineStr')
        $inline=$xml.CreateElement('is',$ns.LookupNamespace('s'));$text=$xml.CreateElement('t',$ns.LookupNamespace('s'))
        $text.InnerText=$Value;[void]$inline.AppendChild($text);[void]$cell.AppendChild($inline)
        $zip.GetEntry($name).Delete();$writer=[IO.StreamWriter]::new($zip.CreateEntry($name).Open(),[Text.UTF8Encoding]::new($false))
        try{$writer.Write($xml.OuterXml)}finally{$writer.Dispose()}
    }finally{$zip.Dispose()}
}
function Export-Fixture { & $exporter -Root $fixture -Group HeroCombat -Mode Both | Out-Null }
function Probe {
    $run=Invoke-CombatProbeProcess
        $output=$run.output
        if($run.code -ne 0){throw "Combat probe failed: $($output | Select-Object -Last 5)"}
        $line=@($output|Where-Object { [string]$_ -like 'COMBAT_DATA_RESULT *' })
        if($line.Count -ne 1){throw 'Combat probe did not emit exactly one result'}
        ([string]$line[0]).Substring('COMBAT_DATA_RESULT '.Length)|ConvertFrom-Json
}
Export-Fixture
$baseline=if($ServerExecutable){Probe}else{$null}
$affixDescriptions=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/equipment_affix.json') -Raw -Encoding UTF8|ConvertFrom-Json
if(($affixDescriptions|Where-Object id -eq 35).combat_descriptions[2] -notlike '*周期伤害增加16%*共享100%上限*'){throw 'Periodic affix description omitted its shared cap'}
# Column names deliberately checked against formal headers below; do not silently
# test another field after a schema change.
. (Join-Path $PSScriptRoot 'Read-UnityVisualExcel.ps1')
$first=@(Read-UnityVisualExcelRows $copy -SheetName combat_effect)[0]
if($first.id -ne '1001' -or $first.ratio_bp -ne '2000'){throw 'Sensitivity fixture no longer matches formal source'}
$cases=@(
    @{name='missing_effect_group';sheet='combat_binding';column='E';row=5;value='[999999]';error='Missing combat effect group'},
    @{name='unknown_operator';sheet='combat_effect';column='H';row=5;value='invented_operator';error='Invalid combat effect vocabulary'},
    @{name='invalid_probability';sheet='combat_effect';column='P';row=5;value='10001';error='Invalid combat effect range'},
    @{name='unknown_skill';sheet='combat_effect';column='D';row=5;value='65534';error='Unknown combat effect skill/buff'},
    @{name='unknown_fact';sheet='combat_effect';column='T';row=5;value='[{"field":"missing_fact","op":"eq","value":1}]';error='Invalid combat condition'},
    @{name='wrong_event_basis';sheet='combat_effect';column='F';row=5;value='after_hit';error='Invalid combat effect vocabulary'},
    @{name='wrong_event_condition';sheet='combat_effect';column='T';row=5;value='[{"field":"enemy_dots","op":"eq","value":1}]';error='Invalid combat condition'},
    @{name='wrong_strategy_condition';sheet='combat_strategy';column='G';row=5;value='[{"field":"overheal","op":"gt","value":0}]';error='Invalid combat condition'},
    @{name='wrong_modifier_target';sheet='combat_effect';column='G';row=11;value='allies';error='Incompatible combat effect'},
    @{name='invalid_rule_flag';sheet='combat_rule';column='C';row=13;value='2';error='Invalid combat shared rule'},
    @{name='periodic_missing_buff';sheet='combat_periodic';column='B';row=5;value='65534';error='Invalid periodic buff reference'},
    @{name='periodic_missing_fact';sheet='combat_periodic';column='F';row=5;value='input';error='Invalid periodic formula'},
    @{name='periodic_missing_cap';sheet='combat_periodic';column='I';row=5;value='-1';error='Invalid periodic range'},
    @{name='invalid_extra_budget';sheet='combat_effect';column='V';row=5;value='unknown_budget';error='Invalid combat budget'},
    @{name='invalid_control_buff';sheet='combat_control';column='B';row=5;value='65534';error='Invalid control policy'},
    @{name='invalid_boss_replacement';sheet='combat_control';column='E';row=5;value='1';error='Invalid boss control replacement'},
    @{name='invalid_control_order';sheet='combat_rule';column='C';row=19;value='3';error='Control reduction must precede immunity'},
    @{name='unsafe_recursion_depth';sheet='combat_rule';column='C';row=9;value='9';error='Invalid combat shared rule'},
    @{name='unresolved_description';sheet='combat_effect';column='U';row=5;value='{not_a_field}';error='Unresolved combat description'},
    @{name='unfinished_branch';sheet='combat_binding';column='D';row=5;value='1';error='Incomplete branch cannot be enabled'},
    @{name='duplicate_strategy_priority';sheet='combat_strategy';column='C';row=6;value='1';error='Invalid combat strategy'},
    @{name='missing_fallback';sheet='combat_strategy';column='D';row=22;value='tactic';error='requires unconditional normal fallback'}
)
$cases+=@(
    @{name='artifact_missing_group';book='fabao.xlsx';sheet='combat_artifact';column='F';row=7;value='999999';error='Invalid equipment effect/status'},
    @{name='artifact_quality_mismatch';book='fabao.xlsx';sheet='combat_artifact';column='C';row=7;value='7';error='Invalid artifact binding/quality'},
    @{name='artifact_incomplete';book='fabao.xlsx';sheet='combat_artifact';column='I';row=5;value='pending_migration';error='Invalid equipment effect/status'},
    @{name='artifact_unknown_item';book='fabao.xlsx';sheet='combat_artifact';column='A';row=5;value='999999';error='Invalid artifact binding/quality'},
    @{name='set_impossible_threshold';book='suit.xlsx';sheet='combat_set';column='C';row=21;value='5';error='Invalid set binding/threshold'},
    @{name='slot_ambiguous_priority';sheet='combat_loadout_slot';column='C';row=9;value='6';error='Invalid/ambiguous loadout slot policy'},
    @{name='invalid_counter_scope';sheet='combat_effect';column='W';row=14;value='unknown';error='Invalid combat counter scope'}
    @{name='unified_sacrifice_random_query';sheet='combat_effect';column='probability_bp';row=855;value='9999';error='Invalid sacrifice damage query'}
    @{name='unified_revive_query_parameter';sheet='combat_effect';column='argument';row=858;value='2';error='Invalid set parameter operation'}
    @{name='unified_zero_periodic_parameter_range';sheet='combat_periodic';column='zero_action_parameter';row=12;value='4';error='Invalid periodic zero action parameter'}
    @{name='unified_periodic_aggregation_unknown';sheet='combat_periodic';column='aggregation';row=12;value='unknown';error='Invalid periodic aggregation'}
    @{name='unified_sacrifice_multiplier_limit';sheet='combat_effect';column='flat';row=857;value='1000001';error='Invalid combat effect range'}
    @{name='artifact_family_conflict';book='fabao.xlsx';sheet='combat_artifact';column='B';row=7;value='2';error='Duplicate artifact family/quality'},
    @{name='artifact_group_conflict';book='fabao.xlsx';sheet='combat_artifact';column='D';row=63;value='another_exclusive';error='Conflicting equipment effect group'},
    @{name='hero_equipment_alias';sheet='combat_binding';column='E';row=5;value='[20003]';error='Hero binding cannot alias an equipment group'},
    @{name='slot_namespace_mismatch';sheet='combat_loadout_slot';column='B';row=9;value='equipment';error='Loadout kind disagrees with slot protocol'},
    @{name='missing_periodic_affix';sheet='combat_periodic';column='O';row=6;value='9999';error='Invalid periodic affix/cap reference'}
    @{name='shared_heal_budget_conflict';sheet='combat_effect';column='Q';row=28;value='2';error='Incompatible shared counter contract'},
    @{name='unknown_ratio_source';sheet='combat_effect';column='Y';row=25;value='item_id_math';error='Invalid combat coefficient/interval/counter'},
    @{name='negative_trigger_interval';sheet='combat_effect';column='X';row=25;value='-1';error='Invalid combat coefficient/interval/counter'},
    @{name='missing_modifier_parameter';sheet='combat_effect';column='S';row=20;value='99';error='Invalid modifier parameter index'}
    @{name='invalid_suit_attribute';book='suit.xlsx';sheet='Sheet1';column='B';row=5;value='[[[1,999,1200]],[],[]]';error='Invalid suit attribute tuple/protocol'},
    @{name='invalid_suit_piece_tiers';book='suit.xlsx';sheet='Sheet1';column='B';row=5;value='[[[1,25,1200]]]';error='Invalid suit piece tiers'}
)
$cases+=@(
    @{name='speed_query_rng';sheet='combat_effect';column='P';row=32;value='5000';error='Speed query must be a deterministic stat modifier'},
    @{name='speed_query_budget';sheet='combat_effect';column='Q';row=32;value='1';error='Speed query must be a deterministic stat modifier'},
    @{name='inverted_damage_range';sheet='combat_rule';column='C';row=25;value='30000';error='Inverted direct multiplier range'}
    @{name='missing_category_buff';sheet='combat_buff_category';column='B';row=5;value='65534';error='Invalid or conflicting buff category'},
    @{name='duplicate_category_buff';sheet='combat_buff_category';column='B';row=6;value='8';error='Invalid or conflicting buff category'},
    @{name='invalid_category';sheet='combat_buff_category';column='C';row=5;value='0';error='Invalid or conflicting buff category'},
    @{name='unknown_stacking_policy';sheet='combat_effect';column='AB';row=34;value='unknown';error='Invalid buff stacking policy'},
    @{name='conflicting_stacking_contract';sheet='combat_effect';column='AB';row=29;value='highest';error='Conflicting buff stacking contract'},
    @{name='missing_presentation_skill';sheet='combat_effect';column='AC';row=34;value='65534';error='Invalid presentation skill reference'}
    @{name='gear_origin_foreign_group';sheet='combat_effect';column='origin_skill';row=14;value='10004';error='Unknown combat effect skill/buff'}
    @{name='gear_presentation_foreign_group';sheet='combat_effect';column='presentation_skill';row=23;value='11001';error='Invalid presentation skill reference'}
    @{name='gear_origin_not_cast_skill';sheet='combat_effect';column='skill_id';row=14;value='10003';error='Unknown combat effect skill/buff'}
    @{name='unknown_cap_source';sheet='combat_effect';column='AM';row=88;value='item_id_math';error='Invalid combat cap ratio source'}
    @{name='unbound_cap_source';sheet='combat_effect';column='AM';row=5;value='affix_value2';error='Affix fact requires affix binding'}
    @{name='zero_dynamic_cap';sheet='combat_effect';column='N';row=88;value='0';error='Dynamic cap requires positive cap coefficient'}
    @{name='invalid_overheal_cap';sheet='combat_rule';column='C';row=47;value='10001';error='Invalid combat shared rule'}
    @{name='unbound_inherited_duration';sheet='combat_effect';column='O';row=5;value='-1';error='Inherited duration requires a valid affix binding'}
    @{name='zero_inherited_duration';sheet='equipment_affix';column='J';row=12;value='0';error='Invalid inherited affix duration'}
    @{name='excess_inherited_duration';sheet='equipment_affix';column='J';row=12;value='256';error='Invalid affix duration/budget'}
    @{name='hero_gear_selector';sheet='combat_effect';column='G';row=5;value='highest_gear_ally';error='Equipment selector requires equipment group'},
    @{name='zero_rage_budget';sheet='combat_rule';column='C';row=27;value='0';error='Invalid combat shared rule'}
    @{name='unreachable_tactic_cost';sheet='combat_rule';column='C';row=36;value='101';error='Tactic minimum exceeds rage cap'}
    @{name='unique_target_scope';sheet='combat_effect';column='W';row=36;value='target';error='Invalid action budget scope/range'},
    @{name='negative_action_budget';sheet='combat_effect';column='AD';row=36;value='-1';error='Invalid action budget scope/range'},
    @{name='action_shared_contract';sheet='combat_effect';column='AE';row=36;value='4';error='Incompatible shared counter contract'},
    @{name='invalid_pierce_value';sheet='combat_rule';column='C';row=37;value='10001';error='Invalid combat shared rule'}
)
$cases+=@(
    @{name='unknown_affix_binding';sheet='combat_effect';column='AF';row=43;value='999';error='Invalid effect affix binding'},
    @{name='unknown_affix_scope';sheet='combat_effect';column='AG';row=43;value='all_enemies';error='Invalid effect affix binding'},
    @{name='unbound_affix_fact';sheet='combat_effect';column='AF';row=43;value='0';error='Affix fact requires affix binding'},
    @{name='conflicting_affix_group';sheet='combat_effect';column='AF';row=28;value='12';error='Conflicting effect group affix binding'},
    @{name='unknown_dynamic_buff_fact';sheet='combat_effect';column='T';row=45;value='[{"field":"target_buff_65534","op":"eq","value":1}]';error='Invalid combat condition'},
    @{name='unknown_comparison_fact';sheet='combat_effect';column='T';row=44;value='[{"field":"rage","op":"ge","value":0,"value_field":"not_a_fact"}]';error='Invalid combat comparison field'},
    @{name='guard_query_rng';sheet='combat_effect';column='P';row=39;value='5000';error='Stat query must be a deterministic modifier'},
    @{name='defense_coefficient';sheet='combat_effect';column='J';row=42;value='10001';error='Invalid remaining fraction coefficient'}
    @{name='defense_curve_range';book='suit.xlsx';sheet='combat_set';column='E';row=16;value='10001';error='Remaining fraction outside 0..10000'},
    @{name='defense_affix_range';sheet='equipment_affix';column='H';row=31;value='[800,1200,10001]';error='Remaining fraction outside 0..10000'}
    @{name='hit_role_wrong_event';sheet='combat_effect';column='F';row=46;value='after_hit';error='Invalid combat condition'},
    @{name='hit_action_contract';sheet='combat_effect';column='AD';row=46;value='2';error='Incompatible shared counter contract'}
    @{name='opening_leader_without_gear';sheet='combat_effect';column='F';row=5;value='battle_begin';changes=@(@{column='I';row=5;value='source_max_hp'},@{column='T';row=5;value='[{"field":"source_is_group_hp_leader","op":"eq","value":1}]'});error='Equipment leader fact requires equipment group'},
    @{name='opening_leader_wrong_event';sheet='combat_effect';column='F';row=48;value='action_start';error='Invalid combat condition'}
    @{name='unknown_growth_fact';sheet='combat_effect';column='AI';row=50;value='unknown_growth';error='Unavailable growth basis'},
    @{name='unknown_gate_reference';sheet='combat_effect';column='AI';row=53;value='gate_count_999999';error='Invalid or cyclic event gate reference'},
    @{name='cyclic_gate_reference';sheet='combat_effect';column='T';row=49;value='[{"field":"gate_30340","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'},
    @{name='cross_group_gate';sheet='combat_effect';column='T';row=50;value='[{"field":"gate_30440","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'},
    @{name='consumer_before_gate';sheet='combat_effect';column='C';row=51;value='5';error='Invalid or cyclic event gate reference'},
    @{name='probabilistic_gate';sheet='combat_effect';column='P';row=49;value='3500';error='Invalid event gate'},
    @{name='target_scope_gate';sheet='combat_effect';column='W';row=49;value='target';error='Invalid event gate'},
    @{name='unknown_argument_role';sheet='combat_effect';column='AJ';row=51;value='ultimate';error='Invalid skill role argument'},
    @{name='ambiguous_argument_role';sheet='combat_effect';column='S';row=51;value='102';error='Invalid skill role argument'},
    @{name='unknown_effective_immunity';sheet='combat_effect';column='T';row=55;value='[{"field":"target_blocks_buff_65534","op":"eq","value":0}]';error='Invalid combat condition'}
    @{name='attack_query_rng';sheet='combat_effect';column='P';row=56;value='5000';error='Attack query must be a deterministic stat modifier'},
    @{name='attack_query_budget';sheet='combat_effect';column='Q';row=58;value='1';error='Attack query must be a deterministic stat modifier'},
    @{name='attack_query_slot';sheet='combat_effect';column='S';row=56;value='3';error='Attack query must be a deterministic stat modifier'},
    @{name='attack_fact_wrong_event';sheet='combat_effect';column='F';row=59;value='before_direct_damage';error='Invalid combat condition'}
    @{name='inverted_hit_range';sheet='combat_rule';column='C';row=42;value='500';error='Inverted direct hit range'},
    @{name='negative_hit_min';sheet='combat_rule';column='C';row=41;value='-1';error='Invalid combat shared rule'},
    @{name='oversized_hit_max';sheet='combat_rule';column='C';row=42;value='10001';error='Invalid combat shared rule'},
    @{name='hit_scope';sheet='combat_rule';column='D';row=41;value='heroes_only';error='Invalid combat shared rule'}
    @{name='unknown_basis_cap';sheet='combat_effect';column='AK';row=60;value='unknown_cap';error='Unavailable basis cap'},
    @{name='unknown_category_reference';sheet='combat_effect';column='T';row=62;value='[{"field":"target_category_65534","op":"eq","value":1}]';error='Invalid combat condition'},
    @{name='unbound_dynamic_coefficient';sheet='combat_effect';column='AF';row=60;value='0';changes=@(@{column='AK';row=60;value='none'});error='Affix fact requires affix binding'},
    @{name='invalid_ratio_fact';sheet='combat_effect';column='Y';row=60;value='source_hp';error='Invalid combat coefficient'},
    @{name='zero_coefficient_divisor';sheet='combat_effect';column='AL';row=60;value='0';error='Invalid coefficient divisor'},
    @{name='constant_dynamic_divisor';sheet='combat_effect';column='AL';row=56;value='2';error='Constant coefficient cannot use a dynamic divisor'},
    @{name='cyclic_basis_cap';sheet='combat_effect';column='AK';row=49;value='gate_30340';error='Invalid or cyclic event gate reference'}
    @{name='healing_lower_range';sheet='combat_rule';column='C';row=43;value='-10001';error='Invalid combat shared rule'},
    @{name='healing_inverted_range';sheet='combat_rule';column='C';row=43;value='5000';changes=@(@{column='C';row=44;value='4000'});error='Inverted active healing range'},
    @{name='antiheal_flag';sheet='combat_rule';column='C';row=45;value='2';error='Invalid combat shared rule'},
    @{name='periodic_heal_wrong_event';sheet='combat_effect';column='F';row=68;value='before_guard';error='Invalid combat condition'},
    @{name='antiheal_scope';sheet='combat_rule';column='D';row=45;value='heroes_only';error='Invalid combat shared rule'},
    @{name='event_policy_unknown';sheet='combat_event_policy';column='B';row=5;value='missing_event';error='Invalid combat event policy'},
    @{name='event_policy_duplicate';sheet='combat_event_policy';column='B';row=6;value='kill';error='Conflicting event policy'},
    @{name='event_policy_negative';sheet='combat_event_policy';column='C';row=5;value='-1';error='Invalid combat event policy'},
    @{name='event_policy_excess';sheet='combat_event_policy';column='C';row=5;value='8';error='Invalid combat event policy'},
    @{name='multiplier_wrong_event';sheet='combat_effect';column='F';row=69;value='after_hit';error='Invalid sequential multiplier'},
    @{name='multiplier_wrong_target';sheet='combat_effect';column='G';row=69;value='self';error='Invalid sequential multiplier'},
    @{name='order_query_rng';sheet='combat_effect';column='P';row=70;value='5000';error='Order query must be a deterministic modifier'},
    @{name='order_query_budget';sheet='combat_effect';column='Q';row=70;value='1';error='Order query must be a deterministic modifier'},
    @{name='cost_query_rng';sheet='combat_effect';column='P';row=72;value='5000';error='Cost query must be a deterministic modifier'},
    @{name='cost_query_budget';sheet='combat_effect';column='Q';row=72;value='1';error='Cost query must be a deterministic modifier'},
    @{name='inherited_budget_unbound';sheet='combat_effect';column='AF';row=73;value='0';error='Inherited budget requires a valid affix binding'},
    @{name='inherited_budget_negative';sheet='equipment_affix';column='K';row=8;value='-1';error='Invalid affix duration/budget'},
    @{name='inherited_budget_excess';sheet='equipment_affix';column='K';row=28;value='65536';error='Invalid affix duration/budget'},
    @{name='invalid_budget_sentinel';sheet='combat_effect';column='Q';row=74;value='-2';error='Invalid combat effect range'},
    @{name='final_heal_query_rng';sheet='combat_effect';column='P';row=78;value='5000';error='Healing/usefulness query must be deterministic'},
    @{name='usefulness_query_budget';sheet='combat_effect';column='Q';row=85;value='1';error='Healing/usefulness query must be deterministic'},
    @{name='query_flag_non_boolean';sheet='combat_effect';column='L';row=80;value='2';error='Query flag must be a constant boolean'},
    @{name='passive_revive_wrong_operator';sheet='combat_effect';column='H';row=84;value='heal';error='Healing/usefulness query must be deterministic'},
    @{name='final_heal_wrong_target';sheet='combat_effect';column='G';row=78;value='self';error='Incompatible combat effect'}
)
$cases+=@(
    @{name='overkill_invalid_target';sheet='combat_effect';column='G';row=93;value='lowest_enemy_ratio_unregistered';error='Invalid combat effect vocabulary'},
    @{name='overkill_unavailable_fact';sheet='combat_effect';column='F';row=93;value='after_hit';error='Invalid or cyclic event gate reference'},
    @{name='overkill_invalid_gate';sheet='combat_effect';column='T';row=93;value='[{"field":"gate_40191","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='shield_loss_cross_gate';sheet='combat_effect';column='T';row=97;value='[{"field":"gate_40010","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='shield_loss_missing_affix';sheet='combat_effect';column='AF';row=94;value='0';error='Inherited budget requires a valid affix binding'}
    @{name='shield_loss_invalid_alive';sheet='combat_effect';column='AH';row=96;value='2';error='Invalid effect affix binding'}
    @{name='share_unknown_duration_source';sheet='combat_effect';column='AN';row=99;value='copied_from_id_2';error='Invalid dynamic duration source'}
    @{name='share_wrong_duration_event';sheet='combat_effect';column='AN';row=5;value='event_duration';error='Invalid dynamic duration source'}
    @{name='share_gate_dynamic_duration';sheet='combat_effect';column='AN';row=98;value='event_duration';error='Invalid dynamic duration source'}
    @{name='share_mixed_duration';sheet='combat_effect';column='O';row=99;value='3';error='Invalid dynamic duration source'}
    @{name='share_missing_duration';sheet='combat_effect';column='AN';row=99;value='constant';error='Incompatible combat effect'}
    @{name='guard_share_query_rng';sheet='combat_effect';column='P';row=103;value='5000';error='Share query must be a deterministic stat modifier'}
    @{name='guard_query_budget';sheet='combat_effect';column='Q';row=103;value='1';error='Share query must be a deterministic stat modifier'}
    @{name='guard_query_target';sheet='combat_effect';column='G';row=103;value='self';error='Invalid sequential multiplier'}
    @{name='guard_query_operator';sheet='combat_effect';column='H';row=103;value='damage';error='Share query must be a deterministic stat modifier'}
    @{name='guard_attacker_wrong_context';sheet='combat_effect';column='F';row=100;value='after_regular';error='Invalid combat condition'}
    @{name='guard_budget_link';sheet='combat_effect';column='T';row=101;value='[{"field":"gate_999999","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='guard_damage_cycle';sheet='combat_effect';column='T';row=102;value='[{"field":"gate_40092","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='break_invalid_emit_flag';sheet='combat_effect';column='AO';row=104;value='2';error='Silent effect requires buff or shield operation'}
    @{name='break_silent_gate';sheet='combat_effect';column='AO';row=105;value='0';error='Silent effect requires buff or shield operation'}
    @{name='break_silent_rage';sheet='combat_effect';column='AO';row=106;value='0';error='Silent effect requires buff or shield operation'}
    @{name='break_shared_contract';sheet='combat_effect';column='Q';row=107;value='2';error='Incompatible shared counter contract'}
    @{name='break_invalid_gate';sheet='combat_effect';column='T';row=108;value='[{"field":"gate_40260","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='break_policy_depth';sheet='combat_event_policy';column='C';row=10;value='8';error='Invalid combat event policy'}
    @{name='break_invalid_immunity_flag';sheet='combat_effect';column='AP';row=104;value='2';error='Invalid skill immunity policy'}
    @{name='break_immunity_gate';sheet='combat_effect';column='AP';row=105;value='0';error='Invalid skill immunity policy'}
    @{name='break_zero_duration';sheet='equipment_affix';column='J';row=30;value='0';error='Invalid inherited affix duration'}
    @{name='cleanse_affix_immunity_flag';sheet='combat_effect';column='AP';row=115;value='2';error='Invalid skill immunity policy'}
    @{name='cleanse_affix_silent_flag';sheet='combat_effect';column='AO';row=115;value='2';error='Silent effect requires buff or shield operation'}
    @{name='cleanse_affix_invalid_duration';sheet='equipment_affix';column='J';row=11;value='0';error='Invalid inherited affix duration'}
    @{name='strip_affix_gate_duration';sheet='combat_effect';column='O';row=116;value='1';error='Invalid event gate'}
    @{name='strip_affix_invalid_gate';sheet='combat_effect';column='T';row=117;value='[{"field":"gate_40070","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='strip_affix_missing_binding';sheet='combat_effect';column='AF';row=116;value='0';error='Inherited budget requires a valid affix binding'}
    @{name='strip_affix_invalid_duration';sheet='equipment_affix';column='J';row=44;value='0';error='Invalid inherited affix duration'}
    @{name='amount_budget_unknown_mode';sheet='combat_effect';column='amount_budget';row=119;value='affix_id_10';error='Invalid amount budget contract'}
    @{name='amount_budget_uppercase_mode';sheet='combat_effect';column='amount_budget';row=119;value='SOURCE_TURN';error='Invalid amount budget contract'}
    @{name='amount_budget_wrong_operator';sheet='combat_effect';column='amount_budget';row=115;value='source_turn';error='Invalid amount budget contract'}
    @{name='amount_budget_zero_cap';sheet='combat_effect';column='cap_bp';row=119;value='0';error='Invalid amount budget contract'}
    @{name='amount_budget_target_scope';sheet='combat_effect';column='counter_scope';row=119;value='target';error='Invalid amount budget contract'}
    @{name='amount_budget_team_scope';sheet='combat_effect';column='counter_scope';row=119;value='team';error='Invalid amount budget contract'}
    @{name='amount_budget_shared_contract';sheet='combat_effect';column='counter_key';row=119;value='40031';error='Incompatible shared amount budget contract'}
    @{name='chance_unknown_source';sheet='combat_effect';column='probability_source';row=123;value='hero_id';error='Invalid probability source'}
    @{name='chance_uppercase_source';sheet='combat_effect';column='probability_source';row=123;value='AFFIX_VALUE1';error='Invalid probability source'}
    @{name='chance_wrong_operator';sheet='combat_effect';column='probability_source';row=124;value='affix_value1';error='Invalid dynamic probability contract'}
    @{name='chance_missing_binding';sheet='combat_effect';column='affix_id';row=123;value='0';error='Invalid dynamic probability contract'}
    @{name='chance_curve_above_limit';sheet='equipment_affix';column='H';row=19;value='[2500,4000,10001]';error='Invalid dynamic probability range'}
    @{name='chance_curve_negative';sheet='equipment_affix';column='H';row=19;value='[2500,4000,-1]';error='Invalid affix three-tier curve'}
    @{name='chance_target_scope';sheet='combat_effect';column='counter_scope';row=123;value='target';error='Invalid chance gate'}
    @{name='chance_multiple_targets';sheet='combat_effect';column='target';row=123;value='allies';error='Invalid chance gate'}
    @{name='chance_nonzero_payload';sheet='combat_effect';column='flat';row=123;value='1';error='Invalid chance gate'}
    @{name='chance_extra_budget';sheet='combat_effect';column='budget';row=123;value='extra_attack';error='Invalid chance gate'}
    @{name='chance_cycle';sheet='combat_effect';column='conditions';row=123;value='[{"field":"gate_40151","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='death_guard_gate';sheet='combat_effect';column='conditions';row=132;value='[{"field":"gate_40420","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='death_guard_duration';sheet='equipment_affix';column='J';row=45;value='0';error='Invalid inherited affix duration'}
    @{name='death_count_target_scope';sheet='combat_effect';column='counter_scope';row=133;value='target';error='Effect count requires source scope'}
    @{name='death_count_team_scope';sheet='combat_effect';column='counter_scope';row=133;value='team';error='Effect count requires source scope'}
    @{name='death_count_unavailable';sheet='combat_effect';column='basis';row=5;value='effect_battle_count';error='Invalid combat effect vocabulary'}
    @{name='death_observer_wrong_fact';sheet='combat_effect';column='conditions';row=133;value='[{"field":"victim_level","op":"eq","value":0}]';error='Invalid combat condition'}
    @{name='removed_affix_parameter_context';sheet='combat_effect';column='basis';row=5;value='buff_param0';error='Invalid combat effect vocabulary'}
    @{name='removed_affix_turn_context';sheet='combat_effect';column='growth_basis';row=5;value='remaining_turns';error='Unavailable growth basis'}
    @{name='removed_affix_argument';sheet='combat_effect';column='op';row=134;value='buff';error='Unknown combat effect skill/buff'}
    @{name='removed_affix_silent_damage';sheet='combat_effect';column='emit_action';row=134;value='0';error='Silent effect requires buff or shield operation'}
    @{name='antiheal_affix_gate';sheet='combat_effect';column='conditions';row=136;value='[{"field":"gate_40340","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='antiheal_affix_missing_binding';sheet='combat_effect';column='affix_id';row=135;value='0';error='Inherited budget requires a valid affix binding'}
    @{name='summon_affix_unknown_scope';sheet='combat_effect';column='affix_scope';row=138;value='highest_random';error='Invalid effect affix binding'}
    @{name='summon_affix_uppercase_scope';sheet='combat_effect';column='affix_scope';row=138;value='TEAM_HIGHEST_VALUE2';error='Invalid effect affix binding'}
    @{name='summon_affix_query_probability';sheet='combat_effect';column='probability_bp';row=137;value='5000';error='Summon query must be a deterministic modifier'}
    @{name='summon_affix_query_turn_limit';sheet='combat_effect';column='per_turn';row=137;value='1';error='Summon query must be a deterministic modifier'}
    @{name='summon_affix_query_budget';sheet='combat_effect';column='budget';row=137;value='extra_attack';error='Summon query must be a deterministic modifier'}
    @{name='summon_affix_query_target';sheet='combat_effect';column='target';row=137;value='self';error='Invalid combat bonus modifier'}
    @{name='summon_affix_missing_binding';sheet='combat_effect';column='affix_id';row=137;value='0';error='Affix fact requires affix binding'}
    @{name='duration_chance_flat_overflow';sheet='combat_effect';column='flat';row=140;value='256';error='Invalid duration addition'}
    @{name='duration_chance_addition_target';sheet='combat_effect';column='target';row=140;value='self';error='Invalid duration addition'}
    @{name='duration_chance_addition_probability';sheet='combat_effect';column='probability_bp';row=140;value='5000';error='Invalid duration addition'}
    @{name='duration_chance_addition_budget';sheet='combat_effect';column='per_turn';row=140;value='1';error='Invalid duration addition'}
    @{name='duration_chance_context_operator';sheet='combat_effect';column='op';row=140;value='rage';error='Accepted control requires gates or duration addition'}
    @{name='duration_chance_hard_fact_context';sheet='combat_effect';column='basis';row=5;value='hard_control';error='Invalid combat effect vocabulary'}
    @{name='duration_chance_target_multiple';sheet='combat_effect';column='target';row=141;value='enemies';error='Invalid chance gate'}
    @{name='duration_chance_target_source_scope';sheet='combat_effect';column='counter_scope';row=141;value='source';error='Invalid chance gate'}
    @{name='duration_chance_unknown_buff';sheet='combat_effect';column='argument';row=142;value='65534';error='Unknown combat effect skill/buff'}
    @{name='duration_chance_missing_buff';sheet='combat_effect';column='argument';row=142;value='0';error='Unknown combat effect skill/buff'}
    @{name='duration_chance_curve_above_limit';sheet='equipment_affix';column='H';row=34;value='[20000,20000,20000]';error='Invalid dynamic probability range'}
    @{name='duration_chance_cyclic_gate';sheet='combat_effect';column='conditions';row=140;value='[{"field":"gate_40301","op":"eq","value":1}]';error='Invalid or cyclic event gate reference'}
    @{name='duration_chance_unknown_status';sheet='combat_effect';column='conditions';row=141;value='[{"field":"target_buff_65534","op":"eq","value":1}]';error='Invalid combat condition'}
    @{name='payload_zero_buff_count';sheet='combat_effect';column='parameter_count';row=143;value='0';error='Invalid buff parameter count'}
    @{name='payload_count_overflow';sheet='combat_effect';column='parameter_count';row=143;value='5';error='Invalid buff parameter count'}
    @{name='payload_fractional_count';sheet='combat_effect';column='parameter_count';row=143;value='1.5';error='Invalid buff parameter count'}
    @{name='payload_nonbuff_count';sheet='combat_effect';column='parameter_count';row=5;value='2';error='Invalid buff parameter count'}
    @{name='payload_copy_fixed_count';sheet='combat_effect';column='parameter_count';row=146;value='1';error='Invalid buff parameter count'}
    @{name='payload_negative_origin';sheet='combat_effect';column='origin_level';row=143;value='-1';error='Invalid buff origin level'}
    @{name='payload_nonbuff_origin';sheet='combat_effect';column='origin_level';row=7;value='1';error='Invalid buff origin level'}
    @{name='payload_copy_fixed_duration';sheet='combat_effect';column='duration_source';row=146;value='constant';error='Invalid buff copy contract'}
    @{name='payload_copy_fixed_argument';sheet='combat_effect';column='argument';row=146;value='9';error='Invalid buff copy contract'}
    @{name='payload_copy_amount';sheet='combat_effect';column='flat';row=146;value='1';error='Invalid buff copy contract'}
    @{name='payload_selector_context';sheet='combat_effect';column='target';row=5;value='first_unstacked_enemy';error='Stack selector requires after_buff'}
    @{name='payload_damage_fact_context';sheet='combat_effect';column='basis';row=5;value='received_damage_bp';error='Invalid combat effect vocabulary'}
    @{name='payload_stack_fact_context';sheet='combat_effect';column='conditions';row=5;value='[{"field":"event_stack_count","op":"gt","value":0}]';error='Invalid combat condition'}
    @{name='payload_missing_spread_binding';sheet='combat_effect';column='affix_id';row=144;value='0';error='Inherited budget requires a valid affix binding'}
    @{name='state_affix_unknown_counter';sheet='combat_effect';column='growth_basis';row=149;value='counter_count_999999';error='Invalid persistent counter reference'}
    @{name='state_affix_non_gate_counter';sheet='combat_effect';column='growth_basis';row=149;value='counter_count_40182';error='Invalid persistent counter reference'}
    @{name='state_affix_counter_wrong_scope';sheet='combat_effect';column='counter_scope';row=147;value='team';error='Effect count requires source scope'}
    @{name='state_affix_counter_uppercase';sheet='combat_effect';column='growth_basis';row=149;value='COUNTER_COUNT_40180';error='Unavailable growth basis'}
    @{name='state_affix_reset_zero';sheet='combat_effect';column='argument';row=148;value='0';error='Invalid state reset operation'}
    @{name='state_affix_reset_probability';sheet='combat_effect';column='probability_bp';row=148;value='5000';error='Invalid state reset operation'}
    @{name='state_affix_reset_dynamic_probability';sheet='combat_effect';column='probability_source';row=148;value='affix_value1';error='Invalid dynamic probability contract'}
    @{name='state_affix_reset_target';sheet='combat_effect';column='target';row=148;value='target';error='Invalid state reset operation'}
    @{name='state_affix_reset_limit';sheet='combat_effect';column='per_turn';row=148;value='1';error='Invalid state reset operation'}
    @{name='state_affix_reset_refund_attempt';sheet='combat_effect';column='argument';row=155;value='40230';error='State reset requires unlimited source gate'}
    @{name='state_affix_reset_record_bounded';sheet='combat_effect';column='per_battle';row=152;value='1';error='State reset requires unlimited source gate'}
    @{name='state_affix_critical_context';sheet='combat_effect';column='conditions';row=149;value='[{"field":"critical","op":"eq","value":0}]';error='Invalid combat condition'}
    @{name='state_affix_reset_uppercase';sheet='combat_effect';column='op';row=148;value='RESET_COUNTER';error='Invalid combat effect vocabulary'}
    @{name='nuwa_origin_below_sentinel';sheet='combat_effect';column='origin_skill';row=6;value='-2';error='Invalid buff origin skill'}
    @{name='nuwa_origin_overflow';sheet='combat_effect';column='origin_skill';row=6;value='65536';error='Invalid buff origin skill'}
    @{name='nuwa_origin_fraction';sheet='combat_effect';column='origin_skill';row=6;value='1.5';error='Invalid buff origin skill'}
    @{name='nuwa_origin_unknown_skill';sheet='combat_effect';column='origin_skill';row=6;value='65534';error='Unknown combat effect skill/buff'}
    @{name='nuwa_origin_nonbuff';sheet='combat_effect';column='origin_skill';row=7;value='0';error='Invalid buff origin skill'}
    @{name='nuwa_origin_shield_level_overflow';sheet='combat_effect';column='origin_level';row=5;value='65536';error='Invalid buff origin level'}
    @{name='revive_record_target_unknown';sheet='combat_effect';column='conditions';row=157;value='[{"field":"target_counter_count_999999","op":"ge","value":1}]';error='Invalid persistent counter reference'}
    @{name='revive_record_wrong_scope';sheet='combat_effect';column='conditions';row=157;value='[{"field":"counter_count_1017","op":"ge","value":1}]';error='Invalid persistent counter reference'}
    @{name='revive_record_non_gate';sheet='combat_effect';column='conditions';row=157;value='[{"field":"target_counter_count_1018","op":"ge","value":1}]';error='Invalid persistent counter reference'}
    @{name='revive_record_reset_target';sheet='combat_effect';column='argument';row=148;value='1017';error='Invalid persistent counter reference'}
    @{name='revive_record_self_target';sheet='combat_effect';column='target';row=156;value='self';error='Invalid event gate'}
    @{name='revive_record_random_gate';sheet='combat_effect';column='probability_bp';row=156;value='5000';error='Invalid event gate'}
    @{name='revive_record_query_probability';sheet='combat_effect';column='probability_bp';row=157;value='5000';error='Healing/usefulness query must be deterministic'}
    @{name='revive_record_query_budget';sheet='combat_effect';column='per_turn';row=157;value='1';error='Healing/usefulness query must be deterministic'}
    @{name='revive_record_query_flag';sheet='combat_effect';column='flat';row=157;value='2';error='Query flag must be a constant boolean'}
    @{name='revive_record_query_index';sheet='combat_effect';column='argument';row=157;value='1';error='Invalid set parameter operation'}
    @{name='revive_record_strategy_context';sheet='combat_strategy';column='conditions';row=5;value='[{"field":"target_counter_count_1017","op":"ge","value":1}]';error='Invalid combat condition'}
    @{name='target_policy_unknown_order';sheet='combat_target_policy';column='order';row=5;value='lowest_mana';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_uppercase_order';sheet='combat_target_policy';column='order';row=5;value='LOWEST_HP';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_unknown_side';sheet='combat_target_policy';column='side';row=5;value='both';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_unknown_role';sheet='combat_target_policy';column='role';row=5;value='instant';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_unknown_tie';sheet='combat_target_policy';column='tie_break';row=5;value='random';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_invalid_enabled';sheet='combat_target_policy';column='enabled';row=5;value='2';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_strategy_range';sheet='combat_target_policy';column='strategy_id';row=5;value='6';error='Invalid target policy vocabulary/range'}
    @{name='target_policy_priority_conflict';sheet='combat_target_policy';column='strategy_id';row=6;value='1';error='Conflicting target policy priority'}
    @{name='target_policy_empty_count';sheet='combat_target_policy';column='count_buff_ids';row=9;value='[]';error='Invalid target count buff contract'}
    @{name='target_policy_unneeded_count';sheet='combat_target_policy';column='count_buff_ids';row=5;value='[8]';error='Invalid target count buff contract'}
    @{name='target_policy_duplicate_buff';sheet='combat_target_policy';column='count_buff_ids';row=9;value='[8,8]';error='Invalid target count buff'}
    @{name='target_policy_unknown_buff';sheet='combat_target_policy';column='count_buff_ids';row=9;value='[65534]';error='Invalid target count buff'}
    @{name='shield_core_tick_flag_range';sheet='combat_rule';column='C';row=48;value='2';error='Invalid combat shared rule'}
    @{name='shield_core_tick_flag_negative';sheet='combat_rule';column='C';row=48;value='-1';error='Invalid combat shared rule'}
    @{name='shield_core_tick_scope';sheet='combat_rule';column='D';row=48;value='allies';error='Invalid combat shared rule'}
    @{name='shield_core_query_probability';sheet='combat_effect';column='probability_bp';row=158;value='5000';error='Healing/usefulness query must be deterministic'}
    @{name='shield_core_query_budget';sheet='combat_effect';column='per_turn';row=158;value='1';error='Healing/usefulness query must be deterministic'}
    @{name='shield_core_query_flag';sheet='combat_effect';column='flat';row=158;value='2';error='Query flag must be a constant boolean'}
    @{name='shield_core_query_index';sheet='combat_effect';column='argument';row=158;value='1';error='Invalid set parameter operation'}
    @{name='shield_core_event_skill_context';sheet='combat_strategy';column='conditions';row=5;value='[{"field":"event_skill","op":"eq","value":124}]';error='Invalid combat condition'}
    @{name='shield_core_event_skill_typo';sheet='combat_effect';column='conditions';row=9;value='[{"field":"event_skills","op":"ne","value":124}]';error='Invalid combat condition'}
    @{name='pursuit_full_gate_random';sheet='combat_effect';column='probability_bp';row=175;value='5000';error='Invalid event gate'}
    @{name='hero61b_bonus_index';sheet='combat_effect';column='argument';row=208;value='4';error='Invalid modifier parameter index'}
    @{name='hero61b_bonus_probability';sheet='combat_effect';column='probability_bp';row=208;value='5000';error='Passive query must be a deterministic modifier'}
    @{name='hero61b_bonus_budget';sheet='combat_effect';column='per_turn';row=208;value='1';error='Passive query must be a deterministic modifier'}
    @{name='hero61b_bonus_event';sheet='combat_effect';column='event';row=208;value='after_passive_attribute_roll';error='Invalid combat bonus modifier'}
    @{name='hero61b_cap_index';sheet='combat_effect';column='argument';row=209;value='4';error='Invalid set parameter operation'}
    @{name='hero61b_gate_probability';sheet='combat_effect';column='probability_bp';row=210;value='5000';error='Invalid event gate'}
    @{name='hero61b_counter_not_gate';sheet='combat_effect';column='conditions';row=212;value='[{"field":"counter_count_6134","op":"ge","value":1}]';error='Invalid persistent counter reference'}
    @{name='hero61b_policy_depth';sheet='combat_event_policy';column='extra_depth';row=27;value='8';error='Invalid combat event policy'}
    @{name='hero65b_buff_index';sheet='combat_effect';column='argument';row=205;value='4';error='Invalid set parameter operation'}
    @{name='hero65b_unknown_skill';sheet='combat_effect';column='skill_id';row=205;value='65534';error='Unknown combat effect skill/buff'}
    @{name='hero65b_query_index';sheet='combat_effect';column='argument';row=207;value='4';error='Invalid parameter addition'}
    @{name='hero65b_query_event';sheet='combat_effect';column='event';row=207;value='after_passive_attribute_roll';error='Invalid parameter addition'}
    @{name='hero65b_query_probability';sheet='combat_effect';column='probability_bp';row=207;value='5000';error='Passive query must be a deterministic modifier'}
    @{name='hero65b_query_budget';sheet='combat_effect';column='per_turn';row=207;value='1';error='Passive query must be a deterministic modifier'}
    @{name='hero65b_incomplete_binding';sheet='combat_binding';column='enabled';row=13;value='1';error='Incomplete branch cannot be enabled'}
    @{name='hero65a_query_index';sheet='combat_effect';column='argument';row=204;value='4';error='Invalid parameter addition'}
    @{name='hero65a_query_target';sheet='combat_effect';column='target';row=204;value='self';error='Invalid parameter addition'}
    @{name='hero65a_query_basis';sheet='combat_effect';column='basis';row=204;value='source_max_hp';error='Invalid parameter addition'}
    @{name='hero65a_query_event';sheet='combat_effect';column='event';row=204;value='after_passive_attribute_roll';error='Invalid parameter addition'}
    @{name='hero65a_query_probability';sheet='combat_effect';column='probability_bp';row=204;value='5000';error='Passive query must be a deterministic modifier'}
    @{name='hero65a_query_budget';sheet='combat_effect';column='per_turn';row=204;value='1';error='Passive query must be a deterministic modifier'}
    @{name='hero65a_negative_shield';sheet='combat_effect';column='event';row=204;value='before_shield';error='Invalid parameter addition'}
    @{name='hero61a_unknown_event';sheet='combat_effect';column='event';row=203;value='after_skills_damage';error='Invalid combat effect vocabulary'}
    @{name='hero61a_unknown_skill';sheet='combat_effect';column='skill_id';row=203;value='65534';error='Unknown combat effect skill/buff'}
    @{name='hero61a_unknown_buff';sheet='combat_effect';column='argument';row=203;value='65534';error='Unknown combat effect skill/buff'}
    @{name='hero61a_unknown_origin';sheet='combat_effect';column='origin_skill';row=203;value='65534';error='Unknown combat effect skill/buff'}
    @{name='hero61a_policy_depth';sheet='combat_event_policy';column='extra_depth';row=26;value='8';error='Invalid combat event policy'}
    @{name='hero61a_policy_event';sheet='combat_event_policy';column='event';row=26;value='after_skills_damage';error='Invalid combat event policy'}
    @{name='hero15a_unknown_skill_fact';sheet='combat_effect';column='conditions';row=193;value='[{"field":"source_skill_level_65534","op":"gt","value":0}]';error='Invalid combat condition'}
    @{name='hero15a_unknown_buff_value';sheet='combat_effect';column='conditions';row=189;value='[{"field":"target_buff_value_65534","op":"lt","value":800}]';error='Invalid combat condition'}
    @{name='hero15a_bad_skill_fact';sheet='combat_effect';column='conditions';row=193;value='[{"field":"source_skill_level_0153","op":"gt","value":0}]';error='Invalid combat condition'}
    @{name='hero15a_counter_not_gate';sheet='combat_effect';column='conditions';row=196;value='[{"field":"counter_age_1536","op":"eq","value":0}]';error='Invalid persistent counter reference'}
    @{name='hero15a_repeat_negative';sheet='combat_effect';column='flat';row=197;value='-1';error='Invalid repeated action scale'}
    @{name='hero15a_repeat_budget';sheet='combat_effect';column='per_turn';row=197;value='1';error='Invalid repeated action scale'}
    @{name='hero15a_repeat_random';sheet='combat_effect';column='probability_bp';row=197;value='5000';error='Invalid repeated action scale'}
    @{name='hero15a_repeat_operator';sheet='combat_effect';column='op';row=197;value='heal';error='Invalid repeated action scale'}
    @{name='hero15a_repeat_index';sheet='combat_effect';column='argument';row=197;value='1';error='Invalid set parameter operation'}
    @{name='hero15a_record_budget';sheet='combat_effect';column='per_turn';row=194;value='1';error='Accepted kill action requires unlimited deterministic record'}
    @{name='hero15a_record_operator';sheet='combat_effect';column='op';row=194;value='damage';error='Accepted kill action requires unlimited deterministic record'}
    @{name='hero15a_record_target';sheet='combat_effect';column='target';row=194;value='enemies';error='Invalid event gate'}
    @{name='hero15a_passive_flag';sheet='combat_effect';column='flat';row=190;value='2';error='Passive query flag must be a constant boolean'}
    @{name='hero15a_passive_flag_basis';sheet='combat_effect';column='basis';row=190;value='source_attack';error='Passive query flag must be a constant boolean'}
    @{name='hero15a_before_buff_index';sheet='combat_effect';column='argument';row=187;value='4';error='Invalid set parameter operation'}
    @{name='hero15b_query_random';sheet='combat_effect';column='probability_bp';row=177;value='5000';error='Passive query must be a deterministic modifier'}
    @{name='hero15b_cooldown_tick_flag';sheet='combat_rule';column='value';row=54;value='2';error='Invalid combat shared rule'}
    @{name='hero15b_shared_rage_flag';sheet='combat_rule';column='value';row=55;value='2';error='Invalid combat shared rule'}
    @{name='hero15b_query_budget';sheet='combat_effect';column='budget';row=177;value='extra_attack';error='Passive query must be a deterministic modifier'}
    @{name='hero15b_query_interval';sheet='combat_effect';column='interval_turns';row=177;value='1';error='Passive query must be a deterministic modifier'}
    @{name='hero15b_query_index';sheet='combat_effect';column='argument';row=177;value='4';error='Invalid set parameter operation'}
    @{name='hero15b_query_field_context';sheet='combat_effect';column='conditions';row=176;value='[{"field":"passive_count","op":"ge","value":5}]';error='Invalid combat condition'}
    @{name='hero15b_kill_kind';sheet='combat_effect';column='flat';row=185;value='3';error='Invalid kill action parameter'}
    @{name='hero15b_invalid_kill_scale';sheet='combat_effect';column='flat';row=186;value='-1';error='Invalid kill action parameter'}
    @{name='hero15b_kill_index';sheet='combat_effect';column='argument';row=186;value='2';error='Invalid set parameter operation'}
    @{name='hero15b_kill_random';sheet='combat_effect';column='probability_bp';row=185;value='5000';error='Kill action query must use deterministic gates or parameters'}
    @{name='hero15b_kill_operator';sheet='combat_effect';column='op';row=183;value='damage';error='Kill action query must use deterministic gates or parameters'}
    @{name='pursuit_full_gate_target';sheet='combat_effect';column='target';row=175;value='enemies';error='Invalid event gate'}
    @{name='pursuit_full_gate_order';sheet='combat_effect';column='priority';row=175;value='11';error='Invalid or cyclic event gate reference'}
    @{name='pursuit_full_context';sheet='combat_effect';column='conditions';row=176;value='[{"field":"event_target_alive","op":"eq","value":1}]';error='Invalid combat condition'}
    @{name='pursuit_full_context_typo';sheet='combat_effect';column='conditions';row=175;value='[{"field":"event_target_alives","op":"eq","value":1}]';error='Invalid combat condition'}
    @{name='pursuit_full_vulnerability_flag';sheet='combat_rule';column='value';row=52;value='2';error='Invalid combat shared rule'}
    @{name='pursuit_full_refresh_flag';sheet='combat_rule';column='value';row=53;value='-1';error='Invalid combat shared rule'}
    @{name='shield_full_scope_typo';sheet='combat_effect';column='binding_scope';row=160;value='all_teams';error='Invalid team binding modifier'}
    @{name='shield_full_scope_event';sheet='combat_effect';column='event';row=160;value='before_heal';error='Invalid team binding modifier'}
    @{name='shield_full_scope_skill';sheet='combat_effect';column='skill_id';row=160;value='121';error='Invalid team binding modifier'}
    @{name='shield_full_scope_budget';sheet='combat_effect';column='per_turn';row=160;value='1';error='Shield query must be deterministic'}
    @{name='shield_full_query_random';sheet='combat_effect';column='probability_bp';row=161;value='5000';error='Shield query must be deterministic'}
    @{name='shield_full_parameter_index';sheet='combat_effect';column='argument';row=162;value='4';error='Invalid parameter addition'}
    @{name='shield_full_parameter_context';sheet='combat_effect';column='event';row=162;value='before_buff';error='Invalid parameter addition'}
    @{name='shield_full_attacker_context';sheet='combat_effect';column='event';row=169;value='after_hit';error='Attacker selector requires shield loss'}
    @{name='shield_full_passive_context';sheet='combat_effect';column='event';row=173;value='after_hit';error='Shield result operation requires shield loss'}
    @{name='shield_full_coefficient_negative';sheet='combat_effect';column='flat';row=171;value='-1';error='Invalid event coefficient addition'}
    @{name='shield_full_coefficient_target';sheet='combat_effect';column='target';row=171;value='enemies';error='Invalid event coefficient addition'}
    @{name='shield_full_coefficient_random';sheet='combat_effect';column='probability_bp';row=171;value='5000';error='Invalid event coefficient addition'}
    @{name='shield_full_bonus_context';sheet='combat_effect';column='ratio_source';row=161;value='event_bonus';error='Invalid event bonus consumer'}
    @{name='shield_full_budget_scope';sheet='combat_effect';column='counter_scope';row=174;value='target';error='Invalid amount budget contract'}
    @{name='shield_full_budget_zero_cap';sheet='combat_effect';column='cap_bp';row=174;value='0';error='Invalid amount budget contract'}
    @{name='shield_full_missing_coefficient';sheet='combat_effect';column='priority';row=173;value='35';error='Missing prior event coefficient producer'}
    @{name='shield_full_missing_hp_result';sheet='combat_effect';column='priority';row=174;value='15';error='Missing prior HP loss producer'}
    @{name='shield_full_thorns_flag_range';sheet='combat_rule';column='C';row=49;value='2';error='Invalid combat shared rule'}
    @{name='shield_full_thorns_cap_range';sheet='combat_rule';column='C';row=50;value='10001';error='Invalid combat shared rule'}
    @{name='shield_full_thorns_budget_negative';sheet='combat_rule';column='C';row=51;value='-1';error='Invalid combat shared rule'}
    @{name='shield_full_thorns_scope';sheet='combat_rule';column='D';row=51;value='allies';error='Invalid combat shared rule'}
)
foreach($case in $cases){
    if(-not (Test-CaseSelected $case.name)){continue}
    Reset-Fixture
    $book=if($case.book){$case.book}else{'hero_combat.xlsx'}
    Set-FixtureCell $case.sheet $case.column $case.row $case.value $book
    foreach($change in $case.changes){Set-FixtureCell $case.sheet $change.column $change.row $change.value $book}
    $before=(Get-FileHash -LiteralPath (Join-Path $fixture 'unityserver/config/json/combat_effect.json')).Hash
    $caught=''
    try{Export-Fixture}catch{$caught=$_.Exception.Message}
    if($caught -notlike ('*'+$case.error+'*')){throw "Case $($case.name) failed; expected '$($case.error)', got '$caught'"}
    $after=(Get-FileHash -LiteralPath (Join-Path $fixture 'unityserver/config/json/combat_effect.json')).Hash
    if($before -ne $after){throw "Rejected export wrote runtime output: $($case.name)"}
    $results.Add(@{case=$case.name;passed=$true;error=$caught})
}
Reset-Fixture
Set-FixtureCell 'combat_effect' 'J' 5 '4000'
Export-Fixture
$server=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/combat_effect.json') -Raw -Encoding UTF8
$client=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/combat_effect.json') -Raw -Encoding UTF8
if($server -cne $client){throw 'Client/server effect data diverged'}
$effect=@($server|ConvertFrom-Json)[0]
if($effect.ratio_bp -ne 4000 -or $effect.description -notlike '*40%*'){throw 'Table edit did not update both effect and description'}
$variant=if($ServerExecutable){Probe}else{$null}
if($ServerExecutable -and ($baseline.shield -ne 200 -or $variant.shield -ne 400)){throw 'Formal table edit did not change actual CFight shield from 200 to 400'}
$sensitivity=[Collections.Generic.List[object]]::new()
if($ServerExecutable){
    $sensitivity.Add(@{case='shield_ratio';before=$baseline.shield;after=$variant.shield})
    $variants=@(
        @{name='effect_target';sheet='combat_effect';column='G';row=5;value='self';field='source_shield';expected=200},
        @{name='effect_event';sheet='combat_effect';column='F';row=5;value='after_revive';field='shield';expected=0},
        @{name='healing_operator';sheet='combat_effect';column='H';row=5;value='heal';field='target_hp';expected=4200},
        @{name='strategy_reserve';sheet='combat_strategy';column='E';row=18;value='21';field='strategy_skill';expected=$baseline.regular_skill},
        @{name='pursuit_budget';sheet='combat_effect';column='Q';row=175;value='2';field='repeated_pursuit';expected=1200},
        @{name='pursuit_full_ratio';sheet='combat_effect';column='ratio_bp';row=10;value='3000';field='pursuit_full_first';expected=300},
        @{name='hero61b_life_scale';sheet='combat_effect';column='flat';row=208;value='5000';field='hero61b_damage';expected=825;expected_fields=@{hero61b_life_parameter=825;hero61b_other_damage=825}},
        @{name='hero61b_attack_cap';sheet='combat_effect';column='flat';row=209;value='10000';field='hero61b_capped_damage';expected=1000;expected_fields=@{hero61b_cap_parameter=10000}},
        @{name='hero61b_rage';sheet='combat_effect';column='flat';row=211;value='5';field='hero61b_rage';expected=5;expected_fields=@{hero61b_repeat_rage=5;hero61b_empty_rage=5;hero61b_secondary_rage=5;hero61b_real_death_rage=5}},
        @{name='hero61b_gate_limit';sheet='combat_effect';column='per_battle';row=210;value='2';field='hero61b_repeat_rage';expected=16;expected_fields=@{hero61b_repeat_damage=0}},
        @{name='hero61b_repeat_guard';sheet='combat_effect';column='conditions';row=212;value='[{"field":"counter_count_6133","op":"ge","value":2}]';field='hero61b_repeat_damage';expected=687;expected_fields=@{hero61b_repeat_rage=8;hero61b_after_empty_damage=687}},
        @{name='hero61b_summon_guard';sheet='combat_effect';column='conditions';row=213;value='[{"field":"source_summoned","op":"eq","value":0}]';field='hero61b_summoned_damage';expected=687;expected_fields=@{hero61b_damage=0;hero61b_summoned_rage=0}},
        @{name='hero61b_summon_credit';sheet='combat_effect';column='conditions';row=210;value='[{"field":"passive_trigger","op":"eq","value":38},{"field":"source_skill_level_613","op":"gt","value":0}]';field='hero61b_summoned_rage';expected=8;expected_fields=@{hero61b_summoned_damage=0}},
        @{name='hero61b_learned_guard';sheet='combat_effect';column='conditions';row=210;value='[{"field":"passive_trigger","op":"eq","value":38},{"field":"source_summoned","op":"eq","value":0}]';field='hero61b_missing_skill_rage';expected=8},
        @{name='hero61b_trigger_guard';sheet='combat_effect';column='conditions';row=210;value='[{"field":"passive_trigger","op":"eq","value":37}]';field='hero61b_rage';expected=0;expected_fields=@{hero61b_repeat_damage=687}},
        @{name='hero61b_sequence_depth';sheet='combat_event_policy';column='extra_depth';row=27;value='0';field='hero61b_secondary_rage';expected=0},
        @{name='hero65b_defense';sheet='combat_effect';column='flat';row=205;value='3000';field='hero65b_defense';expected=3000;expected_fields=@{hero65b_high_defense=3000;hero65b_secondary_defense=0}},
        @{name='hero65b_duration';sheet='combat_effect';column='flat';row=206;value='3';field='hero65b_duration';expected=3},
        @{name='hero65b_raw_delta';sheet='combat_effect';column='flat';row=207;value='400';field='hero65b_raw';expected=1500;expected_fields=@{hero65b_high_raw=8900;hero65b_initialized_magic_immunity=1100;hero65b_high_initialized=8500}},
        @{name='hero65b_raw_index';sheet='combat_effect';column='argument';row=207;value='0';field='hero65b_raw';expected=1100},
        @{name='hero65b_raw_skill';sheet='combat_effect';column='skill_id';row=207;value='653';changes=@(@{column='conditions';row=207;value='[]'});field='hero65b_raw';expected=1100},
        @{name='hero65b_raw_branch';sheet='combat_effect';column='group_id';row=207;value='651';field='hero65b_raw';expected=1100;expected_fields=@{hero65a_other_passive=1900}},
        @{name='hero65b_raw_condition';sheet='combat_effect';column='conditions';row=207;value='[{"field":"parameter_count","op":"ge","value":4}]';field='hero65b_raw';expected=1100},
        @{name='hero65a_raw_delta';sheet='combat_effect';column='flat';row=204;value='-400';field='hero65a_enemy_aura';expected=-1500;expected_fields=@{hero65a_high_aura=-8900;hero65a_raw=-1500}},
        @{name='hero65a_positive_delta';sheet='combat_effect';column='flat';row=204;value='800';field='hero65a_enemy_aura';expected=-300;expected_fields=@{hero65a_high_aura=-7700}},
        @{name='hero65a_parameter_index';sheet='combat_effect';column='argument';row=204;value='2';field='hero65a_enemy_aura';expected=0},
        @{name='hero65a_skill_binding';sheet='combat_effect';column='skill_id';row=204;value='654';changes=@(@{column='conditions';row=204;value='[]'});field='hero65a_other_passive';expected=300;expected_fields=@{hero65a_enemy_aura=-1100}},
        @{name='hero65a_condition';sheet='combat_effect';column='conditions';row=204;value='[{"field":"passive_effect","op":"eq","value":654}]';field='hero65a_enemy_aura';expected=-1100},
        @{name='hero65a_poison_ratio';sheet='combat_effect';column='flat';row=12;value='15000';field='hero65a_poison';expected=915;expected_fields=@{hero65a_poison_flat=150;hero65a_high_poison=2025}},
        @{name='hero65a_poison_duration';sheet='combat_effect';column='flat';row=13;value='4';field='hero65a_poison_duration';expected=4},
        @{name='hero61a_guard';sheet='combat_effect';column='flat';row=203;value='800';field='hero61a_guard';expected=800;expected_fields=@{hero61a_secondary_guard=800;hero61a_dead_guard=800}},
        @{name='hero61a_duration';sheet='combat_effect';column='duration';row=203;value='3';field='hero61a_duration';expected=3;expected_fields=@{hero61a_next_duration=2}},
        @{name='hero61a_event_timing';sheet='combat_effect';column='event';row=203;value='after_primary_hit';field='hero61a_timing_preserved';expected=0},
        @{name='hero61a_skill';sheet='combat_effect';column='skill_id';row=203;value='612';field='hero61a_tactic_guard';expected=1200;expected_fields=@{hero61a_guard=0}},
        @{name='hero61a_alive_target';sheet='combat_effect';column='target';row=203;value='self';field='hero61a_dead_guard';expected=0},
        @{name='hero61a_enemy_target';sheet='combat_effect';column='target';row=203;value='enemies';field='hero61a_enemy_guard';expected=1200;expected_fields=@{hero61a_guard=0}},
        @{name='hero61a_immunity';sheet='combat_effect';column='check_skill_immunity';row=203;value='1';field='hero61a_immunity_bypass';expected=0},
        @{name='hero61a_frequency';sheet='combat_effect';column='per_turn';row=203;value='1';field='hero61a_refresh_duration';expected=1},
        @{name='hero61a_secondary_depth';sheet='combat_event_policy';column='extra_depth';row=26;value='0';field='hero61a_secondary_guard';expected=0},
        @{name='hero61a_nested_depth';sheet='combat_event_policy';column='extra_depth';row=26;value='2';field='hero61a_nested_guard';expected=1200},
        @{name='hero61a_origin';sheet='combat_effect';column='origin_skill';row=203;value='0';field='hero61a_origin';expected=0},
        @{name='hero61a_presentation';sheet='combat_effect';column='emit_action';row=203;value='1';field='hero61a_emitted_actions';expected=([long]$baseline.hero61a_emitted_actions+1)},
        @{name='hero15a_vulnerability';sheet='combat_effect';column='flat';row=187;value='1800';field='hero15a_real_vulnerability';expected=1800;expected_fields=@{hero15a_query_vulnerability=1800}},
        @{name='hero15a_vulnerability_duration';sheet='combat_effect';column='flat';row=188;value='4';field='hero15a_real_duration';expected=4},
        @{name='hero15a_empty_parameter_gate';sheet='combat_effect';column='conditions';row=187;value='[{"field":"parameter_count","op":"ge","value":0}]';field='hero15a_empty_parameters';expected=1},
        @{name='hero15a_post_vulnerability';sheet='combat_effect';column='flat';row=189;value='1000';field='hero15a_after_primary';expected=1000;expected_fields=@{hero15a_weak_replaced=1000}},
        @{name='hero15a_post_threshold';sheet='combat_effect';column='conditions';row=189;value='[{"field":"target_alive","op":"eq","value":1},{"field":"target_buff_value_22","op":"lt","value":1600}]';field='hero15a_equal_kept_duration';expected=2},
        @{name='hero15a_post_immunity';sheet='combat_effect';column='check_skill_immunity';row=189;value='1';field='hero15a_direct_immunity_bypass';expected=0},
        @{name='hero15a_disable_old_speed';sheet='combat_effect';column='conditions';row=190;value='[{"field":"passive_effect","op":"eq","value":155}]';field='hero15a_legacy_speed_filtered';expected=1},
        @{name='hero15a_chase_zero';sheet='combat_effect';column='flat';row=191;value='0';field='hero15a_chase_success_count';expected=0;expected_fields=@{hero15a_chase_extra_count=0}},
        @{name='hero15a_chase_certain';sheet='combat_effect';column='flat';row=191;value='10000';field='hero15a_chance_failure_record';expected=1},
        @{name='hero15a_speed_without_passive';sheet='combat_effect';column='flat';row=192;value='2500';field='hero15a_speed_without_passive';expected=2500},
        @{name='hero15a_speed_flat';sheet='combat_effect';column='flat';row=193;value='4000';field='hero15a_speed_known';expected=4100;expected_fields=@{hero15a_speed_high_level=11500}},
        @{name='hero15a_speed_slope';sheet='combat_effect';column='ratio_bp';row=193;value='500000';field='hero15a_speed_known';expected=3050;expected_fields=@{hero15a_speed_high_level=6750}},
        @{name='hero15a_speed_level_source';sheet='combat_effect';column='basis';row=193;value='source_skill_level_154';field='hero15a_speed_high_level';expected=3100},
        @{name='hero15a_record_kind';sheet='combat_effect';column='conditions';row=194;value='[{"field":"action_kind","op":"eq","value":1}]';field='hero15a_chase_success_count';expected=0;expected_fields=@{hero15a_chase_extra_count=1}},
        @{name='hero15a_revived_gate';sheet='combat_effect';column='conditions';row=195;value='[{"field":"source_just_revived","op":"eq","value":0}]';field='hero15a_chase_success_count';expected=0},
        @{name='hero15a_record_age';sheet='combat_effect';column='conditions';row=196;value='[{"field":"counter_age_1537","op":"eq","value":1}]';field='hero15a_repeat_rng';expected=0},
        @{name='hero15a_repeat_scale';sheet='combat_effect';column='flat';row=197;value='5000';field='hero15a_repeat_damage';expected=[long]([Math]::Floor([long]$baseline.hero15a_repeat_raw*5000/10000));expected_fields=@{hero15a_repeat_scale=5000}},
        @{name='hero15a_growth';sheet='combat_effect';column='flat';row=198;value='600';field='hero15a_growth_enemy';expected=600;expected_fields=@{hero15a_growth_ally=600;hero15a_growth_capped=3000}},
        @{name='hero15a_growth_cap';sheet='combat_effect';column='flat';row=199;value='3';changes=@(@{column='conditions';row=202;value='[{"field":"passive_trigger","op":"eq","value":15},{"field":"parameter_count","op":"ge","value":3},{"field":"passive_count","op":"ge","value":3}]'});field='hero15a_growth_cap';expected=3;expected_fields=@{hero15a_growth_capped=1200}},
        @{name='hero15a_growth_summon_gate';sheet='combat_effect';column='conditions';row=200;value='[{"field":"passive_trigger","op":"eq","value":15},{"field":"parameter_count","op":"ge","value":3},{"field":"target_summoned","op":"eq","value":0}]';field='hero15a_growth_enemy';expected=0},
        @{name='hero15b_ally_growth';sheet='combat_effect';column='flat';row=177;value='450';field='hero15b_growth_ally';expected=450},
        @{name='hero15b_cooldown_tick_policy';sheet='combat_rule';column='value';row=54;value='0';field='hero15b_natural_cd_first';expected=3},
        @{name='hero15b_shared_rage_policy';sheet='combat_rule';column='value';row=55;value='1';field='hero15b_guard_damage_rage';expected=6},
        @{name='hero15b_counter_rage_value';sheet='combat_rule';column='value';row=32;value='4';field='hero15b_counter_received_rage';expected=4},
        @{name='hero15b_enemy_growth';sheet='combat_effect';column='flat';row=178;value='900';field='hero15b_growth_enemy';expected=900;expected_fields=@{hero15b_growth_high_level=900}},
        @{name='hero15b_growth_cap';sheet='combat_effect';column='flat';row=179;value='3';changes=@(@{column='conditions';row=182;value='[{"field":"passive_trigger","op":"eq","value":15},{"field":"parameter_count","op":"ge","value":3},{"field":"passive_count","op":"ge","value":3}]'});field='hero15b_growth_cap';expected=3;expected_fields=@{hero15b_growth_capped_value=1500;hero15b_growth_limit_parameter=3}},
        @{name='hero15b_summon_gate';sheet='combat_effect';column='conditions';row=180;value='[{"field":"passive_trigger","op":"eq","value":15},{"field":"parameter_count","op":"ge","value":3},{"field":"target_summoned","op":"eq","value":0}]';field='hero15b_summoned_rng';expected=0},
        @{name='hero15b_growth_post_limit';sheet='combat_effect';column='conditions';row=182;value='[{"field":"passive_trigger","op":"eq","value":15},{"field":"parameter_count","op":"ge","value":3},{"field":"passive_count","op":"ge","value":3}]';field='hero15b_growth_cap';expected=3;expected_fields=@{hero15b_growth_capped_value=1500}},
        @{name='hero15b_kill_frequency';sheet='combat_effect';column='per_turn';row=184;value='2';field='hero15b_chase_repeat_attempts';expected=2},
        @{name='hero15b_kill_revived_gate';sheet='combat_effect';column='conditions';row=184;value='[{"field":"source_just_revived","op":"eq","value":1}]';field='hero15b_revived_attempts';expected=1;expected_fields=@{hero15b_chase_attempts=0;hero15b_chase_damage=0}},
        @{name='hero15b_kill_scale';sheet='combat_effect';column='flat';row=186;value='4000';field='hero15b_plan_scale';expected=4000},
        @{name='hero15b_kill_mode';sheet='combat_effect';column='flat';row=185;value='2';field='hero15b_plan_kind';expected=2;expected_fields=@{hero15b_chase_damage=0}},
        @{name='pursuit_full_frequency';sheet='combat_effect';column='per_turn';row=175;value='2';field='pursuit_full_repeat';expected=1200;expected_fields=@{pursuit_full_after_zero=600}},
        @{name='pursuit_full_target_gate';sheet='combat_effect';column='conditions';row=175;value='[{"field":"event_target_alive","op":"eq","value":0}]';field='pursuit_full_first';expected=0;expected_fields=@{pursuit_full_dead_target_spent=1}},
        @{name='pursuit_full_bonus';sheet='combat_effect';column='flat';row=176;value='1000';field='pursuit_full_low_bonus';expected=1000},
        @{name='pursuit_full_threshold';sheet='combat_effect';column='conditions';row=176;value='[{"field":"target_hp_bp","op":"lt","value":5000}]';field='pursuit_full_boundary_bonus';expected=2000},
        @{name='pursuit_full_skill';sheet='combat_effect';column='skill_id';row=176;value='151';field='pursuit_full_low_bonus';expected=0;expected_fields=@{pursuit_full_wrong_skill=2000}},
        @{name='pursuit_full_vulnerability_policy';sheet='combat_rule';column='value';row=52;value='0';field='pursuit_full_vulnerability_count';expected=2},
        @{name='pursuit_full_refresh_policy';sheet='combat_rule';column='value';row=53;value='0';field='pursuit_full_speed_count';expected=2},
        @{name='zero_duration';sheet='combat_effect';column='L';row=11;value='0';field='control_turns';expected=0},
        @{name='shared_shield_cap';sheet='combat_rule';column='C';row=6;value='4000';field='rule_shield_cap';expected=4000},
        @{name='shield_refresh_policy';sheet='combat_rule';column='C';row=13;value='0';field='rule_shield_refresh';expected=5000},
        @{name='shared_dot_stacks';sheet='combat_rule';column='C';row=7;value='3';field='rule_dot_stacks';expected=3},
        @{name='shared_dot_duration';sheet='combat_rule';column='C';row=8;value='4';field='rule_dot_duration';expected=4},
        @{name='poison_budget_policy';sheet='combat_rule';column='C';row=14;value='0';field='rule_dot_stacks';expected=6},
        @{name='shared_rage_cap';sheet='combat_rule';column='C';row=5;value='80';field='rule_rage_cap';expected=80},
        @{name='periodic_turn_budget';sheet='combat_rule';column='C';row=15;value='10000';field='periodic_damage';expected=180},
        @{name='periodic_formula';sheet='combat_periodic';column='G';row=6;value='1';field='periodic_damage';expected=0},
        @{name='periodic_bonus';sheet='combat_periodic';column='M';row=11;value='4000';field='periodic_bleed';expected=140},
        @{name='periodic_event';sheet='combat_periodic';column='C';row=11;value='after_heal';field='periodic_bleed';expected=0},
        @{name='control_diminishing';sheet='combat_rule';column='C';row=20;value='2500';field='control_second';expected=1},
        @{name='control_immunity';sheet='combat_rule';column='C';row=18;value='4';field='control_third';expected=3},
        @{name='boss_replacement';sheet='combat_control';column='F';row=5;value='2000';field='boss_slow';expected=2000},
        @{name='boss_budget';sheet='combat_rule';column='C';row=23;value='2';field='boss_count';expected=2},
        @{name='revive_target_budget';sheet='combat_rule';column='C';row=10;value='3';field='revive_third';expected=1000},
        @{name='revive_source_budget';sheet='combat_rule';column='C';row=16;value='2';field='revive_same';expected=1000},
        @{name='extra_attack_budget';sheet='combat_rule';column='C';row=11;value='1';field='extra_count';expected=1},
        @{name='revived_extra_block';sheet='combat_rule';column='C';row=24;value='0';field='revive_extra';expected=1},
        @{name='secondary_depth';sheet='combat_rule';column='C';row=9;value='2';field='nested_shield';expected=200},
        @{name='shield_origin_skill';sheet='combat_effect';column='D';row=9;value='122';field='explosion';expected=0}
    )
    $variants+=@(
        @{name='artifact_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=63;value='3200';field='artifact_guard';expected=3200},
        @{name='artifact_dot_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=70;value='3000';field='artifact_dot';expected=1300},
        @{name='artifact_rank';book='fabao.xlsx';sheet='combat_artifact';column='E';row=63;value='0';field='chosen_artifact';expected=1010},
        @{name='artifact_slot_tie';sheet='combat_loadout_slot';column='C';row=9;value='7';field='tie_artifact';expected=1410},
        @{name='artifact_target_budget';sheet='combat_effect';column='W';row=14;value='source';field='artifact_guard_second';expected=0},
        @{name='set_curve';book='suit.xlsx';sheet='combat_set';column='E';row=21;value='2000';field='set_shield';expected=1200},
        @{name='set_threshold';book='suit.xlsx';sheet='combat_set';column='C';row=21;value='3';field='set_shield';expected=1000}
        @{name='combined_periodic_cap';sheet='combat_periodic';column='P';row=6;value='1000';field='artifact_affix_dot';expected=1100},
        @{name='periodic_affix_binding';sheet='combat_periodic';column='O';row=6;value='0';field='artifact_affix_dot';expected=1180}
        @{name='healing_artifact_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=62;value='2400';field='hot_heal';expected=1340},
        @{name='healing_set_curve';book='suit.xlsx';sheet='combat_set';column='E';row=23;value='2000';field='hot_heal';expected=1320},
        @{name='heal_speed_curve';book='suit.xlsx';sheet='combat_set';column='E';row=24;value='1200';field='active_heal_speed';expected=1200},
        @{name='heal_shared_counter';sheet='combat_effect';column='Z';row=29;value='0';field='shared_heal_speed';expected=800},
        @{name='shield_trigger_interval';sheet='combat_effect';column='X';row=25;value='1';field='shield_interval';expected=672},
        @{name='shield_hp_threshold';sheet='combat_effect';column='T';row=25;value='[{"field":"source_hp_bp","op":"lt","value":2000}]';field='low_shield';expected=0},
        @{name='cleanse_heal_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=72;value='6000';field='cleanse_heal';expected=600},
        @{name='cleanse_turn_budget';sheet='combat_effect';column='Q';row=24;value='2';field='cleanse_repeat';expected=900},
        @{name='share_turn_budget';sheet='combat_effect';column='Q';row=23;value='2';field='share_repeat';expected=1800},
        @{name='hot_bonus_cap';sheet='combat_periodic';column='P';row=10;value='0';field='hot_heal';expected=1000}
        @{name='suit_base_attribute';book='suit.xlsx';sheet='Sheet1';column='B';row=5;value='[[[1,25,1800]],[],[]]';field='base_suit_counter';expected=1800}
    )
    $variants+=@(
        @{name='execute_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=65;value='2400';field='execute_damage';expected=1240},
        @{name='execute_threshold';sheet='combat_effect';column='T';row=30;value='[{"field":"target_hp_bp","op":"lt","value":4000}]';field='execute_boundary';expected=1120},
        @{name='combo_segment_start';sheet='combat_effect';column='T';row=31;value='[{"field":"hit_index","op":"ge","value":2},{"field":"hit_index","op":"le","value":3}]';field='combo_second';expected=1000},
        @{name='speed_duration';sheet='combat_effect';column='T';row=32;value='[{"field":"turn","op":"lt","value":1}]';field='second_speed';expected=1000},
        @{name='speed_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=68;value='2400';field='opening_speed';expected=1240},
        @{name='direct_multiplier_cap';sheet='combat_rule';column='C';row=26;value='15000';field='capped_direct';expected=1500},
        @{name='direct_multiplier_floor';sheet='combat_rule';column='C';row=25;value='5000';field='floored_direct';expected=500}
        @{name='debuff_category';sheet='combat_buff_category';column='C';row=6;value='2';field='weakness_same';expected=1120},
        @{name='weakness_threshold';sheet='combat_effect';column='T';row=33;value='[{"field":"target_debuff_categories","op":"ge","value":3}]';field='weakness_two';expected=1000},
        @{name='weakness_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=69;value='2400';field='weakness_two';expected=1240},
        @{name='death_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=71;value='2400';field='death_high';expected=2700},
        @{name='death_stacking';sheet='combat_effect';column='AB';row=34;value='replace_source';field='death_high';expected=1900},
        @{name='death_budget';sheet='combat_effect';column='R';row=34;value='2';field='death_repeat';expected=1200},
        @{name='death_duration';sheet='combat_effect';column='O';row=34;value='3';field='death_duration';expected=3},
        @{name='summoned_death_condition';sheet='combat_effect';column='T';row=34;value='[]';field='summoned_death';expected=600},
        @{name='effect_presentation';sheet='combat_effect';column='AC';row=34;value='231';field='death_origin';expected=10011}
        @{name='effect_origin';sheet='combat_effect';column='origin_skill';row=34;value='231';field='death_origin';expected=231}
        @{name='artifact_rage_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=73;value='10';field='artifact_rage';expected=10},
        @{name='artifact_team_selection';book='fabao.xlsx';sheet='combat_artifact';column='G';row=73;value='1';field='artifact_rage';expected=2},
        @{name='artifact_rage_scope';sheet='combat_effect';column='W';row=35;value='source';field='repeat_artifact_rage';expected=12},
        @{name='artifact_rage_budget';sheet='combat_effect';column='R';row=35;value='2';field='repeat_artifact_rage';expected=12},
        @{name='rage_actor_cap';sheet='combat_rule';column='C';row=27;value='8';field='extra_actor_rage';expected=8},
        @{name='rage_team_cap';sheet='combat_rule';column='C';row=28;value='20';field='extra_team_rage';expected=20},
        @{name='rage_opening_cap';sheet='combat_rule';column='C';row=29;value='10';field='opening_rage';expected=10},
        @{name='rage_normal_value';sheet='combat_rule';column='C';row=30;value='6';field='base_rage_bypass';expected=6},
        @{name='rage_damage_value';sheet='combat_rule';column='C';row=32;value='4';field='damage_rage';expected=12},
        @{name='rage_damage_count';sheet='combat_rule';column='C';row=33;value='2';field='damage_rage';expected=6},
        @{name='tactic_cost_minimum';sheet='combat_rule';column='C';row=36;value='30';field='tactic_cost_floor';expected=30}
        @{name='disabled_highest_no_fallback';book='fabao.xlsx';sheet='combat_artifact';column='H';row=61;value='0';field='selected_groups';expected=0},
        @{name='shield_efficiency_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=61;value='2400';field='efficient_first';expected=1240},
        @{name='shield_target_budget';sheet='combat_effect';column='AE';row=36;value='3';changes=@(@{column='AE';row=37;value='3'});field='efficient_fourth';expected=1000},
        @{name='shield_action_budget';sheet='combat_effect';column='AD';row=36;value='1';changes=@(@{column='AD';row=37;value='1'});field='efficient_repeat';expected=1000},
        @{name='shield_pressure_curve';book='fabao.xlsx';sheet='combat_artifact';column='G';row=67;value='4000';field='pressure_absorbed';expected=1400},
        @{name='shield_pierce_rule';sheet='combat_rule';column='C';row=37;value='6000';field='base_pierce_life';expected=600},
        @{name='shield_parameter_operator';sheet='combat_effect';column='H';row=38;value='set_parameter';changes=@(@{column='U';row=38;value='直接伤害穿盾比例{gear_value_pct}%'});field='pressure_life';expected=240}
    )
    $variants+=@(
        @{name='set_guard_curve';book='suit.xlsx';sheet='combat_set';column='E';row=8;value='2500';field='set_guard_damage';expected=750},
        @{name='set_guard_threshold';sheet='combat_effect';column='T';row=39;value='[{"field":"source_hp_bp","op":"lt","value":5000}]';field='guard_boundary_damage';expected=850},
        @{name='public_guard_cap';sheet='combat_rule';column='C';row=38;value='5000';field='capped_guard_damage';expected=500},
        @{name='public_guard_floor';sheet='combat_rule';column='C';row=39;value='7000';field='capped_guard_damage';expected=700},
        @{name='set_ignore_curve';book='suit.xlsx';sheet='combat_set';column='E';row=16;value='2500';field='ignore_combined';expected=3700},
        @{name='affix_binding';sheet='combat_effect';column='AF';row=45;value='48';field='ignore_combined';expected=1500},
        @{name='affix_buff_condition';sheet='combat_effect';column='T';row=45;value='[{"field":"source_attack_type","op":"eq","value":2},{"field":"target_buff_28","op":"eq","value":1}]';field='ignore_combined';expected=1500},
        @{name='affix_ignore_ratio';sheet='combat_effect';column='J';row=45;value='5000';field='ignore_combined';expected=2180},
        @{name='ignore_cap';sheet='combat_rule';column='C';row=40;value='4000';field='ignore_capped';expected=4000},
        @{name='received_heal_curve';book='suit.xlsx';sheet='combat_set';column='E';row=14;value='3000';field='received_hot';expected=1120},
        @{name='critical_curve';book='suit.xlsx';sheet='combat_set';column='E';row=14;value='3000';field='low_critical';expected=3000},
        @{name='negative_heal_modifier';sheet='combat_effect';column='L';row=22;value='-2000';field='hot_heal';expected=1020},
        @{name='aura_alive_policy';sheet='combat_effect';column='AH';row=43;value='1';field='dead_aura_damage';expected=750},
        @{name='guard_tactic_condition';sheet='combat_effect';column='T';row=44;value='[{"field":"rage","op":"ge","value":0,"value_field":"affix_value2"}]';field='spent_tactic_damage';expected=669}
        @{name='affix_guard_curve';sheet='equipment_affix';column='H';row=16;value='[400,600,1000]';field='combined_guard_damage';expected=650},
        @{name='affix_guard_duration';sheet='equipment_affix';column='J';row=16;value='3';field='expired_aura_damage';expected=770},
        @{name='affix_rage_threshold';sheet='equipment_affix';column='I';row=52;value='[60,60,60]';field='combined_guard_damage';expected=770}
        @{name='hit_slow_curve';book='suit.xlsx';sheet='combat_set';column='E';row=18;value='1600';field='shielded_hit_slow';expected=1600},
        @{name='hit_boss_curve';sheet='combat_effect';column='L';row=47;value='1500';field='set_boss_slow';expected=1500},
        @{name='hit_boss_duration';sheet='combat_effect';column='O';row=47;value='3';field='set_boss_duration';expected=3},
        @{name='hit_action_budget';sheet='combat_effect';column='AD';row=46;value='2';changes=@(@{column='AD';row=47;value='2'});field='same_action_slow';expected=1200},
        @{name='hit_skill_role';sheet='combat_effect';column='T';row=46;value='[{"field":"regular_skill","op":"eq","value":0},{"field":"target_boss","op":"eq","value":0}]';field='shielded_hit_slow';expected=0}
        @{name='opening_shield_curve';book='suit.xlsx';sheet='combat_set';column='E';row=22;value='1000';field='leader_opening_shield';expected=2240},
        @{name='opening_shield_basis';sheet='combat_effect';column='I';row=48;value='source_attack';field='leader_opening_shield';expected=672},
        @{name='opening_shield_target';sheet='combat_effect';column='G';row=48;value='self';field='leader_opening_shield';expected=0},
        @{name='opening_leader_condition';sheet='combat_effect';column='T';row=48;value='[{"field":"source_is_group_hp_leader","op":"eq","value":0}]';field='nonleader_opening_shield';expected=672},
        @{name='opening_shield_budget';sheet='combat_effect';column='R';row=48;value='2';field='repeat_opening_shield';expected=1344}
        @{name='counter_kill_curve';book='suit.xlsx';sheet='combat_set';column='E';row=10;value='1000';field='counter_kill_heal';expected=1000},
        @{name='counter_kill_cooldown';sheet='combat_effect';column='L';row=51;value='2';field='counter_kill_cd';expected=4},
        @{name='counter_kill_role';sheet='combat_effect';column='AJ';row=51;value='tactic';field='counter_kill_tactic_cd';expected=5},
        @{name='counter_kill_shared_budget';sheet='combat_effect';column='Q';row=49;value='2';field='repeat_counter_heal';expected=1600},
        @{name='kill_stack_curve';book='suit.xlsx';sheet='combat_set';column='E';row=12;value='800';field='third_kill_stack';expected=2400},
        @{name='kill_stack_growth';sheet='combat_effect';column='K';row=53;value='5000';field='third_kill_stack';expected=1200},
        @{name='kill_stack_cap';sheet='combat_effect';column='N';row=53;value='20000';field='capped_kill_stack';expected=1200},
        @{name='kill_stack_refresh_duration';sheet='combat_effect';column='O';row=53;value='5';field='capped_stack_duration';expected=5},
        @{name='kill_stack_summon_condition';sheet='combat_effect';column='T';row=52;value='[{"field":"enemy_kill","op":"eq","value":1}]';field='summon_kill_stack';expected=1200},
        @{name='kill_stack_dead_source_target';sheet='combat_effect';column='G';row=53;value='self';field='dead_source_stack';expected=0},
        @{name='failed_attempt_budget';sheet='combat_effect';column='Q';row=54;value='2';field='failed_gate_rolls';expected=2},
        @{name='seal_probability';sheet='combat_effect';column='P';row=55;value='10000';field='gated_seal';expected=1},
        @{name='low_attack_threshold';sheet='combat_effect';column='T';row=56;value='[{"field":"target_hp_bp","op":"lt","value":4000}]';field='boundary_attack_critical';expected=1600},
        @{name='low_attack_coefficient';sheet='combat_effect';column='J';row=56;value='5000';field='low_attack_critical';expected=800},
        @{name='low_attack_affix_curve';sheet='equipment_affix';column='H';row=21;value='[800,1200,2000]';field='low_attack_critical';expected=2000},
        @{name='chase_attack_affix_curve';sheet='equipment_affix';column='I';row=26;value='[500,800,2000]';field='chase_attack_damage';expected=1700},
        @{name='attack_attribute_slot';sheet='combat_effect';column='S';row=58;value='1';field='chase_attack_hit';expected=0},
        @{name='counter_attack_condition';sheet='combat_effect';column='T';row=59;value='[{"field":"first_attack","op":"eq","value":0},{"field":"counter_attack","op":"eq","value":1}]';field='counter_attack_damage';expected=1620},
        @{name='negative_attack_bonus';sheet='combat_effect';column='J';row=59;value='-10000';field='chase_attack_damage';expected=1380},
        @{name='direct_hit_floor';sheet='combat_rule';column='C';row=41;value='10000';field='direct_min_hit';expected=1000},
        @{name='enemy_hit_floor';sheet='combat_rule';column='C';row=41;value='10000';field='enemy_min_hit';expected=1000},
        @{name='direct_hit_ceiling';sheet='combat_rule';column='C';row=42;value='1000';field='direct_max_hit';expected=0},
        @{name='enemy_hit_ceiling';sheet='combat_rule';column='C';row=42;value='1000';field='enemy_max_hit';expected=0},
        @{name='combo_count_cap';sheet='equipment_affix';column='I';row=25;value='[3,3,2]';field='count_combo_4';expected=1600},
        @{name='combo_uncapped';sheet='combat_effect';column='AK';row=60;value='none';field='count_combo_4';expected=3200},
        @{name='combo_coefficient';sheet='combat_effect';column='J';row=60;value='20000';field='count_combo_2';expected=3200},
        @{name='combo_divisor';sheet='combat_effect';column='AL';row=60;value='2';field='count_combo_2';expected=800},
        @{name='category_curve';sheet='equipment_affix';column='H';row=43;value='[300,400,1000]';field='count_same_category';expected=1000},
        @{name='category_cap';sheet='equipment_affix';column='I';row=43;value='[4,4,2]';field='count_capped_categories';expected=1000},
        @{name='category_uncapped';sheet='combat_effect';column='AK';row=67;value='none';field='count_capped_categories';expected=2500},
        @{name='category_zero_cap';sheet='equipment_affix';column='I';row=43;value='[4,4,0]';field='count_capped_categories';expected=2500},
        @{name='category_taxonomy';sheet='combat_buff_category';column='C';row=6;value='13';field='count_same_category';expected=1000},
        @{name='shield_condition';sheet='combat_effect';column='T';row=61;value='[]';field='count_unshielded';expected=2000},
        @{name='control_category';sheet='combat_effect';column='T';row=62;value='[{"field":"target_category_7","op":"eq","value":1}]';field='count_slow_hit';expected=2000},
        @{name='periodic_category';sheet='combat_effect';column='T';row=64;value='[{"field":"target_category_5","op":"eq","value":1}]';field='count_curse_dot';expected=1600},
        @{name='periodic_no_double_bonus';sheet='combat_effect';column='J';row=64;value='5000';field='count_multiple_dots';expected=800},
        @{name='low_heal_curve';sheet='equipment_affix';column='H';row=10;value='[1200,1800,3000]';field='healing_low';expected=780},
        @{name='low_heal_threshold';sheet='equipment_affix';column='I';row=10;value='[3500,3500,4000]';field='healing_boundary';expected=750},
        @{name='low_heal_periodic_condition';sheet='combat_effect';column='T';row=68;value='[{"field":"periodic_heal","op":"eq","value":1}]';field='healing_hot_excluded';expected=1250},
        @{name='active_heal_upper_cap';sheet='combat_rule';column='C';row=44;value='5000';field='healing_capped';expected=900},
        @{name='active_heal_lower_cap';sheet='combat_rule';column='C';row=43;value='-5000';field='healing_floor';expected=300},
        @{name='normal_antiheal_policy';sheet='combat_rule';column='C';row=45;value='0';field='healing_normal_antiheal';expected=750},
        @{name='revive_antiheal_policy';sheet='combat_rule';column='C';row=46;value='1';field='healing_revive_antiheal';expected=1625},
        @{name='low_heal_coefficient';sheet='combat_effect';column='J';row=68;value='5000';field='healing_low';expected=675},
        @{name='seal_boss_replacement';sheet='combat_effect';column='P';row=55;value='10000';field='gated_boss_slow';expected=1000},
        @{name='zero_probability';sheet='combat_effect';column='P';row=55;value='0';field='successful_gate_applied';expected=0},
        @{name='seal_segment';sheet='combat_effect';column='T';row=54;value='[{"field":"hit_index","op":"eq","value":2}]';field='failed_gate_rolls';expected=0},
        @{name='dot_kill_event_depth';sheet='combat_event_policy';column='C';row=5;value='0';field='terminal_dot_stack';expected=0},
        @{name='counter_kill_heal_depth';sheet='combat_event_policy';column='C';row=6;value='0';field='terminal_counter_heal';expected=0},
        @{name='counter_kill_cooldown_depth';sheet='combat_event_policy';column='C';row=6;value='0';field='terminal_counter_cd';expected=6},
        @{name='counter_hit_seal';sheet='combat_effect';column='P';row=55;value='10000';field='terminal_counter_seal';expected=1},
        @{name='revive_equipment_order_priority';sheet='combat_effect';column='priority';row=14;value='10';field='real_revive_guard_first';expected=193},
        @{name='received_hero_before_affix_priority';sheet='combat_effect';column='priority';row=143;value='0';field='received_order_first';expected=37},
        @{name='shield_recovery_antiheal_operation';sheet='combat_effect';column='op';row=97;value='restore_hp';field='shield_loss_antiheal';expected=400},
        @{name='taunt_recovery_antiheal_operation';sheet='combat_effect';column='op';row=119;value='restore_hp';field='budget_taunt_antiheal';expected=400},
        @{name='counter_recovery_antiheal_operation';sheet='combat_effect';column='op';row=120;value='restore_hp';field='budget_counter_antiheal';expected=800},
        @{name='periodic_recovery_antiheal_operation';sheet='combat_effect';column='op';row=121;value='restore_hp';field='budget_dot_antiheal';expected=600},
        @{name='shield_loss_nested_owner_depth';sheet='combat_event_policy';column='C';row=76;value='0';field='shield_loss_nested_damage';expected=0},
        @{name='shield_loss_nested_recipient_depth';sheet='combat_event_policy';column='C';row=77;value='0';field='shield_loss_nested_heal';expected=0;expected_fields=@{shield_loss_deep_heal=0}},
        @{name='counter_hit_event_depth';sheet='combat_event_policy';column='C';row=7;value='0';changes=@(@{sheet='combat_effect';column='P';row=55;value='10000'});field='terminal_counter_seal';expected=1;expected_fields=@{terminal_secondary_counter_set_skipped=1}},
        @{name='opening_affix_curve';sheet='equipment_affix';column='H';row=33;value='[800,1200,2000]';field='order_opening_speed';expected=1200},
        @{name='opening_affix_duration';sheet='equipment_affix';column='J';row=33;value='3';field='order_expired_speed';expected=1160},
        @{name='opening_order_duration';sheet='equipment_affix';column='J';row=33;value='3';field='order_expired_enemy_first';expected=1},
        @{name='opening_order_disabled';sheet='combat_effect';column='J';row=70;value='0';field='order_opening_enemy_first';expected=0},
        @{name='speed_multiplier_order';sheet='combat_effect';column='C';row=69;value='20';field='order_combined_speed';expected=1306},
        @{name='speed_negative_multiplier';sheet='combat_effect';column='J';row=69;value='-10000';field='order_opening_speed';expected=840},
        @{name='speed_zero_floor';sheet='combat_effect';column='L';row=69;value='-12000';field='order_opening_speed';expected=0},
        @{name='opening_zero_duration';sheet='equipment_affix';column='J';row=33;value='0';field='order_opening_speed';expected=1000},
        @{name='opening_rage_curve';sheet='equipment_affix';column='H';row=49;value='[5,10,12]';field='rage_affix_opening';expected=10},
        @{name='opening_rage_cap';sheet='equipment_affix';column='H';row=49;value='[5,8,30]';field='rage_affix_highest_live';expected=20},
        @{name='opening_rage_repeat_budget';sheet='combat_effect';column='R';row=71;value='2';field='rage_affix_opening_repeat';expected=16},
        @{name='opening_rage_dead_owner';sheet='combat_effect';column='AH';row=71;value='0';field='rage_affix_opening';expected=0},
        @{name='cost_affix_curve';sheet='equipment_affix';column='H';row=51;value='[6,15,18]';field='rage_affix_cost';expected=25},
        @{name='cost_affix_half';sheet='combat_effect';column='J';row=72;value='-5000';field='rage_affix_cost';expected=36},
        @{name='cost_affix_dead_scope';sheet='combat_effect';column='AH';row=72;value='0';field='rage_affix_cost';expected=28},
        @{name='cost_affix_owner_scope';sheet='combat_effect';column='AG';row=72;value='owner';field='rage_affix_cost';expected=34},
        @{name='cost_affix_floor';sheet='equipment_affix';column='H';row=51;value='[6,30,36]';field='rage_affix_cost';expected=20},
        @{name='action_shield_rage_curve';sheet='equipment_affix';column='H';row=8;value='[2,3,6]';field='action_rage_shield_end';expected=6},
        @{name='action_shield_condition';sheet='combat_effect';column='T';row=73;value='[]';field='action_rage_shield_expired';expected=8},
        @{name='combo_rage_budget_one';sheet='equipment_affix';column='K';row=28;value='1';field='action_rage_combo_second';expected=4},
        @{name='combo_rage_budget_three';sheet='equipment_affix';column='K';row=28;value='3';field='action_rage_combo_capped';expected=12},
        @{name='combo_rage_unlimited';sheet='equipment_affix';column='K';row=28;value='0';field='action_rage_combo_capped';expected=12},
        @{name='combo_rage_curve';sheet='equipment_affix';column='H';row=28;value='[2,3,6]';field='action_rage_combo_first';expected=6},
        @{name='combo_segment_condition';sheet='combat_effect';column='T';row=74;value='[{"field":"segments","op":"gt","value":2}]';field='action_rage_combo_first';expected=0},
        @{name='regular_rage_budget_two';sheet='equipment_affix';column='K';row=50;value='2';field='action_rage_regular_budget';expected=8},
        @{name='regular_rage_full_turn_curve';sheet='equipment_affix';column='H';row=50;value='[2,3,6]';field='action_rage_full_turn_delta';expected=10},
        @{name='opening_inherited_battle_budget';sheet='equipment_affix';column='L';row=49;value='2';field='rage_affix_opening_repeat';expected=16},
        @{name='combo_inherited_battle_budget';sheet='equipment_affix';column='L';row=28;value='1';field='action_rage_combo_next';expected=4},
        @{name='passive_revive_source_budget';sheet='combat_rule';column='C';row=16;value='2';field='passive_revive_repeat_hp';expected=1500},
        @{name='passive_revive_target_budget';sheet='combat_rule';column='C';row=10;value='1';changes=@(@{column='C';row=16;value='2'});field='passive_revive_repeat_hp';expected=0},
        @{name='nuwa_a_heal_curve';sheet='combat_effect';column='L';row=76;value='3500';field='nuwa_a_heal';expected=810},
        @{name='nuwa_b_heal_curve';sheet='combat_effect';column='L';row=77;value='-2000';field='nuwa_b_heal';expected=480},
        @{name='nuwa_a_revive_formula';sheet='combat_effect';column='J';row=78;value='3000';field='nuwa_a_revive_hp';expected=3000},
        @{name='nuwa_b_revive_formula';sheet='combat_effect';column='J';row=79;value='4500';field='nuwa_b_revive_hp';expected=4500},
        @{name='nuwa_revive_critical_flag';sheet='combat_effect';column='L';row=80;value='1';field='nuwa_b_revive_critical';expected=1},
        @{name='nuwa_guard_curve';sheet='combat_effect';column='L';row=81;value='1200';field='nuwa_a_guard';expected=1200},
        @{name='nuwa_guard_target';sheet='combat_effect';column='G';row=81;value='self';field='nuwa_a_guard';expected=0},
        @{name='nuwa_single_revive_rage';sheet='combat_effect';column='L';row=82;value='6';field='nuwa_b_revive_rage';expected=6},
        @{name='nuwa_self_revive_team_heal';sheet='combat_effect';column='J';row=83;value='6000';field='nuwa_a_self_revive_ally';expected=1600},
        @{name='nuwa_self_revive_formula';sheet='combat_effect';column='J';row=84;value='4500';field='nuwa_b_self_revive_hp';expected=4500},
        @{name='nuwa_usefulness_threshold';sheet='combat_effect';column='T';row=86;value='[{"field":"source_team_second_hp_bp","op":"lt","value":6500}]';field='nuwa_two_injured';expected=0},
        @{name='nuwa_usefulness_mean';sheet='combat_effect';column='T';row=87;value='[{"field":"source_team_mean_missing_hp_bp","op":"ge","value":1700}]';field='nuwa_mean_below';expected=1},
        @{name='nuwa_usefulness_default';sheet='combat_effect';column='L';row=85;value='1';field='nuwa_mean_below';expected=1},
        @{name='nuwa_common_group_binding';sheet='combat_binding';column='E';row=5;value='[101]';field='nuwa_a_revive_critical';expected=1}
        @{name='overheal_affix_curve';sheet='equipment_affix';column='H';row=9;value='[1500,2200,4000]';field='nuwa_combined_shield';expected=391}
        @{name='overheal_affix_cap';sheet='equipment_affix';column='I';row=9;value='[1000,1000,1000]';field='nuwa_combined_capped';expected=2500}
        @{name='overheal_zero_item_cap';sheet='equipment_affix';column='I';row=9;value='[0,0,0]';field='nuwa_combined_capped';expected=3758}
        @{name='overheal_total_budget';sheet='equipment_affix';column='H';row=9;value='[1500,2200,20000]';field='nuwa_combined_shield';expected=653}
        @{name='overheal_public_cap';sheet='combat_rule';column='C';row=47;value='2500';field='nuwa_combined_shield';expected=163}
        @{name='overheal_zero_public_cap';sheet='combat_rule';column='C';row=47;value='0';field='nuwa_combined_shield';expected=0}
        @{name='overheal_target';sheet='combat_effect';column='G';row=88;value='self';field='nuwa_combined_shield';expected=130}
        @{name='overheal_turn_budget';sheet='equipment_affix';column='K';row=9;value='2';field='nuwa_combined_repeat';expected=326}
        @{name='overheal_cap_coefficient';sheet='combat_effect';column='N';row=88;value='5000';field='nuwa_combined_capped';expected=2500}
        @{name='overheal_cap_source';sheet='combat_effect';column='AM';row=88;value='constant';field='nuwa_combined_capped';expected=3758}
        @{name='overheal_duration';sheet='combat_effect';column='O';row=88;value='3';field='nuwa_combined_duration';expected=3}
        @{name='revive_guard_curve';sheet='equipment_affix';column='H';row=12;value='[2000,3000,3000]';field='revive_guard_first';expected=5000}
        @{name='revive_guard_duration';sheet='equipment_affix';column='J';row=12;value='3';field='revive_guard_duration';expected=3}
        @{name='revive_guard_battle_budget';sheet='equipment_affix';column='L';row=12;value='2';field='revive_guard_second';expected=6000}
        @{name='revive_guard_unlimited';sheet='equipment_affix';column='L';row=12;value='0';field='revive_guard_later_turn';expected=6000}
        @{name='revive_guard_priority';sheet='combat_effect';column='C';row=89;value='0';field='revive_guard_first_applied';expected=4000}
        @{name='revive_guard_target';sheet='combat_effect';column='G';row=89;value='self';field='revive_guard_first';expected=2000}
        @{name='thorns_curve';sheet='equipment_affix';column='H';row=18;value='[800,1200,2000]';field='thorns_first_shield';expected=100}
        @{name='thorns_cap';sheet='equipment_affix';column='I';row=18;value='[300,300,300]';field='thorns_cap';expected=300}
        @{name='thorns_duration';sheet='combat_effect';column='O';row=91;value='3';field='thorns_duration';expected=3}
        @{name='thorns_budget';sheet='equipment_affix';column='K';row=18;value='3';field='thorns_third_shield';expected=80}
        @{name='thorns_absorbed_budget';sheet='equipment_affix';column='K';row=18;value='3';field='thorns_absorbed_budget';expected=80}
        @{name='thorns_gate_condition';sheet='combat_effect';column='T';row=90;value='[{"field":"amount","op":"gt","value":0}]';field='thorns_absorbed_budget';expected=80}
        @{name='thorns_gate_link';sheet='combat_effect';column='T';row=91;value='[{"field":"gate_40140","op":"eq","value":0}]';field='thorns_first_shield';expected=0}
        @{name='overkill_curve';sheet='equipment_affix';column='H';row=23;value='[2000,3000,5000]';field='overkill_first_damage';expected=450}
        @{name='overkill_cap';sheet='equipment_affix';column='I';row=23;value='[1000,1000,1000]';field='overkill_first_damage';expected=100}
        @{name='overkill_budget';sheet='equipment_affix';column='K';row=23;value='2';field='overkill_repeated_damage';expected=720}
        @{name='overkill_no_cap';sheet='equipment_affix';column='I';row=23;value='[0,0,0]';field='overkill_first_damage';expected=360}
        @{name='overkill_target';sheet='combat_effect';column='G';row=93;value='self';field='overkill_first_damage';expected=0}
        @{name='overkill_gate_threshold';sheet='combat_effect';column='T';row=92;value='[{"field":"overkill","op":"gt","value":900}]';field='overkill_first_damage';expected=0}
        @{name='overkill_gate_link';sheet='combat_effect';column='T';row=93;value='[{"field":"gate_40190","op":"eq","value":0}]';field='overkill_first_damage';expected=0}
        @{name='overkill_empty_budget';sheet='equipment_affix';column='K';row=23;value='2';field='overkill_after_empty';expected=360}
        @{name='shield_loss_damage_curve';sheet='equipment_affix';column='H';row=5;value='[1200,1800,3000]';field='shield_loss_damage';expected=300}
        @{name='shield_loss_damage_cap';sheet='equipment_affix';column='I';row=5;value='[1000,1000,1000]';field='shield_loss_cap';expected=100}
        @{name='shield_loss_damage_budget';sheet='equipment_affix';column='K';row=5;value='2';field='shield_loss_repeat_damage';expected=480}
        @{name='shield_loss_damage_target';sheet='combat_effect';column='G';row=95;value='self';field='shield_loss_damage';expected=0}
        @{name='shield_loss_damage_gate';sheet='combat_effect';column='T';row=94;value='[{"field":"broken","op":"eq","value":0}]';field='shield_loss_damage';expected=0}
        @{name='shield_loss_heal_curve';sheet='equipment_affix';column='H';row=7;value='[200,300,600]';field='shield_loss_heal';expected=600}
        @{name='shield_loss_heal_budget';sheet='equipment_affix';column='K';row=7;value='2';field='shield_loss_repeat_heal';expected=800}
        @{name='shield_loss_heal_target';sheet='combat_effect';column='G';row=97;value='enemies';field='shield_loss_heal';expected=0}
        @{name='shield_loss_heal_gate';sheet='combat_effect';column='T';row=96;value='[{"field":"broken","op":"eq","value":0}]';field='shield_loss_heal';expected=0}
        @{name='shield_loss_heal_policy';sheet='combat_effect';column='H';row=97;value='heal';field='shield_loss_antiheal';expected=200}
        @{name='share_curve';sheet='equipment_affix';column='H';row=6;value='[1500,2200,4000]';field='share_ally_shield';expected=400}
        @{name='share_budget';sheet='equipment_affix';column='K';row=6;value='2';field='share_repeat_shield';expected=600}
        @{name='share_empty_budget';sheet='equipment_affix';column='K';row=6;value='2';field='share_after_empty';expected=300}
        @{name='share_include_self';sheet='combat_effect';column='G';row=99;value='lowest_ally';field='share_ally_shield';expected=0}
        @{name='share_fixed_duration';sheet='combat_effect';column='AN';row=99;value='constant';changes=@(@{column='O';row=99;value='5'});field='share_duration';expected=5}
        @{name='share_event_depth';sheet='combat_event_policy';column='C';row=8;value='0';field='share_nested_primary_heal';expected=150}
        @{name='share_gate_condition';sheet='combat_effect';column='T';row=98;value='[{"field":"shield_amount","op":"gt","value":1000}]';field='share_ally_shield';expected=0}
        @{name='share_gate_link';sheet='combat_effect';column='T';row=99;value='[{"field":"gate_40020","op":"eq","value":0}]';field='share_ally_shield';expected=0}
        @{name='guard_counter_curve';sheet='equipment_affix';column='H';row=13;value='[4000,6000,10000]';field='guard_real_counter';expected=1000}
        @{name='guard_counter_limit';sheet='equipment_affix';column='K';row=13;value='1';field='guard_repeat_damage';expected=800}
        @{name='guard_counter_target';sheet='combat_effect';column='G';row=102;value='self';field='guard_real_counter';expected=0}
        @{name='guard_counter_condition';sheet='combat_effect';column='T';row=100;value='[{"field":"attacker_alive","op":"eq","value":0}]';field='guard_real_counter';expected=0}
        @{name='guard_counter_budget_gate';sheet='combat_effect';column='T';row=101;value='[{"field":"gate_40090","op":"eq","value":0}]';field='guard_real_counter';expected=0}
        @{name='guard_counter_damage_gate';sheet='combat_effect';column='T';row=102;value='[{"field":"gate_40091","op":"eq","value":0}]';field='guard_real_counter';expected=0}
        @{name='unified_transfer_cap';sheet='combat_effect';column='cap_bp';row=730;value='4000';field='unified_transfer_snapshot';expected=400}
        @{name='unified_action_attribute_bonus';sheet='combat_effect';column='flat';row=737;value='1200';field='unified_action_buff';expected=1700}
        @{name='unified_landed_growth_limit';sheet='combat_effect';column='per_action';row=732;value='2';field='unified_growth_after_two';expected=0}
        @{name='unified_landed_growth_unlimited';sheet='combat_effect';column='per_action';row=732;value='0';field='unified_growth_capped';expected=100}
        @{name='unified_hp_restore_multiplier';sheet='combat_effect';column='flat';row=795;value='-2000';field='unified_hp_restore';expected=800}
        @{name='unified_revived_action_enabled';sheet='combat_rule';column='value';row=62;value='0';field='unified_revived_action_cd';expected=4}
        @{name='unified_revived_action_two_turns';sheet='combat_rule';column='value';row=62;value='2';field='unified_revived_next_cd';expected=5}
        @{name='unified_opening_branch_rage';sheet='combat_effect';column='flat';row=806;value='7';field='unified_opening_branch_rage';expected=7}
        @{name='unified_opening_branch_guard';sheet='combat_effect';column='flat';row=807;value='2400';field='unified_opening_branch_guard';expected=2400}
        @{name='unified_cleanse_success_bonus';sheet='combat_effect';column='flat';row=808;value='500';field='unified_cleanse_success_bonus';expected=500}
        @{name='unified_thorns_guard_chance';sheet='combat_effect';column='flat';row=809;value='1000';field='unified_thorns_guard_chance';expected=1000}
        @{name='unified_thorns_success_multiplier';sheet='combat_effect';column='flat';row=810;value='6000';field='unified_thorns_with_buff';expected=400}
        @{name='unified_passive_target_attempt_limit';sheet='combat_effect';column='per_turn';row=813;value='2';field='unified_passive_target_repeat';expected=1}
        @{name='unified_passive_target_cap';sheet='combat_effect';column='flat';row=819;value='1';field='unified_passive_target_cap_three';expected=1}
        @{name='unified_passive_target_action_limit';sheet='combat_effect';column='per_action';row=821;value='2';field='unified_passive_target_once_repeat';expected=1}
        @{name='unified_active_buff_tick_policy';sheet='combat_rule';column='value';row=48;value='0';field='unified_active_buff_same_action';expected=1;expected_fields=@{unified_copy_buff_same_action=2}}
        @{name='unified_shield_branch_efficiency';sheet='combat_effect';column='flat';row=823;value='5000';field='unified_shield_branch_self';expected=3675}
        @{name='unified_shield_branch_share';sheet='combat_effect';column='ratio_bp';row=824;value='1500';field='unified_shield_branch_lowest';expected=459}
        @{name='unified_vulnerability_cap';sheet='combat_rule';column='value';row=63;value='12000';field='unified_vulnerability_cap_damage';expected=2160}
        @{name='unified_buff_store_replacement';sheet='combat_effect';column='argument';row=826;value='10';field='unified_stored_buff_type';expected=10;expected_fields=@{unified_stored_buff_amount=300;unified_stored_buff_tail=0;unified_stored_buff_duration=3}}
        @{name='unified_buff_store_amount';sheet='combat_effect';column='ratio_bp';row=828;value='4000';field='unified_stored_buff_amount';expected=600;expected_fields=@{unified_stored_buff_type=9;unified_stored_buff_other_branch=10;unified_stored_buff_other_origin=10}}
        @{name='unified_opening_action_disabled';sheet='combat_effect';column='flat';row=831;value='0';field='unified_opening_action_plan';expected=0;expected_fields=@{unified_opening_action_defense=0;unified_opening_action_weakness=0;unified_opening_action_other=0}}
        @{name='unified_active_hot_multiplier';sheet='combat_effect';column='flat';row=832;value='15000';field='unified_active_hot_self';expected=900;expected_fields=@{unified_active_hot_ally=900;unified_active_hot_other_branch=600}}
        @{name='unified_periodic_extension_interval';sheet='combat_effect';column='interval_turns';row=725;value='1';field='unified_periodic_extension_gap';expected=4;expected_fields=@{unified_periodic_first_extension=3;unified_periodic_next_extension=5;unified_periodic_unapplied_slow=0;unified_periodic_applied_slow=1000}}
        @{name='unified_useful_shield_threshold';sheet='combat_effect';column='conditions';row=846;value='[{"field":"enemies_shielded","op":"ge","value":0}]';field='unified_useful_no_shield';expected=1;expected_fields=@{unified_useful_dead_shield=1;unified_useful_live_shield=1}}
        @{name='unified_useful_susceptible_threshold';sheet='combat_effect';column='conditions';row=843;value='[{"field":"enemy_susceptible_unstacked_2","op":"ge","value":2}]';field='unified_useful_two_susceptible';expected=1;expected_fields=@{unified_useful_three_susceptible=1;unified_useful_immune_marked=0}}
        @{name='unified_active_duration_override';sheet='combat_effect';column='flat';row=849;value='2';field='unified_active_duration_override';expected=2;expected_fields=@{unified_active_duration_same_action=2;unified_active_duration_expired=0;unified_active_duration_other_branch=2}}
        @{name='unified_active_parameter_reduction';sheet='combat_effect';column='flat';row=850;value='0';field='unified_active_parameter_reduction';expected=2200;expected_fields=@{unified_active_parameter_floor=200;unified_active_parameter_absent=1}}
        @{name='unified_break_restoration_ratio';sheet='combat_effect';column='ratio_bp';row=852;value='400';field='unified_break_restore';expected=400;expected_fields=@{unified_break_restore_secondary=400;unified_break_restore_antiheal=200;unified_break_restore_expiry=0;unified_break_restore_dispel=0}}
        @{name='unified_shield_legacy_policy';sheet='combat_effect';column='flat';row=851;value='1';field='unified_break_restore_legacy';expected=1}
        @{name='unified_critical_chance_cap';sheet='combat_rule';column='value';row=64;value='9000';field='unified_critical_attack_cap';expected=1;expected_fields=@{unified_critical_heal_cap=1;unified_critical_attack_damage=2200;unified_critical_rng=1}}
        @{name='unified_critical_minimum';sheet='combat_rule';column='value';row=65;value='20000';field='unified_critical_minimum';expected=2000;expected_fields=@{unified_critical_interior=2200;unified_critical_maximum=3000}}
        @{name='unified_critical_maximum';sheet='combat_rule';column='value';row=66;value='25000';field='unified_critical_maximum';expected=2500;expected_fields=@{unified_critical_interior=2200;unified_critical_minimum=1500;unified_critical_overflow_high=2147483647;unified_critical_overflow_low=-2147483648}}
        @{name='unified_owned_application_heal_ratio';sheet='combat_effect';column='ratio_bp';row=853;value='150';field='unified_owned_taunt_first';expected=600;expected_fields=@{unified_owned_taunt_repeat=0;unified_owned_taunt_next=600;unified_owned_taunt_antiheal=300;unified_owned_taunt_boss_replacement=0}}
        @{name='unified_owned_application_action_budget';sheet='combat_effect';column='per_action';row=853;value='2';field='unified_owned_taunt_first';expected=600;expected_fields=@{unified_owned_taunt_repeat=0;unified_owned_taunt_next=600;unified_owned_taunt_antiheal=300;unified_owned_taunt_full_hp_budget=0}}
        @{name='unified_counter_presence_bonus';sheet='combat_effect';column='flat';row=854;value='5000';field='unified_counter_presence_live';expected=5000;expected_fields=@{unified_counter_presence_absent=0;unified_counter_presence_dead=0;unified_counter_presence_consumed=1;unified_counter_absent_damage=0;unified_counter_dead_damage=0}}
        @{name='unified_sacrifice_cost_ratio';sheet='combat_effect';column='ratio_bp';row=855;value='1000';field='unified_sacrifice_normal_cost';expected=1000;expected_fields=@{unified_sacrifice_low_cost=99;unified_sacrifice_one_hp_cost=0;unified_sacrifice_other_cost=2000}}
        @{name='unified_sacrifice_multiplier_zero';sheet='combat_effect';column='flat';row=857;value='0';field='unified_sacrifice_multiplier';expected=0;expected_fields=@{unified_sacrifice_normal_cost=1500;unified_sacrifice_normal_damage=1}}
        @{name='unified_revive_usefulness_route';sheet='combat_effect';column='flat';row=858;value='0';field='unified_revive_scan_mode';expected=0;expected_fields=@{unified_revive_usefulness_live=1;unified_revive_usefulness_rng=1;unified_revive_strategy_rng=1}}
        @{name='unified_disabled_active_list_enabled';sheet='combat_effect';column='flat';row=859;value='1';field='unified_disabled_active_link';expected=1;expected_fields=@{unified_disabled_active_reduction=1;unified_active_link_other_branch=1}}
        @{name='unified_weapon_scope_parameter';sheet='combat_effect';column='flat';row=313;value='1000';field='unified_weapon_scope_min';expected=1000;expected_fields=@{unified_weapon_scope_max=1000;unified_weapon_scope_count=3;unified_weapon_scope_duration=2}}
        @{name='unified_weapon_scope_duration';sheet='combat_effect';column='flat';row=314;value='3';field='unified_weapon_scope_duration';expected=3;expected_fields=@{unified_weapon_scope_min=1500;unified_weapon_scope_max=1500;unified_weapon_scope_count=3}}
        @{name='unified_high_hp_critical_chance';sheet='combat_effect';column='flat';row=500;value='1000';field='unified_high_hp_critical_chance';expected=1000;expected_fields=@{unified_high_hp_critical_damage=1500;unified_boundary_critical_chance=0;unified_high_hp_critical_consumer=1}}
        @{name='unified_high_hp_critical_damage';sheet='combat_effect';column='flat';row=862;value='1000';field='unified_high_hp_critical_damage';expected=1000;expected_fields=@{unified_high_hp_critical_chance=1500;unified_boundary_critical_damage=0;unified_high_hp_critical_consumer=1}}
        @{name='unified_zero_periodic_disabled';sheet='combat_periodic';column='zero_action_parameter';row=12;value='-1';field='unified_zero_backlash_events';expected=0;expected_fields=@{unified_zero_backlash_hp_loss=0;unified_zero_first_parameter_events=0;unified_zero_periodic_default_events=0}}
        @{name='unified_zero_periodic_parameter';sheet='combat_periodic';column='zero_action_parameter';row=12;value='1';field='unified_zero_first_parameter_events';expected=1;expected_fields=@{unified_zero_backlash_events=1;unified_zero_backlash_hp_loss=0;unified_zero_periodic_default_events=0}}
        @{name='unified_resist_refund_amount';sheet='combat_effect';column='flat';row=863;value='3';field='unified_resist_refund_first';expected=3;expected_fields=@{unified_resist_refund_repeat=3;unified_resist_refund_next=6;unified_resist_refund_immune=0;unified_resist_refund_full_budget=60}}
        @{name='unified_periodic_aggregation_mode';sheet='combat_periodic';column='aggregation';row=12;value='per_source';field='unified_state_aggregate_other_sources_events';expected=2;expected_fields=@{unified_state_aggregate_duplicate_rng_match=0}}
        @{name='unified_emergency_regular_disabled';sheet='combat_strategy';column='emergency';row=8;value='0';field='unified_emergency_regular_choice';expected=0;expected_fields=@{unified_emergency_regular_plain_usefulness=0;unified_emergency_regular_healed=0;unified_emergency_regular_cooldown=0;unified_emergency_regular_boundary=0;unified_emergency_regular_other_strategy=0}}
        @{name='unified_shared_target_count';sheet='combat_rule';column='value';row=61;value='2';field='unified_link_primary';expected=333}
        @{name='unified_shared_target_selector';sheet='combat_rule';column='value';row=60;value='2';field='unified_link_lowest';expected=0}
        @{name='unified_low_water_threshold';sheet='combat_effect';column='flat';row=772;value='9001';field='unified_low_water_memory';expected=9001}
        @{name='guard_reduction_curve';sheet='equipment_affix';column='H';row=15;value='[1000,1500,3000]';field='guard_reduced_1001';expected=700}
        @{name='guard_reduction_coefficient';sheet='combat_effect';column='J';row=103;value='-5000';field='guard_reduced_1001';expected=900}
        @{name='guard_reduction_event';sheet='combat_effect';column='F';row=103;value='before_guard';field='guard_reduced_1001';expected=1001}
        @{name='break_vulnerability_curve';sheet='equipment_affix';column='H';row=30;value='[600,900,1500]';field='break_vulnerability';expected=1500}
        @{name='break_vulnerability_duration';sheet='equipment_affix';column='J';row=30;value='3';field='break_duration';expected=3}
        @{name='break_vulnerability_target';sheet='combat_effect';column='G';row=104;value='self_any';field='break_vulnerability';expected=0}
        @{name='break_vulnerability_alive_target';sheet='combat_effect';column='G';row=104;value='target';field='break_dead_target_vulnerability';expected=0}
        @{name='break_rage_curve';sheet='equipment_affix';column='H';row=32;value='[3,5,9]';field='break_rage';expected=9}
        @{name='break_rage_turn_limit';sheet='equipment_affix';column='K';row=32;value='2';field='break_repeat_rage';expected=12}
        @{name='break_rage_battle_limit';sheet='equipment_affix';column='L';row=32;value='1';field='break_next_rage';expected=7}
        @{name='break_unshare_counter';sheet='combat_effect';column='Z';row=107;value='0';field='dispel_then_break_rage';expected=12}
        @{name='break_rage_gate';sheet='combat_effect';column='T';row=106;value='[{"field":"gate_40280","op":"eq","value":0}]';field='break_rage';expected=0}
        @{name='mark_defense_curve';sheet='equipment_affix';column='H';row=42;value='[400,600,1000]';field='break_defense';expected=1000}
        @{name='mark_defense_duration';sheet='equipment_affix';column='J';row=42;value='3';field='break_defense_duration';expected=3}
        @{name='mark_buff_filter';sheet='combat_effect';column='E';row=109;value='22';field='mark_21_1';expected=0}
        @{name='mark_buff_kind';sheet='combat_effect';column='S';row=109;value='29';field='mark_21_1';expected=0}
        @{name='mark_attack_condition';sheet='combat_effect';column='T';row=109;value='[{"field":"source_attack_type","op":"eq","value":2}]';field='mark_21_1';expected=0}
        @{name='mark_emit_action';sheet='combat_effect';column='AO';row=109;value='1';field='mark_silent_actions';expected=1}
        @{name='break_emit_action';sheet='combat_effect';column='AO';row=104;value='1';field='mark_silent_actions';expected=1}
        @{name='mark_event_depth';sheet='combat_event_policy';column='C';row=10;value='1';field='break_secondary_defense';expected=0}
        @{name='break_event_depth';sheet='combat_event_policy';column='C';row=9;value='0';field='break_secondary_defense';expected=0}
        @{name='break_skill_immunity';sheet='combat_effect';column='AP';row=104;value='1';field='break_immune_vulnerability';expected=0}
        @{name='mark_skill_immunity';sheet='combat_effect';column='AP';row=109;value='1';field='break_immune_defense';expected=0}
        @{name='cleanse_affix_curve';sheet='equipment_affix';column='H';row=11;value='[600,900,1500]';field='cleanse_guard';expected=1500}
        @{name='cleanse_affix_duration';sheet='equipment_affix';column='J';row=11;value='2';field='cleanse_duration';expected=2}
        @{name='cleanse_affix_target';sheet='combat_effect';column='G';row=115;value='self_any';field='cleanse_guard';expected=0}
        @{name='cleanse_affix_event';sheet='combat_effect';column='F';row=115;value='after_enemy_dispel';field='cleanse_guard';expected=0}
        @{name='cleanse_affix_immunity';sheet='combat_effect';column='AP';row=115;value='1';field='cleanse_immune_target';expected=0}
        @{name='cleanse_affix_emit';sheet='combat_effect';column='AO';row=115;value='1';field='cleanse_actions';expected=1}
        @{name='cleanse_affix_coefficient';sheet='combat_effect';column='J';row=115;value='5000';field='cleanse_guard';expected=600}
        @{name='strip_affix_curve';sheet='equipment_affix';column='H';row=44;value='[500,750,1500]';field='strip_attack';expected=1500}
        @{name='strip_affix_duration';sheet='equipment_affix';column='J';row=44;value='3';field='strip_attack_duration';expected=3}
        @{name='strip_affix_turn_limit';sheet='equipment_affix';column='K';row=44;value='2';field='strip_repeat_count';expected=2}
        @{name='strip_affix_battle_limit';sheet='equipment_affix';column='L';row=44;value='1';field='strip_next_count';expected=1}
        @{name='strip_affix_target';sheet='combat_effect';column='G';row=117;value='target_any';field='strip_attack';expected=0}
        @{name='strip_affix_attack_gate';sheet='combat_effect';column='T';row=117;value='[{"field":"gate_40400","op":"eq","value":0}]';field='strip_attack';expected=0}
        @{name='strip_affix_speed_gate';sheet='combat_effect';column='T';row=118;value='[{"field":"gate_40400","op":"eq","value":0}]';field='strip_speed';expected=0}
        @{name='strip_affix_immunity';sheet='combat_effect';column='AP';row=117;value='1';field='strip_immune_attack';expected=0}
        @{name='strip_affix_emit';sheet='combat_effect';column='AO';row=117;value='1';field='strip_actions';expected=1}
        @{name='strip_affix_speed_coefficient';sheet='combat_effect';column='J';row=118;value='5000';field='strip_speed';expected=500}
        @{name='strip_affix_counter_independence';sheet='combat_effect';column='Z';row=116;value='40280';field='strip_with_rage_attack';expected=0}
        @{name='amount_budget_taunt_curve';sheet='equipment_affix';column='H';row=14;value='[200,300,600]';field='budget_taunt_first';expected=600}
        @{name='amount_budget_taunt_cap';sheet='equipment_affix';column='I';row=14;value='[1000,1000,1000]';field='budget_taunt_repeat';expected=1000}
        @{name='amount_budget_taunt_zero_cap';sheet='equipment_affix';column='I';row=14;value='[0,0,0]';field='budget_taunt_first';expected=0}
        @{name='amount_budget_taunt_none';sheet='combat_effect';column='AQ';row=119;value='none';field='budget_taunt_repeat';expected=1200}
        @{name='amount_budget_shared_targets';sheet='combat_effect';column='G';row=119;value='allies';field='budget_taunt_friend_heal';expected=400;expected_fields=@{budget_taunt_full_spent=800;budget_taunt_first=400}}
        @{name='amount_budget_rejected_probability';sheet='combat_effect';column='P';row=119;value='0';field='budget_taunt_full_spent';expected=0}
        @{name='amount_budget_taunt_heal_policy';sheet='combat_effect';column='H';row=119;value='heal';field='budget_taunt_antiheal';expected=0}
        @{name='amount_budget_taunt_alive_source';sheet='combat_effect';column='AH';row=119;value='1';field='budget_taunt_dead_restore';expected=0}
        @{name='amount_budget_counter_curve';sheet='equipment_affix';column='H';row=17;value='[800,1200,400]';field='budget_counter_first';expected=400}
        @{name='amount_budget_counter_cap';sheet='equipment_affix';column='I';row=17;value='[1000,1000,1000]';field='budget_counter_first';expected=1000}
        @{name='amount_budget_counter_zero_cap';sheet='equipment_affix';column='I';row=17;value='[0,0,0]';field='budget_counter_first';expected=0}
        @{name='amount_budget_counter_none';sheet='combat_effect';column='AQ';row=120;value='none';field='budget_counter_repeat';expected=1600}
        @{name='amount_budget_counter_heal_policy';sheet='combat_effect';column='H';row=120;value='heal';field='budget_counter_antiheal';expected=0}
        @{name='amount_budget_counter_alive_target';sheet='combat_effect';column='G';row=120;value='self';field='budget_counter_dead_restore';expected=0}
        @{name='amount_budget_counter_coefficient';sheet='combat_effect';column='cap_bp';row=120;value='5000';field='budget_counter_first';expected=400}
        @{name='amount_budget_dot_curve';sheet='equipment_affix';column='H';row=40;value='[300,450,300]';field='budget_dot_first';expected=300}
        @{name='amount_budget_dot_cap';sheet='equipment_affix';column='I';row=40;value='[1000,1000,1000]';field='budget_dot_repeat';expected=1000}
        @{name='amount_budget_dot_zero_cap';sheet='equipment_affix';column='I';row=40;value='[0,0,0]';field='budget_dot_first';expected=0}
        @{name='amount_budget_dot_none';sheet='combat_effect';column='AQ';row=121;value='none';field='budget_dot_repeat';expected=1200}
        @{name='amount_budget_dot_heal_policy';sheet='combat_effect';column='H';row=121;value='heal';field='budget_dot_antiheal';expected=0}
        @{name='amount_budget_dot_dead_source';sheet='combat_effect';column='G';row=121;value='self_any';changes=@(@{column='AH';row=121;value='0'});field='budget_dot_dead_restore';expected=600}
        @{name='amount_budget_counter_depth';sheet='combat_event_policy';column='C';row=13;value='0';field='budget_counter_natural';expected=0;expected_fields=@{budget_counter_natural_extra=1}}
        @{name='amount_budget_dot_depth';sheet='combat_event_policy';column='C';row=14;value='0';field='budget_dot_secondary_native';expected=0}
        @{name='chance_counter_zero';sheet='combat_effect';column='probability_bp';row=123;value='0';field='chance_15_first';expected=0;expected_fields=@{chance_15_rng=1;chance_15_failed_attempts=1;chance_counter_native_rng=1}}
        @{name='chance_counter_certain';sheet='combat_effect';column='probability_source';row=123;value='constant';field='chance_15_failed';expected=1;expected_fields=@{chance_15_rng=1;chance_15_failed_retry=1;chance_counter_native_rng=1}}
        @{name='chance_counter_curve_zero';sheet='equipment_affix';column='H';row=19;value='[0,0,0]';field='chance_15_first';expected=0;expected_fields=@{chance_15_rng=1}}
        @{name='chance_counter_second_curve';sheet='combat_effect';column='probability_source';row=123;value='affix_value2';field='chance_15_first';expected=0;expected_fields=@{chance_15_rng=1}}
        @{name='chance_scaled_curve_boundary';sheet='equipment_affix';column='H';row=19;value='[20000,20000,20000]';changes=@(@{sheet='combat_effect';column='probability_bp';row=123;value='5000'});field='chance_15_failed';expected=1;expected_fields=@{chance_15_rng=1}}
        @{name='chance_counter_value';sheet='equipment_affix';column='I';row=19;value='[2,2,2]';field='chance_15_first';expected=2;expected_fields=@{chance_15_tactic=0}}
        @{name='chance_counter_zero_value';sheet='equipment_affix';column='I';row=19;value='[0,0,0]';field='chance_15_first';expected=0;expected_fields=@{chance_15_rng=1;chance_15_failed_attempts=1}}
        @{name='chance_counter_two_attempts';sheet='combat_effect';column='per_turn';row=122;value='2';field='chance_15_failed_retry';expected=1;expected_fields=@{chance_15_failed_attempts=1}}
        @{name='chance_counter_tactic';sheet='combat_effect';column='argument_role';row=124;value='tactic';field='chance_15_tactic';expected=1;expected_fields=@{chance_15_first=0}}
        @{name='chance_counter_alive_target';sheet='combat_effect';column='target';row=122;value='self';field='chance_15_dead';expected=0}
        @{name='chance_counter_depth';sheet='combat_event_policy';column='C';row=15;value='0';field='chance_counter_native';expected=0;expected_fields=@{chance_counter_native_extra=1;chance_counter_native_rng=0}}
        @{name='chance_kill_zero';sheet='equipment_affix';column='H';row=24;value='[0,0,0]';field='chance_20_first';expected=0;expected_fields=@{chance_20_rng=1;chance_kill_native_delta=0;chance_kill_summon_delta=0}}
        @{name='chance_kill_value';sheet='equipment_affix';column='I';row=24;value='[2,2,2]';field='chance_20_first';expected=2;expected_fields=@{chance_20_tactic=2;chance_kill_native_delta=2}}
        @{name='chance_kill_coefficient';sheet='combat_effect';column='probability_bp';row=126;value='5000';field='chance_20_failed';expected=0;expected_fields=@{chance_20_rng=1}}
        @{name='chance_kill_regular_only';sheet='combat_effect';column='argument_role';row=127;value='regular';field='chance_20_tactic';expected=0;expected_fields=@{chance_20_first=1}}
        @{name='chance_kill_zero_value';sheet='equipment_affix';column='I';row=24;value='[0,0,0]';field='chance_20_first';expected=0;expected_fields=@{chance_20_rng=1}}
        @{name='chance_control_zero';sheet='combat_effect';column='probability_bp';row=129;value='0';field='chance_31_first';expected=0;expected_fields=@{chance_31_rng=1;chance_31_failed_attempts=1;chance_control_native=0;chance_control_native_attempts=1;chance_control_native_buff=0}}
        @{name='chance_control_certain';sheet='combat_effect';column='probability_source';row=129;value='constant';field='chance_31_failed';expected=8;expected_fields=@{chance_31_rng=1;chance_31_failed_retry=8;chance_control_native=8;chance_control_native_attempts=1;chance_control_native_buff=0}}
        @{name='chance_control_value';sheet='equipment_affix';column='I';row=35;value='[3,5,7]';field='chance_31_first';expected=7}
        @{name='chance_control_zero_value';sheet='equipment_affix';column='I';row=35;value='[0,0,0]';field='chance_31_first';expected=0;expected_fields=@{chance_31_rng=1}}
        @{name='chance_control_depth';sheet='combat_event_policy';column='C';row=16;value='0';field='chance_31_secondary';expected=0}
        @{name='chance_control_battle_limit';sheet='combat_effect';column='per_battle';row=128;value='1';field='chance_31_next';expected=8}
        @{name='death_guard_curve';sheet='equipment_affix';column='H';row=45;value='[800,1200,2000]';field='death_guard_first';expected=2000;expected_fields=@{death_guard_native=2000}}
        @{name='death_guard_turns';sheet='equipment_affix';column='J';row=45;value='3';field='death_guard_duration';expected=3}
        @{name='death_guard_owner_target';sheet='combat_effect';column='target';row=132;value='self_any';field='death_guard_self';expected=1600;expected_fields=@{death_guard_first=0;death_guard_alive_self=1600}}
        @{name='death_guard_all_allies';sheet='combat_effect';column='target';row=132;value='allies';field='death_guard_alive_self';expected=1600;expected_fields=@{death_guard_first=1600}}
        @{name='death_guard_unlimited';sheet='combat_effect';column='per_battle';row=131;value='0';field='death_guard_repeat';expected=3200;expected_fields=@{death_guard_after_empty=1600}}
        @{name='death_guard_silent';sheet='combat_effect';column='emit_action';row=132;value='1';field='death_guard_actions';expected=1}
        @{name='death_guard_depth';sheet='combat_event_policy';column='C';row=17;value='0';field='death_guard_secondary';expected=0;expected_fields=@{death_stack_secondary=500}}
        @{name='death_stack_curve';sheet='equipment_affix';column='H';row=46;value='[300,400,700]';field='death_stack_friend';expected=700;expected_fields=@{death_stack_enemy=700;death_stack_capped=3500;death_stack_native=700}}
        @{name='death_stack_cap';sheet='equipment_affix';column='I';row=46;value='[2,2,2]';field='death_stack_capped';expected=1000;expected_fields=@{death_stack_count=2;death_stack_after_clear=500}}
        @{name='death_stack_zero_cap';sheet='equipment_affix';column='I';row=46;value='[0,0,0]';field='death_stack_count';expected=0;expected_fields=@{death_stack_friend=0;death_stack_capped=0}}
        @{name='death_stack_zero_value';sheet='equipment_affix';column='H';row=46;value='[0,0,0]';field='death_stack_count';expected=5;expected_fields=@{death_stack_friend=0;death_stack_capped=0}}
        @{name='death_stack_summon_condition';sheet='combat_effect';column='conditions';row=133;value='[{"field":"effect_battle_count","op":"lt","value":0,"value_field":"affix_value2"}]';field='death_stack_summoned';expected=500;expected_fields=@{death_stack_summoned_count=1}}
        @{name='death_stack_depth';sheet='combat_event_policy';column='C';row=18;value='0';field='death_stack_secondary';expected=0;expected_fields=@{death_guard_secondary=1600}}
        @{name='death_stack_battle_budget';sheet='combat_effect';column='per_battle';row=133;value='1';field='death_stack_capped';expected=500;expected_fields=@{death_stack_count=1;death_stack_after_clear=0}}
        @{name='removed_affix_curve';sheet='equipment_affix';column='H';row=38;value='[2000,3000,5000]';field='removed_burn_first';expected=1500;expected_fields=@{removed_burn_clear_native=1500;removed_burn_expire_native=500}}
        @{name='removed_affix_cap';sheet='equipment_affix';column='I';row=38;value='[4000,4000,4000]';field='removed_burn_capped';expected=4000}
        @{name='removed_affix_no_cap';sheet='equipment_affix';column='I';row=38;value='[0,0,0]';field='removed_burn_capped';expected=12000}
        @{name='removed_affix_growth';sheet='combat_effect';column='growth_bp';row=134;value='0';field='removed_burn_first';expected=400;expected_fields=@{removed_burn_clear_native=400;removed_burn_expired=400}}
        @{name='removed_affix_growth_basis';sheet='combat_effect';column='growth_basis';row=134;value='one';field='removed_burn_first';expected=400}
        @{name='removed_affix_filter';sheet='combat_effect';column='buff_id';row=134;value='9';field='removed_burn_first';expected=0;expected_fields=@{removed_other_buff=1200}}
        @{name='removed_affix_alive_target';sheet='combat_effect';column='target';row=134;value='target';field='removed_dead_shield_left';expected=2000;expected_fields=@{removed_dead_shield_actions=0}}
        @{name='removed_affix_self_target';sheet='combat_effect';column='target';row=134;value='self_any';field='removed_burn_first';expected=0}
        @{name='removed_affix_frequency';sheet='combat_effect';column='per_turn';row=134;value='1';field='removed_burn_repeat';expected=1200}
        @{name='removed_affix_depth';sheet='combat_event_policy';column='C';row=19;value='0';field='removed_burn_secondary';expected=0}
        @{name='removed_affix_presentation';sheet='combat_effect';column='presentation_skill';row=134;value='5010';field='removed_burn_presentation';expected=5010}
        @{name='antiheal_affix_curve';sheet='equipment_affix';column='H';row=41;value='[500,800,1400]';field='antiheal_slow_native';expected=1400;expected_fields=@{antiheal_slow_next=2800}}
        @{name='antiheal_affix_duration';sheet='combat_effect';column='duration';row=136;value='2';field='antiheal_slow_duration';expected=2}
        @{name='antiheal_affix_unlimited';sheet='combat_effect';column='per_turn';row=135;value='0';field='antiheal_slow_repeat';expected=2000;expected_fields=@{antiheal_slow_next=3000}}
        @{name='antiheal_affix_battle_limit';sheet='combat_effect';column='per_battle';row=135;value='1';field='antiheal_slow_next';expected=1000}
        @{name='antiheal_affix_target';sheet='combat_effect';column='target';row=136;value='self_any';field='antiheal_slow_native';expected=0;expected_fields=@{antiheal_slow_owner=1000}}
        @{name='antiheal_affix_emit';sheet='combat_effect';column='emit_action';row=136;value='1';field='antiheal_slow_actions';expected=2}
        @{name='antiheal_affix_gate_condition';sheet='combat_effect';column='conditions';row=136;value='[{"field":"gate_40370","op":"eq","value":0}]';field='antiheal_slow_native';expected=0}
        @{name='antiheal_affix_status_filter';sheet='combat_effect';column='buff_id';row=135;value='40';field='antiheal_slow_native';expected=0}
        @{name='antiheal_affix_alive_source';sheet='combat_effect';column='affix_alive_only';row=135;value='1';changes=@(@{column='affix_alive_only';row=136;value='1'});field='antiheal_slow_dead_source';expected=0}
        @{name='antiheal_affix_depth';sheet='combat_event_policy';column='C';row=20;value='0';field='antiheal_slow_secondary';expected=0}
        @{name='summon_affix_attack_curve';sheet='equipment_affix';column='H';row=47;value='[2000,3000,4000]';field='summon_affix_attack';expected=1400;expected_fields=@{summon_affix_enemy_attack=1300}}
        @{name='summon_affix_hp_curve';sheet='equipment_affix';column='I';row=47;value='[1000,2000,3000]';field='summon_affix_max_hp';expected=13000;expected_fields=@{summon_affix_hp=8000;summon_affix_enemy_max_hp=12000}}
        @{name='summon_affix_attack_nonmonotonic';sheet='equipment_affix';column='H';row=47;value='[3000,1800,2400]';field='summon_affix_attack';expected=1300;expected_fields=@{summon_affix_max_hp=11600}}
        @{name='summon_affix_hp_nonmonotonic';sheet='equipment_affix';column='I';row=47;value='[3000,1200,1600]';field='summon_affix_max_hp';expected=13000;expected_fields=@{summon_affix_attack=1240;summon_affix_hp=8000}}
        @{name='summon_affix_hp_scope_by_attack';sheet='equipment_affix';column='I';row=47;value='[3000,1200,1600]';changes=@(@{sheet='combat_effect';column='affix_scope';row=138;value='team_highest'});field='summon_affix_max_hp';expected=11600;expected_fields=@{summon_affix_hp=6600}}
        @{name='summon_affix_attack_owner';sheet='combat_effect';column='affix_scope';row=137;value='owner';field='summon_affix_attack';expected=1000;expected_fields=@{summon_affix_max_hp=11600}}
        @{name='summon_affix_hp_owner';sheet='combat_effect';column='affix_scope';row=138;value='owner';field='summon_affix_max_hp';expected=10000;expected_fields=@{summon_affix_attack=1240;summon_affix_hp=5000}}
        @{name='summon_affix_attack_alive';sheet='combat_effect';column='affix_alive_only';row=137;value='1';field='summon_affix_dead_attack';expected=1120;expected_fields=@{summon_affix_dead_hp=11600}}
        @{name='summon_affix_hp_alive';sheet='combat_effect';column='affix_alive_only';row=138;value='1';field='summon_affix_dead_hp';expected=10800;expected_fields=@{summon_affix_dead_attack=1240}}
        @{name='summon_affix_zero_attack';sheet='equipment_affix';column='H';row=47;value='[0,0,0]';field='summon_affix_attack';expected=1000;expected_fields=@{summon_affix_max_hp=11600;summon_affix_flag=1;summon_affix_rng=1}}
        @{name='summon_affix_zero_hp';sheet='equipment_affix';column='I';row=47;value='[0,0,0]';field='summon_affix_max_hp';expected=10000;expected_fields=@{summon_affix_hp=5000;summon_affix_attack=1240}}
        @{name='summon_affix_attack_coefficient';sheet='combat_effect';column='ratio_bp';row=137;value='5000';field='summon_affix_attack';expected=1120;expected_fields=@{summon_affix_round_attack=1121}}
        @{name='summon_affix_hp_coefficient';sheet='combat_effect';column='ratio_bp';row=138;value='5000';field='summon_affix_max_hp';expected=10800;expected_fields=@{summon_affix_hp=5800}}
        @{name='summon_affix_marker_condition';sheet='combat_effect';column='conditions';row=137;value='[{"field":"source_summoned","op":"eq","value":0}]';field='summon_affix_attack';expected=1000;expected_fields=@{summon_affix_flag=1}}
        @{name='duration_chance_control_zero';sheet='equipment_affix';column='H';row=34;value='[0,0,0]';field='duration_control_first';expected=3;expected_fields=@{duration_control_rng=1}}
        @{name='duration_chance_control_certain';sheet='equipment_affix';column='H';row=34;value='[10000,10000,10000]';field='duration_control_failed';expected=4;expected_fields=@{duration_control_rng=1;duration_control_rejected_rng=1}}
        @{name='duration_chance_control_switch_zero';sheet='equipment_affix';column='I';row=34;value='[0,0,0]';field='duration_control_first';expected=3;expected_fields=@{duration_control_rng=1;duration_control_wrap=255}}
        @{name='duration_chance_control_switch_large';sheet='equipment_affix';column='I';row=34;value='[5000,5000,5000]';field='duration_control_first';expected=4;expected_fields=@{duration_control_rng=1}}
        @{name='duration_chance_control_addition';sheet='combat_effect';column='flat';row=140;value='2';field='duration_control_first';expected=5;expected_fields=@{duration_control_second=4;duration_control_wrap=1}}
        @{name='duration_chance_control_zero_addition';sheet='combat_effect';column='flat';row=140;value='0';field='duration_control_first';expected=3;expected_fields=@{duration_control_rng=1;duration_control_wrap=255}}
        @{name='duration_chance_control_depth';sheet='combat_event_policy';column='C';row=21;value='0';field='duration_control_secondary';expected=3}
        @{name='duration_chance_control_alive';sheet='combat_effect';column='affix_alive_only';row=139;value='1';changes=@(@{column='affix_alive_only';row=140;value='1'});field='duration_control_dead_source';expected=3}
        @{name='duration_chance_control_classification';sheet='combat_effect';column='conditions';row=139;value='[{"field":"hard_control","op":"eq","value":0}]';field='duration_control_first';expected=3;expected_fields=@{duration_control_nonhard=4;duration_control_boss=2}}
        @{name='duration_chance_forbid_zero';sheet='equipment_affix';column='H';row=48;value='[0,0,0]';field='duration_forbid_first';expected=5;expected_fields=@{duration_forbid_count=0;duration_forbid_rng=1;duration_forbid_native=5;duration_forbid_native_count=0}}
        @{name='duration_chance_forbid_certain';sheet='equipment_affix';column='H';row=48;value='[10000,10000,10000]';field='duration_forbid_failed';expected=6;expected_fields=@{duration_forbid_failed_count=1;duration_forbid_retry=6;duration_forbid_rng=1;duration_forbid_native=6;duration_forbid_native_count=1}}
        @{name='duration_chance_forbid_amount';sheet='equipment_affix';column='I';row=48;value='[2,2,2]';field='duration_forbid_first';expected=7;expected_fields=@{duration_forbid_first_instance=5;duration_forbid_other_target=4;duration_forbid_wrap=257}}
        @{name='duration_chance_forbid_zero_amount';sheet='equipment_affix';column='I';row=48;value='[0,0,0]';field='duration_forbid_first';expected=5;expected_fields=@{duration_forbid_count=1;duration_forbid_rng=1;duration_forbid_repeat=5}}
        @{name='duration_chance_forbid_two_successes';sheet='combat_effect';column='per_battle';row=141;value='2';field='duration_forbid_repeat';expected=7;expected_fields=@{duration_forbid_next_turn=7}}
        @{name='duration_chance_forbid_target_count_fact';sheet='combat_effect';column='basis';row=142;value='gate_count_40440';changes=@(@{column='per_battle';row=141;value='2'});field='duration_forbid_first';expected=6;expected_fields=@{duration_forbid_repeat=8}}
        @{name='duration_chance_forbid_alive_target';sheet='combat_effect';column='target';row=141;value='target';field='duration_forbid_dead_target';expected=5}
        @{name='duration_chance_forbid_other_buff';sheet='combat_effect';column='argument';row=142;value='44';field='duration_forbid_first';expected=5;expected_fields=@{duration_forbid_count=1}}
        @{name='duration_chance_forbid_status_condition';sheet='combat_effect';column='conditions';row=141;value='[{"field":"target_buff_44","op":"eq","value":1}]';field='duration_forbid_first';expected=5;expected_fields=@{duration_forbid_count=0}}
        @{name='duration_chance_forbid_depth';sheet='combat_event_policy';column='C';row=22;value='0';field='duration_forbid_secondary';expected=5}
        @{name='duration_chance_forbid_alive_source';sheet='combat_effect';column='affix_alive_only';row=141;value='1';changes=@(@{column='affix_alive_only';row=142;value='1'});field='duration_forbid_dead_source';expected=5}
        @{name='payload_brave_curve';sheet='equipment_affix';column='H';row=20;value='[800,1200,2000]';field='payload_brave_first';expected=2000;expected_fields=@{payload_brave_second=2000;payload_brave_immediate_thorns=400}}
        @{name='payload_brave_threshold_low';sheet='equipment_affix';column='I';row=20;value='[1000,1000,1000]';field='payload_brave_below_threshold';expected=1600}
        @{name='payload_brave_threshold_high';sheet='equipment_affix';column='I';row=20;value='[3000,3000,3000]';field='payload_brave_first';expected=0}
        @{name='payload_brave_turns';sheet='equipment_affix';column='J';row=20;value='3';field='payload_brave_duration';expected=3}
        @{name='payload_brave_single_parameter';sheet='combat_effect';column='parameter_count';row=143;value='1';field='payload_brave_second';expected=0;expected_fields=@{payload_brave_first=1600;payload_brave_count=1;payload_brave_immediate_thorns=1}}
        @{name='payload_brave_four_parameters';sheet='combat_effect';column='parameter_count';row=143;value='4';field='payload_brave_count';expected=4;expected_fields=@{payload_brave_second=1600}}
        @{name='payload_brave_inherit_level';sheet='combat_effect';column='origin_level';row=143;value='0';field='payload_brave_level';expected=7}
        @{name='payload_old_affix_inherit_level';sheet='combat_effect';column='origin_level';row=109;value='0';field='payload_raw_origin_level';expected=9}
        @{name='payload_brave_emit';sheet='combat_effect';column='emit_action';row=143;value='1';field='payload_brave_actions';expected=1}
        @{name='payload_brave_depth';sheet='combat_event_policy';column='C';row=23;value='0';field='payload_brave_counter';expected=0}
        @{name='payload_brave_frequency';sheet='combat_effect';column='per_turn';row=143;value='1';field='payload_brave_repeat';expected=1600}
        @{name='payload_spread_zero_probability';sheet='equipment_affix';column='H';row=37;value='[0,0,0]';field='payload_spread_copy';expected=0;expected_fields=@{payload_spread_attempts=1;payload_spread_rng=1}}
        @{name='payload_spread_certain';sheet='equipment_affix';column='H';row=37;value='[10000,10000,10000]';field='payload_spread_failed';expected=1;expected_fields=@{payload_spread_failed_attempts=1;payload_spread_failed_retry=1;payload_spread_rng=1}}
        @{name='payload_spread_threshold_low';sheet='equipment_affix';column='I';row=37;value='[2,2,2]';field='payload_spread_below_threshold';expected=1;expected_fields=@{payload_spread_below_attempts=1}}
        @{name='payload_spread_threshold_high';sheet='equipment_affix';column='I';row=37;value='[4,4,4]';field='payload_spread_copy';expected=0;expected_fields=@{payload_spread_attempts=0}}
        @{name='payload_spread_two_attempts';sheet='combat_effect';column='per_turn';row=144;value='2';field='payload_spread_repeat_third';expected=1}
        @{name='payload_spread_unlimited';sheet='combat_effect';column='per_turn';row=144;value='0';field='payload_spread_after_empty';expected=1}
        @{name='payload_spread_other_family';sheet='combat_effect';column='conditions';row=144;value='[{"field":"event_stack_group","op":"eq","value":11},{"field":"event_stack_count","op":"ge","value":0,"value_field":"affix_value2"}]';field='payload_spread_wrong_family';expected=1;expected_fields=@{payload_spread_copy=0;payload_spread_wrong_family_attempts=1}}
        @{name='payload_spread_self_target';sheet='combat_effect';column='target';row=146;value='self_any';field='payload_spread_copy';expected=0;expected_fields=@{payload_spread_attempts=1}}
        @{name='payload_spread_duration_cap';sheet='combat_rule';column='C';row=8;value='2';field='payload_spread_duration';expected=2}
        @{name='payload_spread_inherit_level';sheet='combat_effect';column='origin_level';row=146;value='0';field='payload_spread_origin_level';expected=7}
        @{name='payload_spread_fixed_level';sheet='combat_effect';column='origin_level';row=146;value='4';field='payload_spread_origin_level';expected=4}
        @{name='payload_spread_skill_immunity';sheet='combat_effect';column='check_skill_immunity';row=146;value='1';field='payload_spread_immunity';expected=0}
        @{name='payload_spread_emit';sheet='combat_effect';column='emit_action';row=146;value='1';field='payload_spread_actions';expected=1}
        @{name='state_affix_critical_curve';sheet='equipment_affix';column='H';row=22;value='[500,700,1000]';field='state_critical_first';expected=1000;expected_fields=@{state_critical_second=2000;state_critical_cap=3000}}
        @{name='state_affix_critical_cap_two';sheet='equipment_affix';column='I';row=22;value='[2,2,2]';field='state_critical_cap';expected=1600;expected_fields=@{state_critical_count=2}}
        @{name='state_affix_critical_cap_zero';sheet='equipment_affix';column='I';row=22;value='[0,0,0]';field='state_critical_cap';expected=0;expected_fields=@{state_critical_count=0}}
        @{name='state_affix_critical_coefficient';sheet='combat_effect';column='ratio_bp';row=149;value='5000';changes=@(@{column='growth_bp';row=149;value='5000'});field='state_critical_first';expected=400;expected_fields=@{state_critical_cap=1200}}
        @{name='state_affix_critical_reset_other_record';sheet='combat_effect';column='argument';row=148;value='40232';field='state_critical_reset';expected=2400;expected_fields=@{state_critical_reset_count=3}}
        @{name='state_affix_critical_counter_depth';sheet='combat_event_policy';column='C';row=24;value='0';field='state_critical_counter';expected=0}
        @{name='state_affix_kill_curve';sheet='equipment_affix';column='H';row=27;value='[1000,2000,5000]';field='state_kill_native_damage';expected=1500}
        @{name='state_affix_kill_duration_zero';sheet='equipment_affix';column='J';row=27;value='0';field='state_kill_next_turn_damage';expected=1000;expected_fields=@{state_kill_next_turn_consumed=1}}
        @{name='state_affix_kill_duration_two';sheet='equipment_affix';column='J';row=27;value='2';field='state_kill_expired_damage';expected=1300;expected_fields=@{state_kill_expired_pending=0}}
        @{name='state_affix_kill_unlimited';sheet='combat_effect';column='per_turn';row=150;value='0';field='state_kill_same_turn_rearm';expected=1;expected_fields=@{state_kill_same_turn_attempts=2};description_affix=23;description_contains='每回合触发次数不限'}
        @{name='state_affix_kill_zero_amount';sheet='equipment_affix';column='H';row=27;value='[0,0,0]';field='state_kill_native_damage';expected=1000;expected_fields=@{state_kill_native_consumed=0;state_kill_native_attempts=1}}
        @{name='state_affix_kill_depth';sheet='combat_event_policy';column='C';row=25;value='0';field='state_kill_secondary_damage';expected=1000;expected_fields=@{state_kill_secondary_pending=1}}
        @{name='state_affix_kill_coefficient';sheet='combat_effect';column='ratio_bp';row=154;value='5000';field='state_kill_native_damage';expected=1150}
        @{name='nuwa_origin_revive_fixed_skill';sheet='combat_effect';column='origin_skill';row=6;value='101';field='nuwa_origin_revive_guard_skill';expected=101}
        @{name='nuwa_origin_revive_follow_display';sheet='combat_effect';column='origin_skill';row=6;value='-1';changes=@(@{column='presentation_skill';row=6;value='102'});field='nuwa_origin_revive_guard_skill';expected=102}
        @{name='nuwa_origin_revive_inherit_level';sheet='combat_effect';column='origin_level';row=6;value='0';field='nuwa_origin_revive_guard_level';expected=7}
        @{name='nuwa_origin_revive_fixed_level';sheet='combat_effect';column='origin_level';row=6;value='9';field='nuwa_origin_revive_guard_level';expected=9}
        @{name='nuwa_origin_revive_skill_filter';sheet='combat_effect';column='check_skill_immunity';row=6;value='1';field='nuwa_origin_revive_guard_amount';expected=0}
        @{name='nuwa_origin_revive_emit';sheet='combat_effect';column='emit_action';row=6;value='1';field='nuwa_origin_revive_actions';expected=1}
        @{name='nuwa_origin_heal_guard_fixed_skill';sheet='combat_effect';column='origin_skill';row=81;value='102';field='nuwa_origin_heal_guard_skill';expected=102}
        @{name='nuwa_origin_heal_guard_inherit_level';sheet='combat_effect';column='origin_level';row=81;value='0';field='nuwa_origin_heal_guard_level';expected=7}
        @{name='nuwa_origin_heal_guard_skill_filter';sheet='combat_effect';column='check_skill_immunity';row=81;value='1';field='nuwa_origin_heal_guard_amount';expected=0}
        @{name='nuwa_origin_merged_shield_skill';sheet='combat_effect';column='origin_skill';row=5;value='101';changes=@(@{column='origin_skill';row=88;value='101'});field='nuwa_origin_merged_shield_skill';expected=101;expected_fields=@{nuwa_origin_shield_display=101}}
        @{name='nuwa_origin_merged_shield_level';sheet='combat_effect';column='origin_level';row=5;value='5';changes=@(@{column='origin_level';row=88;value='5'});field='nuwa_origin_merged_shield_level';expected=5}
        @{name='revive_record_relaxed_public';sheet='combat_rule';column='C';row=16;value='2';field='revive_record_a_public_eligible';expected=1;expected_fields=@{revive_record_a_skill_eligible=0;revive_record_b_skill_eligible=0;revive_record_a_targets=0;revive_record_a_useful=0;revive_record_a_repeat_ai_skill=0;revive_record_a_repeat_hp=0;revive_record_b_repeat_hp=0}}
        @{name='revive_record_limit_two';sheet='combat_effect';column='conditions';row=157;value='[{"field":"target_counter_count_1017","op":"ge","value":2}]';changes=@(@{sheet='combat_rule';column='C';row=16;value='2'});field='revive_record_a_repeat_hp';expected=2500;expected_fields=@{revive_record_b_repeat_hp=4000;revive_record_a_repeat_count=2;revive_record_a_targets=1;revive_record_a_useful=1;revive_record_a_repeat_ai_skill=102}}
        @{name='revive_record_allow_flag';sheet='combat_effect';column='flat';row=157;value='1';changes=@(@{sheet='combat_rule';column='C';row=16;value='2'});field='revive_record_a_query';expected=1;expected_fields=@{revive_record_a_repeat_hp=2500;revive_record_b_repeat_hp=4000}}
        @{name='revive_record_other_skill_record';sheet='combat_effect';column='skill_id';row=156;value='101';changes=@(@{sheet='combat_rule';column='C';row=16;value='2'});field='revive_record_a_first_count';expected=0;expected_fields=@{revive_record_a_repeat_hp=2500;revive_record_a_repeat_count=0}}
        @{name='revive_record_other_skill_query';sheet='combat_effect';column='skill_id';row=157;value='104';changes=@(@{sheet='combat_rule';column='C';row=16;value='2'});field='revive_record_a_other_skill_query';expected=0;expected_fields=@{revive_record_a_repeat_hp=2500}}
        @{name='revive_record_target_age';sheet='combat_effect';column='conditions';row=157;value='[{"field":"target_counter_count_1017","op":"ge","value":1},{"field":"target_counter_age_1017","op":"le","value":0}]';field='revive_record_a_next_turn_query';expected=1;expected_fields=@{revive_record_a_query=0;revive_record_b_next_turn_query=1}}
        @{name='revive_record_counter_alias';sheet='combat_effect';column='counter_key';row=156;value='501017';field='revive_record_a_first_count';expected=0;expected_fields=@{revive_record_a_query=0;revive_record_b_query=0;revive_record_a_repeat_hp=0}}
        @{name='inline_shield_emit';sheet='combat_effect';column='emit_action';row=5;value='1';changes=@(@{column='emit_action';row=88;value='1'});field='nuwa_origin_merged_extra_actions';expected=3;expected_fields=@{nuwa_origin_shield_display=0}}
        @{name='target_policy_heal_attack';sheet='combat_target_policy';column='order';row=5;value='highest_attack';field='target_policy_heal_first';expected=3;expected_fields=@{target_policy_heal_rng=1}}
        @{name='target_policy_guard_hp';sheet='combat_target_policy';column='order';row=6;value='lowest_hp';field='target_policy_guard_order';expected=231}
        @{name='target_policy_attack_tie';sheet='combat_target_policy';column='tie_break';row=7;value='position_desc';field='target_policy_attack_first';expected_from='target_policy_dot_regular'}
        @{name='target_policy_burst_tie';sheet='combat_target_policy';column='tie_break';row=8;value='position_desc';field='target_policy_burst_first';expected_from='target_policy_dot_regular'}
        @{name='target_policy_burst_attack';sheet='combat_target_policy';column='order';row=8;value='highest_attack';changes=@(@{column='tie_break';row=8;value='position_desc'});field='target_policy_burst_first';expected_from='target_policy_dot_regular'}
        @{name='target_policy_dot_regular_subset';sheet='combat_target_policy';column='count_buff_ids';row=10;value='[9,10,11,46]';field='target_policy_dot_regular';expected_from='target_policy_attack_first'}
        @{name='target_policy_dot_regular_extra_family';sheet='combat_target_policy';column='count_buff_ids';row=10;value='[8,9,10,11,46,27]';field='target_policy_dot_regular';expected_from='target_policy_attack_first'}
        @{name='target_policy_dot_tactic_fewest';sheet='combat_target_policy';column='order';row=9;value='fewest_owned_dots';field='target_policy_dot_tactic';expected_from='target_policy_dot_regular'}
        @{name='target_policy_attack_disabled';sheet='combat_target_policy';column='enabled';row=7;value='0';field='target_policy_attack_first';expected_from='target_policy_dot_tactic'}
        @{name='target_policy_attack_side';sheet='combat_target_policy';column='side';row=7;value='ally';field='target_policy_attack_first';expected_from='target_policy_dot_tactic'}
        @{name='target_policy_dot_priority';sheet='combat_target_policy';column='priority';row=9;value='20';field='target_policy_dot_tactic';expected_from='target_policy_dot_regular'}
        @{name='target_policy_dot_role';sheet='combat_target_policy';column='role';row=10;value='regular';field='target_policy_dot_other';expected_from='target_policy_dot_tactic'}
        @{name='target_policy_heal_role';sheet='combat_target_policy';column='role';row=5;value='tactic';field='target_policy_heal_order';expected_from='target_policy_base_order'}
        @{name='target_policy_heal_disabled';sheet='combat_target_policy';column='enabled';row=5;value='0';field='target_policy_heal_order';expected_from='target_policy_base_order'}
        @{name='shield_core_tick_disabled';sheet='combat_rule';column='C';row=48;value='0';field='shield_core_tick_self';expected=1;expected_fields=@{shield_core_tick_next=0;shield_core_tick_other=1}}
        @{name='shield_core_a_query_allow';sheet='combat_effect';column='flat';row=158;value='1';field='shield_core_a_conversion_damage';expected_from='shield_core_broken_legacy_damage';expected_fields=@{shield_core_a_legacy_allowed=1;shield_core_a_conversion_actions=0}}
        @{name='shield_core_b_query_allow';sheet='combat_effect';column='flat';row=159;value='1';field='shield_core_b_conversion_damage';expected_from='shield_core_broken_legacy_damage';expected_fields=@{shield_core_b_legacy_allowed=1}}
        @{name='shield_core_conversion_exclusion_off';sheet='combat_effect';column='conditions';row=9;value='[{"field":"broken","op":"eq","value":1},{"field":"source_alive","op":"eq","value":1}]';field='shield_core_b_conversion_damage';expected=350}
        @{name='shield_core_origin_fact';sheet='combat_effect';column='conditions';row=9;value='[{"field":"broken","op":"eq","value":1},{"field":"source_alive","op":"eq","value":1},{"field":"event_skill","op":"ne","value":0}]';field='shield_core_b_conversion_damage';expected=350}
        @{name='shield_full_aura_off';sheet='combat_effect';column='flat';row=160;value='0';field='shield_full_aura_once';expected=1001;expected_fields=@{shield_full_a_personal=1251;shield_full_a_group=1201}}
        @{name='shield_full_aura_owner_only';sheet='combat_effect';column='binding_scope';row=160;value='owner';field='shield_full_aura_other_source';expected=1001;expected_fields=@{shield_full_aura_once=1121}}
        @{name='shield_full_a_personal';sheet='combat_effect';column='flat';row=161;value='5000';field='shield_full_a_personal';expected=1621}
        @{name='shield_full_a_guard';sheet='combat_effect';column='flat';row=162;value='400';field='shield_full_a_guard';expected=2900}
        @{name='shield_full_a_group';sheet='combat_effect';column='flat';row=163;value='1000';field='shield_full_a_group';expected=1221}
        @{name='shield_full_a_duration';sheet='combat_effect';column='flat';row=164;value='2';field='shield_full_a_duration';expected=4;expected_fields=@{shield_full_a_own_256=257;shield_full_a_share_255=255}}
        @{name='shield_full_b_personal';sheet='combat_effect';column='flat';row=165;value='-1000';field='shield_full_b_personal';expected=900}
        @{name='shield_full_b_group';sheet='combat_effect';column='flat';row=166;value='-1000';field='shield_full_b_group';expected=900}
        @{name='shield_full_a_heal_budget';sheet='combat_effect';column='per_turn';row=167;value='2';field='shield_full_a_repeat';expected=4585}
        @{name='shield_full_a_heal_ratio';sheet='combat_effect';column='ratio_bp';row=168;value='1000';field='shield_full_a_heal';expected=4600}
        @{name='shield_full_b_counter';sheet='combat_effect';column='ratio_bp';row=169;value='4000';field='shield_full_b_counter_total';expected=750}
        @{name='shield_full_b_explosion_budget';sheet='combat_effect';column='per_turn';row=170;value='1';field='shield_full_b_three';expected=890}
        @{name='shield_full_b_extra_coefficient';sheet='combat_effect';column='flat';row=171;value='800';field='shield_full_b_burst';expected=430}
        @{name='shield_full_b_first_coefficient';sheet='combat_effect';column='flat';row=172;value='2000';field='shield_full_b_burst';expected=380;expected_fields=@{unified_event_bonus_first=85;unified_event_bonus_empty_third=0}}
        @{name='shield_full_b_damage_scale';sheet='combat_effect';column='ratio_bp';row=173;value='5000';field='shield_full_b_burst';expected=265}
        @{name='shield_full_b_conversion_ratio';sheet='combat_effect';column='ratio_bp';row=174;value='3000';field='shield_full_b_conversion';expected=300}
        @{name='shield_full_b_conversion_budget';sheet='combat_effect';column='cap_bp';row=174;value='600';field='shield_full_b_budget_spent';expected=6}
        @{name='shield_full_b_conversion_duration';sheet='combat_effect';column='duration';row=174;value='3';field='shield_full_b_conversion_duration';expected=3}
        @{name='shield_full_thorns_cap';sheet='combat_rule';column='C';row=50;value='2500';field='thorns_rule_first';expected=250}
        @{name='shield_full_thorns_budget';sheet='combat_rule';column='C';row=51;value='2';field='thorns_rule_four_total';expected=1000}
        @{name='shield_full_thorns_disabled';sheet='combat_rule';column='C';row=51;value='0';field='thorns_rule_first';expected=0}
    )
    foreach($case in $variants){
        if(-not (Test-CaseSelected $case.name)){continue}
        Reset-Fixture
        $book=if($case.book){$case.book}else{'hero_combat.xlsx'}
        Set-FixtureCell $case.sheet $case.column $case.row $case.value $book
        foreach($change in $case.changes){
            $changeSheet=if($change.sheet){$change.sheet}else{$case.sheet}
            Set-FixtureCell $changeSheet $change.column $change.row $change.value $book
        }
        Export-Fixture
        $actual=Probe
        $expected=if($case.expected_from){$baseline.($case.expected_from)}else{$case.expected}
        if($actual.($case.field) -ne $expected){throw "Sensitivity $($case.name): expected $expected, got $($actual.($case.field))"}
        foreach($field in $case.expected_fields.Keys){
            if($actual.($field) -ne $case.expected_fields[$field]){throw "Sensitivity $($case.name) field ${field}: expected $($case.expected_fields[$field]), got $($actual.($field))"}
        }
        if($case.name -like 'shield_full_*' -and $case.sheet -eq 'combat_effect') {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/combat_effect.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/combat_effect.json') -Raw -Encoding UTF8
            if($runtime -cne $display){throw 'Shield branch client/server descriptions diverged'}
            $row=@($runtime|ConvertFrom-Json)[$case.row-5]
            $token=switch($case.column){'flat'{$case.value};'ratio_bp'{([decimal]$case.value/100).ToString([Globalization.CultureInfo]::InvariantCulture)+'%'};'cap_bp'{([decimal]$case.value/100).ToString([Globalization.CultureInfo]::InvariantCulture)+'%'};'duration'{$case.value};'per_turn'{$case.value};default{$null}}
            if($case.column -eq 'flat' -and $row.op -in @('add_amount_bonus','add_event_bonus')){$token=([decimal]$case.value/100).ToString([Globalization.CultureInfo]::InvariantCulture)+'%'}
            if($token -and $row.description -notlike ('*'+$token+'*')){throw "Shield branch description did not follow table edit: $($case.name)"}
        }
        if($case.name -eq 'effect_target' -and $actual.shield -ne 0){throw 'Changed target still applied shield to original recipient'}
        if($actual.seed -ne 1729){throw 'Probe did not use the declared fixed seed'}
        if($actual.clean_reuse -ne 1){throw 'Battle reuse retained a prior battle budget'}
        if($case.name -eq 'artifact_curve') {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/combat_artifact.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/combat_artifact.json') -Raw -Encoding UTF8
            if($runtime -cne $display -or (@($runtime|ConvertFrom-Json)|Where-Object id -eq 1403).description -notlike '*32%*'){throw 'Artifact curve and description diverged'}
        }
        if($case.name -eq 'periodic_bonus') {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/combat_periodic.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/combat_periodic.json') -Raw -Encoding UTF8
            if($runtime -cne $display -or (@($runtime|ConvertFrom-Json)|Where-Object buff_id -eq 46).description -notlike '*40%*'){throw 'Periodic tuning and description diverged'}
        }
        if($case.name -eq 'affix_guard_curve' -or $case.name -eq 'affix_ignore_ratio') {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/equipment_affix.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/equipment_affix.json') -Raw -Encoding UTF8
            $id=if($case.name -eq 'affix_guard_curve'){12}else{27};$percent=if($id -eq 12){'10%'}else{'8%'}
            if($runtime -cne $display -or (@($runtime|ConvertFrom-Json)|Where-Object id -eq $id).combat_descriptions[2] -notlike "*$percent*"){throw 'Affix value and same-source description diverged'}
        }
        if($case.name -in @('combo_coefficient','combo_divisor','category_zero_cap','periodic_no_double_bonus')) {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/equipment_affix.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/equipment_affix.json') -Raw -Encoding UTF8
            $id=if($case.name -eq 'category_zero_cap'){39}elseif($case.name -eq 'periodic_no_double_bonus'){35}else{21}
            $pattern=switch($case.name){'combo_coefficient'{'*16%*'}'combo_divisor'{'*4%*'}'category_zero_cap'{'*不限*'}'periodic_no_double_bonus'{'*增加8%*周期伤害增加16%*共享100%上限*'}}
            if($runtime -cne $display -or (@($runtime|ConvertFrom-Json)|Where-Object id -eq $id).combat_descriptions[2] -notlike $pattern){throw 'Count/periodic description diverged from its formula'}
        }
        if($case.name -in @('overheal_affix_curve','overheal_affix_cap','overheal_cap_coefficient')) {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/equipment_affix.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/equipment_affix.json') -Raw -Encoding UTF8
            $pattern=if($case.name -eq 'overheal_affix_curve'){'*40%*最大生命20%*'}else{'*30%*最大生命10%*'}
            if($runtime -cne $display -or (@($runtime|ConvertFrom-Json)|Where-Object id -eq 5).combat_descriptions[2] -notlike $pattern){throw 'Overheal shield description diverged from runtime coefficients'}
        }
        if($case.name -in @('revive_guard_curve','revive_guard_duration','revive_guard_battle_budget')) {
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/equipment_affix.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/equipment_affix.json') -Raw -Encoding UTF8
            $pattern=switch($case.name){'revive_guard_curve'{'*30%*'}'revive_guard_duration'{'*持续3回合*'}'revive_guard_battle_budget'{'*每战最多2次*'}}
            if($runtime -cne $display -or (@($runtime|ConvertFrom-Json)|Where-Object id -eq 8).combat_descriptions[2] -notlike $pattern){throw 'Revive guard description diverged from inherited data'}
        }
        $entry=@{case=$case.name;before=$baseline.($case.field);after=$actual.($case.field);expected=$expected}
        if($case.expected_from){$entry.expected_from=$case.expected_from}
        if($case.description_affix){
            $runtime=Get-Content -LiteralPath (Join-Path $fixture 'unityserver/config/json/equipment_affix.json') -Raw -Encoding UTF8
            $display=Get-Content -LiteralPath (Join-Path $fixture 'unityclient/Assets/Resources/ProjectXData/Configs/equipment_affix.json') -Raw -Encoding UTF8
            $descriptions=@((@($runtime|ConvertFrom-Json)|Where-Object id -eq $case.description_affix).combat_descriptions)
            if($runtime -cne $display -or $descriptions.Count -ne 3 -or @($descriptions|Where-Object {-not $_.Contains($case.description_contains)}).Count){throw "Sensitivity $($case.name): description missing '$($case.description_contains)'"}
            $entry.description_checks=@{affix=$case.description_affix;contains=$case.description_contains;tiers=$descriptions.Count}
        }
        if($case.expected_fields){$entry.extra_checks=@{};foreach($field in $case.expected_fields.Keys){$entry.extra_checks[$field]=@{expected=$case.expected_fields[$field];actual=$actual.($field)}}}
        $sensitivity.Add($entry)
    }
    # Fault injection into disposable exported files tests defensive runtime
    # loading, independently of the exporter. No maintained JSON is edited.
    Reset-Fixture
    Export-Fixture
    $effectPath=Join-Path $fixture 'unityserver/config/json/combat_effect.json'
    $pristine=[IO.File]::ReadAllBytes($effectPath)
    foreach($case in @(
        @{name='runtime_unified_transfer_random';effect_id=7018001;key='probability_bp';value=5000;error='attribute transfer query must be deterministic'}
        @{name='runtime_unified_thorns_random';effect_id=7024001;key='probability_bp';value=5000;error='thorns query must be deterministic'}
        @{name='runtime_unified_buff_store_invalid_event';effect_id=7027000;key='event';value='after_hit';error='invalid attempted buff replacement'}
        @{name='runtime_unified_opening_action_flag';effect_id=7028001;key='flat';value=2;error='invalid opening action plan'}
        @{name='runtime_unified_useful_unknown_buff';effect_id=7030010;key='conditions';value=@(@{field='enemy_susceptible_unstacked_65534';op='ge';value=2});error='invalid buff fact reference'}
        @{name='runtime_unified_passive_target_random';effect_id=7025000;key='probability_bp';value=5000;error='invalid passive target plan'}
        @{name='runtime_unified_passive_target_bad_buff';effect_id=7025004;key='flat';value=65534;error='invalid passive target excluded buff'}
        @{name='runtime_unified_action_limit_reference';effect_id=7018004;key='basis';value='counter_action_limit_999999';error='invalid persistent counter reference'}
        @{name='runtime_unified_growth_bad_buff';effect_id=7019000;key='flat';value=65534;error='invalid attribute growth buff reference'}
        @{name='runtime_unified_guard_nonboolean';effect_id=7019010;key='flat';value=2;error='invalid guard candidate flag'}
        @{name='runtime_unified_origin_extension_skill';effect_id=7021010;key='argument';value=65534;error='invalid origin extension skill reference'}
        @{name='runtime_unified_control_owner_context';effect_id=7020019;key='event';value='before_direct_damage';error='invalid source buff owner binding'}
        @{name='runtime_unified_hp_restore_random';effect_id=7021000;key='probability_bp';value=5000;error='HP restoration query must be deterministic'}
        @{name='runtime_unified_heal_flag';effect_id=7020014;key='flat';value=2;error='invalid passive healing modifier'}
        @{name='runtime_integer_type';key='probability_bp';value='not-an-integer';error='invalid integer probability_bp'},
        @{name='runtime_reference';key='skill_id';value=65534;error='invalid skill/buff reference'},
        @{name='runtime_operator';key='op';value='unknown-effect';error='unknown op'},
        @{name='runtime_event_fact';key='basis';value='enemy_dots';error='unavailable basis/cap_basis'},
        @{name='runtime_cap_source';key='cap_ratio_source';value='item_id_math';error='unknown cap_ratio_source'},
        @{name='runtime_cap_binding';key='cap_ratio_source';value='affix_value2';error='affix fact requires affix binding'}
        @{name='runtime_duration_source';key='duration_source';value='skill_script';error='unknown duration_source'}
        @{name='runtime_duration_context';key='duration_source';value='event_duration';error='invalid dynamic duration source'}
        @{name='runtime_guard_multiplier_context';key='op';value='multiply_amount';error='invalid sequential multiplier'}
        @{name='runtime_guard_attacker_context';key='basis';value='attacker_alive';error='unavailable basis/cap_basis'}
        @{name='runtime_emit_type';key='emit_action';value=2;error='invalid integer emit_action'}
        @{name='runtime_emit_non_buff';effect_id=1003;key='emit_action';value=0;error='silent effect requires buff or shield operation'}
        @{name='runtime_skill_immunity_type';key='check_skill_immunity';value=2;error='invalid integer check_skill_immunity'}
        @{name='runtime_skill_immunity_non_buff';key='check_skill_immunity';value=0;error='skill immunity policy requires buff operation'}
        @{name='runtime_amount_budget_mode';key='amount_budget';value='affix_id_10';error='unknown amount_budget'}
        @{name='runtime_amount_budget_contract';effect_id=1002;key='amount_budget';value='source_turn';error='invalid amount budget contract'}
        @{name='runtime_amount_budget_shared_contract';effect_id=40100;key='counter_key';value=40031;error='incompatible shared amount budget contract'}
        @{name='runtime_chance_source';effect_id=40151;key='probability_source';value='hero_id';error='unknown probability_source'}
        @{name='runtime_chance_contract';key='probability_source';value='affix_value1';error='invalid dynamic probability contract'}
        @{name='runtime_chance_scope';effect_id=40151;key='counter_scope';value='target';error='invalid chance gate'}
        @{name='runtime_chance_payload';effect_id=40151;key='flat';value=1;error='invalid chance gate'}
        @{name='runtime_death_count_context';key='basis';value='effect_battle_count';error='unavailable basis/cap_basis'}
        @{name='runtime_death_count_scope';effect_id=40420;key='counter_scope';value='target';error='effect count requires source scope'}
        @{name='runtime_removed_parameter_context';key='basis';value='buff_param0';error='unavailable basis/cap_basis'}
        @{name='runtime_removed_turn_context';key='growth_basis';value='remaining_turns';error='unavailable growth basis'}
        @{name='runtime_summon_scope';effect_id=40431;key='affix_scope';value='highest_random';error='unknown affix_scope'}
        @{name='runtime_summon_query_probability';effect_id=40430;key='probability_bp';value=5000;error='summon query must be a deterministic modifier'}
        @{name='runtime_duration_addition_flat';effect_id=40301;key='flat';value=256;error='invalid duration addition'}
        @{name='runtime_duration_addition_target';effect_id=40301;key='target';value='self';error='invalid duration addition'}
        @{name='runtime_extend_buff_reference';effect_id=40441;key='argument';value=65534;error='invalid skill/buff reference'}
        @{name='runtime_target_chance_scope';effect_id=40440;key='counter_scope';value='source';error='invalid chance gate'}
        @{name='runtime_payload_count';effect_id=40160;key='parameter_count';value=5;error='invalid integer parameter_count'}
        @{name='runtime_payload_copy_count';effect_id=40332;key='parameter_count';value=1;error='invalid buff parameter count'}
        @{name='runtime_payload_nonbuff_origin';effect_id=1003;key='origin_level';value=1;error='fixed origin level requires buff or shield operation'}
        @{name='runtime_payload_origin_type';effect_id=40160;key='origin_level';value='seven';error='invalid integer origin_level'}
        @{name='runtime_payload_copy_duration';effect_id=40332;key='duration_source';value='constant';error='invalid buff copy contract'}
        @{name='runtime_payload_copy_argument';effect_id=40332;key='argument';value=9;error='invalid buff copy contract'}
        @{name='runtime_payload_selector_context';key='target';value='first_unstacked_enemy';error='stack selector requires after_buff'}
        @{name='runtime_state_unknown_counter';effect_id=40182;key='growth_basis';value='counter_count_999999';error='invalid persistent counter reference'}
        @{name='runtime_state_non_gate_counter';effect_id=40182;key='growth_basis';value='counter_count_40182';error='invalid persistent counter reference'}
        @{name='runtime_state_reset_non_gate';effect_id=40181;key='argument';value=40182;error='invalid persistent counter reference'}
        @{name='runtime_state_reset_budget';effect_id=40235;key='argument';value=40230;error='state reset requires unlimited source gate'}
        @{name='runtime_state_reset_probability';effect_id=40181;key='probability_bp';value=5000;error='invalid state reset operation'}
        @{name='runtime_state_reset_dynamic_probability';effect_id=40181;key='probability_source';value='affix_value1';error='invalid dynamic probability contract'}
        @{name='runtime_state_reset_target';effect_id=40181;key='target';value='target';error='invalid state reset operation'}
        @{name='runtime_state_counter_uppercase';effect_id=40182;key='growth_basis';value='COUNTER_COUNT_40180';error='unavailable growth basis'}
        @{name='runtime_nuwa_origin_nonbuff';effect_id=1003;key='origin_skill';value=0;error='fixed origin skill requires buff or shield operation'}
        @{name='runtime_nuwa_origin_range';effect_id=1002;key='origin_skill';value=-2;error='invalid integer origin_skill'}
        @{name='runtime_nuwa_origin_type';effect_id=1002;key='origin_skill';value='raw';error='invalid integer origin_skill'}
        @{name='runtime_nuwa_origin_unknown_skill';effect_id=1002;key='origin_skill';value=65534;error='invalid skill/buff reference in effect'}
        @{name='runtime_gear_origin_foreign_group';effect_id=20003;key='origin_skill';value=10004;error='invalid skill/buff reference in effect'}
        @{name='runtime_gear_presentation_foreign_group';effect_id=20004;key='presentation_skill';value=11001;error='invalid skill/buff reference in effect'}
        @{name='runtime_gear_origin_not_cast_skill';effect_id=20003;key='skill_id';value=10003;error='invalid skill/buff reference in effect'}
        @{name='runtime_nuwa_origin_merge_conflict';effect_id=1001;key='origin_skill';value=101;error='incompatible merged shield origin'}
        @{name='runtime_revive_record_unknown';effect_id=1018;key='conditions';value=@(@{field='target_counter_count_999999';op='ge';value=1});error='invalid persistent counter reference'}
        @{name='runtime_revive_record_scope';effect_id=1018;key='conditions';value=@(@{field='counter_count_1017';op='ge';value=1});error='invalid persistent counter reference'}
        @{name='runtime_revive_record_non_gate';effect_id=1018;key='conditions';value=@(@{field='target_counter_count_1018';op='ge';value=1});error='invalid persistent counter reference'}
        @{name='runtime_revive_record_random';effect_id=1017;key='probability_bp';value=5000;error='invalid event gate'}
        @{name='runtime_revive_record_query_flag';effect_id=1018;key='flat';value=2;error='query flag must be a constant boolean'}
        @{name='runtime_revive_record_query_probability';effect_id=1018;key='probability_bp';value=5000;error='healing/usefulness query must be deterministic'}
        @{name='runtime_inline_shield_conflict';effect_id=1001;key='emit_action';value=1;error='incompatible merged shield presentation'}
        @{name='runtime_shield_core_query_flag';effect_id=1210;key='flat';value=2;error='query flag must be a constant boolean'}
        @{name='runtime_shield_core_query_probability';effect_id=1210;key='probability_bp';value=5000;error='healing/usefulness query must be deterministic'}
        @{name='runtime_shield_core_query_index';effect_id=1210;key='argument';value=1;error='invalid set parameter operation'}
        @{name='runtime_shield_core_event_skill';effect_id=1201;key='conditions';value=@(@{field='event_skills';op='ne';value=124});error='unavailable condition field'}
        @{name='runtime_hero61b_bonus_index';effect_id=6131;key='argument';value=4;error='invalid modifier parameter index'}
        @{name='runtime_hero61b_bonus_probability';effect_id=6131;key='probability_bp';value=5000;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero61b_bonus_budget';effect_id=6131;key='per_turn';value=1;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero61b_bonus_event';effect_id=6131;key='event';value='after_passive_attribute_roll';error='incompatible bonus modifier'}
        @{name='runtime_hero61b_cap_index';effect_id=6132;key='argument';value=4;error='invalid set parameter operation'}
        @{name='runtime_hero61b_gate_probability';effect_id=6133;key='probability_bp';value=5000;error='invalid event gate'}
        @{name='runtime_hero61b_counter_not_gate';effect_id=6135;key='conditions';value=@(@{field='counter_count_6134';op='ge';value=1});error='invalid persistent counter reference'}
        @{name='runtime_hero65b_buff_index';effect_id=6521;key='argument';value=4;error='invalid set parameter operation'}
        @{name='runtime_hero65b_unknown_skill';effect_id=6521;key='skill_id';value=65534;error='invalid skill/buff reference in effect'}
        @{name='runtime_hero65b_query_index';effect_id=6523;key='argument';value=4;error='invalid parameter addition'}
        @{name='runtime_hero65b_query_event';effect_id=6523;key='event';value='after_passive_attribute_roll';error='invalid parameter addition'}
        @{name='runtime_hero65b_query_probability';effect_id=6523;key='probability_bp';value=5000;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero65b_query_budget';effect_id=6523;key='per_turn';value=1;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero65a_query_index';effect_id=6503;key='argument';value=4;error='invalid parameter addition'}
        @{name='runtime_hero65a_query_target';effect_id=6503;key='target';value='self';error='invalid parameter addition'}
        @{name='runtime_hero65a_query_basis';effect_id=6503;key='basis';value='source_max_hp';error='invalid parameter addition'}
        @{name='runtime_hero65a_query_event';effect_id=6503;key='event';value='after_passive_attribute_roll';error='invalid parameter addition'}
        @{name='runtime_hero65a_query_probability';effect_id=6503;key='probability_bp';value=5000;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero65a_query_budget';effect_id=6503;key='per_turn';value=1;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero65a_negative_shield';effect_id=1213;key='flat';value=-800;error='invalid parameter addition'}
        @{name='runtime_hero61a_unknown_event';effect_id=6102;key='event';value='after_skills_damage';error='unknown event'}
        @{name='runtime_hero61a_unknown_skill';effect_id=6102;key='skill_id';value=65534;error='invalid skill/buff reference in effect'}
        @{name='runtime_hero61a_unknown_buff';effect_id=6102;key='argument';value=65534;error='invalid skill/buff reference in effect'}
        @{name='runtime_hero61a_unknown_origin';effect_id=6102;key='origin_skill';value=65534;error='invalid skill/buff reference in effect'}
        @{name='runtime_hero15a_unknown_skill_fact';effect_id=1536;key='conditions';value=@(@{field='source_skill_level_65534';op='gt';value=0});error='invalid source skill fact reference'}
        @{name='runtime_hero15a_unknown_buff_value';effect_id=1532;key='conditions';value=@(@{field='target_buff_value_65534';op='lt';value=800});error='invalid buff fact reference'}
        @{name='runtime_hero15a_bad_skill_fact';effect_id=1536;key='conditions';value=@(@{field='source_skill_level_0153';op='gt';value=0});error='unavailable condition field'}
        @{name='runtime_hero15a_counter_not_gate';effect_id=1539;key='conditions';value=@(@{field='counter_age_1536';op='eq';value=0});error='invalid persistent counter reference'}
        @{name='runtime_hero15a_repeat_negative';effect_id=1540;key='flat';value=-1;error='invalid repeated action scale'}
        @{name='runtime_hero15a_repeat_budget';effect_id=1540;key='per_turn';value=1;error='invalid repeated action scale'}
        @{name='runtime_hero15a_repeat_random';effect_id=1540;key='probability_bp';value=5000;error='invalid repeated action scale'}
        @{name='runtime_hero15a_repeat_operator';effect_id=1540;key='op';value='heal';error='invalid repeated action scale'}
        @{name='runtime_hero15a_repeat_index';effect_id=1540;key='argument';value=1;error='invalid set parameter operation'}
        @{name='runtime_hero15a_record_budget';effect_id=1537;key='per_turn';value=1;error='accepted kill action requires unlimited deterministic record'}
        @{name='runtime_hero15a_record_operator';effect_id=1537;key='op';value='damage';error='accepted kill action requires unlimited deterministic record'}
        @{name='runtime_hero15a_record_target';effect_id=1537;key='target';value='enemies';error='invalid event gate'}
        @{name='runtime_hero15a_passive_flag';effect_id=1533;key='flat';value=2;error='passive query flag must be a constant boolean'}
        @{name='runtime_hero15a_passive_flag_basis';effect_id=1533;key='basis';value='source_attack';error='passive query flag must be a constant boolean'}
        @{name='runtime_hero15a_before_buff_index';effect_id=1530;key='argument';value=4;error='invalid set parameter operation'}
        @{name='runtime_hero15b_query_random';effect_id=1507;key='probability_bp';value=5000;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero15b_query_budget';effect_id=1507;key='budget';value='extra_attack';error='passive query must be a deterministic modifier'}
        @{name='runtime_hero15b_query_interval';effect_id=1507;key='interval_turns';value=1;error='passive query must be a deterministic modifier'}
        @{name='runtime_hero15b_query_index';effect_id=1507;key='argument';value=4;error='invalid set parameter operation'}
        @{name='runtime_hero15b_query_field_context';effect_id=1502;key='conditions';value=@(@{field='passive_count';op='ge';value=5});error='unavailable condition field'}
        @{name='runtime_hero15b_kill_kind';effect_id=1522;key='flat';value=3;error='invalid kill action parameter'}
        @{name='runtime_hero15b_kill_scale';effect_id=1523;key='flat';value=-1;error='invalid kill action parameter'}
        @{name='runtime_hero15b_kill_index';effect_id=1523;key='argument';value=2;error='invalid set parameter operation'}
        @{name='runtime_hero15b_kill_random';effect_id=1522;key='probability_bp';value=5000;error='kill action query must use deterministic gates or parameters'}
        @{name='runtime_hero15b_kill_operator';effect_id=1520;key='op';value='damage';error='kill action query must use deterministic gates or parameters'}
        @{name='runtime_pursuit_full_gate_random';effect_id=1500;key='probability_bp';value=5000;error='invalid event gate'}
        @{name='runtime_pursuit_full_gate_target';effect_id=1500;key='target';value='enemies';error='invalid event gate'}
        @{name='runtime_pursuit_full_gate_order';effect_id=1500;key='priority';value=11;error='invalid or cyclic event gate reference'}
        @{name='runtime_pursuit_full_context';effect_id=1502;key='conditions';value=@(@{field='event_target_alive';op='eq';value=1});error='unavailable condition field'}
        @{name='runtime_pursuit_full_context_typo';effect_id=1500;key='conditions';value=@(@{field='event_target_alives';op='eq';value=1});error='unavailable condition field'}
        @{name='runtime_shield_full_scope';effect_id=1211;key='binding_scope';value='enemy';error='unknown binding_scope'}
        @{name='runtime_shield_full_scope_context';effect_id=1211;key='event';value='before_heal';error='invalid team binding modifier'}
        @{name='runtime_shield_full_scope_budget';effect_id=1211;key='per_turn';value=1;error='shield query must be deterministic'}
        @{name='runtime_shield_full_query_random';effect_id=1212;key='probability_bp';value=5000;error='shield query must be deterministic'}
        @{name='runtime_shield_full_parameter_index';effect_id=1213;key='argument';value=4;error='invalid parameter addition'}
        @{name='runtime_shield_full_attacker_context';effect_id=1224;key='event';value='after_hit';error='attacker selector requires shield loss'}
        @{name='runtime_shield_full_bonus_context';effect_id=1212;key='ratio_source';value='event_bonus';error='invalid event bonus consumer'}
        @{name='runtime_shield_full_coefficient_negative';effect_id=1226;key='flat';value=-1;error='invalid event coefficient addition'}
        @{name='runtime_shield_full_coefficient_target';effect_id=1226;key='target';value='enemies';error='invalid event coefficient addition'}
        @{name='runtime_shield_full_budget_scope';effect_id=1229;key='counter_scope';value='target';error='invalid amount budget contract'}
        @{name='runtime_shield_full_budget_zero_cap';effect_id=1229;key='cap_bp';value=0;error='invalid amount budget contract'}
        @{name='runtime_shield_full_missing_coefficient';effect_id=1228;key='priority';value=35;error='missing prior event coefficient producer'}
        @{name='runtime_shield_full_missing_hp_result';effect_id=1229;key='priority';value=15;error='missing prior HP loss producer'}
    )){
        if(-not (Test-CaseSelected $case.name)){continue}
        $records=@([Text.Encoding]::UTF8.GetString($pristine)|ConvertFrom-Json -AsHashtable)
        $record=if($case.effect_id){@($records|Where-Object id -eq $case.effect_id)[0]}else{$records[0]}
        if(-not $record){throw "Missing runtime corruption effect: $($case.effect_id)"}
        # Operator diagnostics are isolated from metadata that only belongs to
        # the original shield/buff operation. Identity itself has separate cases.
        if($case.key -eq 'op' -and $case.value -notin @('buff','copy_buff','shield')){$record.origin_skill=-1;$record.origin_level=0;$record.emit_action=1;$record.check_skill_immunity=1}
        $record[$case.key]=$case.value
        [IO.File]::WriteAllText($effectPath,(ConvertTo-Json -InputObject $records -Depth 20 -Compress),[Text.UTF8Encoding]::new($false))
        $run=Invoke-CombatProbeProcess;$output=$run.output;$code=$run.code
        if($code -eq 0 -or ($output -join "`n") -notlike ('*'+$case.error+'*')){
            $failurePath=Join-Path $fixture ($case.name+'-runtime-failure.log')
            $output|Set-Content -LiteralPath $failurePath -Encoding utf8
            throw "Runtime corruption was not rejected as '$($case.error)': $($case.name); evidence=$failurePath"
        }
        $results.Add(@{case=$case.name;passed=$true;error=$case.error})
        [IO.File]::WriteAllBytes($effectPath,$pristine)
    }
    $targetPath=Join-Path $fixture 'unityserver/config/json/combat_target_policy.json'
    $targetPristine=[IO.File]::ReadAllBytes($targetPath)
    foreach($case in @(
        @{name='runtime_hero61b_policy_depth';table='combat_event_policy';id=23;key='extra_depth';value=8;error='invalid integer extra_depth'}
        @{name='runtime_hero61a_policy_depth';table='combat_event_policy';id=22;key='extra_depth';value=8;error='invalid integer extra_depth'}
        @{name='runtime_hero61a_policy_event';table='combat_event_policy';id=22;key='event';value='after_skills_damage';error='unknown event'}
        @{name='runtime_target_policy_order';key='order';value='lowest_mana';error='unknown order'}
        @{name='runtime_target_policy_side';key='side';value='both';error='unknown side'}
        @{name='runtime_target_policy_role';key='role';value='instant';error='unknown role'}
        @{name='runtime_target_policy_tie';key='tie_break';value='random';error='unknown tie_break'}
        @{name='runtime_target_policy_enabled';key='enabled';value=2;error='invalid integer enabled'}
        @{name='runtime_target_policy_count_type';id=5;key='count_buff_ids';value='[8]';error='target count buffs must be an array'}
        @{name='runtime_target_policy_count_empty';id=5;key='count_buff_ids';value=@();error='invalid target count buff contract'}
        @{name='runtime_target_policy_count_duplicate';id=5;key='count_buff_ids';value=@(8,8);error='invalid target count buff'}
        @{name='runtime_target_policy_count_unknown';id=5;key='count_buff_ids';value=@(65534);error='invalid target policy buff reference'}
        @{name='runtime_target_policy_priority_conflict';duplicate=$true;error='conflicting target policy priority'}
    )) {
        if(-not (Test-CaseSelected $case.name)){continue}
        $mutationPath=if($case.table){Join-Path $fixture ('unityserver/config/json/'+$case.table+'.json')}else{$targetPath}
        $mutationPristine=if($case.table){[IO.File]::ReadAllBytes($mutationPath)}else{$targetPristine}
        $records=@([Text.Encoding]::UTF8.GetString($mutationPristine)|ConvertFrom-Json -AsHashtable)
        $record=if($case.id){@($records|Where-Object id -eq $case.id)[0]}else{$records[0]}
        if(-not $record){throw "Missing policy mutation record: $($case.name)"}
        if($case.duplicate){$copy=$record.Clone();$copy.id=99;$records+=,$copy}else{$record[$case.key]=$case.value}
        [IO.File]::WriteAllText($mutationPath,(ConvertTo-Json -InputObject $records -Depth 20 -Compress),[Text.UTF8Encoding]::new($false))
        $run=Invoke-CombatProbeProcess
        if($run.code -eq 0 -or ($run.output -join "`n") -notlike ('*'+$case.error+'*')){
            $failurePath=Join-Path $fixture ($case.name+'-runtime-failure.log');$run.output|Set-Content -LiteralPath $failurePath -Encoding utf8
            throw "Runtime policy rejection differs: $($case.name); evidence=$failurePath"
        }
        $results.Add(@{case=$case.name;passed=$true;error=$case.error})
        [IO.File]::WriteAllBytes($mutationPath,$mutationPristine)
    }
    $rulePath=Join-Path $fixture 'unityserver/config/json/combat_rule.json';$rulePristine=[IO.File]::ReadAllBytes($rulePath)
    foreach($case in @(
        @{name='runtime_unified_shared_target_count';key='shared_link_target_count';value=10;error='invalid shared link target plan'}
        @{name='runtime_unified_shared_target_selector';key='shared_link_target_select';value=20;error='invalid shared link target plan'}
        @{name='runtime_unified_missing_action_cap';key='action_attribute_stack_cap';remove=$true}
        @{name='runtime_unified_missing_revived_action';key='revived_action_block_turns';remove=$true}
        @{name='runtime_unified_vulnerability_cap_range';key='vulnerability_multiplier_max_bp';value=9999;error='invalid integer value'}
        @{name='runtime_unified_critical_chance_range';key='critical_chance_cap_bp';value=10001;error='invalid integer value'}
        @{name='runtime_unified_critical_inverted_range';key='critical_multiplier_min_bp';value=40000;error='inverted critical multiplier range'}
        @{name='runtime_shield_core_tick_range';key='buff_tick_same_action_skip';value=2}
        @{name='runtime_hero15a_missing_vulnerability_rule';key='vulnerability_keep_highest';remove=$true}
        @{name='runtime_hero15a_missing_refresh_rule';key='buff_refresh_same_origin';remove=$true}
        @{name='runtime_hero15a_missing_cooldown_rule';key='cooldown_tick_action_begin';remove=$true}
        @{name='runtime_hero15a_missing_shared_rage_rule';key='rage_from_shared_damage';remove=$true}
        @{name='runtime_pursuit_full_vulnerability_flag';key='vulnerability_keep_highest';value=2}
        @{name='runtime_hero15b_cooldown_tick_flag';key='cooldown_tick_action_begin';value=2}
        @{name='runtime_hero15b_shared_rage_flag';key='rage_from_shared_damage';value=2}
        @{name='runtime_pursuit_full_refresh_flag';key='buff_refresh_same_origin';value=-1}
        @{name='runtime_shield_full_thorns_flag';key='thorns_requires_hp_loss';value=2}
        @{name='runtime_shield_full_thorns_cap';key='thorns_cap_bp';value=10001}
        @{name='runtime_shield_full_thorns_budget';key='thorns_per_turn';value=-1}
    )) {
        if(-not (Test-CaseSelected $case.name)){continue}
        $rules=@([Text.Encoding]::UTF8.GetString($rulePristine)|ConvertFrom-Json -AsHashtable)
        $removeRule=$case.ContainsKey('remove') -and [bool]$case['remove']
        $matchingRules=@($rules|Where-Object key -eq $case.key)
        if($matchingRules.Count -ne 1){throw "Missing or duplicate shared-rule fixture target: $($case.key)"}
        if($removeRule){$rules=@($rules|Where-Object key -ne $case.key)}else{$matchingRules[0].value=$case.value}
        [IO.File]::WriteAllText($rulePath,(ConvertTo-Json -InputObject $rules -Depth 20 -Compress),[Text.UTF8Encoding]::new($false))
        $run=Invoke-CombatProbeProcess
        $expectedError=if($case.error){$case.error}elseif($removeRule){'missing shared rule: '+$case.key}else{'invalid integer value'}
        if($run.code -eq 0 -or ($run.output -join "`n") -notlike ('*'+$expectedError+'*')){
            $run.output|Set-Content -LiteralPath (Join-Path $fixture ($case.name+'-failure.log')) -Encoding utf8
            throw "Runtime did not reject the corrupt shared rule: $($case.name)"
        }
        $results.Add(@{case=$case.name;passed=$true;error=$expectedError})
        [IO.File]::WriteAllBytes($rulePath,$rulePristine)
    }
    if((Get-CombatBinaryHash) -ne $binaryHash){throw 'Binary changed during table sensitivity tests'}
}
if((Get-FileHash -LiteralPath $workbook).Hash -ne $sourceHash){throw 'Production workbook changed during fixture tests'}
foreach($name in $equipmentHashes.Keys){if((Get-FileHash -LiteralPath (Join-Path $Root "unitydata/excel/$name")).Hash -ne $equipmentHashes[$name]){throw 'Production equipment workbook changed during fixture tests'}}
foreach($name in $CaseName){if(-not $selectedNames.Contains($name)){throw "Unknown requested combat test case: $name"}}
Save-CombatTestProgress
$report=@{cases=$results.ToArray();baseline=$baseline;variant=$variant;sensitivity=$sensitivity.ToArray();source_sha256=$sourceHash;equipment_sha256=$equipmentHashes;fixture=$fixture;binary=$ServerExecutable;binary_sha256=$binaryHash;runtime_tested=[bool]$ServerExecutable;full_matrix=($CaseName.Count -eq 0);requested_cases=$CaseName}
$report|ConvertTo-Json -Depth 12|Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'results.json') -Encoding utf8
Write-Output "Combat export: $($results.Count) rejection cases; $($sensitivity.Count) runtime sensitivity cases; same-source description passed; runtime_tested=$([bool]$ServerExecutable)"
# Expected failing child processes above are assertions, not the script result.
$global:LASTEXITCODE=0
