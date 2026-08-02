[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Snapshot", "SetupEmpty", "AssertEmpty", "Restore", "AssertRestored")]
    [string]$Action,
    [string]$EvidencePath = ".local/unity-validation/gameplay-cocos-config-fixture.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$sourcePath = Join-Path $root "client\ProjectX\src\ConfigData\function_dat.lua"
$runtimePath = Join-Path $root "client\ProjectX\simulator\win32\src\ConfigData\function_dat.lua"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }

function Get-Sha256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Assert-ClientStopped {
    $expected = [IO.Path]::GetFullPath((Join-Path $root "client\ProjectX\simulator\win32\ProjectX.exe"))
    $running = @(Get-Process ProjectX -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and [IO.Path]::GetFullPath($_.Path) -eq $expected
    })
    if ($running.Count -gt 0) { throw "Stop workspace ProjectX.exe before Gameplay Cocos fixture $Action." }
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "Gameplay Cocos fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Gameplay source config is missing: $sourcePath" }
if (-not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) { throw "Gameplay simulator config is missing: $runtimePath" }

switch ($Action) {
    "Snapshot" {
        Assert-ClientStopped
        $sourceHash = Get-Sha256 $sourcePath
        $runtimeHash = Get-Sha256 $runtimePath
        if ($sourceHash -ne $runtimeHash) { throw "Gameplay simulator config must match source before snapshot." }
        Write-Evidence ([ordered]@{
            schemaVersion = 1
            module = "Gameplay"
            fixture = "runtime-config-pages-hidden"
            phase = "snapshot"
            sourcePath = $sourcePath
            runtimePath = $runtimePath
            sourceHash = $sourceHash
            snapshotHash = $runtimeHash
            runtimeBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($runtimePath))
            residuals = @()
        })
        Write-Host "Gameplay Cocos config snapshot passed: $runtimeHash"
    }
    "SetupEmpty" {
        Assert-ClientStopped
        $payload = Read-Evidence
        if ([string]$payload.snapshotHash -ne (Get-Sha256 $runtimePath)) { throw "Gameplay simulator config changed after snapshot." }
        $runtimeText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]$payload.runtimeBase64))
        $matches = [regex]::Matches($runtimeText, '(?m)(\bpage\s*=\s*)[1-9]\d*')
        if ($matches.Count -eq 0) { throw "Gameplay simulator config has no visible page entries to hide." }
        $emptyText = [regex]::Replace($runtimeText, '(?m)(\bpage\s*=\s*)[1-9]\d*', '${1}0')
        [IO.File]::WriteAllText($runtimePath, $emptyText, [Text.UTF8Encoding]::new($false))
        $payload.phase = "empty-applied"
        $payload | Add-Member -NotePropertyName emptyHash -NotePropertyValue (Get-Sha256 $runtimePath) -Force
        $payload | Add-Member -NotePropertyName hiddenPageEntryCount -NotePropertyValue $matches.Count -Force
        Write-Evidence $payload
        Write-Host "Gameplay Cocos page-hidden config applied to simulator copy only: $($matches.Count) entries."
    }
    "AssertEmpty" {
        $payload = Read-Evidence
        if ([string]$payload.phase -ne "empty-applied") { throw "Gameplay empty fixture is not active." }
        if ((Get-Sha256 $sourcePath) -ne [string]$payload.sourceHash) { throw "Gameplay source config changed during runtime-only fixture." }
        if ((Get-Sha256 $runtimePath) -ne [string]$payload.emptyHash) { throw "Gameplay runtime empty fixture hash mismatch." }
        Write-Host "Gameplay Cocos empty config assertion passed."
    }
    "Restore" {
        Assert-ClientStopped
        $payload = Read-Evidence
        [IO.File]::WriteAllBytes($runtimePath, [Convert]::FromBase64String([string]$payload.runtimeBase64))
        $payload.phase = "restored"
        Write-Evidence $payload
        Write-Host "Gameplay Cocos simulator config restored."
    }
    "AssertRestored" {
        $payload = Read-Evidence
        $sourceHash = Get-Sha256 $sourcePath
        $runtimeHash = Get-Sha256 $runtimePath
        if ($sourceHash -ne [string]$payload.sourceHash -or $runtimeHash -ne [string]$payload.snapshotHash -or $sourceHash -ne $runtimeHash) {
            throw "Gameplay Cocos config restore assertion failed."
        }
        $payload.phase = "restore-asserted"
        $payload.residuals = @()
        Write-Evidence $payload
        Write-Host "Gameplay Cocos config restore assertion passed: $runtimeHash"
    }
}
