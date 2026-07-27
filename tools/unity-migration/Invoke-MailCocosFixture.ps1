[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup")]
    [string]$Action,

    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/Mail/cocos/g1-20260727/mail-fixture-snapshot.json"
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
$userDefaultBackup = Join-Path ([System.IO.Path]::GetDirectoryName($evidence)) "mail-userdefault-before.xml"

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) {
    throw "mysql.exe not found: $mysql"
}

function Invoke-MailSql {
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
        throw "Mail fixture SQL failed: $($output -join [Environment]::NewLine)"
    }
    if ($ReturnOutput) {
        return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
    }
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "Stop kapai.exe, ProjectX.exe and Unity.exe before $Action so the Mail snapshot cannot race a save."
    }
}

function New-MailAttachmentHex {
    param([Parameter(Mandatory = $true)][object[]]$Rewards)
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $bytes.Add([byte]$Rewards.Count)
    foreach ($reward in $Rewards) {
        foreach ($value in @([int]$reward.Type, [int]$reward.TypeId, [int]$reward.Amount)) {
            $bytes.AddRange([BitConverter]::GetBytes($value))
        }
    }
    return -join ($bytes | ForEach-Object { $_.ToString("x2") })
}

$hashExpression = @"
SHA2(CONCAT_WS('|',
 COALESCE(TO_BASE64(r.package),''),
 COALESCE(r.clientstring,''),
 COALESCE((
   SELECT GROUP_CONCAT(
     SHA2(CONCAT_WS('|',x.id,x.money,x.YB,x.bdYB,COALESCE(x.attachment,''),x.from_id,x.to_id,
       x.gmtime,DATE_FORMAT(x.time,'%Y-%m-%d %H:%i:%s'),x.shenhun,x.deleted,x.from_name,
       COALESCE(x.message,'')),256)
     ORDER BY x.id SEPARATOR ',')
   FROM xin_shi x WHERE x.to_id=$RoleId
 ),'')
),256)
"@ -replace "\r?\n", ""

$createTablesSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_mail_fixture (
 user_id INT UNSIGNED NOT NULL,
 role_id INT UNSIGNED NOT NULL,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 source_mail_count INT UNSIGNED NOT NULL DEFAULT 0,
 snapshot_hash CHAR(64) NOT NULL,
 backup_package MEDIUMTEXT NULL,
 backup_clientstring MEDIUMTEXT NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
SET @mail_fixture_clientstring_column=(
 SELECT COUNT(*) FROM information_schema.columns
 WHERE table_schema=DATABASE()
   AND table_name='unity_validation_mail_fixture'
   AND column_name='backup_clientstring'
);
SET @mail_fixture_clientstring_sql=IF(
 @mail_fixture_clientstring_column=0,
 'ALTER TABLE unity_validation_mail_fixture ADD COLUMN backup_clientstring MEDIUMTEXT NULL AFTER backup_package',
 'SELECT 1'
);
PREPARE mail_fixture_clientstring_stmt FROM @mail_fixture_clientstring_sql;
EXECUTE mail_fixture_clientstring_stmt;
DEALLOCATE PREPARE mail_fixture_clientstring_stmt;
CREATE TABLE IF NOT EXISTS unity_validation_mail_backup (
 user_id INT UNSIGNED NOT NULL,
 id INT NOT NULL,
 money INT NOT NULL DEFAULT 0,
 YB INT NOT NULL DEFAULT 0,
 bdYB INT NOT NULL DEFAULT 0,
 attachment TEXT NULL,
 from_id INT NOT NULL DEFAULT 0,
 to_id INT NOT NULL DEFAULT 0,
 gmtime INT NOT NULL DEFAULT 0,
 mail_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 shenhun INT NOT NULL DEFAULT 0,
 deleted TINYINT NOT NULL DEFAULT 0,
 from_name VARCHAR(64) NOT NULL DEFAULT '',
 message TEXT NULL,
 PRIMARY KEY(user_id,id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@

function New-ClientStringHex {
    param([Parameter(Mandatory = $true)][System.Collections.IDictionary]$Values)
    $bytes = [System.Collections.Generic.List[byte]]::new()
    $bytes.AddRange([BitConverter]::GetBytes([int]$Values.Count))
    foreach ($entry in $Values.GetEnumerator() | Sort-Object { [int]$_.Key }) {
        $valueBytes = [Text.Encoding]::UTF8.GetBytes([string]$entry.Value)
        $bytes.AddRange([BitConverter]::GetBytes([int]$entry.Key))
        $bytes.AddRange([BitConverter]::GetBytes([int16]$valueBytes.Length))
        $bytes.AddRange($valueBytes)
    }
    return -join ($bytes | ForEach-Object { $_.ToString("x2") })
}

$mailGuideClientString = New-ClientStringHex ([ordered]@{
    67 = "1,2,3,4,5,6,8,10,15,35"
    69 = "0"
})

$oneAttachment = New-MailAttachmentHex @(
    [pscustomobject]@{ Type = 3201; TypeId = 0; Amount = 10 }
)
$twoAttachments = New-MailAttachmentHex @(
    [pscustomobject]@{ Type = 500; TypeId = 0; Amount = 2 },
    [pscustomobject]@{ Type = 613; TypeId = 0; Amount = 5 }
)
$nineAttachments = New-MailAttachmentHex @(
    [pscustomobject]@{ Type = 500; TypeId = 0; Amount = 1 },
    [pscustomobject]@{ Type = 613; TypeId = 0; Amount = 3 },
    [pscustomobject]@{ Type = 851; TypeId = 0; Amount = 20 },
    [pscustomobject]@{ Type = 853; TypeId = 0; Amount = 2 },
    [pscustomobject]@{ Type = 854; TypeId = 0; Amount = 4 },
    [pscustomobject]@{ Type = 855; TypeId = 0; Amount = 1 },
    [pscustomobject]@{ Type = 861; TypeId = 0; Amount = 2 },
    [pscustomobject]@{ Type = 862; TypeId = 0; Amount = 3 },
    [pscustomobject]@{ Type = 863; TypeId = 0; Amount = 4 }
)

$fixtureValues = @(
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 1 MINUTE),0,0,'系统','邮件验证 无附件未读正文')",
    "(0,0,0,'$oneAttachment',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 2 MINUTE),0,0,'系统','邮件验证 单附件可领取')",
    "(0,0,0,'$nineAttachments',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 3 MINUTE),0,0,'活动使者','邮件验证 多附件滚动与详情')",
    "(0,0,0,'$twoAttachments',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 4 MINUTE),0,0,'系统','邮件验证 一键领取 A')",
    "(0,0,0,'$oneAttachment',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 5 MINUTE),0,0,'系统','邮件验证 一键领取 B')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 6 MINUTE),0,0,'系统','邮件验证 列表滚动 06')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 7 MINUTE),0,0,'系统','邮件验证 列表滚动 07')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 8 MINUTE),0,0,'系统','邮件验证 列表滚动 08')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 9 MINUTE),0,0,'系统','邮件验证 列表滚动 09')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 10 MINUTE),0,0,'系统','邮件验证 列表滚动 10')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 11 MINUTE),0,0,'系统','邮件验证 列表滚动 11')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 12 MINUTE),0,0,'系统','邮件验证 列表滚动 12')",
    "(0,0,0,'',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 13 MINUTE),0,0,'系统','邮件验证 长正文：这是用于验证正文区域滚动、换行、裁剪和返回重进后内容一致性的当前服务器真实邮件。第一段：邮件正文必须从顶部开始。第二段：内容超过视口后允许垂直滚动。第三段：滚动区域必须真实裁剪。第四段：返回重进后内容保持一致。第五段：未读无附件邮件发送已读协议。第六段：已读状态按账号持久化。第七段：不同账号之间不得串档。第八段：正文换行不得截断。第九段：滚动到底部可见末尾。第十段：再次回到顶部仍可阅读。第十一段：领取附件后列表重新拉取。第十二段：重复领取返回明确失败。第十三段：一键领取必须串行。第十四段：一键删除仅删除本地历史。第十五段：断线重连清空 pending。第十六段：邮件红点随未读状态变化。第十七段：固定账号验证后恢复原始快照。第十八段：数据库残留必须为零。第十九段：附件区域独立横向滚动。第二十段：附件详情复用公共获取途径弹窗。正文滚动验证结束。')",
    "(0,0,0,'$oneAttachment',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 14 MINUTE),0,0,'系统','邮件验证 列表滚动 14')",
    "(0,0,0,'$oneAttachment',0,$RoleId,0,DATE_SUB(NOW(),INTERVAL 15 MINUTE),0,1,'系统','邮件验证 已领取不可见行')"
) -join ","

$setupAssertSql = @"
SET @mail_ok=(
 SELECT COUNT(*)=1 FROM unity_validation_mail_fixture
 WHERE user_id=$UserId AND role_id=$RoleId AND applied=1 AND CHAR_LENGTH(snapshot_hash)=64
);
SET @mail_visible=(SELECT COUNT(*)=14 FROM xin_shi WHERE to_id=$RoleId AND deleted=0 AND message LIKE '邮件验证 %');
SET @mail_deleted=(SELECT COUNT(*)=1 FROM xin_shi WHERE to_id=$RoleId AND deleted=1 AND message='邮件验证 已领取不可见行');
SET @mail_attach=(SELECT COUNT(*)>=5 FROM xin_shi WHERE to_id=$RoleId AND deleted=0 AND CHAR_LENGTH(attachment)>2);
SET @mail_plain=(SELECT COUNT(*)>=5 FROM xin_shi WHERE to_id=$RoleId AND deleted=0 AND CHAR_LENGTH(COALESCE(attachment,''))<=2);
SET @mail_attach_scroll=(
 SELECT COUNT(*)=1 FROM xin_shi
 WHERE to_id=$RoleId AND deleted=0
   AND message='邮件验证 多附件滚动与详情'
   AND LEFT(attachment,2)='09'
);
SET @mail_guide=(SELECT COUNT(*)=1 FROM role_info WHERE id=$RoleId AND clientstring='$mailGuideClientString');
SET @mail_sql=IF(@mail_ok AND @mail_visible AND @mail_deleted AND @mail_attach AND @mail_plain AND @mail_attach_scroll AND @mail_guide,
 'SELECT 1','SIGNAL SQLSTATE ''45000'' SET MESSAGE_TEXT=''Mail fixture setup assertion failed''');
PREPARE mail_stmt FROM @mail_sql;
EXECUTE mail_stmt;
DEALLOCATE PREPARE mail_stmt
"@

function Restore-MailSnapshot {
    Invoke-MailSql -Sql @"
DELETE FROM xin_shi WHERE to_id=$RoleId;
INSERT INTO xin_shi(id,money,YB,bdYB,attachment,from_id,to_id,gmtime,time,shenhun,deleted,from_name,message)
SELECT id,money,YB,bdYB,attachment,from_id,to_id,gmtime,mail_time,shenhun,deleted,from_name,message
FROM unity_validation_mail_backup WHERE user_id=$UserId ORDER BY id;
UPDATE role_info r
JOIN unity_validation_mail_fixture f ON f.role_id=r.id AND f.user_id=$UserId
SET r.package=f.backup_package,
    r.clientstring=f.backup_clientstring
WHERE r.id=$RoleId
"@
    $restored = @(Invoke-MailSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN unity_validation_mail_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ([int]$restored[-1] -ne 1) {
        throw "Mail retained snapshot restore assertion failed."
    }
    if (Test-Path -LiteralPath $userDefaultBackup -PathType Leaf) {
        Copy-Item -LiteralPath $userDefaultBackup -Destination $userDefault -Force
    }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        Invoke-MailSql -Sql $createTablesSql
        $existing = @(Invoke-MailSql -Sql "SELECT COUNT(*) FROM unity_validation_mail_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) {
            throw "A Mail fixture row already exists for userId=$UserId. Run Cleanup or inspect it before replacing the snapshot."
        }
        [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($evidence)) | Out-Null
        if (Test-Path -LiteralPath $userDefault -PathType Leaf) {
            Copy-Item -LiteralPath $userDefault -Destination $userDefaultBackup -Force
        }
        Invoke-MailSql -Sql @"
DELETE FROM unity_validation_mail_backup WHERE user_id=$UserId;
INSERT INTO unity_validation_mail_backup(
 user_id,id,money,YB,bdYB,attachment,from_id,to_id,gmtime,mail_time,shenhun,deleted,from_name,message
)
SELECT $UserId,id,money,YB,bdYB,attachment,from_id,to_id,gmtime,time,shenhun,deleted,from_name,message
FROM xin_shi WHERE to_id=$RoleId;
INSERT INTO unity_validation_mail_fixture(
 user_id,role_id,applied,source_mail_count,snapshot_hash,backup_package,backup_clientstring
)
SELECT $UserId,$RoleId,0,(SELECT COUNT(*) FROM xin_shi WHERE to_id=$RoleId),
       $hashExpression,r.package,r.clientstring
FROM role_info r WHERE r.id=$RoleId;
DELETE FROM xin_shi WHERE to_id=$RoleId;
INSERT INTO xin_shi(money,YB,bdYB,attachment,from_id,to_id,gmtime,time,shenhun,deleted,from_name,message)
VALUES $fixtureValues;
UPDATE role_info SET clientstring='$mailGuideClientString' WHERE id=$RoleId;
UPDATE unity_validation_mail_fixture SET applied=1 WHERE user_id=$UserId AND role_id=$RoleId
"@
        Invoke-MailSql -Sql $setupAssertSql
        $snapshot = @(Invoke-MailSql -Sql @"
SELECT snapshot_hash,source_mail_count,LENGTH(backup_package),LENGTH(backup_clientstring)
FROM unity_validation_mail_fixture WHERE user_id=$UserId AND role_id=$RoleId
"@ -ReturnOutput)
        $values = $snapshot[-1] -split "`t"
        $payload = [ordered]@{
            module = "Mail"
            phase = "before-injection"
            userId = $UserId
            roleId = $RoleId
            snapshotHash = $values[0]
            sourceMailCount = [int]$values[1]
            packageLength = [int]$values[2]
            clientStringLength = [int]$values[3]
            fixtureVisibleCount = 14
            fixtureTotalCount = 15
            fixtureAttachmentMaxCount = 9
            userDefaultSha256 = if (Test-Path -LiteralPath $userDefaultBackup) {
                (Get-FileHash -Algorithm SHA256 -LiteralPath $userDefaultBackup).Hash
            } else { "" }
            setupAssertSql = "passed"
            cleanupAssertSql = "pending"
            createdUtc = [DateTime]::UtcNow.ToString("O")
        }
        [System.IO.File]::WriteAllText(
            $evidence,
            (($payload | ConvertTo-Json -Depth 4) + "`n"),
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Host "Mail fixture snapshot and batch created: userId=$UserId roleId=$RoleId visible=14 hash=$($values[0])"
    }
    "AssertSetup" {
        Invoke-MailSql -Sql $setupAssertSql
        Write-Host "Mail fixture application assertion passed: userId=$UserId roleId=$RoleId"
    }
    "Restore" {
        Assert-ClientsStopped
        Restore-MailSnapshot
        Write-Host "Mail fixture restored while retaining snapshot: userId=$UserId roleId=$RoleId"
    }
    "AssertRestored" {
        $restored = @(Invoke-MailSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN unity_validation_mail_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([int]$restored[-1] -ne 1) {
            throw "Mail retained snapshot hash assertion failed."
        }
        if (Test-Path -LiteralPath $userDefaultBackup -PathType Leaf) {
            $expected = (Get-FileHash -Algorithm SHA256 -LiteralPath $userDefaultBackup).Hash
            $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $userDefault).Hash
            if ($expected -ne $actual) { throw "Mail UserDefault snapshot restore assertion failed." }
        }
        Write-Host "Mail retained snapshot hash assertion passed: userId=$UserId roleId=$RoleId"
    }
    "Cleanup" {
        Assert-ClientsStopped
        Invoke-MailSql -Sql $createTablesSql
        $existing = @(Invoke-MailSql -Sql "SELECT COUNT(*) FROM unity_validation_mail_fixture WHERE user_id=$UserId AND role_id=$RoleId" -ReturnOutput)
        if ([int]$existing[-1] -ne 1) { throw "Mail fixture snapshot missing before cleanup." }
        Restore-MailSnapshot
        Invoke-MailSql -Sql @"
DELETE FROM unity_validation_mail_backup WHERE user_id=$UserId;
DELETE FROM unity_validation_mail_fixture WHERE user_id=$UserId
"@
        if (Test-Path -LiteralPath $evidence -PathType Leaf) {
            $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
            $payload.cleanupAssertSql = "passed"
            $payload | Add-Member -NotePropertyName restoredHashAssertSql -NotePropertyValue "passed" -Force
            $payload | Add-Member -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
            [System.IO.File]::WriteAllText(
                $evidence,
                (($payload | ConvertTo-Json -Depth 4) + "`n"),
                [System.Text.UTF8Encoding]::new($false)
            )
        }
        if (Test-Path -LiteralPath $userDefaultBackup -PathType Leaf) {
            Remove-Item -LiteralPath $userDefaultBackup -Force
        }
        Write-Host "Mail fixture cleanup and exact snapshot restore passed: userId=$UserId roleId=$RoleId"
    }
    "AssertCleanup" {
        $fixtureRows = @(Invoke-MailSql -Sql "SELECT COUNT(*) FROM unity_validation_mail_fixture WHERE user_id=$UserId" -ReturnOutput)
        $backupRows = @(Invoke-MailSql -Sql "SELECT COUNT(*) FROM unity_validation_mail_backup WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$fixtureRows[-1] -ne 0 -or [int]$backupRows[-1] -ne 0) {
            throw "Mail fixture cleanup assertion failed for userId=$UserId"
        }
        if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
            throw "Mail fixture evidence is missing: $evidence"
        }
        $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
        $payload.cleanupAssertSql = "passed"
        $payload | Add-Member -NotePropertyName fixtureResidualRows -NotePropertyValue 0 -Force
        $payload | Add-Member -NotePropertyName cleanupVerifiedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        [System.IO.File]::WriteAllText(
            $evidence,
            (($payload | ConvertTo-Json -Depth 4) + "`n"),
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Host "Mail fixture cleanup assertion passed: userId=$UserId residual=0"
    }
}
