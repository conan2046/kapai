[CmdletBinding()]
param(
    [string]$DatabasePath = "",
    [string]$BackupPath = ".local/unity-validation/projectx-before-fixed-identity-20260902.snapshot",
    [string]$EvidencePath = ".local/unity-validation/unity-fixed-test-identity-latest.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
foreach ($name in @("BackupPath", "EvidencePath")) {
    $value = Get-Variable -Name $name -ValueOnly
    if (-not [IO.Path]::IsPathRooted($value)) { Set-Variable -Name $name -Value (Join-Path $root $value) }
}
if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Fixed test identity provisioning only accepts Application.persistentDataPath/LocalServer/projectx.db."
}
if (@(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue).Count -gt 0) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before provisioning the fixed test identity."
}
$python = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $python -or $python.Source -like "*WindowsApps*") {
    $pythonPath = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
    if (-not (Test-Path -LiteralPath $pythonPath -PathType Leaf)) { throw "A working Python runtime is required." }
} else { $pythonPath = $python.Source }
& $pythonPath -X utf8 (Join-Path $PSScriptRoot "Provision-UnityFixedTestIdentity.py") `
    --database $DatabasePath --backup $BackupPath --evidence $EvidencePath
if ($LASTEXITCODE -ne 0) { throw "Fixed test identity provisioning failed." }
