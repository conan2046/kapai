param(
    [string]$Configuration = "Debug",
    [string]$BoostRoot = "",
    [string]$MySqlIncludeDir = "",
    [string]$MySqlLibrary = "",
    [string]$SqliteIncludeDir = "",
    [string]$SqliteLibrary = "",
    [string]$LuaIncludeDir = "",
    [string]$LuaLibrary = "",
    [string]$VcpkgRoot = "",
    [string]$BuildDir = "",
    [switch]$SkipAppLocal,
    [switch]$BuildDatabaseSmoke
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if (-not $BuildDir) {
    $BuildDir = Join-Path $Root "build\server-win"
}
elseif (-not [System.IO.Path]::IsPathRooted($BuildDir)) {
    $BuildDir = Join-Path $Root $BuildDir
}

$Cmake = "cmake"
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    $knownCmakeCandidates = @("C:\Program Files\CMake\bin\cmake.exe")
    $vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        foreach ($vsPath in (& $vswhere -all -products * -property installationPath)) {
            if (-not $vsPath) { continue }
            $knownCmakeCandidates += Join-Path $vsPath "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
        }
    }
    $knownCmake = $knownCmakeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $knownCmake) {
        throw "cmake not found. Install CMake first."
    }
    $Cmake = $knownCmake
}

if (-not $VcpkgRoot) {
    $candidate = Join-Path $Root "tools\local\vcpkg"
    if (Test-Path (Join-Path $candidate "scripts\buildsystems\vcpkg.cmake")) {
        $VcpkgRoot = $candidate
    }
    else {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if (-not $git) {
            $knownGit = "C:\Program Files\Git\cmd\git.exe"
            if (Test-Path -LiteralPath $knownGit -PathType Leaf) { $git = $knownGit }
        }
        if ($git) {
            $commonDirectory = (& $git -C $Root rev-parse --git-common-dir 2>$null | Select-Object -First 1)
            if ($commonDirectory) {
                if (-not [System.IO.Path]::IsPathRooted($commonDirectory)) {
                    $commonDirectory = Join-Path $Root $commonDirectory
                }
                $sharedRoot = Split-Path -Parent ([System.IO.Path]::GetFullPath($commonDirectory))
                $sharedCandidate = Join-Path $sharedRoot "tools\local\vcpkg"
                if (Test-Path (Join-Path $sharedCandidate "scripts\buildsystems\vcpkg.cmake")) {
                    $VcpkgRoot = $sharedCandidate
                }
            }
        }
    }
}

if ($VcpkgRoot) {
    if (-not $LuaIncludeDir) {
        $candidate = Join-Path $VcpkgRoot "installed\x64-windows\include\luajit"
        if (Test-Path (Join-Path $candidate "lua.h")) { $LuaIncludeDir = $candidate }
    }
    if (-not $LuaLibrary) {
        $candidate = Join-Path $VcpkgRoot "installed\x64-windows\lib\lua51.lib"
        if (Test-Path $candidate) { $LuaLibrary = $candidate }
    }
    if (-not $SqliteIncludeDir) {
        $candidate = Join-Path $VcpkgRoot "installed\x64-windows-static-md\include"
        if (Test-Path (Join-Path $candidate "sqlite3.h")) { $SqliteIncludeDir = $candidate }
    }
    if (-not $SqliteLibrary) {
        $sqliteLibraryDir = if ($Configuration -eq "Debug") { "debug\lib" } else { "lib" }
        $candidate = Join-Path $VcpkgRoot "installed\x64-windows-static-md\$sqliteLibraryDir\sqlite3.lib"
        if (Test-Path $candidate) { $SqliteLibrary = $candidate }
    }
}

if (-not $MySqlIncludeDir) {
    foreach ($version in "8.4", "8.0") {
        $candidate = "C:\Program Files\MySQL\MySQL Server $version\include"
        if (Test-Path (Join-Path $candidate "mysql.h")) {
            $MySqlIncludeDir = $candidate
            break
        }
    }
}

if (-not $MySqlLibrary) {
    foreach ($version in "8.4", "8.0") {
        $candidate = "C:\Program Files\MySQL\MySQL Server $version\lib\libmysql.lib"
        if (Test-Path $candidate) {
            $MySqlLibrary = $candidate
            break
        }
    }
}

