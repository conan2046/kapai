[CmdletBinding()]
param(
    [string]$Root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path,
    [Parameter(Mandatory)][string]$OriginalExecutable,
    [Parameter(Mandatory)][string]$OriginalConfigRoot,
    [ValidateSet('nuwa','shield_core','shield_full','pursuit','hero15b','hero15b_battle','hero15a','hero15a_battle','hero61a','hero61a_battle','hero65a','hero65a_battle','hero65b','hero65b_battle','hero61b','hero61b_battle','all_heroes_battle')][string]$Scope='nuwa',
    [ValidateRange(0,719)][int]$EncounterStart=0,
    [ValidateRange(1,720)][int]$EncounterCount=1,
    [ValidateSet('standard','closure','loadout')][string]$BattleProfile='standard',
    [switch]$Trace,
    [string]$ReferenceCorrectionManifest='',
    [string]$CurrentExecutable='',
    [string]$EvidenceDirectory=''
)
$ErrorActionPreference='Stop'
if($Scope -eq 'all_heroes_battle' -and $EncounterStart+$EncounterCount -gt 720){throw 'Encounter range exceeds the 720 encounter batch plan'}
if(-not $CurrentExecutable){$CurrentExecutable=Join-Path $Root '.local/unityserver-build/server-win/Debug/kapai.exe'}
if(-not $EvidenceDirectory){$EvidenceDirectory=Join-Path $Root '.local/hero-affix-integration/binary-diff-nuwa'}
$null=New-Item -ItemType Directory -Force -Path $EvidenceDirectory
$local=Join-Path $Root '.local/hero-affix-integration'
$manifest=Get-Content -LiteralPath (Join-Path $local 'original-source-fingerprint.json') -Raw -Encoding utf8|ConvertFrom-Json
if((Resolve-Path -LiteralPath $OriginalConfigRoot).Path -ne (Resolve-Path -LiteralPath (Join-Path $manifest.root 'server/config')).Path){throw 'Original config does not belong to the frozen reference checkout'}
$fixture=Join-Path $Root 'unityserver/tests/HeroAffixBinaryDiff.inc'
$originalFixture=Join-Path $manifest.root 'server/tests/HeroAffixBinaryDiff.inc'
$fixtureHash=(Get-FileHash -LiteralPath $fixture).Hash
if((Get-FileHash -LiteralPath $originalFixture).Hash -ne $fixtureHash){throw 'Reference and current fixtures differ'}
$baselineSource=Join-Path $local 'pre-harness-fight_hero_build.cpp'
$entry='server/src/fight_hero_build.cpp'
$entryRecord=@($manifest.source_files|Where-Object {$_.path.Replace('\','/') -eq $entry})
if($entryRecord.Count -ne 1 -or (Get-FileHash -LiteralPath $baselineSource).Hash -ne $entryRecord[0].sha256){throw 'Original regression baseline is not the recorded Git source'}
$hook=@'
    const char* binaryDiffMode=std::getenv("HERO_AFFIX_BINARY_DIFF");
    if(binaryDiffMode && std::string(binaryDiffMode)=="1") {
#define HERO_AFFIX_BINARY_DIFF_LEGACY
#include "../tests/HeroAffixBinaryDiff.inc"
#undef HERO_AFFIX_BINARY_DIFF_LEGACY
    }
'@
$hook=$hook.Replace("`r`n","`n")+"`n"
function Assert-OriginalBattleSource {
    foreach($file in $manifest.source_files){
        $path=Join-Path $manifest.root $file.path
        if($file.path.Replace('\','/') -eq $entry){
            $actual=[IO.File]::ReadAllText($path,[Text.Encoding]::UTF8).Replace("`r`n","`n")
            $baseline=[IO.File]::ReadAllText($baselineSource,[Text.Encoding]::UTF8).Replace("`r`n","`n")
            if([regex]::Matches($actual,[regex]::Escape($hook)).Count -ne 1 -or $actual.Replace($hook,'') -cne $baseline){throw 'Reference battle code changed beyond the regression-only include'}
        }elseif((Get-FileHash -LiteralPath $path).Hash -ne $file.sha256){throw "Reference source changed: $($file.path)"}
    }
}
Assert-OriginalBattleSource
$referenceModel='pristine-original-production-source'
function Assert-ReferenceCorrection {
    if(-not $ReferenceCorrectionManifest){return}
    $correction=Get-Content -LiteralPath $ReferenceCorrectionManifest -Raw -Encoding UTF8|ConvertFrom-Json
    $source=Join-Path $manifest.root 'server/src/fight.cpp'
    if($correction.reference_model -ne 'frozen-original-with-two-array-bound-corrections' -or $correction.original_source_mutated -or $correction.pristine_original_equivalence_claimed){throw 'Invalid corrected-reference contract'}
    if((Get-FileHash -LiteralPath $source).Hash -ne $correction.frozen_sha256){throw 'Frozen query source changed'}
    $expected=[IO.File]::ReadAllText($source,[Text.Encoding]::UTF8)
    foreach($name in @('shieldBuff','BuffList')){
        $old='for(uint8 i=0;i < sizeof('+ $name +');i++)'
        $new='for(uint8 i=0;i < sizeof('+ $name +')/sizeof('+ $name +'[0]);i++)'
        if([regex]::Matches($expected,[regex]::Escape($old)).Count -ne 1){throw 'Reference query replacement is not unique'}
        $expected=$expected.Replace($old,$new)
    }
    if([IO.File]::ReadAllText($correction.corrected_source,[Text.Encoding]::UTF8) -cne $expected -or (Get-FileHash -LiteralPath $correction.corrected_source).Hash -ne $correction.corrected_sha256){throw 'Reference changes exceed two query bounds'}
    if((Resolve-Path -LiteralPath $OriginalExecutable).Path -ne (Resolve-Path -LiteralPath $correction.executable).Path -or (Get-FileHash -LiteralPath $OriginalExecutable).Hash -ne $correction.binary_sha256){throw 'Corrected reference binary does not match provenance'}
}
Assert-ReferenceCorrection
if($ReferenceCorrectionManifest){$referenceModel='frozen-original-with-two-array-bound-corrections';Copy-Item -LiteralPath $ReferenceCorrectionManifest -Destination (Join-Path $EvidenceDirectory 'reference-correction-manifest.json')}
function Get-CombatInputFingerprints {
    $hashes=[ordered]@{}
    foreach($name in @('hero_combat.xlsx','fabao.xlsx','suit.xlsx')){
        $hashes['workbook/'+$name]=(Get-FileHash -LiteralPath (Join-Path $Root "unitydata/excel/$name")).Hash
    }
    foreach($side in @('original','current')){
        $config=if($side -eq 'original'){$OriginalConfigRoot}else{Join-Path $Root 'unityserver/config'}
        foreach($kind in @('xml','json')){
            $directory=Join-Path $config $kind
            foreach($file in @(Get-ChildItem -LiteralPath $directory -File -Recurse|Sort-Object FullName)){
                $relative=[IO.Path]::GetRelativePath($config,$file.FullName).Replace('\','/')
                $hashes[$side+'/'+$relative]=(Get-FileHash -LiteralPath $file.FullName).Hash
            }
        }
    }
    return $hashes
}
$inputBefore=Get-CombatInputFingerprints
$inputBefore|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'input-fingerprints.json') -Encoding utf8
$before=@{original=(Get-FileHash -LiteralPath $OriginalExecutable).Hash;current=(Get-FileHash -LiteralPath $CurrentExecutable).Hash}
foreach($exe in @($OriginalExecutable,$CurrentExecutable)){
    if((Get-Item -LiteralPath $exe).LastWriteTimeUtc -lt (Get-Item -LiteralPath $fixture).LastWriteTimeUtc){throw "Fixture is newer than binary; rebuild: $exe"}
}
$binaryTimings=@{}
function Read-Observations([string]$Label,[string]$Executable,[string]$Directory,[string]$Argument){
    $info=[Diagnostics.ProcessStartInfo]::new();$info.FileName=(Resolve-Path -LiteralPath $Executable).Path;$info.WorkingDirectory=$Directory
    $info.ArgumentList.Add($Argument);$info.Environment['HERO_AFFIX_BINARY_DIFF']='1'
    $info.Environment['HERO_AFFIX_DIFF_TRACE']=if($Trace){'1'}else{'0'}
    $info.Environment['HERO_AFFIX_DIFF_SCOPE']=$Scope
    $info.Environment['HERO_AFFIX_BATTLE_PROFILE']=$BattleProfile
    if($Scope -eq 'all_heroes_battle') {
        $info.Environment['HERO_AFFIX_ENCOUNTER_START']=[string]$EncounterStart
        $info.Environment['HERO_AFFIX_ENCOUNTER_COUNT']=[string]$EncounterCount
    }
    $info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $info.StandardOutputEncoding=[Text.Encoding]::UTF8;$info.StandardErrorEncoding=[Text.Encoding]::UTF8
    $process=[Diagnostics.Process]::new();$process.StartInfo=$info
    $timer=[Diagnostics.Stopwatch]::StartNew()
    try {
        if(-not $process.Start()){throw "Could not start $Label"}
        $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        $timeoutMs=if($Scope -like '*_battle'){60000}else{30000}
        $completed=$process.WaitForExit($timeoutMs)
        if(-not $completed){$process.Kill($true);$null=$process.WaitForExit(5000)}
        $output=$stdout.GetAwaiter().GetResult()+"`n"+$stderr.GetAwaiter().GetResult()
        $timer.Stop();$binaryTimings[$Label]=[Math]::Round($timer.Elapsed.TotalSeconds,3)
        [IO.File]::WriteAllText((Join-Path $EvidenceDirectory ($Label+'-runtime.log')),$output,[Text.UTF8Encoding]::new($false))
        @{seconds=$binaryTimings[$Label];timeout_ms=$timeoutMs;completed=$completed;exit_code=$process.ExitCode}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $EvidenceDirectory ($Label+'-timing.json')) -Encoding utf8
        if(-not $completed -or $process.ExitCode -ne 0) {
            $partial=[Collections.Generic.List[object]]::new();$malformed=0;$partialMarker='BINARY_DIFF_RESULT '
            foreach($line in ($output -split '\r?\n')) {
                if(-not $line.StartsWith($partialMarker)){continue}
                try{$partial.Add(($line.Substring($partialMarker.Length)|ConvertFrom-Json -AsHashtable))}catch{$malformed++}
            }
            ConvertTo-Json -InputObject $partial.ToArray() -Depth 20|Set-Content -LiteralPath (Join-Path $EvidenceDirectory ($Label+'-partial-observations.json')) -Encoding utf8
            @{complete=$false;acceptance_passed=$false;checkpoints=$partial.Count;malformed_lines=$malformed;completed=$completed;exit_code=$process.ExitCode}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $EvidenceDirectory ($Label+'-failure.json')) -Encoding utf8
            if($Label -eq 'current' -and $null -ne $original){
                $prefixDifferences=[Collections.Generic.List[object]]::new();$prefixById=@{}
                foreach($row in $original){$prefixById[$row.id]=$row}
                foreach($row in $partial){
                    if(-not $prefixById.ContainsKey($row.id)){continue}
                    $reference=$prefixById[$row.id]
                    foreach($field in $reference.Keys){
                        if((ConvertTo-Json -InputObject $reference[$field] -Depth 20 -Compress) -cne (ConvertTo-Json -InputObject $row[$field] -Depth 20 -Compress)){
                            $prefixDifferences.Add(@{id=$row.id;field=$field;original=$reference[$field];current=$row[$field]})
                        }
                    }
                }
                @{complete=$false;acceptance_passed=$false;checkpoints=$partial.Count;differences=$prefixDifferences.ToArray()}|ConvertTo-Json -Depth 20|Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'partial-prefix-diff.json') -Encoding utf8
            }
        }
        if(-not $completed){throw "Offline binary timed out after $timeoutMs ms: $Label; partial runtime output saved"}
        if($process.ExitCode -ne 0){throw "Offline binary $Label exited $($process.ExitCode); inspect its runtime log"}
        $marker='BINARY_DIFF_RESULT '
        $rows=@($output -split '\r?\n'|Where-Object {$_.StartsWith($marker)}|ForEach-Object {$_.Substring($marker.Length)|ConvertFrom-Json -AsHashtable})
        $expectedCount=switch($Scope){'nuwa'{48};'shield_core'{30};'shield_full'{186};'pursuit'{132};'hero15b'{120};'hero15b_battle'{480};'hero15a'{216};'hero15a_battle'{480};'hero61a'{72};'hero61a_battle'{480};'hero65a'{84};'hero65a_battle'{480};'hero65b'{96};'hero65b_battle'{480};'hero61b'{108};'hero61b_battle'{480}}
        if($Scope -eq 'all_heroes_battle'){$expectedCount=12*$EncounterCount}
        if($rows.Count -ne $expectedCount -or @($rows.id|Select-Object -Unique).Count -ne $expectedCount){throw "Offline binary $Label did not produce $expectedCount unique $Scope fixtures"}
        if($Scope -eq 'all_heroes_battle') {
            if($BattleProfile -eq 'loadout') {
                $loadouts=@($output -split '\r?\n'|Where-Object {$_.StartsWith('BINARY_DIFF_LOADOUT ')}|ForEach-Object {$_.Substring('BINARY_DIFF_LOADOUT '.Length)|ConvertFrom-Json -AsHashtable})
                if($loadouts.Count -ne $EncounterCount -or @($loadouts|Where-Object {$_.units.Count -ne 10 -or @($_.units|Where-Object {$_.equipment.Count -ne 4 -or $_.artifacts.Count -ne 2}).Count}).Count){throw 'Formal 4 equipment + 2 artifacts per member evidence missing'}
                ConvertTo-Json -InputObject $loadouts -Depth 18|Set-Content -LiteralPath (Join-Path $EvidenceDirectory ($Label+'-formal-loadouts.json')) -Encoding utf8
                $performance=@($output -split '\r?\n'|Where-Object {$_.StartsWith('BINARY_DIFF_PERF ')}|ForEach-Object {$_.Substring('BINARY_DIFF_PERF '.Length)|ConvertFrom-Json -AsHashtable})
                if($performance.Count -ne $EncounterCount){throw 'Per-battle calculation performance evidence missing'}
                ConvertTo-Json -InputObject $performance -Depth 12|Set-Content -LiteralPath (Join-Path $EvidenceDirectory ($Label+'-performance.json')) -Encoding utf8
            }
            if(@($rows|Where-Object {$_.units.Count -ne 10 -or @($_.units|Where-Object {$_[0] -le 9}).Count -ne 5 -or @($_.units|Where-Object {$_[0] -gt 9}).Count -ne 5}).Count){throw "Offline binary $Label did not preserve exactly ten members in 5v5"}
            if($Label -eq 'current') {
                $coverage=@($output -split '\r?\n'|Where-Object {$_.StartsWith('BINARY_DIFF_COVERAGE ')}|ForEach-Object {$_.Substring('BINARY_DIFF_COVERAGE '.Length)|ConvertFrom-Json -AsHashtable})
                if($coverage.Count -ne $EncounterCount){throw 'Actual trigger coverage records missing'}
                $expected=@{};$actual=@{}
                foreach($match in $coverage) {
                    foreach($skill in $match.expected){$expected[($skill -join '/')]=1}
                    foreach($hit in $match.observed){
                        $key=$hit[0..2] -join '/'
                        if($hit[4] -gt 0){
                            if(-not $actual.ContainsKey($key)){$actual[$key]=@{}}
                            $actual[$key][$hit[3]]=[int]$actual[$key][$hit[3]]+[int]$hit[4]
                        }
                    }
                }
                $untriggered=@($expected.Keys|Where-Object {-not $actual.ContainsKey($_)}|Sort-Object)
                @{battle_profile=$BattleProfile;encounter_start=$EncounterStart;encounter_count=$EncounterCount;expected_in_batch=$expected.Count;actually_triggered_in_batch=@($expected.Keys|Where-Object {$actual.ContainsKey($_)}).Count;untriggered_in_batch=$untriggered;observations_by_skill_and_kind=$actual;encounters=$coverage;all_skills_passed=($untriggered.Count -eq 0)}|ConvertTo-Json -Depth 18|Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'actual-trigger-coverage.json') -Encoding utf8
            }
        }
        if($Scope -eq 'shield_core' -and -not @($rows|Where-Object {$_.id -like '*_affix44_*'}|ForEach-Object {$_.buffs|Where-Object {$_[3] -gt 255}}).Count){throw "Offline binary $Label did not exercise the int duration boundary"}
        ConvertTo-Json -InputObject $rows -Depth 20|Set-Content -LiteralPath (Join-Path $EvidenceDirectory ($Label+'-observations.json')) -Encoding utf8
        return ,$rows
    }finally{$process.Dispose()}
}
$original=Read-Observations 'original' $OriginalExecutable $OriginalConfigRoot '--hero-build-regression'
$current=Read-Observations 'current' $CurrentExecutable (Join-Path $Root 'unityserver/config') '--combat-data-regression'
$byId=@{};foreach($row in $current){$byId[$row.id]=$row}
$differences=[Collections.Generic.List[object]]::new()
foreach($row in $original){
    if(-not $byId.ContainsKey($row.id)){throw "Missing current fixture: $($row.id)"}
    $next=$byId[$row.id]
    if(($row.Keys|Sort-Object|ConvertTo-Json -Compress) -cne ($next.Keys|Sort-Object|ConvertTo-Json -Compress)){throw "Fixture output schema differs: $($row.id)"}
    foreach($field in $row.Keys){
        $left=ConvertTo-Json -InputObject $row[$field] -Depth 20 -Compress
        $right=ConvertTo-Json -InputObject $next[$field] -Depth 20 -Compress
        if($left -cne $right){$differences.Add(@{id=$row.id;field=$field;original=$row[$field];current=$next[$field]})}
    }
}
Assert-OriginalBattleSource
if($BattleProfile -eq 'loadout') {
    $left=Get-Content -LiteralPath (Join-Path $EvidenceDirectory 'original-formal-loadouts.json') -Raw -Encoding UTF8
    $right=Get-Content -LiteralPath (Join-Path $EvidenceDirectory 'current-formal-loadouts.json') -Raw -Encoding UTF8
    if($left -cne $right){throw 'Original/current formal equipment or deterministic affix inputs differ'}
}
if(($inputBefore|ConvertTo-Json -Depth 4 -Compress) -cne ((Get-CombatInputFingerprints)|ConvertTo-Json -Depth 4 -Compress)){throw 'Formal workbook or original/current runtime config changed during comparison'}
if((Get-FileHash -LiteralPath $OriginalExecutable).Hash -ne $before.original -or (Get-FileHash -LiteralPath $CurrentExecutable).Hash -ne $before.current -or (Get-FileHash -LiteralPath $fixture).Hash -ne $fixtureHash){throw 'Binary or shared fixture changed during comparison'}
$report=@{scope=$Scope;fields='HP/attributes/Buff/all CD/both teams rage/RNG/protocol bytes';original_commit=$manifest.commit;original_source_files=$manifest.source_files.Count;original_battle_source_unchanged=$true;fixture_sha256=$fixtureHash;binary_sha256=$before;cases=$original.Count;differences=$differences.ToArray();passed=($differences.Count -eq 0)}
$report.process_seconds=$binaryTimings
$report.reference_model=$referenceModel
$report.pristine_original_equivalence_claimed=(-not [bool]$ReferenceCorrectionManifest)
Assert-ReferenceCorrection
$report.battle_profile=$BattleProfile
$report.input_fingerprints_unchanged=$true
if($Scope -eq 'all_heroes_battle') {
    $coverage=Get-Content -LiteralPath (Join-Path $EvidenceDirectory 'actual-trigger-coverage.json') -Raw -Encoding UTF8|ConvertFrom-Json
    $report.encounters=$EncounterCount;$report.encounter_start=$EncounterStart;$report.max_rounds=12;$report.checkpoints=12*$EncounterCount;$report.members_per_battle=10
    $report.all_skills_triggered_in_batch=$coverage.all_skills_passed
    $report.acceptance_passed=($report.passed -and $coverage.all_skills_passed)
}elseif($Scope -like '*_battle'){$report.encounters=60;$report.max_rounds=8;$report.checkpoints=480}
$report|ConvertTo-Json -Depth 20|Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'results.json') -Encoding utf8
Write-Output ('Original binary diff: cases={0}; differing fields={1}; original source protected=True' -f $original.Count,$differences.Count)
if($differences.Count){$differences|Select-Object -First 6 id,field|Format-Table -AutoSize;throw 'Original/current battle outcomes differ; diagnose the saved observations before rerunning'}
$global:LASTEXITCODE=0
