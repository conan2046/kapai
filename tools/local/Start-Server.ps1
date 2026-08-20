param(
    [string]$Configuration = "Debug",
    [string]$ExePath = "",
    [string]$ConfigDirectory = "",
    [string]$SqlitePath = "",
    [string]$SqliteSchemaPath = "",
    [int]$WaitSeconds = 20
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$WorkDir = if ($ConfigDirectory) {
    if ([IO.Path]::IsPathRooted($ConfigDirectory)) { [IO.Path]::GetFullPath($ConfigDirectory) }
    else { [IO.Path]::GetFullPath((Join-Path $Root $ConfigDirectory)) }
} else {
    Join-Path $Root "server\config"
}
if (-not (Test-Path -LiteralPath (Join-Path $WorkDir "config") -PathType Leaf)) {
    throw "Server config directory is invalid: $WorkDir"
}

function Test-ListenPort([int]$Port) {
    try {
        if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1) {
            return $true
        }
    }
    catch {
        # Restricted Windows sessions may deny Get-NetTCPConnection.
    }
    $netstat = Join-Path $env:SystemRoot "System32\netstat.exe"
    return $null -ne (@(& $netstat -ano -p tcp 2>$null) |
        Where-Object { $_ -match "^\s*TCP\s+\S+:$Port\s+\S+\s+LISTENING\s+\d+\s*$" } |
        Select-Object -First 1)
}

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

$LocalDir = Join-Path $Root ".local"
New-Item -ItemType Directory -Path $LocalDir -Force | Out-Null
$StdOutLog = Join-Path $LocalDir "kapai-current.out"
$StdErrLog = Join-Path $LocalDir "kapai-current.err"
Remove-Item -LiteralPath $StdOutLog,$StdErrLog -Force -ErrorAction SilentlyContinue

$argumentList = @()
if($SqlitePath -or $SqliteSchemaPath) {
    if(-not $SqlitePath -or -not $SqliteSchemaPath) {
        throw "SQLite startup requires both -SqlitePath and -SqliteSchemaPath."
    }
    $argumentList += @("--sqlite", ([IO.Path]::GetFullPath($SqlitePath)), "--sqlite-schema", ([IO.Path]::GetFullPath($SqliteSchemaPath)))
}
$process = Start-Process -FilePath $ExePath -ArgumentList $argumentList -WorkingDirectory $WorkDir -WindowStyle Hidden `
    -RedirectStandardOutput $StdOutLog -RedirectStandardError $StdErrLog -PassThru
Write-Host "Started server: $ExePath"
Write-Host "Working directory: $WorkDir"
Write-Host "Logs: $StdOutLog, $StdErrLog"

$deadline = (Get-Date).AddSeconds($WaitSeconds)
do {
    Start-Sleep -Milliseconds 250
    if ($process.HasExited) {
        Get-Content -LiteralPath $StdOutLog,$StdErrLog -Tail 80 -ErrorAction SilentlyContinue
        throw "kapai.exe exited during startup with code $($process.ExitCode)"
    }
    if (Test-ListenPort -Port 8711) {
        Write-Host "Server listening on 8711 (pid=$($process.Id))"
        return
    }
} while ((Get-Date) -lt $deadline)

Get-Content -LiteralPath $StdOutLog,$StdErrLog -Tail 80 -ErrorAction SilentlyContinue
throw "kapai.exe did not listen on port 8711 within $WaitSeconds seconds"
