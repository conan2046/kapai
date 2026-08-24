Set-StrictMode -Version Latest

function Get-UnityMigrationRoot {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
}

function Get-UnityMigrationShellRoute {
    param([string]$Root = "")
    if (-not $Root) { $Root = Get-UnityMigrationRoot }
    $resolvedRoot = Resolve-UnityMigrationExistingPath -Root $Root -Path "." -PathType Container
    $escapedRoot = $resolvedRoot.Replace("'", "''")
    return [pscustomobject][ordered]@{
        root = $resolvedRoot
        brokerWorkdirMode = "omit"
        powerShellPrelude = "Set-Location -LiteralPath '$escapedRoot'"
    }
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

function Resolve-UnityMigrationExistingPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet("Any", "Leaf", "Container")][string]$PathType = "Any"
    )
    $resolved = Resolve-UnityMigrationPath -Root $Root -Path $Path
    $exists = if ($PathType -eq "Any") {
        Test-Path -LiteralPath $resolved
    }
    else {
        Test-Path -LiteralPath $resolved -PathType $PathType
    }
    if (-not $exists) {
        throw "Unity migration path was not resolved to an existing $PathType path: $Path. Resolve it through the manifest, matrix, rg --files, or source references before use. Resolved: $resolved"
    }
    return $resolved
}

function Resolve-UnityMigrationUnityExecutable {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [string]$ExplicitPath = ""
    )

    $projectVersionPath = Join-Path $Root "unityclient\ProjectSettings\ProjectVersion.txt"
    $manifestVersionProperty = $Manifest.PSObject.Properties["unityVersion"]
    $version = if ($null -ne $manifestVersionProperty) { [string]$manifestVersionProperty.Value } else { "" }
    if (-not $version -and (Test-Path -LiteralPath $projectVersionPath -PathType Leaf)) {
        $versionMatch = [regex]::Match(
            (Get-Content -LiteralPath $projectVersionPath -Raw -Encoding UTF8),
            '(?m)^m_EditorVersion:\s*(\S+)')
        if ($versionMatch.Success) { $version = $versionMatch.Groups[1].Value }
    }

    $candidates = New-Object System.Collections.Generic.List[string]
    $candidateSources = New-Object System.Collections.Generic.List[string]
    function Add-UnityExecutableCandidate([string]$Path, [string]$Source) {
        if ([string]::IsNullOrWhiteSpace($Path)) { return }
        $resolved = Resolve-UnityMigrationPath -Root $Root -Path $Path
        if ($candidates -notcontains $resolved) {
            $candidates.Add($resolved)
            $candidateSources.Add($Source)
        }
    }

    Add-UnityExecutableCandidate -Path $ExplicitPath -Source "command line"
    Add-UnityExecutableCandidate -Path ([Environment]::GetEnvironmentVariable("PROJECTX_UNITY_EXECUTABLE")) -Source "PROJECTX_UNITY_EXECUTABLE"

    $localSettingsPath = Join-Path $Root ".local\unity-migration\settings.json"
    if (Test-Path -LiteralPath $localSettingsPath -PathType Leaf) {
        $localSettings = Get-Content -LiteralPath $localSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $localExecutableProperty = $localSettings.PSObject.Properties["unityExecutable"]
        if ($null -ne $localExecutableProperty) {
            Add-UnityExecutableCandidate -Path ([string]$localExecutableProperty.Value) -Source $localSettingsPath
        }
    }

    $manifestExecutableProperty = $Manifest.PSObject.Properties["unityExecutable"]
    if ($null -ne $manifestExecutableProperty) {
        Add-UnityExecutableCandidate -Path ([string]$manifestExecutableProperty.Value) -Source "manifest fallback"
    }

    if ($version) {
        if ($env:ProgramFiles) {
            Add-UnityExecutableCandidate -Path (Join-Path $env:ProgramFiles "Unity\Hub\Editor\$version\Editor\Unity.exe") -Source "Unity Hub default"
        }
        $secondaryInstallPath = Join-Path $env:APPDATA "UnityHub\secondaryInstallPath.json"
        if (Test-Path -LiteralPath $secondaryInstallPath -PathType Leaf) {
            $secondaryRoot = (Get-Content -LiteralPath $secondaryInstallPath -Raw -Encoding UTF8).Trim().Trim('"')
            Add-UnityExecutableCandidate -Path (Join-Path $secondaryRoot "$version\Editor\Unity.exe") -Source "Unity Hub secondary path"
        }
        foreach ($drive in @(Get-PSDrive -PSProvider FileSystem)) {
            foreach ($relative in @(
                "UnityPro\$version\Editor\Unity.exe",
                "unity\$version\Editor\Unity.exe",
                "Unity\Hub\Editor\$version\Editor\Unity.exe"
            )) {
                Add-UnityExecutableCandidate -Path (Join-Path $drive.Root $relative) -Source "drive discovery"
            }
        }
    }

    for ($index = 0; $index -lt $candidates.Count; $index++) {
        if (Test-Path -LiteralPath $candidates[$index] -PathType Leaf) {
            Write-Host "Unity executable resolved from $($candidateSources[$index]): $($candidates[$index])"
            return $candidates[$index]
        }
    }

    $attempted = if ($candidates.Count -gt 0) { $candidates -join '; ' } else { '<none>' }
    throw "Unity $version executable was not found. Set PROJECTX_UNITY_EXECUTABLE once or create .local/unity-migration/settings.json with unityExecutable. Attempted: $attempted"
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

function Assert-UnityMigrationRgPathArgument {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Path)) {
        throw "rg path arguments must be literal on Windows; use a literal directory plus -g for file filters: $Path"
    }
    return $Path
}

function Resolve-UnityMigrationRgPathArguments {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$Paths
    )
    if ($Paths.Count -eq 0) {
        throw "At least one rg path argument is required."
    }
    $resolved = New-Object System.Collections.Generic.List[string]
    foreach ($path in $Paths) {
        Assert-UnityMigrationRgPathArgument -Path $path | Out-Null
        try {
            $resolved.Add((Resolve-UnityMigrationExistingPath -Root $Root -Path $path -PathType Any))
        }
        catch {
            throw "rg path preflight rejected '$path' before native rg execution. $($_.Exception.Message)"
        }
    }
    return @($resolved)
}

function Find-UnityMigrationFiles {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$SearchRoot,
        [Parameter(Mandatory = $true)][string]$Pattern
    )
    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        throw "Unity migration file discovery requires a non-empty regex pattern."
    }
    $resolvedRoot = Resolve-UnityMigrationExistingPath -Root $Root -Path $SearchRoot -PathType Container
    $rg = @(Get-Command rg -CommandType Application -ErrorAction Stop)[0]
    $files = @(& $rg.Source --files --hidden --glob '!.git/**' -- $resolvedRoot)
    if ($LASTEXITCODE -ge 2) {
        throw "rg --files discovery failed for '$SearchRoot' with exit code $LASTEXITCODE."
    }
    return @($files | Where-Object { $_ -match $Pattern })
}

function Find-UnityMigrationJsonNodes {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$JsonPath,
        [Parameter(Mandatory = $true)][string]$Name
    )
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "Unity migration JSON node discovery requires a non-empty node name."
    }
    $resolved = Resolve-UnityMigrationExistingPath -Root $Root -Path $JsonPath -PathType Leaf
    if ($null -eq ('UnityMigrationJsonNodeQuery' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

public sealed class UnityMigrationJsonNodeMatch
{
    public string Path { get; set; }
    public bool? Active { get; set; }
}

public static class UnityMigrationJsonNodeQuery
{
    public static UnityMigrationJsonNodeMatch[] Find(string filePath, string requestedName)
    {
        using (JsonDocument document = JsonDocument.Parse(File.ReadAllBytes(filePath)))
        {
            var matches = new List<UnityMigrationJsonNodeMatch>();
            Visit(document.RootElement, String.Empty, requestedName, matches);
            return matches.ToArray();
        }
    }

    private static void Visit(JsonElement element, string parentPath, string requestedName,
        List<UnityMigrationJsonNodeMatch> matches)
    {
        if (element.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement child in element.EnumerateArray())
                Visit(child, parentPath, requestedName, matches);
            return;
        }
        if (element.ValueKind != JsonValueKind.Object)
            return;

        string name = String.Empty;
        JsonElement nameElement;
        if (element.TryGetProperty("name", out nameElement) && nameElement.ValueKind == JsonValueKind.String)
            name = nameElement.GetString() ?? String.Empty;
        string currentPath = String.IsNullOrEmpty(name)
            ? parentPath
            : (String.IsNullOrEmpty(parentPath) ? name : parentPath + "/" + name);
        if (String.Equals(name, requestedName, StringComparison.Ordinal))
        {
            JsonElement nodePath;
            if (element.TryGetProperty("nodePath", out nodePath) && nodePath.ValueKind == JsonValueKind.String)
                currentPath = nodePath.GetString() ?? currentPath;
            bool? active = ReadBoolean(element, "active");
            if (!active.HasValue) active = ReadBoolean(element, "visible");
            matches.Add(new UnityMigrationJsonNodeMatch { Path = currentPath, Active = active });
        }

        JsonElement root;
        if (element.TryGetProperty("root", out root))
            Visit(root, currentPath, requestedName, matches);
        JsonElement children;
        if (element.TryGetProperty("children", out children))
            Visit(children, currentPath, requestedName, matches);
    }

    private static bool? ReadBoolean(JsonElement element, string propertyName)
    {
        JsonElement value;
        if (!element.TryGetProperty(propertyName, out value)) return null;
        if (value.ValueKind == JsonValueKind.True) return true;
        if (value.ValueKind == JsonValueKind.False) return false;
        return null;
    }
}
'@
    }
    return @([UnityMigrationJsonNodeQuery]::Find($resolved, $Name))
}

