param(
    [string]$Configuration = "Debug",
    [string]$ExePath = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$WorkDir = Join-Path $Root "server\config"

if (-not $ExePath) {
    $candidates = @(
        (Join-Path $Root "build\server-win\$Configuration\kapai.exe"),
        (Join-Path $Root "build\server-win\kapai.exe"),
        (Join-Path $Root "server\kapai.exe")
    )
    $ExePath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $ExePath) {
    throw "kapai.exe not found. Build the server first with tools\local\Build-Server.ps1."
}

Start-Process -FilePath $ExePath -WorkingDirectory $WorkDir
Write-Host "Started server: $ExePath"
Write-Host "Working directory: $WorkDir"

