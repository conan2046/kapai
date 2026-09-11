[CmdletBinding()]
param(
    [Alias("Module")][string]$TargetModule = "",
    [string]$ManifestPath = "",
    [int]$StatusMaxLines = 115,
    [int]$GuideMaxLines = 360,
    [switch]$RequireLocalEvidence,
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
$moduleMatches = if ($TargetModule) {
    @($manifest.modules | Where-Object { $_.key -ieq $TargetModule })
} else { @($manifest.modules) }
if ($TargetModule -and $moduleMatches.Count -ne 1) {
    throw "Module '$TargetModule' was not found exactly once."
}
$modulesToCheck = @($moduleMatches)

function Add-Failure([string]$Message) { $failures.Add($Message) }
function Add-Warning([string]$Message) { $warnings.Add($Message) }

try { Assert-UnityMigrationWorkflowPolicy -Root $root | Out-Null }
catch { Add-Failure $_.Exception.Message }

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
$agentsPath = Test-RequiredFile "AGENTS.md"
$steamScopePath = Test-RequiredFile "docs/unityclient/STEAM_SCOPE.md"
$moduleIndexPath = Test-RequiredFile "docs/unityclient/modules/README.md"
$paymentPath = Test-RequiredFile "docs/unityclient/modules/PAYMENT.md"
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
    $statusDenominator = [int](Get-UnityMigrationPropertyValue `
        -Object (Get-UnityMigrationPropertyValue -Object $manifest -Name "steamProgressPolicy" -Default $null) `
        -Name "denominator" -Default 0)
    $functionalMatches = [regex]::Matches($status, '(?m)^\| Functional \| (`?约?\d+%|`待逐控件重审`)')
    if ($functionalMatches.Count -ne 1) {
        Add-Failure "STATUS must contain exactly one Functional percentage row; found $($functionalMatches.Count)."
    }
    $priorityLabels = @("P0 基础层", "P1 核心养成与单人功能", "P2 运营与商业化", "P3 竞技/玩家依赖", "P4 社交最后")
    $lastPriorityIndex = -1
    foreach ($label in $priorityLabels) {
        $priorityIndex = $status.IndexOf($label, [StringComparison]::Ordinal)
        if ($priorityIndex -lt 0 -or $priorityIndex -le $lastPriorityIndex) {
            Add-Failure "STATUS migration priority is missing or out of order: $label"
        }
        $lastPriorityIndex = $priorityIndex
    }
    if ($statusDenominator -le 0 -or -not $status.Contains("当前 Steam 业务模块分母固定为 $statusDenominator")) {
        Add-Failure "STATUS no longer declares the single current Steam denominator."
    }
    $prioritySectionMatch = [regex]::Match($status, '(?s)## \d+\. 总迁移顺序(?<body>.*?)## \d+\.')
    if (-not $prioritySectionMatch.Success) {
        Add-Failure "STATUS priority section cannot be isolated for duplicate-progress validation."
    }
    elseif ($prioritySectionMatch.Groups['body'].Value -match '\d+\s*/\s*\d+\s*=\s*\d+(?:\.\d+)?%') {
        Add-Failure "STATUS priority plan must not maintain a second current completion percentage."
    }
    if (-not $status.Contains("PAYMENT.md")) { Add-Failure "STATUS P2 plan no longer references the payment prerequisite." }
}

if ($paymentPath) {
    $payment = Get-Content -Raw -Encoding UTF8 -LiteralPath $paymentPath
    foreach ($anchor in @(
        "planned-prerequisite", "PROJECTX_PAYMENT_TEST", "PROJECTX_PAYMENT_PRODUCTION",
        "CPackageDeal::Charge", "CMainClass::ChongZhiSuccess", "MSG_CILENT_CHARGE /247",
        "PaymentService", "PaymentBuildGuard"
    )) {
        if (-not $payment.Contains($anchor)) { Add-Failure "Payment prerequisite is missing anchor: $anchor" }
    }
    if (-not $payment.Contains("当前仅冻结方案，未实现源码")) {
        Add-Failure "Payment prerequisite must remain explicitly planned until its source implementation is complete."
    }
}

