Set-StrictMode -Version Latest

function Import-UnityRuntimeSnapshotJsonLines {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Runtime snapshot session is missing: $Path"
    }
    $records = New-Object System.Collections.Generic.List[object]
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        try { $records.Add(($line | ConvertFrom-Json)) }
        catch { throw "Runtime snapshot JSONL is invalid at ${Path}:$lineNumber - $($_.Exception.Message)" }
    }
    if ($records.Count -eq 0) { throw "Runtime snapshot session is empty: $Path" }
    return $records.ToArray()
}

function Import-UnityRuntimeSnapshotTree {
    param(
        [Parameter(Mandatory = $true)]$Action,
        [Parameter(Mandatory = $true)][ValidateSet("pre", "post")][string]$Side,
        [Parameter(Mandatory = $true)][string]$SessionPath
    )
    $inlineField = "${Side}UiTree"
    $refField = "${Side}UiTreeRef"
    $hashField = "${Side}UiTreeHash"
    $countField = "${Side}UiTreeNodeCount"
    $inline = @((Get-UnityMigrationPropertyValue -Object $Action -Name $inlineField -Default @()))
    if ($inline.Count -gt 0) { return $inline }

    $reference = [string](Get-UnityMigrationPropertyValue -Object $Action -Name $refField -Default "")
    if (-not $reference) { throw "Runtime snapshot action '$($Action.actionId)' misses $refField." }
    $sessionDirectory = [IO.Path]::GetFullPath((Split-Path -Parent $SessionPath))
    $treePath = [IO.Path]::GetFullPath((Join-Path $sessionDirectory $reference))
    $prefix = $sessionDirectory.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $treePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Runtime snapshot tree reference escapes the session directory: $reference"
    }
    if (-not (Test-Path -LiteralPath $treePath -PathType Leaf)) { throw "Runtime snapshot tree is missing: $treePath" }

    if ($treePath.EndsWith(".gz", [StringComparison]::OrdinalIgnoreCase)) {
        $file = [IO.File]::OpenRead($treePath)
        try {
            $gzip = [IO.Compression.GZipStream]::new($file, [IO.Compression.CompressionMode]::Decompress)
            try {
                $reader = [IO.StreamReader]::new($gzip, [Text.UTF8Encoding]::new($false), $true)
                try { $json = $reader.ReadToEnd() }
                finally { $reader.Dispose() }
            }
            finally { $gzip.Dispose() }
        }
        finally { $file.Dispose() }
    }
    else { $json = [IO.File]::ReadAllText($treePath, [Text.UTF8Encoding]::new($false)) }

    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $stream = [IO.MemoryStream]::new($bytes)
    try { $actualHash = (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash }
    finally { $stream.Dispose() }
    $expectedHash = [string](Get-UnityMigrationPropertyValue -Object $Action -Name $hashField -Default "")
    if ($actualHash -ne $expectedHash) { throw "Runtime snapshot tree hash mismatch: $reference" }
    try { $tree = @($json | ConvertFrom-Json) }
    catch { throw "Runtime snapshot tree JSON is invalid: $treePath - $($_.Exception.Message)" }
    $expectedCount = [int](Get-UnityMigrationPropertyValue -Object $Action -Name $countField -Default -1)
    if ($expectedCount -ne $tree.Count) { throw "Runtime snapshot tree node count mismatch: $reference expected=$expectedCount actual=$($tree.Count)" }
    return $tree
}

