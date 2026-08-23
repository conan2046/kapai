[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/Gameplay/unity/g5-20260802/gameplay-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$serverConfig = Join-Path $root "server\config\config"
$lockedUserId = 7200260
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }
if (-not (Test-Path -LiteralPath $serverConfig -PathType Leaf)) { throw "server config not found: $serverConfig" }
if ($UserId -ne 7200057 -or $RoleId -ne 1000115) { throw "Gameplay fixed validation requires primary userId=7200057 roleId=1000115." }

function Invoke-GameplaySql {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Gameplay fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $workspaceExecutables = @(
        [IO.Path]::GetFullPath((Join-Path $root "build\server-win\Debug\kapai.exe")),
        [IO.Path]::GetFullPath((Join-Path $root "client\ProjectX\simulator\win32\ProjectX.exe"))
    )
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -eq "Unity" -or ($_.Path -and $workspaceExecutables -contains [IO.Path]::GetFullPath($_.Path))
    })
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before Gameplay fixture $Action." }
}

function Get-UserRoleId([uint32]$TargetUserId) {
    $tables = @(Invoke-GameplaySql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $rows = @(
        foreach ($tableName in $tables) {
            if ([string]$tableName -notmatch '^user_info\d*$') { throw "Unsafe Gameplay user table name: $tableName" }
            Invoke-GameplaySql "SELECT role0 FROM ``$tableName`` WHERE id=$TargetUserId AND role0>0"
        }
    )
    if ($rows.Count -ne 1) { throw "Gameplay userId=$TargetUserId does not map to exactly one role." }
    [uint32]$rows[0]
}

function Get-IdentitySnapshot {
    $identities = @(
        [ordered]@{ key="primary"; userId=7200057; roleId=1000115; roleName="T00057"; level=99 },
        [ordered]@{ key="locked"; userId=7200260; roleId=1000119; roleName="T20260"; level=1 },
        [ordered]@{ key="isolation"; userId=705213; roleId=1000006; roleName="T67076"; level=60 }
    )
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($identity in $identities) {
        $actualRoleId = Get-UserRoleId ([uint32]$identity.userId)
        $roleRows = @(Invoke-GameplaySql "SELECT CONCAT(id,'|',name,'|',level) FROM role_info WHERE id=$($identity.roleId)")
        if ($actualRoleId -ne [uint32]$identity.roleId -or $roleRows.Count -ne 1 -or
            [string]$roleRows[0] -ne "$($identity.roleId)|$($identity.roleName)|$($identity.level)") {
            throw "Gameplay fixed identity mismatch: key=$($identity.key) user=$($identity.userId) expected=$($identity.roleId)|$($identity.roleName)|$($identity.level) actualRole=$actualRoleId row=$($roleRows -join ',')"
        }
        $lines.Add("$($identity.key)|$($identity.userId)|$($roleRows[0])")
    }
    $text = $lines -join "`n"
    [ordered]@{
        hash = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))).ToLowerInvariant()
        lines = @($lines)
    }
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "Gameplay fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Get-PreserveLevelUserId {
    $match = [regex]::Match((Get-Content -LiteralPath $serverConfig -Raw -Encoding UTF8), '(?m)^local_preserve_level_user_id=(\d+)\s*$')
    if (-not $match.Success) { throw "server config has no local_preserve_level_user_id entry." }
    [uint32]$match.Groups[1].Value
}

function Set-PreserveLevelUserId([uint32]$Value) {
    $content = Get-Content -LiteralPath $serverConfig -Raw -Encoding UTF8
    $matches = [regex]::Matches($content, '(?m)^local_preserve_level_user_id=\d+\s*$')
    if ($matches.Count -ne 1) { throw "server config preserve-level entry count mismatch: $($matches.Count)" }
    $updated = [regex]::Replace($content, '(?m)^local_preserve_level_user_id=\d+\s*$', "local_preserve_level_user_id=$Value", 1)
    [IO.File]::WriteAllText($serverConfig, $updated, [Text.UTF8Encoding]::new($false))
    if ((Get-PreserveLevelUserId) -ne $Value) { throw "server config preserve-level update did not persist: $Value" }
}

