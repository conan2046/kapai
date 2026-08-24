[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [Parameter(Mandatory = $true)]
    [ValidateSet("RecordTransportPreflight", "RecordWindowPreflight", "StartFixedClient", "FreezeG1Baseline")]
    [string]$Action,
    [string]$WindowId = "",
    [int]$RawWidth = 0,
    [int]$RawHeight = 0,
    [switch]$InputReady,
    [string]$RuntimeClientRoot = "",
    [ValidateRange(10, 180)][int]$IdentityTimeoutSeconds = 60,
    [string]$PreflightPath = "",
    [string]$IdentityPath = "",
    [string]$BaselinePath = ""
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$moduleKey = $Module.ToLowerInvariant()
if (-not $PreflightPath) { $PreflightPath = ".local/unity-validation/$moduleKey-cocos-preflight-latest.json" }
if (-not $IdentityPath) { $IdentityPath = ".local/unity-validation/$moduleKey-cocos-identity-latest.json" }
if (-not $BaselinePath) { $BaselinePath = ".local/unity-validation/$moduleKey-cocos-baseline-latest.json" }
$resolvedPreflight = Resolve-UnityMigrationPath -Root $root -Path $PreflightPath
$resolvedIdentity = Resolve-UnityMigrationPath -Root $root -Path $IdentityPath
$resolvedBaseline = Resolve-UnityMigrationPath -Root $root -Path $BaselinePath

$manifest = (Import-UnityMigrationManifest -Root $root).Value
$moduleConfig = @($manifest.modules | Where-Object { $_.key -ieq $Module })
if ($moduleConfig.Count -ne 1) { throw "Module '$Module' has no unique manifest entry." }
$matrix = (Import-UnityMigrationJson -Root $root -Path ([string]$moduleConfig[0].controlMatrix)).Value

if ($Action -eq "RecordTransportPreflight") {
    $evidence = [ordered]@{
        schemaVersion = 1
        module = $Module
        tool = "computer-use@openai-bundled"
        targetProcess = "ProjectX.exe"
        targetWindow = "Cocos Simulator"
        transportReady = $true
        windowListed = $false
        inputReady = $false
        captureContract = [ordered]@{
            mode = "window-client-crop-no-scale"
            clientX = 1
            clientY = 26
            width = 1334
            height = 750
            noScale = $true
        }
        transportCheckedUtc = [DateTime]::UtcNow.ToString("O")
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $resolvedPreflight -Content (($evidence | ConvertTo-Json -Depth 8) + "`n")
    Write-Host "Computer Use transport preflight recorded before service/fixture startup: module=$Module"
    return
}

if ($Action -eq "RecordWindowPreflight") {
    if (-not (Test-Path -LiteralPath $resolvedPreflight -PathType Leaf)) {
        throw "RecordTransportPreflight must run before RecordWindowPreflight."
    }
    if (-not $WindowId -or $RawWidth -ne 1336 -or $RawHeight -ne 777 -or -not $InputReady) {
        throw "Window preflight requires the current Cocos Simulator WindowId, raw 1336x777 window and -InputReady."
    }
    if (@(Get-Process ProjectX -ErrorAction SilentlyContinue).Count -ne 1) {
        throw "Window preflight requires exactly one running ProjectX.exe."
    }
    $evidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolvedPreflight | ConvertFrom-Json
    $evidence.windowListed = $true
    $evidence.inputReady = $true
    $evidence | Add-Member -Force -NotePropertyName windowId -NotePropertyValue $WindowId
    $evidence | Add-Member -Force -NotePropertyName rawWindowWidth -NotePropertyValue $RawWidth
    $evidence | Add-Member -Force -NotePropertyName rawWindowHeight -NotePropertyValue $RawHeight
    $evidence | Add-Member -Force -NotePropertyName checkedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
    Write-UnityMigrationUtf8 -Path $resolvedPreflight -Content (($evidence | ConvertTo-Json -Depth 8) + "`n")
    Assert-UnityMigrationCocosPreflight -Root $root -Module $Module -Path $PreflightPath | Out-Null
    Write-Host "Computer Use window/input preflight passed: module=$Module window=$WindowId crop=1,26,1334x750"
    return
}

if ($Action -eq "StartFixedClient") {
    if (-not (Test-Path -LiteralPath $resolvedPreflight -PathType Leaf)) {
        throw "RecordTransportPreflight must pass before starting services or the Cocos client."
    }
    $transport = Get-Content -Raw -Encoding UTF8 -LiteralPath $resolvedPreflight | ConvertFrom-Json
    if (-not [bool]$transport.transportReady) { throw "Computer Use transport preflight is not ready." }
    $scope = Get-UnityMigrationPropertyValue -Object $matrix -Name "scope" -Default $null
    $userId = [uint32](Get-UnityMigrationPropertyValue -Object $scope -Name "fixedUserId" -Default 0)
    $roleId = [uint32](Get-UnityMigrationPropertyValue -Object $scope -Name "fixedRoleId" -Default 0)
    if ($userId -eq 0 -or $roleId -eq 0) {
        throw "Module '$Module' matrix scope must freeze fixedUserId/fixedRoleId before G1."
    }
    if (@(Get-Process ProjectX -ErrorAction SilentlyContinue).Count -gt 0) {
        throw "Stop the existing ProjectX.exe before StartFixedClient."
    }
    $logPath = Join-Path $root ".local/kapai-current.out"
    $initialLength = if (Test-Path -LiteralPath $logPath -PathType Leaf) {
        (Get-Item -LiteralPath $logPath).Length
    } else { 0L }
    $clientRoot = if ($RuntimeClientRoot) { [IO.Path]::GetFullPath($RuntimeClientRoot) } else { $root }
    $clientLauncher = Join-Path $clientRoot "tools/local/Start-Client.ps1"
    $clientExe = Join-Path $clientRoot "client/ProjectX/simulator/win32/ProjectX.exe"
    if (-not (Test-Path -LiteralPath $clientLauncher -PathType Leaf) -or
        -not (Test-Path -LiteralPath $clientExe -PathType Leaf)) {
        throw "Cocos runtime client root is incomplete: $clientRoot"
    }
    $pwsh = Get-UnityMigrationPowerShellExecutable
    & $pwsh -NoProfile -File $clientLauncher -LocalUserId $userId
    if ($LASTEXITCODE -ne 0) { throw "Start-Client.ps1 failed for fixed userId=$userId." }
    $deadline = [DateTime]::UtcNow.AddSeconds($IdentityTimeoutSeconds)
    $matchedUser = $false
    $matchedRole = $false
    do {
        Start-Sleep -Milliseconds 500
        if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) { continue }
        $stream = [IO.File]::Open($logPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            if ($initialLength -le $stream.Length) { [void]$stream.Seek($initialLength, [IO.SeekOrigin]::Begin) }
            $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::UTF8, $true, 4096, $true)
            try { $newText = $reader.ReadToEnd() }
            finally { $reader.Dispose() }
        }
        finally { $stream.Dispose() }
        $matchedUser = $newText -match "(?i)userId\s*[=:]\s*$userId\b"
        $matchedRole = $newText -match "(?i)roleId\s*[=:]\s*$roleId\b"
    } while ((-not $matchedUser -or -not $matchedRole) -and [DateTime]::UtcNow -lt $deadline)
    if (-not $matchedUser -or -not $matchedRole) {
        throw "Current Cocos login did not prove frozen identity $userId/$roleId within $IdentityTimeoutSeconds seconds."
    }
    $evidence = [ordered]@{
        schemaVersion = 1
        module = $Module
        success = $true
        userId = $userId
        roleId = $roleId
        launcher = "tools/unity-migration/Invoke-UnityMigrationCocosEvidence.ps1"
        clientLauncher = "$clientLauncher -LocalUserId $userId"
        runtimeClientRoot = $clientRoot
        authorityLog = ".local/kapai-current.out"
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path $resolvedIdentity -Content (($evidence | ConvertTo-Json -Depth 6) + "`n")
    Write-Host "Current Cocos fixed identity passed: module=$Module userId=$userId roleId=$roleId"
    return
}

Assert-UnityMigrationCocosPreflight -Root $root -Module $Module -Path $PreflightPath | Out-Null
$identity = Assert-UnityMigrationCocosIdentityEvidence -Root $root -Module $Module -Path $IdentityPath -Matrix $matrix
$contracts = (Import-UnityMigrationJson -Root $root -Path "tools/unity-migration/module-evidence-contracts.json").Value
$contract = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($contract.Count -ne 1 -or $null -eq $contract[0].g5) { throw "Module '$Module' has no unique G5 contract." }
$g5 = $contract[0].g5
$cocosDirectory = Resolve-UnityMigrationPath -Root $root -Path ([string]$g5.cocosDirectory)
$states = New-Object System.Collections.Generic.List[object]
Add-Type -AssemblyName System.Drawing
foreach ($pair in @($g5.pairs)) {
    $path = Join-Path $cocosDirectory ([string]$pair.cocos)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "G1 Cocos baseline state is missing: $path" }
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne 1334 -or $image.Height -ne 750) {
            throw "G1 Cocos baseline must be 1334x750: $path"
        }
    }
    finally { $image.Dispose() }
    $states.Add([pscustomobject][ordered]@{
        id = [string]$pair.id
        path = [IO.Path]::GetRelativePath($root, $path).Replace('\', '/')
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
    })
}
if ($states.Count -eq 0) { throw "G5 contract has no Cocos states to freeze at G1." }
$baseline = [ordered]@{
    schemaVersion = 1
    module = $Module
    sourceGate = "G1"
    reuseEligible = $true
    userId = [uint32]$identity.userId
    roleId = [uint32]$identity.roleId
    inputFingerprint = Get-UnityMigrationCocosBaselineFingerprint -Root $root -G5 $g5
    states = @($states.ToArray())
    invalidationRule = "Recapture only states affected by changed cocosBaselineInputs, identity, fixture or pair definitions."
    checkedUtc = [DateTime]::UtcNow.ToString("O")
}
Write-UnityMigrationUtf8 -Path $resolvedBaseline -Content (($baseline | ConvertTo-Json -Depth 8) + "`n")
Assert-UnityMigrationCocosBaseline -Root $root -Module $Module -Path $BaselinePath -RequireCurrentInputs | Out-Null
Write-Host "Reusable G1 Cocos baseline frozen for G5: module=$Module states=$($states.Count)"
