[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Z][A-Za-z0-9]+$')]
    [string]$Module,
    [string]$DisplayName = "",
    [int[]]$Protocols = @(),
    [string[]]$Entries = @(),
    [string[]]$Prefabs = @(),
    [string[]]$Configs = @(),
    [switch]$Mutation,
    [uint32]$FixedUserId = 0,
    [uint32]$FixedRoleId = 0,
    [string]$FixtureAdapter = "",
    [string]$ValidationFlag = "",
    [string]$DestinationRoot = "",
    [string]$ManifestPath = "",
    [switch]$SkipManifest,
    [switch]$IncludeImplementationSkeleton,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")

$repositoryRoot = Get-UnityMigrationRoot
if (-not $DestinationRoot) { $DestinationRoot = $repositoryRoot }
$destination = Resolve-UnityMigrationPath -Root $repositoryRoot -Path $DestinationRoot
$displayNameProvided = $PSBoundParameters.ContainsKey("DisplayName")
if (-not $DisplayName) { $DisplayName = $Module }
$moduleSlug = ($Module -creplace '([a-z0-9])([A-Z])', '$1-$2').ToLowerInvariant()
if (-not $IncludeImplementationSkeleton -and -not $SkipManifest) {
    if ($FixedUserId -eq 0 -or $FixedRoleId -eq 0) {
        throw "Module scaffolding must freeze -FixedUserId and -FixedRoleId at G0."
    }
    if ($Mutation -and -not $FixtureAdapter) {
        throw "Mutating module scaffolding requires -FixtureAdapter for reversible setup/restore/cleanup."
    }
}

