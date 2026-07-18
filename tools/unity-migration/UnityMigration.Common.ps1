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
    if ($manifest.schemaVersion -ne 1 -or $null -eq $manifest.modules) {
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
    return $null -ne (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1)
}

function Get-UnityMigrationWorkspaceProcesses {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string[]]$Names = @("Unity.exe", "kapai.exe", "mysqld.exe", "ProjectX.exe")
    )
    $escapedRoot = [Regex]::Escape([System.IO.Path]::GetFullPath($Root))
    return @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -in $Names -and
            (($_.ExecutablePath -and $_.ExecutablePath -match $escapedRoot) -or
             ($_.CommandLine -and $_.CommandLine -match $escapedRoot))
        })
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
