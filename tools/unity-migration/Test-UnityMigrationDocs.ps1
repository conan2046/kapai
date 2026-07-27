[CmdletBinding()]
param(
    [string]$ManifestPath = "",
    [int]$StatusMaxLines = 100,
    [int]$GuideMaxLines = 360,
    [string]$JsonOutput = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifestEntry = Import-UnityMigrationManifest -Root $root -ManifestPath $ManifestPath
$manifest = $manifestEntry.Value
$scenarioEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/validation-scenarios.json"
$fixtureEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/validation-fixtures.json"
$evidenceContractEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/module-evidence-contracts.json"
$gateEntry = Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/migration-gates.json"
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
try {
    Assert-UnityMigrationRuntimeArtifact -Root $root `
        -Artifact ([pscustomobject]@{ path = ".local/ui-fidelity/protected.png"; lifecycle = "runtime" }) | Out-Null
    Add-Failure "Runtime artifact guard accepted an immutable visual evidence path."
}
catch {
    if ($_.Exception.Message -notlike "Runtime artifact points inside immutable evidence root*") { throw }
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
$guidePath = Test-RequiredFile "docs/unityclient/MIGRATION_GUIDE.md"
Test-RequiredFile "docs/unityclient/modules/README.md" | Out-Null
Test-RequiredFile "docs/unityclient/history/README.md" | Out-Null

$lineRules = @(
    [pscustomobject]@{ Name = "STATUS"; Path = $statusPath; Limit = $StatusMaxLines },
    [pscustomobject]@{ Name = "MIGRATION_GUIDE"; Path = $guidePath; Limit = $GuideMaxLines }
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
    $functionalMatches = [regex]::Matches($status, '(?m)^\| Functional \| (`?约?\d+%|`待逐控件重审`)')
    if ($functionalMatches.Count -ne 1) {
        Add-Failure "STATUS must contain exactly one Functional percentage row; found $($functionalMatches.Count)."
    }
    $friendModule = @($manifest.modules | Where-Object { [string]$_.key -eq "Friend" }) | Select-Object -First 1
    if ([string]$friendModule.status -ne "phase1-complete" -and $status -notmatch '下一批：`Friend Store`') {
        Add-Warning "STATUS next batch is not Friend Store. Update the manifest/document plan if this is intentional."
    }
}

$currentDocPaths = @($statusPath, $guidePath) | Where-Object { $_ }
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
$scenarioKeys = @($scenarioEntry.Value.scenarios | ForEach-Object { [string]$_.key })
foreach ($duplicate in @($scenarioKeys | Group-Object | Where-Object Count -gt 1)) {
    Add-Failure "Duplicate validation scenario key: $($duplicate.Name)"
}
$fixtureKeys = @($fixtureEntry.Value.profiles | ForEach-Object { [string]$_.key })

