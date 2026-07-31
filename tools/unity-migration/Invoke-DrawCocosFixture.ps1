[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup","AssertSetup","Restore","AssertRestored","Cleanup","AssertCleanup")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/Draw/unity/g3/draw-fixed-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$targetHeroId = 64
$retainedHeroId = 57
$heroExpItemId = 834
$isolationUserId = 705213
$isolationRoleId = 1000006
$packageSlots = 500

if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-DrawSql {
    param([Parameter(Mandatory = $true)][string]$Sql, [switch]$ReturnOutput)
    $arguments = @("--protocol=tcp","--host=127.0.0.1","--port=3306","--user=root","--password=123456",
        "--default-character-set=utf8mb4","--database=fxl_game_local","--batch","--raw",
        "--skip-column-names","--execute=$Sql")
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Draw fixture SQL failed: $($output -join [Environment]::NewLine)" }
    if ($ReturnOutput) { return @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" }) }
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai,ProjectX,Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before $Action so the Draw snapshot cannot race a save." }
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 10) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Write-DrawConfigWithRetry([string]$Content) {
    $lastError = $null
    for ($attempt = 1; $attempt -le 20; $attempt++) {
        try {
            [IO.File]::WriteAllText($drawConfigPath, $Content, [Text.UTF8Encoding]::new($false))
            return
        }
        catch [IO.IOException] {
            $lastError = $_
            Start-Sleep -Milliseconds 250
        }
    }
    throw "Draw config remained locked after 5 seconds: $($lastError.Exception.Message)"
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "Draw fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Convert-BytesToHex([byte[]]$Bytes) { -join ($Bytes | ForEach-Object { $_.ToString("x2") }) }
function Compress-DrawBytes([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $zlib.Write($Bytes, 0, $Bytes.Length) } finally { $zlib.Dispose() }
        Convert-BytesToHex $output.ToArray()
    } finally { $output.Dispose() }
}
function Expand-DrawHex([string]$Hex) {
    if ([string]::IsNullOrWhiteSpace($Hex)) { throw "Draw compressed payload is empty." }
    $input = [IO.MemoryStream]::new([Convert]::FromHexString($Hex))
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
        try { $zlib.CopyTo($output) } finally { $zlib.Dispose() }
        $output.ToArray()
    } finally { $input.Dispose(); $output.Dispose() }
}
function Add-UInt16([Collections.Generic.List[byte]]$Bytes, [int]$Value) {
    $Bytes.Add([byte]($Value -band 0xff)); $Bytes.Add([byte](($Value -shr 8) -band 0xff))
}
function Add-UInt32([Collections.Generic.List[byte]]$Bytes, [uint32]$Value) {
    foreach ($shift in 0,8,16,24) { $Bytes.Add([byte](($Value -shr $shift) -band 0xff)) }
}
function Read-UInt16([byte[]]$Bytes, [ref]$Pos) {
    if ($Pos.Value + 2 -gt $Bytes.Length) { throw "Draw fixture payload ended while reading UInt16." }
    $value = [int]$Bytes[$Pos.Value] -bor ([int]$Bytes[$Pos.Value + 1] -shl 8); $Pos.Value += 2; $value
}
function Read-UInt32([byte[]]$Bytes, [ref]$Pos) {
    if ($Pos.Value + 4 -gt $Bytes.Length) { throw "Draw fixture payload ended while reading UInt32." }
    $value = [uint32]([int64]$Bytes[$Pos.Value] -bor ([int64]$Bytes[$Pos.Value + 1] -shl 8) -bor ([int64]$Bytes[$Pos.Value + 2] -shl 16) -bor ([int64]$Bytes[$Pos.Value + 3] -shl 24)); $Pos.Value += 4; $value
}

function New-DrawPackage {
    $items = @{ 834 = 10; 1000 = 20; 1001 = 10; 1002 = 200 }
    $bytes = [Collections.Generic.List[byte]]::new()
    $slot = 0
    foreach ($pair in @($items.GetEnumerator() | Sort-Object Key)) {
        # Must match CUser::GetPackage -> WriteItemBuf: uint16 tmplId followed
        # by SItemInstance::num (uint16). A one-byte fixture quantity shifts
        # every following slot and is not a real server-readable package.
        Add-UInt16 $bytes ([int]$pair.Key); Add-UInt16 $bytes ([int]$pair.Value); $slot++
    }
    while ($slot -lt $packageSlots) { Add-UInt16 $bytes 0; $slot++ }
    Compress-DrawBytes $bytes.ToArray()
}
function Get-DrawPackageCounts([string]$Hex) {
    $bytes = Expand-DrawHex $Hex; $pos = 0; $counts = @{}
    for ($slot = 0; $slot -lt $packageSlots; $slot++) {
        $itemId = Read-UInt16 $bytes ([ref]$pos)
        if ($itemId -eq 0) { continue }
        $quantity = Read-UInt16 $bytes ([ref]$pos)
        $counts[$itemId] = ($counts[$itemId] ?? 0) + $quantity
    }
    $counts
}
function New-DrawPetBlob {
    $bytes = [Collections.Generic.List[byte]]::new()
    $bytes.Add(1); $bytes.Add(1) # count, SPet::extNum
    Add-UInt16 $bytes $retainedHeroId; Add-UInt16 $bytes 1; Add-UInt32 $bytes 0
    $bytes.Add(1); $bytes.Add(0) # star, break
    $name = [Text.Encoding]::UTF8.GetBytes("苏全忠")
    $bytes.Add([byte]$name.Length); $bytes.AddRange($name)
    $bytes.Add(0); $bytes.Add(0) # cultivation level, cultivation entry count
    Compress-DrawBytes $bytes.ToArray()
}
function Get-DrawPetIds([string]$Hex) {
    $bytes = Expand-DrawHex $Hex; if ($bytes.Length -lt 2) { throw "Draw pet payload is incomplete." }
    $count = [int]$bytes[0]; $ext = [int]$bytes[1]; $pos = 2; $ids = [Collections.Generic.List[int]]::new()
    for ($index = 0; $index -lt $count; $index++) {
        $id = Read-UInt16 $bytes ([ref]$pos); $ids.Add($id)
        if ($id -eq 0) { continue }
        [void](Read-UInt16 $bytes ([ref]$pos)); [void](Read-UInt32 $bytes ([ref]$pos))
        if ($pos + 3 -gt $bytes.Length) { throw "Draw pet payload is incomplete after pet $id." }
        $pos += 2; $nameLength = [int]$bytes[$pos]; $pos++; $pos += $nameLength
        if ($pos -gt $bytes.Length) { throw "Draw pet name exceeds payload." }
        if ($ext -gt 0) {
            $pos++
            if ($pos -gt $bytes.Length) { throw "Draw cultivation payload is incomplete." }
            $entryCount = [int]$bytes[$pos - 1]; $pos += 3 * $entryCount
            if ($pos -gt $bytes.Length) { throw "Draw cultivation entries exceed payload." }
        }
    }
    @($ids)
}
function New-DrawPoolBlob {
    $bytes = [Collections.Generic.List[byte]]::new(); $bytes.Add(3)
    foreach ($row in @(@(1,3), @(2,1), @(3,0))) {
        $bytes.Add([byte]$row[0]); Add-UInt32 $bytes 0; Add-UInt32 $bytes 0; $bytes.Add([byte]$row[1])
    }
    Compress-DrawBytes $bytes.ToArray()
}
function Get-DrawPoolState([string]$Hex) {
    $bytes = Expand-DrawHex $Hex; $pos = 0
    if ($bytes.Length -lt 1) { throw "Draw pool payload is incomplete." }
    $count = [int]$bytes[$pos]; $pos++; $result = @{}
    for ($index = 0; $index -lt $count; $index++) {
        if ($pos -ge $bytes.Length) { throw "Draw pool payload ended before type." }
        $type = [int]$bytes[$pos]; $pos++
        $all = Read-UInt32 $bytes ([ref]$pos); $cd = Read-UInt32 $bytes ([ref]$pos)
        if ($pos -ge $bytes.Length) { throw "Draw pool payload ended before free count." }
        $free = [int]$bytes[$pos]; $pos++; $result[$type] = @{ all = $all; cd = $cd; free = $free }
    }
    $result
}

$targetPackage = New-DrawPackage
$targetPet = New-DrawPetBlob
$targetPool = New-DrawPoolBlob
$drawConfigPath = Join-Path $root "server/config/json/draw_config.json"

function Enable-DeterministicDrawDuplicateFixture {
    $original = [IO.File]::ReadAllText($drawConfigPath, [Text.UTF8Encoding]::new($false))
    $originalHash = (Get-FileHash -LiteralPath $drawConfigPath -Algorithm SHA256).Hash
    $config = $original | ConvertFrom-Json
    foreach ($row in @($config | Where-Object { [int]$_.type -eq 3 })) {
        # High-pool type 3 must repeat the real target after its deterministic
        # free first draw. Type 4 is intentionally retained for the guarantee slots.
        $row.award = @(60002, $targetHeroId, 1)
        $row.quanzhong = 1
    }
    $fixtureText = $config | ConvertTo-Json -Depth 8 -Compress
    Write-DrawConfigWithRetry $fixtureText
    [ordered]@{
        path = $drawConfigPath
        originalBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($original))
        originalHash = $originalHash
        fixtureHash = (Get-FileHash -LiteralPath $drawConfigPath -Algorithm SHA256).Hash
    }
}

