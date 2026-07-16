param(
    [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if (-not $OutFile) {
    $OutFile = Join-Path $Root ".local\generated_min_schema.sql"
}

$tables = @{}
$badTables = @{}
$columnDefinitions = @{
    "item" = @{
        "name" = "VARCHAR(32) NOT NULL DEFAULT ''"
        "des" = "VARCHAR(256) NOT NULL DEFAULT ''"
        "pic" = "INT NOT NULL DEFAULT 0"
        "quality" = "INT NOT NULL DEFAULT 0"
        "type" = "INT NOT NULL DEFAULT 0"
        "use_type" = "INT NOT NULL DEFAULT 0"
        "sub_value" = "VARCHAR(256) NOT NULL DEFAULT ''"
        "limit_lv" = "INT NOT NULL DEFAULT 0"
        "limit_time" = "VARCHAR(256) NOT NULL DEFAULT ''"
        "sell" = "INT NOT NULL DEFAULT 0"
        "sort_priority" = "INT NOT NULL DEFAULT 1"
        "jiage" = "INT NOT NULL DEFAULT 0"
        "item_from" = "VARCHAR(256) NOT NULL DEFAULT ''"
        "item_source" = "VARCHAR(256) NOT NULL DEFAULT ''"
        "script" = "INT NOT NULL DEFAULT 0"
        "use_jump" = "INT NOT NULL DEFAULT 0"
    }
    "randombox_cfg" = @{
        "seq" = "INT NOT NULL DEFAULT 0"
        "box_id" = "INT NOT NULL DEFAULT 0"
        "item_id" = "INT NOT NULL DEFAULT 0"
        "odds" = "INT NOT NULL DEFAULT 0"
        "num" = "INT NOT NULL DEFAULT 0"
        "quality" = "INT NOT NULL DEFAULT 0"
        "quality_level" = "INT NOT NULL DEFAULT 0"
        "isnotice" = "INT NOT NULL DEFAULT 0"
        "day_limit" = "INT NOT NULL DEFAULT 0"
    }
}
@(
    "a","an","all","and","any","are","as","be","by","const","do","else","false","for","from",
    "if","in","int","is","it","join","limit","long","not","null","on","or","order","return",
    "select","set","sizeof","static","string","table","the","this","true","update","using",
    "values","void","where","while"
) | ForEach-Object { $badTables[$_] = $true }

function Normalize-Name($Name) {
    if (-not $Name) { return "" }
    return ($Name.Trim() -replace '^`+', '' -replace '`+$', '' -replace '[^A-Za-z0-9_]', '')
}

function Ensure-Table($Table) {
    $t = Normalize-Name $Table
    if (-not $t) { return }
    if ($t.Length -lt 3 -or $badTables.ContainsKey($t.ToLowerInvariant())) { return }
    if (-not $tables.ContainsKey($t)) {
        $tables[$t] = [ordered]@{}
    }
}

function Add-Col($Table, $Col) {
    $t = Normalize-Name $Table
    $c = Normalize-Name $Col
    if (-not $t -or -not $c) { return }
    if ($t.Length -lt 3 -or $badTables.ContainsKey($t.ToLowerInvariant())) { return }
    if ($badTables.ContainsKey($c.ToLowerInvariant())) { return }
    if ($c -match "^[A-Z][A-Za-z0-9_]*$") { return }
    if ($c -match "^[A-Z0-9_]{4,}$") { return }
    if ($c -match "^(p[A-Z].*|s[A-Z].*|m_[A-Za-z0-9_]+|LANGUAGE_TRANSFORM_.*|EM[A-Z0-9_]+|SHUT_.*)$") { return }
    Ensure-Table $t
    $tables[$t][$c] = $true
}

function Force-Col($Table, $Col) {
    $t = Normalize-Name $Table
    $c = Normalize-Name $Col
    if (-not $t -or -not $c) { return }
    if (-not $tables.ContainsKey($t)) {
        $tables[$t] = [ordered]@{}
    }
    $tables[$t][$c] = $true
}

function Add-Cols($Table, $Cols) {
    foreach ($c in $Cols) {
        $name = Normalize-Name $c
        if ($name -and $name -notmatch "^(select|from|where|order|group|limit|values|set|and|or|as|ifnull|unix_timestamp|count|sum|now|from_unixtime)$") {
            Add-Col $Table $name
        }
    }
}

$sqlFiles = Get-ChildItem (Join-Path $Root "server\sql") -File |
    Where-Object { $_.Extension -in @(".sql", ".txt") }
foreach ($file in $sqlFiles) {
    $text = Get-Content -Raw -Path $file.FullName -Encoding UTF8

    foreach ($m in [regex]::Matches($text, '(?is)\btruncate\s+table\s+`?([A-Za-z_][A-Za-z0-9_]*)`?')) {
        Ensure-Table $m.Groups[1].Value
    }

    foreach ($m in [regex]::Matches($text, '(?is)\binsert\s+into\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\s*\((.*?)\)\s*values')) {
        $table = $m.Groups[1].Value
        $cols = [regex]::Matches($m.Groups[2].Value, '`?([A-Za-z_][A-Za-z0-9_]*)`?') | ForEach-Object { $_.Groups[1].Value }
        foreach ($col in $cols) { Force-Col $table $col }
    }

    foreach ($m in [regex]::Matches($text, '(?is)\bCREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+`?([A-Za-z_][A-Za-z0-9_]*)`?')) {
        Ensure-Table $m.Groups[1].Value
    }

    foreach ($m in [regex]::Matches($text, '(?is)\bALTER\s+TABLE\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\s+ADD(?:\s+COLUMN)?\s+`?([A-Za-z_][A-Za-z0-9_]*)`?')) {
        Add-Col $m.Groups[1].Value $m.Groups[2].Value
    }
}

$srcFiles = Get-ChildItem (Join-Path $Root "server\src") -Recurse -File |
    Where-Object { $_.Extension -in @(".cpp", ".h") }
foreach ($file in $srcFiles) {
    $text = Get-Content -Raw -Path $file.FullName -Encoding UTF8

    foreach ($m in [regex]::Matches($text, '(?is)\binsert\s+into\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\s*\((.*?)\)\s*values')) {
        $cols = [regex]::Matches($m.Groups[2].Value, '`?([A-Za-z_][A-Za-z0-9_]*)`?') | ForEach-Object { $_.Groups[1].Value }
        Add-Cols $m.Groups[1].Value $cols
    }

    foreach ($m in [regex]::Matches($text, '(?is)\bupdate\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\s+set\s+(.*?)(?:\s+where|\s*"|;)')) {
        $table = $m.Groups[1].Value
        $cols = [regex]::Matches($m.Groups[2].Value, '`?([A-Za-z_][A-Za-z0-9_]*)`?\s*=') | ForEach-Object { $_.Groups[1].Value }
        Add-Cols $table $cols
    }

    foreach ($m in [regex]::Matches($text, '(?is)\bfrom\s+`?([A-Za-z_][A-Za-z0-9_]*)`?')) {
        Ensure-Table $m.Groups[1].Value
    }

    foreach ($m in [regex]::Matches($text, '(?is)\bjoin\s+`?([A-Za-z_][A-Za-z0-9_]*)`?')) {
        Ensure-Table $m.Groups[1].Value
    }

    foreach ($m in [regex]::Matches($text, '(?is)\bselect\s+(.*?)\s+from\s+`?([A-Za-z_][A-Za-z0-9_]*)`?(?:\s+where|\s+order|\s+limit|\s*"|;)')) {
        $table = $m.Groups[2].Value
        $select = $m.Groups[1].Value
        if ($select -notmatch "[,*]") {
            Add-Col $table $select
        } else {
            $cols = [regex]::Matches($select, '(?:^|,)\s*(?:[A-Za-z_][A-Za-z0-9_]*\.)?`?([A-Za-z_][A-Za-z0-9_]*)`?') | ForEach-Object { $_.Groups[1].Value }
            Add-Cols $table $cols
        }
    }
}

# Tables and fields known to be required by local direct login and startup.
$manual = @{
    "role_info" = @(
        "id","name","sex","head","model","level","exp","money","bd_money","package","bank_item",
        "bitset","sg_bitset","pet","title","zhanDouLi","petZhanDouLi","save_data","state",
        "login_time","reg_time","kuafu_state","admin","user_book","shenqi","wing","mount",
        "zhenfa","pet_equip","xianyuan","hots","chat_time","korea_money_gift"
    )
    "user_info" = @("id","name","password","role0","role1","role2","role3","money","bd_money","binding","phone_state","personal_name","personal_id","del_test_award")
    "user_info1" = @("id","name","password","role0","role1","role2","role3","money","bd_money","binding","phone_state","personal_name","personal_id","del_test_award")
    "tongtianta" = @("id","roleId")
    "notice" = @("id","type","msg","time_space","begin_time","end_time","type1")
    "cz_complete" = @("id","user_id","money","state","role_id","role_level","type","card_num","server_id","ad","is_deal","role_name","time","err_msg")
    "cz_notice" = @("id","user_id","msg","is_first","money")
    "online_user_num" = @("id","num","time")
}
foreach ($entry in $manual.GetEnumerator()) {
    Ensure-Table $entry.Key
    foreach ($col in $entry.Value) { Force-Col $entry.Key $col }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- Auto-generated local fallback schema. Do not use for production.")
$lines.Add("SET NAMES utf8;")
$lines.Add("SET FOREIGN_KEY_CHECKS=0;")

foreach ($table in ($tables.Keys | Sort-Object)) {
    $cols = New-Object System.Collections.Generic.List[string]
    $tableCols = @($tables[$table].Keys | Sort-Object)
    if ($tableCols -contains "id") {
        $cols.Add("  ``id`` INT NOT NULL AUTO_INCREMENT")
    } else {
        $cols.Add("  ``id`` INT NOT NULL AUTO_INCREMENT")
    }
    foreach ($col in $tableCols) {
        if ($col -eq "id") { continue }
        $definition = "MEDIUMTEXT NULL"
        if ($columnDefinitions.ContainsKey($table) -and $columnDefinitions[$table].ContainsKey($col)) {
            $definition = $columnDefinitions[$table][$col]
        }
        $cols.Add("  ``$col`` $definition")
    }
    $cols.Add("  PRIMARY KEY (``id``)")
    $lines.Add("")
    $lines.Add("CREATE TABLE IF NOT EXISTS ``$table`` (")
    $lines.Add(($cols -join ",`n"))
    $lines.Add(") ENGINE=InnoDB DEFAULT CHARSET=utf8;")
}

$lines.Add("")
$lines.Add("SET FOREIGN_KEY_CHECKS=1;")

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$lines | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Generated: $OutFile"
Write-Host "Tables: $($tables.Count)"