if (-not $MySqlIncludeDir -or -not $MySqlLibrary) {
    throw "MySQL headers/library not found. Run Install-LocalDeps.ps1 -IncludeMySql or pass -MySqlIncludeDir/-MySqlLibrary."
}
if (-not $LuaIncludeDir -or -not $LuaLibrary) {
    throw "LuaJIT headers/library not found. Run Install-LocalDeps.ps1 -IncludeBoost or pass -LuaIncludeDir/-LuaLibrary."
}
if (-not $SqliteIncludeDir -or -not $SqliteLibrary) {
    throw "SQLite static headers/library not found. Run Install-LocalDeps.ps1 -IncludeBoost or pass -SqliteIncludeDir/-SqliteLibrary."
}

$configure = @("-S", (Join-Path $Root "server"), "-B", $BuildDir)
if ($BoostRoot) { $configure += "-DBOOST_ROOT=$BoostRoot" }
if ($MySqlIncludeDir) { $configure += "-DMYSQL_INCLUDE_DIR=$MySqlIncludeDir" }
if ($MySqlLibrary) { $configure += "-DMYSQL_LIBRARY=$MySqlLibrary" }
if ($SqliteIncludeDir) { $configure += "-DSQLITE3_INCLUDE_DIR=$SqliteIncludeDir" }
if ($SqliteLibrary) { $configure += "-DSQLITE3_LIBRARY=$SqliteLibrary" }
if ($LuaIncludeDir) { $configure += "-DLUA_INCLUDE_DIR=$LuaIncludeDir" }
if ($LuaLibrary) { $configure += "-DLUA_LIBRARY=$LuaLibrary" }
if ($VcpkgRoot) { $configure += "-DCMAKE_TOOLCHAIN_FILE=$(Join-Path $VcpkgRoot 'scripts\buildsystems\vcpkg.cmake')" }
if ($SkipAppLocal) { $configure += "-DVCPKG_APPLOCAL_DEPS=OFF" }
if ($BuildDatabaseSmoke) { $configure += "-DKAPAI_BUILD_DATABASE_SMOKE=ON" }

function Copy-RuntimeFileIfChanged {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$DestinationDirectory
    )

    $Destination = Join-Path $DestinationDirectory (Split-Path -Leaf $Source)
    if (Test-Path -LiteralPath $Destination) {
        $SourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
        $DestinationHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
        if ($SourceHash -eq $DestinationHash) {
            return $false
        }
    }

    try {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
    catch {
        throw "Runtime dependency changed but could not be deployed to '$Destination'. Stop the process using it and rebuild. $($_.Exception.Message)"
    }
    return $true
}

& $Cmake @configure
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $Cmake --build $BuildDir --config $Configuration --parallel 4
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not $SkipAppLocal) {
    $OutputDir = Join-Path $BuildDir $Configuration
    $ExePath = Join-Path $OutputDir "kapai.exe"
    if (-not (Test-Path $ExePath)) {
        throw "Build succeeded but kapai.exe was not found: $ExePath"
    }

    # CMake's vcpkg app-local step is not emitted for this legacy target on all
    # generators. Deploy the small runtime set explicitly so a clean checkout
    # can run the freshly built server without inheriting stale DLLs.
    if ($VcpkgRoot) {
        $VcpkgBin = if ($Configuration -eq "Debug") {
            Join-Path $VcpkgRoot "installed\x64-windows\debug\bin"
        } else {
            Join-Path $VcpkgRoot "installed\x64-windows\bin"
        }
        if (-not (Test-Path $VcpkgBin)) {
            throw "vcpkg runtime directory not found: $VcpkgBin"
        }
        foreach ($Pattern in "boost_serialization*.dll", "boost_thread*.dll", "lua51.dll", "zd.dll") {
            $RuntimeDlls = @(Get-ChildItem -LiteralPath $VcpkgBin -Filter $Pattern)
            if ($RuntimeDlls.Count -eq 0) {
                throw "Required vcpkg runtime dependency not found: $VcpkgBin\$Pattern"
            }
            $RuntimeDlls | ForEach-Object {
                $null = Copy-RuntimeFileIfChanged -Source $_.FullName -DestinationDirectory $OutputDir
            }
        }
    }

    $ConfigDir = Join-Path $Root "server\config"
    foreach ($DllName in "libmysql.dll", "libssl-3-x64.dll", "libcrypto-3-x64.dll") {
        $DllPath = Join-Path $ConfigDir $DllName
        if (-not (Test-Path $DllPath)) {
            throw "Tracked MySQL runtime dependency not found: $DllPath"
        }
        $null = Copy-RuntimeFileIfChanged -Source $DllPath -DestinationDirectory $OutputDir
    }

    Write-Host "Runtime DLLs deployed to $OutputDir"
}

exit 0
