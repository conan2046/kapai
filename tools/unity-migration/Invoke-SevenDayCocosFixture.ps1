[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [ValidateSet("Day1", "Day2", "Day3", "Day4", "Day5", "Day6", "Day7", "Day7Full", "Incomplete", "Claimable", "Claimed", "ProgressPush", "DuplicateClaim", "InvalidTask", "PurchaseSuccess", "PurchaseInsufficient", "PurchaseLimited")]
    [string]$State = "Day1",
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/SevenDay/cocos/g1-20260808/sevenday-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

$allowedIdentity = ($UserId -eq 7200057 -and $RoleId -eq 1000115) -or
    ($UserId -eq 705213 -and $RoleId -eq 1000006)
if (-not $allowedIdentity) { throw "SevenDay fixture identity is not frozen in SEVEN_DAY_CONTROLS.json." }

function Invoke-SevenDaySql {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "SevenDay fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before SevenDay fixture $Action." }
}

function Get-UserTable {
    $tables = @(Invoke-SevenDaySql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @(
        foreach ($tableName in $tables) {
            if ([string]$tableName -notmatch '^user_info\d*$') { throw "Unsafe user table name: $tableName" }
            $rows = @(Invoke-SevenDaySql "SELECT role0 FROM ``$tableName`` WHERE id=$UserId AND role0=$RoleId")
            if ($rows.Count -eq 1) { [string]$tableName }
        }
    )
    if ($matches.Count -ne 1) { throw "SevenDay userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    $matches[0]
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 10) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "SevenDay fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Initialize-SevenDayValidationConfig {
    $source = Join-Path $root "server\config"
    $destination = Join-Path $root ".local\sevenday-server-validation"
    [IO.Directory]::CreateDirectory($destination) | Out-Null
    Copy-Item -LiteralPath (Join-Path $source "config") -Destination (Join-Path $destination "config") -Force
    foreach ($directory in @("dat", "json", "xml")) {
        Copy-Item -LiteralPath (Join-Path $source $directory) -Destination $destination -Recurse -Force
    }
    $configPath = Join-Path $destination "config"
    $configText = [IO.File]::ReadAllText($configPath, [Text.Encoding]::UTF8)
    foreach ($setting in @(@("local_test_tongbao", "0"), @("local_test_bd_tongbao", "0"))) {
        $pattern = "(?m)^" + [regex]::Escape($setting[0]) + "\s*=.*$"
        if ([regex]::IsMatch($configText, $pattern)) { $configText = [regex]::Replace($configText, $pattern, "$($setting[0])=$($setting[1])") }
        else { $configText = [regex]::Replace($configText, "(?m)^\[server\]\s*$", "[server]`r`n$($setting[0])=$($setting[1])", 1) }
    }
    [IO.File]::WriteAllText($configPath, $configText, [Text.UTF8Encoding]::new($false))
}

$day = if ($State -match '^Day([1-7])$') { [int]$Matches[1] } else { 7 }
$mode = switch ($State) {
    "Claimable" { 1 }
    "DuplicateClaim" { 1 }
    "InvalidTask" { 1 }
    "Claimed" { 2 }
    "Day7Full" { 3 }
    "ProgressPush" { 4 }
    default { 0 }
}
if ($State -eq "Incomplete") { $day = 1; $mode = 4 }
$userMoney = if ($State -eq "PurchaseInsufficient") { 0 } else { 100000 }
$boundMoney = 0
$roleMoney = 1000000
$regTime = [DateTimeOffset]::new([DateTime]::Today.AddHours(12).AddDays(-($day - 1))).ToUnixTimeSeconds()

if ($Action -in @("Setup", "Restore", "Cleanup")) { Assert-ClientsStopped }
$userTable = Get-UserTable
$hashExpression = "LOWER(SHA2(CONCAT_WS('|',COALESCE(r.reg_time,''),COALESCE(r.mission,''),COALESCE(r.package,''),COALESCE(r.mysteryShop,''),COALESCE(r.save_data,''),COALESCE(r.save_val,''),COALESCE(r.clientstring,''),COALESCE(r.questIds,''),COALESCE(CAST(r.money AS CHAR),''),COALESCE(CAST(u.money AS CHAR),''),COALESCE(CAST(u.bd_money AS CHAR),'')),256))"

Invoke-SevenDaySql @"
CREATE TABLE IF NOT EXISTS unity_validation_sevenday_fixture (
 user_id INT UNSIGNED NOT NULL, role_id INT UNSIGNED NOT NULL, user_table VARCHAR(64) NOT NULL,
 enabled TINYINT UNSIGNED NOT NULL DEFAULT 1, applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 fixture_state VARCHAR(32) NOT NULL, fixture_day TINYINT UNSIGNED NOT NULL, fixture_mode TINYINT UNSIGNED NOT NULL,
 backup_reg_time MEDIUMTEXT NULL, backup_mission MEDIUMTEXT NULL, backup_package MEDIUMTEXT NULL,
 backup_shop MEDIUMTEXT NULL, backup_save_data MEDIUMTEXT NULL, backup_save_val MEDIUMTEXT NULL,
 backup_clientstring MEDIUMTEXT NULL, backup_quest_ids MEDIUMTEXT NULL,
 backup_role_money BIGINT NULL, backup_user_money BIGINT NULL, backup_bd_money BIGINT NULL,
 snapshot_hash CHAR(64) NOT NULL, PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"@ | Out-Null

function Restore-SevenDaySnapshot {
    Invoke-SevenDaySql @"
UPDATE role_info r JOIN unity_validation_sevenday_fixture f ON f.role_id=r.id
SET r.reg_time=f.backup_reg_time,r.mission=f.backup_mission,r.package=f.backup_package,
 r.mysteryShop=f.backup_shop,r.save_data=f.backup_save_data,r.save_val=f.backup_save_val,
 r.clientstring=f.backup_clientstring,r.questIds=f.backup_quest_ids,r.money=f.backup_role_money
WHERE f.user_id=$UserId AND f.role_id=$RoleId;
UPDATE ``$userTable`` u JOIN unity_validation_sevenday_fixture f ON f.user_id=u.id AND f.role_id=u.role0
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money WHERE f.user_id=$UserId AND f.role_id=$RoleId;
UPDATE unity_validation_sevenday_fixture SET applied=0 WHERE user_id=$UserId AND role_id=$RoleId;
"@ | Out-Null
}

switch ($Action) {
    "Setup" {
        Initialize-SevenDayValidationConfig
        $existing = @(Invoke-SevenDaySql "SELECT COUNT(*) FROM unity_validation_sevenday_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ([int]$existing[-1] -eq 0) {
            Invoke-SevenDaySql @"
INSERT INTO unity_validation_sevenday_fixture(
 user_id,role_id,user_table,enabled,applied,fixture_state,fixture_day,fixture_mode,
 backup_reg_time,backup_mission,backup_package,backup_shop,backup_save_data,backup_save_val,
 backup_clientstring,backup_quest_ids,backup_role_money,backup_user_money,backup_bd_money,snapshot_hash)
SELECT $UserId,$RoleId,'$userTable',1,0,'$State',$day,$mode,
 r.reg_time,r.mission,r.package,r.mysteryShop,r.save_data,r.save_val,r.clientstring,r.questIds,
 r.money,u.money,u.bd_money,$hashExpression
FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId;
"@ | Out-Null
        }
        elseif ([int]$existing[-1] -eq 1) { Restore-SevenDaySnapshot }
        else { throw "SevenDay fixture row is ambiguous." }

        Invoke-SevenDaySql @"
UPDATE role_info SET reg_time='$regTime',mission='',package=(SELECT backup_package FROM unity_validation_sevenday_fixture WHERE user_id=$UserId),
 mysteryShop='',save_data=(SELECT backup_save_data FROM unity_validation_sevenday_fixture WHERE user_id=$UserId),
 save_val=(SELECT backup_save_val FROM unity_validation_sevenday_fixture WHERE user_id=$UserId),
 clientstring=(SELECT backup_clientstring FROM unity_validation_sevenday_fixture WHERE user_id=$UserId),
 questIds=(SELECT backup_quest_ids FROM unity_validation_sevenday_fixture WHERE user_id=$UserId),money=$roleMoney WHERE id=$RoleId;
UPDATE ``$userTable`` SET money=$userMoney,bd_money=$boundMoney WHERE id=$UserId AND role0=$RoleId;
UPDATE unity_validation_sevenday_fixture SET enabled=1,applied=0,fixture_state='$State',fixture_day=$day,fixture_mode=$mode
WHERE user_id=$UserId AND role_id=$RoleId;
"@ | Out-Null
        $row = @(Invoke-SevenDaySql "SELECT snapshot_hash FROM unity_validation_sevenday_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        Write-Evidence ([ordered]@{
            schemaVersion=1;module="SevenDay";action="Setup";userId=$UserId;roleId=$RoleId;userTable=$userTable;
            fixtureState=$State;fixtureDay=$day;fixtureMode=$mode;regTime=$regTime;snapshotHash=$row[-1];
            injected=[ordered]@{roleMoney=$roleMoney;userMoney=$userMoney;boundMoney=$boundMoney;mission="server-init-then-local-memory-fixture";shop="empty-on-disk"};
            serverConfigDirectory=".local/sevenday-server-validation";createdUtc=[DateTime]::UtcNow.ToString('o')
        })
        Write-Output "SevenDay fixture setup: state=$State day=$day mode=$mode snapshot=$($row[-1])"
    }
    "AssertSetup" {
        $row = @(Invoke-SevenDaySql "SELECT COUNT(*)=1 AND applied=1 AND fixture_state='$State' AND fixture_day=$day AND fixture_mode=$mode FROM unity_validation_sevenday_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[-1] -ne '1') { throw "SevenDay live fixture application assertion failed." }
        $actualDay = @(Invoke-SevenDaySql "SELECT CEIL((UNIX_TIMESTAMP(CURDATE()+INTERVAL 1 DAY)-CAST(reg_time AS UNSIGNED))/86400) FROM role_info WHERE id=$RoleId")
        if ($actualDay.Count -ne 1 -or [int]$actualDay[-1] -ne $day) { throw "SevenDay GetRegDay SQL mirror mismatch: expected=$day actual=$($actualDay -join ',')" }
        Write-Output "SevenDay fixture assert passed: state=$State day=$day mode=$mode"
    }
    "Restore" {
        Restore-SevenDaySnapshot
        Write-Output "SevenDay fixture restored while retaining snapshot."
    }
    "AssertRestored" {
        $row = @(Invoke-SevenDaySql "SELECT COUNT(*)=1 AND f.applied=0 AND $hashExpression=f.snapshot_hash FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId JOIN unity_validation_sevenday_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId WHERE r.id=$RoleId")
        if ($row.Count -ne 1 -or $row[-1] -ne '1') { throw "SevenDay restored hash mismatch." }
        $snapshot = Read-Evidence
        $snapshot.action = "AssertRestored"
        $snapshot | Add-Member -Force -NotePropertyName restoredHash -NotePropertyValue ([string]$snapshot.snapshotHash)
        $snapshot | Add-Member -Force -NotePropertyName restored -NotePropertyValue $true
        Write-Evidence $snapshot
        Write-Output "SevenDay fixture restore hash passed: $($snapshot.snapshotHash)"
    }
    "Cleanup" {
        Restore-SevenDaySnapshot
        Invoke-SevenDaySql "DELETE FROM unity_validation_sevenday_fixture WHERE user_id=$UserId AND role_id=$RoleId" | Out-Null
        Write-Output "SevenDay fixture cleanup complete."
    }
    "AssertCleanup" {
        $row = @(Invoke-SevenDaySql "SELECT COUNT(*) FROM unity_validation_sevenday_fixture WHERE user_id=$UserId OR role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[-1] -ne '0') { throw "SevenDay fixture residual rows remain: $($row -join ',')" }
        Write-Output "SevenDay fixture residual count=0"
    }
    "AssertReloginHash" {
        $snapshot = Read-Evidence
        $row = @(Invoke-SevenDaySql "SELECT $hashExpression FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId")
        if ($row.Count -ne 1 -or $row[-1] -ne [string]$snapshot.snapshotHash) { throw "SevenDay post-login hash mismatch." }
        $snapshot.action = "AssertReloginHash"
        $snapshot | Add-Member -Force -NotePropertyName postLoginHash -NotePropertyValue ([string]$row[-1])
        $snapshot | Add-Member -Force -NotePropertyName residualCount -NotePropertyValue 0
        Write-Evidence $snapshot
        Write-Output "SevenDay post-login hash passed: $($row[-1])"
    }
}
