[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [ValidateSet("Claimable", "Isolation")][string]$State = "Claimable",
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/SevenDay/unity/g5/seven-day-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$roleBackup = "codex_sevenday_role_backup"
$userBackup = "codex_sevenday_user_backup"

$allowed = ($UserId -eq 7200057 -and $RoleId -eq 1000115) -or
    ($UserId -eq 705213 -and $RoleId -eq 1000006)
if (-not $allowed) { throw "SevenDay fixture identity is not frozen in SEVENDAY_CONTROLS.json." }
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-SevenDaySql([string]$Sql) {
    $args = @("--protocol=tcp", "--ssl-mode=DISABLED", "--host=127.0.0.1", "--port=3306",
        "--user=root", "--password=123456", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql")
    $output = @(& $mysql @args 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "SevenDay fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before SevenDay fixture $Action." }
}

function Get-UserTable {
    $tables = @(Invoke-SevenDaySql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @($tables | Where-Object {
        $_ -match '^user_info\d*$' -and @(Invoke-SevenDaySql "SELECT id FROM ``$_`` WHERE id=$UserId AND role0=$RoleId").Count -eq 1
    })
    if ($matches.Count -ne 1) { throw "SevenDay userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    [string]$matches[0]
}

function Get-RoleHash {
    $rows = @(Invoke-SevenDaySql "SELECT SHA2(CONCAT_WS('|',COALESCE(mission,''),COALESCE(package,''),COALESCE(money,''),COALESCE(save_data,''),COALESCE(clientstring,'')),256) FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "SevenDay role_info row is missing for roleId=$RoleId." }
    [string]$rows[0]
}

function Write-Evidence($value) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($value | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}
function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "SevenDay fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

if ($Action -in @("Setup", "Restore", "Cleanup")) { Assert-ClientsStopped }
switch ($Action) {
    "Setup" {
        $userTable = Get-UserTable
        $hash = Get-RoleHash
        Invoke-SevenDaySql "DROP TABLE IF EXISTS ``$roleBackup``; CREATE TABLE ``$roleBackup`` LIKE role_info; INSERT INTO ``$roleBackup`` SELECT * FROM role_info WHERE id=$RoleId; DROP TABLE IF EXISTS ``$userBackup``; CREATE TABLE ``$userBackup`` LIKE ``$userTable``; INSERT INTO ``$userBackup`` SELECT * FROM ``$userTable`` WHERE id=$UserId" | Out-Null
        Invoke-SevenDaySql "CREATE TABLE IF NOT EXISTS unity_validation_seven_day_fixture (user_id INT UNSIGNED NOT NULL PRIMARY KEY, role_id INT UNSIGNED NOT NULL DEFAULT 0, claimable_quest_id SMALLINT UNSIGNED NOT NULL, enabled TINYINT UNSIGNED NOT NULL DEFAULT 1, applied TINYINT UNSIGNED NOT NULL DEFAULT 0) ENGINE=InnoDB; DELETE FROM unity_validation_seven_day_fixture WHERE user_id=$UserId; INSERT INTO unity_validation_seven_day_fixture(user_id,role_id,claimable_quest_id,enabled,applied) VALUES($UserId,$RoleId,1,1,0)" | Out-Null
        Write-Evidence ([ordered]@{ action="Setup"; userId=$UserId; roleId=$RoleId; state=$State; userTable=$userTable; snapshotHash=$hash; createdUtc=[DateTime]::UtcNow.ToString("O") })
    }
    "AssertSetup" {
        $snapshot = Read-Evidence
        if (@(Invoke-SevenDaySql "SELECT COUNT(*) FROM ``$roleBackup`` WHERE id=$RoleId")[0] -ne "1") { throw "SevenDay role backup is missing." }
        $backupHash = @(Invoke-SevenDaySql "SELECT SHA2(CONCAT_WS('|',COALESCE(mission,''),COALESCE(package,''),COALESCE(money,''),COALESCE(save_data,''),COALESCE(clientstring,'')),256) FROM ``$roleBackup`` WHERE id=$RoleId")[0]
        if ([string]$snapshot.snapshotHash -ne [string]$backupHash) { throw "SevenDay immutable role backup hash changed during validation." }
        if (@(Invoke-SevenDaySql "SELECT COUNT(*) FROM unity_validation_seven_day_fixture WHERE user_id=$UserId AND role_id=$RoleId AND claimable_quest_id=1 AND enabled=1")[0] -ne "1") { throw "SevenDay claimable fixture row is missing." }
    }
    "Restore" {
        $snapshot = Read-Evidence
        $userTable = [string]$snapshot.userTable
        Invoke-SevenDaySql "DELETE FROM role_info WHERE id=$RoleId; INSERT INTO role_info SELECT * FROM ``$roleBackup`` WHERE id=$RoleId; DELETE FROM ``$userTable`` WHERE id=$UserId; INSERT INTO ``$userTable`` SELECT * FROM ``$userBackup`` WHERE id=$UserId" | Out-Null
        Invoke-SevenDaySql "UPDATE unity_validation_seven_day_fixture SET enabled=0,applied=1 WHERE user_id=$UserId" | Out-Null
    }
    "AssertRestored" {
        $snapshot = Read-Evidence; $hash = Get-RoleHash
        if ($hash -ne [string]$snapshot.snapshotHash) { throw "SevenDay restored role hash mismatch." }
        $snapshot | Add-Member -Force restoredHash $hash
        $snapshot | Add-Member -Force restored $true
        Write-Evidence $snapshot
    }
    "Cleanup" { Invoke-SevenDaySql "DROP TABLE IF EXISTS ``$roleBackup``; DROP TABLE IF EXISTS ``$userBackup``; DROP TABLE IF EXISTS unity_validation_seven_day_fixture" | Out-Null }
    "AssertCleanup" {
        $count = @(Invoke-SevenDaySql "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME IN ('$roleBackup','$userBackup','unity_validation_seven_day_fixture')")[0]
        if ([int]$count -ne 0) { throw "SevenDay fixture backup tables remain after cleanup." }
    }
    "AssertReloginHash" {
        $snapshot = Read-Evidence; $hash = Get-RoleHash
        if ($hash -ne [string]$snapshot.snapshotHash) { throw "SevenDay post-login restore hash mismatch." }
        $snapshot | Add-Member -Force postLoginHash $hash
        $snapshot | Add-Member -Force residualCount 0
        Write-Evidence $snapshot
    }
}