function Get-UnityMigrationComputerUseRestartDisposition {
    param(
        [Parameter(Mandatory = $true)][string]$ErrorMessage,
        [Parameter(Mandatory = $true)][ValidateRange(1, 10)][int]$Attempt,
        [Parameter(Mandatory = $true)][bool]$RuntimeWasVerifiedStopped
    )
    if ($RuntimeWasVerifiedStopped -and $Attempt -eq 1 -and
        $ErrorMessage -match '(?i)transport closed|connection closed') {
        return 'RetryOnceAfterVerifiedCleanup'
    }
    return 'Fail'
}

function Get-UnityMigrationWorkflowPolicyFailures {
    param([Parameter(Mandatory = $true)]$Policy)
    $failures = New-Object System.Collections.Generic.List[string]
    if ([int](Get-UnityMigrationPropertyValue -Object $Policy -Name "version" -Default 0) -ne 1) {
        $failures.Add("workflowPolicy.version must be 1.")
    }
    $cocos = Get-UnityMigrationPropertyValue -Object $Policy -Name "cocos" -Default $null
    $unity = Get-UnityMigrationPropertyValue -Object $Policy -Name "unity" -Default $null
    $sequence = Get-UnityMigrationPropertyValue -Object $Policy -Name "sequence" -Default $null
    $iteration = Get-UnityMigrationPropertyValue -Object $Policy -Name "iteration" -Default $null
    $expectedStrings = @(
        @($cocos, "tool", "computer-use@openai-bundled"),
        @($cocos, "requestedAppReference", "plugin://computer-use@openai-bundled?app=com.adspower.global"),
        @($cocos, "targetProcess", "ProjectX.exe"),
        @($cocos, "targetWindow", "Cocos Simulator"),
        @($cocos, "mode", "observe-one-action-refresh-then-diagnose"),
        @($cocos, "approvalMode", "routine-project-actions-preapproved"),
        @($cocos, "ledgerWriter", "tools/unity-migration/Update-UnityMigrationOperationLedger.ps1"),
        @($cocos, "evidenceLifecycleTool", "tools/unity-migration/Invoke-UnityMigrationCocosEvidence.ps1"),
        @($cocos, "standardClientCrop", "1,26,1334,750,no-scale"),
        @($unity, "standardRunner", "tools/unity-migration/Run-UnityModuleValidation.ps1"),
        @($unity, "fixedAccountRunner", "tools/unity-migration/Run-UnityFixedAccountValidation.ps1"),
        @($unity, "runtimeValidationMode", "batch-only"),
        @($unity, "mcpScope", "g3-editor-inspection-only"),
        @($iteration, "operationLedgerPattern", ".local/unity-validation/{module}-operation-ledger.json"),
        @($iteration, "retrospectivePattern", ".local/unity-validation/{module}-retrospective-latest.json")
    )
    foreach ($rule in $expectedStrings) {
        if ([string](Get-UnityMigrationPropertyValue -Object $rule[0] -Name $rule[1] -Default "") -ne $rule[2]) {
            $failures.Add("workflowPolicy $($rule[1]) must be '$($rule[2])'.")
        }
    }
    if ([int](Get-UnityMigrationPropertyValue -Object $cocos -Name "maximumAttemptsPerTarget" -Default 0) -ne 1) {
        $failures.Add("workflowPolicy cocos.maximumAttemptsPerTarget must be 1.")
    }
    foreach ($rule in @(
        @($cocos, "requireAutomationLedger"),
        @($cocos, "forbidDesktopCapture"),
        @($cocos, "forbidHistoricalEvidence"),
        @($cocos, "forbidPowerShellUiAutomationMix"),
        @($cocos, "routineActionsPreapproved"),
        @($cocos, "highRiskConfirmationsRemain"),
        @($cocos, "requireTransportPreflightBeforeServices"),
        @($cocos, "requireFixedIdentityBeforeCapture"),
        @($cocos, "freezeReusableG1Baseline"),
        @($unity, "requireRegisteredArtifactsBeforeG3"),
        @($unity, "requireDataPreflightBeforeFullRun"),
        @($sequence, "requireCurrentCocosBeforeG2"),
        @($sequence, "requireSourceContractsBeforeG3"),
        @($sequence, "requireEarlyUserPlayAfterG3BeforeG4"),
        @($sequence, "requireControlCoverageBeforeG4"),
        @($sequence, "requireG5ContractBeforeFullRun"),
        @($sequence, "visualReplayIsNotG5Evidence"),
        @($sequence, "requireTwoBuildBatchRunsForG6"),
        @($sequence, "reuseG1CocosAtG5ByDefault"),
        @($sequence, "recaptureOnlyInvalidatedCocosStates"),
        @($iteration, "recordEveryFailure"),
        @($iteration, "requireFailureRootCause"),
        @($iteration, "requireEarlyFeedbackResolutionBeforeG4"),
        @($iteration, "requireResolutionAndIterationEvidenceBeforeG6"),
        @($iteration, "autoSummarizeAtG6"),
        @($iteration, "requireToolchainTestForPolicyIteration"),
        @($iteration, "requireFileBackedEvidenceAtResolution"),
        @($iteration, "retrospectiveUsesEffectiveRootCause")
    )) {
        $value = Get-UnityMigrationPropertyValue -Object $rule[0] -Name $rule[1] -Default $null
        if ($value -isnot [bool] -or -not $value) {
            $failures.Add("workflowPolicy $($rule[1]) must be boolean true.")
        }
    }
    return @($failures)
}