function Get-UnityRuntimeSnapshotActionFailures {
    param(
        [Parameter(Mandatory = $true)]$Action,
        [Parameter(Mandatory = $true)][string]$ExpectedEngine,
        [string]$ExpectedControlId = ""
    )
    $failures = New-Object System.Collections.Generic.List[string]
    $requiredText = @(
        "module", "stateId", "actionId", "controlId", "operationType", "engine",
        "timestampUtc", "preUiTreeHash", "targetNodePath", "targetSemanticId",
        "postUiTreeHash", "inputFingerprint"
    )
    foreach ($field in $requiredText) {
        if (-not [string](Get-UnityMigrationPropertyValue -Object $Action -Name $field -Default "")) {
            $failures.Add("action misses $field")
        }
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Action -Name "recordType" -Default "") -ne "action") {
        $failures.Add("recordType must be action")
    }
    if ([int](Get-UnityMigrationPropertyValue -Object $Action -Name "sequence" -Default 0) -lt 1) { $failures.Add("sequence must be positive") }
    if ([string](Get-UnityMigrationPropertyValue -Object $Action -Name "inputFingerprint" -Default "") -notmatch '^[A-Fa-f0-9]{64}$') { $failures.Add("inputFingerprint must be SHA256") }
    if ($null -eq $Action.PSObject.Properties["visualStateId"]) { $failures.Add("visualStateId is missing") }
    if ([string](Get-UnityMigrationPropertyValue -Object $Action -Name "engine" -Default "") -ne $ExpectedEngine) {
        $failures.Add("engine must be $ExpectedEngine")
    }
    if ($ExpectedControlId -and [string]$Action.controlId -ne $ExpectedControlId) {
        $failures.Add("controlId mismatch expected=$ExpectedControlId actual=$($Action.controlId)")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Action -Name "inputMode" -Default "") -ne "engine-input-replay") {
        $failures.Add("inputMode must be engine-input-replay")
    }
    if (-not [bool](Get-UnityMigrationPropertyValue -Object $Action -Name "engineEventDispatched" -Default $false)) {
        $failures.Add("engine event dispatch was bypassed")
    }
    $hitTest = Get-UnityMigrationPropertyValue -Object $Action -Name "hitTest" -Default $null
    $hits = @((Get-UnityMigrationPropertyValue -Object $hitTest -Name "hits" -Default @()))
    $firstHit = [string](Get-UnityMigrationPropertyValue -Object $hitTest -Name "firstHit" -Default "")
    if ($hits.Count -eq 0) { $failures.Add("hit test has no results") }
    if (-not $firstHit) { $failures.Add("hit test has no first hit") }
    if ($firstHit -and $firstHit -ne [string]$Action.targetSemanticId -and
        $firstHit -ne [string]$Action.targetNodePath) {
        $failures.Add("first hit does not match the target")
    }
    $coordinates = Get-UnityMigrationPropertyValue -Object $Action -Name "inputCoordinates" -Default $null
    if ($null -eq $coordinates -or
        $null -eq $coordinates.PSObject.Properties["x"] -or
        $null -eq $coordinates.PSObject.Properties["y"]) {
        $failures.Add("input coordinates are missing")
    }
    elseif ([string](Get-UnityMigrationPropertyValue -Object $coordinates -Name "coordinateSpace" -Default "") -ne "1334x750-top-left") {
        $failures.Add("input coordinates are not canonical 1334x750 top-left")
    }
    $protocol = Get-UnityMigrationPropertyValue -Object $Action -Name "protocol" -Default $null
    foreach ($direction in @("sent", "received")) {
        foreach ($packet in @((Get-UnityMigrationPropertyValue -Object $protocol -Name $direction -Default @()))) {
            if ([int](Get-UnityMigrationPropertyValue -Object $packet -Name "command" -Default 0) -le 0) {
                $failures.Add("$direction protocol command is invalid")
            }
            if ([int](Get-UnityMigrationPropertyValue -Object $packet -Name "length" -Default -1) -lt 0) {
                $failures.Add("$direction protocol length is invalid")
            }
            if ([string](Get-UnityMigrationPropertyValue -Object $packet -Name "rawPacketHash" -Default "") -notmatch '^[A-Fa-f0-9]{64}$') {
                $failures.Add("$direction protocol rawPacketHash is missing or invalid")
            }
            if ($null -eq $packet.PSObject.Properties["decodedFields"]) {
                $failures.Add("$direction protocol decodedFields are missing")
            }
        }
    }
    if ($null -eq $Action.PSObject.Properties["changedNodes"]) { $failures.Add("changedNodes are missing") }
    foreach ($side in @("pre", "post")) {
        $tree = @((Get-UnityMigrationPropertyValue -Object $Action -Name "${side}UiTree" -Default @()))
        $treeRef = [string](Get-UnityMigrationPropertyValue -Object $Action -Name "${side}UiTreeRef" -Default "")
        $treeCount = [int](Get-UnityMigrationPropertyValue -Object $Action -Name "${side}UiTreeNodeCount" -Default $tree.Count)
        if ($treeCount -le 0) { $failures.Add("${side}UiTreeNodeCount must be positive") }
        if ($tree.Count -eq 0 -and -not $treeRef) { $failures.Add("${side} UI tree has neither inline data nor a content-addressed reference") }
    }
    $animation = Get-UnityMigrationPropertyValue -Object $Action -Name "animation" -Default $null
    foreach ($field in @("started", "ended", "durationMs", "cleanupPassed")) {
        if ($null -eq $animation -or $null -eq $animation.PSObject.Properties[$field]) {
            $failures.Add("animation.$field is missing")
        }
    }
    if ($null -ne $animation -and -not [bool](Get-UnityMigrationPropertyValue -Object $animation -Name "cleanupPassed" -Default $false)) {
        $failures.Add("animation.cleanupPassed is not passed")
    }
    $stable = Get-UnityMigrationPropertyValue -Object $Action -Name "stableState" -Default $null
    if ($null -eq $stable -or [string](Get-UnityMigrationPropertyValue -Object $stable -Name "outcome" -Default "") -notin @("stable", "business-error")) {
        $failures.Add("stableState does not contain a completed stable or business-error outcome")
    }
    $identity = Get-UnityMigrationPropertyValue -Object $Action -Name "identity" -Default $null
    if ($null -eq $identity -or [uint64](Get-UnityMigrationPropertyValue -Object $identity -Name "userId" -Default 0) -eq 0 -or [uint64](Get-UnityMigrationPropertyValue -Object $identity -Name "roleId" -Default 0) -eq 0) {
        $failures.Add("identity userId/roleId is missing")
    }
    $resolution = Get-UnityMigrationPropertyValue -Object $Action -Name "resolution" -Default $null
    if ($null -eq $resolution -or [int](Get-UnityMigrationPropertyValue -Object $resolution -Name "width" -Default 0) -ne 1334 -or [int](Get-UnityMigrationPropertyValue -Object $resolution -Name "height" -Default 0) -ne 750) {
        $failures.Add("resolution must be 1334x750")
    }
    foreach ($field in @("automationPassed", "engineInputReplayPassed", "protocolSemanticPassed", "runtimeTreePassed")) {
        if (-not [bool](Get-UnityMigrationPropertyValue -Object $Action -Name $field -Default $false)) {
            $failures.Add("$field is not passed")
        }
    }
    return $failures.ToArray()
}

