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
    [string]$ValidationFlag = "",
    [string]$DestinationRoot = "",
    [string]$ManifestPath = "",
    [switch]$SkipManifest,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")

$repositoryRoot = Get-UnityMigrationRoot
if (-not $DestinationRoot) { $DestinationRoot = $repositoryRoot }
$destination = Resolve-UnityMigrationPath -Root $repositoryRoot -Path $DestinationRoot
$displayNameProvided = $PSBoundParameters.ContainsKey("DisplayName")
if (-not $DisplayName) { $DisplayName = $Module }

$files = [ordered]@{}
$files[(Join-Path $destination "unityclient\Assets\ProjectX\src\Data\${Module}Store.cs")] = @"
using System;
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class ${Module}Store
    {
        private readonly List<${Module}Record> items = new List<${Module}Record>();

        public event Action Changed;
        public IReadOnlyList<${Module}Record> Items => items;

        public void Replace(IEnumerable<${Module}Record> values)
        {
            items.Clear();
            if (values != null) items.AddRange(values);
            Changed?.Invoke();
        }

        public void Reset()
        {
            items.Clear();
            Changed?.Invoke();
        }
    }

    public sealed class ${Module}Record
    {
        public uint Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}
"@
$files[(Join-Path $destination "unityclient\Assets\ProjectX\src\Data\${Module}Catalog.cs")] = @"
using System.Collections.Generic;

namespace ProjectX.Data
{
    public sealed class ${Module}Catalog
    {
        private readonly Dictionary<uint, string> names = new Dictionary<uint, string>();

        public bool TryGetName(uint id, out string name) => names.TryGetValue(id, out name);
    }
}
"@
$files[(Join-Path $destination "unityclient\Assets\ProjectX\src\UI\${Module}Presenter.cs")] = @"
using System;
using ProjectX.Data;

namespace ProjectX.UI
{
    public sealed class ${Module}Presenter : IDisposable
    {
        private readonly ${Module}Store store;

        public ${Module}Presenter(${Module}Store store)
        {
            this.store = store ?? throw new ArgumentNullException(nameof(store));
            this.store.Changed += Render;
        }

        public void Render()
        {
            // Bind the authoritative Store state to the imported prefab here.
        }

        public void Dispose()
        {
            store.Changed -= Render;
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

return M
"@
$docName = $Module.ToUpperInvariant() + ".md"
$documentRelative = "docs/unityclient/modules/$docName"
$documentPath = Join-Path $destination ($documentRelative -replace '/', '\')
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

## 实现

- `${Module}Store`
- `${Module}Catalog`
- `${Module}Presenter`
- `${Module}Controller.lua`

## 验证

- 空态：未验证。
- 正常态：未验证。
- 增量/错误/断线：未验证。
- 隔离角色：未验证。
- GameView：未验证。

## 遗留

- 完成协议取证、真实 Prefab 绑定、自动化和完成门禁。
"@

$skipExisting = New-Object System.Collections.Generic.List[string]
foreach ($entry in $files.GetEnumerator()) {
    $path = [string]$entry.Key
    if ((Test-Path -LiteralPath $path) -and -not $Force) {
        if ($path -eq $documentPath) {
            [void]$skipExisting.Add($path)
            continue
        }
        throw "Refusing to overwrite existing file without -Force: $path"
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

if (-not $SkipManifest) {
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
            document = $documentRelative
        }
        $manifest.modules = @($manifest.modules) + @($newModule)
    }
    if ($PSCmdlet.ShouldProcess($manifestEntry.Path, "Update Unity migration manifest")) {
        Write-UnityMigrationUtf8 -Path $manifestEntry.Path -Content (($manifest | ConvertTo-Json -Depth 12) + "`n")
    }
}

Write-Host "Module scaffold ready: $Module"
Write-Host "Selected files: $($files.Count - $skipExisting.Count); written files: $generatedCount; preserved files: $($skipExisting.Count)"
Write-Host "Next: evidence -> protocol parser -> Store merge -> prefab binding -> validation flag."