function Get-UnityMigrationEarlyUserPlayFailures {
    param(
        [Parameter(Mandatory = $true)]$Record,
        [Parameter(Mandatory = $true)][string]$ExpectedModule
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ([int](Get-UnityMigrationPropertyValue -Object $Record -Name "schemaVersion" -Default 0) -ne 1) {
        $failures.Add("early user Play schemaVersion must be 1.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Record -Name "module" -Default "") -ine $ExpectedModule) {
        $failures.Add("early user Play module must be '$ExpectedModule'.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Record -Name "checkpoint" -Default "") -ne "post-g3-early-play") {
        $failures.Add("early user Play checkpoint must be 'post-g3-early-play'.")
    }
    if ((Get-UnityMigrationPropertyValue -Object $Record -Name "userParticipated" -Default $false) -ne $true) {
        $failures.Add("early user Play must record explicit user participation.")
    }
    $testedUtc = [string](Get-UnityMigrationPropertyValue -Object $Record -Name "testedUtc" -Default "")
    $parsedUtc = [DateTime]::MinValue
    if (-not [DateTime]::TryParse($testedUtc, [ref]$parsedUtc)) {
        $failures.Add("early user Play testedUtc must be a valid timestamp.")
    }
    if (-not [string](Get-UnityMigrationPropertyValue -Object $Record -Name "entryPath" -Default "")) {
        $failures.Add("early user Play entryPath is required.")
    }
    $result = [string](Get-UnityMigrationPropertyValue -Object $Record -Name "result" -Default "")
    if ($result -notin @("passed-no-blockers", "feedback-captured")) {
        $failures.Add("early user Play result must be passed-no-blockers or feedback-captured.")
    }
    foreach ($feedback in @(Get-UnityMigrationPropertyValue -Object $Record -Name "feedback" -Default @())) {
        $id = [string](Get-UnityMigrationPropertyValue -Object $feedback -Name "id" -Default "")
        $summary = [string](Get-UnityMigrationPropertyValue -Object $feedback -Name "summary" -Default "")
        $severity = [string](Get-UnityMigrationPropertyValue -Object $feedback -Name "severity" -Default "")
        $status = [string](Get-UnityMigrationPropertyValue -Object $feedback -Name "status" -Default "")
        if (-not $id -or -not $summary) { $failures.Add("early user Play feedback requires id and summary.") }
        if ($severity -notin @("blocking", "non-blocking")) {
            $failures.Add("early user Play feedback '$id' has invalid severity '$severity'.")
        }
        if ($status -notin @("resolved", "accepted")) {
            $failures.Add("early user Play feedback '$id' remains unresolved: status='$status'.")
        }
        if ($severity -eq "blocking" -and $status -ne "resolved") {
            $failures.Add("early user Play blocking feedback '$id' must be resolved before G4.")
        }
    }
    $agentRecheck = Get-UnityMigrationPropertyValue -Object $Record -Name "agentRecheck" -Default $null
    if ($null -eq $agentRecheck -or
        (Get-UnityMigrationPropertyValue -Object $agentRecheck -Name "completed" -Default $false) -ne $true -or
        @(Get-UnityMigrationPropertyValue -Object $agentRecheck -Name "evidence" -Default @()).Count -eq 0) {
        $failures.Add("early user Play requires completed agentRecheck with file-backed evidence.")
    }
    return @($failures)
}

function Assert-UnityMigrationWorkflowPolicy {
    param([Parameter(Mandatory = $true)][string]$Root)
    $entry = Import-UnityMigrationJson -Root $Root -Path "tools/unity-migration/validation-scenarios.json"
    $policy = Get-UnityMigrationPropertyValue -Object $entry.Value -Name "workflowPolicy" -Default $null
    if ($null -eq $policy) { throw "Validation scenario registry has no workflowPolicy." }
    $failures = @(Get-UnityMigrationWorkflowPolicyFailures -Policy $policy)
    if ($failures.Count -gt 0) { throw "Unity migration workflow policy is invalid: $($failures -join '; ')" }
    return $policy
}

function Get-UnityMigrationCocosAutomationLedgerFailures {
    param(
        [Parameter(Mandatory = $true)]$Ledger,
        [Parameter(Mandatory = $true)][string]$ExpectedModule,
        [string]$Root = "",
        [switch]$RequireFiles
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ([int](Get-UnityMigrationPropertyValue -Object $Ledger -Name "schemaVersion" -Default 0) -ne 1) {
        $failures.Add("Cocos automation ledger schemaVersion must be 1.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Ledger -Name "module" -Default "") -ine $ExpectedModule) {
        $failures.Add("Cocos automation ledger module mismatch.")
    }
    if ([int](Get-UnityMigrationPropertyValue -Object $Ledger -Name "workflowPolicyVersion" -Default 0) -ne 1) {
        $failures.Add("Cocos automation ledger workflowPolicyVersion must be 1.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Ledger -Name "tool" -Default "") -ne
        "computer-use@openai-bundled") {
        $failures.Add("Cocos automation ledger must be produced by computer-use@openai-bundled.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Ledger -Name "targetProcess" -Default "") -ne
        "ProjectX.exe") {
        $failures.Add("Cocos automation ledger targetProcess must be ProjectX.exe.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Ledger -Name "targetWindow" -Default "") -notlike
        "*Cocos Simulator*") {
        $failures.Add("Cocos automation ledger targetWindow must identify Cocos Simulator.")
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Ledger -Name "approvalMode" -Default "") -ne
        "routine-project-actions-preapproved") {
        $failures.Add("Cocos automation ledger must record routine-project-actions-preapproved.")
    }
    $attempts = @((Get-UnityMigrationPropertyValue -Object $Ledger -Name "attempts" -Default @()))
    if ($attempts.Count -eq 0) { $failures.Add("Cocos automation ledger has no attempts.") }
    $targetIds = New-Object System.Collections.Generic.List[string]
    $capturePaths = New-Object System.Collections.Generic.List[string]
    foreach ($attempt in $attempts) {
        $targetId = [string](Get-UnityMigrationPropertyValue -Object $attempt -Name "targetId" -Default "")
        if (-not $targetId) { $failures.Add("Cocos automation attempt has no targetId."); continue }
        $targetIds.Add($targetId)
        if ([int](Get-UnityMigrationPropertyValue -Object $attempt -Name "attemptNumber" -Default 0) -ne 1) {
            $failures.Add("Cocos target '$targetId' was attempted more than once.")
        }
        if ([bool](Get-UnityMigrationPropertyValue -Object $attempt -Name "desktopCapture" -Default $true)) {
            $failures.Add("Cocos target '$targetId' used a desktop capture instead of the game window.")
        }
        $capturePath = [string](Get-UnityMigrationPropertyValue -Object $attempt -Name "capturePath" -Default "")
        if (-not $capturePath) {
            $failures.Add("Cocos target '$targetId' has no window capture.")
        }
        else { $capturePaths.Add($capturePath) }
        if ([int](Get-UnityMigrationPropertyValue -Object $attempt -Name "width" -Default 0) -ne 1334 -or
            [int](Get-UnityMigrationPropertyValue -Object $attempt -Name "height" -Default 0) -ne 750) {
            $failures.Add("Cocos target '$targetId' capture must be 1334x750.")
        }
        if ($RequireFiles -and $capturePath) {
            if (-not $Root) { throw "-RequireFiles requires -Root." }
            $resolved = Resolve-UnityMigrationPath -Root $Root -Path $capturePath
            if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                $failures.Add("Cocos target '$targetId' capture is missing: $capturePath")
            }
        }
    }
    if (@($targetIds | Sort-Object -Unique).Count -ne $targetIds.Count) {
        $failures.Add("Cocos automation ledger contains repeated target ids.")
    }
    if (@($capturePaths | Sort-Object -Unique).Count -ne $capturePaths.Count) {
        $failures.Add("Cocos automation ledger reuses a capture path across targets.")
    }
    return @($failures)
}

function Assert-UnityMigrationCocosAutomationLedger {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $failures = @(Get-UnityMigrationCocosAutomationLedgerFailures -Ledger $entry.Value `
        -ExpectedModule $Module -Root $Root -RequireFiles)
    if ($failures.Count -gt 0) { throw "Cocos automation ledger is invalid: $($failures -join '; ')" }
    return @($entry.Value.attempts).Count
}

function Get-UnityMigrationOperationLedgerPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module
    )
    return Join-Path $Root ".local/unity-validation/$($Module.ToLowerInvariant())-operation-ledger.json"
}

function Get-UnityMigrationVerifiedEvidenceFiles {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$References
    )
    $verified = New-Object System.Collections.Generic.List[string]
    foreach ($evidencePath in @($References)) {
        $reference = [string]$evidencePath
        $candidates = @($reference)
        if ($reference -match '^(?<path>.+):\d+(?:-\d+)?$') {
            $candidates = @([string]$Matches.path, $reference)
        }
        foreach ($candidate in $candidates) {
            $resolved = Resolve-UnityMigrationPath -Root $Root -Path $candidate
            if (Test-Path -LiteralPath $resolved -PathType Leaf) {
                $verified.Add($resolved)
                break
            }
        }
    }
    return @($verified)
}

function Add-UnityMigrationOperationRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][ValidatePattern('^G[0-6]$')][string]$Gate,
        [Parameter(Mandatory = $true)][string]$Tool,
        [Parameter(Mandatory = $true)][string]$Operation,
        [Parameter(Mandatory = $true)][ValidateSet("Passed", "Failed", "Blocked", "Resolved", "Supplemented")][string]$Outcome,
        [ValidateSet("General", "CocosAutomation", "UnityBatch", "Gate")][string]$Category = "General",
        [string]$ErrorMessage = "",
        [string]$RootCause = "",
        [string]$RelatedRecordId = "",
        [string]$Resolution = "",
        [string]$IterationAction = "",
        [string[]]$IterationEvidence = @(),
        [string[]]$Evidence = @(),
        [string]$TargetId = "",
        [string]$Path = ""
    )
    if ($Outcome -in @("Failed", "Blocked") -and (-not $ErrorMessage -or -not $RootCause)) {
        throw "$Outcome operation records require -ErrorMessage and -RootCause. Use pending-diagnosis until the cause is known."
    }
    if ($Outcome -eq "Resolved" -and
        (-not $RelatedRecordId -or -not $Resolution -or -not $IterationAction -or $IterationEvidence.Count -eq 0)) {
        throw "Resolved operation records require -RelatedRecordId, -Resolution, -IterationAction and -IterationEvidence."
    }
    if ($Outcome -eq "Supplemented" -and
        (-not $RelatedRecordId -or -not $Resolution -or -not $IterationAction -or $IterationEvidence.Count -eq 0)) {
        throw "Supplemented operation records require -RelatedRecordId, -Resolution, -IterationAction and -IterationEvidence."
    }
    if ($Outcome -in @("Resolved", "Supplemented")) {
        $verifiedEvidence = @(Get-UnityMigrationVerifiedEvidenceFiles -Root $Root -References $IterationEvidence)
        if ($verifiedEvidence.Count -ne $IterationEvidence.Count) {
            throw "$Outcome operation records require every -IterationEvidence item to resolve to an existing file. Text-only evidence must be written to a durable artifact first."
        }
    }
    if (-not $Path) { $Path = Get-UnityMigrationOperationLedgerPath -Root $Root -Module $Module }
    $resolvedPath = Resolve-UnityMigrationPath -Root $Root -Path $Path
    if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
        $ledger = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolvedPath | ConvertFrom-Json
        if ([int](Get-UnityMigrationPropertyValue -Object $ledger -Name "schemaVersion" -Default 0) -ne 1 -or
            [string](Get-UnityMigrationPropertyValue -Object $ledger -Name "module" -Default "") -ine $Module) {
            throw "Operation ledger identity is invalid: $resolvedPath"
        }
    }
    else {
        $ledger = [pscustomobject][ordered]@{
            schemaVersion = 1
            module = $Module
            workflowPolicyVersion = 1
            records = @()
        }
    }
    if ($Outcome -eq "Resolved") {
        $related = @($ledger.records | Where-Object { [string]$_.recordId -eq $RelatedRecordId })
        if ($related.Count -ne 1 -or [string]$related[0].outcome -notin @("Failed", "Blocked")) {
            throw "Resolved record references no unique Failed/Blocked record: $RelatedRecordId"
        }
        if (@($ledger.records | Where-Object {
            [string]$_.outcome -eq "Resolved" -and [string]$_.relatedRecordId -eq $RelatedRecordId
        }).Count -gt 0) {
            throw "Failure '$RelatedRecordId' already has a resolution record."
        }
    }
    if ($Outcome -eq "Supplemented") {
        $related = @($ledger.records | Where-Object { [string]$_.recordId -eq $RelatedRecordId })
        if ($related.Count -ne 1 -or [string]$related[0].outcome -notin @("Failed", "Blocked")) {
            throw "Supplemented record references no unique Failed/Blocked record: $RelatedRecordId"
        }
        if (@($ledger.records | Where-Object {
            [string]$_.outcome -eq "Resolved" -and [string]$_.relatedRecordId -eq $RelatedRecordId
        }).Count -ne 1) {
            throw "Failure '$RelatedRecordId' must have one unique resolution before evidence can be supplemented."
        }
        if (@($ledger.records | Where-Object {
            [string]$_.outcome -eq "Supplemented" -and [string]$_.relatedRecordId -eq $RelatedRecordId
        }).Count -gt 0) {
            throw "Failure '$RelatedRecordId' already has a retrospective supplement record."
        }
    }
    $recordId = ([Guid]::NewGuid().ToString("N"))
    $record = [pscustomobject][ordered]@{
        recordId = $recordId
        timestampUtc = [DateTime]::UtcNow.ToString("O")
        gate = $Gate
        category = $Category
        tool = $Tool
        operation = $Operation
        targetId = $TargetId
        outcome = $Outcome
        error = $ErrorMessage
        rootCause = $RootCause
        relatedRecordId = $RelatedRecordId
        resolution = $Resolution
        iterationAction = $IterationAction
        iterationEvidence = @($IterationEvidence)
        evidence = @($Evidence)
    }
    $ledger.records = @($ledger.records) + @($record)
    $ledger | Add-Member -Force -NotePropertyName updatedUtc -NotePropertyValue $record.timestampUtc
    Write-UnityMigrationUtf8 -Path $resolvedPath -Content (($ledger | ConvertTo-Json -Depth 12) + "`n")
    return [pscustomobject]@{ Path = $resolvedPath; Record = $record; Ledger = $ledger }
}

function Get-UnityMigrationRetrospectiveFailures {
    param(
        [Parameter(Mandatory = $true)]$Ledger,
        [string]$Root = "",
        [switch]$RequireEvidenceFiles
    )
    $failures = New-Object System.Collections.Generic.List[string]
    $records = @((Get-UnityMigrationPropertyValue -Object $Ledger -Name "records" -Default @()))
    foreach ($failed in @($records | Where-Object { [string]$_.outcome -in @("Failed", "Blocked") })) {
        $id = [string]$failed.recordId
        $resolved = @($records | Where-Object {
            [string]$_.outcome -eq "Resolved" -and [string]$_.relatedRecordId -eq $id
        })
        $supplements = @($records | Where-Object {
            [string]$_.outcome -eq "Supplemented" -and [string]$_.relatedRecordId -eq $id
        })
        $recordRootCause = [string](Get-UnityMigrationPropertyValue -Object $failed -Name "rootCause" -Default "")
        $resolvedDiagnosis = if ($resolved.Count -eq 1) {
            [string](Get-UnityMigrationPropertyValue -Object $resolved[0] -Name "resolution" -Default "")
        } else { "" }
        if (-not [string](Get-UnityMigrationPropertyValue -Object $failed -Name "error" -Default "") -or
            ((-not $recordRootCause -or $recordRootCause -eq "pending-diagnosis") -and -not $resolvedDiagnosis)) {
            $failures.Add("Failure '$id' has no diagnosed root cause.")
        }
        if ($resolved.Count -ne 1) {
            $failures.Add("Failure '$id' has no unique resolution and iteration record.")
            continue
        }
        if ($supplements.Count -gt 1) {
            $failures.Add("Failure '$id' has more than one retrospective supplement record.")
            continue
        }
        $item = $resolved[0]
        $evidenceReferences = @($item.iterationEvidence)
        if ($supplements.Count -eq 1) {
            $evidenceReferences = @($evidenceReferences) + @($supplements[0].iterationEvidence)
        }
        if (-not [string]$item.resolution -or -not [string]$item.iterationAction -or $evidenceReferences.Count -eq 0) {
            $failures.Add("Failure '$id' resolution is missing resolution, iterationAction or iterationEvidence.")
        }
        if ($RequireEvidenceFiles) {
            if (-not $Root) { throw "-RequireEvidenceFiles requires -Root." }
            $verifiedEvidenceFiles = @(Get-UnityMigrationVerifiedEvidenceFiles -Root $Root -References $evidenceReferences)
            if ($verifiedEvidenceFiles.Count -eq 0) {
                $failures.Add("Failure '$id' has no verifiable iteration evidence file.")
            }
        }
    }
    return @($failures)
}

function Get-UnityMigrationEffectiveRootCause {
    param(
        [Parameter(Mandatory = $true)]$FailedRecord,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$ResolutionRecords
    )
    $recordRootCause = [string](Get-UnityMigrationPropertyValue -Object $FailedRecord -Name "rootCause" -Default "")
    $resolved = @($ResolutionRecords | Where-Object {
        [string]$_.relatedRecordId -eq [string]$FailedRecord.recordId
    })
    if (($recordRootCause -eq "pending-diagnosis" -or -not $recordRootCause) -and
        $resolved.Count -eq 1 -and [string]$resolved[0].resolution) {
        return [string]$resolved[0].resolution
    }
    return $recordRootCause
}

function Get-UnityMigrationOperationResolutionAudit {
    param(
        [Parameter(Mandatory = $true)]$Ledger,
        [string[]]$RecordIds = @()
    )
    $records = @((Get-UnityMigrationPropertyValue -Object $Ledger -Name "records" -Default @()))
    $requestedIds = @($RecordIds | Where-Object { [string]$_ } | Sort-Object -Unique)
    $failedRecords = @($records | Where-Object { [string]$_.outcome -in @("Failed", "Blocked") })
    if ($requestedIds.Count -gt 0) {
        $failedRecords = @($failedRecords | Where-Object { [string]$_.recordId -in $requestedIds })
    }
    $rows = foreach ($failed in $failedRecords) {
        $id = [string]$failed.recordId
        $resolved = @($records | Where-Object {
            [string]$_.outcome -eq "Resolved" -and [string]$_.relatedRecordId -eq $id
        })
        [pscustomobject][ordered]@{
            recordId = $id
            gate = [string](Get-UnityMigrationPropertyValue -Object $failed -Name "gate" -Default "")
            operation = [string](Get-UnityMigrationPropertyValue -Object $failed -Name "operation" -Default "")
            error = [string](Get-UnityMigrationPropertyValue -Object $failed -Name "error" -Default "")
            rootCause = [string](Get-UnityMigrationPropertyValue -Object $failed -Name "rootCause" -Default "")
            resolutionCount = $resolved.Count
            resolution = if ($resolved.Count -eq 1) {
                [string](Get-UnityMigrationPropertyValue -Object $resolved[0] -Name "resolution" -Default "")
            } else { "" }
            iterationAction = if ($resolved.Count -eq 1) {
                [string](Get-UnityMigrationPropertyValue -Object $resolved[0] -Name "iterationAction" -Default "")
            } else { "" }
            iterationEvidence = if ($resolved.Count -eq 1) {
                @((Get-UnityMigrationPropertyValue -Object $resolved[0] -Name "iterationEvidence" -Default @()))
            } else { @() }
        }
    }
    return @($rows)
}

function Get-UnityMigrationValidationResultSummaries {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$ResultPaths
    )
    $paths = @($ResultPaths | Where-Object { [string]$_ })
    if ($paths.Count -eq 0) { throw "At least one validation result path is required." }
    $rows = foreach ($path in $paths) {
        $resolved = Resolve-UnityMigrationPath -Root $Root -Path $path
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw "Validation result is missing: $path"
        }
        $result = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json
        $semanticAssertions = @(Get-UnityMigrationPropertyValue -Object $result -Name "semanticAssertions" -Default @())
        $passedSemanticAssertions = @(Get-UnityMigrationPropertyValue -Object $result -Name "passedSemanticAssertions" -Default @())
        $failedSemanticAssertions = @(Get-UnityMigrationPropertyValue -Object $result -Name "failedSemanticAssertions" -Default @())
        $semanticAssertionCount = if ($semanticAssertions.Count -gt 0) {
            $semanticAssertions.Count
        } else {
            $passedSemanticAssertions.Count + $failedSemanticAssertions.Count
        }
        $failedSemanticAssertionCount = if ($semanticAssertions.Count -gt 0) {
            @($semanticAssertions | Where-Object {
                -not [bool](Get-UnityMigrationPropertyValue -Object $_ -Name "passed" -Default $false)
            }).Count
        } else {
            $failedSemanticAssertions.Count
        }
        [pscustomobject][ordered]@{
            path = [IO.Path]::GetRelativePath($Root, $resolved).Replace('\', '/')
            success = [bool](Get-UnityMigrationPropertyValue -Object $result -Name "success" -Default $false)
            validatedControlCount = @((Get-UnityMigrationPropertyValue -Object $result -Name "validatedControlIds" -Default @())).Count
            semanticAssertionCount = $semanticAssertionCount
            failedSemanticAssertionCount = $failedSemanticAssertionCount
            screenshotCount = @((Get-UnityMigrationPropertyValue -Object $result -Name "screenshots" -Default @())).Count
            seriousErrorCount = [int](Get-UnityMigrationPropertyValue -Object $result -Name "seriousErrorCount" -Default 0)
            fixtureResidualCount = [int](Get-UnityMigrationPropertyValue -Object $result -Name "fixtureResidualCount" -Default 0)
            message = [string](Get-UnityMigrationPropertyValue -Object $result -Name "message" -Default "")
        }
    }
    return @($rows)
}

function New-UnityMigrationRetrospective {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [switch]$RequireEvidenceFiles
    )
    $ledgerPath = Get-UnityMigrationOperationLedgerPath -Root $Root -Module $Module
    if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
        $ledger = Get-Content -Raw -Encoding UTF8 -LiteralPath $ledgerPath | ConvertFrom-Json
    }
    else {
        $ledger = [pscustomobject][ordered]@{
            schemaVersion = 1; module = $Module; workflowPolicyVersion = 1; records = @()
        }
    }
    $records = @($ledger.records)
    $unresolved = @(Get-UnityMigrationRetrospectiveFailures -Ledger $ledger -Root $Root `
        -RequireEvidenceFiles:$RequireEvidenceFiles)
    $failedRecords = @($records | Where-Object { [string]$_.outcome -in @("Failed", "Blocked") })
    $resolutionRecords = @($records | Where-Object { [string]$_.outcome -eq "Resolved" })
    $supplementRecords = @($records | Where-Object { [string]$_.outcome -eq "Supplemented" })
    $failureRows = @($failedRecords | ForEach-Object {
        $failed = $_
        $recordRootCause = [string](Get-UnityMigrationPropertyValue -Object $failed -Name "rootCause" -Default "")
        $effectiveRootCause = Get-UnityMigrationEffectiveRootCause -FailedRecord $failed -ResolutionRecords $resolutionRecords
        [pscustomobject]@{
            recordId = [string]$failed.recordId
            rootCause = $recordRootCause
            effectiveRootCause = $effectiveRootCause
        }
    })
    $summary = [pscustomobject][ordered]@{
        schemaVersion = 1
        module = $Module
        operationLedger = [IO.Path]::GetRelativePath($Root, $ledgerPath).Replace('\', '/')
        operationCount = $records.Count
        passedCount = @($records | Where-Object { [string]$_.outcome -eq "Passed" }).Count
        failedOrBlockedCount = $failedRecords.Count
        resolvedCount = $resolutionRecords.Count
        supplementedCount = $supplementRecords.Count
        pendingDiagnosisCount = @($failureRows | Where-Object {
            -not [string]$_.effectiveRootCause -or [string]$_.effectiveRootCause -eq "pending-diagnosis"
        }).Count
        unresolvedCount = $unresolved.Count
        unresolved = @($unresolved)
        failureGroups = @($failureRows | Group-Object effectiveRootCause | ForEach-Object {
            [pscustomobject]@{ rootCause = $_.Name; count = $_.Count; recordIds = @($_.Group.recordId) }
        })
        iterations = @($resolutionRecords | ForEach-Object {
            [pscustomobject]@{
                relatedRecordId = $_.relatedRecordId
                resolution = $_.resolution
                action = $_.iterationAction
                evidence = @($_.iterationEvidence)
            }
        })
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    $summaryPath = Join-Path $Root ".local/unity-validation/$($Module.ToLowerInvariant())-retrospective-latest.json"
    Write-UnityMigrationUtf8 -Path $summaryPath -Content (($summary | ConvertTo-Json -Depth 12) + "`n")
    return [pscustomobject]@{ Path = $summaryPath; Summary = $summary }
}

function Get-UnityMigrationBatchSummaryFailures {
    param(
        [Parameter(Mandatory = $true)]$Summary,
        [Parameter(Mandatory = $true)]$Policy
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ([string](Get-UnityMigrationPropertyValue -Object $Summary -Name "executionMode" -Default "") -ne "batch") {
        $failures.Add("validation summary executionMode must be batch")
    }
    $runner = [string](Get-UnityMigrationPropertyValue -Object $Summary -Name "runner" -Default "")
    $allowed = @([string]$Policy.unity.standardRunner, [string]$Policy.unity.fixedAccountRunner)
    if ($runner -notin $allowed) { $failures.Add("validation summary runner is not canonical: $runner") }
    if ([int](Get-UnityMigrationPropertyValue -Object $Summary -Name "workflowPolicyVersion" -Default 0) -ne
        [int]$Policy.version) {
        $failures.Add("validation summary workflowPolicyVersion mismatch")
    }
    return @($failures)
}

function Expand-UnityMigrationCoverageIds {
    param([Parameter(Mandatory = $true)]$Container)
    $ids = New-Object System.Collections.Generic.List[string]
    foreach ($id in @((Get-UnityMigrationPropertyValue -Object $Container -Name "businessIds" -Default @()))) {
        $value = [string]$id
        if (-not $value) { throw "Coverage businessIds contains an empty value." }
        $ids.Add($value)
    }
    foreach ($range in @((Get-UnityMigrationPropertyValue -Object $Container -Name "businessIdRanges" -Default @()))) {
        $start = [int](Get-UnityMigrationPropertyValue -Object $range -Name "start" -Default 0)
        $end = [int](Get-UnityMigrationPropertyValue -Object $range -Name "end" -Default -1)
        $prefix = [string](Get-UnityMigrationPropertyValue -Object $range -Name "prefix" -Default "")
        if ($start -gt $end) { throw "Coverage businessIdRanges contains an invalid range $start..$end." }
        for ($value = $start; $value -le $end; $value++) { $ids.Add("$prefix$value") }
    }
    return @($ids)
}

function Assert-UnityMigrationCoverageList {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ModuleKey,
        [Parameter(Mandatory = $true)]$Matrix
    )
    $coveragePath = [string](Get-UnityMigrationPropertyValue -Object $Matrix -Name "coverageList" -Default "")
    if (-not $coveragePath) { throw "Module '$ModuleKey' control matrix has no coverageList." }
    $coverage = (Import-UnityMigrationJson -Root $Root -Path $coveragePath).Value
    if ([int](Get-UnityMigrationPropertyValue -Object $coverage -Name "schemaVersion" -Default 0) -ne 1 -or
        [string](Get-UnityMigrationPropertyValue -Object $coverage -Name "module" -Default "") -ine $ModuleKey) {
        throw "Invalid coverage list identity: $coveragePath"
    }
    $scenarioIds = @($coverage.scenarios | ForEach-Object { [string]$_.id })
    if ($scenarioIds.Count -eq 0 -or @($scenarioIds | Sort-Object -Unique).Count -ne $scenarioIds.Count) {
        throw "Coverage list must declare unique scenario ids: $coveragePath"
    }
    $sourceIds = New-Object System.Collections.Generic.List[string]
    $businessCount = 0
    foreach ($source in @($coverage.sources)) {
        $sourceId = [string](Get-UnityMigrationPropertyValue -Object $source -Name "id" -Default "")
        if (-not $sourceId -or $sourceIds.Contains($sourceId)) { throw "Coverage list has an empty or duplicate source id." }
        $sourceIds.Add($sourceId)
        if (-not [string](Get-UnityMigrationPropertyValue -Object $source -Name "branchType" -Default "")) {
            throw "Coverage source '$sourceId' has no branchType."
        }
        $sourceFiles = @((Get-UnityMigrationPropertyValue -Object $source -Name "sourceFiles" -Default @()))
        if ($sourceFiles.Count -eq 0) { throw "Coverage source '$sourceId' has no sourceFiles." }
        foreach ($sourceFile in $sourceFiles) {
            $resolved = Resolve-UnityMigrationPath -Root $Root -Path ([string]$sourceFile)
            if (-not (Test-Path -LiteralPath $resolved)) { throw "Coverage source '$sourceId' file is missing: $sourceFile" }
        }
        $ids = @(Expand-UnityMigrationCoverageIds -Container $source)
        $uniqueIds = @($ids | Sort-Object -Unique)
        if ($ids.Count -eq 0 -or $uniqueIds.Count -ne $ids.Count) {
            throw "Coverage source '$sourceId' has no business ids or contains duplicates."
        }
        if ([int](Get-UnityMigrationPropertyValue -Object $source -Name "recordTotal" -Default -1) -ne $ids.Count) {
            throw "Coverage source '$sourceId' recordTotal does not match its $($ids.Count) business ids."
        }
        $mapped = New-Object System.Collections.Generic.List[string]
        foreach ($mapping in @($source.mappings)) {
            $mappingIds = @(Expand-UnityMigrationCoverageIds -Container $mapping)
            if ($mappingIds.Count -eq 0) { throw "Coverage source '$sourceId' contains an empty mapping." }
            $success = @((Get-UnityMigrationPropertyValue -Object $mapping -Name "successScenarioIds" -Default @()))
            $failure = @((Get-UnityMigrationPropertyValue -Object $mapping -Name "failureBoundaryScenarioIds" -Default @()))
            if ($success.Count -eq 0 -or $failure.Count -eq 0) {
                throw "Coverage source '$sourceId' mapping requires success and failure/boundary scenarios."
            }
            foreach ($scenarioId in @($success + $failure)) {
                if ([string]$scenarioId -notin $scenarioIds) {
                    throw "Coverage source '$sourceId' references unknown scenario '$scenarioId'."
                }
            }
            foreach ($mappingId in $mappingIds) {
                if ([string]$mappingId -notin $uniqueIds) {
                    throw "Coverage source '$sourceId' maps unknown business id '$mappingId'."
                }
                $mapped.Add([string]$mappingId)
            }
        }
        if (@($mapped | Sort-Object -Unique).Count -ne $mapped.Count) {
            throw "Coverage source '$sourceId' maps one or more business ids more than once."
        }
        $excludedIds = New-Object System.Collections.Generic.List[string]
        foreach ($excluded in @((Get-UnityMigrationPropertyValue -Object $source -Name "excluded" -Default @()))) {
            if (-not [string]$excluded.productEvidence) {
                throw "Coverage source '$sourceId' exclusion requires productEvidence."
            }
            foreach ($excludedId in @(Expand-UnityMigrationCoverageIds -Container $excluded)) {
                if ([string]$excludedId -notin $uniqueIds) {
                    throw "Coverage source '$sourceId' excludes unknown business id '$excludedId'."
                }
                $excludedIds.Add([string]$excludedId)
            }
        }
        if (@($excludedIds | Sort-Object -Unique).Count -ne $excludedIds.Count -or
            @($excludedIds | Where-Object { $_ -in $mapped }).Count -gt 0) {
            throw "Coverage source '$sourceId' has duplicate exclusions or maps an excluded business id."
        }
        $uncovered = @($uniqueIds | Where-Object { $_ -notin $mapped -and $_ -notin $excludedIds })
        if ($uncovered.Count -gt 0) {
            throw "Coverage source '$sourceId' has uncovered business ids: $($uncovered -join ',')."
        }
        $businessCount += $ids.Count
    }
    if ($sourceIds.Count -eq 0) { throw "Coverage list has no sources: $coveragePath" }
    return [pscustomobject]@{ SourceCount = $sourceIds.Count; BusinessIdCount = $businessCount; Path = $coveragePath }
}

function Assert-UnityMigrationModuleWorkflowContract {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$ModuleConfig,
        [Parameter(Mandatory = $true)]$Scenario,
        [ValidateSet("G0", "G3")][string]$Phase = "G0"
    )
    $policy = Assert-UnityMigrationWorkflowPolicy -Root $Root
    $matrixPath = [string](Get-UnityMigrationPropertyValue -Object $ModuleConfig -Name "controlMatrix" -Default "")
    if (-not $matrixPath) { throw "Module '$($ModuleConfig.key)' has no controlMatrix for workflow policy." }
    $matrix = (Import-UnityMigrationJson -Root $Root -Path $matrixPath).Value
    if ([int](Get-UnityMigrationPropertyValue -Object $matrix -Name "workflowPolicyVersion" -Default 0) -ne
        [int]$policy.version) {
        throw "Module '$($ModuleConfig.key)' control matrix does not freeze workflowPolicyVersion $($policy.version)."
    }
    $examples = @((Get-UnityMigrationPropertyValue -Object $matrix -Name "acceptanceExamples" -Default @()))
    if ($examples.Count -eq 0) {
        throw "Module '$($ModuleConfig.key)' control matrix has no concrete acceptanceExamples."
    }
    $exampleIds = New-Object System.Collections.Generic.List[string]
    foreach ($example in $examples) {
        foreach ($field in @("id", "given", "when", "then")) {
            if (-not [string](Get-UnityMigrationPropertyValue -Object $example -Name $field -Default "")) {
                throw "Module '$($ModuleConfig.key)' acceptance example is missing $field."
            }
        }
        $exampleIds.Add([string]$example.id)
    }
    if (@($exampleIds | Sort-Object -Unique).Count -ne $exampleIds.Count) {
        throw "Module '$($ModuleConfig.key)' acceptanceExamples contains duplicate ids."
    }
    $coveragePath = [string](Get-UnityMigrationPropertyValue -Object $matrix -Name "coverageList" -Default "")
    if ($Phase -eq "G0" -or $coveragePath) {
        Assert-UnityMigrationCoverageList -Root $Root -ModuleKey ([string]$ModuleConfig.key) -Matrix $matrix | Out-Null
    }
    if ($Phase -eq "G3") {
        if (-not [bool](Get-UnityMigrationPropertyValue -Object $Scenario -Name "controlCoverageRequired" -Default $false)) {
            throw "Module '$($ModuleConfig.key)' scenario must require runtime control coverage."
        }
        if (@((Get-UnityMigrationPropertyValue -Object $Scenario -Name "semanticAssertionKeys" -Default @())).Count -eq 0) {
            throw "Module '$($ModuleConfig.key)' scenario has no semantic assertions."
        }
        if (@((Get-UnityMigrationPropertyValue -Object $Scenario -Name "sourceContracts" -Default @())).Count -eq 0) {
            throw "Module '$($ModuleConfig.key)' scenario has no source contracts."
        }
        $visual = Get-UnityMigrationPropertyValue -Object $Scenario -Name "visualAssertions" -Default $null
        if ($null -eq $visual -or [int]$visual.width -ne 1334 -or [int]$visual.height -ne 750) {
            throw "Module '$($ModuleConfig.key)' scenario must freeze 1334x750 visual assertions."
        }
        if (@($Scenario.captureStates).Count -eq 0 -or @($Scenario.artifacts).Count -eq 0) {
            throw "Module '$($ModuleConfig.key)' scenario must register capture states and runtime artifacts before G3."
        }
        $contracts = (Import-UnityMigrationJson -Root $Root `
            -Path "tools/unity-migration/module-evidence-contracts.json").Value
        $matches = @($contracts.modules | Where-Object { $_.module -ieq ([string]$ModuleConfig.key) })
        if ($matches.Count -ne 1 -or $null -eq $matches[0].g5 -or @($matches[0].g5.pairs).Count -eq 0 -or
            [int]$matches[0].g5.width -ne 1334 -or [int]$matches[0].g5.height -ne 750) {
            throw "Module '$($ModuleConfig.key)' requires a unique 1334x750 G5 evidence contract before G3."
        }
        if ([bool]$ModuleConfig.mutatesServer) {
            if ($null -eq $matches[0].fixedAccount) {
                throw "Mutating module '$($ModuleConfig.key)' requires a unique fixed-account evidence contract before G3."
            }
            $contractFailures = @(Get-UnityMigrationFixedAccountContractFailures -Root $Root `
                -Module ([string]$ModuleConfig.key) -FixedAccount $matches[0].fixedAccount)
            if ($contractFailures.Count -gt 0) {
                throw "Mutating module '$($ModuleConfig.key)' fixed-account contract is invalid: $($contractFailures -join '; ')"
            }
        }
    }
    return $policy
}

function Get-UnityMigrationSourceAuditFailures {
    param([Parameter(Mandatory = $true)]$Matrix)
    $failures = New-Object System.Collections.Generic.List[string]
    $audit = Get-UnityMigrationPropertyValue -Object $Matrix -Name "sourceAudit" -Default $null
    if ($null -eq $audit) { return @("Control matrix has no sourceAudit.") }
    foreach ($name in @(
        "entryClosureComplete", "protocolOwnershipComplete",
        "configAssetClosureComplete", "runtimeTransformClosureComplete"
    )) {
        $value = Get-UnityMigrationPropertyValue -Object $audit -Name $name -Default $null
        if ($value -isnot [bool] -or -not $value) {
            $failures.Add("sourceAudit.$name must be boolean true before G2.")
        }
    }
    $gaps = @((Get-UnityMigrationPropertyValue -Object $audit -Name "knownGaps" -Default @()))
    $gapIds = New-Object System.Collections.Generic.List[string]
    foreach ($gap in $gaps) {
        $id = [string](Get-UnityMigrationPropertyValue -Object $gap -Name "id" -Default "")
        $handling = [string](Get-UnityMigrationPropertyValue -Object $gap -Name "handling" -Default "")
        $evidence = [string](Get-UnityMigrationPropertyValue -Object $gap -Name "evidence" -Default "")
        if (-not $id -or -not $handling -or -not $evidence) {
            $failures.Add("Every sourceAudit.knownGaps entry requires id, handling and evidence.")
        }
        else { $gapIds.Add($id) }
    }
    if (@($gapIds | Sort-Object -Unique).Count -ne $gapIds.Count) {
        $failures.Add("sourceAudit.knownGaps contains duplicate ids.")
    }
    return @($failures)
}

function Assert-UnityMigrationSourceAudit {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$MatrixPath
    )
    $matrix = (Import-UnityMigrationJson -Root $Root -Path $MatrixPath).Value
    if ([string]$matrix.module -ine $Module) { throw "Source audit matrix module mismatch: $MatrixPath" }
    $failures = @(Get-UnityMigrationSourceAuditFailures -Matrix $matrix)
    if ($failures.Count -gt 0) { throw "Module '$Module' source audit is incomplete: $($failures -join '; ')" }
    return @($matrix.sourceAudit.knownGaps).Count
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

function Get-UnityMigrationG5ContractFingerprint {
    param([Parameter(Mandatory = $true)]$Contract)
    $payload = [ordered]@{
        module = [string](Get-UnityMigrationPropertyValue -Object $Contract -Name "module" -Default "")
        fixedAccount = Get-UnityMigrationPropertyValue -Object $Contract -Name "fixedAccount" -Default $null
        g5 = Get-UnityMigrationPropertyValue -Object $Contract -Name "g5" -Default $null
    }
    $json = $payload | ConvertTo-Json -Depth 16 -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

function Get-UnityMigrationSummaryIdentityFailures {
    param(
        [Parameter(Mandatory = $true)]$Summary,
        [Parameter(Mandatory = $true)]$Result,
        $FixedAccount = $null
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ($null -eq $FixedAccount) {
        if ([uint32]$Summary.userId -ne [uint32]$Result.userId -or
            [uint32]$Summary.roleId -ne [uint32]$Result.roleId) {
            $failures.Add("summary identity does not match result identity")
        }
        return $failures.ToArray()
    }

    $fixedUserId = [uint32]$FixedAccount.userId
    $fixedRoleId = [uint32]$FixedAccount.roleId
    $terminalUserId = [uint32](Get-UnityMigrationPropertyValue -Object $FixedAccount `
        -Name "terminalUserId" -Default $fixedUserId)
    $terminalRoleId = [uint32](Get-UnityMigrationPropertyValue -Object $FixedAccount `
        -Name "terminalRoleId" -Default $fixedRoleId)
    if ([uint32]$Summary.userId -ne $fixedUserId -or [uint32]$Summary.roleId -ne $fixedRoleId) {
        $failures.Add("summary identity does not match fixed account")
    }
    if ([uint32]$Result.userId -ne $terminalUserId -or [uint32]$Result.roleId -ne $terminalRoleId) {
        $failures.Add("result identity does not match terminal account")
    }
    return $failures.ToArray()
}

function Get-UnityMigrationDataPreflightEvidenceFailures {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ExpectedFingerprint,
        [Parameter(Mandatory = $true)][uint32]$ExpectedUserId,
        [Parameter(Mandatory = $true)][uint32]$ExpectedRoleId
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
    foreach ($name in @("setupAssert", "restoreAssert", "cleanupAssert")) {
        if ([string](Get-UnityMigrationPropertyValue -Object $Evidence -Name $name -Default "") -ne "passed") {
            $failures.Add("$name is not passed")
        }
    }
    return @($failures)
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

function Stop-UnityMigrationCompileChildren {
    param([Parameter(Mandatory = $true)][string]$UnityExecutable)
    if (-not $IsWindows) { return }
    $editorDirectory = Split-Path -Parent $UnityExecutable
    $runtimeDirectory = Join-Path $editorDirectory "Data\NetCoreRuntime"
    $children = @(Get-Process dotnet,bee_backend,Unity.ILPP.Trigger -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and $_.Path.StartsWith($editorDirectory, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($children.Count -eq 0) { return }
    $children | Stop-Process -Force -ErrorAction SilentlyContinue
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        Start-Sleep -Milliseconds 250
        $remaining = @($children | Where-Object { Get-Process -Id $_.Id -ErrorAction SilentlyContinue })
    } while ($remaining.Count -gt 0 -and [DateTime]::UtcNow -lt $deadline)
    if ($remaining.Count -gt 0) {
        throw "Unity ILPP/Bee child process did not exit: pid=$($remaining[0].Id)"
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
    $arguments = @("-batchMode", "-quit", "-projectPath", $UnityProject, "-logFile", $logPath)
    $transientBeeLockPatterns = @(
        "error CS0009:.*Assembly-CSharp\.ref\.dll.*being used by another process",
        "error CS2012:.*Assembly-CSharp(?:-Editor)?\.dll.*being used by another process",
        "PostProcessing failed: System\.IO\.IOException:.*Library\\Bee\\artifacts.*being used by another process",
        "IOException:\s*Sharing violation on path .*Library\\ScriptAssemblies\\Assembly-CSharp(?:-Editor)?\.dll"
    )
    $process = $null
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force }
        $process = Start-Process -FilePath $UnityExecutable -ArgumentList $arguments -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try { $process.Kill($true) } catch { }
            Stop-UnityMigrationCompileChildren -UnityExecutable $UnityExecutable
            throw "Unity compile preflight timed out after $TimeoutSeconds seconds; log=$logPath"
        }
        # Unity batchmode may report its exit code before ILPP/Bee release Assembly-CSharp.dll.
        # The child processes are only cleaned after this owned batch process has exited.
        Stop-UnityMigrationCompileChildren -UnityExecutable $UnityExecutable
        $transientBeeLock = $attempt -eq 1 -and (Test-Path -LiteralPath $logPath) -and
            (Select-String -LiteralPath $logPath -Pattern $transientBeeLockPatterns -CaseSensitive:$false -Quiet)
        if ($process.ExitCode -eq 0 -and -not $transientBeeLock) { break }
        if (-not $transientBeeLock) {
            throw "Unity compile preflight failed with exit code $($process.ExitCode); log=$logPath"
        }
        $retryEvidence = "$logPath.transient-bee-lock-attempt1.log"
        Copy-Item -LiteralPath $logPath -Destination $retryEvidence -Force
        Write-Warning "Unity held a generated Assembly-CSharp artifact during compile/reload; retrying the same compile preflight once even if Unity recovered with exit code 0. Evidence: $retryEvidence"
        Start-Sleep -Seconds 2
        Assert-NoUnityMigrationBlockingDotNet -Root $Root
    }
    if ($null -eq $process -or $process.ExitCode -ne 0) {
        throw "Unity compile preflight failed after transient-lock retry; log=$logPath"
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
        [switch]$RequireLifecycleFields
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $matrix = $entry.Value
    if ([int]$matrix.schemaVersion -ne 1 -or [string]$matrix.module -ine $ModuleKey) {
        throw "Invalid control matrix identity: $Path"
    }
    $controls = @($matrix.controls)
    if ($controls.Count -eq 0) { throw "Control matrix has no controls: $Path" }
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
        if ($expectedControls.Count -gt 0 -and $actualControls.Count -eq 0) {
            throw "Runtime control coverage mismatch: expected=$($expectedControls.Count) actual=0; diff=$($expectedControls -join ',')"
        }
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

function Test-UnityMigrationPort {
    param([Parameter(Mandatory = $true)][int]$Port)
    return $null -ne (Get-UnityMigrationTcpListenerPid -Port $Port)
}

function Get-UnityMigrationScenarioRuntimeFlags {
    param([Parameter(Mandatory = $true)]$Scenario)
    $flags = New-Object System.Collections.Generic.List[string]
    foreach ($flag in @((Get-UnityMigrationPropertyValue -Object $Scenario -Name "flags" -Default @()))) {
        if ([string]$flag -and -not $flags.Contains([string]$flag)) { $flags.Add([string]$flag) }
    }
    $network = Get-UnityMigrationPropertyValue -Object $Scenario -Name "networkValidation" -Default $null
    if ($null -ne $network) {
        $disableAutoReconnect = Get-UnityMigrationPropertyValue -Object $network -Name "disableAutoReconnect" -Default $false
        $showReconnectDialog = Get-UnityMigrationPropertyValue -Object $network -Name "showReconnectDialog" -Default $false
        if (($disableAutoReconnect -isnot [bool]) -or ($showReconnectDialog -isnot [bool])) {
            throw "Scenario networkValidation flags must be boolean."
        }
        if ($disableAutoReconnect -or $showReconnectDialog) {
            $managedFlag = "-projectXScenarioManagedReconnect"
            if (-not $flags.Contains($managedFlag)) { $flags.Add($managedFlag) }
        }
    }
    return @($flags)
}

function Get-UnityMigrationCocosPreflightFailures {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$Module
    )
    $failures = New-Object System.Collections.Generic.List[string]
    if ([string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "module" -Default "") -ine $Module) {
        $failures.Add("Cocos preflight module mismatch.")
    }
    foreach ($name in @("transportReady", "windowListed", "inputReady")) {
        if (-not [bool](Get-UnityMigrationPropertyValue -Object $Evidence -Name $name -Default $false)) {
            $failures.Add("Cocos preflight $name must be true.")
        }
    }
    if ([string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "tool" -Default "") -ne "computer-use@openai-bundled" -or
        [string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "targetProcess" -Default "") -ne "ProjectX.exe" -or
        [string](Get-UnityMigrationPropertyValue -Object $Evidence -Name "targetWindow" -Default "") -notlike "*Cocos Simulator*") {
        $failures.Add("Cocos preflight must identify the official Computer Use ProjectX.exe/Cocos Simulator target.")
    }
    $crop = Get-UnityMigrationPropertyValue -Object $Evidence -Name "captureContract" -Default $null
    if ($null -eq $crop -or [string]$crop.mode -ne "window-client-crop-no-scale" -or
        [int]$crop.clientX -ne 1 -or [int]$crop.clientY -ne 26 -or
        [int]$crop.width -ne 1334 -or [int]$crop.height -ne 750 -or -not [bool]$crop.noScale) {
        $failures.Add("Cocos preflight must freeze the current Simulator 1,26 -> 1334x750 no-scale client crop.")
    }
    return @($failures)
}

function Assert-UnityMigrationCocosPreflight {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $failures = @(Get-UnityMigrationCocosPreflightFailures -Evidence $entry.Value -Module $Module)
    if ($failures.Count -gt 0) { throw "Cocos Computer Use preflight is invalid: $($failures -join '; ')" }
    return $entry.Value
}

function Assert-UnityMigrationCocosIdentityEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Matrix
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $scope = Get-UnityMigrationPropertyValue -Object $Matrix -Name "scope" -Default $null
    $expectedUserId = [uint32](Get-UnityMigrationPropertyValue -Object $scope -Name "fixedUserId" -Default 0)
    $expectedRoleId = [uint32](Get-UnityMigrationPropertyValue -Object $scope -Name "fixedRoleId" -Default 0)
    if ($expectedUserId -eq 0 -or $expectedRoleId -eq 0) {
        throw "Module '$Module' matrix scope must freeze fixedUserId/fixedRoleId before G1."
    }
    if ([string]$entry.Value.module -ine $Module -or -not [bool]$entry.Value.success -or
        [uint32]$entry.Value.userId -ne $expectedUserId -or [uint32]$entry.Value.roleId -ne $expectedRoleId) {
        throw "Cocos identity evidence does not prove the frozen $expectedUserId/$expectedRoleId identity."
    }
    return $entry.Value
}

function Get-UnityMigrationCocosBaselineFingerprint {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$G5
    )
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($path in @((Get-UnityMigrationPropertyValue -Object $G5 -Name "cocosBaselineInputs" -Default @()))) {
        $reference = [string]$path
        $resolved = Resolve-UnityMigrationPath -Root $Root -Path $reference
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw "Cocos baseline input is missing: $reference"
        }
        $lines.Add("$reference=$((Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash)")
    }
    if ($lines.Count -eq 0) { throw "G5 contract must freeze non-empty cocosBaselineInputs before G1." }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

function Assert-UnityMigrationCocosBaseline {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Module,
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$RequireCurrentInputs
    )
    $entry = Import-UnityMigrationJson -Root $Root -Path $Path
    $contracts = (Import-UnityMigrationJson -Root $Root -Path "tools/unity-migration/module-evidence-contracts.json").Value
    $matches = @($contracts.modules | Where-Object { $_.module -ieq $Module })
    if ($matches.Count -ne 1 -or $null -eq $matches[0].g5) { throw "Module '$Module' has no unique G5 contract." }
    $g5 = $matches[0].g5
    if ([string]$entry.Value.module -ine $Module -or [string]$entry.Value.sourceGate -ne "G1" -or
        -not [bool]$entry.Value.reuseEligible) {
        throw "Cocos baseline must be a G1 reusable baseline for module '$Module'."
    }
    if ([uint32]$entry.Value.userId -eq 0 -or [uint32]$entry.Value.roleId -eq 0) {
        throw "Cocos baseline has no frozen identity."
    }
    $states = @($entry.Value.states)
    if ($states.Count -ne @($g5.pairs).Count) { throw "Cocos baseline state count does not match the G5 pair contract." }
    foreach ($state in $states) {
        $resolved = Resolve-UnityMigrationPath -Root $Root -Path ([string]$state.path)
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) { throw "Cocos baseline image is missing: $($state.path)" }
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash -ne [string]$state.sha256) {
            throw "Cocos baseline image changed after G1: $($state.path)"
        }
    }
    if ($RequireCurrentInputs) {
        $current = Get-UnityMigrationCocosBaselineFingerprint -Root $Root -G5 $g5
        if ([string]$entry.Value.inputFingerprint -ne $current) {
            throw "Cocos baseline inputs changed after G1; recapture only the invalidated Cocos states and freeze a new baseline."
        }
    }
    return $entry.Value
}

function Get-UnityMigrationMcpSseMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][int]$Id
    )
    $messages = New-Object System.Collections.Generic.List[object]
    foreach ($line in @($Content -split "`r?`n")) {
        if (-not $line.StartsWith("data: ", [StringComparison]::Ordinal)) { continue }
        try { $messages.Add(($line.Substring(6) | ConvertFrom-Json)) }
        catch { throw "Unity MCP returned invalid SSE JSON: $line" }
    }
    $reply = @($messages | Where-Object {
        $idProperty = $_.PSObject.Properties["id"]
        $null -ne $idProperty -and [int]$idProperty.Value -eq $Id
    }) | Select-Object -Last 1
    if ($null -eq $reply) { throw "Unity MCP response did not contain JSON-RPC id $Id." }
    $errorProperty = $reply.PSObject.Properties["error"]
    if ($null -ne $errorProperty -and $null -ne $errorProperty.Value) {
        throw "Unity MCP JSON-RPC error: $($errorProperty.Value | ConvertTo-Json -Depth 8 -Compress)"
    }
    return $reply
}

