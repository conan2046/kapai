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
    $PythonExecutable = if ($pythonCommand) { $pythonCommand.Source } else { "python" }
}

$pairs = @(
    @{ id = "BAG-01-MAIN-ENTRY"; cocos = "05-bag-default-populated.png"; unity = "BAG-01-ENTRY.png" }
    @{ id = "BAG-02-CLOSE"; cocos = "28-bag-close-main.png"; unity = "BAG-02-CLOSE.png" }
    @{ id = "BAG-03-TAB"; cocos = "19-tab-selected-noop.png"; unity = "BAG-03-TAB.png" }
    @{ id = "BAG-04-LIST-ITEM"; cocos = "05-bag-default-populated.png"; unity = "BAG-04-LIST-ITEM.png" }
    @{ id = "BAG-05-LIST-SCROLL"; cocos = "05-bag-default-populated.png"; unity = "BAG-05-LIST-SCROLL.png" }
    @{ id = "BAG-06-DETAIL-ICON"; cocos = "21-detail-icon-noop.png"; unity = "BAG-06-DETAIL-ICON.png" }
    @{ id = "BAG-07-USE"; cocos = "06-input-default.png"; unity = "BAG-07-USE-BATCH.png" }
    @{ id = "BAG-08-INPUT-DIGITS"; cocos = "07-input-value-10.png"; unity = "BAG-08-INPUT-DIGITS.png" }
    @{ id = "BAG-09-INPUT-DELETE"; cocos = "08-input-delete-to-1.png"; unity = "BAG-09-INPUT-DELETE.png" }
    @{ id = "BAG-10-INPUT-CONFIRM"; cocos = "22-input-empty-confirm-closes.png"; unity = "BAG-10-INPUT-ZERO.png" }
    @{ id = "BAG-11-INPUT-CLOSE"; cocos = "09-gift-item-selected.png"; unity = "BAG-11-INPUT-CLOSE.png" }
    @{ id = "BAG-12-GIFT-OPTION"; cocos = "11-gift-selected-max3.png"; unity = "BAG-12-GIFT-OPTION.png" }
    @{ id = "BAG-13-GIFT-SCROLL"; cocos = "13-gift-list-scrolled.png"; unity = "BAG-13-GIFT-SCROLL.png" }
    @{ id = "BAG-14-GIFT-SUB-ONE"; cocos = "12-gift-quantity2.png"; unity = "BAG-14-GIFT-SUB-ONE.png" }
    @{ id = "BAG-15-GIFT-ADD-ONE"; cocos = "11-gift-selected-max3.png"; unity = "BAG-15-GIFT-ADD-ONE.png" }
    @{ id = "BAG-16-GIFT-SUB-TEN"; cocos = "10-gift-choose-default.png"; unity = "BAG-16-GIFT-SUB-TEN.png" }
    @{ id = "BAG-17-GIFT-ADD-TEN"; cocos = "11-gift-selected-max3.png"; unity = "BAG-17-GIFT-ADD-TEN.png" }
    @{ id = "BAG-18-GIFT-CONFIRM"; cocos = "23-gift-confirm-no-selection.png"; unity = "BAG-18-GIFT-NO-SELECTION.png" }
    @{ id = "BAG-19-GIFT-CLOSE"; cocos = "09-gift-item-selected.png"; unity = "BAG-19-GIFT-CLOSE.png" }
    @{ id = "BAG-20-GIFT-REWARD-DETAIL"; cocos = "14-source-text-only.png"; unity = "BAG-20-GIFT-REWARD-DETAIL.png" }
    @{ id = "BAG-21-SOURCE-CLOSE"; cocos = "11-gift-selected-max3.png"; unity = "BAG-21-SOURCE-CLOSE.png" }
    @{ id = "BAG-22-SOURCE-ICON"; cocos = "24-source-icon-equipment-info.png"; unity = "BAG-22-SOURCE-ICON.png" }
    @{ id = "BAG-23-SOURCE-SCROLL"; cocos = "27-source-list-no-overflow.png"; unity = "BAG-23-SOURCE-SCROLL.png" }
    @{ id = "BAG-24-SOURCE-ACTION"; cocos = "15-source-action-blood-shop.png"; unity = "BAG-24-SOURCE-ACTION.png" }
    @{ id = "BAG-25-EQUIP-INFO-CLOSE"; cocos = "26-equip-info-close-return.png"; unity = "BAG-25-EQUIP-INFO-CLOSE.png" }
    @{ id = "BAG-26-EQUIP-INFO-SCROLL"; cocos = "25-equip-info-scrolled.png"; unity = "BAG-26-EQUIP-INFO-SCROLL.png" }
)

$base = Join-Path $Root ".local/ui-fidelity/Bag"
$cocosDirectory = Join-Path $base "cocos/g1-20260727"
$unityDirectory = Join-Path $base "unity/g5-20260727"
$compareDirectory = Join-Path $base "compare/g5-live-20260727"
$comparisonScript = Join-Path $Root "tools/unity-migration/New-UiFidelityComparison.py"
$contactScript = Join-Path $Root "tools/unity-migration/New-UiFidelityContactSheet.py"
[System.IO.Directory]::CreateDirectory($compareDirectory) | Out-Null

$reports = foreach ($pair in $pairs) {
    $cocos = Join-Path $cocosDirectory $pair.cocos
    $unity = Join-Path $unityDirectory $pair.unity
    if (-not (Test-Path -LiteralPath $cocos)) { throw "Missing Cocos evidence: $cocos" }
    if (-not (Test-Path -LiteralPath $unity)) { throw "Missing Unity evidence: $unity" }
    & $PythonExecutable $comparisonScript --cocos $cocos --unity $unity --output $compareDirectory --name $pair.id | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Comparison failed: $($pair.id)" }
    Get-Content -LiteralPath (Join-Path $compareDirectory ("{0}-report.json" -f $pair.id)) -Raw -Encoding UTF8 |
        ConvertFrom-Json
}

$summary = [ordered]@{
    schemaVersion = 1
    module = "Bag"
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
    "# Bag G5 UI fidelity report"
    ""
    "- Controls: $($reports.Count)/26"
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

& $PythonExecutable $contactScript --input $compareDirectory --output $compareDirectory --per-page 8 --columns 2 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Contact sheet generation failed." }

Write-Host "Bag G5 evidence generated: $($reports.Count)/26 controls"
Write-Host "Report: $(Join-Path $compareDirectory 'report.json')"
