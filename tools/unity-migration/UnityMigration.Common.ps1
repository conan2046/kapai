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

function Resolve-UnityMigrationExecutable {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$ExplicitPath = "",
        [string]$Root = ""
    )
    if ($ExplicitPath) {
        $candidate = if ([IO.Path]::IsPathRooted($ExplicitPath) -or -not $Root) {
            [IO.Path]::GetFullPath($ExplicitPath)
        }
        else {
            Resolve-UnityMigrationPath -Root $Root -Path $ExplicitPath
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "$Name executable was not found: $candidate"
        }
        return $candidate
    }
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command -or -not $command.Source) {
        throw "$Name executable was not found on PATH."
    }
    return [IO.Path]::GetFullPath([string]$command.Source)
}

function Get-UnityMigrationPowerShellExecutable {
    $current = Join-Path $PSHOME "pwsh.exe"
    if (Test-Path -LiteralPath $current -PathType Leaf) {
        return [IO.Path]::GetFullPath($current)
    }
    return Resolve-UnityMigrationExecutable -Name "pwsh"
}

function Get-UnityMigrationPythonExecutable {
    param([string]$ExplicitPath = "", [string]$Root = "")
    if ($ExplicitPath) {
        return Resolve-UnityMigrationExecutable -Name "python" -ExplicitPath $ExplicitPath -Root $Root
    }
    $candidates = @()
    if ($env:USERPROFILE) {
        $candidates += Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    }
    if ($env:LOCALAPPDATA) {
        $candidates += Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\python.exe"
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [IO.Path]::GetFullPath($candidate)
        }
    }
    $command = Get-Command python -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $command -and $command.Source -and
        (Test-Path -LiteralPath $command.Source -PathType Leaf)) {
        return [IO.Path]::GetFullPath([string]$command.Source)
    }
    throw "python executable was not found on PATH or in the Codex bundled runtime. Pass -PythonExecutable explicitly."
}

function Get-UnityMigrationFixedAccountContractFailures {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)]$FixedAccount
    )
    $failures = New-Object System.Collections.Generic.List[string]
    foreach ($name in @(
        "userId", "roleId", "adapter", "snapshot", "resultEvidence",
        "reloginRequired", "extraFlags", "skipPostValidationFixtureAssert", "artifactCopies",
        "dataPreflight"
    )) {
        if ($null -eq $FixedAccount.PSObject.Properties[$name]) {
            $failures.Add("Evidence contract $Module fixedAccount is missing required field '$name'.")
        }
    }
    if ([uint32](Get-UnityMigrationPropertyValue -Object $FixedAccount -Name "userId" -Default 0) -eq 0 -or
        [uint32](Get-UnityMigrationPropertyValue -Object $FixedAccount -Name "roleId" -Default 0) -eq 0) {
        $failures.Add("Evidence contract $Module has no fixed userId/roleId.")
    }
    foreach ($name in @("adapter", "snapshot", "resultEvidence")) {
        if ([string]::IsNullOrWhiteSpace([string](Get-UnityMigrationPropertyValue -Object $FixedAccount -Name $name -Default ""))) {
            $failures.Add("Evidence contract $Module fixedAccount field '$name' is empty.")
        }
    }
    foreach ($name in @("reloginRequired", "skipPostValidationFixtureAssert")) {
        $value = Get-UnityMigrationPropertyValue -Object $FixedAccount -Name $name -Default $null
        if ($null -ne $FixedAccount.PSObject.Properties[$name] -and $value -isnot [bool]) {
            $failures.Add("Evidence contract $Module fixedAccount field '$name' must be boolean.")
        }
    }
    foreach ($flag in @((Get-UnityMigrationPropertyValue -Object $FixedAccount -Name "extraFlags" -Default @()))) {
        if ([string]::IsNullOrWhiteSpace([string]$flag)) {
            $failures.Add("Evidence contract $Module fixedAccount extraFlags contains an empty value.")
        }
    }
    $destinations = New-Object System.Collections.Generic.List[string]
    foreach ($copy in @((Get-UnityMigrationPropertyValue -Object $FixedAccount -Name "artifactCopies" -Default @()))) {
        $source = [string](Get-UnityMigrationPropertyValue -Object $copy -Name "source" -Default "")
        $destination = [string](Get-UnityMigrationPropertyValue -Object $copy -Name "destination" -Default "")
        if (-not $source -or -not $destination) {
            $failures.Add("Evidence contract $Module fixedAccount artifactCopies requires non-empty source and destination.")
            continue
        }
        $destinations.Add($destination)
    }
    if (@($destinations | Sort-Object -Unique).Count -ne $destinations.Count) {
        $failures.Add("Evidence contract $Module fixedAccount artifactCopies contains duplicate destinations.")
    }
    $dataPreflight = Get-UnityMigrationPropertyValue -Object $FixedAccount -Name "dataPreflight" -Default $null
    if ($null -ne $dataPreflight) {
        $requiresLogin = Get-UnityMigrationPropertyValue -Object $dataPreflight -Name "requiresLogin" -Default $null
        if ($requiresLogin -isnot [bool]) {
            $failures.Add("Evidence contract $Module fixedAccount dataPreflight.requiresLogin must be boolean.")
        }
        $requirements = @((Get-UnityMigrationPropertyValue -Object $dataPreflight -Name "requirements" -Default @()))
        if ($requirements.Count -eq 0) {
            $failures.Add("Evidence contract $Module fixedAccount dataPreflight.requirements must not be empty.")
        }
        $requirementIds = New-Object System.Collections.Generic.List[string]
        foreach ($requirement in $requirements) {
            $id = [string](Get-UnityMigrationPropertyValue -Object $requirement -Name "id" -Default "")
            $description = [string](Get-UnityMigrationPropertyValue -Object $requirement -Name "description" -Default "")
            if (-not $id -or -not $description) {
                $failures.Add("Evidence contract $Module fixedAccount data requirement needs non-empty id and description.")
            }
            elseif ($id -notmatch '^[a-z0-9][a-z0-9-]*$') {
                $failures.Add("Evidence contract $Module fixedAccount data requirement id is invalid: $id")
            }
            else {
                $requirementIds.Add($id)
            }
        }
        if (@($requirementIds | Sort-Object -Unique).Count -ne $requirementIds.Count) {
            $failures.Add("Evidence contract $Module fixedAccount dataPreflight contains duplicate requirement ids.")
        }
    }
    $adapter = [string](Get-UnityMigrationPropertyValue -Object $FixedAccount -Name "adapter" -Default "")
    if ($adapter) {
        $resolvedAdapter = Resolve-UnityMigrationPath -Root $Root -Path $adapter
        if (-not (Test-Path -LiteralPath $resolvedAdapter -PathType Leaf)) {
            $failures.Add("Evidence contract $Module fixedAccount adapter is missing: $adapter")
        }
    }
    return @($failures)
}

