Set-StrictMode -Version Latest

function Get-UnityMigrationRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
}

function Resolve-UnityMigrationPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $Root $Path))
}

function Import-UnityMigrationManifest {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$ManifestPath = ""
    )
    if (-not $ManifestPath) {
        $ManifestPath = Join-Path $PSScriptRoot "unityclient-modules.json"
    }
    $resolved = Resolve-UnityMigrationPath -Root $Root -Path $ManifestPath
    if (-not (Test-Path -LiteralPath $resolved)) {
        throw "Unity migration manifest not found: $resolved"
    }
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolved | ConvertFrom-Json
    if ([int]$manifest.schemaVersion -notin @(1, 2) -or $null -eq $manifest.modules) {
        throw "Unsupported or invalid Unity migration manifest: $resolved"
    }
    return [pscustomobject]@{ Path = $resolved; Value = $manifest }
}

function Write-UnityMigrationUtf8 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
    )
    $parent = Split-Path -Parent $Path
    if ($parent) {
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Import-UnityMigrationJson {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $resolved = Resolve-UnityMigrationPath -Root $Root -Path $Path
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "Unity migration registry not found: $resolved"
    }
    return [pscustomobject]@{
        Path = $resolved
        Value = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolved | ConvertFrom-Json
    }
}

function Get-UnityMigrationPropertyValue {
    param($Object, [Parameter(Mandatory = $true)][string]$Name, $Default = $null)
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Get-UnityMigrationScenario {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ModuleKey,
        [string]$RegistryPath = "tools/unity-migration/validation-scenarios.json"
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $RegistryPath
    $matches = @($entry.Value.scenarios | Where-Object { $_.module -ieq $ModuleKey })
    if ($matches.Count -gt 1) { throw "Module '$ModuleKey' has multiple validation scenarios." }
    return $(if ($matches.Count -eq 1) { $matches[0] } else { $null })
}

function Get-UnityMigrationArtifactPath {
    param($Artifact)
    if ($Artifact -is [string]) { return [string]$Artifact }
    return [string](Get-UnityMigrationPropertyValue -Object $Artifact -Name "path" -Default "")
}

function Assert-UnityMigrationRuntimeArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Artifact,
        [string[]]$ImmutableRoots = @(".local/ui-fidelity")
    )
    $path = Get-UnityMigrationArtifactPath -Artifact $Artifact
    if (-not $path) { throw "Validation artifact has no path." }
    $lifecycle = [string](Get-UnityMigrationPropertyValue -Object $Artifact -Name "lifecycle" -Default "runtime")
    if ($lifecycle -ne "runtime") { throw "Refusing to mutate non-runtime artifact: $path (lifecycle=$lifecycle)" }
    $resolved = Resolve-UnityMigrationPath -Root $Root -Path $path
    foreach ($immutableRoot in $ImmutableRoots) {
        $immutable = (Resolve-UnityMigrationPath -Root $Root -Path $immutableRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if ($resolved.StartsWith($immutable, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Runtime artifact points inside immutable evidence root: $path"
        }
    }
    return $resolved
}

function Get-UnityMigrationGateState {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ModuleKey,
        [string]$RegistryPath = "tools/unity-migration/migration-gates.json"
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $RegistryPath
    return @($entry.Value.modules | Where-Object { $_.module -ieq $ModuleKey } | Select-Object -First 1)
}

function Assert-UnityMigrationGatePrerequisite {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ModuleKey,
        [Parameter(Mandatory = $true)][ValidatePattern('^G[0-6]$')][string]$RequiredGate
    )
    $states = @(Get-UnityMigrationGateState -Root $Root -ModuleKey $ModuleKey)
    if ($states.Count -eq 0) { throw "Module '$ModuleKey' has no machine-readable G0-G6 state." }
    $requiredNumber = [int]$RequiredGate.Substring(1)
    foreach ($number in 0..$requiredNumber) {
        $gate = "G$number"
        $value = [string](Get-UnityMigrationPropertyValue -Object $states[0].gates -Name $gate -Default "pending")
        if ($value -ne "passed") { throw "Module '$ModuleKey' cannot run: prerequisite $gate is '$value'." }
    }
}

