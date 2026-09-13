[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$workbookPath = Join-Path $Root 'outputs\answer-question-bank\question.xlsx'
$sourcePath = Join-Path $Root 'server\config\source\question.csv'
$workbookImporter = Join-Path $Root 'tools\local\Import-QuestionWorkbook.py'
$sqliteSeedPath = Join-Path $Root 'server\sql\sqlite\seeds\question.sql'
$mysqlSeedPath = Join-Path $Root 'server\sql\mysql\seeds\question.sql'
$sqliteSchemaPath = Join-Path $Root 'server\sql\sqlite\001_initial_schema.sql'
$mysqlSchemaPath = Join-Path $Root 'server\sql\local_min_schema.sql'
$sqliteBegin = '-- BEGIN GENERATED QUESTION BANK SEED'
$sqliteEnd = '-- END GENERATED QUESTION BANK SEED'
$mysqlBegin = '-- BEGIN GENERATED QUESTION BANK SEED'
$mysqlEnd = '-- END GENERATED QUESTION BANK SEED'

$python = (Get-Command python -ErrorAction Stop).Source
$importArguments = @($workbookImporter, '--workbook', $workbookPath, '--csv', $sourcePath)
if ($ValidateOnly) { $importArguments += '--validate-only' }
& $python @importArguments
if ($LASTEXITCODE -ne 0) { throw "Question workbook import failed with exit code $LASTEXITCODE." }

function Quote-SqlString([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}

function Set-GeneratedBlock([string]$Path, [string]$BeginMarker, [string]$EndMarker, [string]$Block) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $Path
    $pattern = '(?s)' + [regex]::Escape($BeginMarker) + '.*?' + [regex]::Escape($EndMarker)
    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace($content, $pattern, $Block.Trim())
    } else {
        $content = $content.TrimEnd() + "`r`n`r`n" + $Block.Trim() + "`r`n"
    }
    Set-Content -LiteralPath $Path -Encoding UTF8 -NoNewline -Value $content
}

$rows = @(Import-Csv -LiteralPath $sourcePath -Encoding UTF8)
if ($rows.Count -lt 21) { throw 'question.csv must contain at least 21 data rows.' }

$expectedId = 1
foreach ($row in $rows) {
    if ([int]$row.id -ne $expectedId) {
        throw "question.csv ids must be sequential from 1. Expected $expectedId, got $($row.id)."
    }
    foreach ($field in @('question', 'answer1', 'answer2', 'answer3', 'answer4')) {
        if ([string]::IsNullOrWhiteSpace([string]$row.$field)) {
            throw "question.csv row $expectedId has an empty $field."
        }
    }
    if ($row.question -notmatch '[\u3400-\u9fff]') {
        throw "question.csv row $expectedId is not a Chinese question."
    }
    $expectedId++
}

$valueRows = @($rows | ForEach-Object {
    '(' + (@(
        [int]$_.id,
        (Quote-SqlString $_.question),
        (Quote-SqlString $_.answer1),
        (Quote-SqlString $_.answer2),
        (Quote-SqlString $_.answer3),
        (Quote-SqlString $_.answer4)
    ) -join ',') + ')'
})
$valuesSql = $valueRows -join ",`r`n"
$nextId = $rows.Count + 1

$sqliteSql = @"
$sqliteBegin
DELETE FROM question;
INSERT INTO question (id,question,answer1,answer2,answer3,answer4) VALUES
$valuesSql;
DELETE FROM sqlite_sequence WHERE name='question';
INSERT INTO sqlite_sequence(name,seq) VALUES('question',$($rows.Count));
$sqliteEnd
"@

$mysqlSql = @"
$mysqlBegin
SET NAMES utf8mb4;
DELETE FROM question;
INSERT INTO question (id,question,answer1,answer2,answer3,answer4) VALUES
$valuesSql;
ALTER TABLE question AUTO_INCREMENT=$nextId;
$mysqlEnd
"@

if ($ValidateOnly) {
    $checks = @(
        @{ Path = $sqliteSeedPath; Expected = $sqliteSql.Trim(); Label = 'SQLite question seed' },
        @{ Path = $mysqlSeedPath; Expected = $mysqlSql.Trim(); Label = 'MySQL question seed' }
    )
    foreach ($check in $checks) {
        if (-not (Test-Path -LiteralPath $check.Path)) { throw "$($check.Label) is missing. Run exporter." }
        $actual = (Get-Content -Raw -Encoding UTF8 -LiteralPath $check.Path).Trim()
        if ($actual -ne $check.Expected) { throw "$($check.Label) is stale. Run exporter." }
    }
    $sqliteSchema = Get-Content -Raw -Encoding UTF8 -LiteralPath $sqliteSchemaPath
    if (-not $sqliteSchema.Contains($sqliteSql.Trim())) { throw 'SQLite initial schema does not contain the question bank seed.' }
    $mysqlSchema = Get-Content -Raw -Encoding UTF8 -LiteralPath $mysqlSchemaPath
    if (-not $mysqlSchema.Contains($mysqlSql.Trim())) { throw 'MySQL local schema does not contain the question bank seed.' }
    $duplicates = @($rows | Group-Object question | Where-Object Count -gt 1)
    Write-Host "Question bank valid: $($rows.Count) Chinese rows; duplicate question texts=$($duplicates.Count)."
    return
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $sqliteSeedPath) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $mysqlSeedPath) | Out-Null
Set-Content -LiteralPath $sqliteSeedPath -Encoding UTF8 -NoNewline -Value $sqliteSql.Trim()
Set-Content -LiteralPath $mysqlSeedPath -Encoding UTF8 -NoNewline -Value $mysqlSql.Trim()
Set-GeneratedBlock -Path $sqliteSchemaPath -BeginMarker $sqliteBegin -EndMarker $sqliteEnd -Block $sqliteSql
Set-GeneratedBlock -Path $mysqlSchemaPath -BeginMarker $mysqlBegin -EndMarker $mysqlEnd -Block $mysqlSql

$duplicates = @($rows | Group-Object question | Where-Object Count -gt 1)
Write-Host "Question bank exported: $($rows.Count) Chinese rows; duplicate question texts=$($duplicates.Count)."
