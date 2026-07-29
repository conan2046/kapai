[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup","AssertSetup","Restore","AssertRestored","Cleanup","AssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/GameplayShops/unity/g5-20260729/gameplay-shops-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$shopConfigPath = Join-Path $root "server/config/json/shop.json"
$targetTypes = @(2,3,4,5,6,7,8,23,25,26,27,28)

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-GameplayShopSql {
    param([Parameter(Mandatory = $true)][string]$Sql, [switch]$ReturnOutput)
    $arguments = @(
        "--protocol=tcp","--host=127.0.0.1","--port=3306","--user=root","--password=123456",
        "--default-character-set=utf8mb4","--database=fxl_game_local","--batch","--raw",
        "--skip-column-names","--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "GameplayShops fixture SQL failed: $($output -join [Environment]::NewLine)"
    }
    if ($ReturnOutput) {
        return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
    }
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        throw "Stop kapai.exe, ProjectX.exe and Unity.exe before $Action so the GameplayShops snapshot cannot race a save."
    }
}

function Write-Evidence {
    param([Parameter(Mandatory = $true)]$Payload)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 10) + "`n"),
        [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) {
        throw "GameplayShops fixture evidence is missing: $evidence"
    }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Convert-BytesToHex([byte[]]$Bytes) {
    return -join ($Bytes | ForEach-Object { $_.ToString("x2") })
}

function Compress-ShopBytes([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new(
            $output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $zlib.Write($Bytes, 0, $Bytes.Length) } finally { $zlib.Dispose() }
        return Convert-BytesToHex $output.ToArray()
    }
    finally { $output.Dispose() }
}

function Expand-ShopHex([string]$Hex) {
    if ([string]::IsNullOrWhiteSpace($Hex)) { throw "GameplayShops fixture shop blob is empty." }
    $compressed = [Convert]::FromHexString($Hex)
    $input = [IO.MemoryStream]::new($compressed)
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
        try { $zlib.CopyTo($output) } finally { $zlib.Dispose() }
        return $output.ToArray()
    }
    finally { $input.Dispose(); $output.Dispose() }
}

function Get-ConfiguredTargetItems {
    $rows = @(Get-Content -LiteralPath $shopConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    $result = [ordered]@{}
    foreach ($type in $targetTypes) {
        $matches = @($rows | Where-Object { [int]$_.type -eq $type })
        if ($type -eq 2) {
            $selected = New-Object System.Collections.Generic.List[object]
            foreach ($cell in 1..6) {
                $candidate = @($matches | Where-Object {
                    [int]$_.cell -eq $cell -and
                    (@($_.show).Count -eq 0 -or [int]$_.show[0][0] -ne 1 -or [int]$_.show[0][1] -le 99)
                } | Sort-Object { [int]$_.id } | Select-Object -First 1)
                if ($candidate.Count -ne 1) { throw "No deterministic type=2 candidate for cell=$cell." }
                $selected.Add($candidate[0])
            }
            $matches = $selected.ToArray()
        }
        if ($matches.Count -eq 0 -or $matches.Count -gt 255) {
            throw "Invalid deterministic item count for type=${type}: $($matches.Count)"
        }
        $result[[string]$type] = @($matches | Sort-Object { [int]$_.id })
    }
    return $result
}

function New-DeterministicShopBlob {
    $items = Get-ConfiguredTargetItems
    $stream = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([byte]$targetTypes.Count)
        foreach ($type in $targetTypes) {
            $writer.Write([byte]$type)
            $writer.Write([uint16]0)
            $writer.Write([byte]$(if ($type -eq 2) { 10 } else { 0 }))
            $writer.Write([uint32]0)
            $rows = @($items[[string]$type])
            $writer.Write([byte]$rows.Count)
            foreach ($row in $rows) {
                $writer.Write([byte][int]$row.cell)
                $writer.Write([uint16][int]$row.id)
                $writer.Write([uint16]0)
            }
        }
        $writer.Flush()
        return Compress-ShopBytes $stream.ToArray()
    }
    finally { $writer.Dispose(); $stream.Dispose() }
}