function Assert-UnityMigrationControlMatrix {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ModuleKey,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $matrix = $entry.Value
    if ([int]$matrix.schemaVersion -ne 1 -or [string]$matrix.module -ine $ModuleKey) {
        throw "Invalid control matrix identity: $Path"
    }
    $controls = @($matrix.controls)
    if ($controls.Count -eq 0) { throw "Control matrix has no controls: $Path" }
    $required = @("page", "path", "cocosCallback", "unityBinding", "successEvidence", "failureEvidence", "reconnectEvidence")
    foreach ($control in $controls) {
        $id = [string](Get-UnityMigrationPropertyValue -Object $control -Name "id" -Default "<missing>")
        foreach ($field in $required) {
            if (-not [string](Get-UnityMigrationPropertyValue -Object $control -Name $field -Default "")) {
                throw "Control '$id' has no $field in $Path"
            }
        }
        foreach ($field in @("realEntryClick", "automationPassed", "manualPassed")) {
            if (-not [bool](Get-UnityMigrationPropertyValue -Object $control -Name $field -Default $false)) {
                throw "Control '$id' has not passed $field in $Path"
            }
        }
        $status = [string](Get-UnityMigrationPropertyValue -Object $control -Name "status" -Default "")
        if ($status -ne "complete" -and $status -notmatch 'passed$') {
            throw "Control '$id' is not complete/passed in $Path"
        }
    }

    $hardGateVersion = [int](Get-UnityMigrationPropertyValue -Object $matrix -Name "hardGateVersion" -Default 1)
    if ($hardGateVersion -ge 2) {
        $audit = Get-UnityMigrationPropertyValue -Object $matrix -Name "g6Audit"
        if ($null -eq $audit) { throw "Hard-gate v2 matrix has no g6Audit: $Path" }
        if ([uint32](Get-UnityMigrationPropertyValue -Object $audit -Name "userId" -Default 0) -eq 0 -or
            [uint32](Get-UnityMigrationPropertyValue -Object $audit -Name "roleId" -Default 0) -eq 0) {
            throw "Hard-gate v2 matrix has no fixed userId/roleId: $Path"
        }
        if ([string](Get-UnityMigrationPropertyValue -Object $audit -Name "screenshotSize" -Default "") -ne "1334x750") {
            throw "Hard-gate v2 matrix screenshotSize must be 1334x750: $Path"
        }
        foreach ($field in @("placeholderCount", "duplicateUidCount", "seriousErrorCount")) {
            if ([int](Get-UnityMigrationPropertyValue -Object $audit -Name $field -Default -1) -ne 0) {
                throw "Hard-gate v2 matrix $field must be 0: $Path"
            }
        }
        if ([int](Get-UnityMigrationPropertyValue -Object $audit -Name "automationScreenshotCount" -Default -1) -ne $controls.Count) {
            throw "Hard-gate v2 matrix automationScreenshotCount must equal control count $($controls.Count): $Path"
        }

        Add-Type -AssemblyName System.Drawing
        $seenEvidence = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($control in $controls) {
            $id = [string]$control.id
            foreach ($field in @("cocosEvidence", "unityEvidence")) {
                $evidence = [string](Get-UnityMigrationPropertyValue -Object $control -Name $field -Default "")
                if (-not $evidence -or $evidence -match '(^|[-_/])missing([-/_.]|$)') {
                    throw "Control '$id' has missing $field in hard-gate v2 matrix."
                }
                if (-not $seenEvidence.Add($evidence)) {
                    throw "Control evidence path is reused: $evidence"
                }
                $resolved = Resolve-UnityMigrationPath -Root $Root -Path $evidence
                if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                    throw "Control '$id' evidence file does not exist: $evidence"
                }
                $image = [System.Drawing.Image]::FromFile($resolved)
                try {
                    if ($image.Width -ne 1334 -or $image.Height -ne 750) {
                        throw "Control '$id' evidence has wrong size: $evidence ($($image.Width)x$($image.Height))"
                    }
                }
                finally { $image.Dispose() }
            }
        }
    }
    return $controls.Count
}

