param(
    [string]$Database = "",
    [int]$Port = 18711,
    [string]$Configuration = "Debug",
    [string]$ExePath = "",
    [switch]$ImportData
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

if (-not $Database) {
    $Database = "fxl_game_clonecheck_$(Get-Date -Format 'yyyyMMddHHmmss')"
}
if ($Database -notmatch '^[A-Za-z0-9_]+$') {
    throw "Database must contain only letters, digits, and underscores: $Database"
}
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
    throw "Port $Port is already in use. Pass a different -Port."
}

$initArgs = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $Root "tools\local\Init-LocalDb.ps1"),
    "-Database", $Database
)
if ($ImportData) { $initArgs += "-ImportData" }
& pwsh @initArgs
if ($LASTEXITCODE -ne 0) { throw "Fresh database initialization failed: $Database" }

$sourceConfig = Join-Path $Root "server\config"
$workRoot = Join-Path $Root ".local\fresh-local\$Database"
$workDir = Join-Path $workRoot "config"
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
# Runtime DLLs live beside kapai.exe. Copy only mutable server configuration
# into the isolated working directory; duplicating freshly written PE files can
# race antivirus scanners and make CreateProcess return a sharing violation.
foreach ($Entry in "config", "dat", "json", "xml") {
    Copy-Item -LiteralPath (Join-Path $sourceConfig $Entry) -Destination $workDir -Recurse -Force
}

$configPath = Join-Path $workDir "config"
$configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
$configText = [regex]::Replace(
    $configText,
    '(?ms)(^\[database\].*?^dbname=)[^\r\n]+',
    "`${1}$Database",
    1
)
$configText = [regex]::Replace(
    $configText,
    '(?ms)(^\[server\].*?^port=)[^\r\n]+',
    "`${1}$Port",
    1
)
$scriptDir = ((Join-Path $Root "server\script") -replace '\\', '/') + '/'
$configText = [regex]::Replace($configText, '(?m)^script_dir=.*$', "script_dir=$scriptDir")
[System.IO.File]::WriteAllText($configPath, $configText, [System.Text.UTF8Encoding]::new($false))

if ($ExePath -and -not [System.IO.Path]::IsPathRooted($ExePath)) {
    $ExePath = Join-Path $Root $ExePath
}
if (-not $ExePath) {
    $exeCandidates = @(
        (Join-Path $Root "build\server-win\$Configuration\kapai.exe"),
        (Join-Path $Root "build\server-win\kapai.exe")
    )
    $ExePath = $exeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $ExePath -or -not (Test-Path $ExePath)) {
    throw "kapai.exe not found. Run tools/local/Build-Server.ps1 first."
}

$process = $null

try {
    # The legacy Windows server can exit with STATUS_SHARING_VIOLATION when
    # stdout/stderr are redirected to files. Keep the process hidden and use
    # protocol responses plus the exit/listener state as deterministic proof.
    $process = Start-Process -FilePath $ExePath -WorkingDirectory $workDir -WindowStyle Hidden -PassThru

    $deadline = (Get-Date).AddSeconds(25)
    do {
        Start-Sleep -Milliseconds 250
        if ($process.HasExited) {
            throw "Fresh local server exited with code $($process.ExitCode)"
        }
        $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
            Where-Object { $_.OwningProcess -eq $process.Id } |
            Select-Object -First 1
        if ($listener) { break }
    } while ((Get-Date) -lt $deadline)

    if (-not $listener) {
        throw "Fresh local server did not listen on port $Port within 25 seconds"
    }

    $userId = 900000 + (Get-Random -Minimum 1000 -Maximum 9999)
    & pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root "tools\local\Invoke-ProtocolSmoke.ps1") `
        -Port $Port -UserId $userId -RoleId 0 -AutoCreateRole
    if ($LASTEXITCODE -ne 0) { throw "Fresh local protocol smoke failed" }

    Write-Host "Fresh local setup passed"
    Write-Host "Database: $Database"
    Write-Host "Port: $Port"
    Write-Host "Verification: process stayed alive, listened, and completed login/create-role smoke"
}
finally {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
}
