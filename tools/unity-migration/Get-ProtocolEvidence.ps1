[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 65535)]
    [int]$Protocol,
    [string]$Module = "",
    [string]$OutputPath = "",
    [switch]$NoWrite,
    [switch]$PassThru,
    [ValidateRange(10, 200)]
    [int]$MaxLinesPerSection = 60
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
if (-not (Get-Command rg -ErrorAction SilentlyContinue)) {
    throw "rg is required for protocol evidence extraction."
}
if (-not $OutputPath) {
    $OutputPath = ".local/protocol-evidence/$Protocol.md"
}
$resolvedOutput = Resolve-UnityMigrationPath -Root $root -Path $OutputPath

function Invoke-EvidenceSearch {
    param(
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [switch]$Fixed
    )
    $arguments = @("--line-number", "--no-heading", "--color", "never")
    if ($Fixed) { $arguments += "--fixed-strings" }
    $arguments += $Pattern
    $arguments += $Paths
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& rg @arguments 2>$null)
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($code -gt 1) { throw "rg failed with exit code $code for pattern: $Pattern" }
    return @($output | Select-Object -First $MaxLinesPerSection)
}

function Add-EvidenceSection {
    param(
        [Parameter(Mandatory = $true)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory = $true)][string]$Title,
        [string[]]$Lines = @()
    )
    [void]$Builder.AppendLine("## $Title")
    [void]$Builder.AppendLine()
    if ($Lines.Count -eq 0) {
        [void]$Builder.AppendLine("未找到匹配；需要人工继续取证。")
    }
    else {
        [void]$Builder.AppendLine('```text')
        foreach ($line in $Lines) { [void]$Builder.AppendLine($line) }
        [void]$Builder.AppendLine('```')
    }
    [void]$Builder.AppendLine()
}

Push-Location $root
try {
    $protocolHeader = "server/src/protocol.h"
    $definitionLines = Invoke-EvidenceSearch -Pattern "\b$Protocol\b" -Paths @($protocolHeader)
    $symbols = New-Object System.Collections.Generic.List[string]
    foreach ($line in Get-Content -Encoding UTF8 -LiteralPath $protocolHeader) {
        if ($line -match "^\s*const\s+int\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*$Protocol\s*;") {
            $symbols.Add($Matches[1])
        }
    }
    if ($symbols.Count -eq 0) {
        foreach ($line in $definitionLines) {
            if ($line -match "([A-Za-z_][A-Za-z0-9_]*)\s*=\s*$Protocol\b") { $symbols.Add($Matches[1]) }
        }
    }
    $symbols = @($symbols | Sort-Object -Unique)

    $serverLines = New-Object System.Collections.Generic.List[string]
    $clientLines = New-Object System.Collections.Generic.List[string]
    $unityLines = New-Object System.Collections.Generic.List[string]
    foreach ($symbol in $symbols) {
        foreach ($line in Invoke-EvidenceSearch -Pattern $symbol -Paths @("server/src", "server/script") -Fixed) {
            if (-not $serverLines.Contains($line)) { $serverLines.Add($line) }
        }
        foreach ($line in Invoke-EvidenceSearch -Pattern $symbol -Paths @("client/ProjectX/src", "client/ProjectX/res") -Fixed) {
            if (-not $clientLines.Contains($line)) { $clientLines.Add($line) }
        }
        foreach ($line in Invoke-EvidenceSearch -Pattern $symbol -Paths @("unityclient/Assets/ProjectX") -Fixed) {
            if (-not $unityLines.Contains($line)) { $unityLines.Add($line) }
        }
    }
    $clientNumberLines = Invoke-EvidenceSearch -Pattern "\b$Protocol\b" -Paths @("client/ProjectX/src", "client/ProjectX/res")
    $clientAliases = New-Object System.Collections.Generic.List[string]
    foreach ($line in $clientNumberLines) {
        if (-not $clientLines.Contains($line)) { $clientLines.Add($line) }
        if ($line -match "([A-Za-z_][A-Za-z0-9_]*)\s*=\s*$Protocol\b") { $clientAliases.Add($Matches[1]) }
    }
    foreach ($alias in @($clientAliases | Sort-Object -Unique)) {
        foreach ($line in Invoke-EvidenceSearch -Pattern $alias -Paths @("client/ProjectX/src", "client/ProjectX/res") -Fixed) {
            if (-not $clientLines.Contains($line)) { $clientLines.Add($line) }
        }
    }
    if ($Module) {
        foreach ($line in Invoke-EvidenceSearch -Pattern $Module -Paths @("client/ProjectX/src/NetWork", "client/ProjectX/src/View") -Fixed) {
            if (-not $clientLines.Contains($line)) { $clientLines.Add($line) }
        }
    }
    if ($unityLines.Count -eq 0) {
        foreach ($line in Invoke-EvidenceSearch -Pattern "\b$Protocol\b" -Paths @("unityclient/Assets/ProjectX")) {
            $unityLines.Add($line)
        }
    }
    $smokeLines = Invoke-EvidenceSearch -Pattern "\b$Protocol\b" -Paths @("tools/local/Invoke-ProtocolSmoke.ps1")

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.AppendLine("# 协议 /$Protocol 取证草稿")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("> 生成时间：$([DateTime]::Now.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$builder.AppendLine("> 模块：$(if ($Module) { $Module } else { '未指定' })")
    [void]$builder.AppendLine("> 符号：$(if ($symbols.Count -gt 0) { $symbols -join ', ' } else { '未解析' })")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("本文件是搜索证据草稿，不等同于字段语义已确认；最终仍需核对处理函数和真实回包。")
    [void]$builder.AppendLine()

    Add-EvidenceSection -Builder $builder -Title "服务端协议定义" -Lines $definitionLines
    Add-EvidenceSection -Builder $builder -Title "服务端注册、处理与脚本调用" -Lines @($serverLines | Select-Object -First $MaxLinesPerSection)
    Add-EvidenceSection -Builder $builder -Title "旧客户端请求与解析" -Lines @($clientLines | Select-Object -First $MaxLinesPerSection)
    Add-EvidenceSection -Builder $builder -Title "Unity 当前覆盖" -Lines @($unityLines | Select-Object -First $MaxLinesPerSection)
    Add-EvidenceSection -Builder $builder -Title "协议 smoke 当前覆盖" -Lines $smokeLines

    [void]$builder.AppendLine("## 人工确认清单")
    [void]$builder.AppendLine()
    [void]$builder.AppendLine("- [ ] 请求字段顺序、宽度和有符号性。")
    [void]$builder.AppendLine("- [ ] 成功/失败响应及服务端主动增量。")
    [void]$builder.AppendLine("- [ ] 旧客户端入口和真实 Prefab。")
    [void]$builder.AppendLine("- [ ] 空态、正常态、错误态和断线行为。")
    [void]$builder.AppendLine("- [ ] 变更操作前后状态及隔离角色。")

    $content = $builder.ToString()
    if (-not $NoWrite) {
        Write-UnityMigrationUtf8 -Path $resolvedOutput -Content $content
        Write-Host "Protocol evidence written: $resolvedOutput"
    }
    if ($PassThru -or $NoWrite) { $content }
}
finally {
    Pop-Location
}
