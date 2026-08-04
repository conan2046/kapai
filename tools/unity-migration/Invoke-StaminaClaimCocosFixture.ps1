[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash")]
    [string]$Action,
    [ValidateSet("Mixed", "Free", "Paid", "Claimed", "OverCap", "InsufficientPremium", "AllClaimed", "Isolation")]
    [string]$State = "Mixed",
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [string]$EvidencePath = ".local/ui-fidelity/StaminaClaim/cocos/g1-20260804/staminaclaim-fixture-snapshot.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }

$allowedIdentity = ($UserId -eq 7200057 -and $RoleId -eq 1000115) -or
    ($UserId -eq 705213 -and $RoleId -eq 1000006) -or
    ($UserId -eq 7200260 -and $RoleId -eq 1000119)
if (-not $allowedIdentity) { throw "StaminaClaim fixture identity is not frozen in STAMINA_CLAIM_CONTROLS.json." }

function Invoke-StaminaSql {
    param([Parameter(Mandatory = $true)][string]$Sql)
    $arguments = @(
        "--protocol=tcp", "--host=127.0.0.1", "--port=3306", "--user=root", "--password=123456",
        "--default-character-set=utf8mb4", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "StaminaClaim fixture SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Assert-ClientsStopped {
    $running = @(Get-Process kapai, ProjectX, Unity -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop workspace kapai.exe, ProjectX.exe and Unity.exe before StaminaClaim fixture $Action." }
}

function Get-UserTable {
    $tables = @(Invoke-StaminaSql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @(
        foreach ($tableName in $tables) {
            if ([string]$tableName -notmatch '^user_info\d*$') { throw "Unsafe user table name: $tableName" }
            $rows = @(Invoke-StaminaSql "SELECT role0 FROM ``$tableName`` WHERE id=$UserId AND role0=$RoleId")
            if ($rows.Count -eq 1) { [string]$tableName }
        }
    )
    if ($matches.Count -ne 1) { throw "StaminaClaim userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    $matches[0]
}

function Expand-Spirit([string]$Hex) {
    $input = [IO.MemoryStream]::new([Convert]::FromHexString($Hex)); $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($input, [IO.Compression.CompressionMode]::Decompress)
        try { $zlib.CopyTo($output) } finally { $zlib.Dispose() }
        $output.ToArray()
    }
    finally { $input.Dispose(); $output.Dispose() }
}

function Compress-Spirit([byte[]]$Raw) {
    $output = [IO.MemoryStream]::new()
    try {
        $zlib = [IO.Compression.ZLibStream]::new($output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $zlib.Write($Raw, 0, $Raw.Length) } finally { $zlib.Dispose() }
        [Convert]::ToHexString($output.ToArray())
    }
    finally { $output.Dispose() }
}

function New-SpiritHex([uint16]$Stamina, [byte[]]$States) {
    if ($States.Count -ne 3) { throw "StaminaClaim fixture requires exactly three states." }
    $raw = [byte[]]::new(13)
    [Array]::Copy([BitConverter]::GetBytes($Stamina), 0, $raw, 0, 2)
    # Keep the injected stamina stable across login. A zero timestamp makes the
    # server apply historical regeneration immediately and invalidates deltas.
    $lastSpiritTime = [uint32][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    [Array]::Copy([BitConverter]::GetBytes($lastSpiritTime), 0, $raw, 2, 4)
    $raw[6] = 3
    for ($i = 0; $i -lt 3; $i++) { $raw[7 + 2 * $i] = [byte]($i + 1); $raw[8 + 2 * $i] = $States[$i] }
    Compress-Spirit $raw
}

function Read-Spirit([string]$Hex) {
    $raw = Expand-Spirit $Hex
    if ($raw.Length -lt 13 -or $raw[6] -ne 3) { throw "StaminaClaim user_spirit payload is not the expected three-slot layout." }
    [ordered]@{
        stamina = [BitConverter]::ToUInt16($raw, 0)
        lastSpiritTime = [BitConverter]::ToUInt32($raw, 2)
        states = @([int]$raw[8], [int]$raw[10], [int]$raw[12])
    }
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "StaminaClaim fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Initialize-StaminaClaimValidationConfig {
    $source = Join-Path $root "server\config"
    $destination = Join-Path $root ".local\staminaclaim-server-validation"
    [IO.Directory]::CreateDirectory($destination) | Out-Null
    Copy-Item -LiteralPath (Join-Path $source "config") -Destination (Join-Path $destination "config") -Force
    foreach ($directory in @("dat", "json", "xml")) {
        Copy-Item -LiteralPath (Join-Path $source $directory) -Destination $destination -Recurse -Force
    }
    $staminaPath = Join-Path $destination "json\stamina.json"
    $stamina = '[{"id":1,"time":[0,1],"value":[60026,50],"cost":[60001,20]},{"id":2,"time":[0,2400],"value":[60026,50],"cost":[60001,20]},{"id":3,"time":[0,2400],"value":[60026,50],"cost":[60001,20]}]'
    [IO.File]::WriteAllText($staminaPath, $stamina + "`n", [Text.UTF8Encoding]::new($false))
    $configPath = Join-Path $destination "config"
    $configText = [IO.File]::ReadAllText($configPath, [Text.Encoding]::UTF8)
    foreach ($setting in @(@("local_test_tongbao", "0"), @("local_test_bd_tongbao", "0"))) {
        $pattern = "(?m)^" + [regex]::Escape($setting[0]) + "\s*=.*$"
        if ([regex]::IsMatch($configText, $pattern)) { $configText = [regex]::Replace($configText, $pattern, "$($setting[0])=$($setting[1])") }
        else { $configText = [regex]::Replace($configText, "(?m)^\[server\]\s*$", "[server]`r`n$($setting[0])=$($setting[1])", 1) }
    }
    [IO.File]::WriteAllText($configPath, $configText, [Text.UTF8Encoding]::new($false))
}

$definition = switch ($State) {
    "Mixed" { [ordered]@{ stamina=[uint16]40; states=[byte[]]@(0,0,0); userMoney=100; boundMoney=0; roleMoney=1000000; serverClock="slot1-past-slot2-slot3-open" } }
    "Free" { [ordered]@{ stamina=[uint16]40; states=[byte[]]@(0,0,0); userMoney=100; boundMoney=0; roleMoney=1000000; serverClock="canonical" } }
    "Paid" { [ordered]@{ stamina=[uint16]40; states=[byte[]]@(0,0,0); userMoney=100; boundMoney=0; roleMoney=1000000; serverClock="past-window" } }
    "Claimed" { [ordered]@{ stamina=[uint16]90; states=[byte[]]@(3,0,0); userMoney=100; boundMoney=0; roleMoney=1000000; serverClock="canonical" } }
    "OverCap" { [ordered]@{ stamina=[uint16]990; states=[byte[]]@(0,0,0); userMoney=100; boundMoney=0; roleMoney=1000000; serverClock="canonical" } }
    "InsufficientPremium" { [ordered]@{ stamina=[uint16]40; states=[byte[]]@(0,0,0); userMoney=0; boundMoney=0; roleMoney=1000000; serverClock="past-window" } }
    "AllClaimed" { [ordered]@{ stamina=[uint16]90; states=[byte[]]@(3,3,3); userMoney=80; boundMoney=0; roleMoney=1000000; serverClock="canonical" } }
    "Isolation" { [ordered]@{ stamina=[uint16]25; states=[byte[]]@(0,0,0); userMoney=77; boundMoney=0; roleMoney=900000; serverClock="canonical" } }
}

if ($UserId -eq 7200057 -and $RoleId -eq 1000115 -and $Action -eq "Setup") {
    Initialize-StaminaClaimValidationConfig
}

Assert-ClientsStopped
$userTable = Get-UserTable
$hashExpression = "LOWER(SHA2(CONCAT_WS('|',r.id,COALESCE(r.user_spirit,''),COALESCE(CAST(r.money AS CHAR),''),u.id,u.role0,COALESCE(CAST(u.money AS CHAR),''),COALESCE(CAST(u.bd_money AS CHAR),'')),256))"

Invoke-StaminaSql @"
CREATE TABLE IF NOT EXISTS unity_validation_staminaclaim_fixture (
 user_id INT UNSIGNED NOT NULL, role_id INT UNSIGNED NOT NULL, user_table VARCHAR(64) NOT NULL,
 applied TINYINT UNSIGNED NOT NULL DEFAULT 0, fixture_state VARCHAR(32) NOT NULL,
 backup_user_spirit MEDIUMTEXT NULL, backup_role_money BIGINT NULL,
 backup_user_money BIGINT NULL, backup_bd_money BIGINT NULL, snapshot_hash CHAR(64) NOT NULL,
 PRIMARY KEY(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"@ | Out-Null

switch ($Action) {
    "Setup" {
        $existing = @(Invoke-StaminaSql "SELECT applied FROM unity_validation_staminaclaim_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($existing.Count -eq 0) {
            Invoke-StaminaSql @"
INSERT INTO unity_validation_staminaclaim_fixture
SELECT $UserId,$RoleId,'$userTable',0,'$State',r.user_spirit,r.money,u.money,u.bd_money,$hashExpression
FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId;
"@ | Out-Null
        }
        elseif ($existing.Count -ne 1) { throw "StaminaClaim fixture row is ambiguous." }
        $spiritHex = New-SpiritHex -Stamina $definition.stamina -States $definition.states
        Invoke-StaminaSql @"
UPDATE role_info SET user_spirit='$spiritHex',money=$($definition.roleMoney) WHERE id=$RoleId;
UPDATE ``$userTable`` SET money=$($definition.userMoney),bd_money=$($definition.boundMoney) WHERE id=$UserId AND role0=$RoleId;
UPDATE unity_validation_staminaclaim_fixture SET applied=1,fixture_state='$State' WHERE user_id=$UserId AND role_id=$RoleId;
"@ | Out-Null
        $row = @(Invoke-StaminaSql "SELECT snapshot_hash FROM unity_validation_staminaclaim_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        Write-Evidence ([ordered]@{action="Setup";userId=$UserId;roleId=$RoleId;userTable=$userTable;fixtureState=$State;snapshotHash=$row[0];injected=$definition;serverClock=$definition.serverClock;createdUtc=[DateTime]::UtcNow.ToString('o')})
        Write-Output "StaminaClaim fixture setup: state=$State stamina=$($definition.stamina) slots=$($definition.states -join ',') clock=$($definition.serverClock)"
    }
    "AssertSetup" {
        $row = @(Invoke-StaminaSql "SELECT applied,fixture_state,r.user_spirit,r.money,u.money,u.bd_money FROM unity_validation_staminaclaim_fixture f JOIN role_info r ON r.id=f.role_id JOIN ``$userTable`` u ON u.id=f.user_id AND u.role0=f.role_id WHERE f.user_id=$UserId AND f.role_id=$RoleId")
        if ($row.Count -ne 1) { throw "StaminaClaim fixture setup row is missing." }
        $parts = [string]$row[0] -split "`t"
        $actual = Read-Spirit $parts[2]
        if ($parts[0] -ne '1' -or $parts[1] -ne $State -or $actual.stamina -ne $definition.stamina -or (($actual.states -join ',') -ne ($definition.states -join ',')) -or [long]$parts[3] -ne $definition.roleMoney -or [long]$parts[4] -ne $definition.userMoney -or [long]$parts[5] -ne $definition.boundMoney) { throw "StaminaClaim live fixture state mismatch." }
        Write-Output "StaminaClaim fixture assert passed: state=$State stamina=$($actual.stamina) slots=$($actual.states -join ',')"
    }
    "Restore" {
        $row = @(Invoke-StaminaSql "SELECT applied FROM unity_validation_staminaclaim_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($row.Count -ne 1) { throw "StaminaClaim fixture row is missing for restore." }
        Invoke-StaminaSql @"
UPDATE role_info r JOIN unity_validation_staminaclaim_fixture f ON f.role_id=r.id
SET r.user_spirit=f.backup_user_spirit,r.money=f.backup_role_money WHERE f.user_id=$UserId AND f.role_id=$RoleId;
UPDATE ``$userTable`` u JOIN unity_validation_staminaclaim_fixture f ON f.user_id=u.id AND f.role_id=u.role0
SET u.money=f.backup_user_money,u.bd_money=f.backup_bd_money WHERE f.user_id=$UserId AND f.role_id=$RoleId;
UPDATE unity_validation_staminaclaim_fixture SET applied=0 WHERE user_id=$UserId AND role_id=$RoleId;
"@ | Out-Null
        Write-Output "StaminaClaim fixture restored."
    }
    "AssertRestored" {
        $row = @(Invoke-StaminaSql "SELECT COUNT(*)=1 AND f.applied=0 AND $hashExpression=f.snapshot_hash FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId JOIN unity_validation_staminaclaim_fixture f ON f.user_id=$UserId AND f.role_id=$RoleId WHERE r.id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne '1') { throw "StaminaClaim restored hash mismatch." }
        $snapshot = Read-Evidence
        Write-Evidence ([ordered]@{action="AssertRestored";userId=$UserId;roleId=$RoleId;fixtureState=$snapshot.fixtureState;snapshotHash=$snapshot.snapshotHash;restoredHash=$snapshot.snapshotHash;restored=$true;assertedUtc=[DateTime]::UtcNow.ToString('o')})
        Write-Output "StaminaClaim fixture restore hash passed: $($snapshot.snapshotHash)"
    }
    "Cleanup" {
        $row = @(Invoke-StaminaSql "SELECT applied FROM unity_validation_staminaclaim_fixture WHERE user_id=$UserId AND role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne '0') { throw "StaminaClaim fixture must be restored before cleanup." }
        Invoke-StaminaSql "DELETE FROM unity_validation_staminaclaim_fixture WHERE user_id=$UserId AND role_id=$RoleId" | Out-Null
        Write-Output "StaminaClaim fixture cleanup complete."
    }
    "AssertCleanup" {
        $row = @(Invoke-StaminaSql "SELECT COUNT(*) FROM unity_validation_staminaclaim_fixture WHERE user_id=$UserId OR role_id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne '0') { throw "StaminaClaim fixture residual rows remain: $($row -join ',')" }
        Write-Output "StaminaClaim fixture residual count=0"
    }
    "AssertReloginHash" {
        $snapshot = Read-Evidence
        if (-not $snapshot.snapshotHash) { throw "StaminaClaim snapshot hash is missing from evidence: $EvidencePath" }
        $row = @(Invoke-StaminaSql "SELECT $hashExpression FROM role_info r JOIN ``$userTable`` u ON u.id=$UserId AND u.role0=$RoleId WHERE r.id=$RoleId")
        if ($row.Count -ne 1 -or $row[0] -ne [string]$snapshot.snapshotHash) { throw "StaminaClaim post-login hash mismatch." }
        Write-Evidence ([ordered]@{action="AssertReloginHash";userId=$UserId;roleId=$RoleId;fixtureState=$snapshot.fixtureState;snapshotHash=$snapshot.snapshotHash;restoredHash=$snapshot.restoredHash;postLoginHash=$row[0];restored=$true;residualCount=0;assertedUtc=[DateTime]::UtcNow.ToString('o')})
        Write-Output "StaminaClaim post-login hash passed: $($row[0])"
    }
}

# The formal fixed-account runner performs two real account switches in the
# same Unity session. Keep both auxiliary identities under the same reversible
# lifecycle with independent snapshot/hash artifacts.
if ($UserId -eq 7200057 -and $RoleId -eq 1000115) {
    $isolationEvidencePath = if ($EvidencePath -match '\.json$') { $EvidencePath -replace '\.json$', '-isolation.json' } else { "$EvidencePath-isolation.json" }
    & pwsh -NoProfile -File $PSCommandPath -Action $Action -State InsufficientPremium `
        -UserId 705213 -RoleId 1000006 -EvidencePath $isolationEvidencePath
    if ($LASTEXITCODE -ne 0) { throw "StaminaClaim isolation fixture action failed: $Action" }
    $overCapEvidencePath = if ($EvidencePath -match '\.json$') { $EvidencePath -replace '\.json$', '-overcap.json' } else { "$EvidencePath-overcap.json" }
    & pwsh -NoProfile -File $PSCommandPath -Action $Action -State OverCap `
        -UserId 7200260 -RoleId 1000119 -EvidencePath $overCapEvidencePath
    if ($LASTEXITCODE -ne 0) { throw "StaminaClaim over-cap fixture action failed: $Action" }
}
