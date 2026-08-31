[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "SetupVisual", "AssertSetup", "AssertPostValidation", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash", "SeedTestProgress")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/World/cocos/g1-20260731-cua/world-fixed-fixture-snapshot.json",
    [string]$DatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }

if ($DatabasePath) {
    if (-not [IO.Path]::IsPathRooted($DatabasePath)) { $DatabasePath = Join-Path $root $DatabasePath }
    $DatabasePath = [IO.Path]::GetFullPath($DatabasePath)
    if (-not $DatabasePath.EndsWith("LocalServer\projectx.db", [StringComparison]::OrdinalIgnoreCase)) {
        throw "World fixture only accepts Application.persistentDataPath/LocalServer/projectx.db."
    }
    if ($UserId -ne 7200057 -or $RoleId -ne 1000003) {
        throw "World SQLite fixture identity must remain 7200057/1000003."
    }
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before World SQLite fixture $Action." }
    $backup = Join-Path $root ".local\unity-validation\world-sqlite-fixture-backup.db"
    & python -X utf8 (Join-Path $PSScriptRoot "Invoke-WorldCocosFixture.py") `
        --action $Action --database $DatabasePath --backup $backup --evidence $evidence `
        --user-id $UserId --role-id $RoleId
    if ($LASTEXITCODE -ne 0) { throw "World SQLite fixture adapter failed: $Action" }
    return
}

$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-WorldSql {
    param([Parameter(Mandatory = $true)][string]$Sql, [switch]$ReturnOutput)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "World fixture SQL failed: $($output -join [Environment]::NewLine)" }
    if ($ReturnOutput) { return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" }) }
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before $Action so the World snapshot cannot race a save." }
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "World fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

$hashExpression = @"
SHA2(CONCAT_WS('|',
COALESCE(TO_BASE64(r.guan_qia),''),COALESCE(TO_BASE64(r.package),''),
COALESCE(TO_BASE64(r.save_data),''),COALESCE(TO_BASE64(r.save_val),''),
COALESCE(TO_BASE64(r.user_spirit),''),COALESCE(TO_BASE64(r.mission),''),
COALESCE(CAST(r.money AS CHAR),''),COALESCE(CAST(r.exp AS CHAR),''),
COALESCE(CAST(r.level AS CHAR),''),COALESCE(CAST(u.money AS CHAR),''),
COALESCE(CAST(u.bd_money AS CHAR),'')
),256)
"@ -replace "\r?\n", ""

# mission, save_val day/week markers, the selected chapter derived from the
# selected node, and trial availability counters are normalized by the
# authoritative login path even without a player mutation. Keep every raw
# field in the exact restore hash. The post-relogin oracle hashes all other
# fields here and compares those World/save_val fields canonically below.
$reloginHashExpression = @"
SHA2(CONCAT_WS('|',
COALESCE(TO_BASE64(r.package),''),COALESCE(TO_BASE64(r.save_data),''),
COALESCE(TO_BASE64(r.user_spirit),''),
COALESCE(CAST(r.money AS CHAR),''),COALESCE(CAST(r.exp AS CHAR),''),
COALESCE(CAST(r.level AS CHAR),''),COALESCE(CAST(u.money AS CHAR),''),
COALESCE(CAST(u.bd_money AS CHAR),'')
),256)
"@ -replace "\r?\n", ""

$createTableSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_world_fixture (
 user_id INT UNSIGNED NOT NULL,
 role_id INT UNSIGNED NOT NULL,
 enabled TINYINT UNSIGNED NOT NULL DEFAULT 1,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 backup_guan_qia MEDIUMTEXT NULL, backup_package MEDIUMTEXT NULL,
 backup_save_data MEDIUMTEXT NULL, backup_save_val MEDIUMTEXT NULL,
 backup_user_spirit MEDIUMTEXT NULL, backup_mission MEDIUMTEXT NULL,
 backup_role_money BIGINT NULL, backup_exp BIGINT NULL, backup_level INT NULL,
 backup_user_money BIGINT NULL, backup_bd_money BIGINT NULL,
 snapshot_hash CHAR(64) NULL, stable_snapshot_hash CHAR(64) NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@

function Expand-WorldGuanQia {
    param([Parameter(Mandatory = $true)][byte[]]$Compressed)
    $input = [IO.MemoryStream]::new($Compressed); $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
        try { $zlib.CopyTo($output) } finally { $zlib.Dispose() }
        return $output.ToArray()
    }
    finally { $input.Dispose(); $output.Dispose() }
}

function Compress-WorldGuanQia {
    param([Parameter(Mandatory = $true)][byte[]]$Raw)
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $zlib.Write($Raw, 0, $Raw.Length) } finally { $zlib.Dispose() }
        return $output.ToArray()
    }
    finally { $output.Dispose() }
}

