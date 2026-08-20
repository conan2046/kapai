param(
    [string]$OutputPath = ".local/unity-validation/steam-sqlite-s0-sql-inventory-latest.json"
)

$ErrorActionPreference = "Stop"
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$SchemaPath = Join-Path $Root "server\sql\local_min_schema.sql"
$SourceRoot = Join-Path $Root "server\src"

function Get-Matches([string]$Pattern, [string[]]$Paths) {
    $args = @("-n", "-i", "--no-heading", "--with-filename", "--glob", "!build/**", "--glob", "!.local/**", "--glob", "!tools/local/vcpkg/**", "--", $Pattern) + $Paths
    $lines = @(& rg @args 2>$null)
    if ($LASTEXITCODE -notin @(0, 1)) {
        throw "rg failed for pattern: $Pattern"
    }
    return $lines
}

function New-Count([string]$Name, [string]$Pattern, [string[]]$Paths) {
    $hits = @(Get-Matches -Pattern $Pattern -Paths $Paths)
    $files = @($hits | ForEach-Object {
        $fileMatch = [regex]::Match($_, '^(.*):\d+:')
        if ($fileMatch.Success) { $fileMatch.Groups[1].Value }
    } | Sort-Object -Unique)
    return [ordered]@{
        name = $Name
        pattern = $Pattern
        matches = $hits.Count
        files = $files.Count
    }
}

$sourcePaths = @($SourceRoot)
$schemaPaths = @($SchemaPath)
$allPaths = @($SourceRoot, $SchemaPath, (Join-Path $Root "server\script"))
$api = @(
    (New-Count "query" 'pDb->Query\(' $sourcePaths),
    (New-Count "getRow" 'GetRow\(' $sourcePaths),
    (New-Count "getRowNum" 'GetRowNum\(' $sourcePaths),
    (New-Count "insertId" 'InsertId\(' $sourcePaths),
    (New-Count "mysqlApi" 'mysql_[A-Za-z0-9_]+' $sourcePaths)
)
$schema = @(
    (New-Count "createTable" '^CREATE TABLE' $schemaPaths),
    (New-Count "autoIncrement" 'AUTO_INCREMENT' $schemaPaths),
    (New-Count "engineInnoDb" 'ENGINE=InnoDB' $schemaPaths)
)
$dialect = @(
    (New-Count "unixTimestamp" 'unix_timestamp\(' $allPaths),
    (New-Count "fromUnixTime" 'from_unixtime\(' $allPaths),
    (New-Count "concat" 'concat\(' $allPaths),
    (New-Count "truncateTable" 'truncate table' $allPaths),
    (New-Count "onDuplicateKey" 'on duplicate key' $allPaths),
    (New-Count "replaceInto" 'replace into' $allPaths),
    (New-Count "limitOffsetCount" 'LIMIT [^;]*,' $allPaths)
)
$hashFiles = @(
    "server/src/gyu/g_database.h",
    "server/src/gyu/g_database.cpp",
    "server/CMakeLists.txt",
    "server/config/config",
    "server/sql/local_min_schema.sql",
    "tools/local/Invoke-ProtocolSmoke.ps1",
    "tools/local/Run-LocalVerification.ps1"
)
$hashes = foreach ($relative in $hashFiles) {
    $full = Join-Path $Root $relative
    [ordered]@{
        path = $relative.Replace('\', '/')
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash
    }
}
$report = [ordered]@{
    schemaVersion = 1
    generatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    scope = "SteamSqliteFoundation/S0"
    api = $api
    schema = $schema
    dialect = $dialect
    authoritativeHashes = @($hashes)
}
$resolvedOutput = if ([IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path $Root $OutputPath }
New-Item -ItemType Directory -Force -Path (Split-Path $resolvedOutput -Parent) | Out-Null
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedOutput -Encoding utf8NoBOM
Write-Host "SQLite migration inventory written: $resolvedOutput"
