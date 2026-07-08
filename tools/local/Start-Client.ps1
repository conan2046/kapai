$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ClientDir = Join-Path $Root "client\ProjectX"
$SimDir = Join-Path $ClientDir "simulator\win32"
$Exe = Join-Path $SimDir "ProjectX.exe"

if (-not (Test-Path $Exe)) {
    throw "ProjectX.exe not found: $Exe"
}

Push-Location $ClientDir
try {
    & ".\copy_lua_to_simulator.bat"
} finally {
    Pop-Location
}

Start-Process -FilePath $Exe -WorkingDirectory $SimDir
Write-Host "Started client: $Exe"