function Read-WorldUInt16 {
    param([byte[]]$Data, $Cursor)
    if ($Cursor.Position + 2 -gt $Data.Length) { throw "World fixture guan_qia decode overran uint16 at offset $($Cursor.Position)." }
    $value = [BitConverter]::ToUInt16($Data, $Cursor.Position); [void]($Cursor.Position += 2); return $value
}

function Read-WorldUInt32 {
    param([byte[]]$Data, $Cursor)
    if ($Cursor.Position + 4 -gt $Data.Length) { throw "World fixture guan_qia decode overran uint32 at offset $($Cursor.Position)." }
    $value = [BitConverter]::ToUInt32($Data, $Cursor.Position); [void]($Cursor.Position += 4); return $value
}

function Read-WorldByte {
    param([byte[]]$Data, $Cursor)
    if ($Cursor.Position -ge $Data.Length) { throw "World fixture guan_qia decode overran byte at offset $($Cursor.Position)." }
    $value = $Data[$Cursor.Position]; [void]($Cursor.Position++); return $value
}

function Read-WorldGuanQiaSection {
    param([byte[]]$Data, $Cursor)
    $curMapId = Read-WorldUInt32 $Data $Cursor
    $curNodeId = Read-WorldUInt32 $Data $Cursor
    $mapCount = Read-WorldUInt16 $Data $Cursor
    $maps = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $mapCount; $index++) {
        $mapId = Read-WorldUInt32 $Data $Cursor
        $sumStar = Read-WorldUInt16 $Data $Cursor
        $nodeStars = [ordered]@{}
        $nodeCount = Read-WorldByte $Data $Cursor
        for ($nodeIndex = 0; $nodeIndex -lt $nodeCount; $nodeIndex++) {
            $nodeId = [uint32](Read-WorldUInt32 $Data $Cursor)
            $star = [byte](Read-WorldByte $Data $Cursor)
            [void]($nodeStars[$nodeId] = $star)
        }
        $fixIds = [System.Collections.Generic.List[uint32]]::new()
        $fixCount = Read-WorldByte $Data $Cursor
        for ($fixIndex = 0; $fixIndex -lt $fixCount; $fixIndex++) { $fixIds.Add([uint32](Read-WorldUInt32 $Data $Cursor)) }
        $fixStates = [ordered]@{}
        $stateCount = Read-WorldByte $Data $Cursor
        for ($stateIndex = 0; $stateIndex -lt $stateCount; $stateIndex++) {
            $stateId = [uint32](Read-WorldUInt32 $Data $Cursor)
            $state = [byte](Read-WorldByte $Data $Cursor)
            [void]($fixStates[$stateId] = $state)
        }
        $maps.Add([pscustomobject]@{ mapId = [uint32]$mapId; sumStar = [uint16]$sumStar; nodeStars = $nodeStars; fixIds = $fixIds; fixStates = $fixStates })
    }
    [pscustomobject]@{ curMapId = [uint32]$curMapId; curNodeId = [uint32]$curNodeId; maps = $maps }
}

function Add-WorldUInt16 { param([System.Collections.Generic.List[byte]]$Bytes, [uint16]$Value) $Bytes.AddRange([BitConverter]::GetBytes($Value)) }
function Add-WorldUInt32 { param([System.Collections.Generic.List[byte]]$Bytes, [uint32]$Value) $Bytes.AddRange([BitConverter]::GetBytes($Value)) }

