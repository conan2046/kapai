param(
    [string]$OutFile = "",
    [string]$SteamJsonOut = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if (-not $OutFile) {
    $OutFile = Join-Path $Root "PROTOCOL_COVERAGE.md"
}
if (-not $SteamJsonOut) {
    $SteamJsonOut = Join-Path $Root ".local\unity-validation\steam-sqlite-s5-protocol-coverage-latest.json"
}

$protocolPath = Join-Path $Root "server\src\protocol.h"
$packDealPath = Join-Path $Root "server\src\pack_deal.cpp"
$smokePath = Join-Path $Root "tools\local\Invoke-ProtocolSmoke.ps1"
$moduleManifestPath = Join-Path $Root "tools\unity-migration\unityclient-modules.json"

function Read-Text($Path) {
    return Get-Content -Raw -Encoding UTF8 $Path
}

function Get-ProtocolLayer($Name) {
    $overrides = @{
        "PRO_SYSTEM_INFO" = "服务端内部/跨服"
        "PRO_SPEC_CHAT" = "服务端内部/跨服"
        "MSG_BANGPAI_ZHONGZHI" = "人工 UI"
        "MSG_WORLD_MAP_TRANSPORT" = "可控改档"
        "MSG_USER_MSG_TO_WORLD" = "低风险动作"
    }
    if ($overrides.ContainsKey($Name)) {
        return $overrides[$Name]
    }
    if ($Name -match "SERVER_|KF_|KUA_FU|MGR|FORWARD|QUERY_SQL") {
        return "服务端内部/跨服"
    }
    if ($Name -match "FIGHT|BATTLE|GUANZHAN|VIDIO|ARENA|LEITAI|BLOOD|DAILY_BOSS|BOSS|ESCAPE") {
        return "战斗结算"
    }
    if ($Name -match "BUY|CHARGE|CHONGZHI|AWARD|DRAW|SHOP|GIFT|FLOWER|JIAOYI|USE_ITEM|OPEN_PACKAGE|WEIXIN|JIJIN|MONEY|PAY|REWARD|DONATE|REFRESH") {
        return "真实消耗"
    }
    if ($Name -match "SAVE_VAL|STRING|SWITCH|IGNORE|CHANGE|SET|UPDATE|DEL|CREATE|SELECT_ROLE|CREATE_ROLE|HIDE|UNUSE|CLOSE|OPEN") {
        return "可控改档"
    }
    if ($Name -match "OPTION|OPERATE|MOVE|JUMP|TEAM|CHAT|APPLY|REVIVE|SEARCH|LOOK|CHECK|REGISTER|CAIQUAN") {
        return "低风险动作"
    }
    if ($Name -match "QUERY|GET|LIST|INFO|RANK|HELP|TITLE|PACKAGE|PET|TASK|WORLD|VIP|NOTICE|TIME|POINT|COPY|MAP|SCENE|FRIEND|BANGPAI|FORMATION|MISSION|BOOK|ALL_|SELF|NEAR|ONLINE|HEART") {
        return "查询"
    }
    return "人工 UI"
}

$protocolText = Read-Text $protocolPath
$packDealText = Read-Text $packDealPath
$smokeText = Read-Text $smokePath

$protocolByName = @{}
$nameByValue = @{}
[regex]::Matches($protocolText, "const\s+int\s+([A-Za-z0-9_]+)\s*=\s*(0x[0-9A-Fa-f]+|\d+)\s*;") | ForEach-Object {
    $name = $_.Groups[1].Value
    $raw = $_.Groups[2].Value
    $value = if ($raw.StartsWith("0x")) { [Convert]::ToInt32($raw, 16) } else { [int]$raw }
    $protocolByName[$name] = $value
    if (-not $nameByValue.ContainsKey($value)) { $nameByValue[$value] = $name }
}

$registered = @()
[regex]::Matches($packDealText, "cmdFun\.push_back\(SCommand\{([A-Za-z0-9_]+),") | ForEach-Object {
    $name = $_.Groups[1].Value
    $value = if ($protocolByName.ContainsKey($name)) { $protocolByName[$name] } else { $null }
    $registered += [pscustomobject]@{
        Name = $name
        Value = $value
    }
}
$localBuildExcluded = @(
    "MSG_KUN_LUN_SHAN_TEAM",
    "MSG_KF_LOGIN",
    "MSG_KUA_FU_1V1",
    "MSG_SERVER_KF_BANGZHAN_INFO",
    "MSG_QUNXIANZHENGBA"
)
$registered = $registered | Where-Object { $localBuildExcluded -notcontains $_.Name }
$registered = $registered | Sort-Object Value,Name -Unique

$coveredByValue = @{}
$coveredByName = @{}
$caseValueByName = @{}
[regex]::Matches($smokeText, "\('([^']+)'\s*,\s*(\d+)\s*,") | ForEach-Object {
    $caseName = $_.Groups[1].Value
    $value = [int]$_.Groups[2].Value
    $caseValueByName[$caseName] = $value
    if (-not $coveredByValue.ContainsKey($value)) { $coveredByValue[$value] = New-Object System.Collections.Generic.List[string] }
    $coveredByValue[$value].Add($caseName)
}
[regex]::Matches($smokeText, "pkt\((\d+),") | ForEach-Object {
    $value = [int]$_.Groups[1].Value
    if (-not $coveredByValue.ContainsKey($value)) { $coveredByValue[$value] = New-Object System.Collections.Generic.List[string] }
    if (-not $coveredByValue[$value].Contains("login/select/create")) {
        $coveredByValue[$value].Add("login/select/create")
    }
}

$moduleManifest = Get-Content -LiteralPath $moduleManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$steamModules = @($moduleManifest.modules | Where-Object { -not $_.migrationExcluded })
$steamProtocols = @(
    $steamModules |
        ForEach-Object {
            $steamProperty = $_.PSObject.Properties['steamProtocols']
            if ($steamProperty) { @($steamProperty.Value) } else { @($_.protocols) }
        } |
        ForEach-Object { [int]$_ } |
        Sort-Object -Unique
)
$steamAllowlistMatch = [regex]::Match(
    $smokeText,
    "steam_included_names\s*=\s*\{(?<body>.*?)\}\s*smokes\s*=",
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
if (-not $steamAllowlistMatch.Success) {
    throw "Steam smoke allowlist was not found in Invoke-ProtocolSmoke.ps1"
}
$steamCaseNames = @(
    [regex]::Matches($steamAllowlistMatch.Groups['body'].Value, "'([^']+)'") |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
)
$steamCasesByValue = @{}
foreach ($caseName in $steamCaseNames) {
    if (-not $caseValueByName.ContainsKey($caseName)) { continue }
    $value = [int]$caseValueByName[$caseName]
    if (-not $steamCasesByValue.ContainsKey($value)) {
        $steamCasesByValue[$value] = New-Object System.Collections.Generic.List[string]
    }
    $steamCasesByValue[$value].Add($caseName)
}
$implicitSteamCases = @{
    226 = @('playerhud_levelup-push')
    1001 = @('login')
    1003 = @('create-role')
    1004 = @('select-role')
}
$steamCoverageRows = @(
    foreach ($value in $steamProtocols) {
        $moduleKeys = @(
            $steamModules |
                Where-Object {
                    $steamProperty = $_.PSObject.Properties['steamProtocols']
                    $effectiveProtocols = if ($steamProperty) { @($steamProperty.Value) } else { @($_.protocols) }
                    $effectiveProtocols -contains $value
                } |
                ForEach-Object { $_.key }
        )
        $cases = @()
        if ($steamCasesByValue.ContainsKey($value)) { $cases += @($steamCasesByValue[$value]) }
        if ($implicitSteamCases.ContainsKey($value)) { $cases += @($implicitSteamCases[$value]) }
        [pscustomobject]@{
            protocol = $value
            name = if ($nameByValue.ContainsKey($value)) { $nameByValue[$value] } else { '' }
            modules = $moduleKeys
            requestCases = @($cases | Sort-Object -Unique)
            coverage = if ($cases.Count -gt 0) { 'request-covered' } else { 'missing-or-passive' }
        }
    }
)
$steamRequestCovered = @($steamCoverageRows | Where-Object coverage -eq 'request-covered').Count
$steamMissingOrPassive = @($steamCoverageRows | Where-Object coverage -eq 'missing-or-passive').Count
$steamReport = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    source = [ordered]@{
        manifest = 'tools/unity-migration/unityclient-modules.json'
        smoke = 'tools/local/Invoke-ProtocolSmoke.ps1'
    }
    includedModules = @($steamModules | ForEach-Object { $_.key })
    excludedModules = @($moduleManifest.modules | Where-Object migrationExcluded | ForEach-Object { $_.key })
    protocolCount = $steamProtocols.Count
    requestCovered = $steamRequestCovered
    missingOrPassive = $steamMissingOrPassive
    protocols = $steamCoverageRows
}
$steamJsonDirectory = Split-Path -Parent $SteamJsonOut
if ($steamJsonDirectory) { New-Item -ItemType Directory -Path $steamJsonDirectory -Force | Out-Null }
$steamReport | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SteamJsonOut -Encoding UTF8

foreach ($entry in $registered) {
    if ($null -ne $entry.Value -and $coveredByValue.ContainsKey($entry.Value)) {
        $coveredByName[$entry.Name] = $coveredByValue[$entry.Value]
    }
}

$total = @($registered | Where-Object { $null -ne $_.Value }).Count
$covered = @($registered | Where-Object { $null -ne $_.Value -and $coveredByValue.ContainsKey($_.Value) }).Count
$uncovered = $total - $covered
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$uncoveredEntries = @(
    $registered |
        Where-Object { $null -ne $_.Value -and -not $coveredByValue.ContainsKey($_.Value) } |
        ForEach-Object {
            [pscustomobject]@{
                Value = $_.Value
                Name = $_.Name
                Layer = Get-ProtocolLayer $_.Name
            }
        } |
        Sort-Object Layer,Value,Name
)

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# 协议覆盖矩阵")
$lines.Add("")
$lines.Add("> 自动生成时间：$generatedAt")
$lines.Add("> 生成命令：``pwsh -ExecutionPolicy Bypass -File tools/local/Export-ProtocolCoverage.ps1``")
$lines.Add("")
$lines.Add("当前文件用于跟踪本地测试服协议覆盖，不等同于完整人工 UI 验收。")
$lines.Add("")
$lines.Add("## 覆盖统计")
$lines.Add("")
$lines.Add("| 项 | 数量 |")
$lines.Add("|---|---:|")
$lines.Add("| 服务端注册协议 | $total |")
$lines.Add("| smoke 已覆盖协议号 | $covered |")
$lines.Add("| 未覆盖注册协议 | $uncovered |")
$lines.Add("")
$lines.Add("## Steam SQLite S5 保留范围覆盖")
$lines.Add("")
$lines.Add("本节从 ``unityclient-modules.json`` 的非排除模块和 ``Invoke-ProtocolSmoke.ps1 -SteamIncluded`` 白名单生成。``missing-or-passive`` 不能视为失败或通过：它表示尚无主动请求 case，下一步必须区分服务端推送与真实缺口并补结构化断言。")
$lines.Add("")
$lines.Add("| 项 | 数量 |")
$lines.Add("|---|---:|")
$lines.Add("| Steam 保留模块 | $($steamModules.Count) |")
$lines.Add("| 模块登记协议 | $($steamProtocols.Count) |")
$lines.Add("| 已有主动请求 case | $steamRequestCovered |")
$lines.Add("| 待区分被动推送/真实缺口 | $steamMissingOrPassive |")
$lines.Add("")
$lines.Add("| 协议号 | 名称 | 所属模块 | S5主动请求 case | 状态 |")
$lines.Add("|---:|---|---|---|---|")
foreach ($entry in $steamCoverageRows) {
    $cases = if ($entry.requestCases.Count -gt 0) { $entry.requestCases -join ', ' } else { '-' }
    $lines.Add("| $($entry.protocol) | ``$($entry.name)`` | $($entry.modules -join ', ') | $cases | ``$($entry.coverage)`` |")
}
$lines.Add("")
$lines.Add("## 未覆盖分层统计")
$lines.Add("")
$lines.Add("| 分层 | 未覆盖数量 | 推进方式 |")
$lines.Add("|---|---:|---|")
$layerNotes = @{
    "查询" = "优先补入 ``-Extended``，要求有响应且日志干净。"
    "低风险动作" = "优先补入 ``-Actions``，使用空状态/无效参数/只读变更。"
    "可控改档" = "补入 ``-Mutations``，只操作一次性角色和本地测试字段。"
    "真实消耗" = "补入 ``-Positive``，一次性角色给足测试货币并校验扣减/返回。"
    "战斗结算" = "单独分支验证，优先使用可重复的一次性角色和可控战斗入口。"
    "人工 UI" = "保留给客户端点击路径、复杂状态机或无法安全脚本化的入口。"
    "服务端内部/跨服" = "默认不进客户端 smoke，除非本地有明确触发入口。"
}
$layerOrder = @("查询","低风险动作","可控改档","真实消耗","战斗结算","人工 UI","服务端内部/跨服")
foreach ($layer in $layerOrder) {
    $count = @($uncoveredEntries | Where-Object { $_.Layer -eq $layer }).Count
    if ($count -eq 0) { continue }
    $lines.Add("| $layer | $count | $($layerNotes[$layer]) |")
}
$lines.Add("")
$lines.Add("## 下一批优先补覆盖")
$lines.Add("")
$lines.Add("| 协议号 | 名称 | 分层 |")
$lines.Add("|---:|---|---|")
$nextLayers = @("查询","低风险动作","可控改档")
foreach ($entry in ($uncoveredEntries | Where-Object { $nextLayers -contains $_.Layer } | Sort-Object @{Expression = { [array]::IndexOf($nextLayers, $_.Layer) }},Value,Name | Select-Object -First 30)) {
    $lines.Add("| $($entry.Value) | ``$($entry.Name)`` | $($entry.Layer) |")
}
$lines.Add("")
$lines.Add("## 已覆盖注册协议")
$lines.Add("")
$lines.Add("| 协议号 | 名称 | smoke case |")
$lines.Add("|---:|---|---|")
foreach ($entry in ($registered | Where-Object { $null -ne $_.Value -and $coveredByValue.ContainsKey($_.Value) } | Sort-Object Value,Name)) {
    $cases = ($coveredByValue[$entry.Value] | Sort-Object -Unique) -join ", "
    $lines.Add("| $($entry.Value) | ``$($entry.Name)`` | $cases |")
}
$lines.Add("")
$lines.Add("## 未覆盖注册协议")
$lines.Add("")
$lines.Add("| 协议号 | 名称 | 分层 |")
$lines.Add("|---:|---|---|")
foreach ($entry in ($uncoveredEntries | Sort-Object Layer,Value,Name)) {
    $lines.Add("| $($entry.Value) | ``$($entry.Name)`` | $($entry.Layer) |")
}
$lines.Add("")
$lines.Add("## smoke 中未匹配注册名的协议号")
$lines.Add("")
$lines.Add("| 协议号 | protocol.h 名称 | smoke case |")
$lines.Add("|---:|---|---|")
foreach ($value in ($coveredByValue.Keys | Sort-Object)) {
    $registeredMatch = $registered | Where-Object { $_.Value -eq $value } | Select-Object -First 1
    if ($registeredMatch) { continue }
    $name = if ($nameByValue.ContainsKey($value)) { $nameByValue[$value] } else { "" }
    $cases = ($coveredByValue[$value] | Sort-Object -Unique) -join ", "
    $lines.Add("| $value | ``$name`` | $cases |")
}

Set-Content -Path $OutFile -Value ($lines -join "`n") -Encoding UTF8
Write-Host "Protocol coverage written: $OutFile"
Write-Host "registered=$total covered=$covered uncovered=$uncovered"
Write-Host "steam_protocols=$($steamProtocols.Count) request_covered=$steamRequestCovered missing_or_passive=$steamMissingOrPassive json=$SteamJsonOut"
