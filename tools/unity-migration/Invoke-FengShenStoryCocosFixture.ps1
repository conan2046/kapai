[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup")]
    [string]$Action,
    [ValidateSet("Current", "MidChapter", "EndChapter", "NextChapter", "LaterChapter", "LaterEndChapter", "NoCount", "LockedEntry")]
    [string]$State = "LaterEndChapter",
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/FengShenStory/cocos/g1-20260802/fengshenstory-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }
$allowedIdentity = ($UserId -eq 7200057 -and $RoleId -eq 1000115) -or
    ($UserId -eq 7200260 -and $RoleId -eq 1000119) -or
    ($UserId -eq 705213 -and $RoleId -eq 1000006)
if (-not $allowedIdentity) { throw "FengShenStory Cocos fixture identity is not frozen in FENGSHEN_STORY_CONTROLS.json." }

function Invoke-FengShenStorySql {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "FengShenStory fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $workspaceExecutables = @(
        [IO.Path]::GetFullPath((Join-Path $root "build\server-win\Debug\kapai.exe")),
        [IO.Path]::GetFullPath((Join-Path $root "client\ProjectX\simulator\win32\ProjectX.exe"))
    )
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -eq "Unity" -or ($_.Path -and $workspaceExecutables -contains [IO.Path]::GetFullPath($_.Path))
    })
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before FengShenStory fixture $Action." }
}

function Get-UserTable {
    $tables = @(Invoke-FengShenStorySql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @(
        foreach ($tableName in $tables) {
            if ([string]$tableName -notmatch '^user_info\d*$') { throw "Unsafe user table name: $tableName" }
            $rows = @(Invoke-FengShenStorySql "SELECT role0 FROM ``$tableName`` WHERE id=$UserId AND role0=$RoleId")
            if ($rows.Count -eq 1) { [string]$tableName }
        }
    )
    if ($matches.Count -ne 1) { throw "FengShenStory userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    $matches[0]
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "FengShenStory fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Expand-GuanQia([string]$Hex) {
    $input = [IO.MemoryStream]::new([Convert]::FromHexString($Hex)); $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
        try { $zlib.CopyTo($output) } finally { $zlib.Dispose() }
        $output.ToArray()
    }
    finally { $input.Dispose(); $output.Dispose() }
}

function Compress-GuanQia([byte[]]$Raw) {
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $zlib.Write($Raw, 0, $Raw.Length) } finally { $zlib.Dispose() }
        [Convert]::ToHexString($output.ToArray())
    }
    finally { $output.Dispose() }
}

function Set-PetLevels([string]$Hex, [uint16]$Level) {
    $raw = Expand-GuanQia $Hex
    if ($raw.Length -lt 2) { throw "pet payload is incomplete." }
    $count = [int]$raw[0]; $extNum = [int]$raw[1]; $pos = 2
    for ($i = 0; $i -lt $count; $i++) {
        if ($pos + 11 -gt $raw.Length) { throw "pet payload ended before pet $i base fields." }
        $petId = [BitConverter]::ToUInt16($raw, $pos); $pos += 2
        if ($petId -eq 0) { continue }
        [Array]::Copy([BitConverter]::GetBytes($Level), 0, $raw, $pos, 2); $pos += 2
        $pos += 4 # exp
        $pos += 2 # star, break
        $nameLength = [int]$raw[$pos]; $pos++
        $pos += $nameLength
        if ($pos -gt $raw.Length) { throw "pet $petId name exceeds payload." }
        if ($extNum -gt 0) {
            if ($pos + 2 -gt $raw.Length) { throw "pet $petId cultivation payload is incomplete." }
            $pos++ # cultivation level
            $entryCount = [int]$raw[$pos]; $pos++
            $pos += 3 * $entryCount
            if ($pos -gt $raw.Length) { throw "pet $petId cultivation entries exceed payload." }
        }
    }
    Compress-GuanQia $raw
}

function Read-Byte([byte[]]$Data, $Cursor) {
    if ($Cursor.Position -ge $Data.Length) { throw "guan_qia decode overran byte at offset $($Cursor.Position)." }
    $value = $Data[$Cursor.Position]; $Cursor.Position++; $value
}

function Read-U16([byte[]]$Data, $Cursor) {
    if ($Cursor.Position + 2 -gt $Data.Length) { throw "guan_qia decode overran uint16 at offset $($Cursor.Position)." }
    $value = [BitConverter]::ToUInt16($Data, $Cursor.Position); $Cursor.Position += 2; $value
}

function Read-U32([byte[]]$Data, $Cursor) {
    if ($Cursor.Position + 4 -gt $Data.Length) { throw "guan_qia decode overran uint32 at offset $($Cursor.Position)." }
    $value = [BitConverter]::ToUInt32($Data, $Cursor.Position); $Cursor.Position += 4; $value
}

