param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [ValidateSet('Both','Client','Server')][string]$Mode = 'Both',
    [switch]$ValidateOnly
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Read-UnityVisualExcel.ps1')
$workbook = Join-Path $Root 'unitydata\excel\jingjie_config.xlsx'
$sourceRows = @(Read-UnityVisualExcelRows $workbook)
if ($sourceRows.Count -ne 550) { throw 'Unity JingJie must contain 550 small stages.' }
$visuals = @(Get-Content -LiteralPath (Join-Path $Root 'unitydata\export\client\source\Configs\role-visuals.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
function Read-Integer($row, [string]$key) {
    $raw = [string]$row[$key]
    if ($raw -cnotmatch '^\d+$') { throw "Invalid JingJie integer: $key=$raw" }
    return [long]$raw
}
function Read-Range([string]$raw) {
    if ($raw -cnotmatch '^\d+;\d+$') { throw "Invalid JingJie range: $raw" }
    $parts = [int[]]$raw.Split(';')
    if ($parts[0] -gt $parts[1]) { throw "Reversed JingJie range: $raw" }
    return ,$parts
}
$rows = @()
foreach ($r in $sourceRows) {
    $id = Read-Integer $r 'jingjie_id'
    if ($id -ne $rows.Count + 1) { throw "Non-contiguous JingJie id=$id" }
    $realm = Read-Integer $r 'realm'
    $stage = Read-Integer $r 'stage'
    $next = Read-Integer $r 'next_id'
    if ($realm -ne [math]::Ceiling($id / 10) -or $stage -ne (($id - 1) % 10 + 1) -or
        $next -ne $(if ($id -eq 550) { 0 } else { $id + 1 })) { throw "Invalid JingJie progression at id=$id" }
    $quality = Read-Integer $r 'quality'
    $exp = Read-Integer $r 'exp'
    $need = Read-Integer $r 'need_exp'
    $probability = Read-Integer $r 'upgrade_probability'
    $penalty = Read-Integer $r 'fail_upgrade'
    $threshold = Read-Integer $r 'Threshold'
    $visualStage = Read-Integer $r 'visual_stage'
    if ($quality -lt 1 -or $quality -gt 7 -or $exp -le 0 -or $need -le 0 -or
        $probability -gt 10000 -or $penalty -gt 10000 -or $visualStage -lt 1 -or $visualStage -gt 10) {
        throw "Invalid JingJie parameters at id=$id"
    }
    $number = Read-Range ([string]$r.thunder_number)
    $damage = Read-Range ([string]$r.thunder_damage)
    $big = $stage -eq 10 -and $next -ne 0
    if ($big) {
        if ($number[0] -lt 1 -or $number[1] -gt 20 -or $damage[0] -lt 1 -or
            $number[0] * $damage[0] -gt 100 -or $number[1] * $damage[1] -le 100 -or $threshold -le 0) {
            throw "JingJie thunder ranges cannot express both outcomes at id=$id"
        }
    } elseif ($probability -ne 10000 -or $number[1] -ne 0 -or $damage[1] -ne 0 -or $penalty -ne 0 -or $threshold -ne 0) {
        throw "Ordinary/terminal JingJie stage must disable thunder mechanics: id=$id"
    }
    $icon = [string]$r.icon
    if ($icon -cnotmatch '^role_\{sex\}_([0-9]{2})$') { throw "Invalid JingJie Spine key: $icon" }
    $visualId = [int]$Matches[1]
    if (@($visuals | Where-Object visual_id -eq $visualId).Count -ne 1) { throw "Missing JingJie visual=$visualId" }
    foreach ($sex in @('m','w')) {
        $prefab = Join-Path $Root ('unityclient\Assets\Prefabs\Spine\UI\Role\role_{0}_{1:d2}.prefab' -f $sex,$visualId)
        if (-not (Test-Path -LiteralPath $prefab)) { throw "Missing JingJie role prefab: $prefab" }
    }
    $attrs = ConvertFrom-Json -InputObject ('[' + [string]$r.attr + ']') -NoEnumerate
    if ($attrs.Count -ne 7 -or (($attrs | ForEach-Object { $_[0] }) -join ',') -cne '1,2,3,4,19,20,21' -or
        @($attrs | Where-Object { $_.Count -ne 2 -or $_[1] -le 0 -or $_[1] -gt [int]::MaxValue }).Count) {
        throw "Invalid JingJie cumulative attributes at id=$id"
    }
    $rows += [ordered]@{ jingjie_id=$id; name=[string]$r.name; realm=$realm; stage=$stage; quality=$quality;
        need_exp=$need; exp=$exp; upgrade_probability=$probability; thunder_number=$number; thunder_damage=$damage;
        fail_upgrade=$penalty; Threshold=$threshold; attr=@($attrs | ForEach-Object { ,([int[]]$_) });
        icon=$icon; visual_stage=$visualStage; next_id=$next }
}
$rules = [ordered]@{}
foreach ($r in @(Read-UnityVisualExcelRows $workbook 2)) {
    if ($rules.Contains([string]$r.key)) { throw "Duplicate JingJie rule=$($r.key)" }
    $rules[[string]$r.key] = Read-Integer $r 'value'
}
foreach ($key in @('online_interval_ms','offline_cap_seconds','offline_rate','cloud_intro_ms','lightning_interval_ms','result_stay_ms','minimum_success_display_hp')) {
    if (-not $rules.Contains($key) -or $rules[$key] -le 0) { throw "Missing/invalid JingJie rule=$key" }
}
if ($rules.online_interval_ms -ne 5000 -or $rules.offline_cap_seconds -ne 172800 -or
    $rules.offline_rate -ne 10000 -or $rules.cloud_intro_ms -ne 3000 -or $rules.minimum_success_display_hp -ne 1) {
    throw 'JingJie rules differ from confirmed experience/cloud/display contracts.'
}
if ($ValidateOnly) { Write-Output 'Unity JingJie validation passed: 550 stages, 54 breakthroughs, full rule set.'; return }
function Write-Config([string]$relative, [string]$content) {
    $path = Join-Path $Root $relative
    if ((Test-Path -LiteralPath $path) -and [IO.File]::ReadAllText($path,[Text.Encoding]::UTF8) -ceq $content) { return }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $path) | Out-Null
    [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false))
}
$dataJson = ConvertTo-Json -InputObject @($rows) -Depth 12 -Compress
$rulesJson = ConvertTo-Json -InputObject $rules -Depth 4 -Compress
if ($Mode -in @('Both','Client')) {
    foreach ($base in @('unitydata\export\client\source\Configs','unityclient\Assets\Resources\ProjectXData\Configs')) {
        Write-Config (Join-Path $base 'jingjie.json') $dataJson
        Write-Config (Join-Path $base 'jingjie-rules.json') $rulesJson
    }
}
if ($Mode -in @('Both','Server')) {
    foreach ($base in @('unitydata\export\server\generated\json_server','unityserver\config\json')) {
        Write-Config (Join-Path $base 'jingjie_config.json') $dataJson
        Write-Config (Join-Path $base 'jingjie_rules.json') $rulesJson
    }
}
Write-Output "Unity JingJie export passed: 550 stages / 54 breakthroughs; mode=$Mode."
