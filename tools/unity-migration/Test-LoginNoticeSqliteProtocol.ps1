[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$databasePath = [IO.Path]::GetFullPath((Join-Path $root ".local/unity-validation/login-sqlite/LocalServer/projectx.db"))
$schemaPath = [IO.Path]::GetFullPath((Join-Path $root "unityserver/sql/sqlite/001_initial_schema.sql"))
$fixtureScript = Join-Path $PSScriptRoot "Invoke-LoginSqliteFixture.ps1"
$protocolScript = Join-Path $PSScriptRoot "Test-LoginNoticeSqliteProtocol.py"
$startServerScript = Join-Path $root "tools/local/Start-Server.ps1"
$fixtureRunId = [Guid]::NewGuid().ToString("N")
$fixtureEvidence = [IO.Path]::GetFullPath((Join-Path $root ".local/unity-validation/w8-login-notice-sqlite-protocol-fixture-$fixtureRunId.json"))
$protocolEvidence = [IO.Path]::GetFullPath((Join-Path $root ".local/unity-validation/w8-login-notice-sqlite-protocol-$fixtureRunId.json"))
$snapshotDirectory = [IO.Path]::GetFullPath((Join-Path $root ".local/unity-validation/login-notice-log-snapshot-$PID"))
$logPaths = @(
    (Join-Path $root ".local/kapai-current.out"),
    (Join-Path $root ".local/kapai-current.err")
)
$pythonCommand = Get-Command python -ErrorAction Stop | Select-Object -First 1
$pythonExecutable = [string]$pythonCommand.Source
$listenerBefore = Get-UnityMigrationTcpListenerPid -Port 8711
if ($null -ne $listenerBefore) {
    throw "Refusing Login Notice protocol smoke because port 8711 is already occupied by pid=$listenerBefore."
}
$beforeKapaiIds = @((Get-Process kapai -ErrorAction SilentlyContinue | ForEach-Object { [int]$_.Id }))

$logSnapshots = @{}
foreach ($logPath in $logPaths) {
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
        $snapshotPath = Join-Path $snapshotDirectory ([IO.Path]::GetFileName($logPath))
        [IO.Directory]::CreateDirectory($snapshotDirectory) | Out-Null
        Copy-Item -LiteralPath $logPath -Destination $snapshotPath
        $logSnapshots[$logPath] = $snapshotPath
    }
}