function Skip-GuanQiaSection([byte[]]$Data, $Cursor) {
    [void](Read-U32 $Data $Cursor); [void](Read-U32 $Data $Cursor)
    $mapCount = Read-U16 $Data $Cursor
    for ($i = 0; $i -lt $mapCount; $i++) {
        [void](Read-U32 $Data $Cursor); [void](Read-U16 $Data $Cursor)
        $nodeCount = Read-Byte $Data $Cursor; $Cursor.Position += 5 * $nodeCount
        $fixCount = Read-Byte $Data $Cursor; $Cursor.Position += 4 * $fixCount
        $stateCount = Read-Byte $Data $Cursor; $Cursor.Position += 5 * $stateCount
        if ($Cursor.Position -gt $Data.Length) { throw "guan_qia section overran payload." }
    }
}

function Get-LieZhuanOffset([byte[]]$Raw) {
    $cursor = [pscustomobject]@{ Position = 0 }
    Skip-GuanQiaSection $Raw $cursor
    Skip-GuanQiaSection $Raw $cursor
    $attackCount = Read-U16 $Raw $cursor; $cursor.Position += 5 * $attackCount
    $resetCount = Read-U16 $Raw $cursor; $cursor.Position += 5 * $resetCount
    $trialCount = Read-Byte $Raw $cursor; $cursor.Position += 13 * $trialCount
    if ($cursor.Position + 9 -gt $Raw.Length) { throw "guan_qia payload has no complete LieZhuan tail at offset $($cursor.Position)." }
    $cursor.Position
}

function Read-LieZhuan([string]$Hex) {
    $raw = Expand-GuanQia $Hex; $offset = Get-LieZhuanOffset $raw
    [ordered]@{
        count = [int]$raw[$offset]
        chapterIndex = [uint32][BitConverter]::ToUInt32($raw, $offset + 1)
        nodeId = [uint32][BitConverter]::ToUInt32($raw, $offset + 5)
        rawBytes = $raw.Length
        offset = $offset
    }
}

function Set-LieZhuan([string]$Hex, [byte]$Count, [uint32]$ChapterIndex, [uint32]$NodeId) {
    $raw = Expand-GuanQia $Hex; $offset = Get-LieZhuanOffset $raw
    $raw[$offset] = $Count
    [Array]::Copy([BitConverter]::GetBytes($ChapterIndex), 0, $raw, $offset + 1, 4)
    [Array]::Copy([BitConverter]::GetBytes($NodeId), 0, $raw, $offset + 5, 4)
    $updated = Compress-GuanQia $raw
    $actual = Read-LieZhuan $updated
    if ($actual.count -ne $Count -or $actual.chapterIndex -ne $ChapterIndex -or $actual.nodeId -ne $NodeId) {
        throw "FengShenStory fixture round-trip mismatch."
    }
    [ordered]@{ hex = $updated; state = $actual }
}

$stateDefinition = switch ($State) {
    "Current" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]0; nodeId = [uint32]40011 } }
    "MidChapter" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]0; nodeId = [uint32]40013 } }
    "EndChapter" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]0; nodeId = [uint32]40014; petLevel = [uint16]100 } }
    "NextChapter" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]1; nodeId = [uint32]40021 } }
    "LaterChapter" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]6; nodeId = [uint32]40071 } }
    "LaterEndChapter" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]6; nodeId = [uint32]40074; petLevel = [uint16]100 } }
    "NoCount" { [ordered]@{ count = [byte]0; chapterIndex = [uint32]0; nodeId = [uint32]40011 } }
    "LockedEntry" { [ordered]@{ count = [byte]5; chapterIndex = [uint32]0; nodeId = [uint32]40011; roleLevel = 1 } }
}

Assert-ClientsStopped
$userTable = Get-UserTable
$hashExpression = "LOWER(SHA2(CONCAT_WS('|',COALESCE(r.guan_qia,''),COALESCE(r.pet,''),COALESCE(r.user_spirit,''),COALESCE(r.package,''),COALESCE(r.save_data,''),COALESCE(r.save_val,''),COALESCE(r.mission,''),COALESCE(CAST(r.money AS CHAR),''),COALESCE(CAST(r.exp AS CHAR),''),COALESCE(CAST(r.level AS CHAR),''),COALESCE(CAST(u.money AS CHAR),''),COALESCE(CAST(u.bd_money AS CHAR),'')),256))"

