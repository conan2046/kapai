[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "AssertReloginHash", "Cleanup", "AssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/PlayerHud/unity/g5-20260801/playerhud-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-HudSql {
    param([Parameter(Mandatory = $true)][string]$Sql, [switch]$ReturnOutput)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "PlayerHud fixture SQL failed: $($output -join [Environment]::NewLine)" }
    if ($ReturnOutput) { return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" }) }
}

function Assert-ClientsStopped {
    $workspaceExecutables = @(
        [IO.Path]::GetFullPath((Join-Path $root "build\server-win\Debug\kapai.exe")),
        [IO.Path]::GetFullPath((Join-Path $root "client\ProjectX\simulator\win32\ProjectX.exe"))
    )
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -eq "Unity" -or ($_.Path -and $workspaceExecutables -contains [IO.Path]::GetFullPath($_.Path))
    })
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before PlayerHud fixture $Action." }
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 10) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "PlayerHud fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

$createTableSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_playerhud_fixture (
 user_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
 role_id BIGINT UNSIGNED NOT NULL,
 backup_role_money BIGINT NOT NULL,
 backup_exp BIGINT UNSIGNED NOT NULL,
 backup_level INT UNSIGNED NOT NULL,
 backup_power BIGINT UNSIGNED NOT NULL,
 backup_user_money BIGINT NOT NULL,
 backup_bd_money BIGINT NOT NULL,
 backup_user_spirit MEDIUMTEXT NULL,
 snapshot_hash CHAR(64) NOT NULL,
 applied TINYINT NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@
$hashExpression = "LOWER(SHA2(CONCAT_WS('|',r.id,r.name,r.money,r.exp,r.level,r.zhanDouLi,COALESCE(HEX(r.user_spirit),''),u.id,u.role0,u.money,u.bd_money),256))"

function Get-LiveHash {
    $rows = @(Invoke-HudSql -Sql "SELECT $hashExpression FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId" -ReturnOutput)
    if ($rows.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$rows[0])) {
        throw "PlayerHud fixed identity is missing or ambiguous: userId=$UserId roleId=$RoleId"
    }
    [string]$rows[0]
}