function Assert-UnityMigrationControlMatrixDeclared {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ModuleKey,
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$MinimumCaptureStates = 0
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $matrix = $entry.Value
    if ([int]$matrix.schemaVersion -ne 1 -or [string]$matrix.module -ine $ModuleKey) {
        throw "Invalid control matrix identity: $Path"
    }
    $controls = @($matrix.controls)
    if ($controls.Count -eq 0) { throw "Control matrix has no controls: $Path" }
    if ($MinimumCaptureStates -gt 0 -and $controls.Count -lt $MinimumCaptureStates) {
        throw "Control matrix has $($controls.Count) controls, fewer than $MinimumCaptureStates registered capture states: $Path"
    }
    $ids = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $required = @("id", "page", "path", "cocosCallback", "unityBinding",
        "successEvidence", "failureEvidence", "reconnectEvidence")
    foreach ($control in $controls) {
        foreach ($field in $required) {
            if (-not [string](Get-UnityMigrationPropertyValue -Object $control -Name $field -Default "")) {
                throw "Control matrix entry has no $field in $Path"
            }
        }
        $id = [string]$control.id
        if (-not $ids.Add($id)) { throw "Duplicate control id '$id' in $Path" }
    }
    return $controls.Count
}

function Assert-UnityMigrationBootstrapContract {
    param([Parameter(Mandatory = $true)][string]$Root)
    $path = Join-Path $Root "tools\unity-migration\Test-BootstrapSceneIdempotence.ps1"
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
    if ($content -notmatch 'BootstrapSceneBuilder\.BuildBatch') {
        throw "Bootstrap idempotence test must execute BootstrapSceneBuilder.BuildBatch."
    }
    if ($content -match 'BootstrapSceneBuilder\.ForceRebuild|Force Rebuild Bootstrap Scene') {
        throw "Bootstrap ForceRebuild must never be used as idempotence evidence."
    }
}

function Assert-UnityMigrationRunnerIdentity {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$ScenarioKey,
        [Parameter(Mandatory = $true)][uint32]$ExpectedUserId
    )
    if ([string](Get-UnityMigrationPropertyValue -Object $Result -Name "scenario" -Default "") -ne $ScenarioKey) {
        throw "Unity result scenario mismatch: expected=$ScenarioKey actual=$($Result.scenario)"
    }
    if ([uint32](Get-UnityMigrationPropertyValue -Object $Result -Name "userId" -Default 0) -ne $ExpectedUserId) {
        throw "Unity result userId mismatch: expected=$ExpectedUserId actual=$($Result.userId)"
    }
    if ([uint32](Get-UnityMigrationPropertyValue -Object $Result -Name "roleId" -Default 0) -eq 0) {
        throw "Unity result roleId is zero."
    }
    if ([int](Get-UnityMigrationPropertyValue -Object $Result -Name "screenWidth" -Default 0) -ne 1334 -or
        [int](Get-UnityMigrationPropertyValue -Object $Result -Name "screenHeight" -Default 0) -ne 750) {
        throw "Unity result GameView size mismatch: $($Result.screenWidth)x$($Result.screenHeight)"
    }
    $status = [string](Get-UnityMigrationPropertyValue -Object $Result -Name "status" -Default "")
    if ($status -match '(placeholder|占位|missing icon|not resolved|reused uid|duplicate uid)') {
        throw "Unity result contains a hard visual/data failure marker: $status"
    }
}

function Write-UnityMigrationProgress {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$Phase,
        [int]$ProcessId = 0,
        [string]$Detail = ""
    )
    $state = [ordered]@{
        module = $Module
        phase = $Phase
        processId = $ProcessId
        detail = $Detail
        updatedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $Path -Content (($state | ConvertTo-Json -Depth 4) + "`n")
}

function Expand-UnityMigrationTemplate {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Template,
        [Parameter(Mandatory = $true)][hashtable]$Variables
    )
    $expanded = $Template
    foreach ($entry in $Variables.GetEnumerator()) {
        $token = "{{" + $entry.Key + "}}"
        $expanded = $expanded.Replace($token, [string]$entry.Value)
    }
    $unresolved = [regex]::Matches($expanded, '\{\{[A-Za-z][A-Za-z0-9]*\}\}')
    if ($unresolved.Count -gt 0) {
        $tokens = @($unresolved | ForEach-Object Value | Sort-Object -Unique) -join ", "
        throw "Unresolved Unity migration template token(s): $tokens"
    }
    return $expanded
}