function Write-WorldGuanQiaSection {
    param([System.Collections.Generic.List[byte]]$Bytes, $Section)
    if ($Section.maps.Count -gt [byte]::MaxValue) { throw "World fixture map count exceeds the persisted uint16/uint8 safety limit." }
    Add-WorldUInt32 $Bytes $Section.curMapId; Add-WorldUInt32 $Bytes $Section.curNodeId; Add-WorldUInt16 $Bytes ([uint16]$Section.maps.Count)
    foreach ($map in @($Section.maps | Sort-Object mapId)) {
        if ($map.nodeStars.Count -gt [byte]::MaxValue -or $map.fixIds.Count -gt [byte]::MaxValue -or $map.fixStates.Count -gt [byte]::MaxValue) { throw "World fixture map $($map.mapId) exceeds a persisted byte-count limit." }
        Add-WorldUInt32 $Bytes $map.mapId; Add-WorldUInt16 $Bytes $map.sumStar
        $Bytes.Add([byte]$map.nodeStars.Count)
        foreach ($nodeId in @($map.nodeStars.Keys | Sort-Object)) { Add-WorldUInt32 $Bytes ([uint32]$nodeId); $Bytes.Add([byte]$map.nodeStars[$nodeId]) }
        $Bytes.Add([byte]$map.fixIds.Count)
        foreach ($fixId in @($map.fixIds | Sort-Object -Unique)) { Add-WorldUInt32 $Bytes $fixId }
        $Bytes.Add([byte]$map.fixStates.Count)
        foreach ($fixId in @($map.fixStates.Keys | Sort-Object)) { Add-WorldUInt32 $Bytes ([uint32]$fixId); $Bytes.Add([byte]$map.fixStates[$fixId]) }
    }
}

function Get-WorldFixturePayload {
    param([Parameter(Mandatory = $true)][string]$GuanQiaHex)
    $raw = Expand-WorldGuanQia ([Convert]::FromHexString($GuanQiaHex))
    $cursor = [pscustomobject]@{ Position = 0 }
    $primary = Read-WorldGuanQiaSection $raw $cursor
    $secondary = Read-WorldGuanQiaSection $raw $cursor
    if ($cursor.Position -ge $raw.Length) { throw "World fixture guan_qia payload has no post-chapter state." }
    [pscustomobject]@{ raw = $raw; primary = $primary; secondary = $secondary; tail = $raw[$cursor.Position..($raw.Length - 1)] }
}

function ConvertTo-WorldCanonicalSection {
    param($Section, [switch]$IgnoreDerivedCurrentMap)
    [ordered]@{
        curMapId = if ($IgnoreDerivedCurrentMap) { $null } else { [uint32]$Section.curMapId }
        curNodeId = [uint32]$Section.curNodeId
        maps = @($Section.maps | Sort-Object mapId | ForEach-Object {
            $map = $_
            [ordered]@{
                mapId = [uint32]$map.mapId
                sumStar = [uint16]$map.sumStar
                nodeStars = @($map.nodeStars.Keys | Sort-Object | ForEach-Object {
                    [ordered]@{ id = [uint32]$_; value = [byte]$map.nodeStars[$_] }
                })
                fixIds = @($map.fixIds | Sort-Object -Unique | ForEach-Object { [uint32]$_ })
                fixStates = @($map.fixStates.Keys | Sort-Object | ForEach-Object {
                    [ordered]@{ id = [uint32]$_; value = [byte]$map.fixStates[$_] }
                })
            }
        })
    }
}

