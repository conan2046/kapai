function Get-UnityStoryGuideVisuals($Row,[string]$Label) {
 $result=[ordered]@{
  select_visible=(Convert-EventInteger $Row.select_visible "$Label.select_visible" 0 1)
  hint_side=(Convert-EventInteger $Row.hint_side "$Label.hint_side" 1 2)
 }
 foreach($field in @('select_offset_x','select_offset_y','hint_offset_x','hint_offset_y')){
  [double]$value=0
  if(-not [double]::TryParse([string]$Row[$field],[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$value) -or [double]::IsNaN($value) -or [double]::IsInfinity($value) -or [Math]::Abs($value) -gt [single]::MaxValue){throw "$Label.$field must be a finite UI offset"}
  $result[$field]=$value
 }
 return $result
}
# Resolve planner UI placement against the formal native Prefab hierarchy.
function Get-UnityStoryPlacement($Row,[string]$Label,[string]$Root,[hashtable]$Cache) {
 $parent=([string]$Row.parent_node).Trim()
 if([string]::IsNullOrWhiteSpace($parent)){throw "$Label.parent_node is required"}
 if($parent -match '(^|/)\.\.?(/|$)|\\|^/|/$|//'){throw "$Label.parent_node has an invalid path: $parent"}
 $result=[ordered]@{parent_node=$parent}
 foreach($field in @('offset_x','offset_y')){
  [double]$value=0
  if(-not [double]::TryParse([string]$Row[$field],[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$value) -or [double]::IsNaN($value) -or [double]::IsInfinity($value) -or [Math]::Abs($value) -gt [single]::MaxValue){throw "$Label.$field must be a finite UI offset"}
  $result[$field]=$value
 }
 if($parent -ceq 'Canvas'){return $result}
 $parts=$parent.Split('/');$viewKey=$parts[0]
 if(-not $Cache.ContainsKey($viewKey)){
  $catalog=Join-Path $Root "unityclient/Assets/Prefabs/Catalog/$viewKey.asset"
  if(-not (Test-Path -LiteralPath $catalog)){throw "$Label.parent_node unknown UI key: $viewKey"}
  $catalogText=[IO.File]::ReadAllText($catalog)
  $guid=[regex]::Match($catalogText,'prefab:\s*\{fileID: \d+, guid: ([a-f0-9]+)').Groups[1].Value
  if(-not $guid){throw "$Label.parent_node has no native Prefab reference"}
  $metas=@(Get-ChildItem (Join-Path $Root 'unityclient/Assets/Prefabs') -Filter "$viewKey.prefab.meta" -File -Recurse | Where-Object {[IO.File]::ReadAllText($_.FullName) -match "(?m)^guid: $guid\s*$"})
  if($metas.Count -ne 1){throw "$Label.parent_node cannot resolve Prefab $viewKey"}
  $yaml=[IO.File]::ReadAllText($metas[0].FullName.Substring(0,$metas[0].FullName.Length-5))
  $names=@{};$nodes=@{}
  foreach($block in [regex]::Split($yaml,'(?m)^--- ')){
   $id=[regex]::Match($block,'^!u!(1|4|224) &(\d+)')
   if(-not $id.Success){continue}
   if($id.Groups[1].Value -eq '1'){$names[$id.Groups[2].Value]=[regex]::Match($block,'(?m)^  m_Name: (.+)').Groups[1].Value.Trim().Trim('"')}
   else{$nodes[$id.Groups[2].Value]=@{go=[regex]::Match($block,'m_GameObject: \{fileID: (\d+)').Groups[1].Value;father=[regex]::Match($block,'m_Father: \{fileID: (\d+)').Groups[1].Value}}
  }
  $roots=@($nodes.Keys|Where-Object {$nodes[$_].father -eq '0'})
  if($roots.Count -ne 1){throw "$Label.parent_node requires a native root hierarchy"}
  $Cache[$viewKey]=@{names=$names;nodes=$nodes;root=$roots[0]}
 }
 $hierarchy=$Cache[$viewKey];$current=$hierarchy.root
 for($i=1;$i -lt $parts.Count;$i++){
  $children=@($hierarchy.nodes.Keys|Where-Object {$hierarchy.nodes[$_].father -eq $current -and $hierarchy.names[$hierarchy.nodes[$_].go] -ceq $parts[$i]})
  if($children.Count -ne 1){throw "$Label.parent_node missing or ambiguous node: $parent"}
  $current=$children[0]
 }
 return $result
}
# Story rows retain numeric planner fields; every condition resolves the common event table.
function Get-UnityStoryData([string]$Root,$EventData) {
 $book=Join-Path $Root 'unitydata/excel/story_config.xlsx'
 $placementCache=@{}
 $steps=[Collections.Generic.List[object]]::new();$dialogs=[Collections.Generic.List[object]]::new();$ids=@{};$pres=@{};$dids=@{}
 foreach($r in @(Read-UnityVisualExcelRows $book -SheetName story_dialog -RejectFormulas)){
  if((Convert-EventInteger $r.enabled 'dialog.enabled' 0 1) -eq 0){continue}
  $d=[ordered]@{};foreach($k in @('dialogid','order','actor_type','actor_id','position','speed','delay','showskip','enabled')){$d[$k]=Convert-EventInteger $r[$k] ('dialog.'+$k)}
  $d.dialog=[string]$r.dialog;$d.scale=[double]$r.scale;$d.remark=[string]$r.remark
  $placement=Get-UnityStoryPlacement $r ("dialog $($d.dialogid):$($d.order)") $Root $placementCache;foreach($k in $placement.Keys){$d[$k]=$placement[$k]}
  if(-not $d.dialogid -or $d.order -lt 1 -or [string]::IsNullOrWhiteSpace($d.dialog) -or $d.actor_type -notin @(1,3) -or $d.showskip -gt 1 -or $d.scale -ne 1 -or $d.position -ne 0 -or $d.speed -lt 1 -or $d.delay -gt 30000){throw 'Invalid enabled story dialogue'}
  $key="$($d.dialogid):$($d.order)";if($dids.ContainsKey($key)){throw "Duplicate dialogue $key"};$dids[$key]=$true;$dialogs.Add($d)
 }
 $events=@{};foreach($e in $EventData.events){$events[$e.id]=$e}
 foreach($r in @(Read-UnityVisualExcelRows $book -SheetName story_event -RejectFormulas)){
  if((Convert-EventInteger $r.enabled 'story.enabled' 0 1) -eq 0){continue}
  $s=[ordered]@{};foreach($k in @('id','pre_id','trigger_event_id','dialogid','action_type','action_id','param1','param2','complete_event_id','once','enabled')){$s[$k]=Convert-EventInteger $r[$k] ('story.'+$k)}
  if(-not $s.id -or $ids.ContainsKey($s.id) -or $pres.ContainsKey($s.pre_id) -or $s.once -ne 1 -or $s.action_type -gt 6){throw 'Invalid/duplicate story step'}
  if(-not $events.ContainsKey($s.trigger_event_id) -or -not $events.ContainsKey($s.complete_event_id)){throw "Story $($s.id) references disabled event"}
  if($s.dialogid -and -not @($dialogs|Where-Object dialogid -eq $s.dialogid).Count){throw 'Story dialogue reference missing'}
  if($s.action_type -eq 0 -and -not $s.dialogid){throw 'Dialogue action has no dialogue'}
  if($s.action_type -eq 3 -and $s.action_id -eq 0){throw 'Story reward package missing'}
  if($s.action_type -eq 4 -and ($s.action_id -lt 1 -or $s.param1 -notin 1..5)){throw 'Invalid story formation action'}
  $placement=Get-UnityStoryPlacement $r ("story $($s.id)") $Root $placementCache;foreach($k in $placement.Keys){$s[$k]=$placement[$k]}
  $visuals=Get-UnityStoryGuideVisuals $r ("story $($s.id)");foreach($k in $visuals.Keys){$s[$k]=$visuals[$k]}
  $s.hint=[string]$r.hint;$ids[$s.id]=$s;$pres[$s.pre_id]=$s;$steps.Add($s)
 }
 if(-not $pres.ContainsKey(0L)){throw 'Story root missing'}
 $seen=@{};$step=$pres[0L]
 while($null -ne $step){if($seen.ContainsKey($step.id)){throw 'Story loop'};$seen[$step.id]=$true;$step=$pres[$step.id]}
 if($seen.Count -ne $steps.Count){throw 'Story graph is disconnected'}
 $rewardRows=@(Read-UnityVisualExcelRows (Join-Path $Root 'unitydata/excel/reward_fixed.xlsx') -SheetName reward_fixed)
 foreach($s in $steps){if($s.action_type -eq 3){$r=@($rewardRows|Where-Object {[int]$_.ID -eq $s.action_id});if($r.Count -ne 1){throw "Story reward missing $($s.action_id)"}}}

 foreach($s in $steps){
  $e=$events[$s.complete_event_id]
  switch([int]$s.action_type){
   0 {if($e.type -ne 1004 -or $e.param1 -ne $s.dialogid){throw 'Dialogue completion event mismatch'}}
   1 {if($s.action_id -notin @(22,1030) -or $e.type -ne 1003 -or $e.param1 -ne $s.action_id){throw 'Function guidance event mismatch'}}
   3 {
    $r=@($rewardRows|Where-Object {[int]$_.ID -eq $s.action_id})[0]
    try{$a=ConvertFrom-Json -InputObject ([string]$r.reward) -AsHashtable -NoEnumerate}catch{$a=ConvertFrom-Json -InputObject ('['+[string]$r.reward+']') -AsHashtable -NoEnumerate}
    if($a.Count -and $a[0] -isnot [Collections.IList]){$a=,@($a)}
    if($a.Count -ne 1 -or $a[0].Count -ne 3 -or $a[0][2] -ne 1){throw 'Story reward must contain exactly one hero or equipment'}
    $kind=[int]$a[0][0];$obj=[int]$a[0][1]
    if(($kind -ne 60002 -and $kind -ne 60005) -or $e.type -ne $(if($kind -eq 60002){1005}else{1007}) -or $e.param1 -ne $obj -or $e.num -ne 1){throw 'Story reward and completion event disagree'}
   }
   4 {if($e.type -ne 1006 -or $e.param1 -ne $s.action_id -or $e.param2 -ne $s.param1){throw 'Formation action event mismatch'}}
   5 {if($e.type -ne 1002 -or $e.param1 -ne 2){throw 'Main return event mismatch'}}
   6 {if($s.action_id -ne 1030 -or $e.type -ne 1008 -or $e.param1 -lt 1 -or $e.param2 -ne $s.param2){throw 'Equipment tutorial event mismatch'}}
  }
 }
 return @{steps=$steps.ToArray();dialogs=@($dialogs.ToArray()|Sort-Object dialogid,order)}
}
function Add-UnityStoryWrites($Data){
 foreach($entry in @(@('story_event',$Data.steps),@('story_dialog',$Data.dialogs))){
  $name=$entry[0]+'.json';$content=(Json @($entry[1]))+"`n"
  if($Mode -in @('Server','Both')){Add-Write ('unitydata/export/server/generated/json_server/'+$name) $content $null;if($ApplyRuntime){Add-Write ('unityserver/config/json/'+$name) $content $null}}
  if($Mode -in @('Client','Both')){Add-Write ('unitydata/export/client/source/Configs/'+$name) $content $null;if($ApplyRuntime){Add-Write ('unityclient/Assets/Resources/ProjectXData/Configs/'+$name) $content $null}}
 }
}
