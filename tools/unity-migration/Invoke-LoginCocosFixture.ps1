[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Snapshot", "AssertSnapshot", "Capture", "Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "NoticeSetup", "NoticeAssertSetup", "NoticeCleanup", "NoticeAssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7300203,
    [uint32]$RoleId = 0,
    [ValidatePattern('^[A-Za-z0-9]{1,6}$')]
    [string]$RoleName = "T00203",
    [string]$EvidencePath = ".local/ui-fidelity/Login/cocos/g1-20260801/login-create-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-LoginSql {
    param([Parameter(Mandatory = $true)][string]$Sql, [switch]$ReturnOutput)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Login fixture SQL failed: $($output -join [Environment]::NewLine)" }
    if ($ReturnOutput) { return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" }) }
}

function Assert-ClientsStopped {
    $workspacePaths = @(
        [IO.Path]::GetFullPath((Join-Path $root "build\server-win\Debug\kapai.exe")),
        [IO.Path]::GetFullPath((Join-Path $root "client\ProjectX\simulator\win32\ProjectX.exe"))
    )
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -eq "Unity" -or ($_.Path -and $workspacePaths -contains [IO.Path]::GetFullPath($_.Path))
    })
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before Login fixture $Action." }
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 12) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "Login fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-SnapshotHash {
    $bytes = [Text.Encoding]::UTF8.GetBytes("absent|$UserId|$RoleName")
    ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Get-IdentityColumns {
    $sql = @"
SELECT TABLE_NAME,COLUMN_NAME
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='fxl_game_local'
  AND (
    LOWER(COLUMN_NAME) IN ('user_id','userid','role_id','roleid')
    OR (TABLE_NAME='role_info' AND COLUMN_NAME='id')
    OR (TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME='id')
  )
ORDER BY CASE WHEN TABLE_NAME IN ('role_info','user_info') THEN 1 ELSE 0 END,TABLE_NAME,COLUMN_NAME
"@
    @(Invoke-LoginSql -Sql $sql -ReturnOutput | ForEach-Object {
        $parts = [string]$_ -split "`t", 2
        if ($parts.Count -eq 2) { [pscustomobject]@{ table=$parts[0]; column=$parts[1] } }
    })
}

function Quote-Identifier([string]$Value) { "``" + $Value.Replace("``", "````") + "``" }