function Read-TargetShopState([string]$Hex) {
    $bytes = Expand-ShopHex $Hex
    $stream = [IO.MemoryStream]::new($bytes)
    $reader = [IO.BinaryReader]::new($stream)
    $result = [ordered]@{}
    try {
        $shopCount = $reader.ReadByte()
        foreach ($null in 1..$shopCount) {
            $type = [int]$reader.ReadByte()
            $refresh = [int]$reader.ReadUInt16()
            $free = [int]$reader.ReadByte()
            $cd = [uint32]$reader.ReadUInt32()
            $itemCount = [int]$reader.ReadByte()
            $items = New-Object System.Collections.Generic.List[string]
            foreach ($null in 1..$itemCount) {
                $grid = [int]$reader.ReadByte()
                $tid = [int]$reader.ReadUInt16()
                $count = [int]$reader.ReadUInt16()
                $items.Add("$grid,$tid,$count")
            }
            if ($type -in $targetTypes) {
                $result[[string]$type] = "$refresh|$free|$cd|$($items -join ';')"
            }
        }
    }
    finally { $reader.Dispose(); $stream.Dispose() }
    return $result
}

function Get-TargetFingerprint([string]$Hex) {
    $state = Read-TargetShopState $Hex
    foreach ($type in $targetTypes) {
        if (-not $state.Contains([string]$type)) { throw "GameplayShops target type missing from blob: $type" }
    }
    $canonical = ($targetTypes | ForEach-Object { "$_=$($state[[string]$_])" }) -join "`n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($canonical)
    $stream = [IO.MemoryStream]::new($bytes)
    try { return (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

$hashExpression = @"
SHA2(CONCAT_WS('|',
 COALESCE(r.level,''),COALESCE(r.package,''),COALESCE(r.mysteryShop,''),
 COALESCE(r.shenhunShop,''),COALESCE(r.save_data,''),COALESCE(r.mission,''),
 COALESCE(r.money,''),COALESCE(u.money,''),COALESCE(u.bd_money,'')
),256)
"@ -replace "\r?\n", ""

$createTableSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_gameplay_shops_fixture (
 user_id INT UNSIGNED NOT NULL,
 role_id INT UNSIGNED NOT NULL,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 snapshot_hash CHAR(64) NOT NULL,
 target_fingerprint CHAR(64) NOT NULL,
 backup_level MEDIUMTEXT NULL,
 backup_package MEDIUMTEXT NULL,
 backup_shop MEDIUMTEXT NULL,
 backup_soul_shop MEDIUMTEXT NULL,
 backup_save_data MEDIUMTEXT NULL,
 backup_mission MEDIUMTEXT NULL,
 backup_role_money MEDIUMTEXT NULL,
 backup_user_money MEDIUMTEXT NULL,
 backup_bd_money MEDIUMTEXT NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@

function Restore-GameplayShopsSnapshot {
    Invoke-GameplayShopSql -Sql @"
UPDATE role_info r
JOIN unity_validation_gameplay_shops_fixture f ON f.role_id=r.id AND f.user_id=$UserId
SET r.level=f.backup_level,r.package=f.backup_package,r.mysteryShop=f.backup_shop,
    r.shenhunShop=f.backup_soul_shop,r.save_data=f.backup_save_data,
    r.mission=f.backup_mission,r.money=f.backup_role_money
WHERE r.id=$RoleId;
UPDATE user_info1 u
JOIN unity_validation_gameplay_shops_fixture f ON f.user_id=u.id
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money
WHERE u.id=$UserId AND u.role0=$RoleId
"@
    $restored = @(Invoke-GameplayShopSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_gameplay_shops_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ([int]$restored[-1] -ne 1) { throw "GameplayShops retained snapshot restore assertion failed." }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped
        Invoke-GameplayShopSql -Sql $createTableSql
        $existing = @(Invoke-GameplayShopSql -Sql "SELECT COUNT(*) FROM unity_validation_gameplay_shops_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) {
            throw "A GameplayShops fixture row already exists for userId=$UserId. Run Cleanup first."
        }
        $blob = New-DeterministicShopBlob
        $fingerprint = Get-TargetFingerprint $blob
        Invoke-GameplayShopSql -Sql @"
INSERT INTO unity_validation_gameplay_shops_fixture(
 user_id,role_id,applied,snapshot_hash,target_fingerprint,
 backup_level,backup_package,backup_shop,backup_soul_shop,backup_save_data,
 backup_mission,backup_role_money,backup_user_money,backup_bd_money)
SELECT $UserId,$RoleId,0,$hashExpression,'$fingerprint',
 r.level,r.package,r.mysteryShop,r.shenhunShop,r.save_data,
 r.mission,r.money,u.money,u.bd_money
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId;
UPDATE role_info
SET level='99',mysteryShop='$blob',shenhunShop='0000000000',money='1000000'
WHERE id=$RoleId;
UPDATE user_info1 SET money='100000',bd_money='100000'
WHERE id=$UserId AND role0=$RoleId;
UPDATE unity_validation_gameplay_shops_fixture SET applied=1
WHERE user_id=$UserId AND role_id=$RoleId
"@
        $asserted = @(Invoke-GameplayShopSql -Sql @"
SELECT COUNT(*)=1
FROM unity_validation_gameplay_shops_fixture f
JOIN role_info r ON r.id=f.role_id
JOIN user_info1 u ON u.id=f.user_id AND u.role0=f.role_id
WHERE f.user_id=$UserId AND f.role_id=$RoleId AND f.applied=1
  AND CHAR_LENGTH(f.snapshot_hash)=64 AND CHAR_LENGTH(f.target_fingerprint)=64
  AND CAST(r.level AS UNSIGNED)=99 AND r.mysteryShop='$blob'
  AND r.shenhunShop='0000000000' AND CAST(r.money AS UNSIGNED)=1000000
  AND CAST(u.money AS UNSIGNED)=100000 AND CAST(u.bd_money AS UNSIGNED)=100000
"@ -ReturnOutput)
        if ([int]$asserted[-1] -ne 1) { throw "GameplayShops deterministic fixture setup assertion failed." }
        $snapshot = @(Invoke-GameplayShopSql -Sql @"
SELECT snapshot_hash,target_fingerprint,LENGTH(backup_package),LENGTH(backup_shop),
 LENGTH(backup_soul_shop),LENGTH(backup_save_data),LENGTH(backup_mission),
 backup_level,backup_role_money,backup_user_money,backup_bd_money
FROM unity_validation_gameplay_shops_fixture
WHERE user_id=$UserId AND role_id=$RoleId
"@ -ReturnOutput)
        $values = $snapshot[-1] -split "`t"
        Write-Evidence ([ordered]@{
            module = "GameplayShops"; phase = "fixture-applied"; userId = $UserId; roleId = $RoleId
            snapshotHash = $values[0]; targetFingerprint = $values[1]
            packageLength = [int]$values[2]; shopLength = [int]$values[3]
            soulShopLength = [int]$values[4]; saveDataLength = [int]$values[5]
            missionLength = [int]$values[6]
            originalLevel = [string]$values[7]; originalRoleMoney = [string]$values[8]
            originalUserMoney = [string]$values[9]; originalBoundMoney = [string]$values[10]
            deterministic = [ordered]@{
                level = 99; types = $targetTypes; soulCells = 6
                roleMoney = 1000000; userMoney = 100000; boundMoney = 100000
                soulShop = "0000000000"
            }
            setupAssert = "passed"; restoreAssert = "pending"; cleanupAssert = "pending"
            createdUtc = [DateTime]::UtcNow.ToString("O")
        })
        Write-Host "GameplayShops deterministic fixture applied: userId=$UserId roleId=$RoleId fingerprint=$fingerprint"
    }
    "AssertSetup" {
        $row = @(Invoke-GameplayShopSql -Sql @"
SELECT f.target_fingerprint,r.mysteryShop,CAST(r.level AS UNSIGNED),
 CAST(r.money AS UNSIGNED),CAST(u.money AS UNSIGNED),CAST(u.bd_money AS UNSIGNED)
FROM unity_validation_gameplay_shops_fixture f
JOIN role_info r ON r.id=f.role_id
JOIN user_info1 u ON u.id=f.user_id AND u.role0=f.role_id
WHERE f.user_id=$UserId AND f.role_id=$RoleId AND f.applied=1
"@ -ReturnOutput)
        if ($row.Count -eq 0) { throw "GameplayShops fixture row is missing during AssertSetup." }
        $values = $row[-1] -split "`t",6
        $actualFingerprint = Get-TargetFingerprint $values[1]
        if (
            $actualFingerprint -ne $values[0] -or
            [int]$values[2] -ne 99 -or
            [long]$values[3] -lt 1000000 -or
            [long]$values[4] -ne 100000 -or
            [long]$values[5] -ne 100000
        ) {
            throw "GameplayShops setup assertion failed: fingerprint=$actualFingerprint/$($values[0]) level=$($values[2]) balances=$($values[3]),$($values[4]),$($values[5])"
        }
        Write-Host "GameplayShops setup assertion passed: 12 deterministic target pages, level=99, fixed balances."
    }
    "Restore" {
        Assert-ClientsStopped
        Restore-GameplayShopsSnapshot
        Write-Host "GameplayShops fixture restored while retaining snapshot."
    }
    "AssertRestored" {
        $payload = Read-Evidence
        $current = @(Invoke-GameplayShopSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_gameplay_shops_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([int]$current[-1] -ne 1 -or [string]::IsNullOrWhiteSpace([string]$payload.snapshotHash)) {
            throw "GameplayShops restored hash assertion failed."
        }
        Write-Host "GameplayShops retained snapshot hash assertion passed: $($payload.snapshotHash)"
    }
    "Cleanup" {
        Assert-ClientsStopped
        Invoke-GameplayShopSql -Sql $createTableSql
        $existing = @(Invoke-GameplayShopSql -Sql "SELECT COUNT(*) FROM unity_validation_gameplay_shops_fixture WHERE user_id=$UserId AND role_id=$RoleId" -ReturnOutput)
        if ([int]$existing[-1] -ne 1) { throw "GameplayShops fixture snapshot missing before cleanup." }
        Restore-GameplayShopsSnapshot
        Invoke-GameplayShopSql -Sql "DELETE FROM unity_validation_gameplay_shops_fixture WHERE user_id=$UserId"
        $payload = Read-Evidence
        $payload.phase = "restored"
        $payload.restoreAssert = "passed"
        $payload.cleanupAssert = "passed"
        $payload | Add-Member -Force -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O"))
        Write-Evidence $payload
        Write-Host "GameplayShops exact snapshot restore and cleanup completed."
    }
    "AssertCleanup" {
        $payload = Read-Evidence
        $rows = @(Invoke-GameplayShopSql -Sql "SELECT COUNT(*) FROM unity_validation_gameplay_shops_fixture WHERE user_id=$UserId" -ReturnOutput)
        $current = @(Invoke-GameplayShopSql -Sql @"
SELECT $hashExpression
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
        if (
            [int]$rows[-1] -ne 0 -or
            [string]$current[-1] -ne [string]$payload.snapshotHash -or
            $payload.cleanupAssert -ne "passed"
        ) {
            throw "GameplayShops cleanup residual assertion failed."
        }
        Write-Host "GameplayShops cleanup assertion passed: fixture rows=0, residual hash exact."
    }
}