function Get-WorldReloginCanonicalGuanQia {
    param([Parameter(Mandatory = $true)][string]$GuanQiaHex)
    $payload = Get-WorldFixturePayload -GuanQiaHex $GuanQiaHex
    $tail = [byte[]]$payload.tail
    $cursor = [pscustomobject]@{ Position = 0 }

    $attackCounts = @()
    $attackCount = Read-WorldUInt16 $tail $cursor
    for ($index = 0; $index -lt $attackCount; $index++) {
        $attackCounts += [ordered]@{ id = Read-WorldUInt32 $tail $cursor; value = Read-WorldByte $tail $cursor }
    }
    $resetCounts = @()
    $resetCount = Read-WorldUInt16 $tail $cursor
    for ($index = 0; $index -lt $resetCount; $index++) {
        $resetCounts += [ordered]@{ id = Read-WorldUInt32 $tail $cursor; value = Read-WorldByte $tail $cursor }
    }
    $trials = @()
    $trialCount = Read-WorldByte $tail $cursor
    for ($index = 0; $index -lt $trialCount; $index++) {
        $mapId = Read-WorldUInt32 $tail $cursor
        [void](Read-WorldByte $tail $cursor) # login-derived current-week attempt count
        $trials += [ordered]@{
            mapId = $mapId
            sweptNodeId = Read-WorldUInt32 $tail $cursor
            challengeNodeId = Read-WorldUInt32 $tail $cursor
        }
    }
    $lieZhuanCount = Read-WorldByte $tail $cursor
    $lieZhuanMapIndex = Read-WorldUInt32 $tail $cursor
    $lieZhuanNodeId = Read-WorldUInt32 $tail $cursor
    $achievementId = Read-WorldByte $tail $cursor
    $achievementState = Read-WorldByte $tail $cursor
    if ($cursor.Position -ne $tail.Length) {
        throw "World relogin canonical decoder left unexpected tail bytes: consumed=$($cursor.Position) total=$($tail.Length)."
    }

    ([ordered]@{
        primary = ConvertTo-WorldCanonicalSection $payload.primary -IgnoreDerivedCurrentMap
        secondary = ConvertTo-WorldCanonicalSection $payload.secondary
        attackCounts = @($attackCounts | Sort-Object id)
        resetCounts = @($resetCounts | Sort-Object id)
        trials = @($trials | Sort-Object mapId)
        lieZhuan = [ordered]@{ count = $lieZhuanCount; mapIndex = $lieZhuanMapIndex; nodeId = $lieZhuanNodeId }
        achievement = [ordered]@{ id = $achievementId; state = $achievementState }
    } | ConvertTo-Json -Depth 12 -Compress)
}

function Get-WorldReloginCanonicalSaveVal {
    param([Parameter(Mandatory = $true)][string]$SaveVal)
    $parts = @($SaveVal -split '\|')
    if ($parts.Count -ne 12) { throw "World save_val expected 12 persisted values, found $($parts.Count)." }
    # MAX_SAVE_NUM-2 and MAX_SAVE_NUM-1 are the server-owned daily and weekly
    # normalization markers. All business values before them remain strict.
    ($parts[0..9] -join '|')
}

function Get-WorldFixturePreconditions {
    param([string]$GuanQiaHex)
    # CUserGuanQia persists zlib bytes. The fixture decodes and reserializes the
    # exact C++ SaveGuanQia layout; every business-field write is restored from
    # the snapshot before the fixture row is removed.
    $payload = Get-WorldFixturePayload -GuanQiaHex $GuanQiaHex
    $rawLength = $payload.raw.Length
    if ($rawLength -lt 300) { throw "World fixture guan_qia payload is too small for the verified chapter-3 state: bytes=$rawLength." }
    $chapter = @($payload.primary.maps | Where-Object { $_.mapId -eq 1003 })
    if ($chapter.Count -ne 1) { throw "World fixture requires exactly one persisted main chapter 1003 record." }
    [ordered]@{ guanQiaRawBytes = $rawLength; requiredMapId = 1003; requiredNodeId = 10023; existingChapterStars = [int]$chapter[0].sumStar }
}

function Set-WorldFixtureClaimableBoxes {
    param([Parameter(Mandatory = $true)][string]$GuanQiaHex)
    $payload = Get-WorldFixturePayload -GuanQiaHex $GuanQiaHex
    $chapter = @($payload.primary.maps | Where-Object { $_.mapId -eq 1003 })
    if ($chapter.Count -ne 1) { throw "World fixture cannot inject target chapter 1003 because its persisted record is missing or ambiguous." }
    $chapter = $chapter[0]
    # 10031 is the real 3-3 normal chest; 20031 is chapter 3's ten-star chest.
    # Mark both as server-claimable and enter that same authoritative chapter.
    # Otherwise the client correctly renders the account's current chapter 4,
    # where the chapter-3 boxes are intentionally absent.
    [void]($payload.primary.curMapId = [uint32]1003)
    [void]($payload.primary.curNodeId = [uint32]10031)
    [void]($chapter.sumStar = [uint16][Math]::Max([int]$chapter.sumStar, 10))
    foreach ($fixId in @([uint32]10031, [uint32]20031)) {
        if (-not $chapter.fixIds.Contains($fixId)) { $chapter.fixIds.Add($fixId) }
        [void]($chapter.fixStates[$fixId] = [byte]1)
    }
    $bytes = [System.Collections.Generic.List[byte]]::new()
    Write-WorldGuanQiaSection $bytes $payload.primary
    Write-WorldGuanQiaSection $bytes $payload.secondary
    $bytes.AddRange([byte[]]$payload.tail)
    $compressed = Compress-WorldGuanQia ([byte[]]$bytes.ToArray())
    $roundTrip = Get-WorldFixturePayload -GuanQiaHex ([BitConverter]::ToString($compressed).Replace('-', ''))
    $roundTripChapter = @($roundTrip.primary.maps | Where-Object { $_.mapId -eq 1003 })[0]
    if (@($roundTripChapter.fixStates.Keys).Count -lt 2) {
        throw "World fixture serializer lost injected box states; count=$($roundTripChapter.fixStates.Count) keys=$(@($roundTripChapter.fixStates.Keys) -join ',')."
    }
    [ordered]@{ hex = [BitConverter]::ToString($compressed).Replace('-', ''); rawBytes = $bytes.Count; chapterStarCount = [int]$chapter.sumStar; normalBoxId = 10031; starBoxId = 20031 }
}

