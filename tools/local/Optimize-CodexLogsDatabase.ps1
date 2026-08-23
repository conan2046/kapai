[CmdletBinding()]
param(
    [string]$DatabasePath = (Join-Path $env:USERPROFILE ".codex\logs_2.sqlite"),
    [switch]$Apply,
    [ValidateRange(0, 600)]
    [int]$WaitForExitSeconds = 0
)

$ErrorActionPreference = "Stop"
$database = [System.IO.Path]::GetFullPath($DatabasePath)
if (-not (Test-Path -LiteralPath $database -PathType Leaf)) {
    throw "Codex logs database not found: $database"
}

function Get-ActiveCodexDatabaseProcesses {
    @(
        Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -in @("ChatGPT.exe", "codex.exe", "codex-code-mode-host.exe")
            }
    )
}

$active = @(Get-ActiveCodexDatabaseProcesses)
$sizeMb = [Math]::Round((Get-Item -LiteralPath $database).Length / 1MB, 2)
Write-Host "Codex logs database: $database"
Write-Host "Size: $sizeMb MB"
Write-Host "Active Codex processes: $($active.Count)"
if (-not $Apply) {
    Write-Host "Dry run only. Exit Codex completely, then run this script from a standalone PowerShell with -Apply."
    exit 0
}
if ($active.Count -gt 0 -and $WaitForExitSeconds -gt 0) {
    Write-Host "Waiting up to $WaitForExitSeconds seconds for Codex to exit..."
    $deadline = [DateTime]::UtcNow.AddSeconds($WaitForExitSeconds)
    do {
        Start-Sleep -Seconds 1
        $active = @(Get-ActiveCodexDatabaseProcesses)
    } while ($active.Count -gt 0 -and [DateTime]::UtcNow -lt $deadline)
}
if ($active.Count -gt 0) {
    $ids = @($active | ForEach-Object { "$($_.Name):$($_.ProcessId)" }) -join ", "
    throw "Refusing to modify the active Codex database. Exit all Codex processes first: $ids"
}

$timestamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
$backupDirectory = Join-Path (Split-Path -Parent $database) "backups\logs_2-$timestamp"
[System.IO.Directory]::CreateDirectory($backupDirectory) | Out-Null
foreach ($path in @($database, "$database-wal", "$database-shm")) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Copy-Item -LiteralPath $path -Destination (Join-Path $backupDirectory (Split-Path -Leaf $path))
    }
}
Write-Host "Backup created: $backupDirectory"

$python = (Get-Command python -ErrorAction Stop).Source
$script = @'
import sqlite3
import sys

path = sys.argv[1]
connection = sqlite3.connect(path, timeout=60)
try:
    before = connection.execute("PRAGMA integrity_check").fetchone()[0]
    if before != "ok":
        raise RuntimeError(f"integrity_check before VACUUM failed: {before}")
    connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    connection.execute("VACUUM")
    after = connection.execute("PRAGMA integrity_check").fetchone()[0]
    if after != "ok":
        raise RuntimeError(f"integrity_check after VACUUM failed: {after}")
finally:
    connection.close()
print("integrity_check=ok")
'@

$script | & $python - $database
if ($LASTEXITCODE -ne 0) {
    throw "Codex database maintenance failed. Restore the backup from $backupDirectory"
}
$newSizeMb = [Math]::Round((Get-Item -LiteralPath $database).Length / 1MB, 2)
Write-Host "Codex logs database optimized: $sizeMb MB -> $newSizeMb MB"
Write-Host "Keep the backup until Codex restarts and old tasks open normally."
