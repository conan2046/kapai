[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "SetInsufficientCurrency", "AssertInsufficientCurrency", "Restore", "AssertRestored", "Cleanup", "AssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [uint16]$HeroId = 64,
    [string]$EvidencePath = ".local/ui-fidelity/HeroRebirth/cocos/g1/hero-rebirth-cocos-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$backupTable = "unity_validation_hero_rebirth_cocos_fixture"

if ($UserId -ne 7200057 -or $RoleId -ne 1000115 -or $HeroId -ne 64) {
    throw "HeroRebirth Cocos fixture identity/hero must remain 7200057/1000115/64."
}
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-HeroRebirthSql {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $arguments = @(
        "--protocol=tcp", "--ssl-mode=DISABLED", "--host=127.0.0.1", "--port=3306",
        "--user=root", "--password=123456", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "HeroRebirth Cocos fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-HeroRebirthProcessesStopped {
    $running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before HeroRebirth Cocos fixture $Action." }
}

function Get-HeroRebirthUserTable {
    $tables = @(Invoke-HeroRebirthSql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @($tables | Where-Object {
        $_ -match '^user_info\d*$' -and @(Invoke-HeroRebirthSql "SELECT id FROM ``$_`` WHERE id=$UserId AND role0=$RoleId").Count -eq 1
    })
    if ($matches.Count -ne 1) { throw "HeroRebirth identity did not resolve to exactly one user_info shard." }
    [string]$matches[0]
}

function Expand-HeroRebirthBlob([string]$Hex) {
    $inputBytes = [Convert]::FromHexString($Hex)
    $inputStream = [IO.MemoryStream]::new($inputBytes)
    $zlib = [IO.Compression.ZLibStream]::new($inputStream, [IO.Compression.CompressionMode]::Decompress)
    $outputStream = [IO.MemoryStream]::new()
    try { $zlib.CopyTo($outputStream); return [byte[]]$outputStream.ToArray() }
    finally { $zlib.Dispose(); $inputStream.Dispose(); $outputStream.Dispose() }
}

function Compress-HeroRebirthBlob([byte[]]$Bytes) {
    $outputStream = [IO.MemoryStream]::new()
    $zlib = [IO.Compression.ZLibStream]::new($outputStream, [IO.Compression.CompressionLevel]::SmallestSize, $true)
    try {
        $zlib.Write($Bytes, 0, $Bytes.Length)
        $zlib.Dispose()
        [Convert]::ToHexString($outputStream.ToArray()).ToLowerInvariant()
    }
    finally { $zlib.Dispose(); $outputStream.Dispose() }
}

function Get-HeroRebirthFormationIds([string]$Hex) {
    $bytes = Expand-HeroRebirthBlob $Hex
    $position = 0
    if ($bytes.Length -lt 6) { throw "HeroRebirth zhenfa payload is truncated." }
    $position++ # active index
    $zhenfaCount = $bytes[$position++]
    $position += 3 * $zhenfaCount
    if ($position -ge $bytes.Length) { throw "HeroRebirth zhenfa member count is missing." }
    $memberCount = $bytes[$position++]
    $ids = New-Object System.Collections.Generic.List[uint32]
    for ($index = 0; $index -lt $memberCount; $index++) {
        if ($position + 5 -gt $bytes.Length) { throw "HeroRebirth zhenfa member payload is truncated." }
        $kind = $bytes[$position]
        $id = [BitConverter]::ToUInt32($bytes, $position + 1)
        if ($kind -ne 0 -and $id -ne 0) { $ids.Add($id) }
        $position += 5
    }
    @($ids.ToArray())
}

function Set-HeroRebirthProgress([string]$PetHex, [uint16]$TargetHeroId) {
    $bytes = Expand-HeroRebirthBlob $PetHex
    if ($bytes.Length -lt 2) { throw "HeroRebirth pet payload is truncated." }
    $position = 0
    $petCount = $bytes[$position++]
    $extVersion = $bytes[$position++]
    if ($extVersion -lt 1) { throw "HeroRebirth fixture requires pet ext version >= 1." }
    $matched = 0
    for ($index = 0; $index -lt $petCount; $index++) {
        if ($position + 11 -gt $bytes.Length) { throw "HeroRebirth pet entry $index is truncated." }
        $id = [BitConverter]::ToUInt16($bytes, $position)
        $position += 2
        $levelOffset = $position
        $position += 2 # level
        $position += 4 # exp
        $position++ # star
        $breakOffset = $position
        $position++
        $nameLength = $bytes[$position++]
        $position += $nameLength
        if ($position + 2 -gt $bytes.Length) { throw "HeroRebirth pet extension is truncated for hero $id." }
        $xiuLianOffset = $position
        $position++
        $counterCount = $bytes[$position++]
        $position += 3 * $counterCount
        if ($position -gt $bytes.Length) { throw "HeroRebirth pet counters are truncated for hero $id." }
        if ($id -eq $TargetHeroId) {
            [BitConverter]::GetBytes([uint16]10).CopyTo($bytes, $levelOffset)
            $bytes[$breakOffset] = 2
            $bytes[$xiuLianOffset] = 1
            $matched++
        }
    }
    if ($position -ne $bytes.Length) { throw "HeroRebirth pet payload has trailing bytes." }
    if ($matched -ne 1) { throw "HeroRebirth fixture expected exactly one hero $TargetHeroId, found $matched." }
    Compress-HeroRebirthBlob $bytes
}

function Get-HeroRebirthSnapshotHash([string]$UserTable) {
    if ($UserTable -notmatch '^user_info\d*$') { throw "Invalid HeroRebirth user table." }
    $rows = @(Invoke-HeroRebirthSql "SELECT SHA2(CONCAT_WS('|',COALESCE(r.pet,''),COALESCE(r.zhenfa,''),COALESCE(r.package,''),COALESCE(CAST(r.money AS CHAR),''),COALESCE(CAST(u.money AS CHAR),''),COALESCE(CAST(u.bd_money AS CHAR),'')),256) FROM role_info r JOIN ``$UserTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId")
    if ($rows.Count -ne 1 -or [string]$rows[0] -notmatch '^[0-9a-fA-F]{64}$') { throw "HeroRebirth snapshot hash could not be calculated." }
    [string]$rows[0]
}

$createTableSql = @"
CREATE TABLE IF NOT EXISTS $backupTable (
 user_id INT UNSIGNED NOT NULL PRIMARY KEY,
 role_id INT UNSIGNED NOT NULL,
 hero_id SMALLINT UNSIGNED NOT NULL,
 user_table VARCHAR(64) NOT NULL,
 backup_pet MEDIUMTEXT NOT NULL,
 backup_zhenfa MEDIUMTEXT NOT NULL,
 backup_package MEDIUMTEXT NOT NULL,
 backup_role_money BIGINT NOT NULL,
 backup_user_money BIGINT NOT NULL,
 backup_bd_money BIGINT NOT NULL,
 snapshot_hash CHAR(64) NOT NULL,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@

switch ($Action) {
    "Setup" {
        Assert-HeroRebirthProcessesStopped
        Invoke-HeroRebirthSql $createTableSql | Out-Null
        $existing = @(Invoke-HeroRebirthSql "SELECT COUNT(*) FROM $backupTable WHERE user_id=$UserId")
        if ([int]$existing[-1] -ne 0) { throw "HeroRebirth Cocos fixture already exists; restore/cleanup before setup." }
        $userTable = Get-HeroRebirthUserTable
        $source = @(Invoke-HeroRebirthSql "SELECT r.pet,r.zhenfa FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId")
        if ($source.Count -ne 1) { throw "HeroRebirth fixed role source row is missing." }
        $sourceParts = [string]$source[0] -split "`t"
        $formationIds = @(Get-HeroRebirthFormationIds $sourceParts[1])
        if ([uint32]$HeroId -in $formationIds) { throw "HeroRebirth fixture hero $HeroId is deployed and cannot be used." }
        $snapshotHash = Get-HeroRebirthSnapshotHash $userTable
        Invoke-HeroRebirthSql @"
INSERT INTO $backupTable(user_id,role_id,hero_id,user_table,backup_pet,backup_zhenfa,backup_package,backup_role_money,backup_user_money,backup_bd_money,snapshot_hash)
SELECT $UserId,$RoleId,$HeroId,'$userTable',r.pet,r.zhenfa,r.package,r.money,u.money,u.bd_money,'$snapshotHash'
FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId
"@ | Out-Null
        $fixturePet = Set-HeroRebirthProgress $sourceParts[0] $HeroId
        Invoke-HeroRebirthSql "UPDATE role_info SET pet='$fixturePet' WHERE id=$RoleId" | Out-Null
        $fixtureHash = Get-HeroRebirthSnapshotHash $userTable
        $payload = [ordered]@{
            module = "HeroRebirth"; backend = "workspace-local-mysql"; userId = $UserId; roleId = $RoleId
            heroId = $HeroId; heroLevel = 10; heroBreakLevel = 2; heroXiuLianLevel = 1
            formationIds = @($formationIds); snapshotHash = $snapshotHash; fixtureHash = $fixtureHash
            restored = $false; cleanupAssertSql = "pending"; createdUtc = [DateTime]::UtcNow.ToString("O")
        }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
        [IO.File]::WriteAllText($evidence, (($payload | ConvertTo-Json -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
        Write-Host "HeroRebirth Cocos fixture setup: userId=$UserId roleId=$RoleId hero=$HeroId snapshot=$snapshotHash fixture=$fixtureHash"
    }
    "AssertSetup" {
        $userTable = Get-HeroRebirthUserTable
        $row = @(Invoke-HeroRebirthSql "SELECT COUNT(*),snapshot_hash FROM $backupTable WHERE user_id=$UserId AND role_id=$RoleId AND hero_id=$HeroId")
        if ($row.Count -ne 1 -or [int](([string]$row[0] -split "`t")[0]) -ne 1) { throw "HeroRebirth Cocos fixture setup row is missing." }
        $pet = @(Invoke-HeroRebirthSql "SELECT pet FROM role_info WHERE id=$RoleId")
        $verified = Set-HeroRebirthProgress ([string]$pet[0]) $HeroId
        if ([string]$verified -ne [string]$pet[0]) { throw "HeroRebirth Cocos fixture hero progress is not exact." }
        Write-Host "HeroRebirth Cocos fixture assertion passed: userId=$UserId roleId=$RoleId hero=$HeroId"
    }
    "SetInsufficientCurrency" {
        Assert-HeroRebirthProcessesStopped
        $rows = @(Invoke-HeroRebirthSql "SELECT user_table FROM $backupTable WHERE user_id=$UserId AND role_id=$RoleId AND hero_id=$HeroId")
        if ($rows.Count -ne 1 -or [string]$rows[0] -notmatch '^user_info\d*$') { throw "HeroRebirth Cocos snapshot is missing before insufficient-currency setup." }
        $userTable = [string]$rows[0]
        Invoke-HeroRebirthSql "UPDATE ``$userTable`` SET money=0,bd_money=0 WHERE id=$UserId AND role0=$RoleId" | Out-Null
        Write-Host "HeroRebirth Cocos insufficient-currency state set: userId=$UserId roleId=$RoleId money=0 bd_money=0"
    }
    "AssertInsufficientCurrency" {
        $userTable = Get-HeroRebirthUserTable
        $rows = @(Invoke-HeroRebirthSql "SELECT COUNT(*) FROM ``$userTable`` WHERE id=$UserId AND role0=$RoleId AND money=0 AND bd_money=0")
        if ([int]$rows[-1] -ne 1) { throw "HeroRebirth Cocos insufficient-currency assertion failed." }
        Write-Host "HeroRebirth Cocos insufficient-currency assertion passed."
    }
    "Restore" {
        Assert-HeroRebirthProcessesStopped
        $rows = @(Invoke-HeroRebirthSql "SELECT user_table FROM $backupTable WHERE user_id=$UserId AND role_id=$RoleId")
        if ($rows.Count -ne 1 -or [string]$rows[0] -notmatch '^user_info\d*$') { throw "HeroRebirth Cocos snapshot is missing or invalid." }
        $userTable = [string]$rows[0]
        Invoke-HeroRebirthSql "UPDATE role_info r JOIN $backupTable f ON f.role_id=r.id SET r.pet=f.backup_pet,r.zhenfa=f.backup_zhenfa,r.package=f.backup_package,r.money=f.backup_role_money WHERE f.user_id=$UserId; UPDATE ``$userTable`` u JOIN $backupTable f ON f.user_id=u.id SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money WHERE f.user_id=$UserId AND u.role0=$RoleId" | Out-Null
        $expected = @((Invoke-HeroRebirthSql "SELECT snapshot_hash FROM $backupTable WHERE user_id=$UserId"))[-1]
        $actual = Get-HeroRebirthSnapshotHash $userTable
        if ([string]$actual -ne [string]$expected) { throw "HeroRebirth Cocos restore hash mismatch." }
        if (Test-Path -LiteralPath $evidence -PathType Leaf) {
            $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
            $payload.restored = $true
            $payload | Add-Member -Force -NotePropertyName restoredHash -NotePropertyValue $actual
            $payload | Add-Member -Force -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
            [IO.File]::WriteAllText($evidence, (($payload | ConvertTo-Json -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
        }
        Write-Host "HeroRebirth Cocos fixture restored: userId=$UserId roleId=$RoleId hash=$actual"
    }
    "AssertRestored" {
        $rows = @(Invoke-HeroRebirthSql "SELECT user_table,snapshot_hash FROM $backupTable WHERE user_id=$UserId AND role_id=$RoleId")
        if ($rows.Count -ne 1) { throw "HeroRebirth Cocos retained snapshot is missing." }
        $values = [string]$rows[0] -split "`t"
        if ((Get-HeroRebirthSnapshotHash $values[0]) -ne $values[1]) { throw "HeroRebirth Cocos retained restore hash assertion failed." }
        Write-Host "HeroRebirth Cocos retained restore hash passed."
    }
    "Cleanup" {
        Assert-HeroRebirthProcessesStopped
        & $PSCommandPath -Action Restore -UserId $UserId -RoleId $RoleId -HeroId $HeroId -EvidencePath $EvidencePath
        if ($LASTEXITCODE -ne 0) { throw "HeroRebirth Cocos retained restore failed before cleanup." }
        Invoke-HeroRebirthSql "DELETE FROM $backupTable WHERE user_id=$UserId AND role_id=$RoleId" | Out-Null
        if (Test-Path -LiteralPath $evidence -PathType Leaf) {
            $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
            $payload.cleanupAssertSql = "passed"
            $payload | Add-Member -Force -NotePropertyName cleanedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
            [IO.File]::WriteAllText($evidence, (($payload | ConvertTo-Json -Depth 6) + "`n"), [Text.UTF8Encoding]::new($false))
        }
        Write-Host "HeroRebirth Cocos fixture cleanup passed."
    }
    "AssertCleanup" {
        Invoke-HeroRebirthSql $createTableSql | Out-Null
        $count = @(Invoke-HeroRebirthSql "SELECT COUNT(*) FROM $backupTable WHERE user_id=$UserId")
        if ([int]$count[-1] -ne 0) { throw "HeroRebirth Cocos fixture cleanup row remains." }
        if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "HeroRebirth Cocos fixture evidence is missing." }
        $payload = Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not [bool]$payload.restored -or [string]$payload.cleanupAssertSql -ne "passed" -or [string]$payload.restoredHash -ne [string]$payload.snapshotHash) {
            throw "HeroRebirth Cocos fixture evidence does not prove exact restore and cleanup."
        }
        Write-Host "HeroRebirth Cocos fixture cleanup assertion passed."
    }
}
