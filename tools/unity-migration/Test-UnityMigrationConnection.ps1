[CmdletBinding()]
param(
    [int]$McpPort = 8080,
    [switch]$RequireMcp,
    [switch]$WriteReport
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$unityProject = Join-Path $root "unityclient"
$launchLog = Join-Path $unityProject "Library\MCPForUnity\Logs\server-launch-8080.log"
$mcpPid = Get-UnityMigrationTcpListenerPid -Port $McpPort
$serverPid = Get-UnityMigrationTcpListenerPid -Port 8711
$mysqlPid = Get-UnityMigrationTcpListenerPid -Port 3306
$unityProcesses = @(Get-UnityMigrationWorkspaceProcesses -Root $root -Names @("Unity.exe"))
$launchTail = ""
$launchAgeSeconds = $null
if (Test-Path -LiteralPath $launchLog -PathType Leaf) {
    $launchItem = Get-Item -LiteralPath $launchLog
    $launchAgeSeconds = [int]([DateTime]::UtcNow - $launchItem.LastWriteTimeUtc).TotalSeconds
    $launchTail = (Get-Content -LiteralPath $launchLog -Encoding UTF8 -Tail 80 -ErrorAction SilentlyContinue) -join "`n"
}

$mcpState = if ($null -ne $mcpPid -and $unityProcesses.Count -eq 0) {
    "orphan-listener-no-unity"
}
elseif ($null -ne $mcpPid) {
    "listening"
}
elseif ($launchTail -match 'Installed \d+ packages' -and $launchTail -notmatch 'Uvicorn running on') {
    "dependency-installing"
}
elseif ($launchTail -match 'Uvicorn running on') {
    "listener-stopped-or-stale"
}
elseif ($unityProcesses.Count -gt 0) {
    "unity-running-mcp-not-ready"
}
else {
    "offline"
}

$codexDb = Join-Path $env:USERPROFILE ".codex\logs_2.sqlite"
$codexDbMb = if (Test-Path -LiteralPath $codexDb -PathType Leaf) {
    [Math]::Round((Get-Item -LiteralPath $codexDb).Length / 1MB, 2)
}
else { $null }
$warnings = New-Object System.Collections.Generic.List[string]
if ($mcpState -eq "orphan-listener-no-unity") {
    $warnings.Add("8080在监听但本项目Unity未运行；禁止调用Unity MCP，否则会等待桥接直至超时。")
}
elseif ($mcpState -eq "dependency-installing") {
    $warnings.Add("MCP首次依赖仍在安装；等待launch log出现Uvicorn running后再连接。")
}
elseif ($mcpState -eq "listener-stopped-or-stale") {
    $warnings.Add("启动日志曾成功，但8080当前无监听；重开Unity并检查launch log尾部。")
}
elseif ($mcpState -eq "unity-running-mcp-not-ready") {
    $warnings.Add("Unity已运行但MCP未就绪；先检查编译/域重载和MCP启动日志，不要连续重试连接。")
}
if ($null -ne $codexDbMb -and $codexDbMb -ge 150) {
    $warnings.Add("Codex logs_2.sqlite 已达到 $codexDbMb MB；按备份和完整性校验流程收口旧任务。")
}

$report = [ordered]@{
    mcp = [ordered]@{
        state = $mcpState
        port = $McpPort
        processId = $mcpPid
        launchLog = $launchLog
        launchLogAgeSeconds = $launchAgeSeconds
    }
    unity = [ordered]@{
        processCount = $unityProcesses.Count
        processIds = @($unityProcesses | ForEach-Object { [int]$_.ProcessId })
    }
    services = [ordered]@{
        mysql3306ProcessId = $mysqlPid
        kapai8711ProcessId = $serverPid
    }
    codex = [ordered]@{
        logsDatabaseMb = $codexDbMb
    }
    warnings = $warnings.ToArray()
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}

$json = ($report | ConvertTo-Json -Depth 6)
Write-Host $json
if ($WriteReport) {
    $path = Join-Path $root ".local\unity-validation\connection-latest.json"
    Write-UnityMigrationUtf8 -Path $path -Content ($json + "`n")
    Write-Host "Connection report: $path"
}
if ($RequireMcp -and $mcpState -ne "listening") {
    throw "Unity MCP is required but not listening: state=$mcpState"
}
