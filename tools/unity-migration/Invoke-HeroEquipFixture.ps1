[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/HeroEquip/unity/g5-current/hero-equip-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$roleBackup = "codex_hero_equip_role_backup"
$userBackup = "codex_hero_equip_user_backup"
$fixtureEquipmentUid = [uint32]2121073001
$fixtureEquipmentTemplateId = [uint16]1101
$fixtureFaBaoUid = [uint32]2121073002
$fixtureFaBaoTemplateId = [uint16]1101

if ($UserId -ne 7200057 -or $RoleId -ne 1000115) {
    throw "HeroEquip fixed-account fixture identity must remain 7200057/1000115."
}
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-HeroEquipSql([string]$Sql) {
    $args = @("--protocol=tcp", "--ssl-mode=DISABLED", "--host=127.0.0.1", "--port=3306",
        "--user=root", "--password=123456", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql")
    $output = @(& $mysql @args 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "HeroEquip fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before HeroEquip fixture $Action." }
}

function Get-UserTable {
    $tables = @(Invoke-HeroEquipSql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @($tables | Where-Object {
        $_ -match '^user_info\d*$' -and @(Invoke-HeroEquipSql "SELECT id FROM ``$_`` WHERE id=$UserId AND role0=$RoleId").Count -eq 1
    })
    if ($matches.Count -ne 1) { throw "HeroEquip userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    [string]$matches[0]
}

function Get-RoleHash {
    $sql = "SELECT SHA2(CONCAT_WS('|',COALESCE(pet_equip,''),COALESCE(pet,''),COALESCE(zhenfa,''),COALESCE(money,''),COALESCE(package,''),COALESCE(mission,''),COALESCE(save_data,''),COALESCE(clientstring,'')),256) FROM role_info WHERE id=$RoleId"
    $rows = @(Invoke-HeroEquipSql $sql)
    if ($rows.Count -ne 1) { throw "HeroEquip role_info row is missing for roleId=$RoleId." }
    [string]$rows[0]
}

function Expand-HeroEquipBlob([string]$Hex) {
    $inputBytes = [Convert]::FromHexString($Hex)
    $inputStream = [IO.MemoryStream]::new($inputBytes)
    $zlib = [IO.Compression.ZLibStream]::new($inputStream, [IO.Compression.CompressionMode]::Decompress)
    $outputStream = [IO.MemoryStream]::new()
    try { $zlib.CopyTo($outputStream); return [byte[]]$outputStream.ToArray() }
    finally { $zlib.Dispose(); $inputStream.Dispose(); $outputStream.Dispose() }
}

function Compress-HeroEquipBlob([byte[]]$Bytes) {
    $outputStream = [IO.MemoryStream]::new()
    $zlib = [IO.Compression.ZLibStream]::new($outputStream, [IO.Compression.CompressionLevel]::SmallestSize, $true)
    try { $zlib.Write($Bytes, 0, $Bytes.Length); $zlib.Dispose(); return [Convert]::ToHexString($outputStream.ToArray()).ToLowerInvariant() }
    finally { $zlib.Dispose(); $outputStream.Dispose() }
}

function Get-HeroEquipBlobLayout([byte[]]$Bytes) {
    $stream = [IO.MemoryStream]::new($Bytes)
    $reader = [IO.BinaryReader]::new($stream)
    $equipmentUids = New-Object System.Collections.Generic.List[uint32]
    $faBaoUids = New-Object System.Collections.Generic.List[uint32]
    try {
        $equipmentCount = $reader.ReadUInt16()
        for ($index = 0; $index -lt $equipmentCount; $index++) {
            $equipmentUids.Add($reader.ReadUInt32())
            $reader.ReadUInt16() | Out-Null
            $reader.ReadUInt32() | Out-Null
            $reader.ReadUInt32() | Out-Null
            $reader.ReadByte() | Out-Null
            $levelCount = $reader.ReadByte()
            for ($level = 0; $level -lt $levelCount; $level++) {
                $reader.ReadByte() | Out-Null
                $reader.ReadUInt16() | Out-Null
            }
        }
        $equipmentEnd = [int]$stream.Position
        $faBaoCount = $reader.ReadUInt16()
        $faBaoStart = [int]$stream.Position
        for ($index = 0; $index -lt $faBaoCount; $index++) {
            $faBaoUids.Add($reader.ReadUInt32())
            $reader.ReadUInt16() | Out-Null
            $reader.ReadUInt32() | Out-Null
            $reader.ReadByte() | Out-Null
            $reader.ReadByte() | Out-Null
            $levelCount = $reader.ReadByte()
            for ($level = 0; $level -lt $levelCount; $level++) {
                $reader.ReadByte() | Out-Null
                $reader.ReadByte() | Out-Null
            }
        }
        $faBaoEnd = [int]$stream.Position
        if ($Bytes.Length - $faBaoEnd -ne 6) { throw "HeroEquip pet_equip tail length is not uint32+uint16." }
        [pscustomobject]@{
            equipmentCount = [int]$equipmentCount
            equipmentEnd = $equipmentEnd
            equipmentUids = @($equipmentUids)
            faBaoCount = [int]$faBaoCount
            faBaoStart = $faBaoStart
            faBaoEnd = $faBaoEnd
            faBaoUids = @($faBaoUids)
        }
    }
    finally { $reader.Dispose(); $stream.Dispose() }
}

function Add-HeroEquipFixtureItems([string]$Hex) {
    $bytes = Expand-HeroEquipBlob $Hex
    $layout = Get-HeroEquipBlobLayout $bytes
    if ($fixtureEquipmentUid -in $layout.equipmentUids -or $fixtureFaBaoUid -in $layout.faBaoUids) {
        throw "HeroEquip reserved fixture UID already exists in the source snapshot."
    }
    $stream = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]($layout.equipmentCount + 1))
        $writer.Write($bytes, 2, $layout.equipmentEnd - 2)
        $writer.Write($fixtureEquipmentUid)
        $writer.Write($fixtureEquipmentTemplateId)
        $writer.Write([uint32]0)
        $writer.Write([uint32]0)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([uint16]($layout.faBaoCount + 1))
        $writer.Write($bytes, $layout.faBaoStart, $layout.faBaoEnd - $layout.faBaoStart)
        $writer.Write($fixtureFaBaoUid)
        $writer.Write($fixtureFaBaoTemplateId)
        $writer.Write([uint32]0)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write($bytes, $layout.faBaoEnd, $bytes.Length - $layout.faBaoEnd)
        return Compress-HeroEquipBlob ([byte[]]$stream.ToArray())
    }
    finally { $writer.Dispose(); $stream.Dispose() }
}

function Assert-HeroEquipFixtureItems {
    $rows = @(Invoke-HeroEquipSql "SELECT pet_equip FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "HeroEquip role row is missing while asserting fixture items." }
    $layout = Get-HeroEquipBlobLayout (Expand-HeroEquipBlob ([string]$rows[0]))
    if ($fixtureEquipmentUid -notin $layout.equipmentUids) { throw "HeroEquip fixture equipment is missing." }
    if ($fixtureFaBaoUid -notin $layout.faBaoUids) { throw "HeroEquip fixture fabao is missing." }
}

function Write-Evidence($value) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($value | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}
function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "HeroEquip fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

if ($Action -in @("Setup", "Restore", "Cleanup")) { Assert-ClientsStopped }
switch ($Action) {
    "Setup" {
        $userTable = Get-UserTable
        $hash = Get-RoleHash
        Invoke-HeroEquipSql "DROP TABLE IF EXISTS ``$roleBackup``; CREATE TABLE ``$roleBackup`` LIKE role_info; INSERT INTO ``$roleBackup`` SELECT * FROM role_info WHERE id=$RoleId; DROP TABLE IF EXISTS ``$userBackup``; CREATE TABLE ``$userBackup`` LIKE ``$userTable``; INSERT INTO ``$userBackup`` SELECT * FROM ``$userTable`` WHERE id=$UserId" | Out-Null
        $petEquipRows = @(Invoke-HeroEquipSql "SELECT pet_equip FROM role_info WHERE id=$RoleId")
        if ($petEquipRows.Count -ne 1) { throw "HeroEquip role pet_equip payload is missing." }
        $fixtureBlob = Add-HeroEquipFixtureItems ([string]$petEquipRows[0])
        Invoke-HeroEquipSql "UPDATE role_info SET pet_equip='$fixtureBlob' WHERE id=$RoleId" | Out-Null
        Assert-HeroEquipFixtureItems
        Write-Evidence ([ordered]@{
            action="Setup"; userId=$UserId; roleId=$RoleId; userTable=$userTable; snapshotHash=$hash
            fixtureHash=(Get-RoleHash); fixtureEquipmentUid=$fixtureEquipmentUid
            fixtureEquipmentTemplateId=$fixtureEquipmentTemplateId; fixtureFaBaoUid=$fixtureFaBaoUid
            fixtureFaBaoTemplateId=$fixtureFaBaoTemplateId; createdUtc=[DateTime]::UtcNow.ToString("O")
        })
    }
    "AssertSetup" {
        $snapshot = Read-Evidence
        if (@(Invoke-HeroEquipSql "SELECT COUNT(*) FROM ``$roleBackup`` WHERE id=$RoleId")[0] -ne "1") { throw "HeroEquip role backup is missing." }
        $backupHash = @(Invoke-HeroEquipSql "SELECT SHA2(CONCAT_WS('|',COALESCE(pet_equip,''),COALESCE(pet,''),COALESCE(zhenfa,''),COALESCE(money,''),COALESCE(package,''),COALESCE(mission,''),COALESCE(save_data,''),COALESCE(clientstring,'')),256) FROM ``$roleBackup`` WHERE id=$RoleId")[0]
        if ([string]$snapshot.snapshotHash -ne [string]$backupHash) { throw "HeroEquip immutable role backup hash changed." }
        Assert-HeroEquipFixtureItems
    }
    "Restore" {
        $snapshot = Read-Evidence
        $userTable = [string]$snapshot.userTable
        Invoke-HeroEquipSql "DELETE FROM role_info WHERE id=$RoleId; INSERT INTO role_info SELECT * FROM ``$roleBackup`` WHERE id=$RoleId; DELETE FROM ``$userTable`` WHERE id=$UserId; INSERT INTO ``$userTable`` SELECT * FROM ``$userBackup`` WHERE id=$UserId" | Out-Null
    }
    "AssertRestored" {
        $snapshot = Read-Evidence; $hash = Get-RoleHash
        if ($hash -ne [string]$snapshot.snapshotHash) { throw "HeroEquip restored role hash mismatch." }
        $snapshot | Add-Member -Force restoredHash $hash
        $snapshot | Add-Member -Force restored $true
        Write-Evidence $snapshot
    }
    "Cleanup" { Invoke-HeroEquipSql "DROP TABLE IF EXISTS ``$roleBackup``; DROP TABLE IF EXISTS ``$userBackup``" | Out-Null }
    "AssertCleanup" {
        $count = @(Invoke-HeroEquipSql "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME IN ('$roleBackup','$userBackup')")[0]
        if ([int]$count -ne 0) { throw "HeroEquip fixture backup tables remain after cleanup." }
    }
    "AssertReloginHash" {
        $snapshot = Read-Evidence; $hash = Get-RoleHash
        if ($hash -ne [string]$snapshot.snapshotHash) { throw "HeroEquip post-login restore hash mismatch." }
        $snapshot | Add-Member -Force postLoginHash $hash
        $snapshot | Add-Member -Force residualCount 0
        Write-Evidence $snapshot
    }
}