function Invoke-UnityMigrationValidationData {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$ModuleConfig,
        [Parameter(Mandatory = $true)][ValidateSet("setupSql", "setupAssertSql", "cleanupSql", "cleanupAssertSql")][string]$Phase,
        [Parameter(Mandatory = $true)][hashtable]$Variables
    )
    $data = $ModuleConfig.validationData
    if ($null -eq $data) { return }
    $providerName = [string]$data.provider
    $providerProperty = $Manifest.validationDataProviders.PSObject.Properties[$providerName]
    if ($null -eq $providerProperty) { throw "Validation data provider '$providerName' was not found." }
    $provider = $providerProperty.Value
    $executable = Resolve-UnityMigrationPath -Root $Root -Path ([string]$provider.executable)
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "Validation data executable not found: $executable"
    }
    $statements = @((Get-UnityMigrationPropertyValue -Object $data -Name $Phase -Default @()))
    if ($statements.Count -eq 0) { return }
    $sql = (@($statements | ForEach-Object {
        Expand-UnityMigrationTemplate -Template ([string]$_) -Variables $Variables
    }) -join ";`n") + ";"
    $arguments = @($provider.arguments | ForEach-Object {
        Expand-UnityMigrationTemplate -Template ([string]$_) -Variables $Variables
    })
    $arguments += "--execute=$sql"
    & $executable @arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Validation data $Phase failed for module '$($ModuleConfig.key)' via provider '$providerName'."
    }
}

function Test-UnityMigrationPort {
    param([Parameter(Mandatory = $true)][int]$Port)
    return $null -ne (Get-UnityMigrationTcpListenerPid -Port $Port)
}

function Assert-UnityMigrationSourceContracts {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Scenario
    )
    $contracts = @((Get-UnityMigrationPropertyValue -Object $Scenario -Name "sourceContracts" -Default @()))
    $hashLines = New-Object System.Collections.Generic.List[string]
    foreach ($contract in $contracts) {
        $relativePath = [string]$contract.path
        if (-not $relativePath) { throw "Scenario '$($Scenario.key)' contains a source contract without path." }
        $path = Resolve-UnityMigrationPath -Root $Root -Path $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Scenario '$($Scenario.key)' source contract is missing: $relativePath"
        }
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
        foreach ($token in @($contract.contains)) {
            if (-not $content.Contains([string]$token)) {
                throw "Scenario '$($Scenario.key)' source contract drifted: '$relativePath' no longer contains '$token'."
            }
        }
        $hashLines.Add("$relativePath=$((Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash)")
    }
    if ($hashLines.Count -eq 0) { return "" }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($hashLines -join "`n"))
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

function Assert-UnityMigrationVisualArtifacts {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Scenario,
        [string[]]$ImmutableRoots = @(),
        [datetime]$FreshAfterUtc = [datetime]::MinValue
    )
    $assertions = Get-UnityMigrationPropertyValue -Object $Scenario -Name "visualAssertions" -Default $null
    $expectedWidth = [int](Get-UnityMigrationPropertyValue -Object $assertions -Name "width" -Default 1334)
    $expectedHeight = [int](Get-UnityMigrationPropertyValue -Object $assertions -Name "height" -Default 750)
    $minimumBytes = [int](Get-UnityMigrationPropertyValue -Object $assertions -Name "minimumBytes" -Default 1024)
    $requireUnique = [bool](Get-UnityMigrationPropertyValue -Object $assertions -Name "requireUniqueHashes" -Default $true)
    $results = New-Object System.Collections.Generic.List[object]
    Add-Type -AssemblyName System.Drawing
    foreach ($artifact in @($Scenario.artifacts)) {
        $relativePath = Get-UnityMigrationArtifactPath -Artifact $artifact
        $path = Assert-UnityMigrationRuntimeArtifact -Root $Root -Artifact $artifact -ImmutableRoots $ImmutableRoots
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Expected screenshot missing: $relativePath" }
        $item = Get-Item -LiteralPath $path
        if ($item.Length -lt $minimumBytes) {
            throw "Screenshot is suspiciously small: $relativePath ($($item.Length) bytes, minimum=$minimumBytes)."
        }
        if ($FreshAfterUtc -ne [datetime]::MinValue -and $item.LastWriteTimeUtc -lt $FreshAfterUtc.AddSeconds(-2)) {
            throw "Screenshot is stale: $relativePath"
        }
        $image = [System.Drawing.Image]::FromFile($path)
        try {
            if ($image.Width -ne $expectedWidth -or $image.Height -ne $expectedHeight) {
                throw "Screenshot has wrong size: $relativePath ($($image.Width)x$($image.Height), expected ${expectedWidth}x${expectedHeight})"
            }
        }
        finally { $image.Dispose() }
        $results.Add([pscustomobject]@{
            path = $relativePath
            width = $expectedWidth
            height = $expectedHeight
            bytes = [long]$item.Length
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        })
    }
    if ($requireUnique -and $results.Count -gt 1 -and
        @($results | Group-Object sha256 | Where-Object Count -gt 1).Count -gt 0) {
        throw "Scenario '$($Scenario.key)' contains duplicate screenshot content."
    }
    return $results.ToArray()
}