if ($moduleIndexPath) {
    $moduleIndex = Get-Content -Raw -Encoding UTF8 -LiteralPath $moduleIndexPath
    if (-not $moduleIndex.Contains("PAYMENT.md")) { Add-Failure "Module index no longer references PAYMENT.md." }
    if (-not $moduleIndex.Contains("STEAM_SCOPE.md")) { Add-Failure "Module index no longer references STEAM_SCOPE.md." }
}

if ($steamScopePath) {
    $steamScope = Get-Content -Raw -Encoding UTF8 -LiteralPath $steamScopePath
    foreach ($excludedModule in @($manifest.modules | Where-Object {
        [bool](Get-UnityMigrationPropertyValue -Object $_ -Name "migrationExcluded" -Default $false)
    })) {
        if (-not $steamScope.Contains("``$([string]$excludedModule.key)``")) {
            Add-Failure "STEAM_SCOPE is missing excluded module: $([string]$excludedModule.key)"
        }
    }
    foreach ($requiredScopeAnchor in @("不得继续迁移", "不得进入 G0-G6", "migrationExcluded=true")) {
        if (-not $steamScope.Contains($requiredScopeAnchor)) {
            Add-Failure "STEAM_SCOPE is missing enforcement anchor: $requiredScopeAnchor"
        }
    }
}
if ($statusPath -and -not $status.Contains("STEAM_SCOPE.md")) {
    Add-Failure "STATUS no longer references STEAM_SCOPE.md."
}
if ($guidePath) {
    $guideForScope = Get-Content -Raw -Encoding UTF8 -LiteralPath $guidePath
    if (-not $guideForScope.Contains("STEAM_SCOPE.md")) { Add-Failure "MIGRATION_GUIDE no longer references STEAM_SCOPE.md." }
}

$currentDocPaths = @($statusPath, $guidePath) | Where-Object { $_ }
$moduleDocDir = Resolve-UnityMigrationPath -Root $root -Path "docs/unityclient/modules"
$currentDocPaths += if ($TargetModule) {
    @($modulesToCheck | ForEach-Object {
        Resolve-UnityMigrationPath -Root $root -Path ([string]$_.document)
    })
}
else {
    @(Get-ChildItem -LiteralPath $moduleDocDir -Filter "*.md" -File | ForEach-Object FullName)
}
foreach ($path in $currentDocPaths) {
    $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
    if ($text -match '18%') { Add-Failure "Stale 18% progress marker: $path" }
    if ($text -match 'D:\\neiwang_kapai') { Add-Failure "Stale D drive project path: $path" }
}