Invoke-FengShenStorySql @"
CREATE TABLE IF NOT EXISTS unity_validation_fengshenstory_fixture (
 user_id INT UNSIGNED NOT NULL, role_id INT UNSIGNED NOT NULL, user_table VARCHAR(64) NOT NULL,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0, fixture_state VARCHAR(32) NOT NULL,
 backup_guan_qia MEDIUMTEXT NULL, backup_pet MEDIUMTEXT NULL, backup_user_spirit MEDIUMTEXT NULL, backup_package MEDIUMTEXT NULL,
 backup_save_data MEDIUMTEXT NULL, backup_save_val MEDIUMTEXT NULL, backup_mission MEDIUMTEXT NULL,
 backup_role_money BIGINT NULL, backup_exp BIGINT NULL, backup_level INT NULL,
 backup_user_money BIGINT NULL, backup_bd_money BIGINT NULL, snapshot_hash CHAR(64) NOT NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"@ | Out-Null
$petColumnCount = @(Invoke-FengShenStorySql "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME='unity_validation_fengshenstory_fixture' AND COLUMN_NAME='backup_pet'")
if ($petColumnCount.Count -ne 1) { throw "Could not inspect FengShenStory backup_pet fixture column." }
if ([int]$petColumnCount[0] -eq 0) {
    Invoke-FengShenStorySql "ALTER TABLE unity_validation_fengshenstory_fixture ADD COLUMN backup_pet MEDIUMTEXT NULL AFTER backup_guan_qia;" | Out-Null
}

switch ($Action) {
    "Setup" {
        $existing = @(Invoke-FengShenStorySql "SELECT applied,fixture_state FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId")
        $reapplyLiveState = $false
        if ($existing.Count -eq 0) {
            Invoke-FengShenStorySql @"
INSERT INTO unity_validation_fengshenstory_fixture
SELECT $UserId,$RoleId,'$userTable',0,'$State',r.guan_qia,r.pet,r.user_spirit,r.package,r.save_data,r.save_val,r.mission,
 r.money,r.exp,r.level,u.money,u.bd_money,$hashExpression
FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId;
"@ | Out-Null
        }
        elseif ($existing.Count -eq 1 -and $existing[0] -eq "1`t$State") {
            # The server may normalize a serialized field during login (for example the daily
            # LieZhuan count). Reapplying the same state patches only the live serialized value;
            # the original snapshot remains untouched for the final restore/hash assertion.
            $reapplyLiveState = $true
        }
        elseif ($existing.Count -ne 1 -or -not ([string]$existing[0]).StartsWith("0`t")) { throw "FengShenStory fixture already exists in another applied or ambiguous state." }

        $sourceColumn = if ($reapplyLiveState) { "r.guan_qia" } else { "f.backup_guan_qia" }
        $sourceHex = @(Invoke-FengShenStorySql "SELECT $sourceColumn FROM role_info r JOIN unity_validation_fengshenstory_fixture f ON f.role_id=r.id WHERE f.user_id=$UserId AND f.role_id=$RoleId")
        if ($sourceHex.Count -ne 1 -or [string]::IsNullOrWhiteSpace($sourceHex[0])) { throw "FengShenStory source guan_qia is missing." }
        $patched = Set-LieZhuan -Hex ([string]$sourceHex[0]) -Count $stateDefinition.count -ChapterIndex $stateDefinition.chapterIndex -NodeId $stateDefinition.nodeId
        $petAssignment = ""
        if ($stateDefinition.Contains('petLevel')) {
            $backupPet = @(Invoke-FengShenStorySql "SELECT backup_pet FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId AND role_id=$RoleId")
            if ($backupPet.Count -ne 1 -or [string]::IsNullOrWhiteSpace($backupPet[0])) { throw "FengShenStory backup pet is missing." }
            $battlePet = Set-PetLevels -Hex ([string]$backupPet[0]) -Level $stateDefinition.petLevel
            $petAssignment = ",pet='$battlePet'"
        }
        $levelAssignment = if ($stateDefinition.Contains('roleLevel')) { ",level=$($stateDefinition.roleLevel)" } else { "" }
        Invoke-FengShenStorySql "UPDATE role_info SET guan_qia='$($patched.hex)'$petAssignment$levelAssignment WHERE id=$RoleId; UPDATE unity_validation_fengshenstory_fixture SET applied=1,fixture_state='$State' WHERE user_id=$UserId AND role_id=$RoleId;" | Out-Null
        $row = @(Invoke-FengShenStorySql "SELECT snapshot_hash FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        Write-Evidence ([ordered]@{ action="Setup"; userId=$UserId; roleId=$RoleId; userTable=$userTable; fixtureState=$State; snapshotHash=$row[0]; injected=$patched.state; createdUtc=[DateTime]::UtcNow.ToString('o') })
        Write-Output "FengShenStory fixture setup: state=$State chapterIndex=$($patched.state.chapterIndex) node=$($patched.state.nodeId) count=$($patched.state.count)"
    }
    "AssertSetup" {
        $row = @(Invoke-FengShenStorySql "SELECT applied,fixture_state FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne "1`t$State") { throw "FengShenStory fixture setup row mismatch: $($row -join ',')" }
        $liveHex = @(Invoke-FengShenStorySql "SELECT guan_qia FROM role_info WHERE id=$RoleId")
        $actual = Read-LieZhuan ([string]$liveHex[0])
        if ($actual.count -ne $stateDefinition.count -or $actual.chapterIndex -ne $stateDefinition.chapterIndex -or $actual.nodeId -ne $stateDefinition.nodeId) { throw "FengShenStory live fixture state mismatch." }
        if ($stateDefinition.Contains('roleLevel')) {
            $liveLevel = @(Invoke-FengShenStorySql "SELECT level FROM role_info WHERE id=$RoleId")
            if ($liveLevel.Count -ne 1 -or [int]$liveLevel[0] -ne [int]$stateDefinition.roleLevel) { throw "FengShenStory live fixture role level mismatch." }
        }
        Write-Output "FengShenStory fixture assert passed: state=$State node=$($actual.nodeId) count=$($actual.count)"
    }
    "Restore" {
        $row = @(Invoke-FengShenStorySql "SELECT applied,user_table FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($row.Count -ne 1) { throw "FengShenStory fixture row is missing for restore." }
        Invoke-FengShenStorySql @"
UPDATE role_info r JOIN unity_validation_fengshenstory_fixture f ON f.role_id=r.id
SET r.guan_qia=f.backup_guan_qia,r.pet=f.backup_pet,r.user_spirit=f.backup_user_spirit,r.package=f.backup_package,
 r.save_data=f.backup_save_data,r.save_val=f.backup_save_val,r.mission=f.backup_mission,
 r.money=f.backup_role_money,r.exp=f.backup_exp,r.level=f.backup_level
WHERE f.user_id=$UserId AND f.role_id=$RoleId;
UPDATE ``$userTable`` u JOIN unity_validation_fengshenstory_fixture f ON f.user_id=u.id AND f.role_id=u.role0
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money WHERE f.user_id=$UserId AND f.role_id=$RoleId;
UPDATE unity_validation_fengshenstory_fixture SET applied=0 WHERE user_id=$UserId AND role_id=$RoleId;
"@ | Out-Null
        Write-Output "FengShenStory fixture restored."
    }
    "AssertRestored" {
        $row = @(Invoke-FengShenStorySql "SELECT COUNT(*)=1 AND f.applied=0 AND $hashExpression=f.snapshot_hash FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId JOIN unity_validation_fengshenstory_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId WHERE r.id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne '1') { throw "FengShenStory restored hash mismatch." }
        $snapshot = Read-Evidence
        Write-Evidence ([ordered]@{ action="AssertRestored"; userId=$UserId; roleId=$RoleId; fixtureState=$snapshot.fixtureState; snapshotHash=$snapshot.snapshotHash; restoredHash=$snapshot.snapshotHash; restored=$true; assertedUtc=[DateTime]::UtcNow.ToString('o') })
        Write-Output "FengShenStory fixture restore hash passed: $($snapshot.snapshotHash)"
    }
    "Cleanup" {
        $row = @(Invoke-FengShenStorySql "SELECT applied FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne '0') { throw "FengShenStory fixture must be restored before cleanup." }
        Invoke-FengShenStorySql "DELETE FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId AND role_id=$RoleId" | Out-Null
        Write-Output "FengShenStory fixture cleanup complete."
    }
    "AssertCleanup" {
        $row = @(Invoke-FengShenStorySql "SELECT COUNT(*) FROM unity_validation_fengshenstory_fixture WHERE user_id=$UserId OR role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne '0') { throw "FengShenStory fixture residual rows remain: $($row -join ',')" }
        Write-Output "FengShenStory fixture residual count=0"
    }
}

# The fixed-account Unity runner switches to this second real account. Keep its
# serialized LieZhuan state valid and independent under the same reversible
# lifecycle, while retaining a separate snapshot/hash artifact.
if ($UserId -eq 7200057 -and $RoleId -eq 1000115) {
    $isolationEvidencePath = if ($EvidencePath -match '\.json$') {
        $EvidencePath -replace '\.json$', '-isolation.json'
    } else {
        "$EvidencePath-isolation.json"
    }
    & pwsh -NoProfile -File $PSCommandPath -Action $Action -State Current `
        -UserId 705213 -RoleId 1000006 -EvidencePath $isolationEvidencePath
    if ($LASTEXITCODE -ne 0) { throw "FengShenStory isolation fixture action failed: $Action" }
}
