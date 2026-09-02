[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Snapshot", "SetupEmpty", "AssertEmpty", "Restore", "AssertRestored", "FreezeCrossBackendMapping", "AssertCrossBackendMapping")]
    [string]$Action,
    [string]$EvidencePath = ".local/unity-validation/gameplay-cocos-config-fixture.json",
    [string]$MappingEvidencePath = ".local/unity-validation/gameplay-cross-backend-mapping-latest.json",
    [string]$SqliteDatabasePath = ""
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$sourcePath = Join-Path $root "client\ProjectX\src\ConfigData\function_dat.lua"
$runtimePath = Join-Path $root "client\ProjectX\simulator\win32\src\ConfigData\function_dat.lua"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$mappingEvidence = if ([IO.Path]::IsPathRooted($MappingEvidencePath)) { $MappingEvidencePath } else { Join-Path $root $MappingEvidencePath }
if (-not $SqliteDatabasePath) {
    $SqliteDatabasePath = Join-Path $env:USERPROFILE "AppData\LocalLow\Xuancai\ProjectX\LocalServer\projectx.db"
}
$SqliteDatabasePath = [IO.Path]::GetFullPath($SqliteDatabasePath)
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$sqliteInspector = Join-Path $root "tools\unity-migration\Invoke-GameplayFixedAccountFixture.py"

function Get-Sha256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Assert-ClientStopped {
    $expected = [IO.Path]::GetFullPath((Join-Path $root "client\ProjectX\simulator\win32\ProjectX.exe"))
    $running = @(Get-Process ProjectX -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -and [IO.Path]::GetFullPath($_.Path) -eq $expected
    })
    if ($running.Count -gt 0) { throw "Stop workspace ProjectX.exe before Gameplay Cocos fixture $Action." }
}

