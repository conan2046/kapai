[CmdletBinding()]
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $Root 'server\config\source\answer-settings.csv'
$seedPath = Join-Path $Root 'server\sql\sqlite\seeds\answer_settings.sql'
$schemaPath = Join-Path $Root 'server\sql\sqlite\001_initial_schema.sql'
$beginMarker = '-- BEGIN GENERATED UNITY ANSWER SETTINGS SEED'
$endMarker = '-- END GENERATED UNITY ANSWER SETTINGS SEED'

$rows = @(Import-Csv -LiteralPath $sourcePath -Encoding UTF8)
if ($rows.Count -ne 1) { throw 'answer-settings.csv must contain exactly one data row.' }
$row = $rows[0]
if ([int]$row.id -ne 1) { throw 'Unity answer settings row id must be 1.' }
if ([int]$row.daily_attempt_limit -lt 1 -or [int]$row.daily_attempt_limit -gt 255) {
    throw 'daily_attempt_limit must be in the range 1..255.'
}
if ([int]$row.fallback_reward_type -ne 60000) {
    throw 'Missing Unity answer rewards must currently fall back to gold type 60000.'
}
if ([int]$row.fallback_reward_amount -lt 1) {
    throw 'fallback_reward_amount must be positive.'
}

$sql = @"
$beginMarker
INSERT INTO answer_settings (id,daily_attempt_limit,fallback_reward_type,fallback_reward_amount) VALUES
($([int]$row.id),$([int]$row.daily_attempt_limit),$([int]$row.fallback_reward_type),$([int]$row.fallback_reward_amount))
ON CONFLICT(id) DO UPDATE SET
  daily_attempt_limit=excluded.daily_attempt_limit,
  fallback_reward_type=excluded.fallback_reward_type,
  fallback_reward_amount=excluded.fallback_reward_amount;
$endMarker
"@

if ($ValidateOnly) {
    $currentSeed = (Get-Content -Raw -Encoding UTF8 -LiteralPath $seedPath).Trim()
    if ($currentSeed -ne $sql.Trim()) { throw 'SQLite Unity answer settings seed is stale. Run exporter.' }
    $schema = Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaPath
    if (-not $schema.Contains($sql.Trim())) { throw 'SQLite initial schema does not contain the Unity answer settings seed.' }
    if ($schema -notmatch 'CREATE TABLE IF NOT EXISTS `answer_settings`') {
        throw 'SQLite initial schema does not define answer_settings.'
    }
    Write-Host "Unity answer settings valid: daily=$($row.daily_attempt_limit), fallback=$($row.fallback_reward_type)x$($row.fallback_reward_amount)."
    return
}

Set-Content -LiteralPath $seedPath -Encoding UTF8 -NoNewline -Value $sql.Trim()
$schema = Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaPath
$pattern = '(?s)' + [regex]::Escape($beginMarker) + '.*?' + [regex]::Escape($endMarker)
if ([regex]::IsMatch($schema, $pattern)) {
    $schema = [regex]::Replace($schema, $pattern, $sql.Trim())
} else {
    $schema = $schema.TrimEnd() + "`r`n`r`n" + $sql.Trim() + "`r`n"
}
Set-Content -LiteralPath $schemaPath -Encoding UTF8 -NoNewline -Value $schema
Write-Host "Unity answer settings exported: daily=$($row.daily_attempt_limit), fallback=$($row.fallback_reward_type)x$($row.fallback_reward_amount)."
