[CmdletBinding()]
param(
    [string]$ManifestPath = "",
    [int]$StatusMaxLines = 100,
    [int]$HandoffMaxLines = 200,
    [int]$PlanMaxLines = 250,
    [string]$JsonOutput = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifestEntry = Import-UnityMigrationManifest -Root $root -ManifestPath $ManifestPath
$manifest = $manifestEntry.Value
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) { $failures.Add($Message) }
function Add-Warning([string]$Message) { $warnings.Add($Message) }

$templateProbe = Expand-UnityMigrationTemplate -Template "user={{UserId}}" -Variables @{ UserId = 42 }
if ($templateProbe -ne "user=42") { Add-Failure "Validation data template expansion is broken." }
try {
    Expand-UnityMigrationTemplate -Template "{{UnknownToken}}" -Variables @{ UserId = 42 } | Out-Null
    Add-Failure "Validation data template expansion accepted an unresolved token."
}
catch {
    if ($_.Exception.Message -notlike "Unresolved Unity migration template token*") { throw }
}

function Test-RequiredFile {
    param([string]$RelativePath)
    $path = Resolve-UnityMigrationPath -Root $root -Path $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing required file: $RelativePath"
        return $null
    }
    return $path
}

$statusPath = Test-RequiredFile "UNITYCLIENT_STATUS.md"
$handoffPath = Test-RequiredFile "UNITYCLIENT_HANDOFF.md"
$planPath = Test-RequiredFile "UNITYCLIENT_MIGRATION_PLAN.md"
Test-RequiredFile "docs/unityclient/modules/README.md" | Out-Null
Test-RequiredFile "docs/unityclient/history/README.md" | Out-Null

$lineRules = @(
    [pscustomobject]@{ Name = "STATUS"; Path = $statusPath; Limit = $StatusMaxLines },
    [pscustomobject]@{ Name = "HANDOFF"; Path = $handoffPath; Limit = $HandoffMaxLines },
    [pscustomobject]@{ Name = "PLAN"; Path = $planPath; Limit = $PlanMaxLines }
)
foreach ($rule in $lineRules) {
    if (-not $rule.Path) { continue }
    $count = @(Get-Content -Encoding UTF8 -LiteralPath $rule.Path).Count
    if ($count -gt $rule.Limit) {
        Add-Failure "$($rule.Name) has $count lines; limit is $($rule.Limit)."
    }
}

if ($statusPath) {
    $status = Get-Content -Raw -Encoding UTF8 -LiteralPath $statusPath
    $functionalMatches = [regex]::Matches($status, '(?m)^\| Functional \| `?约?\d+%')
    if ($functionalMatches.Count -ne 1) {
        Add-Failure "STATUS must contain exactly one Functional percentage row; found $($functionalMatches.Count)."
    }
    $friendModule = @($manifest.modules | Where-Object { [string]$_.key -eq "Friend" }) | Select-Object -First 1
    if ([string]$friendModule.status -ne "phase1-complete" -and $status -notmatch '下一批：`Friend Store`') {
        Add-Warning "STATUS next batch is not Friend Store. Update the manifest/document plan if this is intentional."
    }
}

$currentDocPaths = @($statusPath, $handoffPath, $planPath) | Where-Object { $_ }
$moduleDocDir = Resolve-UnityMigrationPath -Root $root -Path "docs/unityclient/modules"
$currentDocPaths += @(Get-ChildItem -LiteralPath $moduleDocDir -Filter "*.md" -File | ForEach-Object FullName)
foreach ($path in $currentDocPaths) {
    $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
    if ($text -match '18%') { Add-Failure "Stale 18% progress marker: $path" }
    if ($text -match 'D:\\neiwang_kapai') { Add-Failure "Stale D drive project path: $path" }
}

$keys = @($manifest.modules | ForEach-Object { [string]$_.key })
$duplicates = @($keys | Group-Object | Where-Object Count -gt 1)
foreach ($duplicate in $duplicates) { Add-Failure "Duplicate manifest module key: $($duplicate.Name)" }

$runnerText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs")
$protocolHeader = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "server/src/protocol.h")
foreach ($module in $manifest.modules) {
    $key = [string]$module.key
    if ($key -notmatch '^[A-Z][A-Za-z0-9]+$') { Add-Failure "Invalid module key: $key" }
    if (-not $module.document) {
        Add-Failure "Module $key has no document."
    }
    else {
        Test-RequiredFile ([string]$module.document) | Out-Null
    }
    foreach ($path in @($module.prefabs) + @($module.configs)) {
        if (-not $path) { continue }
        $resolved = Resolve-UnityMigrationPath -Root $root -Path ([string]$path)
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            Add-Failure "Module $key references missing file: $path"
        }
    }
    foreach ($flag in @($module.validationFlags)) {
        if (-not $flag) { continue }
        if ($flag -notmatch '^-projectX[A-Za-z0-9]+Validation$') {
            Add-Failure "Module $key has invalid validation flag: $flag"
        }
        elseif ($runnerText -notmatch [Regex]::Escape([string]$flag)) {
            Add-Failure "Module $key validation flag is not handled by BootstrapAppRunner: $flag"
        }
    }
    foreach ($protocol in @($module.protocols)) {
        if ([int]$protocol -lt 1 -or [int]$protocol -gt 65535) {
            Add-Failure "Module $key has invalid protocol number: $protocol"
        }
        elseif ($protocolHeader -notmatch "=\s*$protocol\s*;") {
            Add-Warning "Module $key protocol /$protocol was not found as an explicit constant assignment in protocol.h."
        }
    }
    $validationDataProperty = $module.PSObject.Properties["validationData"]
    if ($null -ne $validationDataProperty) {
        $validationData = $validationDataProperty.Value
        $providerName = [string]$validationData.provider
        $providerProperty = $manifest.validationDataProviders.PSObject.Properties[$providerName]
        if (-not $providerName -or $null -eq $providerProperty) {
            Add-Failure "Module $key references missing validation data provider: $providerName"
        }
        if (@($validationData.setupSql).Count -eq 0) {
            Add-Failure "Module $key validationData has no setupSql."
        }
        if (@($validationData.cleanupSql).Count -eq 0) {
            Add-Failure "Module $key validationData has no cleanupSql."
        }
        $templates = @($validationData.setupSql) + @($validationData.cleanupSql)
        $allowedTokens = @("UserId", "Now", "NowMinus60", "NowPlus3600", "Module")
        foreach ($template in $templates) {
            foreach ($match in [regex]::Matches([string]$template, '\{\{([A-Za-z][A-Za-z0-9]*)\}\}')) {
                if ($match.Groups[1].Value -notin $allowedTokens) {
                    Add-Failure "Module $key uses unsupported validation data token: $($match.Value)"
                }
            }
        }
    }
}

$friend = @($manifest.modules | Where-Object key -eq "Friend")
if ($friend.Count -ne 1) { Add-Failure "Manifest must contain exactly one Friend module." }

$result = [ordered]@{
    success = ($failures.Count -eq 0)
    manifest = $manifestEntry.Path
    moduleCount = @($manifest.modules).Count
    failures = @($failures)
    warnings = @($warnings)
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}

if ($JsonOutput) {
    $output = Resolve-UnityMigrationPath -Root $root -Path $JsonOutput
    Write-UnityMigrationUtf8 -Path $output -Content (($result | ConvertTo-Json -Depth 8) + "`n")
}

foreach ($warning in $warnings) { Write-Warning $warning }
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Error $failure }
    exit 1
}

Write-Host "Unity migration docs passed: $(@($manifest.modules).Count) modules, no consistency failures."
exit 0