function Restore-DeterministicDrawDuplicateFixture($Payload) {
    if ($null -eq $Payload.drawConfigFixture) { throw "Draw config fixture evidence is missing." }
    $bytes = [Convert]::FromBase64String([string]$Payload.drawConfigFixture.originalBase64)
    Write-DrawConfigWithRetry ([Text.Encoding]::UTF8.GetString($bytes))
    $restoredHash = (Get-FileHash -LiteralPath $drawConfigPath -Algorithm SHA256).Hash
    if ($restoredHash -ne [string]$Payload.drawConfigFixture.originalHash) {
        throw "Draw config fixture restore hash assertion failed."
    }
}
$hashExpression = @"
SHA2(CONCAT_WS('|',COALESCE(r.level,''),COALESCE(r.package,''),COALESCE(r.pet,''),COALESCE(r.chou_ka,''),
COALESCE(r.zhenfa,''),COALESCE(r.save_data,''),COALESCE(r.money,''),COALESCE(r.zhanDouLi,''),
COALESCE(r.petZhanDouLi,''),COALESCE(u.money,''),COALESCE(u.bd_money,'')),256)
"@ -replace "\r?\n", ""
$createTableSql = @"
CREATE TABLE IF NOT EXISTS unity_validation_draw_fixture (
 user_id INT UNSIGNED NOT NULL, role_id INT UNSIGNED NOT NULL, applied TINYINT UNSIGNED NOT NULL DEFAULT 0,
 snapshot_hash CHAR(64) NOT NULL, backup_level MEDIUMTEXT NULL, backup_package MEDIUMTEXT NULL,
 backup_pet MEDIUMTEXT NULL, backup_chou_ka MEDIUMTEXT NULL, backup_zhenfa MEDIUMTEXT NULL,
 backup_save_data MEDIUMTEXT NULL, backup_role_money MEDIUMTEXT NULL, backup_role_power MEDIUMTEXT NULL,
 backup_pet_power MEDIUMTEXT NULL, backup_user_money MEDIUMTEXT NULL, backup_bd_money MEDIUMTEXT NULL,
 backup_item_type INT NULL, backup_item_sub_value MEDIUMTEXT NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
"@
function Restore-DrawSnapshot {
    Invoke-DrawSql -Sql @"
UPDATE role_info r JOIN unity_validation_draw_fixture f ON f.role_id=r.id AND f.user_id=$UserId
SET r.level=f.backup_level,r.package=f.backup_package,r.pet=f.backup_pet,r.chou_ka=f.backup_chou_ka,
 r.zhenfa=f.backup_zhenfa,r.save_data=f.backup_save_data,r.money=f.backup_role_money,
 r.zhanDouLi=f.backup_role_power,r.petZhanDouLi=f.backup_pet_power WHERE r.id=$RoleId;
UPDATE user_info1 u JOIN unity_validation_draw_fixture f ON f.user_id=u.id
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money WHERE u.id=$UserId AND u.role0=$RoleId;
UPDATE item i JOIN unity_validation_draw_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId
SET i.type=f.backup_item_type,i.sub_value=f.backup_item_sub_value WHERE i.id=$heroExpItemId;
"@
    $expected = @(Invoke-DrawSql -Sql "SELECT snapshot_hash FROM unity_validation_draw_fixture WHERE user_id=$UserId AND role_id=$RoleId" -ReturnOutput)
    $restored = $false
    for ($attempt = 1; $attempt -le 5; $attempt++) {
        $current = @(Invoke-DrawSql -Sql @"
SELECT $hashExpression FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ($expected.Count -gt 0 -and [string]$current[-1] -eq [string]$expected[-1]) { $restored = $true; break }
        Start-Sleep -Milliseconds 100
    }
    if (-not $restored) {
        throw "Draw retained snapshot restore assertion failed."
    }
}
function Ensure-DrawFixtureColumns {
    $columns = @(Invoke-DrawSql -Sql "SELECT column_name FROM information_schema.columns WHERE table_schema='fxl_game_local' AND table_name='unity_validation_draw_fixture' AND column_name IN ('backup_item_type','backup_item_sub_value')" -ReturnOutput)
    if ($columns -notcontains 'backup_item_type') { Invoke-DrawSql -Sql "ALTER TABLE unity_validation_draw_fixture ADD COLUMN backup_item_type INT NULL" }
    if ($columns -notcontains 'backup_item_sub_value') { Invoke-DrawSql -Sql "ALTER TABLE unity_validation_draw_fixture ADD COLUMN backup_item_sub_value MEDIUMTEXT NULL" }
}
function Assert-DrawIsolationAccount {
    $row = @(Invoke-DrawSql -Sql @"
SELECT u.role0,r.pet FROM user_info1 u JOIN role_info r ON r.id=u.role0 WHERE u.id=$isolationUserId
"@ -ReturnOutput)
    if ($row.Count -eq 0) { throw "Draw isolation account $isolationUserId is missing." }
    $values = $row[-1] -split "`t",2
    if ([uint32]$values[0] -ne $isolationRoleId) { throw "Draw isolation role mismatch: expected=$isolationRoleId actual=$($values[0])." }
    if ((Get-DrawPetIds $values[1]) -contains $targetHeroId) {
        throw "Draw isolation account already contains target hero $targetHeroId."
    }
}
function Assert-DrawFixtureState([switch]$RequireInitial) {
    $row = @(Invoke-DrawSql -Sql @"
SELECT r.package,r.pet,r.chou_ka,CAST(r.level AS UNSIGNED),f.applied
FROM unity_validation_draw_fixture f JOIN role_info r ON r.id=f.role_id
WHERE f.user_id=$UserId AND f.role_id=$RoleId
"@ -ReturnOutput)
    if ($row.Count -eq 0) { throw "Draw fixture row is missing." }
    $values = $row[-1] -split "`t",5
    $items = Get-DrawPackageCounts $values[0]; $pets = Get-DrawPetIds $values[1]; $pools = Get-DrawPoolState $values[2]
    foreach ($id in 834,1000,1001,1002) { if (($items[$id] ?? 0) -le 0) { throw "Draw fixture lacks item $id." } }
    if ([int]$values[3] -lt 60 -or [int]$values[4] -ne 1) { throw "Draw fixture level/applied assertion failed." }
    $itemTemplate = @(Invoke-DrawSql -Sql "SELECT type,sub_value FROM item WHERE id=$heroExpItemId" -ReturnOutput)
    if ($itemTemplate.Count -eq 0 -or [string]$itemTemplate[-1] -ne "3`t60006,200") {
        throw "Draw fixture hero experience material template assertion failed."
    }
    if (-not $pools.ContainsKey(2)) { throw "Draw fixture has no high-pool record." }
    Assert-DrawIsolationAccount
    if ($RequireInitial) {
        if ($pets -contains $targetHeroId -or $pets -notcontains $retainedHeroId -or
            $pools[2].all -ne 0 -or $pools[2].free -ne 1) {
            throw "Draw initial fixture is not deterministic: hero64=$($pets -contains $targetHeroId), high=$($pools[2].all)/$($pools[2].free)."
        }
    }
}

switch ($Action) {
    "Setup" {
        Assert-ClientsStopped; Invoke-DrawSql -Sql $createTableSql; Ensure-DrawFixtureColumns
        $existing = @(Invoke-DrawSql -Sql "SELECT COUNT(*) FROM unity_validation_draw_fixture WHERE user_id=$UserId" -ReturnOutput)
        if ([int]$existing[-1] -ne 0) { throw "A Draw fixture row already exists for userId=$UserId. Run Cleanup first." }
        Invoke-DrawSql -Sql @"
INSERT INTO unity_validation_draw_fixture(user_id,role_id,applied,snapshot_hash,backup_level,backup_package,backup_pet,
 backup_chou_ka,backup_zhenfa,backup_save_data,backup_role_money,backup_role_power,backup_pet_power,backup_user_money,backup_bd_money,
 backup_item_type,backup_item_sub_value)
SELECT $UserId,$RoleId,0,$hashExpression,r.level,r.package,r.pet,r.chou_ka,r.zhenfa,r.save_data,
 r.money,r.zhanDouLi,r.petZhanDouLi,u.money,u.bd_money,i.type,i.sub_value FROM role_info r
JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId JOIN item i ON i.id=$heroExpItemId WHERE r.id=$RoleId;
UPDATE role_info SET level='60',package='$targetPackage',pet='$targetPet',chou_ka='$targetPool',
 money='1000000',zhanDouLi='0',petZhanDouLi='0' WHERE id=$RoleId;
UPDATE user_info1 SET money='100000',bd_money='100000' WHERE id=$UserId AND role0=$RoleId;
UPDATE item SET type=3,sub_value='60006,200' WHERE id=$heroExpItemId;
UPDATE unity_validation_draw_fixture SET applied=1 WHERE user_id=$UserId AND role_id=$RoleId;
"@
        $drawConfigFixture = Enable-DeterministicDrawDuplicateFixture
        Assert-DrawFixtureState -RequireInitial
        $snapshot = @(Invoke-DrawSql -Sql "SELECT snapshot_hash,backup_item_type,backup_item_sub_value FROM unity_validation_draw_fixture WHERE user_id=$UserId AND role_id=$RoleId" -ReturnOutput)
        $snapshotValues = $snapshot[-1] -split "`t",3
        Write-Evidence ([ordered]@{ module="Draw"; phase="fixture-applied"; userId=$UserId; roleId=$RoleId; snapshotHash=$snapshotValues[0]
            itemTemplate=[ordered]@{ id=$heroExpItemId; type=[int]$snapshotValues[1]; subValue=[string]$snapshotValues[2] }
            drawConfigFixture=$drawConfigFixture
            isolation=[ordered]@{ userId=$isolationUserId; roleId=$isolationRoleId; targetHeroAbsent=$true }
            deterministic=[ordered]@{ targetHeroId=$targetHeroId; retainedHeroId=$retainedHeroId; highPoolAllCnt=0; highPoolFreeTimes=1; heroExpItemId=$heroExpItemId; heroExpItemCount=10; coupons=@{basic=20;high=10;friend=200}; formation="retain original legal formation" }
            setupAssert="passed"; restoreAssert="pending"; cleanupAssert="pending"; createdUtc=[DateTime]::UtcNow.ToString("O") })
        Write-Host "Draw deterministic fixture applied: userId=$UserId roleId=$RoleId targetHero=$targetHeroId"
    }
    "AssertSetup" { Assert-DrawFixtureState; Write-Host "Draw fixture state assertion passed." }
    "Restore" { Assert-ClientsStopped; $payload = Read-Evidence; Restore-DeterministicDrawDuplicateFixture $payload; Restore-DrawSnapshot; Write-Host "Draw fixture restored while retaining snapshot." }
    "AssertRestored" {
        $payload = Read-Evidence
        $current = @(Invoke-DrawSql -Sql @"
SELECT $hashExpression FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId
"@ -ReturnOutput)
        if ([string]$current[-1] -ne [string]$payload.snapshotHash) { throw "Draw restored hash assertion failed." }
        Write-Host "Draw retained snapshot hash assertion passed: $($payload.snapshotHash)"
    }
    "Cleanup" {
        Assert-ClientsStopped; Invoke-DrawSql -Sql $createTableSql; Ensure-DrawFixtureColumns
        $payload = Read-Evidence; Restore-DeterministicDrawDuplicateFixture $payload; Restore-DrawSnapshot
        Invoke-DrawSql -Sql "DELETE FROM unity_validation_draw_fixture WHERE user_id=$UserId AND role_id=$RoleId"
        $payload.phase="restored"; $payload.restoreAssert="passed"; $payload.cleanupAssert="passed"
        $payload | Add-Member -Force -NotePropertyName restoredUtc -NotePropertyValue ([DateTime]::UtcNow.ToString("O")); Write-Evidence $payload
        Write-Host "Draw exact snapshot restore and cleanup completed."
    }
    "AssertCleanup" {
        $payload = Read-Evidence
        $rows = @(Invoke-DrawSql -Sql "SELECT COUNT(*) FROM unity_validation_draw_fixture WHERE user_id=$UserId" -ReturnOutput)
        $current = @(Invoke-DrawSql -Sql @"
SELECT $hashExpression FROM role_info r JOIN user_info1 u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId
"@ -ReturnOutput)
        $itemTemplate = @(Invoke-DrawSql -Sql "SELECT type,sub_value FROM item WHERE id=$heroExpItemId" -ReturnOutput)
        $drawConfigHash = (Get-FileHash -LiteralPath $drawConfigPath -Algorithm SHA256).Hash
        $expectedItemTemplate = "$($payload.itemTemplate.type)`t$($payload.itemTemplate.subValue)"
        if ([int]$rows[-1] -ne 0 -or [string]$current[-1] -ne [string]$payload.snapshotHash -or
            $payload.cleanupAssert -ne "passed" -or $itemTemplate.Count -eq 0 -or [string]$itemTemplate[-1] -ne $expectedItemTemplate -or
            $drawConfigHash -ne [string]$payload.drawConfigFixture.originalHash) {
            throw "Draw cleanup residual assertion failed."
        }
        Write-Host "Draw cleanup assertion passed: fixture rows=0, residual hash and material template exact."
    }
}
