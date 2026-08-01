param(
    [switch]$RedirectLogs,
    [int]$LocalUserId = 0,
    [switch]$DisableAutoEnter,
    [switch]$DisableAutoCreateRole,
    [string]$LocalRoleNamePreset = "",
    [string]$LocalGameIp = "",
    [int]$LocalGamePort = 0
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

$sourceAppDef = Join-Path $ClientDir "src\core\AppDef.lua"
$simulatorAppDef = Join-Path $SimDir "src\core\AppDef.lua"
# Runtime overrides must never leak into the next launch. The legacy copy batch
# uses xcopy /D, so a previously modified simulator file can be newer than the
# authoritative source and survive indefinitely unless this file is reset.
Copy-Item -LiteralPath $sourceAppDef -Destination $simulatorAppDef -Force
if ($PSBoundParameters.ContainsKey("LocalUserId")) {
    if ($LocalUserId -le 0) {
        throw "LocalUserId must be a positive integer"
    }
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

if ($PSBoundParameters.ContainsKey("LocalGameIp") -or $PSBoundParameters.ContainsKey("LocalGamePort")) {
    if (-not $LocalGameIp -or -not [System.Net.IPAddress]::TryParse($LocalGameIp, [ref]([System.Net.IPAddress]$null))) {
        throw "LocalGameIp must be a valid IP address when overriding the local endpoint"
    }
    if ($LocalGamePort -lt 1 -or $LocalGamePort -gt 65535) {
        throw "LocalGamePort must be between 1 and 65535 when overriding the local endpoint"
    }
    $appDefText = Get-Content -LiteralPath $simulatorAppDef -Raw -Encoding UTF8
    $ipPattern = '(?m)^AppDef\.LOCAL_TEST_GAME_IP\s*=\s*"[^"]*"\s*$'
    $portPattern = '(?m)^AppDef\.LOCAL_TEST_GAME_PORT\s*=\s*\d+\s*$'
    if ([regex]::Matches($appDefText, $ipPattern).Count -ne 1 -or
        [regex]::Matches($appDefText, $portPattern).Count -ne 1) {
        throw "Expected exactly one local game endpoint assignment in $simulatorAppDef"
    }
    $appDefText = [regex]::Replace($appDefText, $ipPattern, "AppDef.LOCAL_TEST_GAME_IP = `"$LocalGameIp`"")
    $appDefText = [regex]::Replace($appDefText, $portPattern, "AppDef.LOCAL_TEST_GAME_PORT = $LocalGamePort")
    Set-Content -LiteralPath $simulatorAppDef -Value $appDefText -Encoding utf8NoBOM -NoNewline
}

if ($DisableAutoEnter -or $DisableAutoCreateRole) {
    $appDefText = Get-Content -LiteralPath $simulatorAppDef -Raw -Encoding UTF8
    $autoOverrides = [ordered]@{}
    if ($DisableAutoEnter) { $autoOverrides["LOCAL_TEST_AUTO_ENTER"] = "false" }
    if ($DisableAutoCreateRole) { $autoOverrides["LOCAL_TEST_AUTO_CREATE_ROLE"] = "false" }
    foreach ($entry in $autoOverrides.GetEnumerator()) {
        $pattern = "(?m)^AppDef\.$($entry.Key)\s*=\s*(?:true|false)\s*$"
        if ([regex]::Matches($appDefText, $pattern).Count -ne 1) {
            throw "Expected exactly one AppDef.$($entry.Key) assignment in $simulatorAppDef"
        }
        $appDefText = [regex]::Replace($appDefText, $pattern, "AppDef.$($entry.Key) = $($entry.Value)")
    }
    Set-Content -LiteralPath $simulatorAppDef -Value $appDefText -Encoding utf8NoBOM -NoNewline
}

if ($PSBoundParameters.ContainsKey("LocalRoleNamePreset")) {
    if ($LocalRoleNamePreset -match '["\\\r\n]') {
        throw "LocalRoleNamePreset cannot contain quotes, backslashes, or line breaks"
    }
    $appDefText = Get-Content -LiteralPath $simulatorAppDef -Raw -Encoding UTF8
    $presetPattern = '(?m)^AppDef\.LOCAL_TEST_ROLE_NAME_PRESET\s*=.*(?:\r?\n)?'
    $appDefText = [regex]::Replace($appDefText, $presetPattern, "")
    $anchorPattern = '(?m)^(AppDef\.LOCAL_TEST_ROLE_NAME\s*=.*)$'
    if ([regex]::Matches($appDefText, $anchorPattern).Count -ne 1) {
        throw "Expected exactly one AppDef.LOCAL_TEST_ROLE_NAME assignment in $simulatorAppDef"
    }
    $replacement = "`$1`nAppDef.LOCAL_TEST_ROLE_NAME_PRESET = `"$LocalRoleNamePreset`""
    $appDefText = [regex]::Replace($appDefText, $anchorPattern, $replacement)
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