$runnerText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs")
$protocolHeader = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "server/src/protocol.h")
foreach ($module in $manifest.modules) {
    $key = [string]$module.key
    $scenarios = @($scenarioEntry.Value.scenarios | Where-Object { $_.module -ieq $key })
    if ($scenarios.Count -ne 1) {
        Add-Failure "Module $key must have exactly one central validation scenario; found $($scenarios.Count)."
        $scenario = $null
    }
    else { $scenario = $scenarios[0] }
    if ($null -ne $scenario) {
        try { Assert-UnityMigrationSourceContracts -Root $root -Scenario $scenario | Out-Null }
        catch { Add-Failure "Module $key source contract failed: $($_.Exception.Message)" }
        if ([string]$scenario.fixture -notin $fixtureKeys) {
            Add-Failure "Module $key scenario references missing fixture: $($scenario.fixture)"
        }
        $manifestFlags = @($module.validationFlags | ForEach-Object { [string]$_ })
        $scenarioFlags = @($scenario.flags | ForEach-Object { [string]$_ })
        if (@(Compare-Object $manifestFlags $scenarioFlags).Count -gt 0) {
            Add-Failure "Module $key manifest/scenario validation flags drifted."
        }
        foreach ($artifact in @($scenario.artifacts)) {
            try {
                Assert-UnityMigrationRuntimeArtifact -Root $root -Artifact $artifact `
                    -ImmutableRoots @($scenarioEntry.Value.artifactPolicy.immutableRoots) | Out-Null
            }
            catch { Add-Failure "Module $key has unsafe runtime artifact: $($_.Exception.Message)" }
        }
        $requiredGate = [string](Get-UnityMigrationPropertyValue -Object $scenario -Name "requiredGate" -Default "")
        $coverageRequired = [bool](Get-UnityMigrationPropertyValue -Object $scenario `
            -Name "controlCoverageRequired" -Default $false)
        $semanticKeys = @((Get-UnityMigrationPropertyValue -Object $scenario `
            -Name "semanticAssertionKeys" -Default @()) | ForEach-Object { [string]$_ })
        if ($coverageRequired -and -not [string](Get-UnityMigrationPropertyValue -Object $module `
            -Name "controlMatrix" -Default "")) {
            Add-Failure "Module $key requires runtime control coverage without a controlMatrix."
        }
        if (@($semanticKeys | Where-Object { -not $_ }).Count -gt 0 -or
            @($semanticKeys | Sort-Object -Unique).Count -ne $semanticKeys.Count) {
            Add-Failure "Module $key has empty or duplicate semanticAssertionKeys."
        }
        if ($requiredGate) {
            $gateRecords = @($gateEntry.Value.modules | Where-Object { $_.module -ieq $key })
            if ($gateRecords.Count -ne 1) { Add-Failure "Module $key scenario requires $requiredGate but has no unique gate record." }
        }
    }
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
    $moduleStatus = [string]$module.status
    $visualProperty = $module.PSObject.Properties["visualFidelity"]
    $visual = if ($null -ne $visualProperty) { $visualProperty.Value } else { $null }
    $visualCompleteStatus = if ($manifest.visualFidelityPolicy.completeStatus) {
        [string]$manifest.visualFidelityPolicy.completeStatus
    }
    else { "visual-1to1-complete" }
    if (($moduleStatus -match 'visual-(pending|fixing)') -and $null -eq $visual) {
        Add-Failure "Module $key declares visual work but has no visualFidelity record."
    }
    if ($null -ne $visual) {
        $allowedVisualStates = @("pending-cocos-baseline", "visual-fixing", "passed")
        if ([string]$visual.status -notin $allowedVisualStates) {
            Add-Failure "Module $key has invalid visualFidelity status: $($visual.status)"
        }
    }
    if ($moduleStatus -eq $visualCompleteStatus) {
        $controlMatrix = [string](Get-UnityMigrationPropertyValue -Object $module -Name "controlMatrix" -Default "")
        if (-not $controlMatrix) {
            Add-Failure "Module $key claims $visualCompleteStatus without a controlMatrix."
        }
        else {
            try { Assert-UnityMigrationControlMatrix -Root $root -ModuleKey $key -Path $controlMatrix | Out-Null }
            catch { Add-Failure "Module $key controlMatrix failed: $($_.Exception.Message)" }
        }
        if ($null -eq $visual -or [string]$visual.status -ne "passed") {
            Add-Failure "Module $key claims $visualCompleteStatus without passed visualFidelity evidence."
        }
        else {
            foreach ($field in @("cocosScreenshots", "unityScreenshots", "diffReports")) {
                if (@($visual.$field).Count -eq 0) {
                    Add-Failure "Module $key visualFidelity has no $field."
                }
                foreach ($path in @($visual.$field)) {
                    if (-not $path) { continue }
                    $resolved = Resolve-UnityMigrationPath -Root $root -Path ([string]$path)
                    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                        Add-Failure "Module $key visualFidelity references missing $field file: $path"
                    }
                }
            }
            foreach ($field in @("flowEvidence", "uiMapping")) {
                $path = [string]$visual.$field
                if (-not $path) {
                    Add-Failure "Module $key visualFidelity has no $field."
                    continue
                }
                $resolved = Resolve-UnityMigrationPath -Root $root -Path $path
                if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                    Add-Failure "Module $key visualFidelity references missing $field file: $path"
                }
            }
        }
    }
    $validationDataProperty = $module.PSObject.Properties["validationData"]
    if ($null -ne $validationDataProperty -and $null -ne $validationDataProperty.Value) {
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
        $templates = @($validationData.setupSql) +
            @((Get-UnityMigrationPropertyValue -Object $validationData -Name "setupAssertSql" -Default @())) +
            @($validationData.cleanupSql) +
            @((Get-UnityMigrationPropertyValue -Object $validationData -Name "cleanupAssertSql" -Default @()))
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

foreach ($contract in $evidenceContractEntry.Value.modules) {
    $key = [string]$contract.module
    if ($key -notin $keys) { Add-Failure "Evidence contract references unknown module: $key"; continue }
    if ($null -ne $contract.fixedAccount) {
        $adapter = [string]$contract.fixedAccount.adapter
        if ([uint32]$contract.fixedAccount.userId -eq 0 -or [uint32]$contract.fixedAccount.roleId -eq 0) {
            Add-Failure "Evidence contract $key has no fixed userId/roleId."
        }
        Test-RequiredFile $adapter | Out-Null
    }
    if ($null -ne $contract.g5) {
        $pairIds = @($contract.g5.pairs | ForEach-Object { [string]$_.id })
        if ($pairIds.Count -eq 0 -or @($pairIds | Sort-Object -Unique).Count -ne $pairIds.Count) {
            Add-Failure "Evidence contract $key has empty or duplicate G5 pair ids."
        }
        if ([int]$contract.g5.width -ne 1334 -or [int]$contract.g5.height -ne 750) {
            Add-Failure "Evidence contract $key G5 size must be 1334x750."
        }
    }
}

foreach ($scenario in $scenarioEntry.Value.scenarios) {
    if ([string]$scenario.module -notin $keys) {
        Add-Failure "Validation scenario $($scenario.key) references unknown module: $($scenario.module)"
    }
}

foreach ($record in $gateEntry.Value.modules) {
    if ([string]$record.module -notin $keys) { Add-Failure "Gate record references unknown module: $($record.module)" }
    foreach ($gate in @("G0","G1","G2","G3","G4","G5","G6")) {
        $value = [string](Get-UnityMigrationPropertyValue -Object $record.gates -Name $gate -Default "")
        if ($value -notin @("passed","pending","blocked")) {
            Add-Failure "Module $($record.module) has invalid $gate state: $value"
        }
    }
    if (-not $record.evidence -or -not (Test-Path -LiteralPath (Resolve-UnityMigrationPath -Root $root -Path ([string]$record.evidence)))) {
        Add-Failure "Module $($record.module) gate evidence document is missing: $($record.evidence)"
    }
}

$friend = @($manifest.modules | Where-Object key -eq "Friend")
if ($friend.Count -ne 1) { Add-Failure "Manifest must contain exactly one Friend module." }

$result = [ordered]@{
    success = ($failures.Count -eq 0)
    manifest = $manifestEntry.Path
    moduleCount = @($manifest.modules).Count
    scenarioCount = @($scenarioEntry.Value.scenarios).Count
    fixtureCount = @($fixtureEntry.Value.profiles).Count
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
