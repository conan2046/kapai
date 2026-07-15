param(
    [string]$Configuration = "Debug",
    [string]$BoostRoot = "",
    [string]$MySqlIncludeDir = "",
    [string]$MySqlLibrary = "",
    [string]$LuaIncludeDir = "",
    [string]$LuaLibrary = "",
    [string]$VcpkgRoot = "",
    [switch]$SkipAppLocal
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$BuildDir = Join-Path $Root "build\server-win"

$Cmake = "cmake"
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    $knownCmake = "C:\Program Files\CMake\bin\cmake.exe"
    if (Test-Path $knownCmake) {
        $Cmake = $knownCmake
    } else {
        throw "cmake not found. Install CMake first."
    }
}

if (-not $VcpkgRoot) {
    $candidate = Join-Path $Root "tools\local\vcpkg"
    if (Test-Path (Join-Path $candidate "scripts\buildsystems\vcpkg.cmake")) {
        $VcpkgRoot = $candidate
    }
}

if (-not $MySqlIncludeDir) {
    $candidate = "C:\Program Files\MySQL\MySQL Server 8.4\include"
    if (Test-Path (Join-Path $candidate "mysql.h")) { $MySqlIncludeDir = $candidate }
}

if (-not $MySqlLibrary) {
    $candidate = "C:\Program Files\MySQL\MySQL Server 8.4\lib\libmysql.lib"
    if (Test-Path $candidate) { $MySqlLibrary = $candidate }
}

$configure = @("-S", (Join-Path $Root "server"), "-B", $BuildDir)
if ($BoostRoot) { $configure += "-DBOOST_ROOT=$BoostRoot" }
if ($MySqlIncludeDir) { $configure += "-DMYSQL_INCLUDE_DIR=$MySqlIncludeDir" }
if ($MySqlLibrary) { $configure += "-DMYSQL_LIBRARY=$MySqlLibrary" }
if ($LuaIncludeDir) { $configure += "-DLUA_INCLUDE_DIR=$LuaIncludeDir" }
if ($LuaLibrary) { $configure += "-DLUA_LIBRARY=$LuaLibrary" }
if ($VcpkgRoot) { $configure += "-DCMAKE_TOOLCHAIN_FILE=$(Join-Path $VcpkgRoot 'scripts\buildsystems\vcpkg.cmake')" }
if ($SkipAppLocal) { $configure += "-DVCPKG_APPLOCAL_DEPS=OFF" }

& $Cmake @configure
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Cmake --build $BuildDir --config $Configuration --parallel 4
exit $LASTEXITCODE
