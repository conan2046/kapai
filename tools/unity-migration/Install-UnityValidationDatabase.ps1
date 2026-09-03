[CmdletBinding()]
param(
    [ValidateSet("Verify", "Install", "Restore")][string]$Action = "Verify",
    [string]$DatabasePath = "",
    [string]$BackupPath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$seed = Join-Path $root "server\sql\sqlite\fixtures\projectx-validation-base.db"
$manifest = Join-Path $root "server\sql\sqlite\fixtures\projectx-validation-base.manifest.json"
$adapter = Join-Path $PSScriptRoot "UnityValidationDatabase.py"

if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Validation database install only accepts Application.persistentDataPath/LocalServer/projectx.db."
}

if ($Action -eq "Verify") {
    & python -X utf8 $adapter verify --seed $seed --manifest $manifest
    if ($LASTEXITCODE -ne 0) { throw "Validation database seed verification failed." }
    exit 0
}

$running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before validation database $Action."
}

$evidence = Join-Path $root ".local\unity-validation\validation-database-install-latest.json"
if ($Action -eq "Install") {
    if (-not $BackupPath) {
        $stamp = [DateTime]::UtcNow.ToString("yyyyMMdd-HHmmss")
        $BackupPath = Join-Path $root ".local\unity-validation\database-backups\projectx-before-validation-$stamp.db"
    }
    elseif (-not [IO.Path]::IsPathRooted($BackupPath)) { $BackupPath = Join-Path $root $BackupPath }
    & python -X utf8 $adapter install --seed $seed --manifest $manifest `
        --database $DatabasePath --backup $BackupPath --evidence $evidence
}
else {
    if (-not $BackupPath) { throw "Restore requires -BackupPath from the Install result." }
    if (-not [IO.Path]::IsPathRooted($BackupPath)) { $BackupPath = Join-Path $root $BackupPath }
    & python -X utf8 $adapter restore --database $DatabasePath --backup $BackupPath --evidence $evidence
}
if ($LASTEXITCODE -ne 0) { throw "Validation database $Action failed." }
