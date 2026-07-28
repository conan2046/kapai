[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "Setup",
        "AssertSetup",
        "ApplyFailure",
        "RecordSuccess",
        "RecordFailure",
        "Restore",
        "AssertRestored",
        "Cleanup",
        "AssertCleanup"
    )]
    [string]$Action,

    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/Shop/cocos/g1-20260728/shop-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([System.IO.Path]::IsPathRooted($EvidencePath)) {
    $EvidencePath
} else {
    Join-Path $root $EvidencePath
}
$userDefault = Join-Path $env:LOCALAPPDATA "ProjectX/UserDefault.xml"
$userDefaultBackup = Join-Path ([System.IO.Path]::GetDirectoryName($evidence)) "shop-userdefault-before.xml"

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) {
    throw "mysql.exe not found: $mysql"
}

function Invoke-ShopSql {
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
        "--default-character-set=utf8mb4",
        "--database=fxl_game_local",
        "--batch",
        "--raw",
        "--skip-column-names",
        "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Shop fixture SQL failed: $($output -join [Environment]::NewLine)"
    }
    if ($ReturnOutput) {
        return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
    }
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "Stop kapai.exe, ProjectX.exe and Unity.exe before $Action so the Shop snapshot cannot race a save."
    }
}

function Write-Evidence {
    param([Parameter(Mandatory = $true)]$Payload)
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [System.IO.File]::WriteAllText(
        $evidence,
        (($Payload | ConvertTo-Json -Depth 8) + "`n"),
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
        throw "Shop fixture evidence is missing: $evidence"
    }
    return Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

$hashExpression = @"
SHA2(CONCAT_WS('|',
 COALESCE(r.package,''),
 COALESCE(r.mysteryShop,''),
 COALESCE(r.save_data,''),
 COALESCE(r.mission,''),
 COALESCE(r.money,''),
 COALESCE(u.money,''),
 COALESCE(u.bd_money,'')
),256)
"@ -replace "\r?\n", ""

$createTableSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_shop_fixture (
 user_id INT UNSIGNED NOT NULL,
 role_id INT UNSIGNED NOT NULL,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 mode VARCHAR(16) NOT NULL DEFAULT 'snapshot',
 snapshot_hash CHAR(64) NOT NULL,
 backup_package MEDIUMTEXT NULL,
 backup_shop MEDIUMTEXT NULL,
 backup_save_data MEDIUMTEXT NULL,
 backup_mission MEDIUMTEXT NULL,
 backup_role_money BIGINT NULL,
 backup_user_money BIGINT NULL,
 backup_bd_money BIGINT NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@

function Restore-ShopSnapshot {
    Invoke-ShopSql -Sql @"
UPDATE role_info r
JOIN unity_validation_shop_fixture f ON f.role_id=r.id AND f.user_id=$UserId
SET r.package=f.backup_package,
    r.mysteryShop=f.backup_shop,
    r.save_data=f.backup_save_data,
    r.mission=f.backup_mission,
    r.money=f.backup_role_money
WHERE r.id=$RoleId;
UPDATE user_info1 u
JOIN unity_validation_shop_fixture f ON f.user_id=u.id
SET u.money=f.backup_user_money,
    u.bd_money=f.backup_bd_money
WHERE u.id=$UserId AND u.role0=$RoleId
"@
    $restored = @(Invoke-ShopSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_shop_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ([int]$restored[-1] -ne 1) {
        throw "Shop retained snapshot restore assertion failed."
    }
    if (Test-Path -LiteralPath $userDefaultBackup -PathType Leaf) {
        Copy-Item -LiteralPath $userDefaultBackup -Destination $userDefault -Force
    }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        Invoke-ShopSql -Sql $createTableSql
        $existing = @(Invoke-ShopSql -Sql "SELECT COUNT(*) FROM unity_validation_shop_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) {
            throw "A Shop fixture row already exists for userId=$UserId. Run Cleanup or inspect it before replacing the snapshot."
        }

        [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($evidence)) | Out-Null
        if (Test-Path -LiteralPath $userDefault -PathType Leaf) {
            Copy-Item -LiteralPath $userDefault -Destination $userDefaultBackup -Force
        }

        Invoke-ShopSql -Sql @"
INSERT INTO unity_validation_shop_fixture(
 user_id,role_id,applied,mode,snapshot_hash,
 backup_package,backup_shop,backup_save_data,backup_mission,
 backup_role_money,backup_user_money,backup_bd_money
)
SELECT $UserId,$RoleId,0,'snapshot',$hashExpression,
       r.package,r.mysteryShop,r.save_data,r.mission,
       r.money,u.money,u.bd_money
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId;

UPDATE role_info SET mysteryShop='',money=1000000 WHERE id=$RoleId;
UPDATE user_info1 SET money=100000,bd_money=100000 WHERE id=$UserId AND role0=$RoleId;
UPDATE unity_validation_shop_fixture
SET applied=1,mode='success'
WHERE user_id=$UserId AND role_id=$RoleId
"@

        $asserted = @(Invoke-ShopSql -Sql @"
SELECT COUNT(*)=1
FROM unity_validation_shop_fixture f
JOIN role_info r ON r.id=f.role_id
JOIN user_info1 u ON u.id=f.user_id AND u.role0=f.role_id
WHERE f.user_id=$UserId AND f.role_id=$RoleId
  AND f.applied=1 AND f.mode='success' AND CHAR_LENGTH(f.snapshot_hash)=64
  AND COALESCE(r.mysteryShop,'')='' AND r.money=1000000
  AND u.money=100000 AND u.bd_money=100000
"@ -ReturnOutput)
        if ([int]$asserted[-1] -ne 1) {
            throw "Shop success fixture setup assertion failed."
        }

        $snapshot = @(Invoke-ShopSql -Sql @"
SELECT snapshot_hash,LENGTH(backup_package),LENGTH(backup_shop),
       LENGTH(backup_save_data),LENGTH(backup_mission),
       backup_role_money,backup_user_money,backup_bd_money
FROM unity_validation_shop_fixture
WHERE user_id=$UserId AND role_id=$RoleId
"@ -ReturnOutput)
        $values = $snapshot[-1] -split "`t"
        $payload = [ordered]@{
            module = "Shop"
            phase = "success-fixture-applied"
            userId = $UserId
            roleId = $RoleId
            snapshotHash = $values[0]
            packageLength = [int]$values[1]
            shopLength = [int]$values[2]
            saveDataLength = [int]$values[3]
            missionLength = [int]$values[4]
            originalRoleMoney = [long]$values[5]
            originalUserMoney = [long]$values[6]
            originalBoundMoney = [long]$values[7]
            successBaseline = [ordered]@{
                roleMoney = 1000000
                userMoney = 100000
                boundMoney = 100000
                shopState = "empty-on-disk; initialized by server"
            }
            setupAssertSql = "passed"
            successAssertSql = "pending"
            failureAssertSql = "pending"
            cleanupAssertSql = "pending"
            userDefaultSha256 = if (Test-Path -LiteralPath $userDefaultBackup) {
                (Get-FileHash -Algorithm SHA256 -LiteralPath $userDefaultBackup).Hash
            } else { "" }
            createdUtc = [DateTime]::UtcNow.ToString("O")
        }
        Write-Evidence -Payload $payload
        Write-Host "Shop fixture snapshot and success baseline created: userId=$UserId roleId=$RoleId hash=$($values[0])"
    }

    "AssertSetup" {
        $asserted = @(Invoke-ShopSql -Sql @"
SELECT COUNT(*)=1
FROM unity_validation_shop_fixture f
JOIN role_info r ON r.id=f.role_id
JOIN user_info1 u ON u.id=f.user_id AND u.role0=f.role_id
WHERE f.user_id=$UserId AND f.role_id=$RoleId
  AND f.applied=1 AND f.mode IN ('success','failure')
  AND CHAR_LENGTH(f.snapshot_hash)=64
"@ -ReturnOutput)
        if ([int]$asserted[-1] -ne 1) {
            throw "Shop fixture application assertion failed."
        }
        Write-Host "Shop fixture application assertion passed: userId=$UserId roleId=$RoleId"
    }

    "RecordSuccess" {
        Assert-ClientsStopped
        $result = @(Invoke-ShopSql -Sql @"
SELECT r.money,u.money,u.bd_money,LENGTH(COALESCE(r.mysteryShop,''))
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        $values = $result[-1] -split "`t"
        if ([long]$values[0] -ne 1100000 -or [long]$values[1] -ne 99980 -or [long]$values[2] -ne 100000 -or [int]$values[3] -le 0) {
            throw "Shop success assertion failed: roleMoney=$($values[0]) userMoney=$($values[1]) boundMoney=$($values[2]) shopLength=$($values[3])"
        }
        $payload = Read-Evidence
        $payload.successAssertSql = "passed"
        $payload | Add-Member -NotePropertyName successResult -NotePropertyValue ([ordered]@{
            tid = 1001
            quantity = 1
            roleMoneyBefore = 1000000
            roleMoneyAfter = [long]$values[0]
            userMoneyBefore = 100000
            userMoneyAfter = [long]$values[1]
            boundMoneyAfter = [long]$values[2]
            shopLength = [int]$values[3]
        }) -Force
        $payload | Add-Member -NotePropertyName successVerifiedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence -Payload $payload
        Write-Host "Shop success result passed: userMoney=100000->99980 roleMoney=1000000->1100000"
    }

    "ApplyFailure" {
        Assert-ClientsStopped
        Restore-ShopSnapshot
        Invoke-ShopSql -Sql @"
UPDATE role_info SET mysteryShop='',money=1000000 WHERE id=$RoleId;
UPDATE user_info1 SET money=100000,bd_money=100000 WHERE id=$UserId AND role0=$RoleId;
UPDATE unity_validation_shop_fixture
SET applied=1,mode='failure'
WHERE user_id=$UserId AND role_id=$RoleId
"@
        $asserted = @(Invoke-ShopSql -Sql @"
SELECT COUNT(*)=1
FROM unity_validation_shop_fixture f
JOIN role_info r ON r.id=f.role_id
JOIN user_info1 u ON u.id=f.user_id AND u.role0=f.role_id
WHERE f.user_id=$UserId AND f.role_id=$RoleId
  AND f.applied=1 AND f.mode='failure'
  AND COALESCE(r.mysteryShop,'')='' AND r.money=1000000
  AND u.money=100000 AND u.bd_money=100000
"@ -ReturnOutput)
        if ([int]$asserted[-1] -ne 1) {
            throw "Shop insufficient-currency fixture assertion failed."
        }
        $payload = Read-Evidence
        $payload.phase = "failure-fixture-applied"
        $payload | Add-Member -NotePropertyName failureBaseline -NotePropertyValue ([ordered]@{
            roleMoney = 1000000
            userMoney = 100000
            boundMoney = 100000
            shopState = "empty-on-disk; initialized by server"
            localLoginMinimum = "local_test login enforces user money and bound money >= 100000"
            failureMethod = "select shop id 1015 and request quantity 200; total price 540000 exceeds 100000"
        }) -Force
        Write-Evidence -Payload $payload
        Write-Host "Shop insufficient-currency baseline applied: userId=$UserId roleId=$RoleId"
    }

    "RecordFailure" {
        Assert-ClientsStopped
        $result = @(Invoke-ShopSql -Sql @"
SELECT r.money,u.money,u.bd_money,LENGTH(COALESCE(r.mysteryShop,''))
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        $values = $result[-1] -split "`t"
        if ([long]$values[0] -ne 1000000 -or [long]$values[1] -ne 100000 -or [long]$values[2] -ne 100000 -or [int]$values[3] -le 0) {
            throw "Shop failure assertion failed: roleMoney=$($values[0]) userMoney=$($values[1]) boundMoney=$($values[2]) shopLength=$($values[3])"
        }
        $payload = Read-Evidence
        $payload.failureAssertSql = "passed"
        $payload | Add-Member -NotePropertyName failureResult -NotePropertyValue ([ordered]@{
            tid = 1015
            quantity = 200
            unitPrice = 2700
            totalPrice = 540000
            expected = "材料不足; balances and shop purchase counts unchanged"
            roleMoneyAfter = [long]$values[0]
            userMoneyAfter = [long]$values[1]
            boundMoneyAfter = [long]$values[2]
            shopLength = [int]$values[3]
        }) -Force
        $payload | Add-Member -NotePropertyName failureVerifiedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence -Payload $payload
        Write-Host "Shop insufficient-currency result passed: balances unchanged"
    }

    "Restore" {
        Assert-ClientsStopped
        Restore-ShopSnapshot
        Write-Host "Shop fixture restored while retaining snapshot: userId=$UserId roleId=$RoleId"
    }

    "AssertRestored" {
        $payload = Read-Evidence
        $current = @(Invoke-ShopSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_shop_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([int]$current[-1] -ne 1 -or [string]::IsNullOrWhiteSpace([string]$payload.snapshotHash)) {
            throw "Shop retained snapshot restored assertion failed for userId=$UserId"
        }
        Write-Host "Shop retained snapshot restored assertion passed: userId=$UserId hash=$($payload.snapshotHash)"
    }

    "Cleanup" {
        Assert-ClientsStopped
        Invoke-ShopSql -Sql $createTableSql
        $existing = @(Invoke-ShopSql -Sql "SELECT COUNT(*) FROM unity_validation_shop_fixture WHERE user_id=$UserId AND role_id=$RoleId" -ReturnOutput)
        if ([int]$existing[-1] -ne 1) {
            throw "Shop fixture snapshot missing before cleanup."
        }
        Restore-ShopSnapshot
        Invoke-ShopSql -Sql "DELETE FROM unity_validation_shop_fixture WHERE user_id=$UserId"

        $payload = Read-Evidence
        $payload.phase = "restored"
        $payload.cleanupAssertSql = "passed"
        $payload | Add-Member -NotePropertyName restoredHashAssertSql -NotePropertyValue "passed" -Force
        $payload | Add-Member -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence -Payload $payload
        if (Test-Path -LiteralPath $userDefaultBackup -PathType Leaf) {
            Remove-Item -LiteralPath $userDefaultBackup -Force
        }
        Write-Host "Shop fixture cleanup and exact snapshot restore passed: userId=$UserId roleId=$RoleId"
    }

    "AssertCleanup" {
        $fixtureRows = @(Invoke-ShopSql -Sql "SELECT COUNT(*) FROM unity_validation_shop_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$fixtureRows[-1] -ne 0) {
            throw "Shop fixture cleanup assertion failed for userId=$UserId"
        }
        $payload = Read-Evidence
        $current = @(Invoke-ShopSql -Sql @"
SELECT $hashExpression
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([string]$current[-1] -ne [string]$payload.snapshotHash) {
            throw "Shop fixture restored hash assertion failed for userId=$UserId"
        }
        if ($payload.cleanupAssertSql -ne "passed") {
            throw "Shop fixture evidence does not record cleanup pass."
        }
        Write-Host "Shop fixture cleanup assertion passed: userId=$UserId hash=$($payload.snapshotHash)"
    }
}
