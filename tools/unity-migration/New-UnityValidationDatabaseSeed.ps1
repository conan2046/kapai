[CmdletBinding()]
param(
    [string]$SourceDatabase = "",
    [string]$OutputDatabase = "server/sql/sqlite/fixtures/projectx-validation-base.db",
    [string]$ManifestPath = "server/sql/sqlite/fixtures/projectx-validation-base.manifest.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $SourceDatabase) {
    $SourceDatabase = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($SourceDatabase)) { $SourceDatabase = Join-Path $root $SourceDatabase }
if (-not [IO.Path]::IsPathRooted($OutputDatabase)) { $OutputDatabase = Join-Path $root $OutputDatabase }
if (-not [IO.Path]::IsPathRooted($ManifestPath)) { $ManifestPath = Join-Path $root $ManifestPath }

$running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) {
    throw "Stop kapai.exe, ProjectX.exe and Unity.exe before rebuilding the validation database seed."
}

& python -X utf8 (Join-Path $PSScriptRoot "UnityValidationDatabase.py") build-seed `
    --source $SourceDatabase --output $OutputDatabase --manifest $ManifestPath
if ($LASTEXITCODE -ne 0) { throw "Validation database seed generation failed." }
