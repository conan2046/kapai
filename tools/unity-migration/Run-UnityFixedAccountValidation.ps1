[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Module,
    [uint32]$UserId = 0,
    [uint32]$RoleId = 0,
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "UnityMigration.Common.ps1")
$root = Get-UnityMigrationRoot
$manifest = (Import-UnityMigrationManifest -Root $root).Value
$contracts = (Import-UnityMigrationJson -Root $root `
    -Path "tools/unity-migration/module-evidence-contracts.json").Value
$moduleConfig = @($manifest.modules | Where-Object { $_.key -ieq $Module })
$contract = @($contracts.modules | Where-Object { $_.module -ieq $Module })
if ($moduleConfig.Count -ne 1 -or $contract.Count -ne 1 -or $null -eq $contract[0].fixedAccount) {
    throw "Module '$Module' has no unique fixed-account evidence contract."
}
$moduleConfig = $moduleConfig[0]
$contract = $contract[0]
$fixed = $contract.fixedAccount
$scenario = Get-UnityMigrationScenario -Root $root -ModuleKey ([string]$moduleConfig.key)
if ($null -eq $scenario) { throw "Module '$Module' has no validation scenario." }
if ($UserId -eq 0) { $UserId = [uint32]$fixed.userId }
if ($RoleId -eq 0) { $RoleId = [uint32]$fixed.roleId }
$adapter = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.adapter)
$snapshot = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.snapshot)
$resultPath = Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.resultFile)
$resultEvidence = Resolve-UnityMigrationPath -Root $root -Path ([string]$fixed.resultEvidence)
$logPath = Join-Path (Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.logDirectory)) `
    "unity-$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account.log"
$unityExecutable = [string]$manifest.unityExecutable
$fixtureCreated = $false
$validationPassed = $false

if (-not (Test-Path -LiteralPath $adapter -PathType Leaf)) { throw "Fixed-account adapter is missing: $adapter" }
if (@(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue).Count -gt 0) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before fixed-account validation."
}

function Invoke-FixedAdapter([string]$Action) {
    & pwsh -NoProfile -File $adapter -Action $Action -UserId $UserId -RoleId $RoleId -EvidencePath $snapshot
    if ($LASTEXITCODE -ne 0) { throw "Fixed-account adapter action failed: $Action" }
}

Invoke-FixedAdapter "Setup"
$fixtureCreated = $true
try {
    & pwsh -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
    if ($LASTEXITCODE -ne 0) { throw "Fixed-account server startup failed." }
    if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath -Force }
    $arguments = @(
        "-batchMode",
        "-projectPath", (Resolve-UnityMigrationPath -Root $root -Path ([string]$manifest.unityProject)),
        "-executeMethod", ([string]$manifest.executeMethod),
        "-projectXAutomation",
        "-projectXUserId=$UserId",
        "-projectXValidationScenario=$($scenario.key)",
        "-projectXRunnerTimeoutSeconds=$RunnerTimeoutSeconds",
        "-logFile", $logPath
    ) + @($scenario.flags | ForEach-Object { [string]$_ })
    $process = Start-Process -FilePath $unityExecutable -ArgumentList $arguments `
        -PassThru -WindowStyle Hidden
    $process.WaitForExit()
    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        throw "Unity fixed-account result is missing; exit=$($process.ExitCode); log=$logPath"
    }
    $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not [bool]$result.success -or [string]$result.status -notlike "COMPLETE:*") {
        throw "Unity fixed-account validation failed: $($result.status)"
    }
    Assert-UnityMigrationRunnerIdentity -Result $result -ScenarioKey ([string]$scenario.key) -ExpectedUserId $UserId
    if ([uint32]$result.roleId -ne $RoleId) {
        throw "Unity fixed-account role mismatch: expected=$RoleId actual=$($result.roleId)"
    }
    $coverage = Assert-UnityMigrationRunnerCoverage -Root $root -Result $result -Scenario $scenario `
        -ControlMatrix ([string]$moduleConfig.controlMatrix)
    Invoke-FixedAdapter "AssertSetup"
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($resultEvidence)) | Out-Null
    Copy-Item -LiteralPath $resultPath -Destination $resultEvidence -Force
    $summary = [ordered]@{
        schemaVersion = 1
        module = [string]$moduleConfig.key
        scenario = [string]$scenario.key
        userId = $UserId
        roleId = $RoleId
        validatedControlIds = @($coverage.validatedControlIds)
        passedSemanticAssertions = @($coverage.passedSemanticAssertions)
        snapshot = [string]$fixed.snapshot
        resultEvidence = [string]$fixed.resultEvidence
        resultSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resultEvidence).Hash
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
    Write-UnityMigrationUtf8 -Path (Join-Path $root ".local/unity-validation/$(([string]$moduleConfig.key).ToLowerInvariant())-fixed-account-latest.json") `
        -Content (($summary | ConvertTo-Json -Depth 8) + "`n")
    $validationPassed = $true
}
finally {
    Get-Process Unity,kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if ($fixtureCreated) {
        if ($validationPassed) {
            Invoke-FixedAdapter "Restore"
            Invoke-FixedAdapter "AssertRestored"
        }
        else {
            Invoke-FixedAdapter "Cleanup"
            Invoke-FixedAdapter "AssertCleanup"
            $fixtureCreated = $false
        }
    }
}

if ([bool]$fixed.reloginRequired) {
    $reloginFailure = $null
    try {
        & pwsh -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
        if ($LASTEXITCODE -ne 0) { throw "Fixed-account restore-login server startup failed." }
        & pwsh -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") -UserId $UserId
        if ($LASTEXITCODE -ne 0) { throw "Fixed-account restore-login failed." }
    }
    catch { $reloginFailure = $_ }
    finally {
        Get-Process kapai -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if ($fixtureCreated) {
            Invoke-FixedAdapter "Restore"
            Invoke-FixedAdapter "AssertRestored"
            Invoke-FixedAdapter "Cleanup"
            Invoke-FixedAdapter "AssertCleanup"
            $fixtureCreated = $false
        }
    }
    if ($null -ne $reloginFailure) { throw $reloginFailure }
}
elseif ($fixtureCreated) {
    Invoke-FixedAdapter "Cleanup"
    Invoke-FixedAdapter "AssertCleanup"
    $fixtureCreated = $false
}
Write-Host "Fixed-account validation passed and restored: module=$Module userId=$UserId roleId=$RoleId"
