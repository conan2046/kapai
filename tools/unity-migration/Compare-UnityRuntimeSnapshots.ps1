[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [string]$ScenarioPath = "",
    [string]$CocosSessionPath = "",
    [string]$UnitySessionPath = "",
    [string]$OutputDirectory = "",
    [string[]]$ProductInputs = @(),
    [string[]]$ProbeToolInputs = @(),
    [string]$FixtureEvidencePath = "",
    [switch]$StaticTrial
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$moduleName = $Module.Trim()
if (-not $moduleName) { throw "Module cannot be empty." }
if (-not $ScenarioPath) { $ScenarioPath = "tools/unity-migration/runtime-scenarios/$($moduleName.ToLowerInvariant()).json" }
$scenario = (Import-UnityMigrationJson -Root $root -Path $ScenarioPath).Value
if ([string]$scenario.module -ine $moduleName) { throw "Runtime scenario module mismatch: $ScenarioPath" }
$actions = @($scenario.actions)
if ($actions.Count -eq 0) { throw "Runtime scenario has no actions: $ScenarioPath" }
$actionIds = @($actions | ForEach-Object { [string]$_.actionId })
$controlIds = @($actions | ForEach-Object { [string]$_.action.targetControlId })
if (@($actionIds | Sort-Object -Unique).Count -ne $actions.Count) { throw "Runtime scenario actionId values must be unique." }
if (@($controlIds | Sort-Object -Unique).Count -ne $actions.Count) { throw "Runtime scenario targetControlId values must be unique." }
foreach ($action in $actions) {
    foreach ($field in @("precondition", "startState", "action", "expectedHit", "expectedProtocols", "expectedVisible", "expectedHidden", "expectedState", "timeout", "cleanup", "visualStateId", "volatileFields", "toleranceProfile")) {
        if ($null -eq $action.PSObject.Properties[$field]) { throw "Scenario action '$($action.actionId)' misses $field." }
    }
    if ([string]$action.action.type -notin @("open", "click", "pointerDown/pointerUp", "drag", "scroll", "textInput", "close", "back", "reconnect", "relogin", "accountSwitch")) {
        throw "Scenario action '$($action.actionId)' has unsupported operation type '$($action.action.type)'."
    }
}

if (-not $OutputDirectory) {
    $runId = [DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ")
    $OutputDirectory = ".local/unity-validation/runtime-snapshots/$moduleName/$runId"
}
$resolvedOutput = Resolve-UnityMigrationPath -Root $root -Path $OutputDirectory
[IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null

function ConvertTo-NormalizedPacket {
    param($Packet)
    return [ordered]@{
        command = [int]$Packet.command
        op = if ($null -eq $Packet.op) { $null } else { [int]$Packet.op }
        decodedFields = $Packet.decodedFields
        length = [int]$Packet.length
        rawPacketHash = ([string]$Packet.rawPacketHash).ToUpperInvariant()
    }
}

function ConvertTo-NormalizedNode {
    param($Node)
    $round = { param($value) if ($null -eq $value) { $null } else { [Math]::Round([double]$value, 3) } }
    $rect = Get-UnityMigrationPropertyValue -Object $Node -Name "screenRect" -Default $null
    $value = { param([string]$name, $default = $null) Get-UnityMigrationPropertyValue -Object $Node -Name $name -Default $default }
    return [ordered]@{
        matchKey = "{0}|{1}|{2}|{3}" -f [string](& $value "controlId"), [string](& $value "semanticId"), [string](& $value "dataId"), [string](& $value "dataIndex")
        nodeType = [string](& $value "nodeType" "")
        effectiveVisible = [bool](& $value "effectiveVisible" $false)
        enabled = [bool](& $value "enabled" $true)
        interactable = [bool](& $value "interactable" $true)
        raycast = [bool](& $value "raycast" $false)
        x = if ($null -eq $rect) { $null } else { & $round $rect.x }
        y = if ($null -eq $rect) { $null } else { & $round $rect.y }
        width = if ($null -eq $rect) { $null } else { & $round $rect.width }
        height = if ($null -eq $rect) { $null } else { & $round $rect.height }
        text = [string](& $value "text" "")
        resource = [string](& $value "resource" "")
        source = [string](& $value "source" "")
        animationResource = [string](& $value "animationResource" "")
        animationAction = [string](& $value "animationAction" "")
        toggle = Get-UnityMigrationPropertyValue -Object $Node -Name "toggle" -Default $null
        inputValue = [string](Get-UnityMigrationPropertyValue -Object $Node -Name "inputValue" -Default "")
    }
}

function ConvertTo-NormalizedAction {
    param($Action, [string]$SessionPath)
    $value = { param([string]$name, $default = $null) Get-UnityMigrationPropertyValue -Object $Action -Name $name -Default $default }
    $hitTest = & $value "hitTest" $null
    $protocol = & $value "protocol" $null
    $stableState = & $value "stableState" $null
    return [ordered]@{
        controlId = [string](& $value "controlId" "")
        operationType = [string](& $value "operationType" "")
        targetSemanticId = [string](& $value "targetSemanticId" "")
        firstHit = [string](Get-UnityMigrationPropertyValue -Object $hitTest -Name "firstHit" -Default "")
        sent = @(Get-UnityMigrationPropertyValue -Object $protocol -Name "sent" -Default @() | ForEach-Object { ConvertTo-NormalizedPacket $_ })
        received = @(Get-UnityMigrationPropertyValue -Object $protocol -Name "received" -Default @() | ForEach-Object { ConvertTo-NormalizedPacket $_ })
        protocolErrors = @(Get-UnityMigrationPropertyValue -Object $protocol -Name "errors" -Default @())
        timedOut = [bool](Get-UnityMigrationPropertyValue -Object $protocol -Name "timedOut" -Default $false)
        disconnected = [bool](Get-UnityMigrationPropertyValue -Object $protocol -Name "disconnected" -Default $false)
        stableOutcome = [string](Get-UnityMigrationPropertyValue -Object $stableState -Name "outcome" -Default "")
        nodes = @(Import-UnityRuntimeSnapshotTree -Action $Action -Side post -SessionPath $SessionPath | ForEach-Object { ConvertTo-NormalizedNode $_ } | Sort-Object matchKey)
        visualStateId = [string](& $value "visualStateId" "")
    }
}

function ConvertTo-GateActionSummary {
    param($Action)
    $fields = @(
        "schemaVersion", "recordType", "module", "stateId", "actionId", "controlId", "sequence",
        "timestampUtc", "engine", "operationType", "inputMode", "inputCoordinates", "preUiTreeHash",
        "targetNodePath", "targetSemanticId", "hitTest", "engineEventDispatched", "protocol",
        "changedNodes", "postUiTreeHash", "stableState", "animation", "visualStateId", "identity",
        "resolution", "inputFingerprint", "automationPassed", "engineInputReplayPassed",
        "protocolSemanticPassed", "runtimeTreePassed", "preUiTreeRef", "postUiTreeRef",
        "preUiTreeNodeCount", "postUiTreeNodeCount"
    )
    $summary = [ordered]@{}
    foreach ($field in $fields) {
        $summary[$field] = Get-UnityMigrationPropertyValue -Object $Action -Name $field -Default $null
    }
    $summary["uiTreeNodeCounts"] = [ordered]@{
        pre = [int](Get-UnityMigrationPropertyValue -Object $Action -Name "preUiTreeNodeCount" -Default @((Get-UnityMigrationPropertyValue -Object $Action -Name "preUiTree" -Default @())).Count)
        post = [int](Get-UnityMigrationPropertyValue -Object $Action -Name "postUiTreeNodeCount" -Default @((Get-UnityMigrationPropertyValue -Object $Action -Name "postUiTree" -Default @())).Count)
    }
    return [pscustomobject]$summary
}

$failures = New-Object System.Collections.Generic.List[object]
$cocosRows = @()
$unityRows = @()
if ($StaticTrial) {
    foreach ($action in $actions) {
        foreach ($engine in @("cocos", "unity")) {
            $failures.Add([pscustomobject][ordered]@{ actionId = [string]$action.actionId; controlId = [string]$action.action.targetControlId; engine = $engine; category = "missing-session"; difference = "Static trial does not create runtime evidence." })
        }
    }
}
else {
    if (-not $CocosSessionPath -or -not $UnitySessionPath) { throw "CocosSessionPath and UnitySessionPath are required outside StaticTrial." }
    $resolvedCocosSession = Resolve-UnityMigrationPath -Root $root -Path $CocosSessionPath
    $resolvedUnitySession = Resolve-UnityMigrationPath -Root $root -Path $UnitySessionPath
    $cocosRows = @(Import-UnityRuntimeSnapshotJsonLines -Path $resolvedCocosSession)
    $unityRows = @(Import-UnityRuntimeSnapshotJsonLines -Path $resolvedUnitySession)
    foreach ($definition in $actions) {
        $controlId = [string]$definition.action.targetControlId
        foreach ($engine in @("cocos", "unity")) {
            $source = if ($engine -eq "cocos") { $cocosRows } else { $unityRows }
            $rows = @($source | Where-Object { [string]$_.actionId -eq [string]$definition.actionId -and [string]$_.controlId -eq $controlId })
            if ($rows.Count -ne 1) {
                $failures.Add([pscustomobject][ordered]@{ actionId = [string]$definition.actionId; controlId = $controlId; engine = $engine; category = "coverage"; difference = "Expected one record, found $($rows.Count)." })
                continue
            }
            foreach ($problem in @(Get-UnityRuntimeSnapshotActionFailures -Action $rows[0] -ExpectedEngine $engine -ExpectedControlId $controlId)) {
                $failures.Add([pscustomobject][ordered]@{ actionId = [string]$definition.actionId; controlId = $controlId; engine = $engine; category = "schema-or-gate"; difference = $problem })
            }
            $sessionPath = if ($engine -eq "cocos") { $resolvedCocosSession } else { $resolvedUnitySession }
            foreach ($side in @("pre", "post")) {
                try { [void]@(Import-UnityRuntimeSnapshotTree -Action $rows[0] -Side $side -SessionPath $sessionPath) }
                catch { $failures.Add([pscustomobject][ordered]@{ actionId = [string]$definition.actionId; controlId = $controlId; engine = $engine; category = "tree-storage"; difference = $_.Exception.Message }) }
            }
            if ([string]$rows[0].targetSemanticId -ne [string]$definition.expectedHit) {
                $failures.Add([pscustomobject][ordered]@{ actionId = [string]$definition.actionId; controlId = $controlId; engine = $engine; category = "hit-contract"; difference = "targetSemanticId does not match expectedHit." })
            }
        }
        $c = @($cocosRows | Where-Object { [string]$_.actionId -eq [string]$definition.actionId -and [string]$_.controlId -eq $controlId })
        $u = @($unityRows | Where-Object { [string]$_.actionId -eq [string]$definition.actionId -and [string]$_.controlId -eq $controlId })
        if ($c.Count -eq 1 -and $u.Count -eq 1) {
            $cJson = (ConvertTo-NormalizedAction $c[0] $resolvedCocosSession | ConvertTo-Json -Depth 30 -Compress)
            $uJson = (ConvertTo-NormalizedAction $u[0] $resolvedUnitySession | ConvertTo-Json -Depth 30 -Compress)
            if ($cJson -ne $uJson) {
                $failures.Add([pscustomobject][ordered]@{ actionId = [string]$definition.actionId; controlId = $controlId; engine = "compare"; category = "semantic-difference"; difference = "Normalized operation, protocol, stable state, or UI tree differs." })
            }
        }
    }
}

$allRows = @($cocosRows) + @($unityRows)
$matchedControls = @($actions | Where-Object {
    $id = [string]$_.action.targetControlId
    @($failures | Where-Object { [string]$_.controlId -eq $id }).Count -eq 0
}).Count
$productFingerprint = if ($ProductInputs.Count -gt 0) { Get-UnityRuntimeSnapshotFileFingerprint -Root $root -Paths $ProductInputs } else { "" }
$probeFingerprint = if ($ProbeToolInputs.Count -gt 0) { Get-UnityRuntimeSnapshotFileFingerprint -Root $root -Paths $ProbeToolInputs } else { "" }
$fixtureSummary = [pscustomobject][ordered]@{ restored = $false; reloginVerified = $false; databaseIntegrity = "unknown"; residualCount = -1; evidence = "" }
if ($FixtureEvidencePath) {
    $fixtureEvidence = (Import-UnityMigrationJson -Root $root -Path $FixtureEvidencePath).Value
    $fixtureSummary = [pscustomobject][ordered]@{
        restored = [bool](Get-UnityMigrationPropertyValue -Object $fixtureEvidence -Name "restored" -Default $false)
        reloginVerified = [bool](Get-UnityMigrationPropertyValue -Object $fixtureEvidence -Name "reloginVerified" -Default $false)
        databaseIntegrity = [string](Get-UnityMigrationPropertyValue -Object $fixtureEvidence -Name "databaseIntegrity" -Default "unknown")
        residualCount = [int](Get-UnityMigrationPropertyValue -Object $fixtureEvidence -Name "residualCount" -Default -1)
        evidence = $FixtureEvidencePath
    }
}
$summary = [pscustomobject][ordered]@{
    schemaVersion = 1
    module = $moduleName
    generatedUtc = [DateTime]::UtcNow.ToString("O")
    simulation = [bool]$StaticTrial
    # Complete trees stay in the source JSONL. The gate summary keeps only the
    # evidence contract and counts so it remains reviewable and well below 20 MB.
    actions = @($allRows | ForEach-Object { ConvertTo-GateActionSummary $_ })
    counts = [pscustomobject][ordered]@{
        expectedPerEngine = $actions.Count
        cocos = $cocosRows.Count
        unity = $unityRows.Count
        automationPassed = @($allRows | Where-Object automationPassed).Count
        engineInputReplayPassed = @($allRows | Where-Object engineInputReplayPassed).Count
        protocolSemanticPassed = @($allRows | Where-Object protocolSemanticPassed).Count
        runtimeTreePassed = @($allRows | Where-Object runtimeTreePassed).Count
        failed = $failures.Count
        missing = @($failures | Where-Object category -in @("missing-session", "coverage")).Count
    }
    comparison = [pscustomobject][ordered]@{ passed = (-not $StaticTrial -and $failures.Count -eq 0 -and $matchedControls -eq $actions.Count); matchedControls = $matchedControls }
    realInputSample = [pscustomobject][ordered]@{ passed = $false; sampleCount = 0; byEngine = [pscustomobject]@{ cocos = 0; unity = 0 }; evidence = @() }
    visual = [pscustomobject][ordered]@{ passed = $false; passedStateCount = 0; requiredStateCount = 9; report = "" }
    fixture = $fixtureSummary
    fingerprints = [pscustomobject][ordered]@{ productInputFingerprint = $productFingerprint; probeToolFingerprint = $probeFingerprint }
    manualPassed = $false
}
$report = [pscustomobject][ordered]@{
    schemaVersion = 1; module = $moduleName; generatedUtc = $summary.generatedUtc
    actionCount = $actions.Count; matchedControls = $matchedControls; failedCount = $failures.Count
    differences = $failures.ToArray()
}
$fingerprints = [pscustomobject][ordered]@{
    schemaVersion = 1; module = $moduleName; generatedUtc = $summary.generatedUtc
    productInputFingerprint = $productFingerprint; probeToolFingerprint = $probeFingerprint
    productInputs = @($ProductInputs); probeToolInputs = @($ProbeToolInputs)
}
Write-UnityMigrationUtf8 -Path (Join-Path $resolvedOutput "compare-report.json") -Content (($report | ConvertTo-Json -Depth 30) + "`n")
Write-UnityMigrationUtf8 -Path (Join-Path $resolvedOutput "failures.json") -Content (($failures.ToArray() | ConvertTo-Json -Depth 20) + "`n")
Write-UnityMigrationUtf8 -Path (Join-Path $resolvedOutput "summary.json") -Content (($summary | ConvertTo-Json -Depth 40) + "`n")
Write-UnityMigrationUtf8 -Path (Join-Path $resolvedOutput "current-input-fingerprint.json") -Content (($fingerprints | ConvertTo-Json -Depth 10) + "`n")
Write-Host "Runtime snapshot: actions=$($actions.Count) cocos=$($cocosRows.Count) unity=$($unityRows.Count) matched=$matchedControls failures=$($failures.Count)"
Write-Host "Evidence: $resolvedOutput"
if (-not $StaticTrial -and $failures.Count -gt 0) { exit 1 }
