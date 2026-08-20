param(
    [switch]$IncludeMySql,
    [switch]$IncludeBoost,
    [string]$VcpkgRef = "a7bd30319eeac16afbe18d64a855303a0a425e84"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install dependencies manually: CMake, Visual Studio Build Tools, MySQL, Boost, Lua 5.1."
}

function Install-Winget($Id, $Name) {
    $existing = winget list --id $Id --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and ($existing -match [regex]::Escape($Id))) {
        Write-Host "$Name already installed ($Id)"
        return
    }
    Write-Host "Installing $Name ($Id)"
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget install failed: $Id"
    }
}

function Install-WingetOverride($Id, $Name, $Override) {
    $existing = winget list --id $Id --exact 2>$null
    if ($LASTEXITCODE -eq 0 -and ($existing -match [regex]::Escape($Id))) {
        Write-Host "$Name already installed ($Id)"
        return
    }
    Write-Host "Installing $Name ($Id)"
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements --override $Override
    if ($LASTEXITCODE -ne 0) {
        throw "winget install failed: $Id"
    }
}

function Find-ClExe($VsPath) {
    if (-not $VsPath -or -not (Test-Path $VsPath)) { return "" }
    $found = Get-ChildItem -Path (Join-Path $VsPath "VC\Tools\MSVC") -Filter cl.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match "\\bin\\Hostx64\\x64\\cl.exe$" } |
        Select-Object -First 1
    if ($found) { return $found.FullName }
    return ""
}

function Find-GitExe {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) { return $git.Source }

    $known = "C:\Program Files\Git\cmd\git.exe"
    if (Test-Path $known) { return $known }

    return ""
}

Install-Winget "Kitware.CMake" "CMake"

$vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
$setup = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\setup.exe"
$vsPath = ""
if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -products * -property installationPath
}

if ($vsPath -and (Test-Path $setup)) {
    Write-Host "Adding C++ workload to existing Visual Studio: $vsPath"
    & $setup modify --installPath $vsPath --quiet --wait --norestart `
        --add Microsoft.VisualStudio.Workload.NativeDesktop `
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        --add Microsoft.VisualStudio.Component.Windows11SDK.26100 `
        --includeRecommended
    if ($LASTEXITCODE -ne 0) {
        throw "Visual Studio modify failed: $LASTEXITCODE"
    }
}

$cl = Find-ClExe $vsPath
if (-not $cl) {
    Install-WingetOverride "Microsoft.VisualStudio.2022.BuildTools" "Visual Studio 2022 Build Tools with C++" "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --includeRecommended"
}

if ($IncludeMySql) {
    Install-Winget "Oracle.MySQL" "MySQL"
}

if ($IncludeBoost) {
    $gitExe = Find-GitExe
    if (-not $gitExe) {
        throw "git not found. Cannot bootstrap vcpkg for Boost."
    }
    $Root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
    $vcpkg = Join-Path $Root "tools\local\vcpkg"
    if (-not (Test-Path $vcpkg)) {
        & $gitExe clone https://github.com/microsoft/vcpkg.git $vcpkg
        if ($LASTEXITCODE -ne 0) { throw "git clone vcpkg failed" }
    }

    if (-not (Test-Path (Join-Path $vcpkg ".git"))) {
        throw "Existing vcpkg directory is not a git checkout: $vcpkg"
    }

    $dirty = & $gitExe -C $vcpkg status --porcelain
    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect vcpkg checkout: $vcpkg" }
    if ($dirty) {
        throw "vcpkg checkout has local changes; refusing to switch revisions: $vcpkg"
    }

    & $gitExe -C $vcpkg fetch --depth 1 origin $VcpkgRef
    if ($LASTEXITCODE -ne 0) { throw "vcpkg fetch failed: $VcpkgRef" }
    & $gitExe -C $vcpkg checkout --detach $VcpkgRef
    if ($LASTEXITCODE -ne 0) { throw "vcpkg checkout failed: $VcpkgRef" }

    & (Join-Path $vcpkg "bootstrap-vcpkg.bat")
    if ($LASTEXITCODE -ne 0) { throw "bootstrap vcpkg failed" }
    & (Join-Path $vcpkg "vcpkg.exe") install `
        boost-thread:x64-windows `
        boost-system:x64-windows `
        boost-serialization:x64-windows `
        luajit:x64-windows `
        zlib:x64-windows `
        sqlite3:x64-windows-static-md
    if ($LASTEXITCODE -ne 0) { throw "vcpkg dependency install failed" }
}

Write-Host ""
Write-Host "After install, open a new PowerShell 7 or Developer PowerShell, then run:"
Write-Host "pwsh -ExecutionPolicy Bypass -File tools/local/Check-LocalEnv.ps1"
