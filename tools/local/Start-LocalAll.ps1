param(
    [switch]$InitDb,
    [switch]$ImportData,
    [string]$ServerExe = ""
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

& pwsh -ExecutionPolicy Bypass -File (Join-Path $Root "tools\local\Check-LocalEnv.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& pwsh -ExecutionPolicy Bypass -File (Join-Path $Root "tools\local\Start-LocalMySql.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($InitDb) {
    $args = @("-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "tools\local\Init-LocalDb.ps1"))
    if ($ImportData) { $args += "-ImportData" }
    & pwsh @args
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$serverArgs = @("-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "tools\local\Start-Server.ps1"))
if ($ServerExe) {
    $serverArgs += @("-ExePath", $ServerExe)
}
& pwsh @serverArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& pwsh -ExecutionPolicy Bypass -File (Join-Path $Root "tools\local\Start-Client.ps1")
exit $LASTEXITCODE
