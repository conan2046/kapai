param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$CleanOutput
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $Root 'unitydata\export\client\source'
$destination = Join-Path $Root 'unityclient\Assets\ProjectX\Resources\ProjectXData'

if (-not (Test-Path -LiteralPath $source)) {
    throw "Unity client data source is missing: $source"
}

if ($CleanOutput -and (Test-Path -LiteralPath $destination)) {
    Get-ChildItem -LiteralPath $destination -Force | Remove-Item -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $destination | Out-Null

Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object {
    $_.Extension -notin @('.meta')
} | ForEach-Object {
    $relative = $_.FullName.Substring($source.Length).TrimStart('\', '/')
    $target = Join-Path $destination $relative
    $targetDirectory = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $targetDirectory | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}

$sourceFiles = @(Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object { $_.Extension -notin @('.meta') })
$targetFiles = @(Get-ChildItem -LiteralPath $destination -Recurse -File | Where-Object { $_.Extension -notin @('.meta') })

if ($sourceFiles.Count -ne $targetFiles.Count) {
    throw "Unity client data export count mismatch: source=$($sourceFiles.Count), target=$($targetFiles.Count)."
}

Write-Output ("Unity client data exported: {0} files -> {1}" -f $sourceFiles.Count, $destination)
