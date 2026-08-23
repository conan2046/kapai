[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Setup", "AssertSetup", "CaptureMutationHash", "AssertMutationReloginHash", "Restore", "AssertRestored", "Cleanup", "AssertCleanup", "AssertReloginHash", "AddUserFragments", "RestoreUserFragments", "SeedTestInventory")]
    [string]$Action,
    [uint32]$UserId = 7200057,
    [uint32]$RoleId = 1000115,
    [ValidateSet("Hero", "Cocos", "Transaction")]
    [string]$Profile = "Transaction",
    [string]$EvidencePath = ".local/ui-fidelity/HeroEquip/unity/g5-current/hero-equip-fixed-fixture-snapshot.json",
    [string]$UserFragmentEvidencePath = ".local/unity-validation/hero-equip-user-fragments-latest.json"
)

$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
$evidence = if ([IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $root $EvidencePath }
$roleBackup = "codex_hero_equip_role_backup"
$userBackup = "codex_hero_equip_user_backup"
$fixtureEquipmentUid = [uint32]2121073001
$fixtureEquipmentTemplateId = [uint16]1301
$fixtureShenZhuEquipmentUid = [uint32]2121073003
$fixtureShenZhuEquipmentTemplateId = [uint16]1401
$sourceWornEquipmentUid = [uint32]2121072641
$sourceWornEquipmentTemplateId = [uint16]1001
$scrollFixtureEquipmentUids = @(
    [uint32]2121073010, [uint32]2121073011, [uint32]2121073012,
    [uint32]2121073013, [uint32]2121073014, [uint32]2121073015,
    [uint32]2121073016, [uint32]2121073017, [uint32]2121073018
)
$sourceFormationHeroId = [uint32]57
$targetFormationHeroId = [uint32]64
$fixtureFaBaoUid = [uint32]2121073002
$fixtureFaBaoTemplateId = [uint16]1101
$fixtureFragmentIds = if ($Profile -eq "Transaction") {
    @([uint16]4605, [uint16]4621, [uint16]4622, [uint16]4629)
} elseif ($Profile -eq "Hero") {
    @()
} else {
    @([uint16]4605, [uint16]4621)
}
$fixtureFragmentQuantities = if ($Profile -eq "Transaction") {
    @([uint16]5, [uint16]62, [uint16]2, [uint16]1)
} elseif ($Profile -eq "Hero") {
    @()
} else {
    @([uint16]5, [uint16]30)
}
$fixturePackageItemIds = @($fixtureFragmentIds)
$fixturePackageItemQuantities = @($fixtureFragmentQuantities)
if ($Profile -eq "Transaction") {
    $fixturePackageItemIds += @([uint16]610, [uint16]854)
    $fixturePackageItemQuantities += @([uint16]500, [uint16]5)
}
$userFragmentIds = @([uint16]4605, [uint16]4621, [uint16]4622, [uint16]4629)
$userFragmentQuantities = @([uint16]30, [uint16]60, [uint16]30, [uint16]10)
$packageSlots = 500
$serverConfig = Join-Path $root "server/config/config"

if ($Action -notin @("AddUserFragments", "RestoreUserFragments") -and ($UserId -ne 7200057 -or $RoleId -ne 1000115)) {
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

function Assert-RoleClientsStopped {
    $running = @(Get-Process kapai, ProjectX -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) { throw "Stop kapai.exe and ProjectX.exe before changing persistent HeroEquip user fragments." }
}

function Get-PreserveBalanceUserId {
    $content = Get-Content -LiteralPath $serverConfig -Raw -Encoding UTF8
    $matches = [regex]::Matches($content, '(?m)^local_preserve_balance_user_id=(\d+)\s*$')
    if ($matches.Count -ne 1) { throw "server config must contain exactly one local_preserve_balance_user_id entry." }
    [uint32]$matches[0].Groups[1].Value
}

function Set-PreserveBalanceUserId([uint32]$Value) {
    $content = Get-Content -LiteralPath $serverConfig -Raw -Encoding UTF8
    $updated = [regex]::Replace($content, '(?m)^local_preserve_balance_user_id=\d+\s*$', "local_preserve_balance_user_id=$Value", 1)
    [IO.File]::WriteAllText($serverConfig, $updated, [Text.UTF8Encoding]::new($false))
}

function Get-UserTable {
    $tables = @(Invoke-HeroEquipSql "SELECT TABLE_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fxl_game_local' AND TABLE_NAME LIKE 'user_info%' AND COLUMN_NAME IN ('id','role0') GROUP BY TABLE_NAME HAVING COUNT(DISTINCT COLUMN_NAME)=2")
    $matches = @($tables | Where-Object {
        $_ -match '^user_info\d*$' -and @(Invoke-HeroEquipSql "SELECT id FROM ``$_`` WHERE id=$UserId AND role0=$RoleId").Count -eq 1
    })
    if ($matches.Count -ne 1) { throw "HeroEquip userId=$UserId roleId=$RoleId did not resolve to exactly one user_info shard." }
    [string]$matches[0]
}

function Get-HeroEquipSha256([string]$Value) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { [Convert]::ToHexString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Value))).ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-RoleHashStateFromTable([string]$Table) {
    if ($Table -notmatch '^[A-Za-z0-9_]+$') { throw "Invalid HeroEquip role hash table: $Table" }
    $sql = "SELECT CONCAT_WS(CHAR(31),COALESCE(level,0),COALESCE(zhanDouLi,0),COALESCE(pet_equip,''),COALESCE(pet,''),COALESCE(zhenfa,''),COALESCE(money,''),COALESCE(package,''),COALESCE(mission,''),COALESCE(save_data,''),COALESCE(clientstring,'')) FROM ``$Table`` WHERE id=$RoleId"
    $rows = @(Invoke-HeroEquipSql $sql)
    if ($rows.Count -ne 1) { throw "HeroEquip role_info row is missing for roleId=$RoleId." }
    $parts = @(([string]$rows[0]).Split([char]31))
    if ($parts.Count -ne 10) { throw "HeroEquip role hash source field count mismatch: $($parts.Count)/10." }
    $petEquipBytes = Expand-HeroEquipBlob ([string]$parts[2])
    $layout = Get-HeroEquipBlobLayout $petEquipBytes
    [Array]::Clear($petEquipBytes, [int]$layout.faBaoEnd, 4)
    $parts[2] = [Convert]::ToHexString($petEquipBytes).ToLowerInvariant()
    $names = @("level", "zhanDouLi", "pet_equip_normalized", "pet", "zhenfa", "money", "package", "mission", "save_data", "clientstring")
    $fields = [ordered]@{}
    for ($index = 0; $index -lt $names.Count; $index++) { $fields[$names[$index]] = Get-HeroEquipSha256 ([string]$parts[$index]) }
    [pscustomobject]@{ overall = Get-HeroEquipSha256 ($parts -join '|'); fields = [pscustomobject]$fields }
}