function Assert-RoleClientsStopped {
    $running = @(Get-Process kapai, ProjectX -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe and ProjectX.exe before changing persistent World test progress." }
}

function Set-WorldTestProgress {
    param([Parameter(Mandatory = $true)][string]$GuanQiaHex)
    $payload = Get-WorldFixturePayload -GuanQiaHex $GuanQiaHex
    $required = [ordered]@{
        "1001" = @([uint32]10006)
        "1002" = @([uint32]10016, [uint32]10019, [uint32]10020)
    }
    foreach ($mapIdText in $required.Keys) {
        $mapId = [uint32]$mapIdText
        $chapter = @($payload.primary.maps | Where-Object { $_.mapId -eq $mapId })
        if ($chapter.Count -eq 0) {
            $chapter = [pscustomobject]@{
                mapId = $mapId; sumStar = [uint16]0; nodeStars = [ordered]@{}
                fixIds = [System.Collections.Generic.List[uint32]]::new(); fixStates = [ordered]@{}
            }
            $payload.primary.maps.Add($chapter)
        } elseif ($chapter.Count -eq 1) { $chapter = $chapter[0] }
        else { throw "World test progress map $mapId is duplicated." }
        foreach ($nodeId in $required[$mapIdText]) { [void]($chapter.nodeStars[$nodeId] = [byte]3) }
        $chapter.sumStar = [uint16][Math]::Max([int]$chapter.sumStar, 3 * $chapter.nodeStars.Count)
    }
    $bytes = [System.Collections.Generic.List[byte]]::new()
    Write-WorldGuanQiaSection $bytes $payload.primary
    Write-WorldGuanQiaSection $bytes $payload.secondary
    $bytes.AddRange([byte[]]$payload.tail)
    $compressed = Compress-WorldGuanQia ([byte[]]$bytes.ToArray())
    [ordered]@{ hex = [BitConverter]::ToString($compressed).Replace('-', ''); stageIds = @(10006,10016,10019,10020) }
}
function Get-WorldFixtureRow {
    $rows = @(Invoke-WorldSql -Sql @"
SELECT REPLACE(TO_BASE64(backup_guan_qia), CHAR(10), ''), snapshot_hash, stable_snapshot_hash
FROM unity_validation_world_fixture
WHERE user_id=$UserId AND role_id=$RoleId AND enabled=1
"@ -ReturnOutput)
    if ($rows.Count -ne 1) { throw "World fixture row is missing or ambiguous for userId=$UserId roleId=$RoleId." }
    $parts = $rows[0] -split "`t", 3
    if ($parts.Count -ne 3 -or [string]::IsNullOrWhiteSpace($parts[1]) -or [string]::IsNullOrWhiteSpace($parts[2])) { throw "World fixture snapshot is incomplete." }
    [pscustomobject]@{ guanQiaHex = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[0])); snapshotHash = $parts[1]; stableSnapshotHash = $parts[2] }
}

function Get-WorldLiveGuanQiaHex {
    # role_info.guan_qia is legacy UTF-8 text that itself contains hexadecimal
    # compressed bytes (not a BLOB). Writing UNHEX here would be rejected by
    # utf8mb3 and would also violate the C++ persistence representation.
    $rows = @(Invoke-WorldSql -Sql "SELECT guan_qia FROM role_info WHERE id=$RoleId" -ReturnOutput)
    if ($rows.Count -ne 1 -or [string]::IsNullOrWhiteSpace($rows[0])) { throw "World fixture live guan_qia is missing for roleId=$RoleId." }
    [string]$rows[0]
}