$files = [ordered]@{}
if ($IncludeImplementationSkeleton) {
    Assert-UnityMigrationGatePrerequisite -Root $repositoryRoot -ModuleKey $Module -RequiredGate G2
$files[(Join-Path $destination "unityclient\Assets\ProjectX\src\UI\${Module}ViewState.cs")] = @"
using System;
using System.Collections.Generic;

namespace ProjectX.UI
{
    [Serializable]
    public sealed class ${Module}ViewState
    {
        public string Status = string.Empty;
        public List<${Module}ViewItem> Items = new List<${Module}ViewItem>();
    }

    [Serializable]
    public sealed class ${Module}ViewItem
    {
        public uint Id;
        public string Name = string.Empty;
    }
}
"@
$files[(Join-Path $destination "unityclient\Assets\ProjectX\src\UI\${Module}RenderBridge.cs")] = @"
using System;

namespace ProjectX.UI
{
    public sealed class ${Module}RenderBridge
    {
        public void Render(${Module}ViewState state)
        {
            if (state == null) throw new ArgumentNullException(nameof(state));
            // Rendering only: bind the Lua-authored DTO to the imported prefab.
            // Protocol parsing, business rules and persistent state stay in Lua.
        }
    }
}
"@
$files[(Join-Path $destination "unityclient\Assets\ProjectX\Resources\Lua\$Module\${Module}Controller.lua.txt")] = @"
local M = {}

function M.register(app)
    assert(app, "$Module controller requires the ProjectX app bridge")
end

function M.requestList()
    error("$Module requestList is not implemented")
end

function M.reset()
end

function M.buildViewState()
    return { status = "", items = {} }
end

return M
"@
}
$docName = $Module.ToUpperInvariant() + ".md"
$documentRelative = "docs/unityclient/modules/$docName"
$documentPath = Join-Path $destination ($documentRelative -replace '/', '\')
$matrixRelative = "docs/unityclient/matrices/$($Module.ToUpperInvariant())_CONTROLS.json"
$matrixPath = Join-Path $destination ($matrixRelative -replace '/', '\')
$protocolText = if ($Protocols.Count -gt 0) { ($Protocols | ForEach-Object { "/$_" }) -join "、" } else { "待取证" }
$files[$documentPath] = @"
# $DisplayName 模块

> 状态：骨架已生成，业务尚未完成。

## 范围

待补充。

## 三方证据

- 协议：$protocolText。
- 服务端处理函数：待补充。
- 旧客户端请求/解析：待补充。
- 真实回包：待补充。

## 实现边界

- `${Module}Controller.lua`：协议、业务规则和权威状态。
- `${Module}ViewState`：Lua → C# 的只读渲染 DTO。
- `${Module}RenderBridge`：仅绑定 Prefab、资源、动画和交互回调。
- 禁止新建业务型 C# Store/Catalog 或在 Bridge 解析协议。

## 验证

- 空态：未验证。
- 正常态：未验证。
- 增量/错误/断线：未验证。
- 隔离角色：未验证。
- GameView：未验证。

## 冻结项

- G0 `acceptanceExamples`：待补充具体 `given/when/then`。
- G1 Cocos 自动化账本：待生成。
- G2 `sourceAudit`：入口、共享协议、配置资源和运行时 Transform 待核清。
- G3 batch 场景：源码锚点、语义断言、截图状态和固定账号合同待冻结。

## 遗留

- 完成协议取证、真实 Prefab 绑定、自动化和完成门禁。
"@
$files[$matrixPath] = @"
{
  "schemaVersion": 1,
  "module": "$Module",
  "workflowPolicyVersion": 1,
  "scope": {
    "fixedUserId": $FixedUserId,
    "fixedRoleId": $FixedRoleId
  },
  "acceptanceExamples": [],
  "sourceAudit": {
    "entryClosureComplete": false,
    "protocolOwnershipComplete": false,
    "configAssetClosureComplete": false,
    "runtimeTransformClosureComplete": false,
    "knownGaps": []
  },
  "controls": []
}
"@

$skipExisting = New-Object System.Collections.Generic.List[string]
foreach ($entry in $files.GetEnumerator()) {
    $path = [string]$entry.Key
    if (Test-Path -LiteralPath $path) {
        if ($IncludeImplementationSkeleton -and $path -in @($documentPath, $matrixPath)) {
            [void]$skipExisting.Add($path)
            continue
        }
        if (-not $Force) {
            if ($path -eq $documentPath) {
                [void]$skipExisting.Add($path)
                continue
            }
            throw "Refusing to overwrite existing file without -Force: $path"
        }
    }
}

$generatedCount = 0
foreach ($entry in $files.GetEnumerator()) {
    $path = [string]$entry.Key
    if ($skipExisting.Contains($path)) {
        Write-Host "Preserving existing module document: $path"
        continue
    }
    if ($PSCmdlet.ShouldProcess($path, "Create Unity migration module skeleton")) {
        Write-UnityMigrationUtf8 -Path $path -Content (([string]$entry.Value).TrimEnd() + "`n")
        $generatedCount++
    }
}

if (-not $SkipManifest -and -not $IncludeImplementationSkeleton) {
    $manifestEntry = Import-UnityMigrationManifest -Root $repositoryRoot -ManifestPath $ManifestPath
    $manifest = $manifestEntry.Value
    $existingModules = @($manifest.modules | Where-Object { $_.key -eq $Module })
    if ($existingModules.Count -gt 1) { throw "Manifest contains duplicate module '$Module'." }
    $flags = @()
    if ($ValidationFlag) { $flags += $ValidationFlag }
    if ($existingModules.Count -eq 1) {
        $existing = $existingModules[0]
        if ($existing.status -notin @("planned", "scaffolded") -and -not $Force) {
            throw "Manifest module '$Module' has status '$($existing.status)'; use -Force only when replacement is intentional."
        }
        if ($displayNameProvided) { $existing.displayName = $DisplayName }
        if ($PSBoundParameters.ContainsKey("Protocols")) { $existing.protocols = @($Protocols) }
        if ($PSBoundParameters.ContainsKey("Entries")) { $existing.entries = @($Entries) }
        if ($PSBoundParameters.ContainsKey("Prefabs")) { $existing.prefabs = @($Prefabs) }
        if ($PSBoundParameters.ContainsKey("Configs")) { $existing.configs = @($Configs) }
        if ($PSBoundParameters.ContainsKey("Mutation")) { $existing.mutatesServer = [bool]$Mutation }
        if ($PSBoundParameters.ContainsKey("ValidationFlag")) { $existing.validationFlags = $flags }
        $existing.status = "scaffolded"
        $existing.document = $documentRelative
        $existing | Add-Member -Force -NotePropertyName controlMatrix -NotePropertyValue $matrixRelative
    }
    else {
        $newModule = [ordered]@{
            key = $Module
            displayName = $DisplayName
            status = "scaffolded"
            protocols = @($Protocols)
            entries = @($Entries)
            prefabs = @($Prefabs)
            configs = @($Configs)
            mutatesServer = [bool]$Mutation
            validationFlags = $flags
            screenshots = @()
            controlMatrix = $matrixRelative
            document = $documentRelative
        }
        $manifest.modules = @($manifest.modules) + @($newModule)
    }
    if ($PSCmdlet.ShouldProcess($manifestEntry.Path, "Update Unity migration manifest")) {
        Write-UnityMigrationUtf8 -Path $manifestEntry.Path -Content (($manifest | ConvertTo-Json -Depth 12) + "`n")
    }

    $scenarioEntry = Import-UnityMigrationJson -Root $repositoryRoot -Path "tools/unity-migration/validation-scenarios.json"
    $scenarioMatches = @($scenarioEntry.Value.scenarios | Where-Object { $_.module -ieq $Module })
    if ($scenarioMatches.Count -gt 1) { throw "Validation scenario registry contains duplicate module '$Module'." }
    $savedModule = @($manifest.modules | Where-Object { $_.key -eq $Module }) | Select-Object -First 1
    $fixtureKey = if ([bool]$savedModule.mutatesServer) { "reversible-$moduleSlug-fixed-account" } else { "shared-readonly" }
    if ($scenarioMatches.Count -eq 0) {
        $scenarioEntry.Value.scenarios = @($scenarioEntry.Value.scenarios) + @([ordered]@{
            key = "$moduleSlug-default"
            module = $Module
            fixture = $fixtureKey
            requiredGate = "G3"
            flags = $flags
            artifacts = @()
            captureStates = @()
            controlCoverageRequired = $true
            semanticAssertionKeys = @()
            sourceContracts = @()
            visualAssertions = [ordered]@{
                width = 1334
                height = 750
                minimumBytes = 4096
                requireUniqueHashes = $true
            }
        })
    }
    else {
        $scenarioMatches[0].fixture = $fixtureKey
        $scenarioMatches[0].flags = $flags
        $scenarioMatches[0] | Add-Member -Force -NotePropertyName requiredGate -NotePropertyValue "G3"
        $scenarioMatches[0] | Add-Member -Force -NotePropertyName controlCoverageRequired -NotePropertyValue $true
        foreach ($name in @("semanticAssertionKeys", "sourceContracts")) {
            if ($null -eq $scenarioMatches[0].PSObject.Properties[$name]) {
                $scenarioMatches[0] | Add-Member -NotePropertyName $name -NotePropertyValue @()
            }
        }
        if ($null -eq $scenarioMatches[0].PSObject.Properties["visualAssertions"]) {
            $scenarioMatches[0] | Add-Member -NotePropertyName visualAssertions -NotePropertyValue ([pscustomobject][ordered]@{
                width = 1334
                height = 750
                minimumBytes = 4096
                requireUniqueHashes = $true
            })
        }
    }
    if ($PSCmdlet.ShouldProcess($scenarioEntry.Path, "Update validation scenario registry")) {
        Write-UnityMigrationUtf8 -Path $scenarioEntry.Path -Content (($scenarioEntry.Value | ConvertTo-Json -Depth 12) + "`n")
    }

    $fixtureEntry = Import-UnityMigrationJson -Root $repositoryRoot -Path "tools/unity-migration/validation-fixtures.json"
    $fixtureMatches = @($fixtureEntry.Value.profiles | Where-Object { $_.key -ieq $fixtureKey })
    if ($fixtureMatches.Count -gt 1) { throw "Fixture registry contains duplicate key '$fixtureKey'." }
    if ($fixtureMatches.Count -eq 0) {
        $fixtureEntry.Value.profiles = @($fixtureEntry.Value.profiles) + @([ordered]@{
            key = $fixtureKey
            roleMode = $(if ($Mutation) { "fixed-account" } else { "shared" })
            mutatesServer = [bool]$Mutation
            cleanup = $(if ($Mutation) { "snapshot-relogin-restore-cleanup-assert" } else { "none" })
            adapter = $FixtureAdapter
        })
    }
    if ($PSCmdlet.ShouldProcess($fixtureEntry.Path, "Register validation fixture atomically")) {
        Write-UnityMigrationUtf8 -Path $fixtureEntry.Path -Content (($fixtureEntry.Value | ConvertTo-Json -Depth 12) + "`n")
    }

    $contractEntry = Import-UnityMigrationJson -Root $repositoryRoot -Path "tools/unity-migration/module-evidence-contracts.json"
    $contractMatches = @($contractEntry.Value.modules | Where-Object { $_.module -ieq $Module })
    if ($contractMatches.Count -gt 1) { throw "Evidence contract registry contains duplicate module '$Module'." }
    if ($contractMatches.Count -eq 0) {
        $newContract = [ordered]@{
            module = $Module
            g5 = [ordered]@{
                width = 1334
                height = 750
                cocosDirectory = ".local/ui-fidelity/$Module/cocos/g1"
                unityDirectory = ".local/ui-fidelity/$Module/unity/g5"
                compareDirectory = ".local/ui-fidelity/$Module/compare/g5"
                cocosBaselineInputs = @()
                pairs = @()
            }
        }
        if ($Mutation) {
            $newContract.fixedAccount = [ordered]@{
                userId = $FixedUserId
                roleId = $FixedRoleId
                adapter = $FixtureAdapter
                snapshot = ".local/ui-fidelity/$Module/unity/g5/$moduleSlug-fixed-fixture-snapshot.json"
                resultEvidence = ".local/ui-fidelity/$Module/unity/g6/$moduleSlug-fixed-unity-result.json"
                reloginRequired = $true
                extraFlags = $flags
                skipPostValidationFixtureAssert = $false
                dataPreflight = [ordered]@{ requiresLogin = $true; requirements = @() }
                artifactCopies = @()
            }
        }
        else {
            $newContract.g5.identity = [ordered]@{ primaryUserId = $FixedUserId; primaryRoleId = $FixedRoleId }
        }
        $contractEntry.Value.modules = @($contractEntry.Value.modules) + @($newContract)
    }
    if ($PSCmdlet.ShouldProcess($contractEntry.Path, "Register G5 and fixed-account evidence contracts atomically")) {
        Write-UnityMigrationUtf8 -Path $contractEntry.Path -Content (($contractEntry.Value | ConvertTo-Json -Depth 12) + "`n")
    }

    $gateEntry = Import-UnityMigrationJson -Root $repositoryRoot -Path "tools/unity-migration/migration-gates.json"
    $gateMatches = @($gateEntry.Value.modules | Where-Object { $_.module -ieq $Module })
    if ($gateMatches.Count -gt 1) { throw "Gate registry contains duplicate module '$Module'." }
    if ($gateMatches.Count -eq 0) {
        $gateEntry.Value.modules = @($gateEntry.Value.modules) + @([ordered]@{
            module = $Module
            gates = [ordered]@{ G0 = "pending"; G1 = "pending"; G2 = "pending"; G3 = "pending"; G4 = "pending"; G5 = "pending"; G6 = "pending" }
            evidence = $documentRelative
        })
        if ($PSCmdlet.ShouldProcess($gateEntry.Path, "Add pending G0-G6 gate record")) {
            Write-UnityMigrationUtf8 -Path $gateEntry.Path -Content (($gateEntry.Value | ConvertTo-Json -Depth 12) + "`n")
        }
    }
}

Write-Host "Module scaffold ready: $Module"
Write-Host "Selected files: $($files.Count - $skipExisting.Count); written files: $generatedCount; preserved files: $($skipExisting.Count)"
Write-Host "Next: freeze workflowPolicyVersion=1, acceptanceExamples and controls at G0; collect the Cocos automation ledger at G1; close sourceAudit at G2. Re-run with -IncludeImplementationSkeleton only after G2 passed; run Unity only through the batch runners at G4-G6."