function Invoke-UnityMigrationMcpRequest {
    param(
        [Parameter(Mandatory = $true)][uri]$Uri,
        [Parameter(Mandatory = $true)][string]$Method,
        [hashtable]$Params = @{},
        [int]$Id = 1,
        [string]$SessionId = "",
        [string]$ProtocolVersion = "2025-03-26",
        [ValidateRange(1, 120)][int]$TimeoutSeconds = 15,
        [switch]$Notification
    )
    $headers = @{ Accept = "application/json, text/event-stream" }
    if ($SessionId) {
        $headers["Mcp-Session-Id"] = $SessionId
        $headers["MCP-Protocol-Version"] = $ProtocolVersion
    }
    $payload = [ordered]@{ jsonrpc = "2.0"; method = $Method; params = $Params }
    if (-not $Notification) { $payload.id = $Id }
    $response = Invoke-WebRequest -Uri $Uri -Method Post -Headers $headers -ContentType "application/json" `
        -Body ($payload | ConvertTo-Json -Depth 12 -Compress) -TimeoutSec $TimeoutSeconds
    if ($Notification) {
        return [pscustomobject]@{ statusCode = [int]$response.StatusCode; sessionId = $SessionId; reply = $null }
    }
    return [pscustomobject]@{
        statusCode = [int]$response.StatusCode
        sessionId = if ($response.Headers["Mcp-Session-Id"]) { [string]$response.Headers["Mcp-Session-Id"] } else { $SessionId }
        reply = Get-UnityMigrationMcpSseMessage -Content ([string]$response.Content) -Id $Id
    }
}

function Connect-UnityMigrationMcpSession {
    param(
        [uri]$Uri = "http://127.0.0.1:8080/mcp",
        [string]$ClientName = "unity-migration",
        [string]$ProtocolVersion = "2025-03-26",
        [ValidateRange(1, 120)][int]$TimeoutSeconds = 15
    )
    $initialize = Invoke-UnityMigrationMcpRequest -Uri $Uri -Method "initialize" -Id 1 `
        -TimeoutSeconds $TimeoutSeconds -Params @{
            protocolVersion = $ProtocolVersion
            capabilities = @{}
            clientInfo = @{ name = $ClientName; version = "1.0" }
        }
    if (-not $initialize.sessionId) { throw "Unity MCP initialize response did not include Mcp-Session-Id." }
    Invoke-UnityMigrationMcpRequest -Uri $Uri -Method "notifications/initialized" -Notification `
        -SessionId $initialize.sessionId -ProtocolVersion $ProtocolVersion -TimeoutSeconds $TimeoutSeconds | Out-Null
    return [pscustomobject]@{
        uri = [string]$Uri
        sessionId = $initialize.sessionId
        protocolVersion = $ProtocolVersion
        serverInfo = $initialize.reply.result.serverInfo
    }
}

function Read-UnityMigrationMcpResource {
    param(
        [Parameter(Mandatory = $true)]$Session,
        [Parameter(Mandatory = $true)][string]$ResourceUri,
        [int]$Id = 2,
        [ValidateRange(1, 120)][int]$TimeoutSeconds = 15
    )
    $response = Invoke-UnityMigrationMcpRequest -Uri ([uri]$Session.uri) -Method "resources/read" `
        -Params @{ uri = $ResourceUri } -Id $Id -SessionId ([string]$Session.sessionId) `
        -ProtocolVersion ([string]$Session.protocolVersion) -TimeoutSeconds $TimeoutSeconds
    $contents = @($response.reply.result.contents)
    if ($contents.Count -eq 0 -or -not [string]$contents[0].text) {
        throw "Unity MCP resource '$ResourceUri' returned no text content."
    }
    return ([string]$contents[0].text | ConvertFrom-Json)
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
    $allowedDuplicateGroups = @(Get-UnityMigrationPropertyValue -Object $assertions -Name "allowedDuplicateGroups" -Default @())
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
    if ($requireUnique -and $results.Count -gt 1) {
        Assert-UnityMigrationDuplicateHashPolicy -Items $results.ToArray() -IdentifierProperty "path" `
            -HashProperty "sha256" -AllowedDuplicateGroups $allowedDuplicateGroups `
            -Context "Scenario '$($Scenario.key)'"
    }
    return $results.ToArray()
}

function Assert-UnityMigrationDuplicateHashPolicy {
    param(
        [Parameter(Mandatory = $true)][object[]]$Items,
        [Parameter(Mandatory = $true)][string]$IdentifierProperty,
        [Parameter(Mandatory = $true)][string]$HashProperty,
        [object[]]$AllowedDuplicateGroups = @(),
        [Parameter(Mandatory = $true)][string]$Context
    )
    $knownIds = @($Items | ForEach-Object { [string]$_.$IdentifierProperty })
    $allowedIdSets = New-Object System.Collections.Generic.List[object]
    $claimedIds = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)
    foreach ($group in @($AllowedDuplicateGroups)) {
        $ids = @(Get-UnityMigrationPropertyValue -Object $group -Name "ids" -Default @() | `
            ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
        if ($ids.Count -lt 2) { throw "$Context has an invalid allowed duplicate group; at least two ids are required." }
        foreach ($id in $ids) {
            if ($knownIds -notcontains $id) { throw "$Context allowed duplicate id is unknown: $id" }
            if (-not $claimedIds.Add($id)) { throw "$Context allowed duplicate id appears in multiple groups: $id" }
        }
        $allowedIdSets.Add($ids)
    }
    foreach ($duplicate in @($Items | Group-Object -Property $HashProperty | Where-Object Count -gt 1)) {
        $ids = @($duplicate.Group | ForEach-Object { [string]$_.$IdentifierProperty } | Sort-Object)
        $isAllowed = $false
        foreach ($allowedIds in $allowedIdSets) {
            if (@($ids | Where-Object { $allowedIds -notcontains $_ }).Count -eq 0) {
                $isAllowed = $true
                break
            }
        }
        if (-not $isAllowed) {
            throw "$Context contains duplicate screenshot content: $($ids -join ', ')."
        }
    }
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