function Assert-WorldFixtureInjection {
    param([Parameter(Mandatory = $true)][string]$GuanQiaHex, [switch]$AllowClaimed)
    $payload = Get-WorldFixturePayload -GuanQiaHex $GuanQiaHex
    $chapter = @($payload.primary.maps | Where-Object { $_.mapId -eq 1003 })
    if ($chapter.Count -ne 1) { throw "World fixture injected chapter 1003 is missing or ambiguous." }
    $chapter = $chapter[0]
    foreach ($fixId in @([uint32]10031, [uint32]20031)) {
        $hasPendingId = @($chapter.fixIds) -contains $fixId
        $hasPendingState = @($chapter.fixStates.Keys) -contains $fixId
        $state = if ($hasPendingState) { [byte]$chapter.fixStates[$fixId] } else { [byte]0 }
        $valid = if ($AllowClaimed) { ($state -eq 1 -and $hasPendingId) -or ($state -eq 2 -and -not $hasPendingId) } else { $state -eq 1 -and $hasPendingId }
        if (-not $valid) {
            throw "World fixture injected box $fixId has an invalid persisted state (allowClaimed=$AllowClaimed pendingId=$hasPendingId pendingState=$hasPendingState state=$state stateKeys=$(@($chapter.fixStates.Keys) -join ','))."
        }
    }
    if ([int]$chapter.sumStar -lt 10) { throw "World fixture injected chapter 1003 has insufficient stars: $($chapter.sumStar)." }
    if ($payload.primary.curMapId -ne 1003 -or $payload.primary.curNodeId -ne 10031) { throw "World fixture did not select its injected chapter 1003 / stage 10031." }
    [ordered]@{ chapterId = 1003; stageId = 10031; chapterStars = [int]$chapter.sumStar; claimableNormalBoxId = 10031; claimableStarBoxId = 20031 }
}

function Assert-WorldRestored {
    $restored = @(Invoke-WorldSql -Sql @"
SELECT COUNT(*)=1 AND $hashExpression=f.snapshot_hash
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_world_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ($restored.Count -ne 1 -or [int]$restored[0] -ne 1) { throw "World fixture exact restore hash assertion failed." }
}

function Assert-WorldReloginStable {
    $stable = @(Invoke-WorldSql -Sql @"
SELECT COUNT(*)=1 AND $reloginHashExpression=f.stable_snapshot_hash AND CHAR_LENGTH(r.mission)>0,
 REPLACE(TO_BASE64(r.guan_qia), CHAR(10), ''), REPLACE(TO_BASE64(f.backup_guan_qia), CHAR(10), ''),
 REPLACE(TO_BASE64(r.save_val), CHAR(10), ''), REPLACE(TO_BASE64(f.backup_save_val), CHAR(10), '')
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
JOIN unity_validation_world_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
WHERE r.id=$RoleId
"@ -ReturnOutput)
    if ($stable.Count -ne 1) { throw "World fixture post-login stable-state query was missing or ambiguous." }
    $parts = $stable[0] -split "`t", 5
    if ($parts.Count -ne 5 -or [int]$parts[0] -ne 1) { throw "World fixture post-login stable-state hash assertion failed." }
    $liveGuanQia = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[1]))
    $backupGuanQia = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[2]))
    if ((Get-WorldReloginCanonicalGuanQia $liveGuanQia) -cne (Get-WorldReloginCanonicalGuanQia $backupGuanQia)) {
        throw "World fixture post-login canonical guan_qia assertion failed."
    }
    $liveSaveVal = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[3]))
    $backupSaveVal = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[4]))
    if ((Get-WorldReloginCanonicalSaveVal $liveSaveVal) -cne (Get-WorldReloginCanonicalSaveVal $backupSaveVal)) {
        throw "World fixture post-login canonical save_val assertion failed."
    }
}

