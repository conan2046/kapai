param(
    [string]$MySqlRoot = "C:\Program Files\MySQL\MySQL Server 8.4",
    [string]$MySqlUser = "root",
    [string]$MySqlPassword = "123456",
    [int]$Port = 3306
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$DataDir = Join-Path $Root ".local\mysql-data"
$LogDir = Join-Path $Root ".local\logs"
$MyCnf = Join-Path $Root ".local\mysql-local.ini"
$ConfigRoot = [string]$Root
if ($ConfigRoot -match '[^\x00-\x7F]') {
    $workspaceAlias = "F:\kapai-workspace"
    $aliasItem = Get-Item -LiteralPath $workspaceAlias -Force -ErrorAction SilentlyContinue
    $aliasTarget = if ($aliasItem -and $aliasItem.Target) { [string]$aliasItem.Target } else { "" }
    if (-not $aliasItem -or -not $aliasItem.PSIsContainer -or
        [IO.Path]::GetFullPath($aliasTarget) -ne [IO.Path]::GetFullPath([string]$Root)) {
        throw "MySQL ASCII config path alias is missing or points elsewhere: $workspaceAlias"
    }
    $ConfigRoot = $workspaceAlias
}
$MyCnf = Join-Path $ConfigRoot ".local\mysql-local.ini"

function Find-KnownFile($Paths) {
    foreach ($p in $Paths) {
        if (Test-Path $p) { return $p }
    }
    return ""
}

$mysqld = Join-Path $MySqlRoot "bin\mysqld.exe"
$mysql = Join-Path $MySqlRoot "bin\mysql.exe"
if (-not (Test-Path $mysqld)) {
    $mysqld = Find-KnownFile @(
        "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe",
        "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe"
    )
}
if (-not (Test-Path $mysql)) {
    $mysql = Find-KnownFile @(
        "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe",
        "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
    )
}
if (-not $mysqld -or -not $mysql) {
    throw "MySQL server binaries not found. Run tools/local/Install-LocalDeps.ps1 -IncludeMySql first."
}

# A fallback discovery may select 8.0 even though the parameter default is 8.4.
# Always derive basedir from the binary that will actually be launched.
$MySqlRoot = Split-Path (Split-Path $mysqld -Parent) -Parent

New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$mysqlErrorLog = Join-Path $ConfigRoot ".local\logs\mysql.err"
$mysqlPidFile = Join-Path $ConfigRoot ".local\logs\mysql.pid"
$mysqlSocket = Join-Path $ConfigRoot ".local\mysql.sock"
$configDataDir = Join-Path $ConfigRoot ".local\mysql-data"
$myCnfText = @"
[mysqld]
basedir=$($MySqlRoot -replace "\\", "/")
datadir=$($configDataDir -replace "\\", "/")
port=$Port
bind-address=127.0.0.1
character-set-server=utf8
collation-server=utf8_general_ci
log-error=$($mysqlErrorLog -replace "\\", "/")
pid-file=$($mysqlPidFile -replace "\\", "/")
socket=$($mysqlSocket -replace "\\", "/")

[client]
default-character-set=utf8
port=$Port
host=127.0.0.1
"@
Set-Content -Path $MyCnf -Value $myCnfText -Encoding ASCII

$systemTable = Join-Path $DataDir "mysql"
if (-not (Test-Path $systemTable)) {
    Write-Host "Initializing local MySQL data dir: $DataDir"
    & $mysqld "--defaults-file=$MyCnf" "--initialize-insecure" "--console"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Test-MySql($Password) {
    $args = @("--defaults-file=$MyCnf", "-u$MySqlUser", "--protocol=TCP", "-P$Port", "-e", "SELECT 1;")
    if ($Password -ne $null) { $args = @("--defaults-file=$MyCnf", "-u$MySqlUser", "-p$Password", "--protocol=TCP", "-P$Port", "-e", "SELECT 1;") }
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $mysql @args 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

if (-not (Test-MySql $MySqlPassword)) {
    $existing = Get-Process -Name "mysqld" -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -eq $mysqld } |
        Select-Object -First 1
    if (-not $existing) {
        Write-Host "Starting local MySQL on 127.0.0.1:$Port"
        Start-Process -FilePath $mysqld -ArgumentList @("--defaults-file=$MyCnf") -WorkingDirectory (Split-Path $mysqld) -WindowStyle Hidden | Out-Null
    }

    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-MySql $MySqlPassword) { $ready = $true; break }
        if (Test-MySql $null) {
            $oldPreference = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            & $mysql "--defaults-file=$MyCnf" "-u$MySqlUser" "--protocol=TCP" "-P$Port" "-e" "ALTER USER '$MySqlUser'@'localhost' IDENTIFIED BY '$MySqlPassword'; ALTER USER '$MySqlUser'@'127.0.0.1' IDENTIFIED BY '$MySqlPassword'; FLUSH PRIVILEGES;" 2>$null
            $ErrorActionPreference = $oldPreference
            if ($LASTEXITCODE -eq 0 -and (Test-MySql $MySqlPassword)) { $ready = $true; break }
        }
    }
    if (-not $ready) {
        throw "Local MySQL did not become ready. Check $mysqlErrorLog"
    }
}

Write-Host "Local MySQL ready: 127.0.0.1:$Port"
