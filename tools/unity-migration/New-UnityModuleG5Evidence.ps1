[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [string]$PythonExecutable = "python"
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$contract = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($contract.Count -ne 1 -or $null -eq $contract[0].g5) {
    throw "Module '$Module' has no unique G5 evidence contract."
}
$fixed = $contract[0].fixedAccount
$g5 = $contract[0].g5
$cocosDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.cocosDirectory)
$unityDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.unityDirectory)
$compareDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.compareDirectory)
$comparisonScript = Join-Path $root "tools/unity-migration/New-UiFidelityComparison.py"
$contactScript = Join-Path $root "tools/unity-migration/New-UiFidelityContactSheet.py"
[IO.Directory]::CreateDirectory($compareDirectory) | Out-Null

$pairIds = @($g5.pairs | ForEach-Object { [string]$_.id })
if ($pairIds.Count -eq 0 -or @($pairIds | Sort-Object -Unique).Count -ne $pairIds.Count) {
    throw "Module '$Module' G5 pairs are empty or contain duplicate ids."
}
$reports = foreach ($pair in $g5.pairs) {
    $cocos = Join-Path $cocosDirectory ([string]$pair.cocos)
    $unity = Join-Path $unityDirectory ([string]$pair.unity)
    foreach ($path in @($cocos, $unity)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing G5 evidence: $path" }
    }
    & $PythonExecutable $comparisonScript --cocos $cocos --unity $unity `
        --output $compareDirectory --name ([string]$pair.id) | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "G5 comparison failed: $($pair.id)" }
    $report = Get-Content -LiteralPath (Join-Path $compareDirectory "$($pair.id)-report.json") `
        -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$report.size[0] -ne [int]$g5.width -or [int]$report.size[1] -ne [int]$g5.height) {
        throw "G5 comparison has wrong native size: $($pair.id)"
    }
    $report | Add-Member -NotePropertyName cocosSha256 `
        -NotePropertyValue (Get-FileHash -Algorithm SHA256 -LiteralPath $cocos).Hash
    $report | Add-Member -NotePropertyName unitySha256 `
        -NotePropertyValue (Get-FileHash -Algorithm SHA256 -LiteralPath $unity).Hash
    $report
}
$git = "C:/Program Files/Git/cmd/git.exe"
$sourceCommit = (& $git -C $root rev-parse HEAD).Trim()
$summary = [ordered]@{
    schemaVersion = 2
    module = [string]$contract[0].module
    userId = [uint32]$fixed.userId
    roleId = [uint32]$fixed.roleId
    sourceCommit = $sourceCommit
    stateCount = $reports.Count
    imageSize = @{ width = [int]$g5.width; height = [int]$g5.height }
    states = $reports
    generatedUtc = [DateTime]::UtcNow.ToString("O")
}
Write-UnityMigrationUtf8 -Path (Join-Path $compareDirectory "report.json") `
    -Content (($summary | ConvertTo-Json -Depth 10) + "`n")
& $PythonExecutable $contactScript --input $compareDirectory --output $compareDirectory `
    --per-page 6 --columns 2 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "G5 contact sheet generation failed." }
Write-Host "G5 evidence generated: module=$Module states=$($reports.Count) report=$(Join-Path $compareDirectory 'report.json')"
