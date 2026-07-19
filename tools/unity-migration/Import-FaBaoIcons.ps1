[CmdletBinding()]
param(
    [switch]$AllowChangedSource,
    [switch]$VerifyOnly
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configPath = Join-Path $root "unityclient\Assets\ProjectX\Resources\Configs\fabao.json"
$sourceRoot = Join-Path $root "client\ProjectX\res\item"
$targetRoot = Join-Path $root "unityclient\Assets\ProjectX\Resources\FaBaoIcons"
[System.IO.Directory]::CreateDirectory($targetRoot) | Out-Null

$pictures = @(Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json |
    ForEach-Object { [string]$_.pic } | Where-Object { $_ } | Sort-Object -Unique)
$plan = New-Object System.Collections.Generic.List[object]
foreach ($picture in $pictures) {
    $source = Join-Path $sourceRoot ($picture + ".png")
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Missing authoritative FaBao icon: $source"
    }
    $target = Join-Path $targetRoot ($picture + ".png")
    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash
    $targetHash = if (Test-Path -LiteralPath $target -PathType Leaf) {
        (Get-FileHash -Algorithm SHA256 -LiteralPath $target).Hash
    } else { "" }
    if ($targetHash -and $targetHash -ne $sourceHash -and -not $AllowChangedSource) {
        throw "FaBaoIcons hash collision for '$picture': source=$sourceHash target=$targetHash. Review and rerun with -AllowChangedSource only for an intentional authoritative refresh."
    }
    $plan.Add([pscustomobject]@{ Picture = $picture; Source = $source; Target = $target; Hash = $sourceHash; Changed = ($targetHash -ne $sourceHash) })
}
if (-not $VerifyOnly) {
    foreach ($item in $plan) {
        if ($item.Changed) { Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force }
    }
}
Write-Host "$(if ($VerifyOnly) { 'Verified' } else { 'Imported' }) $($pictures.Count) namespaced FaBao icons; changed=$(@($plan | Where-Object Changed).Count), target=$targetRoot"