function Get-UnityRuntimeSnapshotGateFailures {
    param(
        [Parameter(Mandatory = $true)]$Matrix,
        [Parameter(Mandatory = $true)]$Summary,
        [switch]$RequireManualPassed
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ([int](Get-UnityMigrationPropertyValue -Object $Matrix -Name "hardGateVersion" -Default 0) -ne 4) {
        $failures.Add("matrix hardGateVersion must be 4")
    }
    if ([int](Get-UnityMigrationPropertyValue -Object $Summary -Name "schemaVersion" -Default 0) -ne 1) {
        $failures.Add("runtime summary schemaVersion must be 1")
    }
    if ([string]$Summary.module -ine [string]$Matrix.module) { $failures.Add("runtime summary module mismatch") }
    $expectedIds = @($Matrix.controls | ForEach-Object { [string]$_.id })
    $actionRows = @((Get-UnityMigrationPropertyValue -Object $Summary -Name "actions" -Default @()))
    foreach ($engine in @("cocos", "unity")) {
        $engineRows = @($actionRows | Where-Object { [string]$_.engine -eq $engine })
        if (@($engineRows | ForEach-Object { [string]$_.actionId } | Sort-Object -Unique).Count -ne $engineRows.Count) {
            $failures.Add("$engine runtime actionId values must be unique")
        }
        $actualIds = @($engineRows | ForEach-Object { [string]$_.controlId })
        [object[]]$sortedExpectedIds = @($expectedIds | Sort-Object)
        [object[]]$sortedActualIds = @($actualIds | Sort-Object)
        $coverageMatches = $sortedExpectedIds.Count -eq $sortedActualIds.Count -and
            ($sortedExpectedIds -join "`n") -ceq ($sortedActualIds -join "`n")
        if ($engineRows.Count -ne $expectedIds.Count -or -not $coverageMatches) {
            $failures.Add("$engine action coverage mismatch expected=$($expectedIds.Count) actual=$($engineRows.Count)")
        }
        foreach ($row in $engineRows) {
            foreach ($failure in @(Get-UnityRuntimeSnapshotActionFailures -Action $row -ExpectedEngine $engine)) {
                $failures.Add("$engine/$($row.controlId): $failure")
            }
        }
    }
    $counts = Get-UnityMigrationPropertyValue -Object $Summary -Name "counts" -Default $null
    foreach ($field in @("automationPassed", "engineInputReplayPassed", "protocolSemanticPassed", "runtimeTreePassed")) {
        if ([int](Get-UnityMigrationPropertyValue -Object $counts -Name $field -Default -1) -ne $expectedIds.Count * 2) {
            $failures.Add("summary counts.$field must equal $($expectedIds.Count * 2)")
        }
    }
    $comparison = Get-UnityMigrationPropertyValue -Object $Summary -Name "comparison" -Default $null
    if (-not [bool](Get-UnityMigrationPropertyValue -Object $comparison -Name "passed" -Default $false)) {
        $failures.Add("dual-engine semantic comparison is not passed")
    }
    if ([int](Get-UnityMigrationPropertyValue -Object $comparison -Name "matchedControls" -Default -1) -ne $expectedIds.Count) {
        $failures.Add("dual-engine matchedControls must equal $($expectedIds.Count)")
    }
    $realInput = Get-UnityMigrationPropertyValue -Object $Summary -Name "realInputSample" -Default $null
    $realByEngine = Get-UnityMigrationPropertyValue -Object $realInput -Name "byEngine" -Default $null
    if (-not [bool](Get-UnityMigrationPropertyValue -Object $realInput -Name "passed" -Default $false) -or
        [int](Get-UnityMigrationPropertyValue -Object $realByEngine -Name "cocos" -Default 0) -lt 8 -or
        [int](Get-UnityMigrationPropertyValue -Object $realByEngine -Name "unity" -Default 0) -lt 8) {
        $failures.Add("representative real-input sample must pass at least 8 operations per engine")
    }
    $visual = Get-UnityMigrationPropertyValue -Object $Summary -Name "visual" -Default $null
    if (-not [bool](Get-UnityMigrationPropertyValue -Object $visual -Name "passed" -Default $false) -or
        [int](Get-UnityMigrationPropertyValue -Object $visual -Name "passedStateCount" -Default 0) -ne 9 -or
        [int](Get-UnityMigrationPropertyValue -Object $visual -Name "requiredStateCount" -Default 0) -ne 9) {
        $failures.Add("visual state coverage must be 9/9")
    }
    $fixture = Get-UnityMigrationPropertyValue -Object $Summary -Name "fixture" -Default $null
    if ([int](Get-UnityMigrationPropertyValue -Object $fixture -Name "residualCount" -Default -1) -ne 0 -or
        [string](Get-UnityMigrationPropertyValue -Object $fixture -Name "databaseIntegrity" -Default "") -ne "ok" -or
        -not [bool](Get-UnityMigrationPropertyValue -Object $fixture -Name "restored" -Default $false) -or
        -not [bool](Get-UnityMigrationPropertyValue -Object $fixture -Name "reloginVerified" -Default $false)) {
        $failures.Add("fixture restore, relogin, integrity or zero-residual contract failed")
    }
    $audit = Get-UnityMigrationPropertyValue -Object $Matrix -Name "g6Audit" -Default $null
    $fingerprints = Get-UnityMigrationPropertyValue -Object $Summary -Name "fingerprints" -Default $null
    foreach ($field in @("productInputFingerprint", "probeToolFingerprint")) {
        $expected = [string](Get-UnityMigrationPropertyValue -Object $audit -Name $field -Default "")
        $actual = [string](Get-UnityMigrationPropertyValue -Object $fingerprints -Name $field -Default "")
        if (-not $expected -or $expected -notmatch '^[A-Fa-f0-9]{64}$' -or $actual -ne $expected) {
            $failures.Add("$field is missing or stale")
        }
    }
    if ([bool](Get-UnityMigrationPropertyValue -Object $Summary -Name "simulation" -Default $false)) {
        $failures.Add("simulated runtime evidence cannot pass hard gate v4")
    }
    if ($RequireManualPassed -and -not [bool](Get-UnityMigrationPropertyValue -Object $Summary -Name "manualPassed" -Default $false)) {
        $failures.Add("final user Play manualPassed is not current")
    }
    return $failures.ToArray()
}

function Assert-UnityMigrationRuntimeSnapshotGate {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Matrix,
        [switch]$RequireManualPassed
    )
    $audit = Get-UnityMigrationPropertyValue -Object $Matrix -Name "g6Audit" -Default $null
    $summaryPath = [string](Get-UnityMigrationPropertyValue -Object $audit -Name "runtimeSnapshotSummary" -Default "")
    if (-not $summaryPath) { throw "Hard-gate v4 matrix has no runtimeSnapshotSummary." }
    $summary = (Import-UnityMigrationJson -Root $Root -Path $summaryPath).Value
    $failures = @(Get-UnityRuntimeSnapshotGateFailures -Matrix $Matrix -Summary $summary -RequireManualPassed:$RequireManualPassed)
    if ($failures.Count -gt 0) { throw "Hard-gate v4 runtime snapshot failed: $($failures -join '; ')" }
    return $summary
}

function Get-UnityRuntimeSnapshotFileFingerprint {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][object[]]$Paths
    )
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($path in @($Paths | ForEach-Object { [string]$_ } | Sort-Object -Unique)) {
        $resolved = Resolve-UnityMigrationPath -Root $Root -Path $path
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "Fingerprint input is missing: $path" }
        $lines.Add("$path=$((Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash)")
    }
    if ($lines.Count -eq 0) { throw "Runtime snapshot fingerprint input list is empty." }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash }
    finally { $stream.Dispose() }
}
