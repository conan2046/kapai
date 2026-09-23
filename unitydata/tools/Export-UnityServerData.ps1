param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$CleanOutput,
    [switch]$ApplyGeneratedJson,
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'

$source = Join-Path $Root 'unitydata\export\server'
$excel = Join-Path $Root 'unitydata\excel'
$vendor = Join-Path $Root 'unitydata\tools\vendor\xl转表.exe'
$baseline = Join-Path $Root 'unityserver\config\json'
$generated = Join-Path $source 'generated\json_server'
$authoritativeRoot = Join-Path $source 'authoritative\json'
$authoritativeNames = @(
    'daily.json',
    'drop_matching.json',
    'function.json',
    'item.json',
    'level_reward.json',
    'mission_dialog.json',
    'reward.json',
    'sevendays.json',
    'shop_config.json',
    'shop.json',
    'xiulian.json'
)
$reportPath = Join-Path $Root '.local\unityserver-export\latest.json'

foreach ($required in @($excel, $vendor, $baseline, $authoritativeRoot)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Unity server Excel export input is missing: $required"
    }
}

$stage = Join-Path $Root ('.local\unityserver-export\stage-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'excel') | Out-Null
Copy-Item -LiteralPath $vendor -Destination (Join-Path $stage 'xl转表.exe') -Force
Get-ChildItem -LiteralPath $excel -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($excel.Length).TrimStart('\', '/')
    $target = Join-Path (Join-Path $stage 'excel') $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}

$process = Start-Process -FilePath (Join-Path $stage 'xl转表.exe') -WorkingDirectory $stage -PassThru -WindowStyle Hidden
$deadline = [DateTime]::UtcNow.AddSeconds([Math]::Max(15, $TimeoutSeconds))
$stableCount = 0
$lastCount = -1
while ([DateTime]::UtcNow -lt $deadline) {
    $outputRoot = Join-Path $stage 'json_server'
    $count = if (Test-Path -LiteralPath $outputRoot) {
        @(Get-ChildItem -LiteralPath $outputRoot -Recurse -File | Where-Object { $_.Name -notlike '*.bak_*' }).Count
    } else { 0 }
    if ($count -gt 0 -and $count -eq $lastCount) { $stableCount++ } else { $stableCount = 0 }
    if ($stableCount -ge 3) { break }
    $lastCount = $count
    Start-Sleep -Seconds 1
}

$outputRoot = Join-Path $stage 'json_server'
$generatedFiles = @(Get-ChildItem -LiteralPath $outputRoot -Recurse -File | Where-Object { $_.Name -notlike '*.bak_*' })
if ($generatedFiles.Count -eq 0) {
    if (-not $process.HasExited) { $process.Kill() }
    throw "Unity server Excel converter produced no json_server output. Stage: $stage"
}

# The legacy converter keeps a console child alive after writing its output.
# Stop only processes whose command line points at this isolated stage.
Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -and $_.CommandLine.Contains($stage)
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

if ($CleanOutput -and (Test-Path -LiteralPath $generated)) {
    Get-ChildItem -LiteralPath $generated -Force | Remove-Item -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $generated | Out-Null
$rawGeneratedFiles = @($generatedFiles)
$excelDrift = @()
foreach ($file in $rawGeneratedFiles) {
    $relative = $file.FullName.Substring($outputRoot.Length).TrimStart('\', '/')
    $target = Join-Path $baseline $relative
    if (-not (Test-Path -LiteralPath $target)) {
        $excelDrift += [pscustomobject]@{ path = $relative; kind = 'missing-baseline' }
    } elseif ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne
              (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
        $excelDrift += [pscustomobject]@{ path = $relative; kind = 'content-drift' }
    }
}

foreach ($file in $generatedFiles) {
    $relative = $file.FullName.Substring($outputRoot.Length).TrimStart('\', '/')
    $target = Join-Path $generated $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
}

$authoritativeOverrides = @()
foreach ($name in $authoritativeNames) {
    $authoritative = Join-Path $authoritativeRoot $name
    if (-not (Test-Path -LiteralPath $authoritative)) {
        throw "Unity server authoritative snapshot is missing: $authoritative"
    }
    $target = Join-Path $generated $name
    Copy-Item -LiteralPath $authoritative -Destination $target -Force
    $authoritativeOverrides += [pscustomobject]@{
        path = $name
        source = ('unitydata/export/server/authoritative/json/{0}' -f $name)
        reason = 'server-baseline-authoritative'
    }
}

$unresolvedDrift = @()
foreach ($file in Get-ChildItem -LiteralPath $generated -Recurse -File) {
    $relative = $file.FullName.Substring($generated.Length).TrimStart('\', '/')
    $target = Join-Path $baseline $relative
    if (-not (Test-Path -LiteralPath $target)) {
        $unresolvedDrift += [pscustomobject]@{ path = $relative; kind = 'missing-baseline' }
    } elseif ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne
              (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
        $unresolvedDrift += [pscustomobject]@{ path = $relative; kind = 'content-drift' }
    }
}

$report = [ordered]@{
    schemaVersion = 1
    sourceExcel = 'unitydata/excel'
    converter = 'unitydata/tools/vendor/xl转表.exe'
    generatedOutput = 'unitydata/export/server/generated/json_server'
    baselineRuntime = 'unityserver/config/json'
    generatedFileCount = $generatedFiles.Count
    excelDriftCount = $excelDrift.Count
    authoritativeOverrideCount = $authoritativeOverrides.Count
    unresolvedDriftCount = $unresolvedDrift.Count
    excelDrift = @($excelDrift)
    authoritativeOverrides = @($authoritativeOverrides)
    unresolvedDrift = @($unresolvedDrift)
    applied = $false
    utc = [DateTime]::UtcNow.ToString('O')
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $reportPath) | Out-Null
[IO.File]::WriteAllText($reportPath, ($report | ConvertTo-Json -Depth 8) + "`n", [Text.UTF8Encoding]::new($false))

if ($ApplyGeneratedJson) {
    foreach ($file in Get-ChildItem -LiteralPath $generated -Recurse -File) {
        $relative = $file.FullName.Substring($generated.Length).TrimStart('\', '/')
        foreach ($destination in @($baseline)) {
            $target = Join-Path $destination $relative
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        }
    }
    $report.applied = $true
    [IO.File]::WriteAllText($reportPath, ($report | ConvertTo-Json -Depth 8) + "`n", [Text.UTF8Encoding]::new($false))
}

if ($unresolvedDrift.Count -gt 0) {
    throw "Unity server Excel output still differs from the current Unity baseline after authoritative overrides: $($unresolvedDrift.Count) files. Review $reportPath."
}

Write-Output ("Unity server Excel export generated: {0} files; excelDrift={1}; authoritativeOverrides={2}; unresolved={3}; applied={4}; report={5}" -f $generatedFiles.Count, $excelDrift.Count, $authoritativeOverrides.Count, $unresolvedDrift.Count, $ApplyGeneratedJson.IsPresent, $reportPath)