function Get-RoleHashFromTable([string]$Table) { [string](Get-RoleHashStateFromTable $Table).overall }
function Get-RoleHash { Get-RoleHashFromTable "role_info" }

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

function Add-HeroEquipPackageFragments([string]$Hex) {
    $bytes = Expand-HeroEquipBlob $Hex
    $slots = New-Object System.Collections.Generic.List[object]
    $position = 0
    $existing = @{}
    $emptySlots = New-Object System.Collections.Generic.List[int]
    for ($slot = 0; $slot -lt $packageSlots; $slot++) {
        if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package ended before slot $slot." }
        $itemId = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        $quantity = 0
        if ($itemId -ne 0) {
            if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package item $itemId has no quantity." }
            $quantity = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        }
        $slots.Add([pscustomobject]@{ itemId=[uint16]$itemId; quantity=[uint16]$quantity })
        if ($itemId -eq 0) { $emptySlots.Add($slot); continue }
        $existing[[int]$itemId] = ([int]($existing[[int]$itemId] ?? 0)) + [int]$quantity
    }
    if ($position -ne $bytes.Length) { throw "HeroEquip package has trailing bytes after 500 slots." }
    $nextEmptySlot = 0
    for ($index = 0; $index -lt $fixturePackageItemIds.Count; $index++) {
        $itemId = [int]$fixturePackageItemIds[$index]
        $matchingSlots = @(for ($slotIndex = 0; $slotIndex -lt $slots.Count; $slotIndex++) {
            if ([int]$slots[$slotIndex].itemId -eq $itemId) { $slotIndex }
        })
        if ($matchingSlots.Count -gt 0) {
            $slots[$matchingSlots[0]] = [pscustomobject]@{ itemId=[uint16]$itemId; quantity=[uint16]$fixturePackageItemQuantities[$index] }
            foreach ($duplicateSlot in @($matchingSlots | Select-Object -Skip 1)) {
                $slots[$duplicateSlot] = [pscustomobject]@{ itemId=[uint16]0; quantity=[uint16]0 }
            }
            continue
        }
        if ($emptySlots.Count -le $nextEmptySlot) { throw "HeroEquip package has no empty slot for fragment fixture." }
        $slots[$emptySlots[$nextEmptySlot]] = [pscustomobject]@{ itemId=[uint16]$itemId; quantity=[uint16]$fixturePackageItemQuantities[$index] }
        $nextEmptySlot++
    }
    $output = [IO.MemoryStream]::new(); $writer = [IO.BinaryWriter]::new($output)
    try {
        foreach ($entry in $slots) {
            $writer.Write([uint16]$entry.itemId)
            if ([uint16]$entry.itemId -ne 0) { $writer.Write([uint16]$entry.quantity) }
        }
        Compress-HeroEquipBlob ([byte[]]$output.ToArray())
    }
    finally { $writer.Dispose(); $output.Dispose() }
}

