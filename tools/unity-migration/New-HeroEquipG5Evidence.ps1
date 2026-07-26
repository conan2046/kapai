[CmdletBinding()]
param(
    [string]$Root = "",
    [string]$PythonExecutable = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
}
if ([string]::IsNullOrWhiteSpace($PythonExecutable)) {
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    $PythonExecutable = if ($pythonCommand) { $pythonCommand.Source } else {
        "C:\Users\Admin\AppData\Local\Microsoft\WindowsApps\python.exe"
    }
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) {
    throw "Python executable was not found: $PythonExecutable"
}

$names = @(
    "g1-wear-menu-cua",
    "g1-hero-detail-equipped",
    "g1-equipment-bag",
    "g1-fabao-bag",
    "g1-equipment-hide-worn",
    "g1-fabao-fragments",
    "g1-equipment-help",
    "g1-fabao-help",
    "g1-equipment-detail",
    "g1-fabao-detail",
    "g1-strength-before",
    "g1-strength-after",
    "g1-equipment-change-available",
    "g1-fabao-change-available",
    "g1-equipment-material-insufficient",
    "g1-illegal-uid",
    "g1-repeat-operation",
    "g1-equipment-after-takeoff",
    "g1-after-takeoff",
    "g1-after-rewear"
)

$base = Join-Path $Root ".local/ui-fidelity/HeroEquip"
$cocosDirectory = Join-Path $base "cocos"
$unityDirectory = Join-Path $base "unity/g5-live-20260726"
$compareDirectory = Join-Path $base "compare/g5-live-20260726"
$comparisonScript = Join-Path $Root "tools/unity-migration/New-UiFidelityComparison.py"
[System.IO.Directory]::CreateDirectory($compareDirectory) | Out-Null

$reports = foreach ($name in $names) {
    $cocos = Join-Path $cocosDirectory "$name.png"
    $unity = Join-Path $unityDirectory "$name.png"
    if (-not (Test-Path -LiteralPath $cocos)) { throw "Missing Cocos evidence: $cocos" }
    if (-not (Test-Path -LiteralPath $unity)) { throw "Missing Unity evidence: $unity" }
    & $PythonExecutable $comparisonScript --cocos $cocos --unity $unity `
        --output $compareDirectory --name $name | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Comparison failed: $name" }
    Get-Content -LiteralPath (Join-Path $compareDirectory "$name-report.json") -Raw -Encoding UTF8 |
        ConvertFrom-Json
}

$summary = [ordered]@{
    schemaVersion = 1
    module = "HeroEquip"
    controls = $reports
    controlCount = $reports.Count
    imageSize = @{ width = 1334; height = 750 }
    generatedUtc = [DateTime]::UtcNow.ToString("O")
}
$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText(
    (Join-Path $compareDirectory "report.json"),
    (($summary | ConvertTo-Json -Depth 8) + "`n"),
    $utf8)

$lines = @(
    "# HeroEquip G5 UI fidelity report",
    "",
    "- Controls: $($reports.Count)/20",
    "- Resolution: 1334x750",
    "",
    "| State | MAE | RMSE | Changed ratio > 8 |",
    "|---|---:|---:|---:|"
)
$lines += $reports | ForEach-Object {
    "| $($_.name) | $($_.meanAbsoluteError) | $($_.rootMeanSquareError) | $($_.changedPixelRatioOver8) |"
}
[System.IO.File]::WriteAllText(
    (Join-Path $compareDirectory "report.md"),
    (($lines -join "`n") + "`n"),
    $utf8)

Write-Host "HeroEquip G5 evidence generated: $($reports.Count)/20 states"
Write-Host "Report: $(Join-Path $compareDirectory 'report.json')"
