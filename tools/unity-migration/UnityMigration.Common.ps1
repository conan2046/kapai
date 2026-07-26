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
        if ([string](Get-UnityMigrationPropertyValue -Object $control -Name "status" -Default "") -ne "complete") {
            throw "Control '$id' is not complete in $Path"
        }
    }
    return $controls.Count
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
        [Parameter(Mandatory = $true)][ValidateSet("setupSql", "cleanupSql")][string]$Phase,
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
    $statements = @($data.$Phase)
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