$keys = @($manifest.modules | ForEach-Object { [string]$_.key })
$manifestUnityExecutable = [string]$manifest.unityExecutable
if (-not [string]::IsNullOrWhiteSpace($manifestUnityExecutable)) {
    Add-Failure "Manifest unityExecutable must stay empty; configure PROJECTX_UNITY_EXECUTABLE or .local/unity-migration/settings.json per machine."
}
$projectVersionPath = Resolve-UnityMigrationPath -Root $root -Path "unityclient/ProjectSettings/ProjectVersion.txt"
if (Test-Path -LiteralPath $projectVersionPath -PathType Leaf) {
    $projectVersionText = Get-Content -LiteralPath $projectVersionPath -Raw -Encoding UTF8
    $projectVersionMatch = [regex]::Match($projectVersionText, '(?m)^m_EditorVersion:\s*(\S+)')
    if (-not $projectVersionMatch.Success) {
        Add-Failure "Unity ProjectVersion.txt does not declare m_EditorVersion."
    }
    elseif ([string]$manifest.unityVersion -ne $projectVersionMatch.Groups[1].Value) {
        Add-Failure "Manifest unityVersion '$($manifest.unityVersion)' does not match ProjectVersion '$($projectVersionMatch.Groups[1].Value)'."
    }
}
$duplicates = @($keys | Group-Object | Where-Object Count -gt 1)
foreach ($duplicate in $duplicates) { Add-Failure "Duplicate manifest module key: $($duplicate.Name)" }
$scenarioKeys = @($scenarioEntry.Value.scenarios | ForEach-Object { [string]$_.key })
foreach ($duplicate in @($scenarioKeys | Group-Object | Where-Object Count -gt 1)) {
    Add-Failure "Duplicate validation scenario key: $($duplicate.Name)"
}
$fixtureKeys = @($fixtureEntry.Value.profiles | ForEach-Object { [string]$_.key })
$completionStatuses = @(
    "migration-complete",
    "g6-complete",
    "complete",
    "g6-complete-visual-passed",
    "g0-g6-passed"
)
$completionPolicy = Get-UnityMigrationPropertyValue -Object $manifest -Name "completionPolicy" -Default $null
$userAuthorizedExceptionStatus = [string](Get-UnityMigrationPropertyValue `
    -Object $completionPolicy -Name "userAuthorizedExceptionStatus" -Default "")
$userAuthorizedExceptionCountsTowardStrictProgress = [bool](Get-UnityMigrationPropertyValue `
    -Object $completionPolicy -Name "userAuthorizedExceptionCountsTowardStrictProgress" -Default $false)
if (-not $userAuthorizedExceptionStatus) {
    Add-Failure "Manifest completionPolicy has no userAuthorizedExceptionStatus."
}

$sizeRules = @(
    [pscustomobject]@{ Name = "AGENTS"; Path = $agentsPath; Limit = 12KB },
    [pscustomobject]@{ Name = "STATUS"; Path = $statusPath; Limit = 12KB },
    [pscustomobject]@{ Name = "MIGRATION_GUIDE"; Path = $guidePath; Limit = 44KB },
    [pscustomobject]@{ Name = "MODULE_INDEX"; Path = $moduleIndexPath; Limit = 8KB }
)
foreach ($rule in $sizeRules) {
    if (-not $rule.Path) { continue }
    $size = (Get-Item -LiteralPath $rule.Path).Length
    if ($size -gt $rule.Limit) {
        Add-Failure "$($rule.Name) has $size bytes; limit is $($rule.Limit). Move dated detail to history instead of expanding the current-context document."
    }
}