function Get-UnityMigrationDataPreflightFingerprint {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$FixedAccount
    )
    $adapter = Resolve-UnityMigrationPath -Root $Root -Path ([string]$FixedAccount.adapter)
    $payload = [ordered]@{
        userId = [uint32]$FixedAccount.userId
        roleId = [uint32]$FixedAccount.roleId
        adapter = [string]$FixedAccount.adapter
        adapterSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $adapter).Hash
        dataPreflight = $FixedAccount.dataPreflight
    }
    $json = $payload | ConvertTo-Json -Depth 8 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

function Get-UnityMigrationDataPreflightEvidenceFailures {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ExpectedFingerprint,
        [Parameter(Mandatory = $true)][uint32]$ExpectedUserId,
        [Parameter(Mandatory = $true)][uint32]$ExpectedRoleId,
        [string]$ExpectedSourceContractFingerprint = "",
        [string]$ExpectedG5ContractFingerprint = ""
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ([string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "contractFingerprint" -Default "") -ne $ExpectedFingerprint) {
        $failures.Add("contract fingerprint mismatch")
    }
    if ([uint32](Get-UnityMigrationPropertyValue -Object $Evidence -Name "userId" -Default 0) -ne $ExpectedUserId) {
        $failures.Add("userId mismatch")
    }
    if ([uint32](Get-UnityMigrationPropertyValue -Object $Evidence -Name "roleId" -Default 0) -ne $ExpectedRoleId) {
        $failures.Add("roleId mismatch")
    }
    if ($ExpectedSourceContractFingerprint -and
        [string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "sourceContractFingerprint" -Default "") -ne
        $ExpectedSourceContractFingerprint) {
        $failures.Add("source contract fingerprint mismatch")
    }
    if ($ExpectedG5ContractFingerprint -and
        [string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "g5ContractFingerprint" -Default "") -ne
        $ExpectedG5ContractFingerprint) {
        $failures.Add("G5 contract fingerprint mismatch")
    }
    foreach ($name in @("setupAssert", "restoreAssert", "cleanupAssert")) {
        if ([string](Get-UnityMigrationPropertyValue -Object $Evidence -Name $name -Default "") -ne "passed") {
            $failures.Add("$name is not passed")
        }
    }
    return @($failures)
}

