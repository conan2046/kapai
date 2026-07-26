param(
    [switch]$RedirectLogs,
    [int]$LocalUserId = 0
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ClientDir = Join-Path $Root "client\ProjectX"
$SimDir = Join-Path $ClientDir "simulator\win32"
$Exe = Join-Path $SimDir "ProjectX.exe"
$SourceConfig = Join-Path $ClientDir "config.json"
$SimulatorConfig = Join-Path $SimDir "config.json"

if (-not (Test-Path $Exe)) {
    throw "ProjectX.exe not found: $Exe"
}

if (-not (Test-Path $SourceConfig)) {
    throw "Client config not found: $SourceConfig"
}
if (-not (Test-Path $SimulatorConfig)) {
    throw "Simulator config not found: $SimulatorConfig"
}

# The simulator runs from simulator/win32 and reads that directory's config.
# Keep its product-specific title, but synchronize the authoritative client size.
$sourceConfigJson = Get-Content -LiteralPath $SourceConfig -Raw -Encoding UTF8 | ConvertFrom-Json
$simulatorConfigJson = Get-Content -LiteralPath $SimulatorConfig -Raw -Encoding UTF8 | ConvertFrom-Json
$simulatorConfigJson.init_cfg.isLandscape = $sourceConfigJson.init_cfg.isLandscape
$simulatorConfigJson.init_cfg.width = $sourceConfigJson.init_cfg.width
$simulatorConfigJson.init_cfg.height = $sourceConfigJson.init_cfg.height
$simulatorConfigJson | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $SimulatorConfig -Encoding utf8NoBOM

Push-Location $ClientDir
try {
    & ".\copy_lua_to_simulator.bat"
} finally {
    Pop-Location
}

if ($PSBoundParameters.ContainsKey("LocalUserId")) {
    if ($LocalUserId -le 0) {
        throw "LocalUserId must be a positive integer"
    }
    $simulatorAppDef = Join-Path $SimDir "src\core\AppDef.lua"
    $appDefText = Get-Content -LiteralPath $simulatorAppDef -Raw -Encoding UTF8
    $uidPattern = '(?m)^AppDef\.LOCAL_TEST_UID\s*=\s*\d+\s*$'
    if ([regex]::Matches($appDefText, $uidPattern).Count -ne 1) {
        throw "Expected exactly one AppDef.LOCAL_TEST_UID assignment in $simulatorAppDef"
    }
    $appDefText = [regex]::Replace(
        $appDefText,
        $uidPattern,
        "AppDef.LOCAL_TEST_UID = $LocalUserId"
    )
    Set-Content -LiteralPath $simulatorAppDef -Value $appDefText -Encoding utf8NoBOM -NoNewline
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