switch ($Action) {
    "SeedTestProgress" {
        Assert-RoleClientsStopped
        Invoke-WorldSql -Sql @"
CREATE TABLE IF NOT EXISTS codex_local_test_account_backup (
 role_id INT UNSIGNED NOT NULL PRIMARY KEY, guan_qia MEDIUMTEXT NULL, pet_equip MEDIUMTEXT NULL,
 level INT NULL, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT IGNORE INTO codex_local_test_account_backup(role_id,guan_qia,pet_equip,level)
SELECT id,guan_qia,pet_equip,level FROM role_info WHERE id=$RoleId;
"@
        $live = Get-WorldLiveGuanQiaHex
        $seed = Set-WorldTestProgress -GuanQiaHex $live
        Invoke-WorldSql -Sql "UPDATE role_info SET guan_qia='$($seed.hex)',level=99 WHERE id=$RoleId"
        $roundTrip = Get-WorldFixturePayload -GuanQiaHex (Get-WorldLiveGuanQiaHex)
        foreach ($stageId in $seed.stageIds) {
            $found = @($roundTrip.primary.maps | Where-Object { $_.nodeStars.Contains([uint32]$stageId) })
            if ($found.Count -ne 1 -or [byte]$found[0].nodeStars[[uint32]$stageId] -ne 3) {
                $matches = @($roundTrip.primary.maps | ForEach-Object {
                    $value = if ($_.nodeStars.Contains([uint32]$stageId)) { $_.nodeStars[[uint32]$stageId] } else { "missing" }
                    "$($_.mapId):$value"
                })
                throw "World test progress stage $stageId was not persisted exactly once with three stars; maps=$($matches -join ',')."
            }
        }
        Write-Evidence ([ordered]@{ action=$Action; userId=$UserId; roleId=$RoleId; level=99; unlockedStageIds=$seed.stageIds; backupTable="codex_local_test_account_backup"; createdUtc=[DateTime]::UtcNow.ToString("O") })
        Write-Host "World test progress seeded: roleId=$RoleId stages=$($seed.stageIds -join ',') level=99"
    }
    "Setup" {
        Assert-ClientsStopped
        Invoke-WorldSql -Sql $createTableSql
        $stableColumn = @(Invoke-WorldSql -Sql "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME='unity_validation_world_fixture' AND COLUMN_NAME='stable_snapshot_hash'" -ReturnOutput)
        if ([int]$stableColumn[-1] -eq 0) {
            Invoke-WorldSql -Sql "ALTER TABLE unity_validation_world_fixture ADD COLUMN stable_snapshot_hash CHAR(64) NULL"
        }
        $existing = @(Invoke-WorldSql -Sql "SELECT COUNT(*) FROM unity_validation_world_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) { throw "A World fixture row already exists for userId=$UserId. Restore/Cleanup it before a new snapshot." }
        Invoke-WorldSql -Sql @"
INSERT INTO unity_validation_world_fixture(
 user_id,role_id,enabled,applied,backup_guan_qia,backup_package,backup_save_data,backup_save_val,
 backup_user_spirit,backup_mission,backup_role_money,backup_exp,backup_level,backup_user_money,backup_bd_money,snapshot_hash,stable_snapshot_hash
)
SELECT $UserId,$RoleId,1,1,r.guan_qia,r.package,r.save_data,r.save_val,r.user_spirit,r.mission,
 r.money,r.exp,r.level,u.money,u.bd_money,$hashExpression,$reloginHashExpression
FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId
WHERE r.id=$RoleId
"@
        $fixture = Get-WorldFixtureRow
        $preconditions = Get-WorldFixturePreconditions -GuanQiaHex $fixture.guanQiaHex
        $injection = Set-WorldFixtureClaimableBoxes -GuanQiaHex $fixture.guanQiaHex
        Invoke-WorldSql -Sql "UPDATE role_info SET guan_qia='$($injection.hex)' WHERE id=$RoleId"
        $injected = Assert-WorldFixtureInjection -GuanQiaHex (Get-WorldLiveGuanQiaHex)
        $spirit = @(Invoke-WorldSql -Sql "SELECT CHAR_LENGTH(backup_user_spirit),backup_role_money,backup_user_money,backup_bd_money,backup_exp,backup_level FROM unity_validation_world_fixture WHERE user_id=$UserId" -ReturnOutput)[0] -split "`t"
        if ([int]$spirit[0] -le 0) { throw "World fixture requires persisted authoritative spirit data." }
        Write-Evidence ([ordered]@{
            module = "World"; phase = "after-injection"; userId = $UserId; roleId = $RoleId
            snapshotHash = $fixture.snapshotHash; stableSnapshotHash = $fixture.stableSnapshotHash; preconditions = $preconditions
            injection = $injection; injectedState = $injected
            userSpiritLength = [int]$spirit[0]; roleMoney = [long]$spirit[1]; userMoney = [long]$spirit[2]; boundMoney = [long]$spirit[3]
            roleExperience = [long]$spirit[4]; roleLevel = [int]$spirit[5]
            setupAssertSql = "passed"; restoreAssertSql = "pending"; cleanupAssertSql = "pending"; createdUtc = [DateTime]::UtcNow.ToString("O")
        })
        Write-Host "World fixture snapshot, claimable normal/star boxes and /320 preconditions passed: userId=$UserId roleId=$RoleId hash=$($fixture.snapshotHash)"
    }
    "AssertSetup" {
        [void](Get-WorldFixtureRow)
        $injected = Assert-WorldFixtureInjection -GuanQiaHex (Get-WorldLiveGuanQiaHex) -AllowClaimed
        Write-Host "World fixture live-state assertion passed: userId=$UserId roleId=$RoleId normalBox=$($injected.claimableNormalBoxId) starBox=$($injected.claimableStarBoxId)"
    }
    "Restore" {
        Assert-ClientsStopped
        Invoke-WorldSql -Sql @"
UPDATE role_info r JOIN unity_validation_world_fixture f ON f.user_id=$UserId AND f.role_id=r.id
SET r.guan_qia=f.backup_guan_qia,r.package=f.backup_package,r.save_data=f.backup_save_data,
 r.save_val=f.backup_save_val,r.user_spirit=f.backup_user_spirit,r.mission=f.backup_mission,
 r.money=f.backup_role_money,r.exp=f.backup_exp,r.level=f.backup_level
WHERE r.id=$RoleId;
UPDATE user_info1 u JOIN unity_validation_world_fixture f ON f.user_id=u.id AND f.role_id=$RoleId
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money
WHERE u.id=$UserId AND u.role0=$RoleId
"@
        Assert-WorldRestored
        Write-Host "World fixture restored while retaining snapshot: userId=$UserId roleId=$RoleId"
    }
    "AssertRestored" { Assert-WorldRestored; Write-Host "World fixture exact restore assertion passed: userId=$UserId roleId=$RoleId" }
    "Cleanup" {
        Assert-ClientsStopped
        & $PSCommandPath -Action Restore -UserId $UserId -RoleId $RoleId -EvidencePath $evidence
        if ($LASTEXITCODE -ne 0) { throw "World fixture retained restore failed during cleanup." }
        Invoke-WorldSql -Sql "DELETE FROM unity_validation_world_fixture WHERE user_id=$UserId"
        $remaining = @(Invoke-WorldSql -Sql "SELECT COUNT(*) FROM unity_validation_world_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$remaining[-1] -ne 0) { throw "World fixture cleanup residual row assertion failed." }
        $payload = Read-Evidence; $payload.restoreAssertSql = "passed"; $payload.cleanupAssertSql = "passed"
        $payload | Add-Member -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence $payload
        Write-Host "World fixture cleanup and residual-zero assertion passed: userId=$UserId"
    }
    "AssertCleanup" {
        $remaining = @(Invoke-WorldSql -Sql "SELECT COUNT(*) FROM unity_validation_world_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$remaining[-1] -ne 0) { throw "World fixture residual row exists for userId=$UserId." }
        $payload = Read-Evidence
        $current = @(Invoke-WorldSql -Sql "SELECT $hashExpression FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId" -ReturnOutput)
        if ($current.Count -ne 1 -or [string]$current[0] -ne [string]$payload.snapshotHash) { throw "World fixture post-cleanup hash assertion failed." }
        Write-Host "World fixture cleanup and exact hash assertion passed: userId=$UserId"
    }
    "AssertReloginHash" {
        Assert-WorldReloginStable
        $payload = Read-Evidence
        $payload | Add-Member -NotePropertyName residualCount -NotePropertyValue 0 -Force
        $payload | Add-Member -NotePropertyName postLoginHashVerified -NotePropertyValue $true -Force
        $payload | Add-Member -NotePropertyName postLoginVerifiedUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")) -Force
        Write-Evidence $payload
        Write-Host "World fixture post-login stable-state hash assertion passed (mission login normalization allowed): userId=$UserId roleId=$RoleId"
    }
}