if (-not $TargetModule) {
    $progressPolicy = Get-UnityMigrationPropertyValue -Object $manifest `
        -Name "steamProgressPolicy" -Default $null
    if ($null -eq $progressPolicy) {
        Add-Failure "Manifest is missing steamProgressPolicy."
    }
    else {
        $declaredDenominator = [int](Get-UnityMigrationPropertyValue -Object $progressPolicy `
            -Name "denominator" -Default 0)
        $nonDenominatorSubmodules = @((Get-UnityMigrationPropertyValue -Object $progressPolicy `
            -Name "nonDenominatorSubmodules" -Default @()) | ForEach-Object { [string]$_ })
        foreach ($submodule in $nonDenominatorSubmodules) {
            if ($submodule -notin $keys) {
                Add-Failure "Steam progress policy references unknown non-denominator submodule: $submodule"
            }
        }
        $eligibleModules = @($manifest.modules | Where-Object {
            -not [bool](Get-UnityMigrationPropertyValue -Object $_ -Name "migrationExcluded" -Default $false) -and
            [string]$_.key -notin $nonDenominatorSubmodules
        })
        if ($eligibleModules.Count -ne $declaredDenominator) {
            Add-Failure "Steam progress denominator drifted: declared=$declaredDenominator eligible=$($eligibleModules.Count)."
        }

        $completedKeys = New-Object System.Collections.Generic.List[string]
        foreach ($eligibleModule in $eligibleModules) {
            $eligibleKey = [string]$eligibleModule.key
            $eligibleGateRecords = @($gateEntry.Value.modules | Where-Object { $_.module -ieq $eligibleKey })
            if ($eligibleGateRecords.Count -ne 1) {
                Add-Failure "Steam progress module $eligibleKey has no unique gate record."
                continue
            }
            $allGatesPassed = $true
            foreach ($gate in @("G0","G1","G2","G3","G4","G5","G6")) {
                if ([string]$eligibleGateRecords[0].gates.$gate -ne "passed") {
                    $allGatesPassed = $false
                    break
                }
            }
            $eligibleStatus = [string]$eligibleModule.status
            $claimsComplete = $eligibleStatus -in $completionStatuses
            $isUserAuthorizedException = $eligibleStatus -eq $userAuthorizedExceptionStatus
            if (-not $isUserAuthorizedException -and $allGatesPassed -ne $claimsComplete) {
                Add-Failure "Steam progress module $eligibleKey status/gate drift: status=$eligibleStatus allGatesPassed=$allGatesPassed."
            }
            if ($allGatesPassed -and ($claimsComplete -or
                ($isUserAuthorizedException -and $userAuthorizedExceptionCountsTowardStrictProgress))) {
                $completedKeys.Add($eligibleKey)
            }
        }

        if ($statusPath -and $declaredDenominator -gt 0) {
            $percentage = ([double]$completedKeys.Count / [double]$declaredDenominator * 100.0).ToString(
                "0.0", [Globalization.CultureInfo]::InvariantCulture)
            $expectedProgress = "$($completedKeys.Count)/$declaredDenominator = $percentage%"
            if (-not $status.Contains($expectedProgress)) {
                Add-Failure "STATUS validated progress drifted; expected '$expectedProgress'."
            }
        }
    }
}

$runnerText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "unityclient/Assets/ProjectX/src/Editor/BootstrapAppRunner.cs")
$protocolHeader = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $root "server/src/protocol.h")
foreach ($module in $modulesToCheck) {
    $key = [string]$module.key
    $scenarios = @($scenarioEntry.Value.scenarios | Where-Object { $_.module -ieq $key })
    if ($scenarios.Count -ne 1) {
        Add-Failure "Module $key must have exactly one central validation scenario; found $($scenarios.Count)."
        $scenario = $null
    }
    else { $scenario = $scenarios[0] }
    if ($null -ne $scenario) {
        $moduleGateRecords = @($gateEntry.Value.modules | Where-Object { $_.module -ieq $key })
        if ($moduleGateRecords.Count -eq 1 -and [string]$moduleGateRecords[0].gates.G0 -eq "passed") {
            try {
                Assert-UnityMigrationModuleWorkflowContract -Root $root -ModuleConfig $module `
                    -Scenario $scenario -Phase G0 | Out-Null
            }
            catch { Add-Failure "Module $key workflow contract failed: $($_.Exception.Message)" }
        }
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
    $currentCocosReachable = [bool](Get-UnityMigrationPropertyValue -Object $module `
        -Name "currentCocosReachable" -Default $true)
    $excludedFromCurrentCocosParityDenominator = [bool](Get-UnityMigrationPropertyValue -Object $module `
        -Name "excludedFromCurrentCocosParityDenominator" -Default $false)
    $currentCocosUnreachable = -not $currentCocosReachable -and $excludedFromCurrentCocosParityDenominator
    if ($currentCocosUnreachable) {
        $exclusionEvidence = [string](Get-UnityMigrationPropertyValue -Object $module `
            -Name "exclusionEvidence" -Default "")
        if (-not $exclusionEvidence) {
            Add-Failure "Module $key excludes a current-Cocos-unreachable flow without exclusionEvidence."
        }
        elseif ($RequireLocalEvidence) {
            Test-RequiredFile $exclusionEvidence | Out-Null
        }
    }
    foreach ($flag in @($module.validationFlags)) {
        if (-not $flag) { continue }
        if ($flag -notmatch '^-projectX[A-Za-z0-9]+Validation$') {
            Add-Failure "Module $key has invalid validation flag: $flag"
        }
        elseif (-not $currentCocosUnreachable -and $runnerText -notmatch [Regex]::Escape([string]$flag)) {
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
    $moduleGateRecords = @($gateEntry.Value.modules | Where-Object { $_.module -ieq $key })
    $isUserAuthorizedException = $moduleStatus -eq $userAuthorizedExceptionStatus
    if ($isUserAuthorizedException) {
        if ($moduleGateRecords.Count -ne 1) {
            Add-Failure "Module $key claims a user-authorized G6 exception without a unique gate record."
        }
        else {
            foreach ($gate in @("G0","G1","G2","G3","G4","G5","G6")) {
                if ([string]$moduleGateRecords[0].gates.$gate -ne "passed") {
                    Add-Failure "Module $key claims a user-authorized G6 exception while $gate is '$($moduleGateRecords[0].gates.$gate)'."
                }
            }
            $exceptionEvidence = @($moduleGateRecords[0].gateEvidence.G6 | ForEach-Object { [string]$_ })
            if (@($exceptionEvidence | Where-Object { $_ -like '*-final-user-acceptance-latest.json' }).Count -ne 1) {
                Add-Failure "Module $key user-authorized G6 exception has no unique final user acceptance evidence."
            }
            if (@($exceptionEvidence | Where-Object { $_ -like '*-g6-user-authorized-retrospective-latest.json' }).Count -ne 1) {
                Add-Failure "Module $key user-authorized G6 exception has no unique disclosed retrospective evidence."
            }
        }
    }
    $controlMatrixPath = [string](Get-UnityMigrationPropertyValue -Object $module -Name "controlMatrix" -Default "")
    if ($controlMatrixPath -and $moduleGateRecords.Count -eq 1) {
        $matrixPath = Resolve-UnityMigrationPath -Root $root -Path $controlMatrixPath
        if (Test-Path -LiteralPath $matrixPath -PathType Leaf) {
            $matrix = Get-Content -Raw -Encoding UTF8 -LiteralPath $matrixPath | ConvertFrom-Json
            $matrixCompletion = Get-UnityMigrationPropertyValue -Object $matrix -Name "completion" -Default $null
            $matrixG6Audit = Get-UnityMigrationPropertyValue -Object $matrix -Name "g6Audit" -Default $null
            $matrixClaimsG6 = [string](Get-UnityMigrationPropertyValue -Object $matrixCompletion -Name "status" -Default "") -eq "complete" -or
                [string](Get-UnityMigrationPropertyValue -Object $matrixG6Audit -Name "status" -Default "") -eq "passed"
            if ($matrixClaimsG6 -and [string]$moduleGateRecords[0].gates.G6 -ne "passed") {
                Add-Failure "Module $key control matrix claims G6 completion while registry G6 is '$($moduleGateRecords[0].gates.G6)'."
            }
        }
    }
    $visualProperty = $module.PSObject.Properties["visualFidelity"]
    $visual = if ($null -ne $visualProperty) { $visualProperty.Value } else { $null }
    $visualCompleteStatus = if ($manifest.visualFidelityPolicy.completeStatus) {
        [string]$manifest.visualFidelityPolicy.completeStatus
    }
    else { "visual-1to1-complete" }
    $claimsCompletion = $moduleStatus -in $completionStatuses -or $moduleStatus -eq $visualCompleteStatus
    if (($moduleStatus -match 'visual-(pending|fixing)') -and $null -eq $visual) {
        Add-Failure "Module $key declares visual work but has no visualFidelity record."
    }
    if ($null -ne $visual) {
        $allowedVisualStates = @("pending-cocos-baseline", "visual-fixing", "passed")
        if ([string]$visual.status -notin $allowedVisualStates) {
            Add-Failure "Module $key has invalid visualFidelity status: $($visual.status)"
        }
    }
    if ($claimsCompletion) {
        $completionGateRecords = @($gateEntry.Value.modules | Where-Object { $_.module -ieq $key })
        if ($completionGateRecords.Count -ne 1) {
            Add-Failure "Module $key claims $moduleStatus without a unique gate record."
        }
        else {
            foreach ($gate in @("G0","G1","G2","G3","G4","G5","G6")) {
                $gateValue = [string](Get-UnityMigrationPropertyValue `
                    -Object $completionGateRecords[0].gates -Name $gate -Default "")
                if ($gateValue -ne "passed") {
                    Add-Failure "Module $key claims $moduleStatus while $gate is '$gateValue'."
                }
            }
        }
        $controlMatrix = [string](Get-UnityMigrationPropertyValue -Object $module -Name "controlMatrix" -Default "")
        if (-not $controlMatrix) {
            Add-Failure "Module $key claims $moduleStatus without a controlMatrix."
        }
        else {
            try {
                Assert-UnityMigrationControlMatrix -Root $root -ModuleKey $key -Path $controlMatrix `
                    -SkipEvidenceFileValidation:(-not $RequireLocalEvidence) | Out-Null
            }
            catch { Add-Failure "Module $key controlMatrix failed: $($_.Exception.Message)" }
        }
        if ($null -eq $visual -or [string]$visual.status -ne "passed") {
            Add-Failure "Module $key claims $moduleStatus without passed visualFidelity evidence."
        }
        else {
            foreach ($field in @("cocosScreenshots", "unityScreenshots", "diffReports")) {
                if (@($visual.$field).Count -eq 0) {
                    Add-Failure "Module $key visualFidelity has no $field."
                }
                foreach ($path in @($visual.$field)) {
                    if (-not $path) { continue }
                    $resolved = Resolve-UnityMigrationPath -Root $root -Path ([string]$path)
                    if ($RequireLocalEvidence -and -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
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
                $requiresFile = $field -eq "uiMapping" -or $RequireLocalEvidence
                if ($requiresFile -and -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
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

foreach ($contract in @($evidenceContractEntry.Value.modules | Where-Object {
    -not $TargetModule -or [string]$_.module -ieq $TargetModule
})) {
    $key = [string]$contract.module
    if ($key -notin $keys) { Add-Failure "Evidence contract references unknown module: $key"; continue }
    $contractModule = @($manifest.modules | Where-Object { [string]$_.key -ieq $key })[0]
    $contractMigrationExcluded = $null -ne $contractModule -and
        [bool](Get-UnityMigrationPropertyValue -Object $contractModule `
            -Name "migrationExcluded" -Default $false)
    $fixedAccount = Get-UnityMigrationPropertyValue -Object $contract -Name "fixedAccount" -Default $null
    if ($null -ne $fixedAccount -and -not $contractMigrationExcluded) {
        foreach ($contractFailure in @(Get-UnityMigrationFixedAccountContractFailures `
            -Root $root -Module $key -FixedAccount $fixedAccount)) {
            Add-Failure $contractFailure
        }
    }
    if ($null -ne $contract.g5) {
        $contractCurrentCocosUnreachable = $null -ne $contractModule -and
            -not [bool](Get-UnityMigrationPropertyValue -Object $contractModule -Name "currentCocosReachable" -Default $true) -and
            [bool](Get-UnityMigrationPropertyValue -Object $contractModule `
                -Name "excludedFromCurrentCocosParityDenominator" -Default $false)
        $pairIds = @($contract.g5.pairs | ForEach-Object { [string]$_.id })
        $supplementalPairs = @(Get-UnityMigrationPropertyValue -Object $contract.g5 `
            -Name "supplementalReferencePairs" -Default @())
        $supplementalPairIds = @($supplementalPairs | ForEach-Object { [string]$_.id })
        $allPairIds = @($pairIds + $supplementalPairIds)
        if ($contractCurrentCocosUnreachable -and $allPairIds.Count -ne 0) {
            Add-Failure "Evidence contract $key must not fabricate G5 pairs for a current-Cocos-unreachable flow."
        }
        elseif (-not $contractCurrentCocosUnreachable -and
            ($pairIds.Count -eq 0 -or @($allPairIds | Sort-Object -Unique).Count -ne $allPairIds.Count)) {
            Add-Failure "Evidence contract $key has empty or duplicate G5 pair ids."
        }
        foreach ($pair in $supplementalPairs) {
            if (-not [string]$pair.cocosPath -or -not [string]$pair.unity -or
                [string]$pair.referenceKind -ne "archived-current-unreachable" -or
                -not [string]$pair.currentUnreachableReason -or @($pair.evidence).Count -eq 0) {
                Add-Failure "Evidence contract $key has an invalid supplemental G5 reference pair."
            }
        }
        if ([int]$contract.g5.width -ne 1334 -or [int]$contract.g5.height -ne 750) {
            Add-Failure "Evidence contract $key G5 size must be 1334x750."
        }
    }
}

foreach ($scenario in @($scenarioEntry.Value.scenarios | Where-Object {
    -not $TargetModule -or [string]$_.module -ieq $TargetModule
})) {
    if ([string]$scenario.module -notin $keys) {
        Add-Failure "Validation scenario $($scenario.key) references unknown module: $($scenario.module)"
    }
}

foreach ($record in @($gateEntry.Value.modules | Where-Object {
    -not $TargetModule -or [string]$_.module -ieq $TargetModule
})) {
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

if (-not $TargetModule -or $TargetModule -ieq "Draw") {
    $drawContract = @($evidenceContractEntry.Value.modules | Where-Object { [string]$_.module -ieq "Draw" })
    $runtimeOwners = @($evidenceContractEntry.Value.modules | Where-Object {
        $null -ne (Get-UnityMigrationPropertyValue -Object $_ -Name "runtimeSnapshot" -Default $null)
    })
    if ($drawContract.Count -ne 1) {
        Add-Failure "Draw must have exactly one evidence contract."
    }
    elseif ($null -eq (Get-UnityMigrationPropertyValue -Object $drawContract[0] -Name "runtimeSnapshot" -Default $null)) {
        Add-Failure "Draw evidence contract is missing runtimeSnapshot."
    }
    if (@($runtimeOwners | Where-Object { [string]$_.module -ieq "Draw" }).Count -ne 1 -or
        @($runtimeOwners | Where-Object { [string]$_.module -ine "Draw" -and
            [string]$_.runtimeSnapshot.scenario -eq "tools/unity-migration/runtime-scenarios/draw.json" }).Count -ne 0) {
        Add-Failure "Draw runtime snapshot contract is attached to the wrong module or duplicated."
    }

    $drawMatrixPath = Test-RequiredFile "docs/unityclient/matrices/DRAW_CONTROLS.json"
    $drawScenarioPath = Test-RequiredFile "tools/unity-migration/runtime-scenarios/draw.json"
    Test-RequiredFile "tools/unity-migration/runtime-snapshot.schema.json" | Out-Null
    Test-RequiredFile "tools/unity-migration/runtime-scenarios/draw-fixture-requirements.json" | Out-Null
    Test-RequiredFile "tools/unity-migration/RuntimeSnapshot.Common.ps1" | Out-Null
    Test-RequiredFile "tools/unity-migration/Compare-UnityRuntimeSnapshots.ps1" | Out-Null
    Test-RequiredFile "tools/unity-migration/Invoke-DrawSqliteFixture.ps1" | Out-Null
    Test-RequiredFile "client/ProjectX/src/Validation/RuntimeSnapshotReplay.lua" | Out-Null
    Test-RequiredFile "unityclient/Assets/ProjectX/src/Validation/RuntimeInputDispatcher.cs" | Out-Null
    if ($drawMatrixPath -and $drawScenarioPath) {
        $drawMatrix = Get-Content -Raw -Encoding UTF8 -LiteralPath $drawMatrixPath | ConvertFrom-Json
        $drawRuntimeScenario = Get-Content -Raw -Encoding UTF8 -LiteralPath $drawScenarioPath | ConvertFrom-Json
        $matrixIds = @($drawMatrix.controls | ForEach-Object { [string]$_.id } | Sort-Object)
        $scenarioIds = @($drawRuntimeScenario.actions | ForEach-Object { [string]$_.action.targetControlId } | Sort-Object)
        $expectedFields = @("automationPassed", "engineInputReplayPassed", "realInputSamplePassed",
            "protocolSemanticPassed", "runtimeTreePassed", "visualPassed", "manualPassed")
        if ([int]$drawMatrix.hardGateVersion -ne 4) { Add-Failure "Draw hardGateVersion must be 4." }
        if ($matrixIds.Count -ne 28 -or @($matrixIds | Sort-Object -Unique).Count -ne 28) {
            Add-Failure "Draw matrix must contain 28 unique controls for runtime v4."
        }
        if ($scenarioIds.Count -ne 28 -or @($scenarioIds | Sort-Object -Unique).Count -ne 28 -or
            @((Compare-Object $matrixIds $scenarioIds)).Count -ne 0) {
            Add-Failure "Draw runtime scenario action targets must equal the 28 matrix control ids."
        }
        if (@(Compare-Object @($drawMatrix.runtimeEvidenceFields) $expectedFields).Count -ne 0) {
            Add-Failure "Draw runtimeEvidenceFields must match the seven v4 evidence flags."
        }
        if ([string]$drawMatrix.g6Audit.status -ne "runtime-v4-pending" -or
            [bool]$drawMatrix.g6Audit.manualPassed -or [int]$drawMatrix.g6Audit.cocosActionCount -ne 28 -or
            [int]$drawMatrix.g6Audit.unityActionCount -ne 28 -or
            [int]$drawMatrix.g6Audit.matchedControlCount -ne 0) {
            Add-Failure "Draw v4 pilot must retain 28 actions per engine, zero current matches and manualPassed=false while G6 remains pending."
        }
    }
    if ($drawContract.Count -eq 1) {
        if ([string]$drawContract[0].fixedAccount.dataBackend -ne "sqlite" -or
            [int]$drawContract[0].fixedAccount.userId -ne 7200057 -or
            [int]$drawContract[0].fixedAccount.roleId -ne 1000003) {
            Add-Failure "Draw fixed account contract must use SQLite identity 7200057/1000003."
        }
        if ([int]$drawContract[0].runtimeSnapshot.realInputMinimumPerEngine -ne 8 -or
            [int]$drawContract[0].runtimeSnapshot.visualStateCount -ne 9) {
            Add-Failure "Draw runtime contract must require 8 real-input samples per engine and 9 visual states."
        }
    }
}

if (-not $TargetModule) {
    $friend = @($manifest.modules | Where-Object key -eq "Friend")
    if ($friend.Count -ne 1) { Add-Failure "Manifest must contain exactly one Friend module." }
}

$result = [ordered]@{
    success = ($failures.Count -eq 0)
    manifest = $manifestEntry.Path
    scope = $(if ($TargetModule) { "module" } else { "all" })
    module = $TargetModule
    moduleCount = @($modulesToCheck).Count
    scenarioCount = @($scenarioEntry.Value.scenarios | Where-Object { -not $TargetModule -or [string]$_.module -ieq $TargetModule }).Count
    fixtureCount = @($fixtureEntry.Value.profiles).Count
    failures = @($failures)
    warnings = @($warnings)
    requireLocalEvidence = [bool]$RequireLocalEvidence
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

Write-Host "Unity migration docs passed: scope=$(if ($TargetModule) { $TargetModule } else { 'all' }), modules=$(@($modulesToCheck).Count), localEvidence=$(if ($RequireLocalEvidence) { 'required' } else { 'optional' }), no consistency failures."
exit 0
