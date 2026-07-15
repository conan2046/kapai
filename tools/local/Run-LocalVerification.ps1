param(
    [switch]$Build,
    [switch]$Start,
    [switch]$RestartServer,
    [switch]$InitDb,
    [switch]$ImportData,
    [switch]$SkipClient,
    [switch]$SkipSmoke,
    [int]$WaitSeconds = 3,
    [int]$LogTailLines = 500
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$LogPattern = 'error|failed|falied|assert|exception|Crash|cannot|Can not|No such|Unknown|call:|mysql|Query.*fail|失败|错误|attempt to|nil value|stack traceback|断开|连接失败|config error'
$ScanStart = Get-Date

function Invoke-Step($Name, $Script, $Arguments = @()) {
    Write-Host "== $Name =="
    & pwsh -ExecutionPolicy Bypass -File $Script @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

function Show-ProcessState {
    Get-Process kapai,ProjectX -ErrorAction SilentlyContinue |
        Select-Object Id,ProcessName,Responding,StartTime |
        Format-Table -AutoSize
    Get-NetTCPConnection -LocalPort 8711 -State Listen -ErrorAction SilentlyContinue |
        Select-Object LocalAddress,LocalPort,OwningProcess |
        Format-Table -AutoSize
}

function Test-GameServerListening {
    return $null -ne (Get-NetTCPConnection -LocalPort 8711 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Test-ClientRunning {
    return $null -ne (Get-Process ProjectX -ErrorAction SilentlyContinue | Select-Object -First 1)
}

Push-Location $Root
try {
    Invoke-Step "Check local environment" (Join-Path $Root "tools\local\Check-LocalEnv.ps1")

    if ($Start -or $InitDb) {
        Invoke-Step "Start local MySQL" (Join-Path $Root "tools\local\Start-LocalMySql.ps1")
    }

    if ($InitDb) {
        $dbArgs = @()
        if ($ImportData) { $dbArgs += "-ImportData" }
        Invoke-Step "Initialize local DB" (Join-Path $Root "tools\local\Init-LocalDb.ps1") $dbArgs
    }

    if ($Build -and $RestartServer) {
        Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 1
    }

    if ($Build) {
        $luaInclude = Join-Path $Root "tools\local\vcpkg\installed\x64-windows\include\luajit"
        $luaLib = Join-Path $Root "tools\local\vcpkg\installed\x64-windows\lib\lua51.lib"
        $buildArgs = @()
        if (Test-Path $luaInclude) { $buildArgs += @("-LuaIncludeDir", $luaInclude) }
        if (Test-Path $luaLib) { $buildArgs += @("-LuaLibrary", $luaLib) }
        Invoke-Step "Build server" (Join-Path $Root "tools\local\Build-Server.ps1") $buildArgs
    }

    if ($Start) {
        if ($RestartServer) {
            Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 1
        }

        if (Test-GameServerListening) {
            Write-Host "== Start server =="
            Write-Host "Server already listens on 8711; reusing current process. Use -RestartServer to force restart."
        }
        else {
            Invoke-Step "Start server" (Join-Path $Root "tools\local\Start-Server.ps1")
        }

        if (-not $SkipClient) {
            if (Test-ClientRunning) {
                Write-Host "== Start client =="
                Write-Host "ProjectX.exe is already running; reusing current process."
            }
            else {
                Invoke-Step "Start client" (Join-Path $Root "tools\local\Start-Client.ps1")
            }
        }
        Start-Sleep -Seconds $WaitSeconds
    }

    Show-ProcessState

    if (-not $SkipSmoke) {
        if (-not (Test-GameServerListening)) {
            throw "Protocol smoke cannot start because no game server is listening on port 8711"
        }
        $uid = 730000 + (Get-Random -Minimum 100 -Maximum 999)
        Write-Host "== Protocol smoke userId=$uid =="
        & pwsh -ExecutionPolicy Bypass -File (Join-Path $Root "tools\local\Invoke-ProtocolSmoke.ps1") `
            -UserId $uid -RoleId 0 -AutoCreateRole -Extended -Actions -Mutations -Positive
        if ($LASTEXITCODE -ne 0) {
            throw "Protocol smoke failed with exit code $LASTEXITCODE"
        }
    }

    Write-Host "== Log scan =="
    $logFiles = @()
    $localDir = Join-Path $Root ".local"
    if (Test-Path $localDir) {
        $logFiles += Get-ChildItem $localDir -File -Include *.out,*.err -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -ge $ScanStart.AddMinutes(-5) }
    }
    $clientLog = Join-Path $Root "client\ProjectX\simulator\win32\local_client.log"
    if (Test-Path $clientLog) {
        $logFiles += Get-Item $clientLog
    }

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($file in $logFiles | Sort-Object FullName -Unique) {
        $lines = Get-Content -Path $file.FullName -Tail $LogTailLines -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        $lineNoBase = [Math]::Max(0, (Get-Content -Path $file.FullName -ErrorAction SilentlyContinue).Count - $lines.Count)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $LogPattern) {
                $matches.Add([pscustomobject]@{
                    Path = $file.FullName
                    LineNumber = $lineNoBase + $i + 1
                    Line = $lines[$i]
                })
            }
        }
    }
    if ($matches.Count -gt 0) {
        $matches | Select-Object -Last 120 | ForEach-Object {
            Write-Host "$($_.Path):$($_.LineNumber): $($_.Line)"
        }
        throw "Log scan found error-like entries"
    }
    Write-Host "Verification passed: no SQL/Lua/assert/crash/config-error entries found."
}
finally {
    Pop-Location
}