function Get-Residuals([uint32]$RoleId, [uint32]$TargetUserId = $UserId) {
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($target in Get-IdentityColumns) {
        $lower = ([string]$target.column).ToLowerInvariant()
        $value = if ($lower -in @('user_id','userid') -or ([string]$target.table -like 'user_info*' -and $lower -eq 'id')) { $TargetUserId } else { $RoleId }
        if ($value -eq 0) { continue }
        $table = Quote-Identifier ([string]$target.table)
        $column = Quote-Identifier ([string]$target.column)
        $count = @((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM $table WHERE $column=$value" -ReturnOutput))[-1]
        if ([int64]$count -gt 0) { $rows.Add([pscustomobject]@{table=$target.table;column=$target.column;value=$value;count=[int64]$count}) }
    }
    @($rows)
}

$fixedPrimaryUserId = 7200057
$fixedPrimaryRoleId = 1000115
$fixedIsolationUserId = 705213
$fixedIsolationRoleId = 1000006
$fixedDisposableUserId = 7300204
$fixedNoticeId = 99008802

function Get-UserRoleId([uint32]$TargetUserId) {
    $userTables = @(Invoke-LoginSql -Sql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2" -ReturnOutput)
    $roleRows = @(
        foreach ($userTable in $userTables) {
            $table = Quote-Identifier ([string]$userTable)
            Invoke-LoginSql -Sql "SELECT role0 FROM $table WHERE id=$TargetUserId AND role0>0" -ReturnOutput
        }
    )
    if ($roleRows.Count -gt 1) { throw "Login userId=$TargetUserId maps to multiple role0 rows." }
    if ($roleRows.Count -eq 0) { return [uint32]0 }
    return [uint32]$roleRows[-1]
}

function Get-FixedIdentityHash {
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($identity in @(
        [pscustomobject]@{userId=$fixedPrimaryUserId;roleId=$fixedPrimaryRoleId},
        [pscustomobject]@{userId=$fixedIsolationUserId;roleId=$fixedIsolationRoleId}
    )) {
        $actualRoleId = Get-UserRoleId -TargetUserId $identity.userId
        $roleRow = @((Invoke-LoginSql -Sql "SELECT CONCAT(id,'|',name,'|',level) FROM role_info WHERE id=$($identity.roleId)" -ReturnOutput))
        if ($actualRoleId -ne [uint32]$identity.roleId -or $roleRow.Count -ne 1) {
            throw "Login fixed identity mismatch: user=$($identity.userId) expectedRole=$($identity.roleId) actualRole=$actualRoleId"
        }
        $lines.Add("$($identity.userId)|$actualRoleId|$($roleRow[0])")
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($lines -join "`n"))
    ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Remove-FixedDisposableIdentity {
    $disposableRoleId = Get-UserRoleId -TargetUserId $fixedDisposableUserId
    if ($disposableRoleId -eq 0) { return }
    foreach ($target in Get-IdentityColumns) {
        $lower = ([string]$target.column).ToLowerInvariant()
        $value = if ($lower -in @('user_id','userid') -or ([string]$target.table -like 'user_info*' -and $lower -eq 'id')) { $fixedDisposableUserId } else { $disposableRoleId }
        if ($value -eq 0) { continue }
        $table = Quote-Identifier ([string]$target.table)
        $column = Quote-Identifier ([string]$target.column)
        Invoke-LoginSql -Sql "DELETE FROM $table WHERE $column=$value"
    }
    Invoke-LoginSql -Sql "DELETE FROM role_info WHERE id=$disposableRoleId"
}

function Assert-FixedRestored($Payload) {
    if ([string]$Payload.identityHash -ne (Get-FixedIdentityHash)) { throw "Login fixed primary/isolation identity hash changed." }
    $disposableRoleId = Get-UserRoleId -TargetUserId $fixedDisposableUserId
    $noticeCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login" -ReturnOutput))[-1]
    $fixtureNoticeCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login WHERE id=$fixedNoticeId" -ReturnOutput))[-1]
    if ($disposableRoleId -ne 0 -or $fixtureNoticeCount -ne 0 -or $noticeCount -ne [int]$Payload.initialNoticeCount) {
        throw "Login fixed restore mismatch: disposableRole=$disposableRoleId fixtureNotice=$fixtureNoticeCount noticeCount=$noticeCount expected=$($Payload.initialNoticeCount)"
    }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        if ($UserId -ne $fixedPrimaryUserId -or $RoleId -ne $fixedPrimaryRoleId) { throw "Login fixed contract requires $fixedPrimaryUserId/$fixedPrimaryRoleId." }
        if ((Get-UserRoleId -TargetUserId $fixedDisposableUserId) -ne 0) { throw "Login disposable user already has a role: $fixedDisposableUserId" }
        $fixtureNoticeCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login WHERE id=$fixedNoticeId" -ReturnOutput))[-1]
        if ($fixtureNoticeCount -ne 0) { throw "Login fixed notice id already exists: $fixedNoticeId" }
        $initialNoticeCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login" -ReturnOutput))[-1]
        $identityHash = Get-FixedIdentityHash
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        Invoke-LoginSql -Sql "INSERT INTO notice_login(id,title,msg,showType,jumpType,beginTime,endTime) VALUES($fixedNoticeId,'登录批处理公告','Unity 登录与创角真实 /88 批处理公告。',0,0,$($now-60),$($now+3600))"
        Write-Evidence ([ordered]@{schemaVersion=1;module="Login";phase="setup";userId=$UserId;roleId=$RoleId;identityHash=$identityHash;initialNoticeCount=$initialNoticeCount;noticeId=$fixedNoticeId;disposableUserId=$fixedDisposableUserId;isolationUserId=$fixedIsolationUserId;isolationRoleId=$fixedIsolationRoleId;snapshotHash=$identityHash})
        Write-Host "Login fixed setup passed: primary=$UserId/$RoleId disposable=$fixedDisposableUserId isolation=$fixedIsolationUserId/$fixedIsolationRoleId"
    }
    "AssertSetup" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        if ([string]$payload.identityHash -ne (Get-FixedIdentityHash)) { throw "Login fixed setup identity hash changed." }
        $noticeCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login WHERE id=$fixedNoticeId AND title='登录批处理公告'" -ReturnOutput))[-1]
        if ($noticeCount -ne 1) { throw "Login fixed notice setup assertion failed." }
        if ((Get-UserRoleId -TargetUserId $fixedDisposableUserId) -ne 0) { throw "Login disposable user is not absent before validation." }
        Write-Host "Login fixed setup assertion passed."
    }
    "Restore" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        Remove-FixedDisposableIdentity
        Invoke-LoginSql -Sql "DELETE FROM notice_login WHERE id=$fixedNoticeId"
        $payload.phase = "restored"
        Write-Evidence $payload
        Write-Host "Login fixed restore executed: disposable identity and notice removed."
    }
    "AssertRestored" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        Assert-FixedRestored $payload
        Write-Host "Login fixed restore assertion passed: primary/isolation unchanged, disposable and notice residue zero."
    }
    "NoticeSetup" {
        Assert-ClientsStopped
        $noticeId = 99008801
        $initialCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login" -ReturnOutput))[-1]
        $fixtureCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login WHERE id=$noticeId" -ReturnOutput))[-1]
        if ($fixtureCount -ne 0) { throw "Login notice fixture id already exists: $noticeId" }
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $begin = $now - 60
        $end = $now + 3600
        Invoke-LoginSql -Sql "INSERT INTO notice_login(id,title,msg,showType,jumpType,beginTime,endTime) VALUES($noticeId,'登录迁移公告','这是登录与创角模块的真实 /88 公告证据。',0,0,$begin,$end)"
        Write-Evidence ([ordered]@{module="Login";phase="notice-setup";noticeId=$noticeId;initialCount=$initialCount;title="登录迁移公告";beginTime=$begin;endTime=$end})
        Write-Host "Login /88 notice fixture inserted: id=$noticeId initialCount=$initialCount"
    }
    "NoticeAssertSetup" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        $count = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login WHERE id=$($payload.noticeId) AND title='登录迁移公告'" -ReturnOutput))[-1]
        if ($count -ne 1) { throw "Login /88 notice fixture setup assertion failed." }
        Write-Host "Login /88 notice fixture setup assertion passed."
    }
    "NoticeCleanup" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        Invoke-LoginSql -Sql "DELETE FROM notice_login WHERE id=$($payload.noticeId)"
        $payload.phase = "notice-cleaned"
        Write-Evidence $payload
        Write-Host "Login /88 notice fixture removed: id=$($payload.noticeId)"
    }
    "NoticeAssertCleanup" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        $count = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login" -ReturnOutput))[-1]
        $fixtureCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM notice_login WHERE id=$($payload.noticeId)" -ReturnOutput))[-1]
        if ($fixtureCount -ne 0 -or $count -ne [int]$payload.initialCount) { throw "Login /88 notice cleanup assertion failed: count=$count fixtureCount=$fixtureCount" }
        Write-Host "Login /88 notice cleanup assertion passed: original row count restored."
    }
    "Snapshot" {
        Assert-ClientsStopped
        $userResiduals = @(Get-Residuals -RoleId 0)
        $nameCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM role_info WHERE name='$RoleName'" -ReturnOutput))[-1]
        if ($userResiduals.Count -ne 0 -or $nameCount -ne 0) { throw "Login fixture target is not absent: residuals=$($userResiduals | ConvertTo-Json -Compress) nameCount=$nameCount" }
        Write-Evidence ([ordered]@{module="Login";phase="snapshot";userId=$UserId;roleId=0;roleName=$RoleName;snapshotHash=Get-SnapshotHash;initialUserCount=0;initialNameCount=0;residuals=@()})
        Write-Host "Login absent-state snapshot passed: userId=$UserId roleName=$RoleName"
    }
    "AssertSnapshot" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        if ([uint32]$payload.userId -ne $UserId -or [string]$payload.roleName -ne $RoleName -or [string]$payload.snapshotHash -ne (Get-SnapshotHash)) { throw "Login snapshot identity/hash mismatch." }
        $userResiduals = @(Get-Residuals -RoleId 0)
        $nameCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM role_info WHERE name='$RoleName'" -ReturnOutput))[-1]
        if ($userResiduals.Count -ne 0 -or $nameCount -ne 0) { throw "Login snapshot no longer represents an absent target." }
        Write-Host "Login absent-state snapshot assertion passed."
    }
    "Capture" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        $userTables = @(Invoke-LoginSql -Sql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2" -ReturnOutput)
        $roleRows = @(
            foreach ($userTable in $userTables) {
                $table = Quote-Identifier ([string]$userTable)
                Invoke-LoginSql -Sql "SELECT role0 FROM $table WHERE id=$UserId AND role0>0" -ReturnOutput
            }
        )
        if ($roleRows.Count -ne 1) { throw "Login created role was not uniquely resolved for userId=$UserId" }
        $roleId = [uint32]$roleRows[-1]
        $roleCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM role_info WHERE id=$roleId AND name='$RoleName'" -ReturnOutput))[-1]
        if ($roleCount -ne 1) { throw "Login created role identity mismatch: roleId=$roleId roleName=$RoleName" }
        $payload.roleId = $roleId
        $payload.phase = "captured"
        $payload.residuals = @(Get-Residuals -RoleId $roleId)
        Write-Evidence $payload
        Write-Host "Login created-role capture passed: userId=$UserId roleId=$roleId roleName=$RoleName"
    }
    "Cleanup" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        if ($null -ne $payload.PSObject.Properties["identityHash"]) {
            Remove-FixedDisposableIdentity
            Invoke-LoginSql -Sql "DELETE FROM notice_login WHERE id=$fixedNoticeId"
            $payload.phase = "cleaned"
            Write-Evidence $payload
            Write-Host "Login fixed cleanup executed."
            break
        }
        $roleId = [uint32]$payload.roleId
        if ($roleId -eq 0) { throw "Login fixture has no captured roleId." }
        foreach ($target in Get-IdentityColumns) {
            $lower = ([string]$target.column).ToLowerInvariant()
            $value = if ($lower -in @('user_id','userid') -or ([string]$target.table -like 'user_info*' -and $lower -eq 'id')) { $UserId } else { $roleId }
            if ($value -eq 0) { continue }
            $table = Quote-Identifier ([string]$target.table)
            $column = Quote-Identifier ([string]$target.column)
            Invoke-LoginSql -Sql "DELETE FROM $table WHERE $column=$value"
        }
        Invoke-LoginSql -Sql "DELETE FROM role_info WHERE id=$roleId OR name='$RoleName'; DELETE FROM user_info WHERE id=$UserId"
        $payload.phase = "cleaned"
        $payload.residuals = @()
        Write-Evidence $payload
        Write-Host "Login disposable role cleanup executed: userId=$UserId roleId=$roleId"
    }
    "AssertCleanup" {
        Assert-ClientsStopped
        $payload = Read-Evidence
        if ($null -ne $payload.PSObject.Properties["identityHash"]) {
            Assert-FixedRestored $payload
            Write-Host "Login fixed cleanup assertion passed: zero fixture residue."
            break
        }
        $roleId = [uint32]$payload.roleId
        $residuals = @(Get-Residuals -RoleId $roleId)
        $nameCount = [int]@((Invoke-LoginSql -Sql "SELECT COUNT(*) FROM role_info WHERE name='$RoleName'" -ReturnOutput))[-1]
        if ($residuals.Count -ne 0 -or $nameCount -ne 0) { throw "Login fixture cleanup residuals remain: $($residuals | ConvertTo-Json -Compress)" }
        if ([string]$payload.snapshotHash -ne (Get-SnapshotHash)) { throw "Login fixture snapshot hash changed." }
        Write-Host "Login fixture cleanup assertion passed: zero identity residue and snapshot hash restored."
    }
}