$fixtureSetup = $false
$primaryError = $null
$cleanupError = $null
$startedKapaiPid = $null
$serverStopped = $true
try {
    & $fixtureScript -Action Setup -DatabasePath $databasePath -EvidencePath $fixtureEvidence
    $fixtureSetup = $true
    & $fixtureScript -Action AssertSetup -DatabasePath $databasePath -EvidencePath $fixtureEvidence

    & $startServerScript -Configuration Debug -SqlitePath $databasePath `
        -SqliteSchemaPath $schemaPath -WaitSeconds 30
    $listenerPid = Get-UnityMigrationTcpListenerPid -Port 8711
    if ($null -eq $listenerPid -or [int]$listenerPid -in $beforeKapaiIds) {
        throw "SQLite LocalServer did not start as a new process on port 8711."
    }
    $startedKapaiPid = [int]$listenerPid
    $serverProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $startedKapaiPid" -ErrorAction Stop
    $serverCommandLine = [string]$serverProcess.CommandLine
    if ([string]$serverProcess.Name -ine "kapai.exe" -or
        $serverCommandLine.IndexOf("--sqlite", [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
        $serverCommandLine.IndexOf($databasePath, [StringComparison]::OrdinalIgnoreCase) -lt 0 -or
        $serverCommandLine.IndexOf($schemaPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Started LocalServer is not using the isolated Login SQLite fixture database/schema."
    }

    & $pythonExecutable -X utf8 $protocolScript --host 127.0.0.1 --port 8711 --evidence $protocolEvidence
    if ($LASTEXITCODE -ne 0) { throw "SQLite-backed PRO_GONGGAO/88 protocol smoke failed." }
}
catch {
    $primaryError = $_
}
finally {
    if ($null -ne $startedKapaiPid) {
        $serverProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $startedKapaiPid" -ErrorAction SilentlyContinue
        $cleanupCommandLine = if ($serverProcess) { [string]$serverProcess.CommandLine } else { "" }
        if (-not $serverProcess) {
            $serverStopped = $true
        }
        elseif ([string]$serverProcess.Name -ieq "kapai.exe" -and
            $cleanupCommandLine -match '(?i)(?:^|\s)--sqlite(?:\s|=)' -and
            $cleanupCommandLine -match '(?i)(?:^|\s)--sqlite-schema(?:\s|=)' -and
            $cleanupCommandLine.IndexOf($databasePath, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
            $cleanupCommandLine.IndexOf($schemaPath, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            Stop-Process -Id $startedKapaiPid -Force -ErrorAction SilentlyContinue
            $stopDeadline = (Get-Date).AddSeconds(10)
            while ((Get-UnityMigrationTcpListenerPid -Port 8711) -eq $startedKapaiPid -and (Get-Date) -lt $stopDeadline) {
                Start-Sleep -Milliseconds 100
            }
            while ((Get-Process -Id $startedKapaiPid -ErrorAction SilentlyContinue) -and (Get-Date) -lt $stopDeadline) {
                Start-Sleep -Milliseconds 100
            }
            $serverStopped = $null -eq (Get-Process -Id $startedKapaiPid -ErrorAction SilentlyContinue)
        }
        else {
            $serverStopped = $false
        }
    }
    elseif ($fixtureSetup) {
        foreach ($process in @(Get-Process kapai -ErrorAction SilentlyContinue | Where-Object { $_.Id -notin $beforeKapaiIds })) {
            $processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)" -ErrorAction SilentlyContinue
            $cleanupCommandLine = if ($processInfo) { [string]$processInfo.CommandLine } else { "" }
            if ($processInfo -and [string]$processInfo.Name -ieq "kapai.exe" -and
                $cleanupCommandLine -match '(?i)(?:^|\s)--sqlite(?:\s|=)' -and
                $cleanupCommandLine -match '(?i)(?:^|\s)--sqlite-schema(?:\s|=)' -and
                $cleanupCommandLine.IndexOf($databasePath, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
                $cleanupCommandLine.IndexOf($schemaPath, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if ($fixtureSetup -and $serverStopped) {
        try {
            & $fixtureScript -Action Restore -DatabasePath $databasePath -EvidencePath $fixtureEvidence
            & $fixtureScript -Action AssertRestored -DatabasePath $databasePath -EvidencePath $fixtureEvidence
            & $fixtureScript -Action Cleanup -DatabasePath $databasePath -EvidencePath $fixtureEvidence
            & $fixtureScript -Action AssertCleanup -DatabasePath $databasePath -EvidencePath $fixtureEvidence
        }
        catch {
            $cleanupError = $_
        }
    }
    elseif ($fixtureSetup) {
        $cleanupError = [InvalidOperationException]::new("SQLite fixture restore was skipped because the owned kapai.exe process did not stop.")
    }

    foreach ($logPath in $logPaths) {
        if ($logSnapshots.ContainsKey($logPath)) {
            Copy-Item -LiteralPath $logSnapshots[$logPath] -Destination $logPath -Force
        }
        elseif (Test-Path -LiteralPath $logPath -PathType Leaf) {
            Remove-Item -LiteralPath $logPath -Force
        }
    }
    if (Test-Path -LiteralPath $snapshotDirectory) {
        Remove-Item -LiteralPath $snapshotDirectory -Recurse -Force
    }
}

if ($null -ne $primaryError) { throw $primaryError }
if ($null -ne $cleanupError) { throw $cleanupError }
Write-Host "Login Notice /88 SQLite protocol response verified and fixture restored: $protocolEvidence"
