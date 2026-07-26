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
    $PythonExecutable = if ($pythonCommand) {
        $pythonCommand.Source
    }
    else {
        "C:\Users\Admin\AppData\Local\Microsoft\WindowsApps\python.exe"
    }
}
if (-not (Test-Path -LiteralPath $PythonExecutable)) {
    throw "Python executable was not found: $PythonExecutable"
}

$pairs = @(
    @{ id = "HERO-01-CLOSE"; cocos = "HERO-01-CLOSE.png" }
    @{ id = "HERO-02-OCCUPIED-ROW"; cocos = "HERO-02-OCCUPIED-ROW.png" }
    @{ id = "HERO-03-EMPTY-ROW"; cocos = "HERO-03-EMPTY-ROW.png" }
    @{ id = "HERO-04-ALL-ROWS-UNLOCKED"; cocos = "HERO-04-ALL-ROWS-UNLOCKED.png" }
    @{ id = "HERO-05-ADD-HERO"; cocos = "HERO-05-ADD-HERO.png" }
    @{ id = "HERO-06-CULTIVATE"; cocos = "HERO-06-CULTIVATE.png" }
    @{ id = "HERO-07-ENHANCE-MASTER"; cocos = "HERO-07-ENHANCE-MASTER.png" }
    @{ id = "HERO-08-REPLACE"; cocos = "HERO-08-REPLACE.png" }
    @{ id = "HERO-09-EQUIP-SLOT-1"; cocos = "HERO-09-EQUIP-SLOT-1.png" }
    @{ id = "HERO-10-EQUIP-SLOT-2"; cocos = "HERO-10-EQUIP-SLOT-2.png" }
    @{ id = "HERO-11-EQUIP-SLOT-3"; cocos = "HERO-11-EQUIP-SLOT-3.png" }
    @{ id = "HERO-12-EQUIP-SLOT-4"; cocos = "HERO-12-EQUIP-SLOT-4.png" }
    @{ id = "HERO-13-FABAO-SLOT-1"; cocos = "HERO-13-FABAO-SLOT-1.png" }
    @{ id = "HERO-14-FABAO-SLOT-2"; cocos = "HERO-14-FABAO-SLOT-2.png" }
    @{ id = "HERO-15-DETAIL"; cocos = "HERO-15-DETAIL.png" }
    @{ id = "HERO-16-FORMATION"; cocos = "HERO-16-FORMATION.png" }
)

$base = Join-Path $Root ".local/ui-fidelity/Hero"
$cocosDirectory = Join-Path $base "cocos/g5-live-20260726"
$unityDirectory = Join-Path $base "unity"
$compareDirectory = Join-Path $base "compare/g5-live-20260726"
$comparisonScript = Join-Path $Root "tools/unity-migration/New-UiFidelityComparison.py"
[System.IO.Directory]::CreateDirectory($compareDirectory) | Out-Null

$reports = foreach ($pair in $pairs) {
    $cocos = Join-Path $cocosDirectory $pair.cocos
    $unity = Join-Path $unityDirectory ("g5-{0}.png" -f $pair.id)
    if (-not (Test-Path -LiteralPath $cocos)) { throw "Missing Cocos evidence: $cocos" }
    if (-not (Test-Path -LiteralPath $unity)) { throw "Missing Unity evidence: $unity" }
    & $PythonExecutable $comparisonScript --cocos $cocos --unity $unity --output $compareDirectory --name $pair.id | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Comparison failed: $($pair.id)" }
    Get-Content -LiteralPath (Join-Path $compareDirectory ("{0}-report.json" -f $pair.id)) -Raw -Encoding UTF8 |
        ConvertFrom-Json
}

$summary = [ordered]@{
    schemaVersion = 1
    module = "Hero"
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
    "# Hero G5 UI fidelity report"
    ""
    "- Controls: $($reports.Count)/16"
    "- Resolution: 1334x750"
    ""
    "| Control | MAE | RMSE | Changed ratio > 8 |"
    "|---|---:|---:|---:|"
)
$lines += $reports | ForEach-Object {
    "| $($_.name) | $($_.meanAbsoluteError) | $($_.rootMeanSquareError) | $($_.changedPixelRatioOver8) |"
}
[System.IO.File]::WriteAllText(
    (Join-Path $compareDirectory "report.md"),
    (($lines -join "`n") + "`n"),
    $utf8)

Write-Host "Hero G5 evidence generated: $($reports.Count)/16 controls"
Write-Host "Report: $(Join-Path $compareDirectory 'report.json')"
