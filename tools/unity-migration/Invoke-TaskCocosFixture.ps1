[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup")]
    [string]$Action,

    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [uint32]$ActiveValue = 50,
    [string]$EvidencePath = ".local/ui-fidelity/Task/cocos/g1-20260727/task-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([System.IO.Path]::IsPathRooted($EvidencePath)) {
    $EvidencePath
} else {
    Join-Path $root $EvidencePath
}

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) {
    throw "mysql.exe not found: $mysql"
}

function Invoke-TaskSql {
    param(
        [Parameter(Mandatory = $true)][string]$Sql,
        [switch]$ReturnOutput
    )
    $arguments = @(
        "--protocol=tcp",
        "--host=127.0.0.1",
        "--port=3306",
        "--user=root",
        "--password=123456",
        "--default-character-set=utf8",
        "--database=fxl_game_local",
        "--batch",
        "--raw",
        "--skip-column-names",
        "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Task fixture SQL failed: $($output -join [Environment]::NewLine)"
    }
    if ($ReturnOutput) {
        return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
    }
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai,ProjectX -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "Stop kapai.exe and ProjectX.exe before $Action so the fixed-role snapshot cannot race a save."
    }
}

$hashExpression = @"
SHA2(CONCAT_WS('|',
COALESCE(TO_BASE64(r.mission),''),
COALESCE(TO_BASE64(r.save_data),''),
COALESCE(TO_BASE64(r.package),''),
COALESCE(CAST(r.money AS CHAR),''),
COALESCE(CAST(u.money AS CHAR),''),
COALESCE(CAST(u.bd_money AS CHAR),'')
),256)
"@ -replace "\r?\n", ""

$createTableSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_task_fixture (
 user_id INT UNSIGNED NOT NULL,
 role_id INT UNSIGNED NOT NULL DEFAULT 0,
 active_value INT UNSIGNED NOT NULL DEFAULT 50,
 enabled TINYINT UNSIGNED NOT NULL DEFAULT 1,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 backup_mission MEDIUMTEXT NULL,
 backup_save_data MEDIUMTEXT NULL,
 backup_package MEDIUMTEXT NULL,
 backup_role_money BIGINT NULL,
 backup_user_money BIGINT NULL,
 backup_bd_money BIGINT NULL,
 snapshot_hash CHAR(64) NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@

$setupAssertSql = @"
SET @task_ok=(
 SELECT COUNT(*)=1
 FROM unity_validation_task_fixture
 WHERE user_id=$UserId AND role_id=$RoleId AND active_value=$ActiveValue
   AND enabled=1 AND applied=0 AND CHAR_LENGTH(snapshot_hash)=64
);
SET @task_sql=IF(@task_ok,'SELECT 1','SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT=''Task fixture setup assertion failed''');
PREPARE task_stmt FROM @task_sql;
EXECUTE task_stmt;
DEALLOCATE PREPARE task_stmt
"@

$appliedAssertSql = @"
SET @task_ok=(
 SELECT COUNT(*)=1
 FROM unity_validation_task_fixture
 WHERE user_id=$UserId AND role_id=$RoleId AND active_value=$ActiveValue
   AND enabled=1 AND applied=1 AND CHAR_LENGTH(snapshot_hash)=64
);
SET @task_sql=IF(@task_ok,'SELECT 1','SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT=''Task fixture application assertion failed''');
PREPARE task_stmt FROM @task_sql;
EXECUTE task_stmt;
DEALLOCATE PREPARE task_stmt
"@

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        Invoke-TaskSql -Sql $createTableSql
        $existing = @(Invoke-TaskSql -Sql "SELECT COUNT(*) FROM unity_validation_task_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) {
            throw "A Task fixture row already exists for userId=$UserId. Run Cleanup or inspect it before replacing the snapshot."
        }

        $setupSql = @"
INSERT INTO unity_validation_task_fixture(
 user_id,role_id,active_value,enabled,applied,
 backup_mission,backup_save_data,backup_package,backup_role_money,
 backup_user_money,backup_bd_money,snapshot_hash
)
SELECT $UserId,$RoleId,$ActiveValue,1,0,
 r.mission,r.save_data,r.package,r.money,u.money,u.bd_money,$hashExpression
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@
        Invoke-TaskSql -Sql $setupSql
        Invoke-TaskSql -Sql $setupAssertSql

        $snapshot = @(Invoke-TaskSql -Sql @"
SELECT snapshot_hash,LENGTH(backup_mission),LENGTH(backup_save_data),LENGTH(backup_package),
 backup_role_money,backup_user_money,backup_bd_money
FROM unity_validation_task_fixture WHERE user_id=$UserId
"@ -ReturnOutput)
        $values = ($snapshot[-1] -split "`t")
        $payload = [ordered]@{
            module = "Task"
            phase = "before-injection"
            userId = $UserId
            roleId = $RoleId
            activeValue = $ActiveValue
            snapshotHash = $values[0]
            missionLength = [int]$values[1]
            saveDataLength = [int]$values[2]
            packageLength = [int]$values[3]
            roleMoney = [long]$values[4]
            userMoney = [long]$values[5]
            boundMoney = [long]$values[6]
            setupAssertSql = "passed"
            cleanupAssertSql = "pending"
            createdUtc = [DateTime]::UtcNow.ToString("O")
        }
        [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($evidence)) | Out-Null
        [System.IO.File]::WriteAllText(
            $evidence,
            (($payload | ConvertTo-Json -Depth 4) + "`n"),
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Host "Task fixture snapshot created: userId=$UserId roleId=$RoleId hash=$($values[0])"
    }
    "AssertSetup" {
        Invoke-TaskSql -Sql $appliedAssertSql
        Write-Host "Task fixture application assertion passed: userId=$UserId roleId=$RoleId"
    }
    "Restore" {
        Assert-ClientsStopped
        $existing = @(Invoke-TaskSql -Sql "SELECT COUNT(*) FROM unity_validation_task_fixture WHERE user_id=$UserId AND role_id=$RoleId" -ReturnOutput)
        if ([int]$existing[-1] -ne 1) { throw "Task fixture snapshot missing before retained restore." }
        Invoke-TaskSql -Sql @"
UPDATE role_info r
JOIN unity_validation_task_fixture f ON f.role_id=r.id AND f.user_id=$UserId
SET r.mission=f.backup_mission,
    r.save_data=f.backup_save_data,
    r.package=f.backup_package,
    r.money=f.backup_role_money
WHERE r.id=$RoleId;
UPDATE user_info1 u
JOIN unity_validation_task_fixture f ON f.user_id=u.id
SET u.money=f.backup_user_money,
    u.bd_money=f.backup_bd_money
WHERE u.id=$UserId AND u.role0=$RoleId
"@
        $restored = @(Invoke-TaskSql -Sql @"
SELECT $hashExpression=f.snapshot_hash
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_task_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([int]$restored[-1] -ne 1) { throw "Task retained snapshot restore assertion failed." }
        Write-Host "Task fixture restored while retaining snapshot: userId=$UserId roleId=$RoleId"
    }
    "AssertRestored" {
        $restored = @(Invoke-TaskSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_task_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([int]$restored[-1] -ne 1) { throw "Task retained snapshot hash assertion failed." }
        Write-Host "Task retained snapshot hash assertion passed: userId=$UserId roleId=$RoleId"
    }
    "Cleanup" {
        Assert-ClientsStopped
        Invoke-TaskSql -Sql $createTableSql
        $cleanupSql = @"
SET @task_exists=(SELECT COUNT(*) FROM unity_validation_task_fixture WHERE user_id=$UserId AND role_id=$RoleId);
SET @task_sql=IF(@task_exists=1,'SELECT 1','SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT=''Task fixture snapshot missing before cleanup''');
PREPARE task_stmt FROM @task_sql;
EXECUTE task_stmt;
DEALLOCATE PREPARE task_stmt;

UPDATE role_info r
JOIN unity_validation_task_fixture f ON f.role_id=r.id AND f.user_id=$UserId
SET r.mission=f.backup_mission,
    r.save_data=f.backup_save_data,
    r.package=f.backup_package,
    r.money=f.backup_role_money
WHERE r.id=$RoleId;

UPDATE user_info1 u
JOIN unity_validation_task_fixture f ON f.user_id=u.id
SET u.money=f.backup_user_money,
    u.bd_money=f.backup_bd_money
WHERE u.id=$UserId AND u.role0=$RoleId;

SET @task_restore_ok=(
 SELECT $hashExpression=f.snapshot_hash
 FROM role_info r
 JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
 JOIN unity_validation_task_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
 WHERE r.id=$RoleId
);
SET @task_sql=IF(@task_restore_ok=1,'SELECT 1','SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT=''Task fixture cleanup restore assertion failed''');
PREPARE task_stmt FROM @task_sql;
EXECUTE task_stmt;
DEALLOCATE PREPARE task_stmt;

DELETE FROM unity_validation_task_fixture WHERE user_id=$UserId;
SET @task_deleted=(SELECT COUNT(*)=0 FROM unity_validation_task_fixture WHERE user_id=$UserId);
SET @task_sql=IF(@task_deleted=1,'SELECT 1','SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT=''Task fixture cleanup row assertion failed''');
PREPARE task_stmt FROM @task_sql;
EXECUTE task_stmt;
DEALLOCATE PREPARE task_stmt
"@
        Invoke-TaskSql -Sql $cleanupSql

        if (Test-Path -LiteralPath $evidence -PathType Leaf) {
            $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
            $payload.cleanupAssertSql = "passed"
            $payload | Add-Member -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
            [System.IO.File]::WriteAllText(
                $evidence,
                (($payload | ConvertTo-Json -Depth 4) + "`n"),
                [System.Text.UTF8Encoding]::new($false)
            )
        }
        Write-Host "Task fixture cleanup and exact snapshot restore passed: userId=$UserId roleId=$RoleId"
    }
    "AssertCleanup" {
        $result = @(Invoke-TaskSql -Sql "SELECT COUNT(*) FROM unity_validation_task_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$result[-1] -ne 0) {
            throw "Task fixture cleanup assertion failed for userId=$UserId"
        }
        if (Test-Path -LiteralPath $evidence -PathType Leaf) {
            $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
            $current = @(Invoke-TaskSql -Sql @"
SELECT $hashExpression
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
            if ([string]$current[-1] -ne [string]$payload.snapshotHash) {
                throw "Task fixture restored hash assertion failed for userId=$UserId"
            }
            $payload.cleanupAssertSql = "passed"
            $payload | Add-Member -NotePropertyName restoredHashAssertSql -NotePropertyValue "passed" -Force
            $payload | Add-Member -NotePropertyName restoredHashVerifiedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
            [System.IO.File]::WriteAllText(
                $evidence,
                (($payload | ConvertTo-Json -Depth 4) + "`n"),
                [System.Text.UTF8Encoding]::new($false)
            )
        }
        Write-Host "Task fixture cleanup assertion passed: userId=$UserId"
    }
}