function Read-Evidence {
    if (-not (Test-Path -LiteralPath $evidence -PathType Leaf)) { throw "Gameplay Cocos fixture evidence is missing: $evidence" }
    Get-Content -LiteralPath $evidence -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-Evidence($Payload) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($evidence)) | Out-Null
    [IO.File]::WriteAllText($evidence, (($Payload | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Invoke-GameplayMappingSql([string]$Sql) {
    if (-not (Test-Path -LiteralPath $mysql -PathType Leaf)) { throw "mysql.exe not found: $mysql" }
    $arguments = @(
        "--protocol=tcp", "--ssl-mode=DISABLED", "--host=127.0.0.1", "--port=3306",
        "--user=root", "--password=123456", "--database=fxl_game_local", "--batch", "--raw",
        "--skip-column-names", "--execute=$Sql"
    )
    $output = @(& $mysql @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Gameplay cross-backend SQL failed: $($output -join [Environment]::NewLine)" }
    @($output | Where-Object { [string]$_ -notmatch "\[Warning\] Using a password" })
}

function Get-GameplayCrossBackendState {
    Assert-ClientStopped
    if (@(Get-Process kapai, Unity -ErrorAction SilentlyContinue).Count -gt 0) {
        throw "Stop kapai.exe and Unity.exe before Gameplay cross-backend mapping audit."
    }
    $tables = @(Invoke-GameplayMappingSql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $userTables = @($tables | Where-Object {
        $_ -match '^user_info\d*$' -and @(Invoke-GameplayMappingSql "SELECT id FROM ``$_`` WHERE id=7200057 AND role0=1000115").Count -eq 1
    })
    if ($userTables.Count -ne 1) { throw "Gameplay Cocos identity 7200057/1000115 did not resolve to one user_info shard." }
    $mysqlIdentity = @(Invoke-GameplayMappingSql "SELECT u.id,u.role0,r.id,r.name,r.level FROM ``$($userTables[0])`` u JOIN role_info r ON r.id=u.role0 WHERE u.id=7200057 AND r.id=1000115")
    if ($mysqlIdentity.Count -ne 1) { throw "Gameplay Cocos identity row is missing or duplicated." }
    $mysqlFields = @([string]$mysqlIdentity[0] -split "`t")
    if ($mysqlFields.Count -ne 5) { throw "Gameplay Cocos identity row has an unexpected shape." }
    $mysqlHash = @(Invoke-GameplayMappingSql "SELECT SHA2(CONCAT_WS('|',u.id,u.role0,r.id,r.name,r.level),256) FROM ``$($userTables[0])`` u JOIN role_info r ON r.id=u.role0 WHERE u.id=7200057 AND r.id=1000115")

    $inspectArgs = @(
        "-X", "utf8", $sqliteInspector, "--action", "InspectIdentity",
        "--database", $SqliteDatabasePath,
        "--backup", (Join-Path $root ".local\unity-validation\gameplay-sqlite-fixture-backup.db"),
        "--evidence", (Join-Path $root ".local\ui-fidelity\Gameplay\fixture\gameplay-sqlite-fixture-snapshot.json"),
        "--user-id", "7200057", "--role-id", "1000003"
    )
    $sqliteJson = @(& python @inspectArgs 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "Gameplay SQLite identity inspection failed: $($sqliteJson -join [Environment]::NewLine)" }
    $sqlite = ([string]($sqliteJson -join "`n") | ConvertFrom-Json)

    $cocosText = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
    $cocosRoutes = @([regex]::Matches($cocosText, '(?s)\{\s*function_id\s*=\s*(?<id>\d+).*?\bpage\s*=\s*(?<page>\d+).*?\}') | ForEach-Object {
        [pscustomobject]@{ id = [int]$_.Groups['id'].Value; page = [int]$_.Groups['page'].Value }
    } | Where-Object { $_.id -lt 999 -and $_.page -ne 0 } | Sort-Object id)
    $unityConfigPath = Join-Path $root "unityclient\Assets\ProjectX\Resources\Configs\gameplay.json"
    $unityRoutes = @(Get-Content -LiteralPath $unityConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json)
    $steamRetained = @($unityRoutes | Where-Object { $_.steamEnabled -ne $false -and $_.page -ne 0 } | Sort-Object id | ForEach-Object { [int]$_.id })
    $unityReady = @($unityRoutes | Where-Object { $_.steamEnabled -ne $false -and $_.migrationReady -ne $false -and $_.page -ne 0 } | Sort-Object id | ForEach-Object { [int]$_.id })
    $cocosIds = @($cocosRoutes | ForEach-Object { [int]$_.id })
    $productExcluded = @($cocosIds | Where-Object { $steamRetained -notcontains $_ })
    $migrationPending = @($steamRetained | Where-Object { $unityReady -notcontains $_ })
    $sharedOpenLevel = @($unityRoutes | Where-Object { $unityReady -contains [int]$_.id } | Measure-Object -Property openLevel -Maximum).Maximum

    [ordered]@{
        schemaVersion = 1
        module = "Gameplay"
        contract = "semantic-cross-backend-identity-v1"
        logicalUserId = 7200057
        cocos = [ordered]@{
            backend = "mysql"
            userTable = [string]$userTables[0]
            userId = [uint32]$mysqlFields[0]
            linkedRoleId = [uint32]$mysqlFields[1]
            roleId = [uint32]$mysqlFields[2]
            roleName = [string]$mysqlFields[3]
            level = [int]$mysqlFields[4]
            identityHash = [string]$mysqlHash[0]
        }
        unity = [ordered]@{
            backend = "sqlite"
            database = "Application.persistentDataPath/LocalServer/projectx.db"
            userId = [uint32]$sqlite.identity.userId
            linkedRoleId = [uint32]$sqlite.identity.linkedRoleId
            roleId = [uint32]$sqlite.identity.roleId
            roleName = [string]$sqlite.identity.roleName
            level = [int]$sqlite.identity.level
            identityHash = [string]$sqlite.identityHash
            integrity = [string]$sqlite.integrity
        }
        semantics = [ordered]@{
            sameLogicalUser = ([uint32]$mysqlFields[0] -eq [uint32]$sqlite.identity.userId)
            sameRoleName = ([string]$mysqlFields[3] -eq [string]$sqlite.identity.roleName)
            maximumSharedOpenLevel = [int]$sharedOpenLevel
            bothOpenSharedReadyRoutes = ([int]$mysqlFields[4] -ge [int]$sharedOpenLevel -and [int]$sqlite.identity.level -ge [int]$sharedOpenLevel)
            cocosVisibleIds = $cocosIds
            steamRetainedIds = $steamRetained
            unityReadyVisibleIds = $unityReady
            productExcludedIds = $productExcluded
            migrationPendingIds = $migrationPending
            visualParityReady = ($migrationPending.Count -eq 0)
            redPointOwnership = "shared-cache-read-only"
        }
        inputs = [ordered]@{
            cocosConfig = "client/ProjectX/src/ConfigData/function_dat.lua"
            cocosConfigSha256 = Get-Sha256 $sourcePath
            unityConfig = "unityclient/Assets/ProjectX/Resources/Configs/gameplay.json"
            unityConfigSha256 = Get-Sha256 $unityConfigPath
        }
        checkedUtc = [DateTime]::UtcNow.ToString("O")
    }
}

function Get-GameplayMappingFingerprint($State) {
    $projection = [ordered]@{
        logicalUserId = $State.logicalUserId
        cocos = $State.cocos
        unity = $State.unity
        semantics = $State.semantics
        inputs = $State.inputs
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($projection | ConvertTo-Json -Depth 12 -Compress))
    $stream = [IO.MemoryStream]::new($bytes)
    try { (Get-FileHash -Algorithm SHA256 -InputStream $stream).Hash }
    finally { $stream.Dispose() }
}

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Gameplay source config is missing: $sourcePath" }
if (-not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) { throw "Gameplay simulator config is missing: $runtimePath" }

switch ($Action) {
    "Snapshot" {
        Assert-ClientStopped
        $sourceHash = Get-Sha256 $sourcePath
        $runtimeHash = Get-Sha256 $runtimePath
        if ($sourceHash -ne $runtimeHash) { throw "Gameplay simulator config must match source before snapshot." }
        Write-Evidence ([ordered]@{
            schemaVersion = 1
            module = "Gameplay"
            fixture = "runtime-config-pages-hidden"
            phase = "snapshot"
            sourcePath = $sourcePath
            runtimePath = $runtimePath
            sourceHash = $sourceHash
            snapshotHash = $runtimeHash
            runtimeBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($runtimePath))
            residuals = @()
        })
        Write-Host "Gameplay Cocos config snapshot passed: $runtimeHash"
    }
    "SetupEmpty" {
        Assert-ClientStopped
        $payload = Read-Evidence
        if ([string]$payload.snapshotHash -ne (Get-Sha256 $runtimePath)) { throw "Gameplay simulator config changed after snapshot." }
        $runtimeText = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([string]$payload.runtimeBase64))
        $matches = [regex]::Matches($runtimeText, '(?m)(\bpage\s*=\s*)[1-9]\d*')
        if ($matches.Count -eq 0) { throw "Gameplay simulator config has no visible page entries to hide." }
        $emptyText = [regex]::Replace($runtimeText, '(?m)(\bpage\s*=\s*)[1-9]\d*', '${1}0')
        [IO.File]::WriteAllText($runtimePath, $emptyText, [Text.UTF8Encoding]::new($false))
        $payload.phase = "empty-applied"
        $payload | Add-Member -NotePropertyName emptyHash -NotePropertyValue (Get-Sha256 $runtimePath) -Force
        $payload | Add-Member -NotePropertyName hiddenPageEntryCount -NotePropertyValue $matches.Count -Force
        Write-Evidence $payload
        Write-Host "Gameplay Cocos page-hidden config applied to simulator copy only: $($matches.Count) entries."
    }
    "AssertEmpty" {
        $payload = Read-Evidence
        if ([string]$payload.phase -ne "empty-applied") { throw "Gameplay empty fixture is not active." }
        if ((Get-Sha256 $sourcePath) -ne [string]$payload.sourceHash) { throw "Gameplay source config changed during runtime-only fixture." }
        if ((Get-Sha256 $runtimePath) -ne [string]$payload.emptyHash) { throw "Gameplay runtime empty fixture hash mismatch." }
        Write-Host "Gameplay Cocos empty config assertion passed."
    }
    "Restore" {
        Assert-ClientStopped
        $payload = Read-Evidence
        [IO.File]::WriteAllBytes($runtimePath, [Convert]::FromBase64String([string]$payload.runtimeBase64))
        $payload.phase = "restored"
        Write-Evidence $payload
        Write-Host "Gameplay Cocos simulator config restored."
    }
    "AssertRestored" {
        $payload = Read-Evidence
        $sourceHash = Get-Sha256 $sourcePath
        $runtimeHash = Get-Sha256 $runtimePath
        if ($sourceHash -ne [string]$payload.sourceHash -or $runtimeHash -ne [string]$payload.snapshotHash -or $sourceHash -ne $runtimeHash) {
            throw "Gameplay Cocos config restore assertion failed."
        }
        $payload.phase = "restore-asserted"
        $payload.residuals = @()
        Write-Evidence $payload
        Write-Host "Gameplay Cocos config restore assertion passed: $runtimeHash"
    }
    "FreezeCrossBackendMapping" {
        $state = Get-GameplayCrossBackendState
        if (-not $state.semantics.sameLogicalUser -or -not $state.semantics.sameRoleName -or -not $state.semantics.bothOpenSharedReadyRoutes) {
            throw "Gameplay cross-backend identity semantics are not equivalent."
        }
        $state | Add-Member -NotePropertyName mappingFingerprint -NotePropertyValue (Get-GameplayMappingFingerprint $state)
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($mappingEvidence)) | Out-Null
        [IO.File]::WriteAllText($mappingEvidence, (($state | ConvertTo-Json -Depth 12) + "`n"), [Text.UTF8Encoding]::new($false))
        Write-Host "Gameplay cross-backend mapping frozen: shared=$($state.semantics.unityReadyVisibleIds -join ',') pending=$($state.semantics.migrationPendingIds -join ',')"
    }
    "AssertCrossBackendMapping" {
        if (-not (Test-Path -LiteralPath $mappingEvidence -PathType Leaf)) { throw "Gameplay cross-backend mapping evidence is missing." }
        $frozen = Get-Content -LiteralPath $mappingEvidence -Raw -Encoding UTF8 | ConvertFrom-Json
        $current = Get-GameplayCrossBackendState
        $currentFingerprint = Get-GameplayMappingFingerprint $current
        if ([string]$frozen.mappingFingerprint -ne $currentFingerprint) { throw "Gameplay cross-backend mapping changed after freeze." }
        if (-not $current.semantics.sameLogicalUser -or -not $current.semantics.sameRoleName -or -not $current.semantics.bothOpenSharedReadyRoutes) {
            throw "Gameplay cross-backend identity semantics regressed."
        }
        Write-Host "Gameplay cross-backend mapping assertion passed; visualParityReady=$($current.semantics.visualParityReady)."
    }
}
