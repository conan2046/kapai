[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$configPath = Join-Path $root "unityclient\Assets\ProjectX\Resources\Configs\fabao.json"
$sourceRoot = Join-Path $root "client\ProjectX\res\item"
$targetRoot = Join-Path $root "unityclient\Assets\ProjectX\Resources\FaBaoIcons"
[System.IO.Directory]::CreateDirectory($targetRoot) | Out-Null

$pictures = @(Get-Content -Raw -Encoding UTF8 -LiteralPath $configPath | ConvertFrom-Json |
    ForEach-Object { [string]$_.pic } | Where-Object { $_ } | Sort-Object -Unique)
foreach ($picture in $pictures) {
    $source = Join-Path $sourceRoot ($picture + ".png")
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Missing authoritative FaBao icon: $source"
    }
    Copy-Item -LiteralPath $source -Destination (Join-Path $targetRoot ($picture + ".png")) -Force
}
Write-Host "Imported $($pictures.Count) authoritative FaBao icons into $targetRoot"
