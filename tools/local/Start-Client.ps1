param(
    [switch]$RedirectLogs
)

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

if ($RedirectLogs) {
    $LogDir = Join-Path $Root ".local"
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    $StdOut = Join-Path $LogDir "client-current.out"
    $StdErr = Join-Path $LogDir "client-current.err"
    Remove-Item -LiteralPath $StdOut, $StdErr -Force -ErrorAction SilentlyContinue
    Start-Process -FilePath $Exe -WorkingDirectory $SimDir -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr
} else {
    Start-Process -FilePath $Exe -WorkingDirectory $SimDir
}
Write-Host "Started client: $Exe"