function Assert-HeroEquipPackageFragments {
    $rows = @(Invoke-HeroEquipSql "SELECT package FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "HeroEquip role package is missing while asserting fixture fragments." }
    $bytes = Expand-HeroEquipBlob ([string]$rows[0]); $counts = @{}
    $position = 0
    for ($slot = 0; $slot -lt $packageSlots; $slot++) {
        if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package ended before assertion slot $slot." }
        $itemId = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        if ($itemId -eq 0) { continue }
        if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package item $itemId has no assertion quantity." }
        $quantity = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        $counts[[int]$itemId] = ([int]($counts[[int]$itemId] ?? 0)) + [int]$quantity
    }
    if ($position -ne $bytes.Length) { throw "HeroEquip package has trailing assertion bytes." }
    for ($index = 0; $index -lt $fixturePackageItemIds.Count; $index++) {
        $itemId = [int]$fixturePackageItemIds[$index]
        if ([int]$counts[$itemId] -ne [int]$fixturePackageItemQuantities[$index]) { throw "HeroEquip fixture package item $itemId count mismatch." }
    }
}

function Get-HeroEquipPackageFragmentCounts([string]$Hex, [uint16[]]$ItemIds) {
    $wanted = @{}; foreach ($itemId in $ItemIds) { $wanted[[int]$itemId] = 0 }
    $bytes = Expand-HeroEquipBlob $Hex
    $position = 0
    for ($slot = 0; $slot -lt $packageSlots; $slot++) {
        if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package ended before fragment count slot $slot." }
        $itemId = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        if ($itemId -eq 0) { continue }
        if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package item $itemId has no fragment count quantity." }
        $quantity = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        if ($wanted.ContainsKey([int]$itemId)) { $wanted[[int]$itemId] += [int]$quantity }
    }
    if ($position -ne $bytes.Length) { throw "HeroEquip package has trailing bytes after fragment count." }
    $result = [ordered]@{}
    foreach ($itemId in $ItemIds) { $result[[string][int]$itemId] = [int]$wanted[[int]$itemId] }
    $result
}

function Add-HeroEquipUserFragments([string]$Hex) {
    $bytes = Expand-HeroEquipBlob $Hex
    $slots = New-Object System.Collections.Generic.List[object]
    $slotByItemId = @{}
    $emptySlots = New-Object System.Collections.Generic.Queue[int]
    $position = 0
    for ($slot = 0; $slot -lt $packageSlots; $slot++) {
        if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package ended before user fragment slot $slot." }
        $itemId = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        $quantity = 0
        if ($itemId -ne 0) {
            if ($position + 2 -gt $bytes.Length) { throw "HeroEquip package item $itemId has no user fragment quantity." }
            $quantity = [BitConverter]::ToUInt16($bytes, $position); $position += 2
        }
        $slots.Add([pscustomobject]@{ itemId=[uint16]$itemId; quantity=[uint16]$quantity })
        if ($itemId -eq 0) { $emptySlots.Enqueue($slot) }
        elseif (-not $slotByItemId.ContainsKey([int]$itemId)) { $slotByItemId[[int]$itemId] = $slot }
    }
    if ($position -ne $bytes.Length) { throw "HeroEquip package has trailing bytes before adding user fragments." }
    for ($index = 0; $index -lt $userFragmentIds.Count; $index++) {
        $itemId = [int]$userFragmentIds[$index]
        $quantity = [int]$userFragmentQuantities[$index]
        if ($slotByItemId.ContainsKey($itemId)) {
            $slot = [int]$slotByItemId[$itemId]
            $total = [int]$slots[$slot].quantity + $quantity
            if ($total -gt [uint16]::MaxValue) { throw "HeroEquip user fragment $itemId exceeds uint16 quantity." }
            $slots[$slot] = [pscustomobject]@{ itemId=[uint16]$itemId; quantity=[uint16]$total }
        } else {
            if ($emptySlots.Count -eq 0) { throw "HeroEquip package has no empty slot for user fragment $itemId." }
            $slot = $emptySlots.Dequeue()
            $slots[$slot] = [pscustomobject]@{ itemId=[uint16]$itemId; quantity=[uint16]$quantity }
        }
    }
    $output = [IO.MemoryStream]::new(); $writer = [IO.BinaryWriter]::new($output)
    try {
        foreach ($entry in $slots) {
            $writer.Write([uint16]$entry.itemId)
            if ([uint16]$entry.itemId -ne 0) { $writer.Write([uint16]$entry.quantity) }
        }
        Compress-HeroEquipBlob ([byte[]]$output.ToArray())
    }
    finally { $writer.Dispose(); $output.Dispose() }
}

function Set-HeroEquipSecondFormationPosition([string]$Hex) {
    $bytes = Expand-HeroEquipBlob $Hex
    $position = 0
    if ($bytes.Length -lt 2) { throw "HeroEquip zhenfa payload is truncated." }
    $activeIndex = $bytes[$position]; $position++
    $zhenfaCount = $bytes[$position]; $position++
    $position += 3 * $zhenfaCount
    if ($position -ge $bytes.Length) { throw "HeroEquip zhenfa member count is missing." }
    $memberCount = $bytes[$position]; $position++
    $expectedHeroes = @($sourceFormationHeroId, $targetFormationHeroId)
    if ($memberCount -lt $expectedHeroes.Count) { throw "HeroEquip fixture requires at least $($expectedHeroes.Count) formation member slots." }
    $memberStart = $position
    $position += 5 * $memberCount
    if ($position -ge $bytes.Length) { throw "HeroEquip zhenfa chuzhan count is missing." }
    $chuzhanCount = $bytes[$position]; $position++
    if ($chuzhanCount -lt $expectedHeroes.Count) { throw "HeroEquip fixture requires at least $($expectedHeroes.Count) chuzhan slots." }
    if ($position + 2 * $chuzhanCount -ne $bytes.Length) { throw "HeroEquip zhenfa payload length does not match source serialization." }

    $firstMemberOffset = $memberStart
    if ($bytes[$firstMemberOffset] -ne 2 -or [BitConverter]::ToUInt32($bytes, $firstMemberOffset + 1) -ne $sourceFormationHeroId) {
        throw "HeroEquip source formation position 1 is not hero $sourceFormationHeroId."
    }
    for ($index = 1; $index -lt $expectedHeroes.Count; $index++) {
        $memberOffset = $memberStart + 5 * $index
        $bytes[$memberOffset] = 2
        [BitConverter]::GetBytes([uint32]$expectedHeroes[$index]).CopyTo($bytes, $memberOffset + 1)
        [BitConverter]::GetBytes([uint16]$expectedHeroes[$index]).CopyTo($bytes, $position + 2 * $index)
    }
    Compress-HeroEquipBlob $bytes
}

function Assert-HeroEquipFormationPositions {
    $rows = @(Invoke-HeroEquipSql "SELECT zhenfa FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "HeroEquip role zhenfa is missing while asserting formation fixture." }
    $bytes = Expand-HeroEquipBlob ([string]$rows[0])
    $position = 0
    $position += 1
    $zhenfaCount = $bytes[$position]; $position++
    $position += 3 * $zhenfaCount
    $memberCount = $bytes[$position]; $position++
    $expectedHeroes = @($sourceFormationHeroId, $targetFormationHeroId)
    if ($memberCount -lt $expectedHeroes.Count) { throw "HeroEquip formation assertion has fewer than $($expectedHeroes.Count) member slots." }
    $memberStart = $position
    $position += 5 * $memberCount
    $chuzhanCount = $bytes[$position]; $position++
    if ($chuzhanCount -lt $expectedHeroes.Count) { throw "HeroEquip formation assertion has fewer than $($expectedHeroes.Count) chuzhan slots." }
    for ($index = 0; $index -lt $expectedHeroes.Count; $index++) {
        $memberOffset = $memberStart + 5 * $index
        if ($bytes[$memberOffset] -ne 2 -or [BitConverter]::ToUInt32($bytes, $memberOffset + 1) -ne $expectedHeroes[$index]) {
            throw "HeroEquip formation member position $($index + 1) mismatch."
        }
        if ([BitConverter]::ToUInt16($bytes, $position + 2 * $index) -ne [uint16]$expectedHeroes[$index]) {
            throw "HeroEquip chuzhan position $($index + 1) mismatch."
        }
    }
}

function Get-HeroEquipBlobLayout([byte[]]$Bytes) {
    $stream = [IO.MemoryStream]::new($Bytes)
    $reader = [IO.BinaryReader]::new($stream)
    $equipmentUids = New-Object System.Collections.Generic.List[uint32]
    $equipmentEntries = New-Object System.Collections.Generic.List[object]
    $faBaoUids = New-Object System.Collections.Generic.List[uint32]
    $faBaoEntries = New-Object System.Collections.Generic.List[object]
    try {
        $equipmentCount = $reader.ReadUInt16()
        for ($index = 0; $index -lt $equipmentCount; $index++) {
            $uid = $reader.ReadUInt32()
            $templateId = $reader.ReadUInt16()
            $equipmentUids.Add($uid)
            $reader.ReadUInt32() | Out-Null
            $reader.ReadUInt32() | Out-Null
            $formationPosition = $reader.ReadByte()
            $levelCount = $reader.ReadByte()
            for ($level = 0; $level -lt $levelCount; $level++) {
                $reader.ReadByte() | Out-Null
                $reader.ReadUInt16() | Out-Null
            }
            $equipmentEntries.Add([pscustomobject]@{ uid=$uid; templateId=$templateId; formationPosition=$formationPosition })
        }
        $equipmentEnd = [int]$stream.Position
        $faBaoCount = $reader.ReadUInt16()
        $faBaoStart = [int]$stream.Position
        for ($index = 0; $index -lt $faBaoCount; $index++) {
            $uid = $reader.ReadUInt32()
            $templateId = $reader.ReadUInt16()
            $faBaoUids.Add($uid)
            $reader.ReadUInt32() | Out-Null
            $reader.ReadByte() | Out-Null
            $reader.ReadByte() | Out-Null
            $levelCount = $reader.ReadByte()
            for ($level = 0; $level -lt $levelCount; $level++) {
                $reader.ReadByte() | Out-Null
                $reader.ReadByte() | Out-Null
            }
            $faBaoEntries.Add([pscustomobject]@{ uid=$uid; templateId=$templateId })
        }
        $faBaoEnd = [int]$stream.Position
        if ($Bytes.Length - $faBaoEnd -ne 6) { throw "HeroEquip pet_equip tail length is not uint32+uint16." }
        [pscustomobject]@{
            equipmentCount = [int]$equipmentCount
            equipmentEnd = $equipmentEnd
            equipmentUids = @($equipmentUids)
            equipmentEntries = $equipmentEntries.ToArray()
            faBaoCount = [int]$faBaoCount
            faBaoStart = $faBaoStart
            faBaoEnd = $faBaoEnd
            faBaoUids = @($faBaoUids)
            faBaoEntries = $faBaoEntries.ToArray()
        }
    }
    finally { $reader.Dispose(); $stream.Dispose() }
}

function Add-HeroEquipFixtureItems([string]$Hex) {
    $bytes = Expand-HeroEquipBlob $Hex
    $layout = Get-HeroEquipBlobLayout $bytes
    if ($Profile -eq "Hero") { return $Hex }
    $reservedEquipmentUids = @($sourceWornEquipmentUid, $fixtureEquipmentUid, $fixtureShenZhuEquipmentUid) +
        @($scrollFixtureEquipmentUids)
    $presentEquipmentUids = @($reservedEquipmentUids | Where-Object { $_ -in $layout.equipmentUids })
    $fixtureFaBaoPresent = $fixtureFaBaoUid -in $layout.faBaoUids
    if ($presentEquipmentUids.Count -gt 0 -or $fixtureFaBaoPresent) {
        if ($presentEquipmentUids.Count -eq $reservedEquipmentUids.Count -and $fixtureFaBaoPresent) {
            return $Hex
        }
        throw "HeroEquip reserved fixture UID set is partially occupied in the source snapshot."
    }
    $stream = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($stream)
    try {
        $addedEquipmentCount = if ($Profile -eq "Transaction") { 3 + $scrollFixtureEquipmentUids.Count } else { 2 }
        $writer.Write([uint16]($layout.equipmentCount + $addedEquipmentCount))
        $writer.Write($bytes, 2, $layout.equipmentEnd - 2)
        $writer.Write($sourceWornEquipmentUid)
        $writer.Write($sourceWornEquipmentTemplateId)
        $writer.Write([uint32]0)
        $writer.Write([uint32]0)
        $writer.Write([byte]1)
        $writer.Write([byte]0)
        $writer.Write($fixtureEquipmentUid)
        $writer.Write($fixtureEquipmentTemplateId)
        $writer.Write([uint32]0)
        $writer.Write([uint32]0)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        if ($Profile -eq "Transaction") {
            $writer.Write($fixtureShenZhuEquipmentUid)
            $writer.Write($fixtureShenZhuEquipmentTemplateId)
            $writer.Write([uint32]0)
            $writer.Write([uint32]0)
            $writer.Write([byte]0)
            $writer.Write([byte]0)
            foreach ($scrollUid in $scrollFixtureEquipmentUids) {
                $writer.Write($scrollUid)
                $writer.Write($sourceWornEquipmentTemplateId)
                $writer.Write([uint32]0)
                $writer.Write([uint32]0)
                $writer.Write([byte]0)
                $writer.Write([byte]0)
            }
        }
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

function Get-PreserveLevelUserId {
    $content = Get-Content -LiteralPath $serverConfig -Raw -Encoding UTF8
    $matches = [regex]::Matches($content, '(?m)^local_preserve_level_user_id=(\d+)\s*$')
    if ($matches.Count -ne 1) { throw "server config must contain exactly one local_preserve_level_user_id entry." }
    [uint32]$matches[0].Groups[1].Value
}

function Set-PreserveLevelUserId([uint32]$Value) {
    $content = Get-Content -LiteralPath $serverConfig -Raw -Encoding UTF8
    $updated = [regex]::Replace($content, '(?m)^local_preserve_level_user_id=\d+\s*$', "local_preserve_level_user_id=$Value", 1)
    [IO.File]::WriteAllText($serverConfig, $updated, [Text.UTF8Encoding]::new($false))
}

function Add-HeroEquipTestInventory([string]$Hex) {
    $bytes = Expand-HeroEquipBlob $Hex
    $layout = Get-HeroEquipBlobLayout $bytes
    $equipmentTemplates = @([uint16]1401,[uint16]1402,[uint16]1403,[uint16]1404,[uint16]1411,[uint16]1412,[uint16]1413,[uint16]1414)
    $faBaoTemplates = @([uint16]1301,[uint16]1302,[uint16]1303,[uint16]1304,[uint16]1305,[uint16]1306,[uint16]1307,[uint16]1308,[uint16]1309,[uint16]1310,[uint16]1311,[uint16]1312,[uint16]1313,[uint16]1314)
    $equipmentBaseUid = [uint32]2121090000
    $faBaoBaseUid = [uint32]2121091000
    $existingEquipmentTemplates = @($layout.equipmentEntries | ForEach-Object { [uint16]$_.templateId })
    $equipmentToAdd = @($equipmentTemplates | Where-Object { $_ -notin $existingEquipmentTemplates })
    $existingFaBaoTemplates = @($layout.faBaoEntries | ForEach-Object { [uint16]$_.templateId })
    $faBaoToAdd = @($faBaoTemplates | Where-Object { $_ -notin $existingFaBaoTemplates })
    $stream = [IO.MemoryStream]::new(); $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]($layout.equipmentCount + $equipmentToAdd.Count))
        $writer.Write($bytes, 2, $layout.equipmentEnd - 2)
        foreach ($templateId in $equipmentToAdd) {
            $templateIndex = [Array]::IndexOf($equipmentTemplates, [uint16]$templateId)
            $uid = [uint32]($equipmentBaseUid + $templateIndex)
            if ($uid -in $layout.equipmentUids) { throw "HeroEquip test equipment UID $uid is occupied by another template." }
            $writer.Write($uid); $writer.Write([uint16]$templateId)
            $writer.Write([uint32]0); $writer.Write([uint32]0); $writer.Write([byte]0); $writer.Write([byte]0)
        }
        $writer.Write([uint16]($layout.faBaoCount + $faBaoToAdd.Count))
        $writer.Write($bytes, $layout.faBaoStart, $layout.faBaoEnd - $layout.faBaoStart)
        foreach ($templateId in $faBaoToAdd) {
            $templateIndex = [Array]::IndexOf($faBaoTemplates, [uint16]$templateId)
            $uid = [uint32]($faBaoBaseUid + $templateIndex)
            if ($uid -in $layout.faBaoUids) { throw "HeroEquip test FaBao UID $uid is occupied by another template." }
            $writer.Write($uid); $writer.Write([uint16]$templateId)
            $writer.Write([uint32]0); $writer.Write([byte]0); $writer.Write([byte]0); $writer.Write([byte]0)
        }
        $writer.Write($bytes, $layout.faBaoEnd, $bytes.Length - $layout.faBaoEnd)
        [ordered]@{ hex = Compress-HeroEquipBlob ([byte[]]$stream.ToArray()); equipmentTemplates=$equipmentTemplates; faBaoTemplates=$faBaoTemplates }
    } finally { $writer.Dispose(); $stream.Dispose() }
}

function Assert-HeroEquipFixtureItems {
    $rows = @(Invoke-HeroEquipSql "SELECT pet_equip FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "HeroEquip role row is missing while asserting fixture items." }
    $layout = Get-HeroEquipBlobLayout (Expand-HeroEquipBlob ([string]$rows[0]))
    if ($Profile -eq "Hero") {
        if ($layout.equipmentCount -lt 4 -or $layout.faBaoCount -lt 2) {
            throw "Hero fixture requires at least four equipment records and two fabao records."
        }
        return
    }
    if ($fixtureEquipmentUid -notin $layout.equipmentUids) { throw "HeroEquip fixture equipment is missing." }
    if ($fixtureFaBaoUid -notin $layout.faBaoUids) { throw "HeroEquip fixture fabao is missing." }
    $source = @($layout.equipmentEntries | Where-Object { $_.uid -eq $sourceWornEquipmentUid })
    $target = @($layout.equipmentEntries | Where-Object { $_.uid -eq $fixtureEquipmentUid })
    if ($source.Count -ne 1 -or $source[0].templateId -ne $sourceWornEquipmentTemplateId -or $source[0].formationPosition -ne 1) {
        throw "HeroEquip source worn weapon contract mismatch."
    }
    if ($target.Count -ne 1 -or $target[0].templateId -ne $fixtureEquipmentTemplateId -or $target[0].formationPosition -ne 0) {
        throw "HeroEquip target unworn weapon contract mismatch."
    }
    $shenZhuTarget = @($layout.equipmentEntries | Where-Object { $_.uid -eq $fixtureShenZhuEquipmentUid })
    if ($Profile -eq "Transaction") {
        if ($shenZhuTarget.Count -ne 1 -or $shenZhuTarget[0].templateId -ne $fixtureShenZhuEquipmentTemplateId -or $shenZhuTarget[0].formationPosition -ne 0) {
            throw "HeroEquip transaction shenzhu weapon contract mismatch."
        }
        if (@($scrollFixtureEquipmentUids | Where-Object { $_ -notin $layout.equipmentUids }).Count -gt 0) {
            throw "HeroEquip transaction scroll fixture equipment is missing."
        }
    } elseif ($shenZhuTarget.Count -ne 0) {
        throw "HeroEquip Cocos profile must not add the transaction-only shenzhu weapon."
    }
}

function Assert-HeroEquipCultivationContract {
    $rows = @(Invoke-HeroEquipSql "SELECT level FROM role_info WHERE id=$RoleId")
    if ($rows.Count -ne 1) { throw "HeroEquip role level is missing while asserting cultivation contract." }
    $expectedLevel = if ($Profile -eq "Transaction") { 70 } elseif ($Profile -eq "Hero") { 99 } else { 60 }
    if ([int]$rows[0] -ne $expectedLevel) { throw "HeroEquip $Profile profile level must be $expectedLevel." }
    if ($Profile -ne "Transaction") { return }
    # 4621=62 supports compose 1301 (60) followed by awaken level 1 (2);
    # 4622=2 and frozen package item 854=5 support awaken, while 4629=1 supports red-weapon shenzhu.
    if ($fixtureFragmentIds.Count -ne 4 -or $fixtureFragmentQuantities[1] -ne 62 -or $fixtureFragmentQuantities[2] -ne 2 -or $fixtureFragmentQuantities[3] -ne 1) {
        throw "HeroEquip transaction cultivation material sequence is not frozen."
    }
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
    "SeedTestInventory" {
        Assert-RoleClientsStopped
        Invoke-HeroEquipSql "CREATE TABLE IF NOT EXISTS codex_local_test_account_backup (role_id INT UNSIGNED NOT NULL PRIMARY KEY,guan_qia MEDIUMTEXT NULL,pet_equip MEDIUMTEXT NULL,level INT NULL,created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; INSERT IGNORE INTO codex_local_test_account_backup(role_id,guan_qia,pet_equip,level) SELECT id,guan_qia,pet_equip,level FROM role_info WHERE id=$RoleId;" | Out-Null
        $rows = @(Invoke-HeroEquipSql "SELECT pet_equip FROM role_info WHERE id=$RoleId")
        if ($rows.Count -ne 1 -or [string]::IsNullOrWhiteSpace($rows[0])) { throw "HeroEquip test inventory source is missing." }
        $seed = Add-HeroEquipTestInventory ([string]$rows[0])
        Invoke-HeroEquipSql "UPDATE role_info SET pet_equip='$($seed.hex)',level=99 WHERE id=$RoleId" | Out-Null
        $live = @(Invoke-HeroEquipSql "SELECT pet_equip FROM role_info WHERE id=$RoleId")
        $layout = Get-HeroEquipBlobLayout (Expand-HeroEquipBlob ([string]$live[0]))
        $liveEquipmentTemplates = @($layout.equipmentEntries | ForEach-Object { [uint16]$_.templateId })
        $liveFaBaoTemplates = @($layout.faBaoEntries | ForEach-Object { [uint16]$_.templateId })
        $missingEquipment = @($seed.equipmentTemplates | Where-Object { $_ -notin $liveEquipmentTemplates })
        if ($missingEquipment.Count -gt 0) { throw "HeroEquip test red equipment templates are missing: $($missingEquipment -join ',')" }
        $missingFaBao = @($seed.faBaoTemplates | Where-Object { $_ -notin $liveFaBaoTemplates })
        if ($missingFaBao.Count -gt 0) { throw "HeroEquip test FaBao templates are missing: $($missingFaBao -join ',')" }
        Write-Evidence ([ordered]@{ action=$Action; userId=$UserId; roleId=$RoleId; level=99; redEquipmentTemplates=$seed.equipmentTemplates; faBaoTemplates=$seed.faBaoTemplates; equipmentCount=$layout.equipmentCount; faBaoCount=$layout.faBaoCount; backupTable="codex_local_test_account_backup"; createdUtc=[DateTime]::UtcNow.ToString("O") })
        Write-Host "HeroEquip test inventory seeded: roleId=$RoleId redEquipment=$($seed.equipmentTemplates.Count) faBao=$($seed.faBaoTemplates.Count)"
    }
    "AddUserFragments" {
        Assert-RoleClientsStopped
        $userTable = Get-UserTable
        $rows = @(Invoke-HeroEquipSql "SELECT package FROM role_info WHERE id=$RoleId")
        if ($rows.Count -ne 1) { throw "HeroEquip user role package is missing for roleId=$RoleId." }
        $originalPackage = [string]$rows[0]
        $beforeCounts = Get-HeroEquipPackageFragmentCounts $originalPackage $userFragmentIds
        $updatedPackage = Add-HeroEquipUserFragments $originalPackage
        Invoke-HeroEquipSql "UPDATE role_info SET package='$updatedPackage' WHERE id=$RoleId" | Out-Null
        $afterRows = @(Invoke-HeroEquipSql "SELECT package FROM role_info WHERE id=$RoleId")
        $afterCounts = Get-HeroEquipPackageFragmentCounts ([string]$afterRows[0]) $userFragmentIds
        for ($index = 0; $index -lt $userFragmentIds.Count; $index++) {
            $key = [string][int]$userFragmentIds[$index]
            if ([int]$afterCounts[$key] -ne [int]$beforeCounts[$key] + [int]$userFragmentQuantities[$index]) {
                throw "HeroEquip user fragment $key increment assertion failed."
            }
        }
        $userEvidence = if ([IO.Path]::IsPathRooted($UserFragmentEvidencePath)) { $UserFragmentEvidencePath } else { Join-Path $root $UserFragmentEvidencePath }
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($userEvidence)) | Out-Null
        [IO.File]::WriteAllText($userEvidence, (([ordered]@{
            action="AddUserFragments"; userId=$UserId; roleId=$RoleId; userTable=$userTable
            fragmentIds=@($userFragmentIds); fragmentQuantities=@($userFragmentQuantities)
            beforeCounts=$beforeCounts; afterCounts=$afterCounts; originalPackage=$originalPackage
            updatedPackageSha256=(Get-HeroEquipSha256 $updatedPackage); createdUtc=[DateTime]::UtcNow.ToString("O")
        } | ConvertTo-Json -Depth 8) + "`n"), [Text.UTF8Encoding]::new($false))
    }
    "RestoreUserFragments" {
        Assert-RoleClientsStopped
        $userEvidence = if ([IO.Path]::IsPathRooted($UserFragmentEvidencePath)) { $UserFragmentEvidencePath } else { Join-Path $root $UserFragmentEvidencePath }
        if (-not (Test-Path -LiteralPath $userEvidence -PathType Leaf)) { throw "HeroEquip user fragment evidence is missing: $userEvidence" }
        $snapshot = Get-Content -LiteralPath $userEvidence -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([uint32]$snapshot.userId -ne $UserId -or [uint32]$snapshot.roleId -ne $RoleId) { throw "HeroEquip user fragment restore identity mismatch." }
        Invoke-HeroEquipSql "UPDATE role_info SET package='$([string]$snapshot.originalPackage)' WHERE id=$RoleId" | Out-Null
    }
    "Setup" {
        $userTable = Get-UserTable
        $hash = Get-RoleHash
        $originalPreserveBalanceUserId = Get-PreserveBalanceUserId
        $originalPreserveLevelUserId = Get-PreserveLevelUserId
        Set-PreserveBalanceUserId $UserId
        Set-PreserveLevelUserId $UserId
        Invoke-HeroEquipSql "DROP TABLE IF EXISTS ``$roleBackup``; CREATE TABLE ``$roleBackup`` LIKE role_info; INSERT INTO ``$roleBackup`` SELECT * FROM role_info WHERE id=$RoleId; DROP TABLE IF EXISTS ``$userBackup``; CREATE TABLE ``$userBackup`` LIKE ``$userTable``; INSERT INTO ``$userBackup`` SELECT * FROM ``$userTable`` WHERE id=$UserId" | Out-Null
        Write-Evidence ([ordered]@{
            action="SetupPending"; profile=$Profile; userId=$UserId; roleId=$RoleId; userTable=$userTable; snapshotHash=$hash
            originalPreserveBalanceUserId=$originalPreserveBalanceUserId
            originalPreserveLevelUserId=$originalPreserveLevelUserId
            createdUtc=[DateTime]::UtcNow.ToString("O")
        })
        $petEquipRows = @(Invoke-HeroEquipSql "SELECT pet_equip FROM role_info WHERE id=$RoleId")
        if ($petEquipRows.Count -ne 1) { throw "HeroEquip role pet_equip payload is missing." }
        $fixtureBlob = Add-HeroEquipFixtureItems ([string]$petEquipRows[0])
        $packageRows = @(Invoke-HeroEquipSql "SELECT package FROM role_info WHERE id=$RoleId")
        if ($packageRows.Count -ne 1) { throw "HeroEquip role package payload is missing." }
        $fixturePackage = Add-HeroEquipPackageFragments ([string]$packageRows[0])
        $zhenfaRows = @(Invoke-HeroEquipSql "SELECT zhenfa FROM role_info WHERE id=$RoleId")
        if ($zhenfaRows.Count -ne 1) { throw "HeroEquip role zhenfa payload is missing." }
        $fixtureZhenfa = Set-HeroEquipSecondFormationPosition ([string]$zhenfaRows[0])
        $fixtureLevel = if ($Profile -eq "Transaction") { 70 } elseif ($Profile -eq "Hero") { 99 } else { 60 }
        Invoke-HeroEquipSql "UPDATE role_info SET level=$fixtureLevel,pet_equip='$fixtureBlob',package='$fixturePackage',zhenfa='$fixtureZhenfa' WHERE id=$RoleId" | Out-Null
        Assert-HeroEquipFixtureItems
        Assert-HeroEquipPackageFragments
        Assert-HeroEquipFormationPositions
        Assert-HeroEquipCultivationContract
        Write-Evidence ([ordered]@{
            action="Setup"; profile=$Profile; userId=$UserId; roleId=$RoleId; userTable=$userTable; snapshotHash=$hash
            originalPreserveBalanceUserId=$originalPreserveBalanceUserId
            originalPreserveLevelUserId=$originalPreserveLevelUserId
            fixtureHash=(Get-RoleHash); fixtureEquipmentUid=$fixtureEquipmentUid
            fixtureEquipmentTemplateId=$fixtureEquipmentTemplateId; fixtureFaBaoUid=$fixtureFaBaoUid
            fixtureShenZhuEquipmentUid=$fixtureShenZhuEquipmentUid
            fixtureShenZhuEquipmentTemplateId=$fixtureShenZhuEquipmentTemplateId
            fixtureFaBaoTemplateId=$fixtureFaBaoTemplateId; fixtureFragmentIds=@($fixtureFragmentIds)
            fixtureFragmentQuantities=@($fixtureFragmentQuantities)
            sourceWornEquipmentUid=$sourceWornEquipmentUid; sourceWornEquipmentTemplateId=$sourceWornEquipmentTemplateId
            sourceFormationHeroId=$sourceFormationHeroId; targetFormationHeroId=$targetFormationHeroId
            createdUtc=[DateTime]::UtcNow.ToString("O")
        })
    }
    "AssertSetup" {
        $snapshot = Read-Evidence
        if (@(Invoke-HeroEquipSql "SELECT COUNT(*) FROM ``$roleBackup`` WHERE id=$RoleId")[0] -ne "1") { throw "HeroEquip role backup is missing." }
        if ([string]$snapshot.profile -ne $Profile) { throw "HeroEquip fixture profile mismatch: evidence=$($snapshot.profile) invocation=$Profile" }
        if ((Get-PreserveBalanceUserId) -ne $UserId) { throw "HeroEquip preserve-balance config was not applied." }
        $backupHash = Get-RoleHashFromTable $roleBackup
        if ([string]$snapshot.snapshotHash -ne [string]$backupHash) { throw "HeroEquip immutable role backup hash changed." }
        Assert-HeroEquipFixtureItems
        Assert-HeroEquipPackageFragments
        Assert-HeroEquipFormationPositions
        Assert-HeroEquipCultivationContract
    }
    "CaptureMutationHash" {
        $snapshot = Read-Evidence
        $state = Get-RoleHashStateFromTable "role_info"
        $hash = [string]$state.overall
        if ($hash -eq [string]$snapshot.snapshotHash) {
            throw "HeroEquip transaction did not change the authoritative role hash."
        }
        $snapshot | Add-Member -Force mutationHash $hash
        $snapshot | Add-Member -Force mutationFieldHashes $state.fields
        $snapshot | Add-Member -Force mutationMoney ([string]@(Invoke-HeroEquipSql "SELECT money FROM role_info WHERE id=$RoleId")[0])
        $snapshot | Add-Member -Force mutationCapturedUtc ([DateTime]::UtcNow.ToString("O"))
        Write-Evidence $snapshot
    }
    "AssertMutationReloginHash" {
        $snapshot = Read-Evidence
        $state = Get-RoleHashStateFromTable "role_info"
        $hash = [string]$state.overall
        if ([string]::IsNullOrWhiteSpace([string]$snapshot.mutationHash)) {
            throw "HeroEquip mutation hash was not captured before relogin."
        }
        if ($hash -ne [string]$snapshot.mutationHash) {
            $changed = @($state.fields.PSObject.Properties | Where-Object {
                [string]$snapshot.mutationFieldHashes.($_.Name) -ne [string]$_.Value
            } | ForEach-Object { $_.Name })
            $snapshot | Add-Member -Force mutationPostLoginHash $hash
            $snapshot | Add-Member -Force mutationPostLoginFieldHashes $state.fields
            $snapshot | Add-Member -Force mutationPostLoginChangedFields $changed
            $snapshot | Add-Member -Force mutationPostLoginMoney ([string]@(Invoke-HeroEquipSql "SELECT money FROM role_info WHERE id=$RoleId")[0])
            Write-Evidence $snapshot
            throw "HeroEquip post-transaction relogin hash mismatch: changedFields=$($changed -join ','), money=$($snapshot.mutationMoney)->$($snapshot.mutationPostLoginMoney)."
        }
        $snapshot | Add-Member -Force mutationPostLoginHash $hash
        $snapshot | Add-Member -Force mutationReloginAssertedUtc ([DateTime]::UtcNow.ToString("O"))
        Write-Evidence $snapshot
    }
    "Restore" {
        $snapshot = Read-Evidence
        $userTable = [string]$snapshot.userTable
        Invoke-HeroEquipSql "DELETE FROM role_info WHERE id=$RoleId; INSERT INTO role_info SELECT * FROM ``$roleBackup`` WHERE id=$RoleId; DELETE FROM ``$userTable`` WHERE id=$UserId; INSERT INTO ``$userTable`` SELECT * FROM ``$userBackup`` WHERE id=$UserId" | Out-Null
        Set-PreserveBalanceUserId ([uint32]$snapshot.originalPreserveBalanceUserId)
        Set-PreserveLevelUserId ([uint32]$snapshot.originalPreserveLevelUserId)
    }
    "AssertRestored" {
        $snapshot = Read-Evidence; $hash = Get-RoleHash
        if ($hash -ne [string]$snapshot.snapshotHash) { throw "HeroEquip restored role hash mismatch." }
        if ((Get-PreserveBalanceUserId) -ne [uint32]$snapshot.originalPreserveBalanceUserId) { throw "HeroEquip preserve-balance config was not restored." }
        if ((Get-PreserveLevelUserId) -ne [uint32]$snapshot.originalPreserveLevelUserId) { throw "HeroEquip preserve-level config was not restored." }
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
