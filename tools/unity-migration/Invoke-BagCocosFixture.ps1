[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [uint32]$UserId = 1,
    [uint32]$RoleId = 1000001,
    [string]$EvidencePath = ".local/ui-fidelity/Bag/fixture/bag-cocos-g1-fixture-snapshot.json",
    [ValidateSet("Full", "FocusedBoxes")][string]$Profile = "FocusedBoxes"
)

# Contract id: reversible-bag-fixed-account

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$roleBackup = "codex_bag_role_backup"
$userBackup = "codex_bag_user_backup"
$packageSlots = 500

if ($UserId -ne 1 -or $RoleId -ne 1000001) {
    throw "Bag current Cocos G1 fixture identity must remain 1/1000001."
}
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

function Invoke-BagSql([string]$Sql) {
    $arguments = @("--protocol=tcp", "--ssl-mode=DISABLED", "--host=127.0.0.1", "--port=3306",
        "--user=root", "--password=123456", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql")
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Bag fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe, ProjectX.exe and Unity.exe before Bag fixture $Action." }
}

function Get-UserTable {
    $tables = @(Invoke-BagSql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @($tables | Where-Object {
        $_ -match '^user_info\d*$' -and @(Invoke-BagSql "SELECT id FROM ``$_`` WHERE id=$UserId AND role0=$RoleId").Count -eq 1
    })
    if ($matches.Count -ne 1) { throw "Bag userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    [string]$matches[0]
}

function Get-RowHash([string]$Table, [string]$Where) {
    $columns = @(Invoke-BagSql "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME='$Table' ORDER BY ORDINAL_POSITION")
    if ($columns.Count -eq 0) { throw "Bag hash table is missing: $Table" }
    $parts = @($columns | ForEach-Object { "COALESCE(HEX(``$_``),'NULL')" }) -join ','
    $rows = @(Invoke-BagSql "SELECT SHA2(CONCAT_WS('|',$parts),256) FROM ``$Table`` WHERE $Where")
    if ($rows.Count -ne 1) { throw "Bag hash expected one row from $Table where $Where." }
    [string]$rows[0]
}

function Convert-BytesToHex([byte[]]$Bytes) { -join ($Bytes | ForEach-Object { $_.ToString("x2") }) }
function Compress-BagBytes([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $zlib.Write($Bytes, 0, $Bytes.Length) } finally { $zlib.Dispose() }
        Convert-BytesToHex $output.ToArray()
    }
    finally { $output.Dispose() }
}
function Expand-BagHex([string]$Hex) {
    $input = [IO.MemoryStream]::new([Convert]::FromHexString($Hex)); $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
        try { $zlib.CopyTo($output) } finally { $zlib.Dispose() }
        $output.ToArray()
    }
    finally { $input.Dispose(); $output.Dispose() }
}
function Add-UInt16([Collections.Generic.List[byte]]$Bytes, [int]$Value) {
    $Bytes.Add([byte]($Value -band 0xff)); $Bytes.Add([byte](($Value -shr 8) -band 0xff))
}
function Read-UInt16([byte[]]$Bytes, [ref]$Position) {
    if ($Position.Value + 2 -gt $Bytes.Length) { throw "Bag package ended while reading UInt16." }
    $value = [int]$Bytes[$Position.Value] -bor ([int]$Bytes[$Position.Value + 1] -shl 8)
    $Position.Value += 2
    $value
}

function New-BagPackage([string]$FixtureProfile) {
    # Two independent 500 slots prove the Cocos aggregate-by-itemId behavior.
    # The remaining entries cover no-action, jump, direct-use, choice and overflow states.
    # Preserve the accepted 2026-07-27 Cocos visual data totals so those
    # screenshots remain comparable. Item 500 is split across two authoritative
    # slots while retaining the old displayed total 20, adding aggregation proof
    # without invalidating the visible baseline.
    $items = if ($FixtureProfile -eq "FocusedBoxes") { @(
        @(512, 2), @(513, 2), @(514, 2)
    ) } else { @(
        @(614, 1), @(852, 1), @(853, 1), @(855, 1), @(401, 20),
        @(500, 10), @(500, 10),
        @(512, 2), @(513, 2), @(514, 2),
        @(1112, 2), @(1111, 3), @(1114, 3),
        @(610, 1), @(611, 1), @(612, 1), @(613, 1),
        @(851, 1), @(854, 1), @(1000, 1), @(1001, 1),
        @(3201, 1)
    ) }
    $bytes = [Collections.Generic.List[byte]]::new()
    foreach ($item in $items) { Add-UInt16 $bytes $item[0]; Add-UInt16 $bytes $item[1] }
    for ($slot = $items.Count; $slot -lt $packageSlots; $slot++) { Add-UInt16 $bytes 0 }
    Compress-BagBytes $bytes.ToArray()
}

function Get-BagPackageCounts([string]$Hex) {
    $bytes = Expand-BagHex $Hex; $position = 0; $counts = @{}
    for ($slot = 0; $slot -lt $packageSlots; $slot++) {
        $itemId = Read-UInt16 $bytes ([ref]$position)
        if ($itemId -eq 0) { continue }
        $quantity = Read-UInt16 $bytes ([ref]$position)
        $counts[$itemId] = ($counts[$itemId] ?? 0) + $quantity
    }
    $counts
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}
function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "Bag fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}
function Assert-BagFixturePackage([string]$FixtureProfile) {
    $rows = @(Invoke-BagSql "SELECT package FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "Bag role package is missing." }
    $counts = Get-BagPackageCounts ([string]$rows[0])
    $expected = if ($FixtureProfile -eq "FocusedBoxes") { @{512=2;513=2;514=2} } else { @{500=20;1111=3;1114=3;3201=1;401=20;610=1;1000=1;512=2;513=2;514=2} }
    foreach ($pair in $expected.GetEnumerator()) {
        if ([int]$counts[[int]$pair.Key] -ne [int]$pair.Value) { throw "Bag fixture item $($pair.Key) count mismatch." }
    }
}

if ($Action -in @("Setup", "Restore", "Cleanup")) { Assert-ClientsStopped }
switch ($Action) {
    "Setup" {
        $userTable = Get-UserTable
        $roleHash = Get-RowHash "role_info" "id=$RoleId"
        $userHash = Get-RowHash $userTable "id=$UserId AND role0=$RoleId"
        Invoke-BagSql "DROP TABLE IF EXISTS ``$roleBackup``; CREATE TABLE ``$roleBackup`` LIKE role_info; INSERT INTO ``$roleBackup`` SELECT * FROM role_info WHERE id=$RoleId; DROP TABLE IF EXISTS ``$userBackup``; CREATE TABLE ``$userBackup`` LIKE ``$userTable``; INSERT INTO ``$userBackup`` SELECT * FROM ``$userTable`` WHERE id=$UserId AND role0=$RoleId" | Out-Null
        $package = New-BagPackage $Profile
        Invoke-BagSql "UPDATE role_info SET package='$package' WHERE id=$RoleId" | Out-Null
        Assert-BagFixturePackage $Profile
        Write-Evidence ([ordered]@{action="Setup"; profile=$Profile; userId=$UserId; roleId=$RoleId; userTable=$userTable; snapshotRoleHash=$roleHash; snapshotUserHash=$userHash; fixtureRoleHash=(Get-RowHash "role_info" "id=$RoleId"); aggregateItem500=if($Profile -eq "Full"){20}else{0}; createdUtc=[DateTime]::UtcNow.ToString("O")})
    }
    "AssertSetup" {
        $snapshot = Read-Evidence
        if (@(Invoke-BagSql "SELECT COUNT(*) FROM ``$roleBackup`` WHERE id=$RoleId")[0] -ne "1") { throw "Bag role backup is missing." }
        if (@(Invoke-BagSql "SELECT COUNT(*) FROM ``$userBackup`` WHERE id=$UserId")[0] -ne "1") { throw "Bag user backup is missing." }
        Assert-BagFixturePackage ([string]$snapshot.profile)
        if ((Get-RowHash $roleBackup "id=$RoleId") -ne [string]$snapshot.snapshotRoleHash) { throw "Bag immutable role backup hash changed." }
        if ((Get-RowHash $userBackup "id=$UserId") -ne [string]$snapshot.snapshotUserHash) { throw "Bag immutable user backup hash changed." }
    }
    "Restore" {
        $snapshot = Read-Evidence; $userTable = [string]$snapshot.userTable
        Invoke-BagSql "DELETE FROM role_info WHERE id=$RoleId; INSERT INTO role_info SELECT * FROM ``$roleBackup`` WHERE id=$RoleId; DELETE FROM ``$userTable`` WHERE id=$UserId; INSERT INTO ``$userTable`` SELECT * FROM ``$userBackup`` WHERE id=$UserId" | Out-Null
    }
    "AssertRestored" {
        $snapshot = Read-Evidence
        $roleHash = Get-RowHash "role_info" "id=$RoleId"; $userHash = Get-RowHash ([string]$snapshot.userTable) "id=$UserId AND role0=$RoleId"
        if ($roleHash -ne [string]$snapshot.snapshotRoleHash -or $userHash -ne [string]$snapshot.snapshotUserHash) { throw "Bag restored row hash mismatch." }
        $snapshot | Add-Member -Force restoredRoleHash $roleHash; $snapshot | Add-Member -Force restoredUserHash $userHash; $snapshot | Add-Member -Force restored $true
        Write-Evidence $snapshot
    }
    "Cleanup" { Invoke-BagSql "DROP TABLE IF EXISTS ``$roleBackup``; DROP TABLE IF EXISTS ``$userBackup``" | Out-Null }
    "AssertCleanup" {
        $count = @(Invoke-BagSql "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME IN ('$roleBackup','$userBackup')")[0]
        if ([int]$count -ne 0) { throw "Bag fixture backup tables remain after cleanup." }
    }
    "AssertReloginHash" {
        $snapshot = Read-Evidence
        if ((Get-RowHash "role_info" "id=$RoleId") -ne [string]$snapshot.snapshotRoleHash) { throw "Bag post-login role hash mismatch." }
        if ((Get-RowHash ([string]$snapshot.userTable) "id=$UserId AND role0=$RoleId") -ne [string]$snapshot.snapshotUserHash) { throw "Bag post-login user hash mismatch." }
        $snapshot | Add-Member -Force residualCount 0; $snapshot | Add-Member -Force postLoginHashVerified $true
        Write-Evidence $snapshot
    }
}