function Get-UnityMigrationObjectFingerprint {
    param([Parameter(Mandatory = $true)]$Value)
    $json = $Value | ConvertTo-Json -Depth 16 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

function Get-UnityMigrationG5ContractFingerprint {
    param([Parameter(Mandatory = $true)]$Contract)
    $g5 = Get-UnityMigrationPropertyValue -Object $Contract -Name "g5" -Default $null
    if ($null -eq $g5) { return "" }
    return Get-UnityMigrationObjectFingerprint -Value $g5
}

function Test-UnityMigrationCommandLineReferencesRoot {
    param(
        [AllowEmptyString()][string]$CommandLine,
        [Parameter(Mandatory = $true)][string]$Root
    )
    if (-not $CommandLine) { return $false }
    $fullRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    return $CommandLine.IndexOf($fullRoot, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
        $CommandLine.IndexOf(($fullRoot -replace '\\', '/'), [StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Get-UnityMigrationBlockingDotNetProcesses {
    param([Parameter(Mandatory = $true)][string]$Root)
    if (-not $IsWindows) { return @() }
    try {
        return @(Get-CimInstance Win32_Process -Filter "Name = 'dotnet.exe'" -ErrorAction Stop | Where-Object {
            Test-UnityMigrationCommandLineReferencesRoot -CommandLine ([string]$_.CommandLine) -Root $Root
        })
    }
    catch {
        $dotnetProcesses = @(Get-Process dotnet -ErrorAction SilentlyContinue)
        if ($dotnetProcesses.Count -eq 0) { return @() }
        $details = ($dotnetProcesses | ForEach-Object { "pid=$($_.Id)" }) -join ", "
        throw "dotnet is running but its command line cannot be inspected; stop it before Unity validation. $details"
    }
}

function Assert-NoUnityMigrationBlockingDotNet {
    param([Parameter(Mandatory = $true)][string]$Root)
    $blocking = @(Get-UnityMigrationBlockingDotNetProcesses -Root $Root)
    if ($blocking.Count -gt 0) {
        $details = ($blocking | ForEach-Object {
            $command = [string]$_.CommandLine
            if ($command.Length -gt 180) { $command = $command.Substring(0, 180) + "..." }
            "pid=$($_.ProcessId), command=$command"
        }) -join "; "
        throw "Project-related dotnet process may hold Unity/ILPP files. Stop it before validation. $details"
    }
}

function Get-UnityMigrationCompileFingerprint {
    param(
        [Parameter(Mandatory = $true)][string]$UnityProject,
        [Parameter(Mandatory = $true)][string]$UnityExecutable
    )
    $inputs = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $assets = Join-Path $UnityProject "Assets"
    if (Test-Path -LiteralPath $assets -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $assets -Recurse -File -ErrorAction Stop | Where-Object {
            $_.Extension -in @(".cs", ".asmdef", ".asmref", ".rsp")
        })) {
            $inputs.Add($file)
        }
    }
    foreach ($relativePath in @(
        "Packages/manifest.json",
        "Packages/packages-lock.json",
        "ProjectSettings/ProjectVersion.txt"
    )) {
        $path = Resolve-UnityMigrationPath -Root $UnityProject -Path $relativePath
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $inputs.Add((Get-Item -LiteralPath $path))
        }
    }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($file in @($inputs | Sort-Object FullName -Unique)) {
        $relative = [IO.Path]::GetRelativePath($UnityProject, $file.FullName)
        $lines.Add("$relative=$((Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash)")
    }
    $unityItem = Get-Item -LiteralPath $UnityExecutable
    $lines.Add("unity=$($unityItem.FullName)|$($unityItem.LastWriteTimeUtc.Ticks)|$($unityItem.Length)")
    $bytes = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

function Invoke-UnityMigrationCompilePreflight {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$UnityProject,
        [Parameter(Mandatory = $true)][string]$UnityExecutable,
        [ValidateRange(120, 1800)][int]$TimeoutSeconds = 900,
        [switch]$Force
    )
    Assert-NoUnityMigrationBlockingDotNet -Root $Root
    $summaryDirectory = Join-Path $Root ".local\unity-validation"
    [IO.Directory]::CreateDirectory($summaryDirectory) | Out-Null
    $stampPath = Join-Path $summaryDirectory "unity-compile-preflight-latest.json"
    $logPath = Join-Path $summaryDirectory "unity-compile-preflight.log"
    $fingerprint = Get-UnityMigrationCompileFingerprint -UnityProject $UnityProject -UnityExecutable $UnityExecutable
    if (-not $Force -and (Test-Path -LiteralPath $stampPath -PathType Leaf)) {
        try {
            $stamp = Get-Content -Raw -Encoding UTF8 -LiteralPath $stampPath | ConvertFrom-Json
            if ([bool]$stamp.success -and [string]$stamp.fingerprint -eq $fingerprint) {
                Write-Host "Unity compile preflight cache hit: $fingerprint"
                return [pscustomobject]@{ cached = $true; fingerprint = $fingerprint; log = $logPath }
            }
        }
        catch { }
    }
    if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
    $arguments = @("-batchMode", "-quit", "-projectPath", $UnityProject, "-logFile", $logPath)
    $run = Invoke-UnityMigrationProcess -Executable $UnityExecutable -Arguments $arguments `
        -Module "Toolchain" -Phase "compile-preflight" -LogPath $logPath `
        -TimeoutSeconds $TimeoutSeconds -HeartbeatSeconds 30
    if ($run.exitCode -ne 0) {
        throw "Unity compile preflight failed with exit code $($run.exitCode); log=$logPath"
    }
    $seriousPattern = 'error CS\d+|Unhandled Exception|Fatal Error|Crash!!!|ILPostProcessorException|IOException:.*Assembly-CSharp|sharing violation|being used by another process'
    $serious = @(Select-String -LiteralPath $logPath -Pattern $seriousPattern -CaseSensitive:$false -ErrorAction SilentlyContinue)
    if ($serious.Count -gt 0) {
        $sample = ($serious | Select-Object -First 10 | ForEach-Object { "$($_.LineNumber):$($_.Line)" }) -join "`n"
        throw "Unity compile preflight log contains serious errors:`n$sample"
    }
    Start-Sleep -Seconds 1
    Assert-NoUnityMigrationBlockingDotNet -Root $Root
    $stamp = [ordered]@{
        success = $true
        fingerprint = $fingerprint
        unityExecutable = $UnityExecutable
        unityProject = $UnityProject
        log = $logPath
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $stampPath -Content (($stamp | ConvertTo-Json -Depth 4) + "`n")
    Write-Host "Unity compile preflight passed: $fingerprint"
    return [pscustomobject]@{ cached = $false; fingerprint = $fingerprint; log = $logPath }
}

function Start-UnityMigrationTiming {
    return [pscustomobject]@{
        startedUtc = [DateTime]::UtcNow
        stopwatch = [Diagnostics.Stopwatch]::StartNew()
    }
}

function Complete-UnityMigrationTiming {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Timings,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$Timing
    )
    $Timing.stopwatch.Stop()
    $Timings[$Name] = [ordered]@{
        startedUtc = ([DateTime]$Timing.startedUtc).ToString("O")
        durationMs = [long]$Timing.stopwatch.ElapsedMilliseconds
    }
}

function Stop-UnityMigrationProcessTree {
    param([Parameter(Mandatory = $true)][int]$ProcessId)
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $process) { return }
    try { $process.Kill($true) }
    catch { Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue }
}

function Invoke-UnityMigrationProcess {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$Phase,
        [string]$LogPath = "",
        [string]$ResultPath = "",
        [string]$ProgressPath = "",
        [ValidateRange(30, 7200)][int]$TimeoutSeconds = 1800,
        [ValidateRange(5, 300)][int]$HeartbeatSeconds = 30,
        [ValidateRange(0, 1800)][int]$NoProgressTimeoutSeconds = 0,
        [ValidateRange(5, 120)][int]$StartupGraceSeconds = 30
    )
    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) {
        throw "Process executable is missing: $Executable"
    }
    $startedUtc = [DateTime]::UtcNow
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $lastHeartbeat = [DateTime]::MinValue
    $lastProgressUtc = $startedUtc
    $lastLogLength = -1L
    $lastResultWriteUtc = [DateTime]::MinValue
    $lastCpuSeconds = 0d
    $startupObserved = $false
    if ($LogPath -and (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        Remove-Item -LiteralPath $LogPath -Force
    }
    $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -WindowStyle Hidden -PassThru
    try {
        while (-not $process.HasExited) {
            Start-Sleep -Seconds 1
            $process.Refresh()
            $now = [DateTime]::UtcNow
            $progressed = $false
            if ($LogPath -and (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
                $logItem = Get-Item -LiteralPath $LogPath
                if ($logItem.LastWriteTimeUtc -ge $startedUtc.AddSeconds(-2) -and
                    $logItem.Length -ne $lastLogLength) {
                    $lastLogLength = $logItem.Length
                    $progressed = $true
                    $startupObserved = $true
                }
            }
            if ($ResultPath -and (Test-Path -LiteralPath $ResultPath -PathType Leaf)) {
                $resultItem = Get-Item -LiteralPath $ResultPath
                if ($resultItem.LastWriteTimeUtc -ne $lastResultWriteUtc) {
                    $lastResultWriteUtc = $resultItem.LastWriteTimeUtc
                    $progressed = $true
                    $startupObserved = $true
                }
            }
            try {
                $cpuSeconds = $process.TotalProcessorTime.TotalSeconds
                if ($cpuSeconds -gt $lastCpuSeconds + 0.05d) {
                    $lastCpuSeconds = $cpuSeconds
                    $progressed = $true
                }
                if ($cpuSeconds -ge 0.25d) { $startupObserved = $true }
            }
            catch { }
            if ($progressed) { $lastProgressUtc = $now }
            $heartbeatDue = ($now - $lastHeartbeat).TotalSeconds -ge $HeartbeatSeconds
            if ($ProgressPath -and ($progressed -or $heartbeatDue)) {
                Write-UnityMigrationProgress -Path $ProgressPath -Module $Module -Phase $Phase `
                    -ProcessId $process.Id -Detail "elapsed=$([int]$stopwatch.Elapsed.TotalSeconds)s; logBytes=$lastLogLength; cpu=$([Math]::Round($lastCpuSeconds, 2))s"
            }
            if ($heartbeatDue) {
                Write-Host "Unity process heartbeat: module=$Module phase=$Phase pid=$($process.Id) elapsed=$([int]$stopwatch.Elapsed.TotalSeconds)s logBytes=$lastLogLength cpu=$([Math]::Round($lastCpuSeconds, 2))s"
                $lastHeartbeat = $now
            }
            if (-not $startupObserved -and $stopwatch.Elapsed.TotalSeconds -ge $StartupGraceSeconds) {
                throw "Unity process did not start real work within ${StartupGraceSeconds}s: module=$Module phase=$Phase pid=$($process.Id) log=$LogPath"
            }
            if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                throw "Unity process timed out: module=$Module phase=$Phase timeout=${TimeoutSeconds}s log=$LogPath"
            }
            if ($NoProgressTimeoutSeconds -gt 0 -and
                ($now - $lastProgressUtc).TotalSeconds -ge $NoProgressTimeoutSeconds) {
                throw "Unity process made no file progress: module=$Module phase=$Phase timeout=${NoProgressTimeoutSeconds}s log=$LogPath"
            }
        }
        $process.WaitForExit()
        $stopwatch.Stop()
        if ($ResultPath) {
            if (-not (Test-Path -LiteralPath $ResultPath -PathType Leaf)) {
                throw "Unity process result is missing: module=$Module phase=$Phase result=$ResultPath log=$LogPath"
            }
            if ((Get-Item -LiteralPath $ResultPath).LastWriteTimeUtc -lt $startedUtc.AddSeconds(-2)) {
                throw "Unity process result is stale: module=$Module phase=$Phase result=$ResultPath"
            }
        }
        return [pscustomobject]@{
            processId = $process.Id
            exitCode = $process.ExitCode
            startedUtc = $startedUtc.ToString("O")
            durationMs = [long]$stopwatch.ElapsedMilliseconds
            logPath = $LogPath
            resultPath = $ResultPath
        }
    }
    catch {
        Stop-UnityMigrationProcessTree -ProcessId $process.Id
        throw
    }
    finally {
        $process.Dispose()
    }
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
        [int]$MinimumCaptureStates = 0,
        [switch]$RequireLifecycleFields
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
        if ($RequireLifecycleFields) {
            foreach ($field in @("status", "realEntryClick", "automationPassed", "manualPassed")) {
                if ($null -eq $control.PSObject.Properties[$field]) {
                    throw "Control matrix entry '$($control.id)' has no lifecycle field $field in $Path"
                }
            }
            foreach ($field in @("realEntryClick", "automationPassed", "manualPassed")) {
                if ((Get-UnityMigrationPropertyValue -Object $control -Name $field -Default $null) -isnot [bool]) {
                    throw "Control matrix entry '$($control.id)' field $field must be boolean in $Path"
                }
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

function Assert-UnityMigrationRunnerCoverage {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)]$Scenario,
        [string]$ControlMatrix = ""
    )
    $coverageRequired = [bool](Get-UnityMigrationPropertyValue -Object $Scenario `
        -Name "controlCoverageRequired" -Default $false)
    $semanticKeys = @((Get-UnityMigrationPropertyValue -Object $Scenario `
        -Name "semanticAssertionKeys" -Default @()) | ForEach-Object { [string]$_ })
    $actualControls = @((Get-UnityMigrationPropertyValue -Object $Result `
        -Name "validatedControlIds" -Default @()) | ForEach-Object { [string]$_ })
    $passedSemantics = @((Get-UnityMigrationPropertyValue -Object $Result `
        -Name "passedSemanticAssertions" -Default @()) | ForEach-Object { [string]$_ })
    $failedSemantics = @((Get-UnityMigrationPropertyValue -Object $Result `
        -Name "failedSemanticAssertions" -Default @()) | ForEach-Object { [string]$_ })

    if ($coverageRequired) {
        if (-not $ControlMatrix) { throw "Scenario '$($Scenario.key)' requires runtime control coverage but has no control matrix." }
        $matrix = (Import-UnityMigrationJson -Root $Root -Path $ControlMatrix).Value
        $expectedControls = @($matrix.controls | ForEach-Object { [string]$_.id })
        $difference = @(Compare-Object ($expectedControls | Sort-Object) ($actualControls | Sort-Object))
        if ($difference.Count -gt 0) {
            throw "Runtime control coverage mismatch: expected=$($expectedControls.Count) actual=$($actualControls.Count); diff=$($difference.InputObject -join ',')"
        }
    }
    if ($failedSemantics.Count -gt 0) {
        throw "Runtime semantic assertions failed: $($failedSemantics -join '; ')"
    }
    $missingSemantics = @($semanticKeys | Where-Object { $_ -notin $passedSemantics })
    if ($missingSemantics.Count -gt 0) {
        throw "Runtime semantic assertions were not proved: $($missingSemantics -join ', ')"
    }
    return [pscustomobject]@{
        validatedControlIds = $actualControls
        passedSemanticAssertions = $passedSemantics
        failedSemanticAssertions = $failedSemantics
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

function Invoke-UnityMigrationSql {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$Sql,
        [string]$ProviderName = ""
    )
    if (-not $ProviderName) {
        $providers = @($Manifest.validationDataProviders.PSObject.Properties)
        if ($providers.Count -ne 1) {
            throw "A validation data provider must be specified when the manifest has $($providers.Count) providers."
        }
        $ProviderName = [string]$providers[0].Name
    }
    $providerProperty = $Manifest.validationDataProviders.PSObject.Properties[$ProviderName]
    if ($null -eq $providerProperty) { throw "Validation data provider '$ProviderName' was not found." }
    $provider = $providerProperty.Value
    $executable = Resolve-UnityMigrationPath -Root $Root -Path ([string]$provider.executable)
    $arguments = @($provider.arguments | ForEach-Object { [string]$_ })
    $arguments += "--batch"
    $arguments += "--skip-column-names"
    $arguments += "--execute=$Sql"
    $output = @(& $executable @arguments 2>$null)
    if ($LASTEXITCODE -ne 0) { throw "Validation SQL failed via provider '$ProviderName'." }
    return @($output)
}

function Remove-UnityMigrationDisposableRole {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][uint32]$UserId
    )
    if ($UserId -eq 0) { throw "Disposable-role cleanup refuses userId 0." }
    $sql = @"
SET @uid := $UserId;
SET @rid := COALESCE((SELECT CAST(role0 AS UNSIGNED) FROM user_info1 WHERE id=@uid LIMIT 1), 0);
DELETE FROM role_info WHERE id=@rid AND @rid<>0;
DELETE FROM user_info1 WHERE id=@uid;
SELECT CONCAT('residual=', (SELECT COUNT(*) FROM user_info1 WHERE id=@uid) + (SELECT COUNT(*) FROM role_info WHERE id=@rid AND @rid<>0));
"@
    $output = @(Invoke-UnityMigrationSql -Root $Root -Manifest $Manifest -Sql $sql)
    if ("residual=0" -notin @($output | ForEach-Object { ([string]$_).Trim() })) {
        throw "Disposable-role cleanup left residue for userId=$UserId; output=$($output -join ',')"
    }
    return [pscustomobject]@{ userId = $UserId; cleanupAssert = "passed"; residual = 0 }
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