function Assert-SetupState {
    $rows = @(Invoke-HudSql -Sql @"
SELECT COUNT(*)=1 AND r.name='T00057' AND r.level=99 AND r.exp=0 AND r.zhanDouLi IN (0,13800)
 AND r.money=1000000 AND u.money=100000 AND u.bd_money=100000 AND CHAR_LENGTH(r.user_spirit)>0
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_playerhud_fixture f ON f.user_id=u.id AND f.role_id=r.id
WHERE r.id=$RoleId AND f.applied=1
"@ -ReturnOutput)
    if ($rows.Count -ne 1 -or [int]$rows[0] -ne 1) { throw "PlayerHud deterministic authoritative display fixture assertion failed." }
}

function Assert-RestoredState {
    $rows = @(Invoke-HudSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_playerhud_fixture f ON f.user_id=u.id AND f.role_id=r.id
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ($rows.Count -ne 1 -or [int]$rows[0] -ne 1) { throw "PlayerHud fixture exact restore hash assertion failed." }
}

function Assert-ReloginState {
    $rows = @(Invoke-HudSql -Sql @"
SELECT COUNT(*)=1 AND r.money=f.backup_role_money AND r.exp=f.backup_exp AND r.level=f.backup_level
 AND r.zhanDouLi=13800 AND u.money=f.backup_user_money AND u.bd_money=f.backup_bd_money
 AND COALESCE(HEX(r.user_spirit),'')=COALESCE(HEX(f.backup_user_spirit),'')
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_playerhud_fixture f ON f.user_id=u.id AND f.role_id=r.id
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ($rows.Count -ne 1 -or [int]$rows[0] -ne 1) { throw "PlayerHud post-relogin normalized state assertion failed." }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        Invoke-HudSql -Sql $createTableSql
        $existing = @(Invoke-HudSql -Sql "SELECT COUNT(*) FROM unity_validation_playerhud_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) { throw "PlayerHud fixture residue exists for userId=$UserId; restore/cleanup before setup." }
        Invoke-HudSql -Sql @"
INSERT INTO unity_validation_playerhud_fixture(
 user_id,role_id,backup_role_money,backup_exp,backup_level,backup_power,backup_user_money,backup_bd_money,backup_user_spirit,snapshot_hash,applied)
SELECT $UserId,$RoleId,r.money,r.exp,r.level,r.zhanDouLi,u.money,u.bd_money,r.user_spirit,$hashExpression,1
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId;
UPDATE role_info SET money=1000000,exp=0,level=99,zhanDouLi=0 WHERE id=$RoleId;
UPDATE user_info1 SET money=100000,bd_money=100000 WHERE id=$UserId AND role0=$RoleId
"@
        Assert-SetupState
        $row = @((Invoke-HudSql -Sql "SELECT snapshot_hash,CHAR_LENGTH(backup_user_spirit) FROM unity_validation_playerhud_fixture WHERE user_id=$UserId" -ReturnOutput))[0] -split "`t"
        Write-Evidence ([ordered]@{
            schemaVersion=1; module="PlayerHud"; phase="fixture-applied"; userId=$UserId; roleId=$RoleId
            snapshotHash=[string]$row[0]; spiritBytes=[int]$row[1]
            deterministic=[ordered]@{name="T00057";level=99;experience=0;powerAfterLogin=13800;gold=1000000;premium=100000;boundPremium=100000}
            setupAssert="passed"; restoreAssert="pending"; cleanupAssert="pending"; createdUtc=[DateTime]::UtcNow.ToString("O")
        })
        Write-Host "PlayerHud fixture snapshot/setup assertion passed: userId=$UserId roleId=$RoleId hash=$($row[0])"
    }
    "AssertSetup" { Assert-SetupState; Write-Host "PlayerHud fixture live setup assertion passed." }
    "Restore" {
        Assert-ClientsStopped
        Invoke-HudSql -Sql @"
UPDATE role_info r JOIN unity_validation_playerhud_fixture f ON f.user_id=$UserId AND f.role_id=r.id
SET r.money=f.backup_role_money,r.exp=f.backup_exp,r.level=f.backup_level,r.zhanDouLi=f.backup_power,r.user_spirit=f.backup_user_spirit
WHERE r.id=$RoleId;
UPDATE user_info1 u JOIN unity_validation_playerhud_fixture f ON f.user_id=u.id AND f.role_id=$RoleId
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money WHERE u.id=$UserId AND u.role0=$RoleId
"@
        Assert-RestoredState
        Write-Host "PlayerHud fixture restored while retaining snapshot."
    }
    "AssertRestored" { Assert-RestoredState; Write-Host "PlayerHud fixture exact restore assertion passed." }
    "AssertReloginHash" { Assert-ReloginState; Write-Host "PlayerHud post-relogin normalized state assertion passed." }
    "Cleanup" {
        Assert-ClientsStopped
        & $PSCommandPath -Action Restore -UserId $UserId -RoleId $RoleId -EvidencePath $evidence
        if ($LASTEXITCODE -ne 0) { throw "PlayerHud retained restore failed during cleanup." }
        Invoke-HudSql -Sql "DELETE FROM unity_validation_playerhud_fixture WHERE user_id=$UserId"
        $payload=Read-Evidence
        $payload.restoreAssert="passed"; $payload.cleanupAssert="passed"
        $payload | Add-Member -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence $payload
        Write-Host "PlayerHud fixture cleanup completed."
    }
    "AssertCleanup" {
        $remaining = @(Invoke-HudSql -Sql "SELECT COUNT(*) FROM unity_validation_playerhud_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$remaining[-1] -ne 0) { throw "PlayerHud fixture residue remains for userId=$UserId." }
        $payload=Read-Evidence
        if ((Get-LiveHash) -ne [string]$payload.snapshotHash) { throw "PlayerHud post-cleanup live hash differs from snapshot." }
        Write-Host "PlayerHud fixture residual=0 and exact live hash assertion passed."
    }
}
