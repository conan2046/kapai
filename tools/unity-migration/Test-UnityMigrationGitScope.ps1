[CmdletBinding()]
param(
    [string[]]$AllowedPath = @(),
    [switch]$FailOnUnexpected,
    [switch]$SummaryOnly
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) { $git = "C:\Program Files\Git\cmd\git.exe" }
if (-not (Test-Path -LiteralPath $git -PathType Leaf)) { throw "git executable not found." }

$lines = @(& $git -C $root status --porcelain=v1 --untracked-files=all)
$semanticPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($diffPath in @(& $git -C $root diff --name-only 2>$null)) {
    [void]$semanticPaths.Add(([string]$diffPath -replace '\\', '/'))
}
foreach ($diffPath in @(& $git -C $root diff --cached --name-only 2>$null)) {
    [void]$semanticPaths.Add(([string]$diffPath -replace '\\', '/'))
}
$untrackedPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($untrackedPath in @(& $git -C $root ls-files --others --exclude-standard)) {
    [void]$untrackedPaths.Add(([string]$untrackedPath -replace '\\', '/'))
}
$records = New-Object System.Collections.Generic.List[object]
foreach ($line in $lines) {
    if ($line.Length -lt 4) { continue }
    $status = $line.Substring(0, 2)
    $path = $line.Substring(3).Trim('"') -replace '\\', '/'
    if ($path -match ' -> ') { $path = ($path -split ' -> ')[-1] }
    $semantic = $semanticPaths.Contains($path) -or $untrackedPaths.Contains($path) -or $status -match 'A'
    $allowed = $AllowedPath.Count -eq 0
    foreach ($pattern in $AllowedPath) {
        if ($path -like $pattern) { $allowed = $true; break }
    }
    $kind = if (-not $semantic) { "line-ending-or-stat-noise" }
        elseif ($path.EndsWith(".meta", [StringComparison]::OrdinalIgnoreCase)) { "unity-meta" }
        else { "semantic" }
    $records.Add([pscustomobject]@{ Status = $status; Kind = $kind; Allowed = $allowed; Path = $path })
}

if (-not $SummaryOnly) { $records | Sort-Object Kind, Path | Format-Table -AutoSize }
$unexpected = @($records | Where-Object { $_.Kind -eq "semantic" -and -not $_.Allowed })
$meta = @($records | Where-Object Kind -eq "unity-meta")
$noise = @($records | Where-Object Kind -eq "line-ending-or-stat-noise")
Write-Host "Git scope: total=$($records.Count), semantic=$(@($records | Where-Object Kind -eq 'semantic').Count), meta=$($meta.Count), noise=$($noise.Count), unexpected=$($unexpected.Count)"
if ($FailOnUnexpected -and $unexpected.Count -gt 0) { throw "Unexpected semantic changes were found outside AllowedPath." }
