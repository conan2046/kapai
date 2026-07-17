[CmdletBinding()]
param(
    [string]$BuildDir = "build/ui-migration-native",
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$buildPath = Join-Path $repoRoot $BuildDir
$cocosRoot = (Resolve-Path (Join-Path $repoRoot "client/ProjectX/frameworks/cocos2d-x")).Path.Replace("\", "/")

$cmakeCandidates = @(@(
    (Get-Command cmake.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
    "C:/Program Files/CMake/bin/cmake.exe",
    "C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe",
    "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) })

if (-not $cmakeCandidates) {
    throw "CMake not found. Install Visual Studio C++ Build Tools with CMake support."
}
$cmake = $cmakeCandidates[0]

& $cmake -S (Join-Path $PSScriptRoot "native") -B $buildPath -G "Visual Studio 17 2022" -A x64 "-DCOCOS2DX_ROOT=$cocosRoot"
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed: $LASTEXITCODE" }

& $cmake --build $buildPath --config $Configuration --parallel
if ($LASTEXITCODE -ne 0) { throw "CSB decoder build failed: $LASTEXITCODE" }

$exe = Join-Path $buildPath "$Configuration/csb_dump.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Build succeeded but csb_dump.exe was not found" }
Write-Output $exe
