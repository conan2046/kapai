[CmdletBinding()]
param(
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/Task/unity/g5-20260727/task-fixed-fixture-snapshot.json",
    [ValidateRange(60, 900)][int]$RunnerTimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$fixture = Join-Path $root "tools/unity-migration/Invoke-TaskCocosFixture.ps1"
$resultPath = Join-Path $root "build/ui-migration/bootstrap-app-result.json"
$resultEvidencePath = Join-Path $root ".local/ui-fidelity/Task/unity/g5-20260727/task-fixed-unity-result.json"
$logPath = Join-Path $root "build/ui-migration/unity-task-fixed-g5.log"
$unityExecutable = "E:\UnityPro\2022.3.62f3c1\Editor\Unity.exe"
$fixtureCreated = $false

if (@(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue).Count -gt 0) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before fixed-account Task validation."
}

& pwsh -NoProfile -File $fixture -Action Setup -UserId $UserId -RoleId $RoleId -EvidencePath $EvidencePath
if ($LASTEXITCODE -ne 0) { throw "Task fixed-account snapshot setup failed." }
$fixtureCreated = $true

try {
    & pwsh -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
    if ($LASTEXITCODE -ne 0) { throw "Task fixed-account server startup failed." }

    Remove-Item -LiteralPath $resultPath -Force -ErrorAction SilentlyContinue
    $arguments = @(
        "-batchMode",
        "-projectPath", (Join-Path $root "unityclient"),
        "-executeMethod", "ProjectX.Editor.BootstrapAppRunner.RunBatch",
        "-projectXAutomation",
        "-projectXUserId=$UserId",
        "-projectXTaskG4Validation",
        "-projectXValidationScenario=task-default",
        "-projectXRunnerTimeoutSeconds=$RunnerTimeoutSeconds",
        "-logFile", $logPath
    )
    $process = Start-Process -FilePath $unityExecutable -ArgumentList $arguments -PassThru -WindowStyle Hidden
    $process.WaitForExit()

    if (-not (Test-Path -LiteralPath $resultPath -PathType Leaf)) {
        throw "Unity fixed-account result is missing; exit=$($process.ExitCode); log=$logPath"
    }
    $result = Get-Content -LiteralPath $resultPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not [bool]$result.success -or [string]$result.status -notlike "COMPLETE: Task G4*") {
        throw "Unity fixed-account Task validation failed: $($result.status)"
    }
    & pwsh -NoProfile -File $fixture -Action AssertSetup -UserId $UserId -RoleId $RoleId -EvidencePath $EvidencePath
    if ($LASTEXITCODE -ne 0) { throw "Task fixed-account fixture application assertion failed." }

    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($resultEvidencePath)) | Out-Null
    Copy-Item -LiteralPath $resultPath -Destination $resultEvidencePath -Force
    Write-Host "Task fixed-account Unity validation passed: userId=$UserId roleId=$($result.roleId)"
}
finally {
    Get-Process Unity -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "*UnityPro*" } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process kapai -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    if ($fixtureCreated) {
        & pwsh -NoProfile -File $fixture -Action Cleanup -UserId $UserId -RoleId $RoleId -EvidencePath $EvidencePath
        if ($LASTEXITCODE -ne 0) { throw "Task fixed-account exact restore failed." }
        & pwsh -NoProfile -File $fixture -Action AssertCleanup -UserId $UserId -RoleId $RoleId -EvidencePath $EvidencePath
        if ($LASTEXITCODE -ne 0) { throw "Task fixed-account cleanup assertion failed." }
    }
}

try {
    & pwsh -NoProfile -File (Join-Path $root "tools/local/Start-Server.ps1") -WaitSeconds 60
    if ($LASTEXITCODE -ne 0) { throw "Task fixed-account restore-login server startup failed." }
    & pwsh -NoProfile -File (Join-Path $root "tools/local/Invoke-ProtocolSmoke.ps1") -UserId $UserId
    if ($LASTEXITCODE -ne 0) { throw "Task fixed-account restore-login failed." }
}
finally {
    Get-Process kapai -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

& pwsh -NoProfile -File $fixture -Action AssertCleanup -UserId $UserId -RoleId $RoleId -EvidencePath $EvidencePath
if ($LASTEXITCODE -ne 0) { throw "Task fixed-account restored hash changed after re-login." }
Write-Host "Task fixed-account re-login and restored hash assertion passed: userId=$UserId roleId=$RoleId"
