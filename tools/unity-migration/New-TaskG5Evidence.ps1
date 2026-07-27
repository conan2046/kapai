[CmdletBinding()]
param(
    [string]$Root = "",
    [string]$PythonExecutable = "python"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
}

$pairs = @(
    @{ id = "TASK-01-POPULATED"; cocos = "12-task-populated-claimable-native.png"; unity = "TASK-01-POPULATED.png" }
    @{ id = "TASK-02-RELOAD"; cocos = "12-task-populated-claimable-native.png"; unity = "TASK-02-RELOAD.png" }
    @{ id = "TASK-07-SCROLL-BOTTOM"; cocos = "23-task-scroll-bottom-claimed-native.png"; unity = "TASK-07-SCROLL-BOTTOM.png" }
    @{ id = "TASK-09-GO-GUILD"; cocos = "17-task-go-guild-native.png"; unity = "TASK-09-GO-GUILD.png" }
    @{ id = "TASK-10-DAILY-CLAIMED-REWARD"; cocos = "13-daily-claim-reward-popup-native.png"; unity = "TASK-10-DAILY-CLAIMED-REWARD.png" }
    @{ id = "TASK-10-DAILY-CLAIMED-ROW"; cocos = "23-task-scroll-bottom-claimed-native.png"; unity = "TASK-10-DAILY-CLAIMED-ROW.png" }
    @{ id = "TASK-11-BOX-CLAIMABLE"; cocos = "18-active-box-claimable-popup-native.png"; unity = "TASK-11-BOX-CLAIMABLE.png" }
    @{ id = "TASK-12-BOX-CONFIRMED"; cocos = "20-active-box-claimed-rewards-native.png"; unity = "TASK-12-BOX-CONFIRMED.png" }
    @{ id = "TASK-13-BOX-CLOSE"; cocos = "19-active-box-popup-closed-native.png"; unity = "TASK-13-BOX-CLOSE.png" }
    @{ id = "TASK-14-BOX-OPENED"; cocos = "21-active-box-claimed-native.png"; unity = "TASK-11-BOX-OPENED.png" }
    @{ id = "TASK-15-RECONNECT"; cocos = "24-restored-relogin-native.png"; unity = "TASK-01-RECONNECT.png" }
)

$base = Join-Path $Root ".local/ui-fidelity/Task"
$cocosDirectory = Join-Path $base "cocos/g1-20260727"
$unityDirectory = Join-Path $base "unity/g5-20260727"
$compareDirectory = Join-Path $base "compare/g5-live-20260727"
$comparisonScript = Join-Path $Root "tools/unity-migration/New-UiFidelityComparison.py"
$contactScript = Join-Path $Root "tools/unity-migration/New-UiFidelityContactSheet.py"
[System.IO.Directory]::CreateDirectory($compareDirectory) | Out-Null

$reports = foreach ($pair in $pairs) {
    $cocos = Join-Path $cocosDirectory $pair.cocos
    $unity = Join-Path $unityDirectory $pair.unity
    if (-not (Test-Path -LiteralPath $cocos -PathType Leaf)) { throw "Missing Cocos evidence: $cocos" }
    if (-not (Test-Path -LiteralPath $unity -PathType Leaf)) { throw "Missing Unity evidence: $unity" }
    & $PythonExecutable $comparisonScript --cocos $cocos --unity $unity --output $compareDirectory --name $pair.id | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Task comparison failed: $($pair.id)" }
    Get-Content -LiteralPath (Join-Path $compareDirectory "$($pair.id)-report.json") -Raw -Encoding UTF8 |
        ConvertFrom-Json
}

$summary = [ordered]@{
    schemaVersion = 1
    module = "Task"
    userId = 7200057
    roleId = 1000115
    stateCount = $reports.Count
    imageSize = @{ width = 1334; height = 750 }
    states = $reports
    generatedUtc = [DateTime]::UtcNow.ToString("O")
}
$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText(
    (Join-Path $compareDirectory "report.json"),
    (($summary | ConvertTo-Json -Depth 8) + "`n"),
    $utf8
)

& $PythonExecutable $contactScript --input $compareDirectory --output $compareDirectory --per-page 6 --columns 2 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Task contact sheet generation failed." }

Write-Host "Task G5 evidence generated: $($reports.Count)/$($pairs.Count) states"
Write-Host "Report: $(Join-Path $compareDirectory 'report.json')"