function Assert-PreserveLevelOverride {
    if ((Get-PreserveLevelUserId) -ne $lockedUserId) { throw "Gameplay locked-account preserve-level override is not active." }
}

function Restore-PreserveLevelOverride($Payload) {
    Set-PreserveLevelUserId ([uint32]$Payload.originalPreserveLevelUserId)
}

function Assert-PreserveLevelRestored($Payload) {
    $original = [uint32]$Payload.originalPreserveLevelUserId
    $actual = Get-PreserveLevelUserId
    if ($actual -ne $original) { throw "Gameplay preserve-level config was not restored: expected=$original actual=$actual" }
}

function Assert-Unchanged {
    $payload = Read-Evidence
    $current = Get-IdentitySnapshot
    if ([string]$current.hash -ne [string]$payload.snapshotHash) { throw "Gameplay read-only identity hash changed." }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        $snapshot = Get-IdentitySnapshot
        $originalPreserveLevelUserId = Get-PreserveLevelUserId
        Set-PreserveLevelUserId $lockedUserId
        Assert-PreserveLevelOverride
        $configHash = (Get-FileHash -LiteralPath (Join-Path $root "client\ProjectX\src\ConfigData\function_dat.lua") -Algorithm SHA256).Hash
        Write-Evidence ([ordered]@{
            schemaVersion=1; module="Gameplay"; fixture="no-server-fixture"; phase="setup-asserted"
            userId=$UserId; roleId=$RoleId; snapshotHash=$snapshot.hash; identityLines=$snapshot.lines
            configHash=$configHash; mutationCount=0; configMutationCount=1
            originalPreserveLevelUserId=$originalPreserveLevelUserId; lockedPreserveLevelUserId=$lockedUserId
            setupAssert="passed"; restoreAssert="pending"; cleanupAssert="pending"
            createdUtc=[DateTime]::UtcNow.ToString("O")
        })
        Write-Host "Gameplay read-only fixture setup passed: hash=$($snapshot.hash) mutations=0 preserveLevelUserId=$lockedUserId"
    }
    "AssertSetup" { Assert-Unchanged; Assert-PreserveLevelOverride; Write-Host "Gameplay read-only setup assertion passed." }
    "Restore" {
        Assert-ClientsStopped
        Assert-Unchanged
        $payload=Read-Evidence
        Restore-PreserveLevelOverride $payload
        Assert-PreserveLevelRestored $payload
        $payload.phase="restore-asserted"; $payload.restoreAssert="passed"; Write-Evidence $payload
        Write-Host "Gameplay read-only fixture restore is a verified no-op."
    }
    "AssertRestored" { $payload=Read-Evidence; Assert-Unchanged; Assert-PreserveLevelRestored $payload; Write-Host "Gameplay exact identity restore assertion passed." }
    "Cleanup" {
        Assert-ClientsStopped
        $payload=Read-Evidence
        Restore-PreserveLevelOverride $payload
        Assert-PreserveLevelRestored $payload
        Assert-Unchanged
        $payload.phase="cleanup-asserted"; $payload.cleanupAssert="passed"
        $payload | Add-Member -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence $payload
        Write-Host "Gameplay read-only fixture cleanup completed with zero created rows."
    }
    "AssertCleanup" {
        Assert-Unchanged
        $payload=Read-Evidence
        Assert-PreserveLevelRestored $payload
        if ([int]$payload.mutationCount -ne 0 -or [string]$payload.cleanupAssert -ne "passed") { throw "Gameplay read-only cleanup contract failed." }
        Write-Host "Gameplay fixture residual=0 and identity hash unchanged."
    }
}
