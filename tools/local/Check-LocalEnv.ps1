param(
    [string]$MySqlUser = "root",
    [string]$MySqlPassword = "123456",
    [string]$Database = "fxl_game_local",
    [switch]$SkipClient
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Write-Check($Name, $Ok, $Detail) {
    $state = if ($Ok) { "OK" } else { "MISS" }
    Write-Host ("[{0}] {1} - {2}" -f $state, $Name, $Detail)
}

function Has-Command($Name) {
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Find-VsTool($FileName) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return "" }
    $vsPaths = & $vswhere -all -products * -property installationPath
    foreach ($vsPath in $vsPaths) {
        if (-not $vsPath) { continue }
        $found = Get-ChildItem -Path $vsPath -Filter $FileName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return ""
}

function Find-KnownFile($Paths) {
    foreach ($p in $Paths) {
        if (Test-Path $p) { return $p }
    }
    return ""
}

$clientExe = Join-Path $Root "client\ProjectX\simulator\win32\ProjectX.exe"
$serverConfig = Join-Path $Root "server\config\config"
$serverXml = Join-Path $Root "server\config\xml"
$serverDat = Join-Path $Root "server\config\dat"
$serverScript = Join-Path $Root "server\script"
$cmakeFile = Join-Path $Root "server\CMakeLists.txt"
$allSql = Join-Path $Root "server\sql\_all_sql.sql"
$itemSql = Join-Path $Root "server\sql\item_template.sql"
$luaInclude = Join-Path $Root "tools\local\vcpkg\installed\x64-windows\include\luajit\lua.h"
$luaLib = Join-Path $Root "tools\local\vcpkg\installed\x64-windows\lib\lua51.lib"

Write-Host "Local run environment check"
Write-Host "Root: $Root"
Write-Host ""

if (-not $SkipClient) {
    Write-Check "Client simulator" (Test-Path $clientExe) $clientExe
}
Write-Check "Server config" (Test-Path $serverConfig) $serverConfig
Write-Check "Server xml" (Test-Path $serverXml) $serverXml
Write-Check "Server dat" (Test-Path $serverDat) $serverDat
Write-Check "Server script" (Test-Path $serverScript) $serverScript
Write-Check "Server CMake" (Test-Path $cmakeFile) $cmakeFile
Write-Check "Data SQL" (Test-Path $allSql) $allSql
Write-Check "Item SQL" (Test-Path $itemSql) $itemSql
Write-Check "Server LuaJIT headers" (Test-Path $luaInclude) $luaInclude
Write-Check "Server LuaJIT library" (Test-Path $luaLib) $luaLib

$roleInfoPattern = "CREATE\s+TABLE(?:\s+IF\s+NOT\s+EXISTS)?\s+``?role_info``?\s*\("
$hasBaseSchema = Get-ChildItem (Join-Path $Root "server\sql") -File |
    Where-Object { Select-String -Path $_.FullName -Pattern $roleInfoPattern -Quiet } |
    Select-Object -First 1
Write-Check "Base DB schema" ([bool]$hasBaseSchema) ($(if($hasBaseSchema){$hasBaseSchema.FullName}else{"missing CREATE TABLE role_info"}))

$fallbackSchema = Join-Path $Root "server\sql\local_min_schema.sql"
Write-Check "Fallback DB schema" (Test-Path $fallbackSchema) $fallbackSchema

$cmakeKnown = Find-KnownFile @("C:\Program Files\CMake\bin\cmake.exe")
$cmakePath = Get-Command cmake -ErrorAction SilentlyContinue
$vsCmake = Find-VsTool "cmake.exe"
Write-Check "cmake" ([bool]$cmakePath -or [bool]$cmakeKnown -or [bool]$vsCmake) ($(if($cmakePath){$cmakePath.Source}elseif($cmakeKnown){$cmakeKnown}elseif($vsCmake){$vsCmake}else{"cmake"}))

$clPath = Get-Command cl -ErrorAction SilentlyContinue
$vsCl = Find-VsTool "cl.exe"
Write-Check "MSVC cl" ([bool]$clPath -or [bool]$vsCl) ($(if($clPath){$clPath.Source}elseif($vsCl){$vsCl}else{"cl"}))
$mysqlKnown = Find-KnownFile @(
    "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe",
    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
)
$mysqlCommand = Get-Command mysql -ErrorAction SilentlyContinue
Write-Check "mysql client" ([bool]$mysqlCommand -or [bool]$mysqlKnown) ($(if($mysqlCommand){$mysqlCommand.Source}elseif($mysqlKnown){$mysqlKnown}else{"mysql.exe"}  ))

$vcpkgExe = Join-Path $Root "tools\local\vcpkg\vcpkg.exe"
$boostLibDir = Join-Path $Root "tools\local\vcpkg\installed\x64-windows\lib"
$boostThread = ""
if (Test-Path $boostLibDir) {
    $boostThreadFile = Get-ChildItem -Path $boostLibDir -Filter "boost_thread*.lib" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($boostThreadFile) { $boostThread = $boostThreadFile.FullName }
}
Write-Check "vcpkg" (Test-Path $vcpkgExe) $vcpkgExe
Write-Check "Boost via vcpkg" ([bool]$boostThread) ($(if($boostThread){$boostThread}else{$boostLibDir}))

$mysqlForCheck = ""
if (Has-Command "mysql") {
    $mysqlForCheck = (Get-Command mysql).Source
} elseif ($mysqlKnown) {
    $mysqlForCheck = $mysqlKnown
}

if ($mysqlForCheck) {
    $args = @("-u$MySqlUser", "-p$MySqlPassword", "--host=127.0.0.1", "--port=3306", "-e", "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME='$Database';")
    try {
        $out = & $mysqlForCheck @args 2>&1
        Write-Check "MySQL database $Database" ($LASTEXITCODE -eq 0 -and ($out -match $Database)) "127.0.0.1:3306"
    } catch {
        Write-Check "MySQL database $Database" $false $_.Exception.Message
    }
}

Write-Host ""
Write-Host "If tools are missing, run:"
Write-Host "pwsh -ExecutionPolicy Bypass -File tools/local/Install-LocalDeps.ps1 -IncludeMySql -IncludeBoost"