function Get-UnityMigrationTcpListenerPid {
    param([Parameter(Mandatory = $true)][int]$Port)
    try {
        $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
        if ($listener) { return [int]$listener.OwningProcess }
    }
    catch {
        # Restricted Windows sessions can deny Get-NetTCPConnection even when netstat is readable.
    }
    $netstat = Join-Path $env:SystemRoot "System32\netstat.exe"
    if (-not (Test-Path -LiteralPath $netstat -PathType Leaf)) { return $null }
    foreach ($line in @(& $netstat -ano -p tcp 2>$null)) {
        if ($line -match "^\s*TCP\s+\S+:$Port\s+\S+\s+LISTENING\s+(\d+)\s*$") {
            return [int]$Matches[1]
        }
    }
    return $null
}

function Get-UnityMigrationWorkspaceProcesses {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string[]]$Names = @("Unity.exe", "kapai.exe", "mysqld.exe", "ProjectX.exe")
    )
    $escapedRoot = [Regex]::Escape([System.IO.Path]::GetFullPath($Root))
    try {
        return @(Get-CimInstance Win32_Process -ErrorAction Stop |
            Where-Object {
                $_.Name -in $Names -and
                (($_.ExecutablePath -and $_.ExecutablePath -match $escapedRoot) -or
                 ($_.CommandLine -and $_.CommandLine -match $escapedRoot))
            })
    }
    catch {
        return @(Get-Process -ErrorAction SilentlyContinue |
            Where-Object {
                "$($_.ProcessName).exe" -in $Names -and $_.Path -and $_.Path -match $escapedRoot
            } |
            ForEach-Object {
                [pscustomobject]@{
                    ProcessId = $_.Id
                    Name = "$($_.ProcessName).exe"
                    ExecutablePath = $_.Path
                    CommandLine = $null
                }
            })
    }
}

function New-UnityMigrationUserId {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [int]$StartAt = 7200000
    )
    $localDir = Join-Path $Root ".local"
    [System.IO.Directory]::CreateDirectory($localDir) | Out-Null
    $statePath = Join-Path $localDir "unity-migration-userids.json"
    $lockPath = Join-Path $localDir "unity-migration-userids.lock"
    $lock = $null
    try {
        $lock = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        $next = $StartAt
        if (Test-Path -LiteralPath $statePath) {
            $state = Get-Content -Raw -Encoding UTF8 -LiteralPath $statePath | ConvertFrom-Json
            if ($state.nextUserId -ge $StartAt) { $next = [int]$state.nextUserId }
        }
        $state = [ordered]@{
            nextUserId = $next + 1
            lastAllocatedUserId = $next
            updatedUtc = [DateTime]::UtcNow.ToString("O")
        }
        Write-UnityMigrationUtf8 -Path $statePath -Content (($state | ConvertTo-Json -Depth 4) + "`n")
        return $next
    }
    finally {
        if ($null -ne $lock) { $lock.Dispose() }
    }
}
