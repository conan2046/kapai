[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "CaptureMutationHash", "AssertMutationReloginHash", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 1,
    [uint32]$RoleId = 1000001,
    [string]$EvidencePath = ".local/ui-fidelity/HeroCultivation/fixture/hero-cultivation-fixed-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
if (-not $DatabasePath) {
    $DatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
elseif (-not [IO.Path]::IsPathRooted($DatabasePath)) {
    $DatabasePath = Join-Path $root $DatabasePath
}

if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
    throw "HeroCultivation fixture only accepts the Unity LocalServer projectx.db path."
}

throw "HeroCultivation fixture is frozen at G0 and cannot run before the G2 source/data audit and G3 implementation. Action=$Action UserId=$UserId RoleId=$RoleId EvidencePath=$EvidencePath DatabasePath=$DatabasePath"
